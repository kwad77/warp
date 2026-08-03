// SPEC §20 — postcard sending v1. Routes stay thin; this module owns the I/O.
import { randomBytes } from 'node:crypto';
import { SPEC_CONSTANTS } from '../constants.js';
import type { Pg } from '../db/client.js';
import { AppError } from '../errors.js';
import { uuidv7 } from '../lib/uuid.js';
import type { TextModerationProvider } from '../moderation/text_provider.js';
import { urlCard } from '../pois/service.js';

const RATE = SPEC_CONSTANTS.rate;

export interface SentPostcard {
  id: string;
  token: string;
  url: string;
}

export function postcardUrl(publicBaseUrl: string, token: string): string {
  return `${publicBaseUrl}/v1/postcards/${token}`;
}

/**
 * SPEC §20 — only the caller's own `verified` check-ins can be sent (no visibility leak
 * on `pending`/`rejected`, same "resource/not_found rather than a specific reason"
 * pattern already used for voting/saving). Each call mints a fresh token — sending twice
 * from the same check-in is allowed (e.g. sharing with a second person later), not
 * deduplicated.
 */
export async function sendPostcard(
  pg: Pg,
  textModeration: TextModerationProvider,
  publicBaseUrl: string,
  senderId: string,
  checkinId: string,
  message: string | undefined,
  now: Date,
): Promise<SentPostcard> {
  const checkinRows = await pg`
    SELECT id FROM checkins
    WHERE id = ${checkinId} AND user_id = ${senderId} AND status = 'verified'`;
  if (checkinRows.length === 0) {
    throw new AppError('resource/not_found', 'No such check-in');
  }

  const dayAgo = new Date(now.getTime() - 86_400_000);
  const countRows = await pg`
    SELECT count(*)::int AS n FROM postcards
    WHERE sender_id = ${senderId} AND created_at > ${dayAgo.toISOString()}`;
  const recent = Number((countRows[0] as { n: number } | undefined)?.n ?? 0);
  if (recent >= RATE.POSTCARD_SEND_PER_DAY) {
    throw new AppError('rate/limited', 'Too many postcards sent today', { retryAfterS: 86_400 });
  }

  const verdict = message ? await textModeration.moderate(message) : { approved: true };
  const id = uuidv7(now.getTime());
  const token = randomBytes(18).toString('base64url');
  await pg`
    INSERT INTO postcards (id, checkin_id, sender_id, token, message, message_approved, created_at)
    VALUES (${id}, ${checkinId}, ${senderId}, ${token}, ${message ?? null}, ${verdict.approved},
            ${now.toISOString()})`;

  return { id, token, url: postcardUrl(publicBaseUrl, token) };
}

/** SPEC §20 — one-directional: no un-revoke. Not owned / already revoked / unknown ⇒
 *  the same `resource/not_found` (no leak of which). */
export async function revokePostcard(
  pg: Pg,
  senderId: string,
  postcardId: string,
  now: Date,
): Promise<void> {
  const rows = await pg`
    UPDATE postcards SET revoked_at = ${now.toISOString()}
    WHERE id = ${postcardId} AND sender_id = ${senderId} AND revoked_at IS NULL
    RETURNING id`;
  if (rows.length === 0) {
    throw new AppError('resource/not_found', 'No such postcard');
  }
}

export interface PostcardRenderView {
  poiTitle: string;
  senderHandle: string;
  verifiedAt: string;
  message: string | null;
  photoUrlCard: string | null;
  photographerHandle: string | null;
}

/**
 * SPEC §20 — photo resolution is computed at VIEW time, not snapshotted at send time: the
 * check-in's own photo (photo-mode) if it's `approved`, else the POI's best-approved
 * gallery photo (same tie-break as `GET /pois/:id`'s gallery / `thumbnailUrl`), with
 * photographer credit following whichever photo was actually used. `null` if neither
 * exists — a photo-less card still renders (place, date, sender, message), since
 * requiring a photo would block sending from any POI without an approved photo yet.
 */
export async function getPostcardForRender(
  pg: Pg,
  token: string,
): Promise<PostcardRenderView | null> {
  const rows = await pg`
    SELECT pc.message, pc.message_approved, pc.revoked_at,
           p.title AS poi_title, u.handle AS sender_handle, c.verified_at,
           cph.storage_key AS checkin_photo_key, cph.moderation AS checkin_photo_moderation,
           cpu.handle AS checkin_photo_uploader,
           bp.storage_key AS gallery_photo_key, bpu.handle AS gallery_photo_uploader
    FROM postcards pc
    JOIN checkins c ON c.id = pc.checkin_id
    JOIN pois p ON p.id = c.poi_id
    JOIN users u ON u.id = pc.sender_id
    LEFT JOIN photos cph ON cph.id = c.photo_id
    LEFT JOIN users cpu ON cpu.id = cph.uploader_id
    LEFT JOIN LATERAL (
      SELECT storage_key, uploader_id FROM photos
      WHERE poi_id = p.id AND moderation = 'approved'
      ORDER BY vote_score DESC, created_at ASC
      LIMIT 1
    ) bp ON true
    LEFT JOIN users bpu ON bpu.id = bp.uploader_id
    WHERE pc.token = ${token}`;
  const row = rows[0] as
    | {
        message: string | null;
        message_approved: boolean;
        revoked_at: string | null;
        poi_title: string;
        sender_handle: string;
        verified_at: string;
        checkin_photo_key: string | null;
        checkin_photo_moderation: string | null;
        checkin_photo_uploader: string | null;
        gallery_photo_key: string | null;
        gallery_photo_uploader: string | null;
      }
    | undefined;
  if (!row || row.revoked_at) return null;

  const useCheckinPhoto = !!row.checkin_photo_key && row.checkin_photo_moderation === 'approved';
  const photoKey = useCheckinPhoto ? row.checkin_photo_key : row.gallery_photo_key;
  const photographerHandle = useCheckinPhoto
    ? row.checkin_photo_uploader
    : row.gallery_photo_uploader;

  return {
    poiTitle: row.poi_title,
    senderHandle: row.sender_handle,
    // Invariant: only a `status='verified'` checkin can have a postcard (sendPostcard's
    // WHERE clause), so verified_at is always set here despite the column being nullable.
    verifiedAt: new Date(row.verified_at).toISOString(),
    message: row.message_approved ? row.message : null,
    photoUrlCard: photoKey ? urlCard(photoKey) : null,
    photographerHandle: photoKey ? photographerHandle : null,
  };
}
