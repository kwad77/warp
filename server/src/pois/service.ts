// SPEC §7 — POI CRUD/discovery and photo presign/complete. Routes stay thin; this module
// owns the I/O and geo queries (raw pg tagged SQL for ST_* per src/checkins/service.ts).
import { and, count, eq, gt } from 'drizzle-orm';
import { gridDisk } from 'h3-js';
import { type PoiCategory, SPEC_CONSTANTS } from '../constants.js';
import type { Db, Pg } from '../db/client.js';
import { pois } from '../db/schema.js';
import { AppError } from '../errors.js';
import { type LatLng, haversineM } from '../geo/distance.js';
import { coverageCell, dedupeCell, h3ToBigint } from '../geo/h3.js';
import { uuidv7 } from '../lib/uuid.js';
import type { ModerationProvider } from '../moderation/provider.js';
import { runModerationForPhoto } from '../moderation/service.js';
import type { Storage } from '../storage/r2.js';

const G = SPEC_CONSTANTS.geo;
const RATE = SPEC_CONSTANTS.rate;
const PHOTOS = SPEC_CONSTANTS.photos;

export interface PoiPinView {
  id: string;
  title: string;
  category: string;
  location: { lat: number; lng: number };
  checkinCount: number;
  /** SPEC §19 (M2) — best approved photo, computed only where noted; `null` elsewhere. */
  thumbnailUrl: string | null;
}

export interface ClusterView {
  h3: string;
  count: number;
  centroid: { lat: number; lng: number };
}

export interface PhotoView {
  id: string;
  urlCard: string;
  urlThumb: string;
  voteScore: number;
  myVote: boolean;
  uploader: { handle: string };
  status: string;
}

export interface PoiView extends PoiPinView {
  description: string | null;
  creator: { id: string; handle: string };
  checkinRadiusM: number;
  gallery: PhotoView[];
}

interface PoiPinRow {
  id: string;
  title: string;
  category: string;
  checkin_count: number;
  lat: number | string;
  lng: number | string;
  /** Present only for queries that join the best-approved-photo lookup (SPEC §19). */
  storage_key?: string | null;
}

function serializePin(row: PoiPinRow): PoiPinView {
  return {
    id: row.id,
    title: row.title,
    category: row.category,
    location: { lat: Number(row.lat), lng: Number(row.lng) },
    checkinCount: Number(row.checkin_count),
    thumbnailUrl: row.storage_key ? urlThumb(row.storage_key) : null,
  };
}

/** CDN mapping comes later — kept as a pure, swappable function. SPEC §6. */
export function urlCard(storageKey: string): string {
  return `/media/card/${storageKey}`;
}
export function urlThumb(storageKey: string): string {
  return `/media/thumb/${storageKey}`;
}

function ewkt(p: LatLng): string {
  return `SRID=4326;POINT(${p.lng} ${p.lat})`;
}

export interface BboxQuery {
  w: number;
  s: number;
  e: number;
  n: number;
}

/** SPEC §7: w > e (antimeridian) is unsupported in M1 regardless of zoom. */
export function parseBbox(raw: string): BboxQuery {
  const parts = raw.split(',').map(Number);
  if (parts.length !== 4 || parts.some((p) => !Number.isFinite(p))) {
    throw new AppError('request/invalid', 'bbox must be four numbers: w,s,e,n');
  }
  const [w, s, e, n] = parts as [number, number, number, number];
  if (w < -180 || w > 180 || e < -180 || e > 180 || s < -90 || s > 90 || n < -90 || n > 90) {
    throw new AppError('request/invalid', 'bbox coordinates out of range');
  }
  if (s >= n) {
    throw new AppError('request/invalid', 'bbox south must be less than north');
  }
  if (w > e) {
    throw new AppError('request/invalid', 'Antimeridian-crossing bbox is unsupported in M1');
  }
  return { w, s, e, n };
}

