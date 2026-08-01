# Wanderpost — Normative Implementation Spec

**This file is the contract.** Narrative docs under `docs/` explain *why*; this file defines
*what*, exactly. Where they disagree, SPEC.md wins. Implementers (human or AI, any model)
MUST follow it without improvisation.

Keywords MUST / MUST NOT / SHOULD / MAY are RFC-2119 normative.

Version: 1.0 · Scope: Milestone 1 (server + Flutter app foundation). Sections marked
**[M2]**/**[M3]** are declared here so schemas don't churn, but MUST NOT be implemented early.

---

## 0. Change control (read first)

- Any behavior, constant, endpoint, or schema not in this file MUST NOT be invented.
  Missing something? Stop and ask, or add it to SPEC.md **in the same PR** and call it out.
- Constants live in §2 only. Changing one = a SPEC change, flagged in the PR description.
- Code comments MUST NOT restate the spec; they reference it (`// SPEC §5.3`).
- Every PR description MUST list which SPEC sections it implements.

## 1. Toolchain & repo layout (pinned)

| Component | Version | Notes |
| --- | --- | --- |
| Node.js | 22 LTS | server runtime |
| TypeScript | ^5.6 | `strict: true`; `any` and `@ts-ignore` are forbidden (`@ts-expect-error` with a reason string is allowed) |
| Fastify | ^5 | HTTP framework |
| Zod | ^3 | ALL request/response bodies validated at the boundary |
| drizzle-orm + postgres.js | latest stable | DB access; raw SQL allowed for geo queries |
| PostgreSQL | 16 + PostGIS 3.4 | dev via `docker compose up -d db` (image `postgis/postgis:16-3.4`) |
| jose | ^5 | JWT |
| h3-js | ^4 | H3 cells |
| Vitest | latest stable | tests |
| Biome | ^1.9 | lint + format (no ESLint/Prettier) |
| Flutter | 3.x stable | app; packages: `maplibre_gl`, `camera`, `google_mlkit_face_detection`, `riverpod`, `dio`, `freezed` |

Dependency allowlist (server prod deps): `fastify`, `zod`, `drizzle-orm`, `postgres`,
`jose`, `h3-js`, `sharp` (worker only), `graphile-worker`, `aws4fetch` (R2 presigning).
Anything else requires a SPEC edit in the same PR.

```
server/    src/{config,app,index,constants,errors}.ts, src/db/, src/routes/,
           src/verification/, src/geo/, src/auth/, src/storage/, src/lib/,
           migrations/*.sql, test/
app/       Flutter project (M1 steps 3–4)
docker-compose.yml    local PostGIS (repo root so `docker compose up -d db` just works)
.github/workflows/    CI (SPEC §10 gates)
docs/      narrative documents (non-normative)
```

Layering rule: `routes/` (thin: parse → call service → serialize) → services →
`db/`. `verification/` and `geo/` MUST be pure (no I/O, no clock reads — time is always a
parameter). `Date.now()` inside `src/verification/` is a review-rejecting defect.

## 2. Constants (single source of truth)

Implement as one exported object `SPEC_CONSTANTS` in `server/src/constants.ts`; the Flutter
app mirrors what it needs in `app/lib/core/constants.dart`. Values here are authoritative.

```
GEO
  H3_RES_COVERAGE            = 7
  H3_RES_DEDUPE              = 9
  DEDUPE_RADIUS_M            = 50
  DEDUPE_PHASH_MAX_HAMMING   = 10        // of 64-bit pHash
  PIN_ADJUST_MAX_M           = 30        // creator may nudge pin this far from GPS fix

CHECK-IN RADII (by POI category, meters)
  landmark = 75, architecture = 75, street_art = 50, nature = 150,
  viewpoint = 250, other = 75

PRESENCE (§5.3)
  ACCURACY_CEILING_M         = 150
  MIN_FIXES                  = 2
  MAX_FIXES                  = 5
  FIX_SPAN_MIN_S             = 8
  FIX_WINDOW_MAX_S           = 25
  TRACK_CONSISTENCY_M        = max(150, 2 × max(accuracy_i))
  CONF_PASS                  = 0.90
  CONF_DEGRADED              = 0.60
  CONF_PENDING               = 0.30

VELOCITY (§5.4)
  MAX_SPEED_KMH              = 950
  TELEPORT_WINDOW_S          = 90
  TELEPORT_DISTANCE_M        = 1500

NONCE
  CHECKIN_NONCE_TTL_S        = 120       // single use, bound to (user, device, poi)

TRUST (§5.6) — score starts at 100, clamped [0, 100]
  D_INTEGRITY_FAIL           = −25
  D_VELOCITY_VIOLATION       = −15
  D_REPORT_UPHELD            = −30
  D_PEOPLE_PHOTO_UPHELD      = −10
  D_CLEAN_30D                = +5
  TRUST_PHOTO_REQUIRED_BELOW = 40        // photo mode forced, check-ins land pending
  TRUST_MANUAL_REVIEW_BELOW  = 15

PHOTOS (§6)
  UPLOAD_MAX_LONG_EDGE_PX    = 2048
  UPLOAD_MIN_LONG_EDGE_PX    = 1024
  UPLOAD_MAX_BYTES           = 1_048_576
  DERIVED_CARD_PX            = 1024
  DERIVED_THUMB_PX           = 256
  ALLOWED_MIME               = image/jpeg, image/webp

AUTH (§4)
  ACCESS_TTL_S               = 900
  REFRESH_TTL_S              = 2_592_000 // 30 d, rotating, reuse ⇒ revoke family
  EMAIL_CODE_TTL_S           = 600
  EMAIL_CODE_LENGTH          = 6         // numeric

RATE LIMITS (per user unless noted)
  AUTH_EMAIL_REQUEST         = 5 / 15 min per email
  CHECKIN_INTENT             = 12 / hour
  POI_CREATE                 = 20 / day
  REPORT_CREATE              = 20 / day

LEADERBOARD
  LEADERBOARD_ENTRIES_MAX    = 100

ENTITLEMENT [M3]
  FREE_UNLOCKED_CHECKINS     = 50        // beyond: vaulted=true, never blocked
```

## 3. Error envelope & codes

Every non-2xx response body is exactly:

```json
{ "error": { "code": "domain/reason", "message": "human readable", "details": {} } }
```

`details` MAY be omitted. Codes are closed-set; add new ones only via SPEC edit:

| HTTP | code |
| --- | --- |
| 400 | `request/invalid` (zod issues in `details.issues`) |
| 401 | `auth/missing`, `auth/expired`, `auth/invalid` |
| 403 | `auth/refresh_reused`, `account/suspended` |
| 404 | `resource/not_found` |
| 409 | `checkin/duplicate` (user already has a check-in for this POI), `auth/email_code_used` |
| 410 | `checkin/nonce_expired` |
| 422 | `checkin/rejected` (`details.reasons` per §5), `photo/rejected` (`details.reason` ∈ people, unsafe, quality), `poi/outside_pin_adjust` |
| 429 | `rate/limited` (`details.retryAfterS`) |
| 500 | `internal/error` (unexpected failure; never leaks internals) |
| 503 | `service/unavailable` |

## 4. Auth

- Access token: JWT HS256 (secret ≥ 32 bytes from env `JWT_SECRET`), claims
  `{ sub: userId, typ: "access", iat, exp }`, TTL `ACCESS_TTL_S`.
- Refresh token: JWT `{ sub, typ: "refresh", jti, fam, iat, exp }`. On refresh: issue new
  pair, mark old `jti` used. Presenting a used `jti` ⇒ revoke the whole `fam` family and
  return `auth/refresh_reused`. Store `(jti, fam, user_id, used, expires_at)` in
  `refresh_tokens`.
- Email flow: `POST /v1/auth/email/request {email}` → generate `EMAIL_CODE_LENGTH`-digit
  code via `crypto.randomInt`, store **hash** (sha256) with TTL, send via mail provider
  (dev: log to stdout). `POST /v1/auth/email/verify {email, code}` → single-use; success
  upserts user (handle = `explorer_` + 6 base32 chars, retry on collision) and returns
  `{accessToken, refreshToken, user}`.
- Apple/Google: `POST /v1/auth/apple` / `/google` verify the platform ID token
  (issuer + audience + signature via provider JWKS), link by stable provider subject.
  **[M1 step 1: return 501 `service/unavailable`; implement in M1 step 4.]**
- Anonymous browsing: all 🌐 endpoints in §7 MUST work with no `Authorization` header.

## 5. Check-in verification pipeline (the heart — implement exactly)

### 5.1 Flow

1. `POST /v1/checkins/intent {poiId, deviceId}` (auth; the device must belong to the
   caller) → server generates a 32-byte random nonce (base64url), stores `(nonce_hash,
   user_id, device_id, poi_id, expires_at = now + CHECKIN_NONCE_TTL_S, used=false)`,
   returns `{nonce, expiresInS}`. Refused early with `checkin/duplicate` if a
   verified/pending check-in already exists, and rate-limited per §2.
2. Client gathers `MIN_FIXES..MAX_FIXES` fused-location fixes spanning ≥ `FIX_SPAN_MIN_S`
   within `FIX_WINDOW_MAX_S`, requests platform integrity token bound to the nonce, and
   (photo mode) captures in-app with a capture token minted at shutter time.
3. `POST /v1/checkins` with the payload in §7. Server runs layers L1→L5 **in order**,
   short-circuiting only on hard rejects. Every layer appends to `reasons[]` and the full
   input+verdicts are persisted to `checkin_evidence` **even on rejection**.

### 5.2 L1 Integrity

Verify the platform verdict server-side (Play Integrity decodeIntegrityToken; App Attest
assertion) and that it is bound to our nonce. Outcomes:
`pass` | `degraded` (device cannot attest: no Play services, old OS) | `fail`
(emulator, root/jailbreak signals, wrong nonce). `fail` ⇒ status `rejected`, trust event
`integrity_fail`, stop. `degraded` ⇒ continue; final status caps at `pending`.
**[M1 step 2 ships the interface + nonce binding + `DevIntegrityVerifier`; real platform
verifiers are M1 step 4.]** `DevIntegrityVerifier` (active only when `NODE_ENV ≠
production`): `integrityToken` MUST be exactly `dev.<pass|degraded|fail>.<nonce>`; a
malformed token or nonce mismatch ⇒ `fail`. In production, until platform verifiers ship,
every integrity evaluation returns `degraded` (so nothing can reach `verified` on the
strength of an unverified device — honest by construction).

### 5.3 L2 Presence (pure function, `src/verification/presence.ts`)

For each fix, with `d` = haversine distance (m) from fix to POI center, `a` = reported
accuracy (m), `r` = category check-in radius:

```
if a > ACCURACY_CEILING_M      → fix verdict REJECT(accuracy_ceiling)
confidence c = clamp01((r + a − d) / (2a))     // a > 0; if a == 0 treat a = 5
```

Aggregate: track consistency first — if max pairwise distance between fixes >
`TRACK_CONSISTENCY_M` ⇒ result caps at `pending(inconsistent_track)`; a fix-set whose
timestamp span falls outside `[FIX_SPAN_MIN_S, FIX_WINDOW_MAX_S]` likewise caps at
`pending(fix_span)`. Caps only ever downgrade a pass — a reject stays a reject. Then take the
best-confidence fix: `c ≥ CONF_PASS` ⇒ pass · `≥ CONF_DEGRADED` ⇒ pass_degraded ·
`≥ CONF_PENDING` ⇒ pending(low_confidence) · else reject(outside_radius).
Worked examples (MUST be test cases): `(d=20,a=60,r=75)→c≈0.958 pass` ·
`(d=75,a=60,r=75)→c=0.5 pending` · `(d=130,a=60,r=75)→c≈0.04 reject` ·
`(d=0,a=150,r=75)→c=0.75 pass_degraded`.

### 5.4 L3 Velocity (pure, same module)

Against the user's most recent check-in with status `verified` or `pending`:
`v = haversine(prev, best_fix) / Δt`. Violation if `v > MAX_SPEED_KMH` OR
(`Δt < TELEPORT_WINDOW_S` AND distance > `TELEPORT_DISTANCE_M`). Violation ⇒ cap at
`pending(velocity)` + trust event `velocity_violation` (NOT a hard reject — flights and
clock skew exist). First-ever check-in: skip.

### 5.5 L4 Capture (photo mode only)

`capture.token` MUST equal hex sha256 of `"<nonce>.<capturedAtMs>"` (minted app-side at
shutter — tamper-evidence only; real assurance is the attested app, L1), and
`capture.capturedAt` MUST fall within the nonce window ± 30 s clock-skew allowance.
`capture.storageKey` MUST resolve to an existing `photos` row with `uploader_id` = caller,
`poi_id` = target POI, `source = 'checkin'`; the check-in links its `photo_id`. EXIF is
stored in evidence, never used as a pass/fail signal. Any violation ⇒
`rejected(capture_invalid)`.

### 5.6 L5 Trust gate

`trust < TRUST_PHOTO_REQUIRED_BELOW` ⇒ confirm-mode requests are rejected with
`checkin/rejected (details.reasons=["photo_required"])`; photo-mode check-ins cap at
`pending`. `trust < TRUST_MANUAL_REVIEW_BELOW` ⇒ everything lands `pending`, flagged for
review. Trust math: fold of `trust_events` deltas from 100, clamped [0,100], computed at
event insert and cached on `users.trust_score`.

### 5.7 Final status

`verified` (all pass; degraded presence allowed) · `pending` (any layer said pending, or
integrity degraded) · `rejected`. Status transitions allowed: `pending → verified|rejected`
(worker or admin) only. Mechanics:

- The nonce is consumed on submit **regardless of outcome** — a retry after rejection
  starts with a fresh intent. A used or expired nonce ⇒ `checkin/nonce_expired`.
- Rejected attempts ARE persisted (`checkins` row with `status='rejected'` + evidence) for
  the audit trail. Uniqueness applies only to live check-ins: partial unique index on
  `(user_id, poi_id) WHERE status <> 'rejected'` (migration 0001) — rejection never locks
  a user out of an honest retry. A verified/pending duplicate ⇒ `checkin/duplicate`.
- Response shape: `201 {checkin}` for `verified`/`pending`; `rejected` ⇒ `422
  checkin/rejected` with `details = {checkinId, reasons}`.
- `verified` ⇒ insert `user_coverage` (r7, idempotent) + increment `pois.checkin_count`,
  both in the same transaction as the check-in row. `pending → verified` performs the same
  side effects at transition time.
- `GET /checkins/:id` by a non-owner ⇒ `resource/not_found` (no existence leak).

## 6. Photos & no-people policy (hard product rule)

- Check-in photos: in-app camera only — the Flutter check-in flow MUST NOT offer any
  gallery/roll picker. POI-creation flow MAY, labeled "for creating places only".
- On-device (Flutter): ML Kit face detection on the captured frame; any face ⇒ block with
  retake prompt. This gate runs before upload for BOTH flows.
- Upload: client resizes to ≤ `UPLOAD_MAX_LONG_EDGE_PX`, then `POST .../photos/presign` →
  `{uploadUrl, storageKey, maxBytes}` (R2 presigned PUT, 10-min expiry) → PUT → `POST
  .../photos/complete`. Storage keys are server-minted:
  `photos/<poiId>/<photoId>.<jpg|webp>`; no photos row exists until complete. At complete
  the server verifies via HEAD only — object exists, size ≤ `UPLOAD_MAX_BYTES`, mime in
  `ALLOWED_MIME` — and creates the row (`moderation=pending`). Failed HEAD checks ⇒
  `photo/rejected (details.reason='quality')` and no row. Pixel-dimension and quality
  checks require the bytes and run in the moderation worker (M1.5), which rejects
  undersized images there.
- Worker moderation (async, before ANY public visibility): provider face/person detection +
  safety labels behind interface `ModerationProvider` (M1 ships `DevModerationProvider`
  auto-approving with a log line; Rekognition impl is M1 step 5). Any person ⇒
  `rejected(people)`. Borderline ⇒ `escalated` (human queue). pHash (64-bit) computed here.
- A photo rejection NEVER changes its check-in's status (§5.7 owns that).
- States: `pending → approved | rejected(reason) | escalated → approved|rejected`.

## 7. API surface (M1; exact)

All under `/v1`, except `/healthz` and `/readyz` which live at the root (infra
convention). 🌐 = works unauthenticated. Coordinates are `{lat, lng}` WGS84 numbers;
timestamps ISO-8601 UTC strings; IDs are UUIDv7 strings.

| Endpoint | Auth | Request → Response (2xx) |
| --- | --- | --- |
| `GET /healthz` | 🌐 | → `{ok: true, version}` (no DB touch) |
| `GET /readyz` | 🌐 | → `{ok: true}` or 503 (DB ping) |
| `POST /auth/email/request` | 🌐 | `{email}` → `{ok: true}` (always 200 — no account enumeration) |
| `POST /auth/email/verify` | 🌐 | `{email, code}` → `{accessToken, refreshToken, user: User}` |
| `POST /auth/refresh` | 🌐 | `{refreshToken}` → `{accessToken, refreshToken}` |
| `POST /auth/apple` · `/google` | 🌐 | `{idToken}` → same as verify · *(501 until M1.4)* |
| `POST /devices` | ✅ | `{platform: "ios"\|"android", model}` → `{deviceId}` |
| `GET /pois?bbox=w,s,e,n&zoom=` | 🌐 | → zoom ≥ 13: `{pois: PoiPin[]}` (active only, cap 200, `clusters: []`); zoom < 13: `{pois: [], clusters: Cluster[]}` grouped by r7 cell, `Cluster = {h3, count, centroid: {lat, lng}}` (centroid = mean of member POIs). Bbox wider/taller than 2° with zoom ≥ 13 ⇒ `request/invalid`. Antimeridian-crossing bboxes (w > e) unsupported in M1 ⇒ `request/invalid`. |
| `GET /pois/nearby?lat=&lng=&radiusM=` | 🌐 | `radiusM` optional, default 2000, max 10000 → `{pois: PoiPin[]}` active only, ordered by distance, max 50 |
| `GET /pois/:id` | 🌐 | → `{poi: Poi}` (gallery: approved photos, vote-ranked, max 20). Only `removed` ⇒ 404; `pending_review`/`flagged` POIs serve normally until moderation resolves them. |
| `POST /pois` | ✅ | `{title(3..80 code points), description?(..280), category, location, gpsFix: Fix, force?: bool}` → `201 {poi}` or `200 {dedupeCandidates: PoiPin[]}`. Rules: haversine(location, gpsFix) ≤ `PIN_ADJUST_MAX_M` else `poi/outside_pin_adjust`; creation dedupe is **proximity-only** (active POIs within `DEDUPE_RADIUS_M`, found via r9 neighbor cells) — pHash similarity runs later in photo moderation (M1.5); `force: true` skips the dedupe prompt; rate limit §2. New POI: `status='active'`, radius from category (§2). |
| `POST /pois/:id/photos/presign` | ✅ | `{contentType ∈ ALLOWED_MIME, source: "poi_creation"\|"checkin"}` → `{uploadUrl, storageKey, maxBytes}` (key format §6; no row created yet) |
| `POST /pois/:id/photos/complete` | ✅ | `{storageKey, source}` → `201 {photo: Photo(moderation=pending)}` — key embeds photoId; server checks HEAD + mints row with uploader = caller (§6). **Idempotent**: the same caller re-completing the same key gets the existing photo back (retry-safe); a different caller ⇒ `request/invalid`. |
| `POST /checkins/intent` | ✅ | `{poiId, deviceId}` → `{nonce, expiresInS}` |
| `POST /checkins` | ✅ | `{nonce, poiId, mode: "photo"\|"confirm", fixes: Fix[2..5], integrityToken, capture?: {token, capturedAt, storageKey}}` → `201 {checkin: {id, status, poiId, verifiedAt?}}`; rejected ⇒ `422` per §5.7; `Fix = {lat, lng, accuracyM, capturedAt}` |
| `GET /checkins/:id` | ✅ owner | → `{checkin}` (non-owner ⇒ 404, §5.7) |
| `GET /me` | ✅ | → `{user, stats: {checkins, cellsCovered, poisCreated}}` — `checkins` counts `status='verified'` only; `poisCreated` counts the caller's POIs with `status <> 'removed'`; `cellsCovered` = `user_coverage` row count |
| `GET /me/map` | ✅ | → `{checkedIn: PoiPin[], created: PoiPin[], vaulted: PoiPin[]}` — `checkedIn` = POIs with a verified check-in by the caller; `created` = caller's POIs with `status <> 'removed'`; `vaulted` is always `[]` in M1 (vault ships M3; SPEC §6 of MVP.md) |
| `GET /me/coverage` | ✅ | → `{cells: string[] (h3 r7, lowercase hex), count}` |
| `GET /me/checkins?cursor=&limit=50` | ✅ | → `{items, nextCursor?}` — keyset pagination per the convention below; `limit` max 100 |
| `DELETE /me` | ✅ | → `{ok}` — soft-delete now (`deleted_at`), hard purge after 14 d (worker, M1.5); revokes every refresh-token family for the user in the same request (immediate logout everywhere) |
| `GET /me/export` | ✅ | *(M1.5 — requires the job queue, which does not exist yet; until then, 501 `service/unavailable`)* |
| `POST /photos/:id/vote` | ✅ | `{value: 1\|0}` (0 = retract) → `{voteScore}` — upsert on `(user_id, photo_id)`; `voteScore` on `photos` is the denormalized sum, updated in the same transaction; voting on a non-`approved` photo ⇒ `resource/not_found` (no visibility leak into pending/rejected review state) |
| `POST /reports` | ✅ | `{targetType: "poi"\|"photo", targetId, reason: "people"\|"unsafe"\|"wrong_location"\|"duplicate"\|"other", note?(..280)}` → `201 {ok}` — target must exist (else `resource/not_found`); rate limit §2; no dedupe on repeat reports from the same user in M1 (moderation queue is M1.5+, so nothing consumes this yet beyond the row existing) |
| `GET /leaderboards/coverage?window=weekly\|all&scope=global` | 🌐 (optional auth) | → `{entries: [{rank, handle, cells}], me?: {rank, cells}}`, entries capped at `LEADERBOARD_ENTRIES_MAX` (§2). `scope` accepts only `global` in M1 (other scopes ⇒ `request/invalid`); `window=weekly` counts distinct `user_coverage.h3_r7` rows whose `created_at` falls in the current ISO week (Monday 00:00 UTC start, UTC throughout); `window=all` counts all rows. `me` is present only when the request carries a valid bearer token (optional auth — a missing/invalid token omits `me` rather than erroring). **M1 implementation note:** computed live (`GROUP BY user_id ORDER BY count DESC LIMIT`); precomputed snapshots (`leaderboard_snapshots`, ARCHITECTURE.md) are deferred until live cost requires them — no such table exists yet. |

**Pagination convention** (`GET /me/checkins` and any future cursor-paginated list): cursor
is base64 of `"<createdAt ISO>|<id>"` for the last row of the previous page; results order
by `(created_at DESC, id DESC)`; an absent/malformed cursor starts from the top; no
`nextCursor` in the response means no further pages.

`User = {id, handle, createdAt}` · `PoiPin = {id, title, category, location, checkinCount}`
· Full `Poi` adds `{description, creator: {id, handle}, checkinRadiusM, gallery: Photo[]}`
· `Photo = {id, urlCard, urlThumb, voteScore, uploader: {handle}, status}` (non-approved
photos visible only to their uploader).

## 8. Database schema (authoritative DDL)

Migration `0000_init.sql` MUST create exactly this (plus `CREATE EXTENSION IF NOT EXISTS
postgis`). Drizzle schema mirrors the *cumulative* state after all migrations; drift is a
defect. UUIDv7 generated in app code. Applied deltas: **0001** drops
`checkins_user_poi_unique` and creates
`UNIQUE INDEX checkins_user_poi_active ON checkins (user_id, poi_id) WHERE status <>
'rejected'` (§5.7 retry semantics).

```sql
CREATE TYPE poi_category AS ENUM ('landmark','viewpoint','nature','architecture','street_art','other');
CREATE TYPE poi_status AS ENUM ('active','pending_review','flagged','removed');
CREATE TYPE photo_source AS ENUM ('poi_creation','checkin');
CREATE TYPE photo_moderation AS ENUM ('pending','approved','rejected','escalated');
CREATE TYPE photo_rejection AS ENUM ('people','unsafe','quality','other');
CREATE TYPE checkin_mode AS ENUM ('photo','confirm');
CREATE TYPE checkin_status AS ENUM ('verified','pending','rejected');
CREATE TYPE device_platform AS ENUM ('ios','android');
CREATE TYPE integrity_state AS ENUM ('untested','passed','degraded','failed');

CREATE TABLE users (
  id UUID PRIMARY KEY, handle TEXT NOT NULL UNIQUE,
  email TEXT UNIQUE, apple_sub TEXT UNIQUE, google_sub TEXT UNIQUE,
  trust_score SMALLINT NOT NULL DEFAULT 100,
  privacy JSONB NOT NULL DEFAULT '{}',
  deleted_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT now());

CREATE TABLE refresh_tokens (
  jti UUID PRIMARY KEY, fam UUID NOT NULL, user_id UUID NOT NULL REFERENCES users(id),
  used BOOLEAN NOT NULL DEFAULT false, expires_at TIMESTAMPTZ NOT NULL);
CREATE INDEX ON refresh_tokens (fam);

CREATE TABLE email_login_codes (
  email TEXT NOT NULL, code_hash TEXT NOT NULL, used BOOLEAN NOT NULL DEFAULT false,
  expires_at TIMESTAMPTZ NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX ON email_login_codes (email, created_at);

CREATE TABLE devices (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES users(id),
  platform device_platform NOT NULL, model TEXT,
  integrity_state integrity_state NOT NULL DEFAULT 'untested',
  first_seen TIMESTAMPTZ NOT NULL DEFAULT now(), last_seen TIMESTAMPTZ NOT NULL DEFAULT now());

CREATE TABLE pois (
  id UUID PRIMARY KEY, creator_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL, description TEXT, category poi_category NOT NULL,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  h3_r9 BIGINT NOT NULL, checkin_radius_m INT NOT NULL,
  status poi_status NOT NULL DEFAULT 'active',
  checkin_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX ON pois USING GIST (location);
CREATE INDEX ON pois (h3_r9);

CREATE TABLE photos (
  id UUID PRIMARY KEY, poi_id UUID NOT NULL REFERENCES pois(id),
  uploader_id UUID NOT NULL REFERENCES users(id),
  storage_key TEXT NOT NULL UNIQUE, width INT, height INT, bytes INT,
  phash BIGINT, source photo_source NOT NULL,
  moderation photo_moderation NOT NULL DEFAULT 'pending',
  rejection_reason photo_rejection,
  vote_score INT NOT NULL DEFAULT 0, exif_summary JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX ON photos (poi_id, moderation, vote_score DESC);

CREATE TABLE checkin_nonces (
  nonce_hash TEXT PRIMARY KEY, user_id UUID NOT NULL, device_id UUID NOT NULL,
  poi_id UUID NOT NULL, used BOOLEAN NOT NULL DEFAULT false, expires_at TIMESTAMPTZ NOT NULL);

CREATE TABLE checkins (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES users(id),
  poi_id UUID NOT NULL REFERENCES pois(id),
  mode checkin_mode NOT NULL, photo_id UUID REFERENCES photos(id),
  status checkin_status NOT NULL, vaulted BOOLEAN NOT NULL DEFAULT false,
  h3_r7 BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), verified_at TIMESTAMPTZ,
  UNIQUE (user_id, poi_id));
CREATE INDEX ON checkins (user_id, created_at DESC);

CREATE TABLE checkin_evidence (
  checkin_id UUID PRIMARY KEY REFERENCES checkins(id),
  fixes JSONB NOT NULL, best_fix JSONB NOT NULL, distance_m NUMERIC,
  integrity JSONB NOT NULL, velocity JSONB, capture JSONB,
  verdicts JSONB NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now());

CREATE TABLE trust_events (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES users(id),
  type TEXT NOT NULL, delta SMALLINT NOT NULL, metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX ON trust_events (user_id, created_at DESC);

CREATE TABLE user_coverage (
  user_id UUID NOT NULL REFERENCES users(id), h3_r7 BIGINT NOT NULL,
  first_checkin_id UUID NOT NULL REFERENCES checkins(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY (user_id, h3_r7));

CREATE TABLE votes (
  user_id UUID NOT NULL REFERENCES users(id), photo_id UUID NOT NULL REFERENCES photos(id),
  value SMALLINT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, photo_id));

CREATE TABLE reports (
  id UUID PRIMARY KEY, reporter_id UUID NOT NULL REFERENCES users(id),
  target_type TEXT NOT NULL, target_id UUID NOT NULL, reason TEXT NOT NULL, note TEXT,
  status TEXT NOT NULL DEFAULT 'open', resolved_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now());

-- [M2] badges, health_daily · [M3] entitlements — declared in docs, created when built.
```

## 9. Privacy & safety invariants (MUST NOT ever)

- No background location collection, no motion/pedometer APIs, no Wi-Fi/BLE scanning. The
  app reads location only in foreground during map use and check-in.
- No third-party analytics/ad SDKs. Telemetry = our own API, event allowlist, no raw coords
  at > r7 precision in any event.
- Server logs MUST NOT contain: emails (log user IDs), tokens/nonces, exact coordinates
  (round to 3 decimals in logs), photo EXIF.
- `trust_score` and per-layer verification verdicts are NEVER returned by any API.
- Check-in history is private by default; only aggregate counts are public.
- Photos with `moderation != 'approved'` are served to their uploader only.
- Deleted accounts: purge PII + photos within 14 days; keep anonymized check-in rows
  (poi_id, h3, timestamps) for leaderboard integrity.

## 10. Testing & CI (merge gates — no exceptions)

- `npm run check` = Biome + `tsc --noEmit` + `vitest run`. CI runs it on every PR; red = no
  merge. CI also boots `postgis/postgis:16-3.4`, applies ALL migrations to an empty DB, and
  runs route tests against it.
- `src/verification/**` and (when built) vault/entitlement logic: ≥ 90% line coverage,
  table-driven tests, MUST include every worked example in §5.3 plus: nonce replay,
  nonce expiry, duplicate check-in, teleport violation, degraded integrity capping at
  pending, trust-gate forcing photo mode, track inconsistency.
- Route tests use `app.inject()` (no network). Pure modules get no mocks — real math.
- Flutter (when built): `flutter analyze` + unit tests for API client and check-in state
  machine; golden test for the stamp animation frame.

## 11. Localization & place names

The rule (modeled on how Pikmin Bloom renders Osaka): **places wear their own names; the
interface speaks the user's language.**

- **Basemap labels MUST use local endonyms** — the map style renders the tiles' `name`
  field (native-language names), never `name:en`. A user browsing Osaka sees 大阪市,
  whatever their device language. No transliteration overlay in MVP.
- **POI titles and descriptions are displayed exactly as authored**, in whatever script
  the creator wrote. No machine translation, no romanization, no script restrictions.
  Creators are nudged (placeholder copy) to name places in the local language.
- **All text is UTF-8 end-to-end**; validation MUST NOT restrict scripts. Length limits
  (e.g. title 3..80) count Unicode code points, not bytes and not UTF-16 units.
- **UI chrome is localized** to the device locale via Flutter's l10n (ARB) with English
  fallback; dates/numbers format per locale. Launch locales: en, pt (seed-city Portugal);
  adding a locale is an ARB file, never a code change.
- **Server-generated user-facing strings don't exist** — the API returns codes and data,
  never display copy (error `message` is for developers; clients localize from `code`).
- Search across scripts (normalization, transliterated queries) is deferred to M2 and
  MUST be listed there when built.

## 12. Definition of done (every PR)

1. Implements only SPEC'd behavior; SPEC updated in-PR if it had to change (called out).
2. `npm run check` green locally and in CI.
3. New behavior has tests at the layer it lives in (§10 minimums).
4. No new dependencies outside the allowlist (§1).
5. No TODOs without an issue reference; no commented-out code; no `console.log` (use the
   Fastify logger).
6. Errors use §3 envelope/codes exactly.
7. PR description lists SPEC sections touched.
