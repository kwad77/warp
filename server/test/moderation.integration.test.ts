// SPEC §6 — applyModerationVerdict / runModerationForPhoto against real PostGIS, isolated
// from the HTTP layer (route-level wiring is covered in test/pois.integration.test.ts).
import { randomUUID } from 'node:crypto';
import sharp from 'sharp';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { type DbHandle, createDb } from '../src/db/client.js';
import { migrate } from '../src/db/migrate.js';
import { dedupeCell, h3ToBigint } from '../src/geo/h3.js';
import { uuidv7 } from '../src/lib/uuid.js';
import type { ModerationProvider, ModerationVerdict } from '../src/moderation/provider.js';
import { applyModerationVerdict, runModerationForPhoto } from '../src/moderation/service.js';
import type { Storage } from '../src/storage/r2.js';

/** Minimal fake — only `get` matters here; the other methods aren't exercised. */
class FakeStorage implements Storage {
  getResult: Uint8Array | null = null;

  async presignPut(storageKey: string): Promise<never> {
    throw new Error('not used in this suite');
  }

  async head(): Promise<null> {
    return null;
  }

  async get(_storageKey: string) {
    return this.getResult;
  }
}

async function fakeJpeg(width: number, height: number): Promise<Uint8Array> {
  return sharp({
    create: { width, height, channels: 3, background: { r: 100, g: 150, b: 200 } },
  })
    .jpeg()
    .toBuffer();
}

const url = process.env.TEST_DATABASE_URL;
const POI_LL = { lat: 20.0, lng: -60.0 };

function offsetLatMeters(ll: { lat: number; lng: number }, meters: number) {
  return { lat: ll.lat + meters / 111_320, lng: ll.lng };
}

