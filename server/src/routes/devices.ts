// SPEC §7 — device registration. Integrity attestation arrives with M1 step 2 (§5.2).
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { parseBody, requireAuth, requireDb } from '../app.js';
import { devices } from '../db/schema.js';
import { uuidv7 } from '../lib/uuid.js';

const deviceSchema = z.object({
  platform: z.enum(['ios', 'android']),
  model: z.string().max(80).optional(),
});

export function registerDeviceRoutes(app: FastifyInstance): void {
  app.post('/devices', async (req, reply) => {
    const userId = await requireAuth(req);
    const body = parseBody(deviceSchema, req.body);
    const { db } = requireDb(app);
    const id = uuidv7();
    await db.insert(devices).values({
      id,
      userId,
      platform: body.platform,
      ...(body.model !== undefined ? { model: body.model } : {}),
    });
    return reply.status(201).send({ deviceId: id });
  });
}
