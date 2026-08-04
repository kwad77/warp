# Wanderpost server

TypeScript (Fastify) API. Everything here implements [SPEC.md](../SPEC.md) — read the
relevant sections before changing behavior.

## Setup

```sh
# 1. Dependencies (Node 22+)
npm install

# 2. Local PostGIS (from the repo root)
docker compose up -d db
# — or point DATABASE_URL at any Postgres 16 with the postgis extension available.

# 3. Environment
cp .env.example .env

# 4. Schema
DATABASE_URL=postgres://wanderpost:wanderpost@localhost:5432/wanderpost npm run db:migrate

# 5. Run
npm run dev            # http://localhost:8080/healthz
```

In development the email login code is written to the server log instead of being mailed
(`[dev-mail] …`). Flow: `POST /v1/auth/email/request {email}` → read code from log →
`POST /v1/auth/email/verify {email, code}` → use the returned `accessToken` as
`Authorization: Bearer …`.

## Checks (the merge gate — SPEC §10)

```sh
npm run check          # biome + tsc + vitest
```

DB-backed integration tests run when `TEST_DATABASE_URL` is set (CI always sets it):

```sh
TEST_DATABASE_URL=postgres://wanderpost:wanderpost@localhost:5432/wanderpost npm test
```

## Seeding unclaimed POIs for a new city

`docs/MILESTONES.md`'s M2 "seed 50-100 founder POIs per city" — pulls real, named POIs
from OpenStreetMap (no API key needed) and creates them through `importUnclaimedPoi`
(same validation/dedupe every user's `POST /pois` gets, via the shared `createPoi` dedupe
path). Seeded POIs have no creator (SPEC §21 — `creator_id IS NULL` means "unclaimed"):
the first real check-in photo that clears moderation for one founds it, permanently.

```sh
DATABASE_URL=postgres://wanderpost:wanderpost@localhost:5432/wanderpost npm run db:seed -- <city_key> [maxPois]
```

`<city_key>` must be a key in `src/scripts/seed_osm_pois.ts`'s `CITY_BBOXES` map
(currently `tigard_or`, `portland_or`) — add a new bbox there for each additional city.
`maxPois` (default 80) caps how many candidates get created. No rate limit applies (an
unclaimed POI has no creator to rate-limit) and no synthetic account is created —
`POI_CREATE_PER_DAY` only ever governed real users' own `POST /pois` calls.

## Layout

```
migrations/        numbered SQL, forward-only (SPEC §8 is the authority)
src/constants.ts   SPEC §2 constants — never change without a SPEC edit
src/errors.ts      SPEC §3 envelope + closed code set
src/verification/  presence, velocity, evidence-freshness (SPEC §17, M2) math — pure
                   functions, table-driven tests
src/auth/          tokens (JWT) + email-code service, refresh rotation, Apple/Google
                   ID-token verification (oidc.ts, config-gated — SPEC §4)
src/db/            drizzle schema (mirror of migrations), client, migration runner
src/routes/        thin handlers: parse → service → serialize
src/storage/       R2 presigned uploads (aws4fetch) + object GET (storage.get, sharp/§6)
src/moderation/    ModerationProvider seam, verdict application, phash.ts (dHash + the
                   pixel-dimension check — SPEC §6); text_provider.ts is the same seam
                   shape for postcard messages (SPEC §20, M2) — smaller verdict (just
                   approved: boolean), since nothing consumes a rejection reason
src/badges/        badge taxonomy + awarding, run in the verified check-in's own
                   transaction (SPEC §16, M2)
src/postcards/     postcard sending v1 (SPEC §20, M2) — service.ts (send/revoke/view
                   data), render.ts (the pure HTML template GET /postcards/:token
                   serves — no templating-engine dependency, just a string builder)
src/scripts/       ops tooling, not part of the served API — seed_osm_pois.ts imports
                   founder POIs from OpenStreetMap for a new city (see "Seeding founder
                   POIs" above), through the real createPoi service function
test/              unit + inject route tests + DB integration suite
```
