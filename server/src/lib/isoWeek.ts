/** Pure: no clock reads. Start of the ISO 8601 week (Monday 00:00:00.000 UTC) containing `now`. */
export function isoWeekStartUtc(now: Date): Date {
  const d = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0),
  );
  const isoDay = d.getUTCDay() === 0 ? 7 : d.getUTCDay(); // Mon=1 .. Sun=7
  d.setUTCDate(d.getUTCDate() - (isoDay - 1));
  return d;
}
