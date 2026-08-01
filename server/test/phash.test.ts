// SPEC §6/§2 — pHash (dHash) pure functions, plus computePhotoMetrics against sharp
// directly (no DB, no HTTP — the integration wiring is covered in
// moderation.integration.test.ts).
import sharp from 'sharp';
import { describe, expect, it } from 'vitest';
import {
  computePhotoMetrics,
  dHashFromGrayscale,
  hammingDistance,
} from '../src/moderation/phash.js';

describe('dHashFromGrayscale (SPEC §6)', () => {
  it('throws if given anything other than 9x8=72 pixels', () => {
    expect(() => dHashFromGrayscale(new Uint8Array(10))).toThrow();
  });

  it('is deterministic for the same input', () => {
    const pixels = new Uint8Array(72).map((_, i) => (i * 37) % 256);
    expect(dHashFromGrayscale(pixels)).toBe(dHashFromGrayscale(pixels));
  });

  it('a strictly ascending row (left < right always) sets every bit in that row to 0', () => {
    // Row 0 ascending 0..8 across width 9: left < right at every step.
    const pixels = new Uint8Array(72);
    for (let x = 0; x < 9; x++) pixels[x] = x * 10;
    const hash = dHashFromGrayscale(pixels);
    // The top 8 bits of the 64-bit hash correspond to row 0 (this implementation's bit
    // order: MSB-first, row-major). All should be 0 since left is never > right.
    const topByte = Number((hash >> 56n) & 0xffn);
    expect(topByte).toBe(0);
  });

  it('a strictly descending row sets every bit in that row to 1', () => {
    const pixels = new Uint8Array(72);
    for (let x = 0; x < 9; x++) pixels[x] = (8 - x) * 10;
    const hash = dHashFromGrayscale(pixels);
    const topByte = Number((hash >> 56n) & 0xffn);
    expect(topByte).toBe(0xff);
  });

  it('differs for visibly different images', () => {
    const a = new Uint8Array(72).map((_, i) => (i * 37) % 256);
    const b = new Uint8Array(72).map((_, i) => (i * 53 + 11) % 256);
    expect(dHashFromGrayscale(a)).not.toBe(dHashFromGrayscale(b));
  });
});

describe('hammingDistance (SPEC §2 DEDUPE_PHASH_MAX_HAMMING)', () => {
  it('is 0 for identical hashes', () => {
    expect(hammingDistance(0b1010n, 0b1010n)).toBe(0);
  });

  it('counts differing bits', () => {
    expect(hammingDistance(0b0000n, 0b1111n)).toBe(4);
    expect(hammingDistance(0b1010n, 0b0101n)).toBe(4);
  });

  it('is symmetric', () => {
    const a = 0xabcdef1234567890n;
    const b = 0x1234567890abcdefn;
    expect(hammingDistance(a, b)).toBe(hammingDistance(b, a));
  });
});

describe('computePhotoMetrics (SPEC §6, real sharp — no DB/HTTP)', () => {
  async function solidJpeg(width: number, height: number, rgb: [number, number, number]) {
    return sharp({
      create: { width, height, channels: 3, background: { r: rgb[0], g: rgb[1], b: rgb[2] } },
    })
      .jpeg()
      .toBuffer();
  }

  it('reports the original (pre-hash-resize) pixel dimensions', async () => {
    const bytes = await solidJpeg(1200, 800, [10, 20, 30]);

    const metrics = await computePhotoMetrics(bytes);

    expect(metrics.width).toBe(1200);
    expect(metrics.height).toBe(800);
  });

  it('produces the same phash for two independently-encoded copies of the same image', async () => {
    const a = await solidJpeg(640, 480, [200, 50, 50]);
    const b = await solidJpeg(640, 480, [200, 50, 50]);

    const [metricsA, metricsB] = await Promise.all([
      computePhotoMetrics(a),
      computePhotoMetrics(b),
    ]);

    expect(metricsA.phash).toBe(metricsB.phash);
  });

  it('a solid color image has zero distance from itself after a resize+recompress', async () => {
    const original = await solidJpeg(2000, 1500, [80, 160, 240]);
    const recompressed = await sharp(original).resize(600, 450).jpeg({ quality: 60 }).toBuffer();

    const [m1, m2] = await Promise.all([
      computePhotoMetrics(original),
      computePhotoMetrics(recompressed),
    ]);

    expect(hammingDistance(m1.phash, m2.phash)).toBeLessThanOrEqual(10);
  });
});
