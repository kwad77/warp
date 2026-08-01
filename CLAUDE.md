# Wanderpost — Agent Operating Rules

Wanderpost is a location-based collection game: users check in at community-created
points of interest with verified presence ("I've been there — here's the proof").
Monorepo: `server/` (TypeScript/Fastify), `app/` (Flutter), `docs/` (narrative), `SPEC.md`
(normative).

## The one rule that matters

**`SPEC.md` is the contract. Read the sections relevant to your task BEFORE writing code.**
It defines the exact constants, API shapes, DDL, verification algorithm, error codes, and
merge gates. If the spec doesn't cover what you're about to build: stop, propose a SPEC
edit in the same PR, and call it out. Never improvise endpoints, constants, schema columns,
or error codes. Where code and SPEC disagree, SPEC wins; where SPEC and `docs/` disagree,
SPEC wins.

## Hard rules (review-rejecting if violated)

- No new dependencies outside the SPEC §1 allowlist without a SPEC edit in the same PR.
- `src/verification/` and `src/geo/` stay pure: no I/O, no `Date.now()` — time and data
  come in as parameters.
- All request/response bodies validated with Zod at the route boundary. No `any`,
  no `@ts-ignore`.
- Errors: SPEC §3 envelope and closed code set, exactly.
- Privacy invariants (SPEC §9) are non-negotiable — no background location, no precise
  coords or emails or tokens in logs, trust internals never exposed via API.
- Never weaken, skip, or delete a test to get green. Fix the code or flag the conflict.
- Check-in photos come from the in-app camera only; every photo passes the no-people gates
  (SPEC §6) before public visibility.

## Workflow

- Before commit: `cd server && npm run check` (Biome + typecheck + tests). Red = not done.
- DB changes: new numbered SQL file in `server/migrations/` + matching Drizzle schema
  update + SPEC §8 update, all in one PR. Never edit an applied migration.
- Local DB: `docker compose up -d db` (PostGIS), then `npm run db:migrate`.
- Commits: imperative subject ≤ 72 chars; body says which SPEC sections are involved.
- Keep PRs to one SPEC-scoped concern. Milestone order lives in `docs/MILESTONES.md`.

## Known footgun

Once `drizzle(pg, {schema})` has wrapped a connection (see `src/db/client.ts`), raw
tagged-template queries on that *same* connection (`pg\`SELECT ...\``) return
`timestamptz` columns as strings, not `Date` instances — even though Drizzle's own query
builder (`db.select()...`) still converts them correctly. Any raw-SQL code path that reads
a timestamp column must `new Date(row.created_at)` before calling Date methods on it, or
it throws at runtime, not at compile time (the column is typed `Date` in ad-hoc row
interfaces because nothing catches the mismatch). See `src/me/service.ts` for the pattern.

## Style

- Match surrounding code. Comments only for non-obvious constraints, referencing the spec
  (`// SPEC §5.3`) instead of restating it.
- Route handlers stay thin (parse → service → serialize); logic lives in services;
  services touching money, trust, or verification get table-driven tests first.
