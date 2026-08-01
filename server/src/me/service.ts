// SPEC §7 — the /me surface: profile stats, personal map, coverage, check-in history,
// account deletion. Raw pg tagged SQL for geo/aggregate reads, matching src/pois/service.ts.
import { and, eq } from 'drizzle-orm';
import type { Db, Pg } from '../db/client.js';
import { refreshTokens, users } from '../db/schema.js';
import { AppError } from '../errors.js';
import { bigintToH3 } from '../geo/h3.js';
import type { PoiPinView } from '../pois/service.js';

interface PinRow {
  id: string;
  title: string;
  category: string;
  checkin_count: number;
  lat: number | string;
  lng: number | string;
}

function serializePin(row: PinRow): PoiPinView {
  return {
    id: row.id,
    title: row.title,
    category: row.category,
    location: { lat: Number(row.lat), lng: Number(row.lng) },
    checkinCount: Number(row.checkin_count),
  };
}

export interface MeStats {
  checkins: number;
  cellsCovered: number;
  poisCreated: number;
}

export async function getMeStats(pg: Pg, userId: string): Promise<MeStats> {
  const rows = await pg`
    SELECT
      (SELECT count(*)::int FROM checkins WHERE user_id = ${userId} AND status = 'verified') AS checkins,
      (SELECT count(*)::int FROM user_coverage WHERE user_id = ${userId}) AS cells_covered,
      (SELECT count(*)::int FROM pois WHERE creator_id = ${userId} AND status <> 'removed') AS pois_created`;
  const row = rows[0] as { checkins: number; cells_covered: number; pois_created: number };
  return {
    checkins: row.checkins,
    cellsCovered: row.cells_covered,
    poisCreated: row.pois_created,
  };
}

export interface MeMap {
  checkedIn: PoiPinView[];
  created: PoiPinView[];
  vaulted: PoiPinView[];
}

export async function getMeMap(pg: Pg, userId: string): Promise<MeMap> {
  const checkedInRows = await pg`
    SELECT p.id, p.title, p.category, p.checkin_count,
           ST_Y(p.location::geometry) AS lat, ST_X(p.location::geometry) AS lng
    FROM checkins c JOIN pois p ON p.id = c.poi_id
    WHERE c.user_id = ${userId} AND c.status = 'verified'`;
  const createdRows = await pg`
    SELECT id, title, category, checkin_count,
           ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng
    FROM pois WHERE creator_id = ${userId} AND status <> 'removed'`;
  return {
    checkedIn: (checkedInRows as unknown as PinRow[]).map(serializePin),
    created: (createdRows as unknown as PinRow[]).map(serializePin),
    // Vault ships in M3 (docs/MVP.md) — the flag exists on `checkins` but nothing sets it yet.
    vaulted: [],
  };
}

export async function getMeCoverage(
  pg: Pg,
  userId: string,
): Promise<{ cells: string[]; count: number }> {
  const rows = await pg`SELECT h3_r7 FROM user_coverage WHERE user_id = ${userId}`;
  const cells = (rows as unknown as { h3_r7: string }[]).map((r) => bigintToH3(BigInt(r.h3_r7)));
  return { cells, count: cells.length };
}

export interface CheckinListItem {
  id: string;
  poiId: string;
  status: string;
  mode: string;
  createdAt: string;
  verifiedAt: string | null;
}

/** Pagination convention (SPEC §7): cursor = base64("<createdAt ISO>|<id>"), keyset on
 *  (created_at DESC, id DESC). Malformed/absent cursor starts from the top. */
function encodeCursor(createdAt: Date, id: string): string {
  return Buffer.from(`${createdAt.toISOString()}|${id}`, 'utf8').toString('base64');
}

function decodeCursor(cursor: string): { createdAt: Date; id: string } | null {
  try {
    const decoded = Buffer.from(cursor, 'base64').toString('utf8');
    const sep = decoded.lastIndexOf('|');
    if (sep < 0) return null;
    const createdAt = new Date(decoded.slice(0, sep));
    const id = decoded.slice(sep + 1);
    if (Number.isNaN(createdAt.getTime()) || !id) return null;
    return { createdAt, id };
  } catch {
    return null;
  }
}

export async function listMeCheckins(
  pg: Pg,
  userId: string,
  limit: number,
  cursor: string | undefined,
): Promise<{ items: CheckinListItem[]; nextCursor?: string }> {
  const after = cursor ? decodeCursor(cursor) : null;
  const rows = after
    ? await pg`
        SELECT id, poi_id, status, mode, created_at, verified_at
        FROM checkins
        WHERE user_id = ${userId}
          AND (created_at, id) < (${after.createdAt.toISOString()}, ${after.id})
        ORDER BY created_at DESC, id DESC
        LIMIT ${limit + 1}`
    : await pg`
        SELECT id, poi_id, status, mode, created_at, verified_at
        FROM checkins
        WHERE user_id = ${userId}
        ORDER BY created_at DESC, id DESC
        LIMIT ${limit + 1}`;

  // NOTE: once `drizzle(pg, {schema})` has wrapped a connection, raw tagged-template
  // queries on that same connection return timestamptz columns as strings, not Date
  // instances (Drizzle's own query builder still converts them; this raw path does not).
  // Always wrap with `new Date(...)` before touching Date methods here.
  const rawRows = rows as unknown as {
    id: string;
    poi_id: string;
    status: string;
    mode: string;
    created_at: string;
    verified_at: string | null;
  }[];
  const typed = rawRows.map((r) => ({
    ...r,
    created_at: new Date(r.created_at),
    verified_at: r.verified_at ? new Date(r.verified_at) : null,
  }));
  const page = typed.slice(0, limit);
  const items: CheckinListItem[] = page.map((r) => ({
    id: r.id,
    poiId: r.poi_id,
    status: r.status,
    mode: r.mode,
    createdAt: r.created_at.toISOString(),
    verifiedAt: r.verified_at ? r.verified_at.toISOString() : null,
  }));
  const hasMore = typed.length > limit;
  const last = page[page.length - 1];
  return {
    items,
    ...(hasMore && last ? { nextCursor: encodeCursor(last.created_at, last.id) } : {}),
  };
}

/** Soft-delete + immediate logout everywhere (revoke every refresh-token family). SPEC §7. */
export async function deleteMe(db: Db, userId: string, now: Date): Promise<void> {
  await db.transaction(async (tx) => {
    await tx.update(users).set({ deletedAt: now }).where(eq(users.id, userId));
    await tx
      .update(refreshTokens)
      .set({ used: true })
      .where(and(eq(refreshTokens.userId, userId), eq(refreshTokens.used, false)));
  });
}

export const _internals = { encodeCursor, decodeCursor };
