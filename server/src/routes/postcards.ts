// SPEC §20 — the unlisted public postcard view + revocation. GET /postcards/:token is a
// deliberate carve-out from §3's "every non-2xx response is the JSON envelope" rule: a
// plain browser opens this link directly, so both success and not-found render HTML.
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { parseBody, requireAuth, requireDb } from '../app.js';
import { renderPostcardHtml, renderPostcardNotFoundHtml } from '../postcards/render.js';
import { getPostcardForRender, revokePostcard } from '../postcards/service.js';

const tokenParamsSchema = z.object({ token: z.string().min(1) });
const idParamsSchema = z.object({ id: z.string().uuid() });

export function registerPostcardRoutes(app: FastifyInstance): void {
  app.get('/postcards/:token', async (req, reply) => {
    const params = parseBody(tokenParamsSchema, req.params);
    const { pg } = requireDb(app);
    const view = await getPostcardForRender(pg, params.token);
    if (!view) {
      return reply.code(404).type('text/html').send(renderPostcardNotFoundHtml());
    }
    const { PUBLIC_BASE_URL, APP_STORE_URL, PLAY_STORE_URL } = app.deps.config;
    return reply.type('text/html').send(
      renderPostcardHtml(view, {
        publicBaseUrl: PUBLIC_BASE_URL,
        appStoreUrl: APP_STORE_URL,
        playStoreUrl: PLAY_STORE_URL,
      }),
    );
  });

  app.delete('/postcards/:id', async (req) => {
    const userId = await requireAuth(req);
    const params = parseBody(idParamsSchema, req.params);
    const { pg } = requireDb(app);
    await revokePostcard(pg, userId, params.id, new Date());
    return { ok: true };
  });
}
