// SPEC §5, §7 — check-in endpoints. Thin: parse → service → serialize.
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { parseBody, requireAuth, requireDb } from '../app.js';
import { createIntent, getCheckin, submitCheckin } from '../checkins/service.js';
import { SPEC_CONSTANTS } from '../constants.js';
import { AppError } from '../errors.js';
import { createIntegrityVerifier } from '../verification/integrity.js';

const P = SPEC_CONSTANTS.presence;

const intentSchema = z.object({
  poiId: z.string().uuid(),
  deviceId: z.string().uuid(),
});

const fixSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  accuracyM: z.number().min(0).max(10_000),
  capturedAt: z.string().datetime(),
});

const submitSchema = z.object({
  nonce: z.string().min(16).max(128),
  poiId: z.string().uuid(),
  mode: z.enum(['photo', 'confirm']),
  fixes: z.array(fixSchema).min(P.MIN_FIXES).max(P.MAX_FIXES),
  integrityToken: z.string().min(1).max(8192),
  evidence: z.enum(['live', 'deferred']).default('live'),
  capture: z
    .object({
      token: z.string().regex(/^[0-9a-f]{64}$/),
      capturedAt: z.string().datetime(),
      storageKey: z.string().min(1).max(512),
    })
    .optional(),
});

export function registerCheckinRoutes(app: FastifyInstance): void {
  const verifier = createIntegrityVerifier(app.deps.config.NODE_ENV);

  app.post('/checkins/intent', async (req) => {
    const userId = await requireAuth(req);
    const body = parseBody(intentSchema, req.body);
    const { db, pg } = requireDb(app);
    return createIntent(db, pg, userId, body.poiId, body.deviceId, new Date());
  });

  app.post('/checkins', async (req, reply) => {
    const userId = await requireAuth(req);
    const body = parseBody(submitSchema, req.body);
    if (body.mode === 'photo' && !body.capture) {
      throw new AppError('request/invalid', 'Photo mode requires capture', {
        issues: [{ path: 'capture', message: 'Required for photo mode' }],
      });
    }
    const { db, pg } = requireDb(app);
    const input = {
      nonce: body.nonce,
      poiId: body.poiId,
      mode: body.mode,
      fixes: body.fixes,
      integrityToken: body.integrityToken,
      evidence: body.evidence,
      ...(body.capture ? { capture: body.capture } : {}),
    };
    const checkin = await submitCheckin(db, pg, verifier, userId, input, new Date());
    return reply.status(201).send({ checkin });
  });

  app.get('/checkins/:id', async (req) => {
    const userId = await requireAuth(req);
    const params = parseBody(z.object({ id: z.string().uuid() }), req.params);
    const { db } = requireDb(app);
    return { checkin: await getCheckin(db, userId, params.id) };
  });
}
