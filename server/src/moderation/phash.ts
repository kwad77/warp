// SPEC §6/§2 — pHash (64-bit) + the pixel-dimension check, both deferred pending "the
// actual image bytes (a GET, not just the HEAD used for validation) plus pixel processing
// (sharp, already allowlisted)". sharp being pre-approved means this needed no new
// dependency decision — only the Rekognition detector and the admin surface remain
// genuinely blocked (SPEC §6 M1 note).
//
// Implemented as a difference hash (dHash): resize to 9x8 grayscale, one bit per
// horizontal adjacent-pixel comparison (8 comparisons/row × 8 rows = 64 bits). This is a
// well-known DCT-free 64-bit perceptual hash, robust to minor resize/recompression —
// exactly what DEDUPE_PHASH_MAX_HAMMING (§2) is meant to tolerate. Called out explicitly
// because "pHash" more narrowly refers to a DCT-based algorithm elsewhere; no DCT library
// is allowlisted, and dHash serves the same purpose here.
import sharp from 'sharp';

const HASH_WIDTH = 9;
const HASH_HEIGHT = 8;

/** Pure: 64-bit dHash from a 9x8 grayscale pixel buffer (row-major, 1 byte/pixel). */
export function dHashFromGrayscale(pixels: Uint8Array): bigint {
  if (pixels.length !== HASH_WIDTH * HASH_HEIGHT) {
    throw new Error(`Expected ${HASH_WIDTH * HASH_HEIGHT} pixels, got ${pixels.length}`);
  }
  let hash = 0n;
  for (let y = 0; y < HASH_HEIGHT; y++) {
    for (let x = 0; x < HASH_WIDTH - 1; x++) {
      const left = pixels[y * HASH_WIDTH + x] as number;
      const right = pixels[y * HASH_WIDTH + x + 1] as number;
      hash = (hash << 1n) | (left > right ? 1n : 0n);
    }
  }
  return hash;
}

/** Pure: Hamming distance between two hashes — compared against DEDUPE_PHASH_MAX_HAMMING. */
export function hammingDistance(a: bigint, b: bigint): number {
  let x = a ^ b;
  let count = 0;
  while (x !== 0n) {
    count += Number(x & 1n);
    x >>= 1n;
  }
  return count;
}

export interface PhotoMetrics {
  width: number;
  height: number;
  phash: bigint;
}

/** Impure: decodes the real bytes via sharp. Original dimensions + the dHash. */
export async function computePhotoMetrics(bytes: Uint8Array): Promise<PhotoMetrics> {
  const metadata = await sharp(bytes).metadata();
  const { data } = await sharp(bytes)
    .resize(HASH_WIDTH, HASH_HEIGHT, { fit: 'fill' })
    .grayscale()
    .raw()
    .toBuffer({ resolveWithObject: true });
  return {
    width: metadata.width ?? 0,
    height: metadata.height ?? 0,
    phash: dHashFromGrayscale(data),
  };
}
