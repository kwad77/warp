// SPEC §7 — coverage leaderboard. Public with optional auth for `me`.
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { optionalAuth, parseBody, requireDb } from '../app.js';
import { getCoverageLeaderboard } from '../leaderboards/service.js';

const querySchema = z.object({
  window: z.enum(['weekly', 'all']),
  scope: z.literal('global'),
});

export function registerLeaderboardRoutes(app: FastifyInstance): void {
  app.get('/leaderboards/coverage', async (req) => {
    const requesterId = await optionalAuth(req);
    const query = parseBody(querySchema, req.query);
    const { pg } = requireDb(app);
    return getCoverageLeaderboard(pg, query.window, requesterId, new Date());
  });
}
