// SPEC §7 — the /me surface. Thin: parse → service → serialize.
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { parseBody, requireAuth, requireDb } from '../app.js';
import { listBadges } from '../badges/service.js';
import { notImplemented } from '../errors.js';
import {
  deleteMe,
  getMeCoverage,
  getMeCoverageHeatmap,
  getMeMap,
  getMeStats,
  listMeCheckins,
  setDisplayName,
} from '../me/service.js';
import { listMyPostcards } from '../postcards/service.js';

const checkinsQuerySchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});

const heatmapQuerySchema = z.object({
  zoom: z.coerce.number().int().min(0).max(22),
});

/** SPEC §11: length limits count Unicode code points, not UTF-16 units. */
function codePointLength(s: string): number {
  return [...s].length;
}

// SPEC §21 — 1..40 code points, or null to clear.
const displayNameSchema = z.object({
  displayName: z
    .string()
    .refine((s) => codePointLength(s) >= 1 && codePointLength(s) <= 40, {
      message: 'displayName must be 1..40 Unicode code points',
    })
    .nullable(),
});

export function registerMeRoutes(app: FastifyInstance): void {
  app.get('/me', async (req) => {
    const userId = await requireAuth(req);
    const { pg } = requireDb(app);
    const stats = await getMeStats(pg, userId);
    const userRows = await pg`
      SELECT id, handle, display_name, created_at FROM users WHERE id = ${userId}`;
    // Raw pg query on a drizzle-wrapped connection returns timestamptz as a string.
    const row = userRows[0] as {
      id: string;
      handle: string;
      display_name: string | null;
      created_at: string;
    };
    return {
      user: {
        id: row.id,
        handle: row.handle,
        displayName: row.display_name,
        createdAt: new Date(row.created_at).toISOString(),
      },
      stats,
    };
  });

  // SPEC §21 — sets/clears the caller's opt-in display name (distinct from `handle`).
  app.patch('/me/display-name', async (req) => {
    const userId = await requireAuth(req);
    const body = parseBody(displayNameSchema, req.body);
    const { pg } = requireDb(app);
    return setDisplayName(pg, app.deps.displayNameModeration, userId, body.displayName);
  });

  app.get('/me/map', async (req) => {
    const userId = await requireAuth(req);
    const { pg } = requireDb(app);
    return getMeMap(pg, userId);
  });

  app.get('/me/coverage', async (req) => {
    const userId = await requireAuth(req);
    const { pg } = requireDb(app);
    return getMeCoverage(pg, userId);
  });

  app.get('/me/coverage/heatmap', async (req) => {
    const userId = await requireAuth(req);
    const query = parseBody(heatmapQuerySchema, req.query);
    const { pg } = requireDb(app);
    return getMeCoverageHeatmap(pg, userId, query.zoom);
  });

  app.get('/me/checkins', async (req) => {
    const userId = await requireAuth(req);
    const query = parseBody(checkinsQuerySchema, req.query);
    const { pg } = requireDb(app);
    return listMeCheckins(pg, userId, query.limit, query.cursor);
  });

  app.get('/me/badges', async (req) => {
    const userId = await requireAuth(req);
    const { db } = requireDb(app);
    return { badges: await listBadges(db, userId) };
  });

  // SPEC §20 — the caller's own sent postcards, newest first, so they can find and
  // revoke one (`DELETE /postcards/:id`, routes/postcards.ts).
  app.get('/me/postcards', async (req) => {
    const userId = await requireAuth(req);
    const { pg } = requireDb(app);
    return { postcards: await listMyPostcards(pg, app.deps.config.PUBLIC_BASE_URL, userId) };
  });

  app.get('/me/export', async () => {
    throw notImplemented('Data export');
  });

  app.delete('/me', async (req) => {
    const userId = await requireAuth(req);
    const { db } = requireDb(app);
    await deleteMe(db, userId, new Date());
    return { ok: true };
  });
}
