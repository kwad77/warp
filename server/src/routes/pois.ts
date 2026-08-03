// SPEC §7 — POI discovery/creation and photo presign/complete. Thin: parse → service → serialize.
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { optionalAuth, parseBody, requireAuth, requireDb } from '../app.js';
import { POI_CATEGORIES, type PoiCategory, SPEC_CONSTANTS } from '../constants.js';
import {
  completePhoto,
  createPoi,
  getPoiById,
  listNearby,
  listPois,
  parseBbox,
  presignPhoto,
  setSavedPoi,
} from '../pois/service.js';

const categorySchema = z.enum(POI_CATEGORIES as [PoiCategory, ...PoiCategory[]]);
const mimeSchema = z.enum(SPEC_CONSTANTS.photos.ALLOWED_MIME);
const sourceSchema = z.enum(['poi_creation', 'checkin']);

const idParamsSchema = z.object({ id: z.string().uuid() });
const saveSchema = z.object({ value: z.union([z.literal(0), z.literal(1)]) });

const poisQuerySchema = z.object({
  bbox: z.string(),
  zoom: z.coerce.number().int().min(0).max(22),
});

const nearbyQuerySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lng: z.coerce.number().min(-180).max(180),
  radiusM: z.coerce.number().min(1).max(10_000).optional(),
});

/** SPEC §11: length limits count Unicode code points, not UTF-16 units. */
function codePointLength(s: string): number {
  return [...s].length;
}

const titleSchema = z.string().refine((t) => codePointLength(t) >= 3 && codePointLength(t) <= 80, {
  message: 'title must be 3..80 Unicode code points',
});

const descriptionSchema = z
  .string()
  .refine((t) => codePointLength(t) <= 280, {
    message: 'description must be at most 280 Unicode code points',
  })
  .optional();

const latLngSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

const gpsFixSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  accuracyM: z.number().min(0).max(10_000),
  capturedAt: z.string().datetime(),
});

const createPoiSchema = z.object({
  title: titleSchema,
  description: descriptionSchema,
  category: categorySchema,
  location: latLngSchema,
  gpsFix: gpsFixSchema,
  force: z.boolean().optional(),
});

const presignSchema = z.object({
  contentType: mimeSchema,
  source: sourceSchema,
});

const completeSchema = z.object({
  storageKey: z.string().min(1).max(512),
  source: sourceSchema,
});

export function registerPoiRoutes(app: FastifyInstance): void {
  app.get('/pois', async (req) => {
    const query = parseBody(poisQuerySchema, req.query);
    const bbox = parseBbox(query.bbox);
    const { pg } = requireDb(app);
    return listPois(pg, bbox, query.zoom);
  });

  app.get('/pois/nearby', async (req) => {
    const query = parseBody(nearbyQuerySchema, req.query);
    const { pg } = requireDb(app);
    return listNearby(pg, { lat: query.lat, lng: query.lng }, query.radiusM ?? 2000);
  });

  app.get('/pois/:id', async (req) => {
    const params = parseBody(idParamsSchema, req.params);
    const requesterId = await optionalAuth(req);
    const { pg } = requireDb(app);
    return { poi: await getPoiById(pg, params.id, requesterId) };
  });

  app.post('/pois', async (req, reply) => {
    const userId = await requireAuth(req);
    const body = parseBody(createPoiSchema, req.body);
    const { db, pg } = requireDb(app);
    const result = await createPoi(
      db,
      pg,
      userId,
      {
        title: body.title,
        category: body.category,
        location: body.location,
        gpsFix: body.gpsFix,
        ...(body.description !== undefined ? { description: body.description } : {}),
        ...(body.force !== undefined ? { force: body.force } : {}),
      },
      new Date(),
    );
    if ('dedupeCandidates' in result) {
      return reply.status(200).send(result);
    }
    return reply.status(201).send({ poi: result.poi });
  });

  app.post('/pois/:id/save', async (req) => {
    const userId = await requireAuth(req);
    const params = parseBody(idParamsSchema, req.params);
    const body = parseBody(saveSchema, req.body);
    const { pg } = requireDb(app);
    return setSavedPoi(pg, userId, params.id, body.value);
  });

  app.post('/pois/:id/photos/presign', async (req) => {
    await requireAuth(req);
    const params = parseBody(idParamsSchema, req.params);
    const body = parseBody(presignSchema, req.body);
    const { pg } = requireDb(app);
    return presignPhoto(app.deps.storage, pg, params.id, body.contentType, new Date());
  });

  app.post('/pois/:id/photos/complete', async (req, reply) => {
    const userId = await requireAuth(req);
    const params = parseBody(idParamsSchema, req.params);
    const body = parseBody(completeSchema, req.body);
    const { pg } = requireDb(app);
    const photo = await completePhoto(
      app.deps.storage,
      app.deps.moderation,
      pg,
      userId,
      params.id,
      body.storageKey,
      body.source,
    );
    return reply.status(201).send({ photo });
  });
}
