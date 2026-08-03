// SPEC §20 — postcard sending v1, against real PostGIS.
import { randomUUID } from 'node:crypto';
import type { FastifyInstance } from 'fastify';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { SPEC_CONSTANTS } from '../src/constants.js';
import { type DbHandle, createDb } from '../src/db/client.js';
import { migrate } from '../src/db/migrate.js';
import { dedupeCell, h3ToBigint } from '../src/geo/h3.js';
import { uuidv7 } from '../src/lib/uuid.js';
import { devModerationProvider } from '../src/moderation/provider.js';
import type {
  TextModerationProvider,
  TextModerationVerdict,
} from '../src/moderation/text_provider.js';
import { createR2Storage } from '../src/storage/r2.js';

const url = process.env.TEST_DATABASE_URL;
const BASE_LL = { lat: 48.85, lng: 2.35 };
const RUN_SALT_M = Math.floor(Math.random() * 400_000);

function offsetLatMeters(ll: { lat: number; lng: number }, meters: number) {
  return { lat: ll.lat + meters / 111_320, lng: ll.lng };
}

class FakeTextModerationProvider implements TextModerationProvider {
  nextVerdict: TextModerationVerdict = { approved: true };
  calls: string[] = [];

  async moderate(text: string) {
    this.calls.push(text);
    return this.nextVerdict;
  }
}

