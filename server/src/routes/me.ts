// SPEC §7 — the /me surface. Thin: parse → service → serialize.
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { parseBody, requireAuth, requireDb } from '../app.js';
import { listBadges } from '../badges/service.js';
import { notImplemented } from '../errors.js';
import { deleteMe, getMeCoverage, getMeMap, getMeStats, listMeCheckins } from '../me/service.js';

const checkinsQuerySchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});

export function registerMeRoutes(app: FastifyInstance): void {
  app.get('/me', async (req) => {
    const userId = await requireAuth(req);
    const { pg } = requireDb(app);
    const stats = await getMeStats(pg, userId);
    const userRows = await pg`SELECT id, handle, created_at FROM users WHERE id = ${userId}`;
    // Raw pg query on a drizzle-wrapped connection returns timestamptz as a string.
    const row = userRows[0] as { id: string; handle: string; created_at: string };
    return {
      user: { id: row.id, handle: row.handle, createdAt: new Date(row.created_at).toISOString() },
      stats,
    };
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
