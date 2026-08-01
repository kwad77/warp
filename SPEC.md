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
| Flutter | 3.x stable (3.44.8 validated) | app; see mobile allowlist below |

Dependency allowlist (server prod deps): `fastify`, `zod`, `drizzle-orm`, `postgres`,
`jose`, `h3-js`, `sharp` (worker only), `graphile-worker`, `aws4fetch` (R2 presigning).
Anything else requires a SPEC edit in the same PR.

Dependency allowlist (mobile, `app/pubspec.yaml`): `maplibre_gl`, `camera`,
`google_mlkit_face_detection`, `flutter_riverpod`, `dio`, `freezed` + `freezed_annotation`
+ `build_runner` (dev; freezed's own codegen toolchain, not a separate decision) — all
named in the original product brief — plus **`flutter_secure_storage`**, added in M1 step 3
(Keychain/Keystore-backed token persistence; SharedPreferences would put JWTs in
plaintext, which fails SPEC §9's spirit even though §9 is written for the server).
`camera` and `google_mlkit_face_detection` are pre-approved but NOT yet in
`pubspec.yaml` — nothing in step 3 uses them, and adding them now would mean unused
native platform surface (camera/photo permissions) sitting in this PR for no reason;
they land in step 4 alongside the code that actually calls them (§13). **`image_picker`**
is added in step 4 alongside them — a NEW dependency not named in the original product
brief, flagged here: §6 explicitly allows a gallery/roll picker for POI-creation photos
("POI-creation flow MAY [offer gallery]"), and `camera`'s plugin surface has no photo-
library picker of its own. **`geolocator`** is also added in step 4 — flagged here as a
gap the original brief never named: nothing in this allowlist reads the device's GPS fix
at all, and both POI creation (a single `gpsFix`, §13.1) and check-in (`MIN_FIXES..
MAX_FIXES` fused fixes, §5.1) need one. `geolocator` is the standard maintained Flutter
plugin for this (position + accuracy + its own permission-request flow — no separate
`permission_handler` needed for the read-only foreground use this app makes of it).
**`image`** (pure Dart, no platform channel) is added for the client-side photo resize
§13.1 always deferred until now — decode/resize/re-encode only, no camera/gallery access
of its own, so it doesn't expand native permission surface the way the others did. No `json_serializable`
— model classes write `fromJson`/`toJson` by hand (freezed's immutability/`copyWith`/
union support doesn't require it, and it avoids a second codegen package for a handful
of simple DTOs). No routing package — `Navigator`/`MaterialApp` routes suffice at this
app's current size; revisit if nested/deep-link routing is needed.

```
server/    src/{config,app,index,constants,errors}.ts, src/db/, src/routes/,
           src/verification/, src/geo/, src/auth/, src/storage/, src/lib/,
           migrations/*.sql, test/
app/       Flutter project — lib/{core,features}/, test/ (layout: SPEC §12)
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
  Implemented via `createOidcVerifier` (`src/auth/oidc.ts`, `jose`'s `createRemoteJWKSet`
  against `appleid.apple.com`/`googleapis.com`'s public JWKS — no new dependency).
  **Config-gated, same pattern as R2 storage (§6) and moderation (§6):** each provider
  needs its own `APPLE_CLIENT_ID` / `GOOGLE_CLIENT_ID` env var (the app's bundle id /
  OAuth client id) — real values only a human with Apple Developer / Google Cloud console
  access can create, not something this repo can provision. Unset ⇒ `501
  service/unavailable`, identical to the placeholder behavior before this was built. The
  verification logic itself is fully tested (`test/oidc.test.ts`, no network — a locally
  generated keypair + `createLocalJWKSet` stands in for the real JWKS) and exercised
  end-to-end against real PostGIS with a locally-keyed verifier
  (`test/auth.provider.integration.test.ts`) — only the two client ids are missing to go
  live, not any of the code.
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
verifiers were planned for M1 step 4 — scoped back out, flagged in §13.2: Play Integrity
decodeIntegrityToken needs a Google Cloud/Play Console project + service account, App
Attest verification needs Apple's root CA and a paid Developer Program enrollment —
credentials this environment cannot obtain or provision. `RealIntegrityVerifier` stays an
unbuilt named seam (same treatment as `RekognitionModerationProvider`, §6) behind
`INTEGRITY_VERIFIER` env (default `dev`); mobile step 4 sends a `DevIntegrityTokenProvider`
token shaped like the server's own dev format so the flow is exercised end-to-end. In
production this is unchanged from step 2: every integrity evaluation returns `degraded`
until a real verifier is wired in — honest by construction, never a fabricated `pass`.]**
`DevIntegrityVerifier` (active only when `NODE_ENV ≠
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
  `photo/rejected (details.reason='quality')` and no row. Pixel-dimension checks (below)
  require the actual bytes, fetched separately during moderation, not at this HEAD-only
  step (kept HEAD-only deliberately, to keep upload latency low).
- Moderation (before ANY public visibility): provider face/person detection + safety
  labels behind interface `ModerationProvider`. Any person ⇒ `rejected(people)`.
  Borderline ⇒ `escalated` (human queue). pHash (64-bit) computed here, alongside a
  pixel-dimension check: `storage.get` fetches the real bytes (§13.1's `Storage`
  interface gained a `get` alongside `presignPut`/`head`); a long edge below
  `UPLOAD_MIN_LONG_EDGE_PX` ⇒ `rejected(quality)` before the moderation provider even
  runs. Implemented as a difference hash (dHash: 9×8 grayscale, 64 one-bit horizontal
  adjacent-pixel comparisons) via `sharp` — a DCT-free 64-bit perceptual hash, not the
  DCT-based algorithm "pHash" more narrowly refers to elsewhere; called out so a future
  implementer doesn't assume DCT. `storage.get` failing or returning nothing (e.g. object
  storage unconfigured) degrades to skipping these checks rather than failing the
  request — they're enrichment on top of validation the presign/complete step already
  did, not a substitute for it.
- A photo rejection NEVER changes its check-in's status (§5.7 owns that).
- States: `pending → approved | rejected(reason) | escalated → approved|rejected`.

**M1 implementation note — scoped down from the async worker design, called out
explicitly:**
- `completePhoto` invokes the configured `ModerationProvider` **synchronously, in-process**
  (not via a job queue) immediately after inserting the `pending` row, then applies the
  verdict to the same row before the request returns. The `201` response body still
  reflects the row as freshly inserted (`moderation: 'pending'`) — callers re-fetch
  (`GET /pois/:id`) to see the resolved state; this keeps the response contract stable
  regardless of which provider is behind it.
- `DevModerationProvider` (M1's only implementation) always returns `approved` with a log
  line. It is synchronous and instant, which is *why* M1 can skip the job queue: nothing
  yet does network I/O here. The async `graphile-worker` design in ARCHITECTURE.md remains
  the target the moment a real network-calling provider (Rekognition or equivalent) is
  wired in — a synchronous Rekognition call in the request path would add real, unbounded
  latency to every photo upload, which is not acceptable once it's real.
- **Deferred, not decided — needs your call before building:**
  1. **Real detector.** No AWS SDK (or any Rekognition client) is in the §1 allowlist yet;
     adding one is a dependency decision (cost, credentials, data-processing terms) this
     spec isn't making unilaterally. `RekognitionModerationProvider` exists as a named seam
     (selected via `MODERATION_PROVIDER` env, default `dev`) that throws
     `service/unavailable` if ever selected, so the integration point is ready without the
     dependency being added silently.
  2. **Human-review admin surface** (docs/MILESTONES.md M1 step 5) needs its own auth
     realm — undesigned. Not stubbed as a fake-authed endpoint; simply not built yet.
     `escalated` is a reachable enum state with no consumer until this exists.

  **pHash and the pixel-dimension check are no longer on this list — implemented.**
  They were bundled here alongside the real detector originally, but on closer look the
  stated blocker (needing the actual bytes + `sharp`) doesn't actually require a new
  dependency or credential decision: `sharp` was already in the §1 allowlist, just never
  installed. Corrected rather than left to silently rot as a stale "needs your call" that
  no longer described a real blocker.

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
  runs route tests against it. A separate CI job runs `flutter analyze` + `flutter test`
  for `app/` on every PR — both jobs must be green (`.github/workflows/ci.yml`).
- `src/verification/**` and (when built) vault/entitlement logic: ≥ 90% line coverage,
  table-driven tests, MUST include every worked example in §5.3 plus: nonce replay,
  nonce expiry, duplicate check-in, teleport violation, degraded integrity capping at
  pending, trust-gate forcing photo mode, track inconsistency.
- Route tests use `app.inject()` (no network). Pure modules get no mocks — real math.
- Flutter, M1 step 3 (map/browse/auth): `cd app && dart run build_runner build
  --delete-conflicting-outputs && flutter analyze && flutter test` — codegen must be
  regenerated and committed (`*.freezed.dart` files ARE checked in, matching Flutter
  community convention, so CI doesn't need the Dart SDK's codegen step to be
  reproducible-by-accident). Unit tests required for: the API client (every endpoint this
  slice calls, success + every mapped error code) and the auth/refresh interceptor
  (attaches token, refreshes once on `auth/expired`, clears + surfaces logged-out on
  refresh failure). No live device/emulator is available in this sandbox — widget/golden
  tests for map rendering are deferred to when one is; `flutter test` covers
  non-rendering logic only for this slice.
- Flutter, M1 step 4 (check-in flow): the check-in state machine (`CheckinController`) has
  exhaustive plain-Dart unit tests (every response branch — verified/pending/rejected/
  duplicate/photo-blocked/fix-timeout/nonce-expired-retry). **Revised from the original
  plan:** a golden test for the stamp-animation frame, and a fuller tap-through-to-
  verified `testWidgets` test, were both attempted and abandoned — `flutter test`'s
  `AutomatedTestWidgetsFlutterBinding` pump loop didn't reliably drain the real Dio async
  chain within a bounded number of `pump()` calls (with or without `Stream.timeout()` in
  play), and `pumpAndSettle()` times out outright against the `inProgress` state's
  indeterminate spinner. A `testWidgets` test covering the screen's initial render under
  the real provider graph exists instead; the flow logic itself is the unit tests' job.

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

## 12. Mobile app — map, browse, auth (M1 step 3; exact)

Scope: MapLibre map with server-driven clustering, POI detail, email-code auth. Check-in
flow, camera, and on-device face detection are M1 step 4 — not covered here.

**Layout** (`app/lib/`):
```
main.dart
core/
  api_client.dart      Dio instance: base URL, auth header injection, refresh interceptor
  api_exception.dart   ApiException{code, message, details} — parses the SPEC §3 envelope
  token_store.dart      flutter_secure_storage wrapper: read/write/clear access+refresh
  constants.dart         API base URL default, map style URL, SPEC_CONSTANTS mirror (§2
                          values this client needs — currently none; add as UI needs them)
models/
  user.dart, poi.dart, poi_pin.dart, cluster.dart, photo.dart   hand-written fromJson;
  freezed for immutability/copyWith/equality
features/
  auth/   auth_controller.dart (Riverpod), email_auth_screen.dart
  map/    map_screen.dart, map_controller.dart (Riverpod: fetches /pois for the current
          viewport+zoom, debounced on camera-idle)
  poi/    poi_detail_sheet.dart (fetches GET /pois/:id on open)
```

**API base URL**: `String.fromEnvironment('API_BASE_URL', defaultValue: ...)`, default
`http://10.0.2.2:8080` (Android emulator → host loopback). iOS simulator run instructions
use `--dart-define=API_BASE_URL=http://localhost:8080` (shares host networking directly).

**Map style**: `https://tiles.openfreemap.org/styles/liberty` (OpenFreeMap, matches
ARCHITECTURE.md's MapLibre choice, zero cost). Hardcoded for M1; pinning a
self-hosted/versioned style is a pre-launch hardening item (ARCHITECTURE.md §12), not
blocking now.

**Auth flow**: email-code only for this slice (Apple/Google are server-side 501 per §4,
so the client doesn't build UI for them yet). `AuthController` (Riverpod) states:
`loggedOut | codeSent(email) | loggedIn(user)`. On `loggedIn`, tokens persist via
`TokenStore` immediately. App launch reads `TokenStore`; a present access token means
optimistically `loggedIn` (no eager `/me` call — the first authenticated request either
succeeds or the interceptor's refresh path resolves it).

**Auth header + refresh interceptor** (`ApiClient`, Dio `Interceptor`):
1. Every request: if an access token is stored, attach `Authorization: Bearer <token>`.
2. On a `401` response: if this request has already been retried once, propagate the
   error (no infinite loop). Otherwise call `POST /v1/auth/refresh` with the stored
   refresh token; on success, persist the new pair and retry the original request once;
   on failure (any error), clear `TokenStore` and propagate a distinguished
   `ApiException(code: 'auth/session_expired')` — a client-local code (not a server one)
   the UI maps to "logged out, please sign in again."
3. Map browsing (🌐 endpoints) never triggers step 2 — the interceptor only attempts
   refresh for requests that included an `Authorization` header in the first place.

**Clustering rendering** (no client-side logic — server already decided): the client
calls `GET /pois?bbox=&zoom=` with the current viewport and integer zoom on every
camera-idle event (debounced 300ms); it renders `clusters[]` as cluster markers
(labeled with `count`) when present and `pois[]` as individual pins otherwise — exactly
whichever array the response returned non-empty, never both. Tapping a pin opens
`poi_detail_sheet` via `GET /pois/:id`; tapping a cluster zooms in (no separate
expand-cluster endpoint).

**Error handling convention**: `ApiException.code` is pattern-matched for exactly the
cases the UI treats specially (`rate/limited` → "try again in a moment"; local
`auth/session_expired` → route to auth screen); everything else shows a generic
"something went wrong, pull to retry" — never the raw `message` (§11: server strings are
for developers).

## 13. Mobile app — POI creation & check-in (M1 step 4; exact)

Scope: everything gated behind "Flutter app: create + check in" in `docs/MILESTONES.md`.
Built as two PRs; this section is written incrementally — the **POI creation** subsection
below is exact and implemented; **check-in flow** (nonce intent, fix gathering, capture
token, success/retry UX) follows in a subsequent PR and is appended here, not filed as a
new section, when it lands.

### 13.1 POI creation

**New dependencies** (mobile allowlist, §1): `camera` and `google_mlkit_face_detection`
land in `pubspec.yaml` now — pre-approved in the original brief, deferred until this PR
per §1's note. `image_picker` also lands now — flagged as a new dependency in §1's entry
above (needed for the gallery path §6 explicitly allows for POI-creation photos only).
`geolocator` also lands now — flagged in §1 as a genuine spec gap (nothing previously
named a GPS-fix package at all); this PR uses only its single-fix read
(`LocationSource.currentFix()` below), the multi-fix gathering check-in needs is built on
the same package in the follow-up PR.

**Location abstraction** (`lib/features/poi/location_source.dart`, reused by check-in):
`abstract class LocationSource { Future<GpsFix> currentFix(); }`, backed by
`GeolocatorLocationSource` (real: `Geolocator.requestPermission()` then
`Geolocator.getCurrentPosition()`). A small interface, not a direct `geolocator`
dependency in the controller, for the same testability reason as `SecureStore`/`FaceGate`
— `geolocator`'s concrete implementation needs a real device/emulator to run.

**Layout additions** (`app/lib/`):
```
features/poi/
  poi_create_screen.dart     title/description/category form + pin-adjust map + photo step
  poi_create_controller.dart Riverpod: holds draft state, calls POST /pois, handles the
                              201 vs 200 dedupeCandidates branch, drives photo upload after
  face_gate.dart              wraps google_mlkit_face_detection: given an image file/bytes,
                              returns pass/blocked; used by both camera and gallery paths
```

**Entry point**: a "Create POI" affordance on the map screen (long-press on the map, or an
app-bar action that drops a pin at the current map center) opens `poi_create_screen` with
the tapped/centered map coordinate as the initial `location` candidate. The device's
current single GPS fix (not the multi-fix check-in flow — this is one fix, best-effort) is
captured as `gpsFix` at screen-open time.

**Pin adjustment**: the user may drag the pin on a small embedded map before submitting.
Client enforces `haversine(location, gpsFix) ≤ PIN_ADJUST_MAX_M` (§2) locally for
immediate feedback (drag beyond that radius snaps back / shows a "too far from your
location" hint); the server remains authoritative and a `422 poi/outside_pin_adjust` is
still handled (inline error on the map, not a toast — the user needs to see the pin to
correct it), since the local check is advisory only (stale/low-accuracy `gpsFix`).

**Form fields**: title (3..80 code points, enforced client-side before submit as well as
server-side), description (optional, ≤280), category (single-select over the §8 enum:
`landmark | viewpoint | nature | architecture | street_art | other`).

**Photo (optional for POI creation)**: user picks camera (`camera` package) or gallery
(`image_picker`), both explicitly labeled "for creating places only" (§6). Whichever image
results, it MUST pass the face-detection gate (`face_gate.dart`, ML Kit) before anything
uploads — this runs for both paths identically (§6: "this gate runs before upload for BOTH
flows"). Any face detected ⇒ block, offer retake (camera) or reselect (gallery); never a
silent auto-crop, blur, or bypass. No photo is a valid submission — `POST /pois` has no
photo field (§7); a photo, if present, uploads only after the POI exists.

**Submit flow**: `POST /pois {title, description?, category, location, gpsFix, force?}`.
- `201 {poi}` → if a photo was captured/picked and passed the gate, upload it now against
  the new POI (`POST /pois/:id/photos/presign {contentType, source: "poi_creation"}` → PUT
  the resized (≤ `UPLOAD_MAX_LONG_EDGE_PX`) bytes → `POST /pois/:id/photos/complete
  {storageKey, source: "poi_creation"}`); then navigate to the POI's detail screen
  regardless of upload outcome (a failed photo upload does not undo POI creation — surface
  a retry affordance on the detail screen instead of blocking navigation).
- `200 {dedupeCandidates: PoiPin[]}` → dedupe picker screen: list/mini-map of the
  candidates ("Is this place already here?"). Selecting one navigates to its detail
  screen; nothing is created. "None of these — create mine" resubmits the identical
  payload with `force: true`.
- `422 poi/outside_pin_adjust` → inline pin-adjust error (not the generic error handler).
- `429 rate/limited` → `details.retryAfterS` surfaced per the existing §12 error
  convention (POI_CREATE = 20/day, §2).
- Any other error ⇒ the existing generic `ApiException` handling (§12).

**Client-side resize** (`lib/core/image_resize.dart`, `resizeForUpload`): decodes the
captured/picked bytes, downscales (never upscales) so the long edge is ≤
`UPLOAD_MAX_LONG_EDGE_PX`, and re-encodes to JPEG regardless of source format — the
declared `contentType` is always `image/jpeg` (§13.1's dependency note), so the bytes
must actually be JPEG, not merely mislabeled. Starts at quality 85; if that encode still
exceeds `UPLOAD_MAX_BYTES`, quality steps down by 10 (floor 30) until it fits or the floor
is hit — confirmed necessary, not hypothetical: a genuinely detailed/noisy photo at the
full `UPLOAD_MAX_LONG_EDGE_PX` can exceed `UPLOAD_MAX_BYTES` at quality 85 alone (verified
against a synthetic worst-case image: 12MB source → 1.27MB at quality 85 alone, 0.85MB
with quality stepping, same 2048px long edge). The server's HEAD check (§6) remains the
backstop if even the floor doesn't fit — this just makes that rejection the exception
rather than routine for detailed photos. Pure function, no I/O: takes and returns bytes,
so it's unit-tested directly against synthetically generated (noisy, not flat-color —
flat color compresses unrealistically well and wouldn't exercise the quality-stepping
path) images, no device or real photo fixture needed, rather than behind a fake-backed
interface like `FaceGate`/`LocationSource`. **New dependency** (mobile allowlist, §1):
`image` (pub.dev, pure Dart — no platform channel, decode/resize/encode only) for this.

**Known limitation, flagged, not silently accepted:** the pure-Dart `image` package
cannot decode HEIC/HEIF — the default capture format on iOS's Photos library (though
`camera`-captured frames are JPEG and unaffected). `resizeForUpload` returns `null` on an
undecodable image; both POI creation and check-in (§13.2) treat that as a new
`photoProcessingFailed` state — checked before any network call, alongside the
face-detection gate, not after — surfacing "couldn't process this photo, try another"
rather than silently uploading a mislabeled or unresized file. A HEIC-capable path (e.g.
platform-channel decoding) is a follow-up if this proves common in practice.

### 13.2 Check-in flow

**New dependency** (mobile allowlist, §1): `crypto` (dart-lang official package) — needed
for the SHA-256 capture-token hash (§5.5). Minimal, no transitive deps, same publisher
family as the SDK itself; the smallest correct choice for one hash function.

**Device registration**: lazy, once, cached. Before the first `checkins/intent` call in
the life of the install, if no `deviceId` is cached, `POST /devices {platform, model?}` →
cache `deviceId` (new `DeviceStore`, `SecureStore`-backed, same pattern as `TokenStore`;
`platform` from `Platform.isIOS ? 'ios' : 'android'`, `model` omitted — no device-model
lookup dependency for a field the server already treats as optional).

**Entry point**: a "Check in" action on `PoiDetailSheet` (SPEC §12) opens a check-in
screen for that POI. Mode choice first: **photo** or **confirm** (no default — SPEC §5.6
can hard-reject a low-trust `confirm` with `photo_required`, so the choice matters and
isn't hidden). Confirm mode has no camera step at all.

**Flow** (`lib/features/checkin/`):
1. Ensure device registered (above); `POST /checkins/intent {poiId, deviceId}` →
   `{nonce, expiresInS}`. `checkin/duplicate` here ⇒ "You've already checked in here,"
   no retry affordance (not a transient failure).
2. Collect fixes: `FixCollector.collect(fixStream, minFixes: MIN_FIXES, maxFixes:
   MAX_FIXES, minSpan: FIX_SPAN_MIN_S, maxWindow: FIX_WINDOW_MAX_S)` — pure over each
   fix's own `capturedAt` (no wall-clock reads, so it's unit-testable against a synthetic
   fix stream); stops once `maxFixes` reached OR (`minFixes` reached AND span ≥
   `minSpan`), else runs until `maxWindow` elapsed. The real `LocationSource.fixStream()`
   (extends the §13.1 interface with a continuous stream, `Geolocator
   .getPositionStream`) is wrapped in a real wall-clock `.timeout(FIX_WINDOW_MAX_S + 10s)`
   by the caller, not inside the pure collector, so a stalled GPS stream can't hang the
   screen forever. Fewer than `MIN_FIXES` collected when the window closes ⇒ "Couldn't
   get a clear location fix — try again outdoors" with a retry (fresh intent, step 1).
3. Photo mode only: open the same in-app camera capture screen as §13.1 (extended to also
   return the shutter timestamp) — no gallery option, ever, in this flow (§6). At shutter:
   `capturedAt = DateTime.now().toUtc()`, `token = sha256("<nonce>.<capturedAt
   .millisecondsSinceEpoch>")` hex — MUST match the server's `Date.parse` of the same
   `capturedAt` ISO string it's sent alongside (§5.5's exact formula, computed client-side
   here since the server only re-derives the same ms value from the string we send). Runs
   through the same `FaceGate` as §13.1 before upload; a face ⇒ retake, same as POI
   creation. Then the same `resizeForUpload` (§13.1) runs before upload; `null` (undecodable
   image) ⇒ `photoProcessingFailed`, checked before any network call, same as POI creation.
   Photo then uploads via presign → PUT → complete (`source: "checkin"`) BEFORE
   submit, so `capture.storageKey` resolves to an existing row (§5.5's `photoFound` check).
   The capture-token hash (`sha256("<nonce>.<capturedAtMs>")`) is over the nonce and
   shutter timestamp only, never the image bytes — resizing doesn't touch it.
4. `integrityToken`: `IntegrityTokenProvider.token(nonce)` — `DevIntegrityTokenProvider`
   (the only implementation; real platform attestation is scoped out, §5.2) returns
   `"dev.pass.<nonce>"`, matching the server's `DevIntegrityVerifier` format exactly so the
   dev/local flow is exercised end-to-end.
5. `POST /checkins {nonce, poiId, mode, fixes, integrityToken, capture?}`.

**Response handling**:
- `201 {checkin}`, `status: 'verified'` → success screen (stamp/animation per
  `docs/MILESTONES.md`'s "success animation").
- `201 {checkin}`, `status: 'pending'` → pending screen — explicitly NOT the same as
  success; copy explains review is in progress, no false confirmation.
- `422 checkin/rejected` → `details.reasons[]` shown plainly (no jargon translation
  table in this PR — raw reason codes are still more honest than a generic failure, and
  §11's "server strings are for developers" is about `message`, not this `details` array,
  which SPEC already treats as user-facing via UI, e.g. `photo_required` ⇒ prompt
  switching to photo mode). Retry ⇒ fresh intent (step 1); the nonce is already consumed
  (§5.7) so re-submitting the same nonce is never attempted.
- `409 checkin/duplicate` → "Already checked in," no retry.
- `410 checkin/nonce_expired` → silently retries once from step 1 (fresh intent) without
  surfacing an error — an expired nonce during normal use is a UX papercut, not a user
  mistake to explain.
- `429 rate/limited` → `details.retryAfterS`, existing §12 convention.
- Any other error ⇒ existing generic `ApiException` handling (§12).

`Checkin = {id, poiId, status: 'verified'|'pending'|'rejected', mode, createdAt,
verifiedAt?}` (mirrors `CheckinView` server-side exactly, §7).

## 14. Mobile app — profile, personal map, coverage, leaderboard (M1 step 6; exact)

Scope: everything under `docs/MILESTONES.md`'s M1 step 6 one-liner. Replaces the
Account tab's placeholder (`main.dart`'s `RootScreen`, currently just "Signed in as
{handle}") with a real profile screen. No new server work — SPEC §7's `GET /me`, `GET
/me/map`, `GET /me/coverage`, `GET /leaderboards/coverage` are unchanged and already
implemented; this section is purely the mobile consumption of them.

**Layout additions** (`app/lib/features/profile/`):
```
profile_screen.dart       stats header, My Places (created/checked-in lists), coverage
                          count, weekly leaderboard, sign-out
profile_controller.dart   Riverpod: loads GET /me + /me/map + /me/coverage +
                          /leaderboards/coverage?window=weekly&scope=global concurrently
                          (Future.wait) on open; single loading/loaded/error state, no
                          per-section spinners — SPEC has no requirement forcing
                          progressive reveal, and one round-trip is simpler
```

**New models** (`app/lib/models/`): `MeStats {checkins, cellsCovered, poisCreated}`,
`MeMap {checkedIn: PoiPin[], created: PoiPin[], vaulted: PoiPin[]}` (`vaulted` rendered
as an empty section in M1 — always `[]` server-side until M3), `LeaderboardEntry {rank,
handle, cells}` (top-list rows), `MeStanding {rank, cells}` (the optional `me` field —
deliberately a separate type: it never has a `handle`, so this avoids a
nullable-and-sometimes-missing field on `LeaderboardEntry`).

**Content**:
- Stats header: `stats.checkins` check-ins, `stats.cellsCovered` cells, `stats.poisCreated`
  places created (SPEC §7's exact `GET /me` counts — verified check-ins only, POIs with
  `status <> 'removed'`).
- My Places: two lists (created / checked-in) of `PoiPin`s, each row tappable → the
  existing `PoiDetailSheet` (§12), same as map pins. `vaulted` renders only if non-empty
  (never is, in M1) — no separate "sealed" UI is built for a state that can't occur yet.
- Coverage: `GET /me/coverage`'s `count` shown as "N map cells explored." **Scope
  reduction, flagged:** the `cells` array (H3 r7 hex ids) is fetched but not rendered as a
  map overlay in this PR — a personal coverage heatmap is a real feature, not a one-line
  addition, and SPEC's step-6 one-liner doesn't itself demand the visualization, only "the
  coverage." Deferred to a follow-up if the count-only view proves insufficient.
- Weekly leaderboard: `GET /leaderboards/coverage?window=weekly&scope=global`'s
  `entries` (rank/handle/cells) in a simple ranked list; `me` (when present, i.e. the
  request carried a valid bearer token) shown pinned below the list if not already in it,
  matching §7's "entries capped at `LEADERBOARD_ENTRIES_MAX`" — `me` existing outside that
  cap is the normal case being handled, not an edge case being ignored.
- Sign out: calls the existing `AuthController.signOut()` (SPEC §12) — wired here because
  this is the first screen with a natural place for it; §12 built the method but never a
  button.

**Error handling**: existing generic `ApiException` handling (§12) — a single load
failure shows a retry affordance for the whole screen, not per-section (same one-round-
trip reasoning as above).

## 15. Definition of done (every PR)

1. Implements only SPEC'd behavior; SPEC updated in-PR if it had to change (called out).
2. `npm run check` green locally and in CI.
3. New behavior has tests at the layer it lives in (§10 minimums).
4. No new dependencies outside the allowlist (§1).
5. No TODOs without an issue reference; no commented-out code; no `console.log` (use the
   Fastify logger).
6. Errors use §3 envelope/codes exactly.
7. PR description lists SPEC sections touched.
