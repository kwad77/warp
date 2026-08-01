// SPEC §6 — moderation provider seam. Provider unit tests are pure; DB application is
// covered against real PostGIS in test/moderation.integration.test.ts.
import { describe, expect, it, vi } from 'vitest';
import {
  createModerationProvider,
  devModerationProvider,
  rekognitionModerationProvider,
} from '../src/moderation/provider.js';

describe('devModerationProvider', () => {
  it('always approves and logs a line naming the photo', async () => {
    const lines: string[] = [];
    const provider = devModerationProvider((msg) => lines.push(msg));
    const verdict = await provider.moderate({ photoId: 'p1', storageKey: 'photos/x/p1.jpg' });
    expect(verdict).toEqual({ outcome: 'approved' });
    expect(lines).toHaveLength(1);
    expect(lines[0]).toContain('p1');
  });
});

describe('rekognitionModerationProvider', () => {
  it('is a named seam, not a working integration — selecting it is a 501, not a crash', async () => {
    const provider = rekognitionModerationProvider();
    await expect(provider.moderate({ photoId: 'p1', storageKey: 'x' })).rejects.toMatchObject({
      code: 'service/unavailable',
    });
  });
});

describe('createModerationProvider', () => {
  it('defaults to dev semantics; rekognition selection reaches the stub', async () => {
    const log = vi.fn();
    const dev = createModerationProvider('dev', log);
    await expect(dev.moderate({ photoId: 'a', storageKey: 'b' })).resolves.toEqual({
      outcome: 'approved',
    });

    const rekognition = createModerationProvider('rekognition', log);
    await expect(rekognition.moderate({ photoId: 'a', storageKey: 'b' })).rejects.toMatchObject({
      code: 'service/unavailable',
    });
  });
});
