import Fastify, { type FastifyInstance, type FastifyRequest } from 'fastify';
import type { z } from 'zod';
import { verifyAccessToken } from './auth/tokens.js';
import type { Config } from './config.js';
import type { DbHandle } from './db/client.js';
import { AppError } from './errors.js';
import { registerAuthRoutes } from './routes/auth.js';
import { registerCheckinRoutes } from './routes/checkins.js';
import { registerDeviceRoutes } from './routes/devices.js';
import { registerPoiRoutes } from './routes/pois.js';
import type { Storage } from './storage/r2.js';

export const APP_VERSION = '0.1.0';

export interface AppDeps {
  config: Config;
  dbHandle: DbHandle | null;
  storage: Storage;
}

declare module 'fastify' {
  interface FastifyRequest {
    userId: string | null;
  }
  interface FastifyInstance {
    deps: AppDeps;
  }
}

/** Throws the SPEC §3 envelope for zod failures; returns typed data otherwise. */
export function parseBody<S extends z.ZodTypeAny>(schema: S, body: unknown): z.infer<S> {
  const result = schema.safeParse(body);
  if (!result.success) {
    throw new AppError('request/invalid', 'Request validation failed', {
      issues: result.error.issues.map((i) => ({ path: i.path.join('.'), message: i.message })),
    });
  }
  return result.data;
}

/** Auth guard for ✅ endpoints. 🌐 endpoints simply don't use it. SPEC §7. */
export async function requireAuth(req: FastifyRequest): Promise<string> {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    throw new AppError('auth/missing', 'Authorization header required');
  }
  const claims = await verifyAccessToken(req.server.deps.config.JWT_SECRET, header.slice(7));
  req.userId = claims.sub;
  return claims.sub;
}

export function buildApp(deps: AppDeps): FastifyInstance {
  const app = Fastify({
    logger: {
      level: deps.config.NODE_ENV === 'test' ? 'silent' : 'info',
      // SPEC §9: no emails, tokens, or precise coordinates in logs.
      redact: ['req.headers.authorization', 'req.body.email', 'req.body.refreshToken'],
    },
  });

  app.decorate('deps', deps);
  app.decorateRequest('userId', null);

  app.setErrorHandler((err, req, reply) => {
    if (err instanceof AppError) {
      if (err.code === 'internal/error') req.log.error({ err }, 'internal error');
      return reply.status(err.status).send(err.toBody());
    }
    // Fastify's own 4xx (bad JSON, oversized body) → request/invalid; everything else is 500.
    const e = err as { statusCode?: unknown; message?: unknown };
    const clientError = typeof e.statusCode === 'number' && e.statusCode < 500;
    if (!clientError) {
      req.log.error({ err }, 'unhandled error');
      return reply
        .status(500)
        .send(new AppError('internal/error', 'Internal server error').toBody());
    }
    const message = typeof e.message === 'string' ? e.message : 'Bad request';
    return reply.status(400).send(new AppError('request/invalid', message).toBody());
  });

  app.setNotFoundHandler((_req, reply) =>
    reply.status(404).send(new AppError('resource/not_found', 'No such route').toBody()),
  );

  // Health endpoints live at the root (infra convention); product API under /v1. SPEC §7.
  app.get('/healthz', async () => ({ ok: true, version: APP_VERSION }));
  app.get('/readyz', async (_req, reply) => {
    if (!deps.dbHandle) {
      return reply
        .status(503)
        .send(new AppError('service/unavailable', 'Database not configured').toBody());
    }
    try {
      await deps.dbHandle.pg`SELECT 1`;
      return { ok: true };
    } catch {
      return reply
        .status(503)
        .send(new AppError('service/unavailable', 'Database unreachable').toBody());
    }
  });

  app.register(
    async (v1) => {
      registerAuthRoutes(v1);
      registerDeviceRoutes(v1);
      registerCheckinRoutes(v1);
      registerPoiRoutes(v1);
    },
    { prefix: '/v1' },
  );

  return app;
}

/** For routes that need the DB: 503 when the server is running without one. */
export function requireDb(app: FastifyInstance): DbHandle {
  const handle = app.deps.dbHandle;
  if (!handle) throw new AppError('service/unavailable', 'Database not configured');
  return handle;
}
