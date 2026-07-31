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
}

export function createR2Storage(config: Config): Storage {
  const { R2_ENDPOINT, R2_BUCKET, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY } = config;
  if (!R2_ENDPOINT || !R2_BUCKET || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY) {
    return {
      presignPut() {
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
  };
}
