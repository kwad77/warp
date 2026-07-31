# Wanderpost — Implementation Handoff Template

Paste this prompt when handing a work item to any session or agent, on any model. Fill in
the [SLOTS]. The template assumes the repo's CLAUDE.md and SPEC.md do the heavy lifting —
the prompt's job is scoping, design decisions, and the test list, never re-explaining the
project.

---

You are implementing a well-specified work item in the Wanderpost server
(TypeScript/Fastify) at `server/`. This codebase is spec-driven: `SPEC.md` at the repo
root is the binding contract and `CLAUDE.md` has the operating rules. Read both BEFORE
writing code — specifically SPEC sections [LIST THE SECTIONS THIS TASK TOUCHES, e.g.
"2 (constants), 3 (error codes), 7 (the endpoint rows for X)"].

## Task

[NUMBERED LIST OF ENDPOINTS/FEATURES, one line each, restating the SPEC row plus any
behavior the table abbreviates. Never describe behavior that contradicts SPEC — if you
need different behavior, patch SPEC first, in the same PR.]

## Required design decisions (follow exactly)

[ARCHITECTURAL CHOICES MADE FOR THE IMPLEMENTER — file names, which existing patterns to
copy (name the exact files, e.g. "services take (db, pg, ...) like src/checkins/service.ts;
geometry via raw pg tagged SQL — see loadPoi there"), any interface changes permitted.
This section exists so the implementer executes, not architects.]

## Testing (required, SPEC §10)

- Add [TEST FILE NAME] modeled on [EXISTING TEST FILE — name it].
- A local Postgres with PostGIS runs at `postgres://wanderpost@127.0.0.1:5432/wanderpost`.
  If connection refused, restart it:
  `su postgres -c "/usr/lib/postgresql/16/bin/pg_ctl -D /var/lib/postgresql/wp -l /var/lib/postgresql/wp.log -o '-p 5432 -k /tmp' start"`
  (or `docker compose up -d db && npm run db:migrate` where Docker works).
- Cover at least: [EXPLICIT SCENARIO LIST — happy path, every error path, edge cases.
  Enumerate them; "add tests" without a list produces happy-path-only coverage.]
- Full gate must pass:
  `cd server && TEST_DATABASE_URL=postgres://wanderpost@127.0.0.1:5432/wanderpost npm run check`
  — Biome + tsc + ALL tests including existing ones. Fix your code; never weaken, skip,
  or delete an existing test.

## Hard rules

- No new dependencies (SPEC §1 allowlist). No schema/migration changes unless this prompt
  explicitly includes one. No new error codes — the set in `src/errors.ts` is closed.
- Do not modify [LIST PROTECTED AREAS, e.g. "src/verification/, src/checkins/, src/auth/"]
  beyond what the design-decisions section explicitly permits.
- [GIT MODE — pick one:]
  - Subagent-for-review: do NOT run `git commit` or `git push`. Leave the tree for review.
  - Main session: commit per CLAUDE.md (imperative subject ≤ 72 chars, body lists SPEC
    sections) and push to [BRANCH].
- If SPEC is ambiguous on something you need: make the smallest reasonable choice and
  list it explicitly in your report — do not silently improvise. If the ambiguity is
  behavioral (would change what users see), stop and ask instead.

## Report back (your final message)

Files created/changed · vitest summary line pasted verbatim · every ambiguity you hit and
the choice you made · anything SPEC should clarify.

---

## Why this shape

- **SPEC sections up front** — the reader loads the contract before the code.
- **Design decisions are made by the spec author, not the implementer** — cheaper models
  execute well and architect poorly; remove the architecture degrees of freedom.
- **The test list is enumerated** — an unlisted scenario is an untested scenario.
- **The gate is the whole suite** — regressions in existing tests are the handoff's
  tripwire, not the implementer's judgment.
- **Ambiguity protocol** — "smallest reasonable choice + report it" for mechanical gaps,
  "stop and ask" for behavioral ones. Silent improvisation is the only unforgivable mode.
