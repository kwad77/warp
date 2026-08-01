// SPEC §7 — coverage leaderboard. Live query in M1 (no leaderboard_snapshots table exists
// yet); revisit with precomputed snapshots if this becomes a read-cost problem.
import { SPEC_CONSTANTS } from '../constants.js';
import type { Pg } from '../db/client.js';
import { isoWeekStartUtc } from '../lib/isoWeek.js';

const MAX = SPEC_CONSTANTS.leaderboard.LEADERBOARD_ENTRIES_MAX;

export interface LeaderboardEntry {
  rank: number;
  handle: string;
  cells: number;
}

export interface LeaderboardResult {
  entries: LeaderboardEntry[];
  me?: { rank: number; cells: number };
}

export async function getCoverageLeaderboard(
  pg: Pg,
  window: 'weekly' | 'all',
  requesterId: string | null,
  now: Date,
): Promise<LeaderboardResult> {
  const since = window === 'weekly' ? isoWeekStartUtc(now) : new Date(0);

  // SPEC §17 (M2): a cell counts here only if its first-ever verified check-in was live —
  // one first proven via deferred (offline) evidence doesn't count competitively until
  // re-covered live. GET /me/coverage, the heatmap, creatorScore, and badges are unaffected
  // (they join through no such filter) since none of those are competitive-ranking surfaces.
  const rows = await pg`
    SELECT u.handle, u.id, count(*)::int AS cells
    FROM user_coverage uc
    JOIN users u ON u.id = uc.user_id
    JOIN checkins c ON c.id = uc.first_checkin_id
    WHERE uc.created_at >= ${since.toISOString()} AND c.evidence = 'live'
    GROUP BY u.id, u.handle
    ORDER BY cells DESC, u.id ASC
    LIMIT ${MAX}`;

  const typed = rows as unknown as { handle: string; id: string; cells: number }[];
  const entries: LeaderboardEntry[] = typed.map((r, i) => ({
    rank: i + 1,
    handle: r.handle,
    cells: r.cells,
  }));

  let me: { rank: number; cells: number } | undefined;
  if (requesterId) {
    const inTop = typed.findIndex((r) => r.id === requesterId);
    if (inTop >= 0) {
      me = { rank: inTop + 1, cells: typed[inTop]?.cells ?? 0 };
    } else {
      const meRows = await pg`
        SELECT count(*)::int AS cells
        FROM user_coverage uc
        JOIN checkins c ON c.id = uc.first_checkin_id
        WHERE uc.user_id = ${requesterId} AND uc.created_at >= ${since.toISOString()}
          AND c.evidence = 'live'`;
      const myCells = Number((meRows[0] as { cells: number } | undefined)?.cells ?? 0);
      if (myCells > 0) {
        const rankRows = await pg`
          SELECT count(*)::int AS n FROM (
            SELECT uc.user_id, count(*) AS c
            FROM user_coverage uc
            JOIN checkins c ON c.id = uc.first_checkin_id
            WHERE uc.created_at >= ${since.toISOString()} AND c.evidence = 'live'
            GROUP BY uc.user_id
            HAVING count(*) > ${myCells}
          ) ranked_above`;
        const above = Number((rankRows[0] as { n: number } | undefined)?.n ?? 0);
        me = { rank: above + 1, cells: myCells };
      }
    }
  }

  return { entries, ...(me ? { me } : {}) };
}
