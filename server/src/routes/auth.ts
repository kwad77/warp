// SPEC §4, §7 — auth endpoints. Apple/Google land in M1 step 4 (501 until then).
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { parseBody, requireDb } from '../app.js';
import {
  devMailSender,
  requestEmailCode,
  rotateRefreshToken,
  verifyEmailCode,
} from '../auth/service.js';
import { notImplemented } from '../errors.js';

const emailSchema = z.object({ email: z.string().email().max(254).toLowerCase() });
const verifySchema = emailSchema.extend({ code: z.string().regex(/^\d{6}$/) });
const refreshSchema = z.object({ refreshToken: z.string().min(1) });

export function registerAuthRoutes(app: FastifyInstance): void {
  const mail = devMailSender((msg) => app.log.info(msg));

  app.post('/auth/email/request', async (req) => {
    const { email } = parseBody(emailSchema, req.body);
    const { db } = requireDb(app);
    // Always 200 regardless of account existence — no enumeration. SPEC §7.
    await requestEmailCode(db, mail, email, new Date());
    return { ok: true };
  });

  app.post('/auth/email/verify', async (req, reply) => {
    const { email, code } = parseBody(verifySchema, req.body);
    const { db } = requireDb(app);
    const { tokens, user } = await verifyEmailCode(
      db,
      app.deps.config.JWT_SECRET,
      email,
      code,
      new Date(),
    );
    return reply.status(200).send({ ...tokens, user });
  });

  app.post('/auth/refresh', async (req) => {
    const { refreshToken } = parseBody(refreshSchema, req.body);
    const { db } = requireDb(app);
    return rotateRefreshToken(db, app.deps.config.JWT_SECRET, refreshToken, new Date());
  });

  app.post('/auth/apple', async () => {
    throw notImplemented('Sign in with Apple');
  });

  app.post('/auth/google', async () => {
    throw notImplemented('Google sign-in');
  });
}