export async function listPois(
  pg: Pg,
  bbox: BboxQuery,
  zoom: number,
): Promise<{ pois: PoiPinView[]; clusters: ClusterView[] }> {
  if (zoom >= 13) {
    if (bbox.e - bbox.w > 2 || bbox.n - bbox.s > 2) {
      throw new AppError('request/invalid', 'bbox wider/taller than 2° requires zoom < 13');
    }
    const rows = await pg`
      SELECT id, title, category, checkin_count,
             ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng
      FROM pois
      WHERE status = 'active'
        AND ST_Intersects(location, ST_MakeEnvelope(${bbox.w}, ${bbox.s}, ${bbox.e}, ${bbox.n}, 4326)::geography)
      LIMIT 200`;
    return { pois: (rows as unknown as PoiPinRow[]).map(serializePin), clusters: [] };
  }

  const rows = await pg`
    SELECT ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng
    FROM pois
    WHERE status = 'active'
      AND ST_Intersects(location, ST_MakeEnvelope(${bbox.w}, ${bbox.s}, ${bbox.e}, ${bbox.n}, 4326)::geography)`;
  const groups = new Map<string, { lat: number; lng: number }[]>();
  for (const r of rows as unknown as { lat: number | string; lng: number | string }[]) {
    const point = { lat: Number(r.lat), lng: Number(r.lng) };
    const cell = coverageCell(point);
    const bucket = groups.get(cell);
    if (bucket) bucket.push(point);
    else groups.set(cell, [point]);
  }
  const clusters: ClusterView[] = [...groups.entries()].map(([h3, pts]) => ({
    h3,
    count: pts.length,
    centroid: {
      lat: pts.reduce((s, p) => s + p.lat, 0) / pts.length,
      lng: pts.reduce((s, p) => s + p.lng, 0) / pts.length,
    },
  }));
  return { pois: [], clusters };
}

export async function listNearby(
  pg: Pg,
  center: LatLng,
  radiusM: number,
): Promise<{ pois: PoiPinView[] }> {
  // thumbnailUrl (SPEC §19, M2): bounded to 50 results, cheap enough for the per-row
  // best-approved-photo lookup — deliberately not done for the bbox endpoint (up to 200
  // results, hit continuously while panning).
  const rows = await pg`
    SELECT p.id, p.title, p.category, p.checkin_count,
           ST_Y(p.location::geometry) AS lat, ST_X(p.location::geometry) AS lng,
           bp.storage_key
    FROM pois p
    LEFT JOIN LATERAL (
      SELECT storage_key FROM photos
      WHERE poi_id = p.id AND moderation = 'approved'
      ORDER BY vote_score DESC, created_at ASC
      LIMIT 1
    ) bp ON true
    WHERE p.status = 'active'
      AND ST_DWithin(p.location, ST_GeogFromText(${ewkt(center)}), ${radiusM})
    ORDER BY ST_Distance(p.location, ST_GeogFromText(${ewkt(center)})) ASC
    LIMIT 50`;
  return { pois: (rows as unknown as PoiPinRow[]).map(serializePin) };
}

export async function getPoiById(pg: Pg, id: string, requesterId: string | null): Promise<PoiView> {
  const rows = await pg`
    SELECT p.id, p.title, p.description, p.category, p.checkin_radius_m, p.checkin_count,
           p.status, ST_Y(p.location::geometry) AS lat, ST_X(p.location::geometry) AS lng,
           u.id AS creator_id, u.handle AS creator_handle
    FROM pois p JOIN users u ON u.id = p.creator_id
    WHERE p.id = ${id}`;
  const row = rows[0] as
    | {
        id: string;
        title: string;
        description: string | null;
        category: string;
        checkin_radius_m: number;
        checkin_count: number;
        status: string;
        lat: number | string;
        lng: number | string;
        creator_id: string;
        creator_handle: string;
      }
    | undefined;
  if (!row || row.status === 'removed') {
    throw new AppError('resource/not_found', 'No such POI');
  }
  const photoRows = await pg`
    SELECT ph.id, ph.storage_key, ph.vote_score, ph.moderation, u2.handle AS uploader_handle,
           (v.user_id IS NOT NULL) AS my_vote
    FROM photos ph JOIN users u2 ON u2.id = ph.uploader_id
    LEFT JOIN votes v ON v.photo_id = ph.id AND v.user_id = ${requesterId}
    WHERE ph.poi_id = ${id} AND ph.moderation = 'approved'
    ORDER BY ph.vote_score DESC, ph.created_at ASC
    LIMIT 20`;
  const gallery: PhotoView[] = (
    photoRows as unknown as {
      id: string;
      storage_key: string;
      vote_score: number;
      moderation: string;
      uploader_handle: string;
      my_vote: boolean;
    }[]
  ).map((p) => ({
    id: p.id,
    urlCard: urlCard(p.storage_key),
    urlThumb: urlThumb(p.storage_key),
    voteScore: Number(p.vote_score),
    myVote: p.my_vote,
    uploader: { handle: p.uploader_handle },
    status: p.moderation,
  }));
  return {
    id: row.id,
    title: row.title,
    category: row.category,
    location: { lat: Number(row.lat), lng: Number(row.lng) },
    checkinCount: Number(row.checkin_count),
    // gallery is already vote-ranked (SPEC §7) — its first entry is the same "best
    // approved photo" thumbnailUrl uses elsewhere (SPEC §19), no extra query needed.
    thumbnailUrl: gallery[0]?.urlThumb ?? null,
    description: row.description,
    creator: { id: row.creator_id, handle: row.creator_handle },
    checkinRadiusM: Number(row.checkin_radius_m),
    gallery,
  };
}