describe.runIf(!!url)('postcards (SPEC §20)', () => {
  let handle: DbHandle;
  let app: FastifyInstance;
  let textModeration: FakeTextModerationProvider;

  async function makeUser(): Promise<{ headers: { authorization: string }; userId: string }> {
    const email = `pc-${randomUUID().slice(0, 12)}@example.com`;
    const { requestEmailCode } = await import('../src/auth/service.js');
    let code = '';
    await requestEmailCode(
      handle.db,
      {
        sendLoginCode: async (_e: string, c: string) => {
          code = c;
        },
      },
      email,
      new Date(),
    );
    const res = await app.inject({
      method: 'POST',
      url: '/v1/auth/email/verify',
      payload: { email, code },
    });
    return {
      headers: { authorization: `Bearer ${res.json().accessToken}` },
      userId: res.json().user.id,
    };
  }

  async function makePoi(creatorId: string, ll: { lat: number; lng: number }): Promise<string> {
    const id = uuidv7();
    await handle.pg`
      INSERT INTO pois (id, creator_id, title, category, location, h3_r9, checkin_radius_m, status)
      VALUES (${id}, ${creatorId}, 'Le Postcard Spot', 'landmark',
              ST_GeogFromText(${`SRID=4326;POINT(${ll.lng} ${ll.lat})`}),
              ${h3ToBigint(dedupeCell(ll)).toString()}, 75, 'active')`;
    return id;
  }

  async function makePhoto(
    poiId: string,
    uploaderId: string,
    moderation: 'pending' | 'approved' = 'approved',
  ): Promise<string> {
    const id = uuidv7();
    await handle.pg`
      INSERT INTO photos (id, poi_id, uploader_id, storage_key, source, moderation)
      VALUES (${id}, ${poiId}, ${uploaderId}, ${`photos/${poiId}/${id}.jpg`}, 'checkin', ${moderation})`;
    return id;
  }

  async function makeCheckin(
    userId: string,
    poiId: string,
    ll: { lat: number; lng: number },
    status: 'verified' | 'pending' | 'rejected',
    photoId: string | null = null,
  ): Promise<string> {
    const id = uuidv7();
    const cell = h3ToBigint(dedupeCell(ll)).toString();
    await handle.pg`
      INSERT INTO checkins (id, user_id, poi_id, mode, photo_id, status, h3_r7, evidence, verified_at)
      VALUES (${id}, ${userId}, ${poiId}, ${photoId ? 'photo' : 'confirm'}, ${photoId}, ${status},
              ${cell}, 'live', ${status === 'verified' ? new Date().toISOString() : null})`;
    return id;
  }

  beforeAll(async () => {
    await migrate(url as string, () => {});
    handle = createDb(url as string);
    textModeration = new FakeTextModerationProvider();
    const config = loadConfig({
      JWT_SECRET: 'test-secret-that-is-at-least-32-chars!!',
      NODE_ENV: 'test',
      DATABASE_URL: url,
    });
    app = buildApp({
      config,
      dbHandle: handle,
      storage: createR2Storage(config),
      moderation: devModerationProvider(() => {}),
      textModeration,
      oidcVerifiers: { apple: null, google: null },
    });
  });
  afterAll(async () => {
    await app.close();
    await handle.close();
  });

  it('sends a postcard from a verified check-in; the public page renders it, no auth needed', async () => {
    const sender = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M);
    const poiId = await makePoi(sender.userId, ll);
    const checkinId = await makeCheckin(sender.userId, poiId, ll, 'verified');

    const send = await app.inject({
      method: 'POST',
      url: `/v1/checkins/${checkinId}/postcards`,
      headers: sender.headers,
      payload: { message: 'Wish you were here!' },
    });
    expect(send.statusCode).toBe(201);
    const { postcard } = send.json();
    expect(postcard.token).toBeTruthy();
    expect(postcard.url).toContain(`/v1/postcards/${postcard.token}`);

    const view = await app.inject({ method: 'GET', url: `/v1/postcards/${postcard.token}` });
    expect(view.statusCode).toBe(200);
    expect(view.headers['content-type']).toContain('text/html');
    expect(view.body).toContain('Le Postcard Spot');
    expect(view.body).toContain('Wish you were here!');
  });

  it("prefers the check-in's own approved photo over the POI gallery, credits the photographer", async () => {
    const sender = await makeUser();
    const photographer = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 5_000);
    const poiId = await makePoi(sender.userId, ll);
    // A gallery photo from someone else — should be shadowed by the check-in's own photo.
    await makePhoto(poiId, photographer.userId, 'approved');
    const ownPhotoId = await makePhoto(poiId, sender.userId, 'approved');
    const checkinId = await makeCheckin(sender.userId, poiId, ll, 'verified', ownPhotoId);

    const send = await app.inject({
      method: 'POST',
      url: `/v1/checkins/${checkinId}/postcards`,
      headers: sender.headers,
      payload: {},
    });
    const view = await app.inject({
      method: 'GET',
      url: `/v1/postcards/${send.json().postcard.token}`,
    });
    // Own photo used, uploader === sender, so no separate "Photo by" credit line.
    expect(view.body).not.toContain('Photo by');
  });

  it('falls back to the POI gallery best photo when the check-in has none, credits that photographer', async () => {
    const sender = await makeUser();
    const photographer = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 10_000);
    const poiId = await makePoi(sender.userId, ll);
    await makePhoto(poiId, photographer.userId, 'approved');
    const checkinId = await makeCheckin(sender.userId, poiId, ll, 'verified'); // confirm mode, no photo

    const send = await app.inject({
      method: 'POST',
      url: `/v1/checkins/${checkinId}/postcards`,
      headers: sender.headers,
      payload: {},
    });
    const view = await app.inject({
      method: 'GET',
      url: `/v1/postcards/${send.json().postcard.token}`,
    });
    expect(view.body).toContain('Photo by');
  });

  it('a rejected message is not rendered, but the send still succeeds', async () => {
    const sender = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 15_000);
    const poiId = await makePoi(sender.userId, ll);
    const checkinId = await makeCheckin(sender.userId, poiId, ll, 'verified');

    textModeration.nextVerdict = { approved: false };
    const send = await app.inject({
      method: 'POST',
      url: `/v1/checkins/${checkinId}/postcards`,
      headers: sender.headers,
      payload: { message: 'this message gets rejected' },
    });
    expect(send.statusCode).toBe(201);
    textModeration.nextVerdict = { approved: true };

    const view = await app.inject({
      method: 'GET',
      url: `/v1/postcards/${send.json().postcard.token}`,
    });
    expect(view.statusCode).toBe(200);
    expect(view.body).not.toContain('this message gets rejected');
  });

  it("someone else's check-in, or a pending/rejected one, → 404 resource/not_found", async () => {
    const owner = await makeUser();
    const other = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 20_000);
    const poiId = await makePoi(owner.userId, ll);
    const verifiedCheckin = await makeCheckin(owner.userId, poiId, ll, 'verified');
    // A separate POI: checkins_user_poi_active (migration 0001) allows only one
    // non-rejected checkin per (user, poi), so the pending fixture needs its own POI.
    const otherPoiId = await makePoi(owner.userId, offsetLatMeters(ll, 500));
    const pendingCheckin = await makeCheckin(owner.userId, otherPoiId, ll, 'pending');

    const notOwner = await app.inject({
      method: 'POST',
      url: `/v1/checkins/${verifiedCheckin}/postcards`,
      headers: other.headers,
      payload: {},
    });
    expect(notOwner.statusCode).toBe(404);
    expect(notOwner.json().error.code).toBe('resource/not_found');

    const notVerified = await app.inject({
      method: 'POST',
      url: `/v1/checkins/${pendingCheckin}/postcards`,
      headers: owner.headers,
      payload: {},
    });
    expect(notVerified.statusCode).toBe(404);
  });

  it('revoke: DELETE by the sender makes the page 404 HTML; a non-owner revoke → resource/not_found', async () => {
    const sender = await makeUser();
    const other = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 25_000);
    const poiId = await makePoi(sender.userId, ll);
    const checkinId = await makeCheckin(sender.userId, poiId, ll, 'verified');
    const send = await app.inject({
      method: 'POST',
      url: `/v1/checkins/${checkinId}/postcards`,
      headers: sender.headers,
      payload: {},
    });
    const { id: postcardId, token } = send.json().postcard;

    const revokeByOther = await app.inject({
      method: 'DELETE',
      url: `/v1/postcards/${postcardId}`,
      headers: other.headers,
    });
    expect(revokeByOther.statusCode).toBe(404);

    const revoke = await app.inject({
      method: 'DELETE',
      url: `/v1/postcards/${postcardId}`,
      headers: sender.headers,
    });
    expect(revoke.statusCode).toBe(200);
    expect(revoke.json().ok).toBe(true);

    const view = await app.inject({ method: 'GET', url: `/v1/postcards/${token}` });
    expect(view.statusCode).toBe(404);
    expect(view.headers['content-type']).toContain('text/html');
  });

  it('unknown token → 404 HTML; unauthenticated revoke → 401 auth/missing', async () => {
    const view = await app.inject({ method: 'GET', url: '/v1/postcards/no-such-token' });
    expect(view.statusCode).toBe(404);
    expect(view.headers['content-type']).toContain('text/html');

    const revoke = await app.inject({ method: 'DELETE', url: `/v1/postcards/${uuidv7()}` });
    expect(revoke.statusCode).toBe(401);
    expect(revoke.json().error.code).toBe('auth/missing');
  });

  it('rate limit: the 21st postcard sent today → 429 rate/limited', async () => {
    const sender = await makeUser();
    const ll = offsetLatMeters(BASE_LL, RUN_SALT_M + 30_000);
    const poiId = await makePoi(sender.userId, ll);
    const checkinId = await makeCheckin(sender.userId, poiId, ll, 'verified');

    let last: Awaited<ReturnType<typeof app.inject>> | undefined;
    for (let i = 0; i < 21; i++) {
      last = await app.inject({
        method: 'POST',
        url: `/v1/checkins/${checkinId}/postcards`,
        headers: sender.headers,
        payload: {},
      });
    }
    expect(last?.statusCode).toBe(429);
    expect(last?.json().error.code).toBe('rate/limited');
  });
});
