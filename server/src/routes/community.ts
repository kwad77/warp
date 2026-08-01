// SPEC §7 — photo voting and reporting.
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { parseBody, requireAuth, requireDb } from '../app.js';
import { createReport, voteOnPhoto } from '../community/service.js';

const idParamsSchema = z.object({ id: z.string().uuid() });
const voteSchema = z.object({ value: z.union([z.literal(0), z.literal(1)]) });
const reportSchema = z.object({
  targetType: z.enum(['poi', 'photo']),
  targetId: z.string().uuid(),
  reason: z.enum(['people', 'unsafe', 'wrong_location', 'duplicate', 'other']),
  note: z.string().max(280).optional(),
});

export function registerCommunityRoutes(app: FastifyInstance): void {
  app.post('/photos/:id/vote', async (req) => {
    const userId = await requireAuth(req);
    const params = parseBody(idParamsSchema, req.params);
    const body = parseBody(voteSchema, req.body);
    const { pg } = requireDb(app);
    return voteOnPhoto(pg, userId, params.id, body.value);
  });

  app.post('/reports', async (req, reply) => {
    const userId = await requireAuth(req);
    const body = parseBody(reportSchema, req.body);
    const { db, pg } = requireDb(app);
    await createReport(
      db,
      pg,
      userId,
      body.targetType,
      body.targetId,
      body.reason,
      body.note,
      new Date(),
    );
    return reply.status(201).send({ ok: true });
  });
}