export interface CreatePoiInput {
  title: string;
  description?: string;
  category: PoiCategory;
  location: LatLng;
  gpsFix: LatLng;
  force?: boolean;
  // Ops-only escape hatch for bulk data import (server/src/scripts/seed_osm_pois.ts):
  // POI_CREATE_PER_DAY models a real user's posting velocity, which a one-time curated
  // import of real-world places isn't — modeling that import AS a rate-limited user (via
  // a pile of synthetic "founder" accounts sized to the day's quota) was itself the wrong
  // shape, not something to route around by tuning account count. NEVER settable from the
  // route: routes/pois.ts's createPoiSchema has no such field, and the route handler
  // builds CreatePoiInput field-by-field rather than spreading the parsed body, so this
  // can't leak in from a client request.
  skipRateLimit?: boolean;
}

export type CreatePoiResult = { poi: PoiView } | { dedupeCandidates: PoiPinView[] };

export async function createPoi(
  db: Db,
  pg: Pg,
  userId: string,
  input: CreatePoiInput,
  now: Date,
): Promise<CreatePoiResult> {
  const pinDistance = haversineM(input.location, input.gpsFix);
  if (pinDistance > G.PIN_ADJUST_MAX_M) {
    throw new AppError('poi/outside_pin_adjust', 'Pin is too far from the GPS fix', {
      distanceM: pinDistance,
    });
  }

  if (!input.skipRateLimit) {
    const dayAgo = new Date(now.getTime() - 86_400_000);
    const [recent] = await db
      .select({ n: count() })
      .from(pois)
      .where(and(eq(pois.creatorId, userId), gt(pois.createdAt, dayAgo)));
    if ((recent?.n ?? 0) >= RATE.POI_CREATE_PER_DAY) {
      throw new AppError('rate/limited', 'Too many POIs created today', { retryAfterS: 86_400 });
    }
  }

  const cell = dedupeCell(input.location);

  if (!input.force) {
    // Proximity-only dedupe: r9 neighbor cells (ring size 1) then exact ST_DWithin. SPEC §7.
    // BIGINT params travel as strings — postgres.js has no native bigint fragment type.
    const neighborCells = gridDisk(cell, 1).map((c) => h3ToBigint(c).toString());
    const candidateRows = await pg`
      SELECT id, title, category, checkin_count,
             ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng
      FROM pois
      WHERE status = 'active'
        AND h3_r9 = ANY(${neighborCells})
        AND ST_DWithin(location, ST_GeogFromText(${ewkt(input.location)}), ${G.DEDUPE_RADIUS_M})`;
    if (candidateRows.length > 0) {
      return {
        dedupeCandidates: (candidateRows as unknown as PoiPinRow[]).map(serializePin),
      };
    }
  }

  const id = uuidv7(now.getTime());
  const radiusM = SPEC_CONSTANTS.checkinRadiusM[input.category];
  await pg`
    INSERT INTO pois (id, creator_id, title, description, category, location, h3_r9, checkin_radius_m, status)
    VALUES (${id}, ${userId}, ${input.title}, ${input.description ?? null}, ${input.category},
            ST_GeogFromText(${ewkt(input.location)}), ${h3ToBigint(cell).toString()}, ${radiusM}, 'active')`;

  return { poi: await getPoiById(pg, id, userId) };
}

async function poiExists(pg: Pg, poiId: string): Promise<boolean> {
  const rows = await pg`SELECT 1 FROM pois WHERE id = ${poiId} AND status <> 'removed'`;
  return rows.length > 0;
}

export interface PresignResult {
  uploadUrl: string;
  storageKey: string;
  maxBytes: number;
}

export async function presignPhoto(
  storage: Storage,
  pg: Pg,
  poiId: string,
  contentType: string,
  now: Date,
): Promise<PresignResult> {
  if (!(await poiExists(pg, poiId))) {
    throw new AppError('resource/not_found', 'No such POI');
  }
  const ext = contentType === 'image/webp' ? 'webp' : 'jpg';
  const photoId = uuidv7(now.getTime());
  const storageKey = `photos/${poiId}/${photoId}.${ext}`;
  const presigned = await storage.presignPut(storageKey, contentType);
  return { uploadUrl: presigned.uploadUrl, storageKey, maxBytes: presigned.maxBytes };
}

