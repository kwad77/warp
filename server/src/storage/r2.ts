// SPEC §6 — R2 presigned PUT via aws4fetch (SigV4 query signing). No SDK dependency.
import { AwsClient } from 'aws4fetch';
import type { Config } from '../config.js';
import { SPEC_CONSTANTS } from '../constants.js';
import { AppError } from '../errors.js';

export interface PresignedUpload {
  uploadUrl: string;
  storageKey: string;
  maxBytes: number;
  expiresInS: number;
}

export interface Storage {
  presignPut(storageKey: string, contentType: string): Promise<PresignedUpload>;
  /** HEAD the object; null when it does not exist (or the provider reports 404). SPEC §6. */
  head(storageKey: string): Promise<{ bytes: number; contentType: string } | null>;
  /**
   * GET the object's full bytes; null when it does not exist. SPEC §6 — used only for
   * pHash + pixel-dimension checks (moderation.ts), never for the presign/complete HEAD
   * validation path, which stays HEAD-only to keep upload latency low.
   */
  get(storageKey: string): Promise<Uint8Array | null>;
}

export function createR2Storage(config: Config): Storage {
  const { R2_ENDPOINT, R2_BUCKET, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY } = config;
  if (!R2_ENDPOINT || !R2_BUCKET || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY) {
    return {
      presignPut() {
        throw new AppError('service/unavailable', 'Object storage is not configured');
      },
      head() {
        throw new AppError('service/unavailable', 'Object storage is not configured');
      },
      get() {
        throw new AppError('service/unavailable', 'Object storage is not configured');
      },
    };
  }
  const client = new AwsClient({
    accessKeyId: R2_ACCESS_KEY_ID,
    secretAccessKey: R2_SECRET_ACCESS_KEY,
    service: 's3',
    region: 'auto',
  });
  return {
    async presignPut(storageKey, contentType) {
      const url = new URL(`${R2_ENDPOINT}/${R2_BUCKET}/${storageKey}`);
      url.searchParams.set('X-Amz-Expires', String(SPEC_CONSTANTS.photos.PRESIGN_TTL_S));
      const signed = await client.sign(
        new Request(url, { method: 'PUT', headers: { 'content-type': contentType } }),
        { aws: { signQuery: true } },
      );
      return {
        uploadUrl: signed.url,
        storageKey,
        maxBytes: SPEC_CONSTANTS.photos.UPLOAD_MAX_BYTES,
        expiresInS: SPEC_CONSTANTS.photos.PRESIGN_TTL_S,
      };
    },
    async head(storageKey) {
      const url = `${R2_ENDPOINT}/${R2_BUCKET}/${storageKey}`;
      const res = await client.fetch(url, { method: 'HEAD' });
      if (res.status === 404) return null;
      if (!res.ok) return null;
      return {
        bytes: Number(res.headers.get('content-length') ?? '0'),
        contentType: res.headers.get('content-type') ?? '',
      };
    },
    async get(storageKey) {
      const url = `${R2_ENDPOINT}/${R2_BUCKET}/${storageKey}`;
      const res = await client.fetch(url, { method: 'GET' });
      if (res.status === 404) return null;
      if (!res.ok) return null;
      return new Uint8Array(await res.arrayBuffer());
    },
  };
}
