import { describe, expect, it } from 'vitest';
import { isoWeekStartUtc } from '../src/lib/isoWeek.js';

describe('isoWeekStartUtc', () => {
  it("a Wednesday rolls back to that week's Monday 00:00 UTC", () => {
    const wed = new Date('2026-08-05T15:30:00.000Z'); // Wednesday
    expect(isoWeekStartUtc(wed).toISOString()).toBe('2026-08-03T00:00:00.000Z');
  });

  it('a Monday at 00:00:00.000 UTC stays put', () => {
    const mon = new Date('2026-08-03T00:00:00.000Z');
    expect(isoWeekStartUtc(mon).toISOString()).toBe('2026-08-03T00:00:00.000Z');
  });

  it('a Monday at 23:59:59.999 UTC stays in the same week', () => {
    const mon = new Date('2026-08-03T23:59:59.999Z');
    expect(isoWeekStartUtc(mon).toISOString()).toBe('2026-08-03T00:00:00.000Z');
  });

  it('a Sunday rolls back to the PRECEDING Monday (ISO week ends Sunday)', () => {
    const sun = new Date('2026-08-09T12:00:00.000Z');
    expect(isoWeekStartUtc(sun).toISOString()).toBe('2026-08-03T00:00:00.000Z');
  });

  it('crosses a month boundary correctly', () => {
    // 2026-08-31 is a Monday; 2026-09-01 (Tuesday) should roll back to it.
    const tue = new Date('2026-09-01T05:00:00.000Z');
    expect(isoWeekStartUtc(tue).toISOString()).toBe('2026-08-31T00:00:00.000Z');
  });
});