/** photos/<poiId>/<photoId>.<jpg|webp> — server-minted in presignPhoto. SPEC §6. */
function parseStorageKey(storageKey: string, poiId: string): string {
  const match = /^photos\/([^/]+)\/([^/.]+)\.(jpg|webp)$/.exec(storageKey);
  if (!match || match[1] !== poiId) {
    throw new AppError('request/invalid', 'Malformed or mismatched storageKey');
  }
  return match[2] as string;
}

export async function completePhoto(
  storage: Storage,
  moderation: ModerationProvider,
  pg: Pg,
  userId: string,
  poiId: string,
  storageKey: string,
  source: 'poi_creation' | 'checkin',
): Promise<PhotoView> {
  if (!(await poiExists(pg, poiId))) {
    throw new AppError('resource/not_found', 'No such POI');
  }
  const photoId = parseStorageKey(storageKey, poiId);

  // Idempotent retry: a lost complete-response must not 500 on the unique storage_key.
  const existing = await pg`
    SELECT ph.id, ph.storage_key, ph.uploader_id, ph.vote_score, ph.moderation,
           u.handle AS uploader_handle
    FROM photos ph JOIN users u ON u.id = ph.uploader_id
    WHERE ph.storage_key = ${storageKey}`;
  const prior = existing[0] as
    | {
        id: string;
        storage_key: string;
        uploader_id: string;
        vote_score: number;
        moderation: string;
        uploader_handle: string;
      }
    | undefined;
  if (prior) {
    if (prior.uploader_id !== userId) {
      throw new AppError('request/invalid', 'storageKey already completed by another user');
    }
    return {
      id: prior.id,
      urlCard: urlCard(prior.storage_key),
      urlThumb: urlThumb(prior.storage_key),
      voteScore: Number(prior.vote_score),
      // Voting requires an approved photo (community/service.ts); a freshly-completed
      // upload is always 'pending', so the uploader can't have voted on it yet.
      myVote: false,
      uploader: { handle: prior.uploader_handle },
      status: prior.moderation,
    };
  }

  const head = await storage.head(storageKey);
  const allowed = PHOTOS.ALLOWED_MIME as readonly string[];
  if (!head || head.bytes > PHOTOS.UPLOAD_MAX_BYTES || !allowed.includes(head.contentType)) {
    throw new AppError('photo/rejected', 'Uploaded object failed validation', {
      reason: 'quality',
    });
  }

  await pg`
    INSERT INTO photos (id, poi_id, uploader_id, storage_key, bytes, source, moderation)
    VALUES (${photoId}, ${poiId}, ${userId}, ${storageKey}, ${head.bytes}, ${source}, 'pending')`;

  const rows = await pg`
    SELECT ph.id, ph.storage_key, ph.vote_score, ph.moderation, u.handle AS uploader_handle
    FROM photos ph JOIN users u ON u.id = ph.uploader_id
    WHERE ph.id = ${photoId}`;
  const row = rows[0] as {
    id: string;
    storage_key: string;
    vote_score: number;
    moderation: string;
    uploader_handle: string;
  };
  const view: PhotoView = {
    id: row.id,
    urlCard: urlCard(row.storage_key),
    urlThumb: urlThumb(row.storage_key),
    voteScore: Number(row.vote_score),
    // Same reasoning as the idempotent-retry branch above: a 'pending' photo can't have
    // any votes yet.
    myVote: false,
    uploader: { handle: row.uploader_handle },
    status: row.moderation,
  };

  // SPEC §6 M1 note: run synchronously (Dev provider is instant), but the response above
  // deliberately still reflects the freshly-inserted row — callers re-fetch to see the
  // resolved verdict, keeping the response contract stable once a real provider lands.
  await runModerationForPhoto(moderation, storage, pg, photoId, storageKey);

  return view;
}

/**
 * SPEC §19 (M2) — a plain bookmark, same shape as `voteOnPhoto` (`value: 0` retracts).
 * Saving a non-`active` POI ⇒ `resource/not_found`, same visibility-leak avoidance as
 * voting on a non-approved photo.
 */
export async function setSavedPoi(
  pg: Pg,
  userId: string,
  poiId: string,
  value: 0 | 1,
): Promise<{ saved: boolean }> {
  const poiRows = await pg`SELECT id FROM pois WHERE id = ${poiId} AND status = 'active'`;
  if (poiRows.length === 0) {
    throw new AppError('resource/not_found', 'Unknown POI');
  }
  if (value === 0) {
    await pg`DELETE FROM saved_pois WHERE user_id = ${userId} AND poi_id = ${poiId}`;
  } else {
    await pg`
      INSERT INTO saved_pois (user_id, poi_id)
      VALUES (${userId}, ${poiId})
      ON CONFLICT (user_id, poi_id) DO NOTHING`;
  }
  return { saved: value === 1 };
}
