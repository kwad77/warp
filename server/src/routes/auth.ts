// SPEC §4, §7 — auth endpoints. Apple/Google verify a real platform ID token when
// APPLE_CLIENT_ID/GOOGLE_CLIENT_ID are configured; 501 service/unavailable otherwise
// (unchanged from before this was implemented — see config.ts).
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { parseBody, requireDb } from '../app.js';
import {
  devMailSender,
  loginWithProvider,
  requestEmailCode,
  rotateRefreshToken,
  verifyEmailCode,
} from '../auth/service.js';
import { notImplemented } from '../errors.js';

const emailSchema = z.object({ email: z.string().email().max(254).toLowerCase() });
const verifySchema = emailSchema.extend({ code: z.string().regex(/^\d{6}$/) });
const refreshSchema = z.object({ refreshToken: z.string().min(1) });
const idTokenSchema = z.object({ idToken: z.string().min(1) });

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

  app.post('/auth/apple', async (req, reply) => {
    const verifier = app.deps.oidcVerifiers.apple;
    if (!verifier) throw notImplemented('Sign in with Apple');
    const { idToken } = parseBody(idTokenSchema, req.body);
    const { sub } = await verifier.verify(idToken);
    const { db } = requireDb(app);
    const { tokens, user } = await loginWithProvider(
      db,
      app.deps.config.JWT_SECRET,
      'apple',
      sub,
      new Date(),
    );
    return reply.status(200).send({ ...tokens, user });
  });

  app.post('/auth/google', async (req, reply) => {
    const verifier = app.deps.oidcVerifiers.google;
    if (!verifier) throw notImplemented('Google sign-in');
    const { idToken } = parseBody(idTokenSchema, req.body);
    const { sub } = await verifier.verify(idToken);
    const { db } = requireDb(app);
    const { tokens, user } = await loginWithProvider(
      db,
      app.deps.config.JWT_SECRET,
      'google',
      sub,
      new Date(),
    );
    return reply.status(200).send({ ...tokens, user });
  });
}