describe.runIf(!!url)('moderation service (SPEC §6)', () => {
  let handle: DbHandle;

  async function makeUser(): Promise<string> {
    const id = uuidv7();
    await handle.pg`INSERT INTO users (id, handle) VALUES (${id}, ${`mod_${randomUUID().slice(0, 8)}`})`;
    return id;
  }

  async function makePendingPhoto(userId: string, salt: number): Promise<string> {
    const ll = offsetLatMeters(POI_LL, salt);
    const poiId = uuidv7();
    await handle.pg`
      INSERT INTO pois (id, creator_id, title, category, location, h3_r9, checkin_radius_m, status)
      VALUES (${poiId}, ${userId}, 'x', 'landmark',
              ST_GeogFromText(${`SRID=4326;POINT(${ll.lng} ${ll.lat})`}),
              ${h3ToBigint(dedupeCell(ll)).toString()}, 75, 'active')`;
    const photoId = uuidv7();
    await handle.pg`
      INSERT INTO photos (id, poi_id, uploader_id, storage_key, source, moderation)
      VALUES (${photoId}, ${poiId}, ${userId}, ${`photos/${poiId}/${photoId}.jpg`}, 'poi_creation', 'pending')`;
    return photoId;
  }

  beforeAll(async () => {
    await migrate(url as string, () => {});
    handle = createDb(url as string);
  });
  afterAll(async () => {
    await handle.close();
  });

  it('applyModerationVerdict: approved sets moderation, leaves rejection_reason null', async () => {
    const u = await makeUser();
    const photoId = await makePendingPhoto(u, 1_000);
    await applyModerationVerdict(handle.pg, photoId, { outcome: 'approved' });
    const row =
      await handle.pg`SELECT moderation, rejection_reason FROM photos WHERE id = ${photoId}`;
    expect(row[0]).toMatchObject({ moderation: 'approved', rejection_reason: null });
  });

  it('applyModerationVerdict: rejected sets both moderation and reason', async () => {
    const u = await makeUser();
    const photoId = await makePendingPhoto(u, 2_000);
    await applyModerationVerdict(handle.pg, photoId, { outcome: 'rejected', reason: 'unsafe' });
    const row =
      await handle.pg`SELECT moderation, rejection_reason FROM photos WHERE id = ${photoId}`;
    expect(row[0]).toMatchObject({ moderation: 'rejected', rejection_reason: 'unsafe' });
  });

  it('applyModerationVerdict: escalated sets moderation, no reason', async () => {
    const u = await makeUser();
    const photoId = await makePendingPhoto(u, 3_000);
    await applyModerationVerdict(handle.pg, photoId, { outcome: 'escalated' });
    const row =
      await handle.pg`SELECT moderation, rejection_reason FROM photos WHERE id = ${photoId}`;
    expect(row[0]).toMatchObject({ moderation: 'escalated', rejection_reason: null });
  });

  it('runModerationForPhoto: calls the provider with (photoId, storageKey) and applies its verdict', async () => {
    const u = await makeUser();
    const photoId = await makePendingPhoto(u, 4_000);
    const keyRows = await handle.pg`SELECT storage_key FROM photos WHERE id = ${photoId}`;
    const storageKey = keyRows[0]?.storage_key as string;

    const seen: { photoId: string; storageKey: string }[] = [];
    const provider: ModerationProvider = {
      async moderate(input) {
        seen.push(input);
        return { outcome: 'rejected', reason: 'quality' } satisfies ModerationVerdict;
      },
    };
    const storage = new FakeStorage();
    const verdict = await runModerationForPhoto(provider, storage, handle.pg, photoId, storageKey);
    expect(verdict).toEqual({ outcome: 'rejected', reason: 'quality' });
    expect(seen).toEqual([{ photoId, storageKey }]);
    const row = await handle.pg`SELECT moderation FROM photos WHERE id = ${photoId}`;
    expect(row[0]?.moderation).toBe('rejected');
  });

  it('runModerationForPhoto: no bytes available (storage.get returns null) skips metrics, still runs the provider', async () => {
    const u = await makeUser();
    const photoId = await makePendingPhoto(u, 5_000);
    const keyRows = await handle.pg`SELECT storage_key FROM photos WHERE id = ${photoId}`;
    const storageKey = keyRows[0]?.storage_key as string;
    const provider: ModerationProvider = {
      async moderate() {
        return { outcome: 'approved' };
      },
    };
    const storage = new FakeStorage();
    storage.getResult = null;

    const verdict = await runModerationForPhoto(provider, storage, handle.pg, photoId, storageKey);

    expect(verdict).toEqual({ outcome: 'approved' });
    const row = await handle.pg`SELECT width, height, phash FROM photos WHERE id = ${photoId}`;
    expect(row[0]).toMatchObject({ width: null, height: null, phash: null });
  });

  it('runModerationForPhoto: a genuinely small photo is rejected(quality) before the provider runs', async () => {
    const u = await makeUser();
    const photoId = await makePendingPhoto(u, 6_000);
    const keyRows = await handle.pg`SELECT storage_key FROM photos WHERE id = ${photoId}`;
    const storageKey = keyRows[0]?.storage_key as string;
    let providerCalled = false;
    const provider: ModerationProvider = {
      async moderate() {
        providerCalled = true;
        return { outcome: 'approved' };
      },
    };
    const storage = new FakeStorage();
    storage.getResult = await fakeJpeg(200, 150); // long edge 200 < UPLOAD_MIN_LONG_EDGE_PX (1024)

    const verdict = await runModerationForPhoto(provider, storage, handle.pg, photoId, storageKey);

    expect(verdict).toEqual({ outcome: 'rejected', reason: 'quality' });
    expect(providerCalled).toBe(false);
    const row =
      await handle.pg`SELECT moderation, rejection_reason, width, height, phash FROM photos WHERE id = ${photoId}`;
    expect(row[0]).toMatchObject({ moderation: 'rejected', rejection_reason: 'quality' });
    expect(row[0]?.width).toBe(200);
    expect(row[0]?.height).toBe(150);
    expect(row[0]?.phash).not.toBeNull();
  });

  it('runModerationForPhoto: a properly sized photo gets width/height/phash populated and still runs the provider', async () => {
    const u = await makeUser();
    const photoId = await makePendingPhoto(u, 7_000);
    const keyRows = await handle.pg`SELECT storage_key FROM photos WHERE id = ${photoId}`;
    const storageKey = keyRows[0]?.storage_key as string;
    let providerCalled = false;
    const provider: ModerationProvider = {
      async moderate() {
        providerCalled = true;
        return { outcome: 'approved' };
      },
    };
    const storage = new FakeStorage();
    storage.getResult = await fakeJpeg(1200, 900);

    const verdict = await runModerationForPhoto(provider, storage, handle.pg, photoId, storageKey);

    expect(verdict).toEqual({ outcome: 'approved' });
    expect(providerCalled).toBe(true);
    const row = await handle.pg`SELECT width, height, phash FROM photos WHERE id = ${photoId}`;
    expect(row[0]).toMatchObject({ width: 1200, height: 900 });
    expect(row[0]?.phash).not.toBeNull();
  });
});
