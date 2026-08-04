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
of its own, so it doesn't expand native permission surface the way the others did.
**`path_provider`** is added in the offline check-in outbox slice (§17, M2) — the standard
Flutter plugin for locating the app's own documents directory; needed for a durable
(survives-restart) local queue of unsent check-ins (JSON manifest + copied photo files).
No credentials/cost and no new native permission prompt (it's app-sandboxed storage the
app already implicitly has access to, unlike camera/location/photo-library).
**`share_plus`** is added in the Instagram-style browsing & sharing slice (§19, M2) — the
standard Flutter plugin wrapping each platform's native share sheet (iOS `UIActivityViewController`,
Android `Intent.ACTION_SEND`). No credentials/cost; no new native permission beyond what
the OS's own share UI requires (none, beyond the share sheet itself appearing). No `json_serializable`
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
  COVERAGE_HEATMAP_RESOLUTIONS = [2, 3, 5, 7]   // coarse→fine drill-down tiers, §15

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

EVIDENCE (§5.1/§5.3/§5.5, §17 offline outbox)
  CLOCK_SKEW_S               = 30        // existing L4 tolerance, now named + shared
  CHECKIN_LIVE_MAX_AGE_S     = 150       // CHECKIN_NONCE_TTL_S + CLOCK_SKEW_S
  CHECKIN_DEFERRED_MAX_AGE_S = 86_400    // 24h bound on offline-captured (deferred) evidence

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

The submit body carries an optional `evidence: "live"|"deferred"` (default `"live"`, §17
offline outbox). It is the only thing that changes L1→L5's behavior: it selects the
freshness bound fixes/capture are checked against (§5.3, §5.5) and whether the resulting
coverage counts toward the competitive leaderboard (§7) — confidence, velocity, and trust
math are identical either way.

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

**Evidence freshness (§17 offline outbox; pure, `src/verification/freshness.ts`):** before
any of the above, the most recent fix's `capturedAt` is checked against `now`: it must be
no more than `CLOCK_SKEW_S` in the future, and no older than `CHECKIN_LIVE_MAX_AGE_S`
(`evidence: "live"`) or `CHECKIN_DEFERRED_MAX_AGE_S` (`evidence: "deferred"`). A violation
is evidence integrity, not a confidence signal — it hard `reject(stale_evidence)`s
regardless of how well the fixes would otherwise score, same tier as `accuracy_ceiling`.

### 5.4 L3 Velocity (pure, same module)

Against the user's most recent check-in with status `verified` or `pending`:
`v = haversine(prev, best_fix) / Δt`. Violation if `v > MAX_SPEED_KMH` OR
(`Δt < TELEPORT_WINDOW_S` AND distance > `TELEPORT_DISTANCE_M`). Violation ⇒ cap at
`pending(velocity)` + trust event `velocity_violation` (NOT a hard reject — flights and
clock skew exist). First-ever check-in: skip.

### 5.5 L4 Capture (photo mode only)

`capture.token` MUST equal hex sha256 of `"<nonce>.<capturedAtMs>"` (minted app-side at
shutter — tamper-evidence only; real assurance is the attested app, L1), and
`capture.capturedAt` MUST pass the same evidence-freshness check as fixes (§5.3) — this
replaces M1's narrower nonce-window-only bound with the named `CHECKIN_LIVE_MAX_AGE_S`/
`CHECKIN_DEFERRED_MAX_AGE_S` ± `CLOCK_SKEW_S` check, a superset for `evidence: "live"` (a
live check-in's nonce window is inside `CHECKIN_LIVE_MAX_AGE_S` by construction), not a
behavior change for any check-in that could pass before.
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
| `GET /pois/nearby?lat=&lng=&radiusM=` | 🌐 | `radiusM` optional, default 2000, max 10000 → `{pois: PoiPin[]}` active only, ordered by distance, max 50; `thumbnailUrl` populated (§19, M2 — bounded result count, cheap enough to compute per request) |
| `GET /pois/:id` | 🌐 (optional auth) | → `{poi: Poi}` (gallery: approved photos, vote-ranked, max 20). Only `removed` ⇒ 404; `pending_review`/`flagged` POIs serve normally until moderation resolves them. Each gallery photo's `myVote` (M2) reflects the caller's own vote on it — `false` for an anonymous caller or one who hasn't voted, same optional-auth pattern `GET /leaderboards/coverage`'s `me` already uses. |
| `POST /pois` | ✅ | `{title(3..80 code points), description?(..280), category, location, gpsFix: Fix, force?: bool}` → `201 {poi}` or `200 {dedupeCandidates: PoiPin[]}`. Rules: haversine(location, gpsFix) ≤ `PIN_ADJUST_MAX_M` else `poi/outside_pin_adjust`; creation dedupe is **proximity-only** (active POIs within `DEDUPE_RADIUS_M`, found via r9 neighbor cells) — pHash similarity runs later in photo moderation (M1.5); `force: true` skips the dedupe prompt; rate limit §2. New POI: `status='active'`, radius from category (§2). |
| `POST /pois/:id/photos/presign` | ✅ | `{contentType ∈ ALLOWED_MIME, source: "poi_creation"\|"checkin"}` → `{uploadUrl, storageKey, maxBytes}` (key format §6; no row created yet) |
| `POST /pois/:id/photos/complete` | ✅ | `{storageKey, source}` → `201 {photo: Photo(moderation=pending)}` — key embeds photoId; server checks HEAD + mints row with uploader = caller (§6). **Idempotent**: the same caller re-completing the same key gets the existing photo back (retry-safe); a different caller ⇒ `request/invalid`. |
| `POST /checkins/intent` | ✅ | `{poiId, deviceId}` → `{nonce, expiresInS}` |
| `POST /checkins` | ✅ | `{nonce, poiId, mode: "photo"\|"confirm", fixes: Fix[2..5], integrityToken, evidence?: "live"\|"deferred" (default "live", §17), capture?: {token, capturedAt, storageKey}}` → `201 {checkin: {id, status, poiId, mode, evidence, verifiedAt?}}`; rejected ⇒ `422` per §5.7 (now also `stale_evidence`, §5.3); `Fix = {lat, lng, accuracyM, capturedAt}` |
| `GET /checkins/:id` | ✅ owner | → `{checkin}` (non-owner ⇒ 404, §5.7) |
| `GET /me` | ✅ | → `{user, stats: {checkins, cellsCovered, poisCreated, creatorScore}}` — `checkins` counts `status='verified'` only; `poisCreated` counts the caller's POIs with `status <> 'removed'`; `cellsCovered` = `user_coverage` row count; `creatorScore` = sum of `checkin_count` across those same POIs (§16, M2); `user.displayName` (§21, M2) reflects the caller's own current opt-in choice |
| `PATCH /me/display-name` | ✅ | `{displayName: string(1..40 code points) \| null}` → `{displayName}` (§21, M2) — `null` clears it; a profanity-flagged name ⇒ `request/invalid` (`details.reason: 'profanity'`) |
| `GET /me/map` | ✅ | → `{checkedIn: PoiPin[], created: PoiPin[], saved: PoiPin[], vaulted: PoiPin[]}` — `checkedIn` = POIs with a verified check-in by the caller (deduplicated per POI — M2 fix, §19; multiple verified check-ins at the same POI previously produced duplicate pins); `created` = caller's POIs with `status <> 'removed'`; `saved` = the caller's `saved_pois` rows, most recently saved first (§19, M2); `vaulted` is always `[]` in M1 (vault ships M3; SPEC §6 of MVP.md). `thumbnailUrl` populated on all three real arrays (§19, M2). |
| `POST /pois/:id/save` | ✅ | `{value: 1\|0}` (0 = unsave) → `{saved: bool}` — upsert/delete on `(user_id, poi_id)` (§19, M2); saving a non-`active` POI ⇒ `resource/not_found` (no visibility leak, same pattern as photo voting) |
| `GET /me/coverage` | ✅ | → `{cells: string[] (h3 r7, lowercase hex), count}` |
| `GET /me/coverage/heatmap?zoom=` | ✅ | → `{cells: [{h3, count, centroid: {lat, lng}}], resolution}` — `zoom` (0..22) maps to an H3 resolution per §15's table; `count` = number of the caller's r7 cells under each returned coarser cell (§15, M2) |
| `GET /me/badges` | ✅ | → `{badges: [{badgeKey, awardedAt}]}`, ordered by `awardedAt ASC` (§16, M2) |
| `GET /me/checkins?cursor=&limit=50` | ✅ | → `{items: CheckinListItem[], nextCursor?}` — keyset pagination per the convention below; `limit` max 100. `CheckinListItem = {id, poiId, poiTitle, poiCategory, status, mode, evidence, createdAt, verifiedAt?}` — `poiTitle`/`poiCategory` (M2 addition; this row previously never actually specified the item shape) come from a plain `JOIN pois` (not `LEFT`, same assumption `GET /me/map`'s `checkedIn` already makes: a POI is soft-deleted, never hard-deleted, so every checkin's `poiId` always resolves) |
| `DELETE /me` | ✅ | → `{ok}` — soft-delete now (`deleted_at`), hard purge after 14 d (worker, M1.5); revokes every refresh-token family for the user in the same request (immediate logout everywhere) |
| `GET /me/export` | ✅ | *(M1.5 — requires the job queue, which does not exist yet; until then, 501 `service/unavailable`)* |
| `POST /photos/:id/vote` | ✅ | `{value: 1\|0}` (0 = retract) → `{voteScore}` — upsert on `(user_id, photo_id)`; `voteScore` on `photos` is the denormalized sum, updated in the same transaction; voting on a non-`approved` photo ⇒ `resource/not_found` (no visibility leak into pending/rejected review state) |
| `POST /reports` | ✅ | `{targetType: "poi"\|"photo", targetId, reason: "people"\|"unsafe"\|"wrong_location"\|"duplicate"\|"other", note?(..280)}` → `201 {ok}` — target must exist (else `resource/not_found`); rate limit §2; no dedupe on repeat reports from the same user in M1 (moderation queue is M1.5+, so nothing consumes this yet beyond the row existing) |
| `GET /leaderboards/coverage?window=weekly\|all&scope=global` | 🌐 (optional auth) | → `{entries: [{rank, handle, cells}], me?: {rank, cells}}`, entries capped at `LEADERBOARD_ENTRIES_MAX` (§2). `scope` accepts only `global` in M1 (other scopes ⇒ `request/invalid`); `window=weekly` counts distinct `user_coverage.h3_r7` rows whose `created_at` falls in the current ISO week (Monday 00:00 UTC start, UTC throughout); `window=all` counts all rows. `me` is present only when the request carries a valid bearer token (optional auth — a missing/invalid token omits `me` rather than erroring). **Deferred-evidence exclusion (§17, M2):** a cell counts here only if its
`user_coverage` row's `first_checkin_id` checkin has `evidence='live'` — a cell first
proven via offline/deferred evidence doesn't count competitively until re-covered by a
live check-in, though it always counts fully toward `GET /me/coverage`, the heatmap (§15),
`creatorScore`, and badges (§16), none of which are competitive-ranking surfaces. **M1
implementation note:** computed live (`GROUP BY user_id ORDER BY count DESC LIMIT`); precomputed snapshots (`leaderboard_snapshots`, ARCHITECTURE.md) are deferred until live cost requires them — no such table exists yet. |
| `POST /checkins/:id/postcards` | ✅ owner | `{message?: string(..280)}` → `201 {postcard: {id, token, url}}` (§20, M2) — check-in must be the caller's own AND `verified`, else `resource/not_found`; rate limit §2 |
| `GET /postcards/:token` | 🌐 | → HTML, not the §3 JSON envelope (§20, M2 — the one deliberate carve-out from §3's rule) |
| `DELETE /postcards/:id` | ✅ owner | → `{ok: true}` (§20, M2) — one-directional; not owned/unknown/already-revoked ⇒ `resource/not_found` |

**Pagination convention** (`GET /me/checkins` and any future cursor-paginated list): cursor
is base64 of `"<createdAt ISO>|<id>"` for the last row of the previous page; results order
by `(created_at DESC, id DESC)`; an absent/malformed cursor starts from the top; no
`nextCursor` in the response means no further pages.

`User = {id, handle, displayName, createdAt}` (`displayName: string | null` — §21, M2;
the caller's own opt-in choice, `GET /me` only) · `PoiPin = {id, title, category,
location, checkinCount, thumbnailUrl}` (`thumbnailUrl: string | null` — §19, M2; the
POI's best approved photo, computed only where noted below, `null` elsewhere including
endpoints that don't compute it at all) · Full `Poi` adds `{description, creator: {id,
handle} | null, checkinRadiusM, gallery: Photo[]}` (`creator: null` — §21, M2 — means the
POI is unclaimed: seeded, no real founder yet) · `Photo = {id, urlCard, urlThumb,
voteScore, myVote, uploader: {handle}, contributorName, status}` (non-approved photos
visible only to their uploader; `myVote: boolean` — M2, §7's `GET /pois/:id` note — is
the one caller-specific field on an otherwise-shared shape, `false` whenever there's no
authenticated caller or they haven't voted; `contributorName: string | null` — §21, M2 —
the uploader's opt-in display name, `null` if they haven't set one, never falling back to
`handle`).

## 8. Database schema (authoritative DDL)

Migration `0000_init.sql` MUST create exactly this (plus `CREATE EXTENSION IF NOT EXISTS
postgis`). Drizzle schema mirrors the *cumulative* state after all migrations; drift is a
defect. UUIDv7 generated in app code. Applied deltas: **0001** drops
`checkins_user_poi_unique` and creates
`UNIQUE INDEX checkins_user_poi_active ON checkins (user_id, poi_id) WHERE status <>
'rejected'` (§5.7 retry semantics). **0002** adds `badge_key` + `badges` (§16, M2). **0003**
adds `checkin_evidence_mode` + `checkins.evidence` (§17, M2). **0004** adds `saved_pois`
(§19, M2). **0005** adds `postcards` (§20, M2). **0006** drops `pois.creator_id`'s
`NOT NULL` and adds `users.display_name` (§21, M2).

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
-- Migration 0006 adds: display_name TEXT (opt-in, distinct from handle; §21, M2).

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
-- Migration 0006 drops creator_id's NOT NULL — NULL means unclaimed (§21, M2).
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
-- Migration 0003 adds: evidence checkin_evidence_mode NOT NULL DEFAULT 'live' (§17, M2).
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

-- Migration 0002 (§16, M2):
CREATE TYPE badge_key AS ENUM ('first_in_region', 'poi_milestone_10', 'poi_milestone_50', 'poi_milestone_100');
CREATE TABLE badges (
  user_id UUID NOT NULL REFERENCES users(id), badge_key badge_key NOT NULL,
  awarded_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY (user_id, badge_key));

-- Migration 0003 (§17, M2):
CREATE TYPE checkin_evidence_mode AS ENUM ('live', 'deferred');
ALTER TABLE checkins ADD COLUMN evidence checkin_evidence_mode NOT NULL DEFAULT 'live';

-- Migration 0004 (§19, M2):
CREATE TABLE saved_pois (
  user_id UUID NOT NULL REFERENCES users(id), poi_id UUID NOT NULL REFERENCES pois(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY (user_id, poi_id));

-- Migration 0005 (§20, M2): postcards — see §20's own data-model block for the full DDL.

-- Migration 0006 (§21, M2):
ALTER TABLE pois ALTER COLUMN creator_id DROP NOT NULL;
ALTER TABLE users ADD COLUMN display_name TEXT;

-- [M2] health_daily · [M3] entitlements — declared in docs, created when built.
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

## 15. Personal coverage map — heatmap & drill-down (M2 step 2; exact)

Scope: the "heat map effect" + "click down into city... state... country" + "arrive at an
area, see your own postcards and nearby POIs" feature. Fills a gap flagged, not silently
skipped, in §14: "the `cells` array is fetched but not rendered as a map overlay... a
personal coverage heatmap is a real feature, not a one-line addition." This section is
that feature.

**Decision, made explicit (asked, not assumed):** true city/state/country drill-down
needs *some* source of real administrative boundaries — an H3 cell is a geometric
hexagon; it has no inherent idea it's "in France." Three paths exist (bundle a static
boundary dataset for offline point-in-polygon lookup; call an external reverse-geocoding
service; or approximate the hierarchy using H3's own coarse→fine resolution structure,
no new data source, generic area labels instead of real place names). **Chosen: H3
resolution tiers.** No new dependency, no network call, ships fastest — the tradeoff,
accepted explicitly, is that drill-down levels read as "this area" / a cell-based
identity rather than literally "California." Real administrative names are a follow-up
if this proves insufficient, gated on picking one of the other two paths.

**Resolution tiers** (`SPEC_CONSTANTS.geo.COVERAGE_HEATMAP_RESOLUTIONS = [2, 3, 5, 7]`,
approximate hex edge lengths: res 2 ≈ 158 km, res 3 ≈ 59 km, res 5 ≈ 8.5 km, res 7 ≈
1.2 km — the existing `H3_RES_COVERAGE`). `resolutionForZoom(zoom)` (pure,
`src/geo/h3.ts`) maps a map-camera zoom to one of these, reusing the same "server decides
granularity from zoom" convention `GET /pois`'s cluster/pin split already established
(§7, §12):
```
zoom < 4   → res 2   (coarsest — "country"-scale blobs)
zoom < 6   → res 3   ("state"-scale)
zoom < 9   → res 5   ("city"-scale)
zoom < 13  → res 7   ("neighborhood"-scale — same resolution GET /me/coverage uses)
zoom ≥ 13  → no heatmap; switch to individual pins (below)
```
`13` matches `GET /pois`'s existing cluster-zoom threshold — one pin-mode boundary across
both maps, not a second magic number to keep in sync.

**`GET /me/coverage/heatmap?zoom=`** (§7): fetches the caller's `user_coverage` r7 cells
(same query `GET /me/coverage` already runs), buckets each by its H3 ancestor at the
resolution `resolutionForZoom(zoom)` selects (`cellToParent`; a no-op when the resolution
is already 7), and returns one entry per non-empty bucket: `h3` (the bucket cell),
`count` (how many of the caller's r7 cells fall under it — the heatmap's intensity
signal), `centroid` (`cellToLatLng` of the bucket cell itself — its true geometric
center, not a mean of members, unlike `Cluster.centroid` in §7's `GET /pois`, which
*does* average member POIs since a POI cluster has no single well-defined center the way
an H3 cell already does).

**Mobile** (`app/lib/features/profile/`, extends the personal-map surface `docs/
MILESTONES.md`'s M1 step 6 flagged as count-only): a `MapLibreMap` rendering the current
tier's heatmap. Tapping a heatmap cell zooms the camera to its centroid at the next
tier's zoom band — same "tap a cluster to zoom in" interaction `MapScreen` already uses
for POI clusters (§12), reused rather than re-invented. At `zoom ≥ 13` the heatmap layer
is replaced entirely by individual pins from two existing endpoints, not a new one:
`GET /me/map`'s `checkedIn` (the caller's own postcards — their verified check-in POIs,
filtered to the viewport) and `GET /pois?bbox=&zoom=` (nearby POIs generally, exactly as
the discovery map already renders them) — rendered together so arriving at an area shows
both what the caller has personally collected there and what else is nearby to go
collect. Tapping either pin opens the existing `PoiDetailSheet` (§12); no new detail UI.

**Deferred, flagged:** real administrative-boundary labels (needs the bundled-dataset or
reverse-geocoding decision above); a heatmap *color legend* / intensity styling beyond
whatever `maplibre_gl`'s heatmap layer type supports out of the box; combining this with
the community/global coverage map (this is the caller's own coverage only, not
aggregate — a global heatmap is a distinct, larger feature).

## 16. Badges & creator score (M2 step 1; exact)

Scope: `docs/MILESTONES.md`'s M2 "Badges v1 (first-in-region, POI milestones) and creator
score accrual (visible, not yet a leaderboard)". Nothing here previously had a SPEC
section — M2 items are declared only in `docs/`, not `SPEC.md`, until built. **The badge
taxonomy and thresholds below are this PR's proposal**, not a pre-existing product
decision — narrower docs (`ARCHITECTURE.md`'s schema sketch) named the `badges` table and
the two badge categories but not concrete keys or thresholds; both are picked here and
flagged, same as `dHashFromGrayscale`'s algorithm choice (§6) was.

**Constants** (new `SPEC_CONSTANTS.badges`):
```
POI_CHECKIN_MILESTONES = [10, 50, 100]   // verified check-ins on a POI you created
```

**Badge taxonomy** (closed set, Postgres enum `badge_key`, mirrors §3's closed-code-set
discipline):
- `first_in_region` — awarded once, ever, to whichever user's verified check-in is the
  first to insert a brand-new row into `user_coverage` for a given `h3_r7` cell (i.e. the
  first person anyone has recorded a verified check-in "covering" that cell). One-time
  per user, not per cell — the `badges` table's `(user_id, badge_key)` primary key
  (`docs/ARCHITECTURE.md`) has no per-instance column, so this cannot be re-earned for a
  *different* cell; it marks "you were first somewhere," not "you were first everywhere
  you've been." A user who already holds it is simply never re-checked.
- `poi_milestone_10` / `poi_milestone_50` / `poi_milestone_100` — awarded to a POI's
  `creator_id` (not the person checking in, unless they're the same) the moment one of
  their created POIs' `checkin_count` reaches that exact threshold (§2
  `POI_CHECKIN_MILESTONES`). Independent thresholds — reaching 50 also awards
  `poi_milestone_10` if not already held (checked in ascending order).

**Awarding mechanics** (`src/badges/service.ts`, `awardBadgesForVerifiedCheckin`): called
inside the same transaction as §5.7's `verified` side effects (`user_coverage`
insert + `checkin_count` increment) — same transaction, not a follow-up step, so a badge
is never awarded for a check-in that ends up rolled back. `INSERT ... ON CONFLICT
(user_id, badge_key) DO NOTHING` is the only idempotency guard needed (no separate
"already has it" check) since re-running the awarding logic against an unrelated
check-in in an already-covered cell, or a POI whose count already passed a threshold, is
harmless — the conflict just no-ops. `pending → verified` transitions (worker/admin,
§5.7) perform the same awarding at transition time, exactly like the existing coverage
insert / checkin_count increment they already mirror.

**Creator score** (`GET /me`'s `stats`, §7 — no new endpoint): `creatorScore` = sum of
`checkin_count` across the caller's POIs with `status <> 'removed'` — i.e. total verified
check-ins received across everything they've created. Deliberately the simplest faithful
definition (a straight sum, not a weighted/decayed score) since M2 only calls for it being
*visible*, not ranked — a leaderboard (M3, per `docs/MVP.md`) is where a more considered
formula would matter, and inventing one now without that pressure risks getting it wrong
twice.

**New API** (SPEC §7):
| Endpoint | Auth | Request → Response (2xx) |
| --- | --- | --- |
| `GET /me/badges` | ✅ | → `{badges: [{badgeKey, awardedAt}]}`, ordered by `awardedAt ASC` (earned-order, not alphabetical) |

`GET /me`'s `stats` gains `creatorScore: number` alongside the existing
`checkins`/`cellsCovered`/`poisCreated`.

**Database** (migration `0002_badges_creator_score.sql`, §8 delta): adds
```sql
CREATE TYPE badge_key AS ENUM ('first_in_region', 'poi_milestone_10', 'poi_milestone_50', 'poi_milestone_100');
CREATE TABLE badges (
  user_id UUID NOT NULL REFERENCES users(id), badge_key badge_key NOT NULL,
  awarded_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY (user_id, badge_key));
```
No column changes elsewhere — `creatorScore` is computed from the existing
`pois.checkin_count`, not stored.

**Deferred, flagged, not built here:** the badges/creator-score *leaderboard* (M3, full
matrix per `docs/MVP.md`); pushing a notification on a new badge (M2's separate "push
notifications" item, needs APNs/FCM credentials — a real blocker, unlike pHash's); any
mobile UI surfacing badges (this PR is server-only, matching how M1's moderation loop
step landed server-first before the profile screen consumed its data).

## 17. Offline check-in outbox — deferred evidence (M2; exact)

Scope: `docs/MILESTONES.md`'s M2 "Offline check-in outbox (deferred-evidence flow)",
making exact the design `docs/ARCHITECTURE.md` §8 already sketched narratively (durable
local outbox, replay on connectivity, wider tolerance + lower leaderboard weight). **The
exact ages/bounds below are this PR's proposal**, same treatment as the badge thresholds
(§16) and the H3 heatmap resolutions (§15) — ARCHITECTURE.md named the shape but not the
numbers.

**Why a new field, not a new endpoint:** the check-in submission itself (`POST
/checkins`) doesn't need to change shape to support this — only what it's willing to
accept as fresh does. `evidence: "live"|"deferred"` (default `"live"`) on the existing
`POST /checkins` body (§7) is the entire server-visible surface of this feature; intent
issuance (`POST /checkins/intent`) is unaffected because a nonce can only ever be
requested live regardless of how old the fixes ultimately submitted with it are (nonce
freshness — §5.1 — is exactly why offline check-ins can't pre-issue an intent at capture
time and must replay the whole intent→submit sequence later).

**Server (§2, §5, §7, §8):**
- New constants `CLOCK_SKEW_S = 30` (naming M1's existing inline 30 s tolerance),
  `CHECKIN_LIVE_MAX_AGE_S = 150` (`CHECKIN_NONCE_TTL_S + CLOCK_SKEW_S`),
  `CHECKIN_DEFERRED_MAX_AGE_S = 86_400` (24 h).
- Evidence freshness (§5.3, §5.5): the most recent fix's/capture's `capturedAt` must be no
  more than `CLOCK_SKEW_S` in the future and no older than the mode's max age. Violation ⇒
  hard `reject(stale_evidence)` — evidence integrity, never just a confidence cap. This
  closes a latent gap: M1 never actually enforced fix recency for `mode: "confirm"`
  check-ins (only `mode: "photo"`'s capture token had a freshness bound) — this feature
  gives both modes the same enforced bound, gated by `evidence`.
- `evidence` never changes L1/L2/L3/L5 pass/pending/reject math itself — only the
  freshness bound (§5.3/§5.5) and the leaderboard weight (§7) differ between `"live"` and
  `"deferred"`.
- Persisted on the `checkins` row (`checkin_evidence_mode` enum, migration
  `0003_checkin_evidence.sql`, §8) and returned on it (§7) so the client can show
  "synced later" truthfully rather than rendering a deferred check-in indistinguishably
  from a live one.
- Leaderboard weight (§7 `GET /leaderboards/coverage`): a `user_coverage` cell counts
  toward this ranking only if its `first_checkin_id` checkin has `evidence='live'`. A cell
  first proven via deferred evidence simply doesn't count there until re-covered live —
  deliberately the simplest faithful rule (keyed off the cell's *first* prover, not a
  per-checkin weighted sum, matching creatorScore's §16 "simplest faithful definition"
  precedent) — while `GET /me/coverage`, the heatmap (§15), `creatorScore`, and badges
  (§16) all still count it fully, since none of those are competitive-ranking surfaces.
  `first_in_region` (§16) is unaffected by evidence mode for the same reason: it rewards
  genuine first presence, not live-ness.

**Mobile (`app/lib/features/checkin/`):**
- Trigger: a network-class failure (no connectivity, timeout, `service/unavailable`)
  interrupting the very first `POST /checkins/intent` of a check-in the user explicitly
  started — the realistic "no signal at all" case, and the only network call in the whole
  flow that doesn't already have fixes/a photo gathered by the time it could fail. A
  rejected/invalid attempt the server actually answered (nonce expired,
  `checkin/rejected`, `checkin/duplicate`, …) is never queued — only genuine connectivity
  failure is. **Narrower than the general case, flagged:** a network failure striking
  *later* in the flow (fixes already gathered, intent already succeeded, `POST /checkins`
  itself fails) is out of scope for this slice and still surfaces as today's plain error —
  building that path too means deciding what to do with an already-uploaded photo
  mid-flow, deferred until it's a real problem rather than guessed at now.
- `CheckinOutbox`: a durable (survives app restart) local queue — a JSON manifest plus any
  already-captured photo file, in the app's documents directory (`path_provider`, §1).
  Each queued item keeps the real `fixes` (with their true `capturedAt`), `mode`, `poiId`,
  and the photo file path if one was captured, exactly as gathered — nothing about it is
  submitted yet, since no nonce can exist for an offline attempt.
- Replay, opportunistic (app foreground/launch, or a manual retry action — no background
  sync, consistent with §9's no-background-anything invariant): per queued item, in order,
  (1) fresh `POST /checkins/intent`, (2) photo mode only — presign/upload/complete the
  photo now (upload timestamp reflects replay time; only `capture.capturedAt` preserves
  the original shutter moment), (3) `POST /checkins` with the original `fixes`/
  `capture.capturedAt` and `evidence: "deferred"`. A network failure OR a `rate/limited`
  response (transient — `CHECKIN_INTENT_PER_HOUR`, §2 — not a verdict on this check-in;
  a replay burst can legitimately hit it) stops the whole pass and leaves every remaining
  item queued, this one included. Any other server-answered outcome drops that one item
  (no infinite retry on a real verdict the server has already given).
- Client-side age drop: an item whose original capture moment is already past
  `CHECKIN_DEFERRED_MAX_AGE_S` by the time it's replayed is discarded without a server
  round trip — the server would `stale_evidence`-reject it anyway (§5.3); this just avoids
  a doomed request. `app/lib/core/constants.dart` mirrors the 24 h bound for this check.
- UI: while a check-in is queued (offline), the check-in screen shows a "no connection —
  saved, will sync automatically" state rather than an error. Separately, a non-empty
  outbox shows a small "N check-ins waiting to sync" banner on the profile screen with the
  manual retry action; it disappears once the outbox is empty (the common case). `Checkin`
  carries `evidence` (SPEC §7) so a future check-in history/detail screen can render a
  "synced later" badge on the resulting record — no such screen exists in the mobile app
  yet (profile only shows `GET /me/map`'s created/checked-in POIs, not raw check-in
  history), so this is API-ready but has no consumer today.

**Deferred, flagged, not built here:** exponential backoff/jitter on repeated replay
failure (fine at current scale — no thundering-herd risk yet); any background-triggered
replay (push-woken sync would violate §9's no-background-location spirit even though this
outbox itself gathers no new location data, so it's out of scope on principle, not just
unbuilt); queuing a network failure that strikes after intent already succeeded (see the
trigger note above); a per-check-in "synced later" badge, which needs a check-ins list/
detail screen that doesn't exist in the mobile app yet.

## 18. Offline POI-creation outbox (M2; exact)

Extends §17's offline-capture pattern to POI creation. **Architecturally simpler than the
check-in outbox, and the reason is worth stating plainly:** `POST /pois` (§7, §13.1) has no
intent/nonce step — it's a single, self-contained call — and, unlike check-in fixes,
`gpsFix.capturedAt` is never read for freshness server-side (`server/src/pois/service.ts`
only uses `gpsFix.lat/lng` for the `PIN_ADJUST_MAX_M` distance check; §13.1's own text
already says the server is authoritative on distance only). **Consequence: this feature
needs zero server-side changes** — no new field, no migration, no freshness bound. A
queued POI creation replayed hours or days later is verified by exactly the same rule a
live one is.

**Trigger:** a network-class failure on the single `POST /pois` call for a POI the user
explicitly tried to create. Everything needed to queue it — title, description, category,
location, `gpsFix`, and (if attached) the already face-gated and resized photo — is
already gathered client-side *before* that call, since POI creation has no server round
trip earlier in its flow the way check-in's fix-gathering does. So, unlike §17's check-in
outbox, there's no "only the very first call" carve-out to make here: the network call
either succeeds or it's the only one that can fail before anything is queued.

**Queued item** (`QueuedPoiCreation`): `title`, `description?`, `category`, `location`,
`gpsFix`, `photoPath?` — no `attemptedAt`-based age bound (unlike §17's
`CHECKIN_DEFERRED_MAX_AGE_S`): nothing server-side depends on this data's age, so nothing
client-side needs to preemptively drop it either.

**Replay** (`PoiCreateOutboxController`, same opportunistic triggers as §17 — app launch,
manual retry, no background sync):
1. `POST /pois` with `force: false` (the item's stored fields).
2. **`200 {dedupeCandidates}` (proximity match found):** unlike the live flow, there's no
   human present at replay time to compare candidates, so the queued creation is
   automatically resubmitted with `force: true` rather than left stuck forever or silently
   dropped — **this PR's chosen behavior, flagged**: creation dedupe is a proximity nudge,
   not a data-integrity gate (§7's own wording — "creation dedupe is proximity-only"), and
   losing a user's real, offline-captured creation effort is worse than an occasional
   avoidable duplicate a human can still merge/report later. The alternative (hold the
   item pending a manual dedupe-review UI) is deferred below.
3. **Success (`201 {poi}`, whether direct or after the force-retry above):** if a photo was
   queued, presign/upload/complete it now against the new POI's id — a failure here is
   swallowed exactly as it already is in the live flow (§13.1's `_uploadPhoto`; the POI
   detail screen's own retry affordance is unchanged), not queued a second time. The item
   is then removed from the outbox regardless of the photo outcome.
4. A network failure OR `rate/limited` (`POI_CREATE_PER_DAY`, §2) at any point stops the
   whole pass, same rule as §17's check-in outbox (both now share one `retryLaterCodes`
   set, `app/lib/features/checkin/checkin_outbox_controller.dart`). Any other
   server-answered outcome (e.g. `poi/outside_pin_adjust`, which shouldn't recur since the
   pin/fix distance already passed client-side validation once) drops the item.

**UI:** the POI-creation screen shows a "no connection — saved, will sync automatically"
state, mirroring §17's check-in screen exactly. The profile screen's existing outbox
banner (§17) is extended to a combined "N items waiting to sync" count across both queues
rather than two separate banners.

**Deferred, flagged, not built here:** a "needs your review" UI for dedupe candidates
instead of auto-force-creating, should duplicate creation prove to be a real curation
problem in practice; unifying `CheckinOutbox`/`PoiCreateOutbox`'s near-identical
manifest/photo-file file-I/O into one generic implementation — reasonable with two call
sites already this similar, but deferred until a third appears (`Three similar lines is
better than a premature abstraction`) or the duplication itself causes a bug.

## 19. Instagram-style browsing & sharing (M2; exact)

Scope: an IG-style profile grid, a discovery feed ("places around me" + "places I want to
visit"), and sharing (map/photo/leaderboard) to the native share sheet. **Postcard sending
v1** (ARCHITECTURE.md §10 — a new public web renderer + unlisted links) is explicitly
*not* part of this: a deliberate product decision to ship the lower-lift pieces first, not
an oversight. A public/social feed of *other users'* activity is also not built — SPEC §9
("check-in history is private by default") rules it out; everything here is either the
caller's own data or already-public POI discovery data (`GET /pois*` are 🌐 today).

**`thumbnailUrl` (§7's `PoiPin`):** the POI's best approved photo — `SELECT storage_key
FROM photos WHERE poi_id = ? AND moderation = 'approved' ORDER BY vote_score DESC,
created_at ASC LIMIT 1`, same tie-break `GET /pois/:id`'s gallery already uses — turned
into a URL via the existing `urlThumb()` (§6). `null` if the POI has no approved photo.
**Computed for `GET /me/map`, `GET /pois/nearby`, and `GET /pois/:id`** — the first two
return small, bounded result sets (a caller's own places; ≤ 50, distance-capped); the
third gets it for free from its already-fetched, already-ranked `gallery` (first entry's
`urlThumb`, no extra query). **Deliberately not computed for `GET /pois?bbox=&zoom=`**
(up to 200 results, hit continuously while panning the discovery map) — the extra per-row
photo lookup is a real added cost there that a first pass doesn't need; `thumbnailUrl` is
`null` on every pin that endpoint returns. Revisit if
photo-rich map browsing turns out to matter enough to justify it.

**Saved POIs ("places I want to visit"):** `saved_pois(user_id, poi_id, created_at)`
(migration `0004`), a plain bookmark — no moderation, no scoring, no leaderboard
interaction, nothing SPEC §9-sensitive (it's the caller's own list, never exposed for
anyone else). `POST /pois/:id/save {value: 1|0}` (§7) mirrors `POST /photos/:id/vote`'s
shape exactly (`value: 0` retracts) rather than inventing a new toggle convention. Surfaced
back via `GET /me/map`'s new `saved: PoiPin[]` array (most-recently-saved first) — reusing
the existing endpoint rather than adding a fourth one, the same way `vaulted` already sits
there as a stub for a not-yet-built M3 feature.

**`checkedIn` uses `SELECT DISTINCT` defensively** — every selected column already comes
from `pois` (`checkins` only supplies the join condition), so a `SELECT DISTINCT` costs
nothing here. Not fixing an active bug: `checkins_user_poi_active` (migration 0001)
already guarantees at most one non-rejected checkin per `(user_id, poi_id)`, so a
duplicate pin isn't reachable today — this is just correct-by-construction insurance if
that constraint's rule ever loosens.

**Mobile — profile grid** (`app/lib/features/profile/`): `created` + `checkedIn` render as
a 3-column photo grid (IG profile style) instead of the current plain list — a
category-icon tile stands in for `thumbnailUrl: null`. Tapping a cell opens a full-screen,
swipeable (`PageView`) viewer across that section's items — a lightweight "feed-style"
browsing experience over the caller's own grid, not a new endpoint or a public feed.

**Mobile — discovery feed** (new `app/lib/features/feed/`, new tab in `main.dart`'s
`RootScreen` alongside Map/Account): a vertical scroll of cards — nearby POIs
(`GET /pois/nearby`, centered on the device's current location) interleaved with the
caller's `saved` list (`GET /me/map`) — each card: `thumbnailUrl` (or a category-icon
placeholder), title, category, distance (nearby cards only), a save/unsave toggle, tap to
open `PoiDetailSheet` (§12, unchanged). No new "browse everyone's activity" concept —
exactly the two `GET`s above, client-merged.

**Mobile — sharing** (new `share_plus` dependency, §1 — the standard Flutter native
share-sheet plugin; no credentials/cost, no new native permission beyond what the OS share
UI itself requires): three concrete share actions, each rendering to an image and handing
it to the OS share sheet:
1. **A POI photo** (from the grid viewer or POI detail): fetch the image bytes from its
   `urlCard`, share directly.
2. **The coverage map** (`PersonalMapScreen`, §15): capture the *currently displayed* view
   (`RenderRepaintBoundary.toImage()`) and share it. This is deliberately how
   `docs/MILESTONES.md`'s "shareable map image with precision controls" M2 item is being
   satisfied — the already-built H3 zoom-tier heatmap (§15) *is* the precision control:
   whatever's on screen never shows anything finer than the resolution the current zoom
   maps to, so sharing the visible view can never leak raw coordinates. No separate
   precision slider is being added on top of it.
3. **The leaderboard** (`ProfileScreen`, §14): a small rendered "share card" widget
   (handle, rank, cell count) captured the same way and shared.

**Deferred, flagged, not built here:** postcard sending v1 (now built — see §20);
`thumbnailUrl` on the bbox discovery endpoint; any notion of following/followers or
seeing another user's saved/checked-in list (would need its own privacy model, not
assumed here).

## 20. Postcard sending v1 (M2; exact)

Scope: `docs/MILESTONES.md`'s M2 "postcard sending v1" (ARCHITECTURE.md §10) — after any
verified check-in, send a shareable web postcard (photo-front / message-back, a verified
mark, sender handle, photographer credit) to anyone via any messenger. No friend graph,
no recipient targeting server-side — a "send" mints an unlisted link the sender shares
however they like. **M3+ in-app postcard inbox and physical print-and-mail (ARCHITECTURE
§10) are explicitly not built here.**

**Data model** (migration `0005`, §8 delta):
```sql
CREATE TABLE postcards (
  id UUID PRIMARY KEY,
  checkin_id UUID NOT NULL REFERENCES checkins(id),
  sender_id UUID NOT NULL REFERENCES users(id),
  token TEXT NOT NULL,
  message TEXT,
  message_approved BOOLEAN NOT NULL DEFAULT true,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX postcards_token_idx ON postcards (token);
CREATE INDEX postcards_checkin_idx ON postcards (checkin_id);
```
`token` (18 random bytes, base64url via `crypto.randomBytes`) is deliberately a separate
value from `id` — the public/unlisted share URL never doubles as the row's own
(sequential-ish, uuidv7) internal identifier.

**New API** (§7):
| Endpoint | Auth | Request → Response |
| --- | --- | --- |
| `POST /checkins/:id/postcards` | ✅ owner | `{message?: string(..280)}` → `201 {postcard: {id, token, url}}`. The check-in must be the caller's own AND `status='verified'` — anything else (not owned, `pending`, `rejected`, unknown) ⇒ `resource/not_found` (no visibility leak, same pattern as photo voting/POI saving). Each call mints a fresh token; sending twice from the same check-in is allowed, not deduplicated. Rate limit: `POSTCARD_SEND_PER_DAY` (§2) ⇒ `rate/limited`. |
| `GET /postcards/:token` | 🌐 | Renders the postcard as an HTML page (see below) — **not** the §3 JSON envelope; see the carve-out note below. Unknown/revoked token ⇒ `404` HTML. |
| `DELETE /postcards/:id` | ✅ owner | → `{ok: true}`. One-directional (no un-revoke). Not owned / already revoked / unknown ⇒ `resource/not_found` (same no-leak pattern). |

**Deliberate carve-out from §3:** `GET /postcards/:token` is opened directly by a plain
browser from a shared link — it always returns an HTML document (200 with the card, or
404 with a plain "not found" page), never the `{error: {...}}` JSON envelope every other
endpoint uses. This is the ONLY endpoint in the API with this exception, and it exists
because this is the one route a human, not the mobile app, is the actual client of.

**Text moderation** (`src/moderation/text_provider.ts`, mirrors `ModerationProvider`'s
shape from §6): `TextModerationProvider.moderate(text) → {approved: boolean}` — smaller
than the photo verdict shape since nothing consumes a rejection *reason* (a rejected
message just isn't rendered, not surfaced as an error to the sender — the send itself
still succeeds with `201`). `devTextModerationProvider()` always approves; no real
detector wired in yet (same M1-style "seam, not real thing yet" as
`RekognitionModerationProvider`) — no config knob to select an alternative provider
exists yet either, since unlike photo moderation there's no named stub for a real one to
select.

**Photo resolution** — computed at VIEW time (`GET /postcards/:token`), not snapshotted at
send time: the check-in's own photo (photo-mode) if `moderation='approved'`, else the
POI's best-approved gallery photo (same tie-break as `GET /pois/:id`'s gallery /
`thumbnailUrl`: `vote_score DESC, created_at ASC`), else no photo at all — a photo-less
card still renders (place, date, sender, message) rather than blocking the send, since
requiring a photo would block sending from any POI without one yet. Photographer credit
follows whichever photo was actually used; omitted when the photographer is the sender
themselves (their own handle is already shown as "sent by").

**Config** (§1): `PUBLIC_BASE_URL` (new, defaults to `http://localhost:8080`) — the
postcard page needs its own absolute origin to embed in the shared link and the photo
`<img>` src, unlike `PoiPin`/`Photo`'s server-relative paths (which the MOBILE app
resolves against its own `API_BASE_URL` — a plain browser has no such client to do that
resolution). `APP_STORE_URL` / `PLAY_STORE_URL` (new, both optional) — the page's "Get
the app" prompt is omitted entirely, not shown with a placeholder/broken link, when
unset (no real store listing exists yet).

**Mobile** (`app/lib/features/checkin/`): the check-in result screen's `verified` state
gains an optional message field + "Send postcard" button, calling the new endpoint, then
handing the returned `url` to the OS share sheet (`share_plus`'s `Share.share(url)` — no
new mobile dependency; already added for §19's image sharing). No "manage my sent
postcards" screen in this slice (revocation is built server-side per the design guard in
ARCHITECTURE §10, but nothing in the mobile UI surfaces it yet) — flagged as a fast-follow,
not an oversight.

**Deferred, flagged, not built here:** a "manage/revoke my sent postcards" mobile screen
(server-side revoke exists, unreachable from the UI yet); a real text-moderation
detector; rendering the postcard's `<title>`/OpenGraph tags for richer message-preview
cards in chat apps (plain `<title>` only, no `og:*` meta tags yet).

## 21. Unclaimed POIs, founder promotion & named photo credit (M2; exact)

Scope: `docs/MILESTONES.md`'s M2 "seed 50-100 founder POIs per city" — this SPEC's answer
to a problem the seeding tooling surfaced directly (a real Portland, OR stress test):
synthetic "founder" accounts, sized to stay under `POI_CREATE_PER_DAY`, aren't a real
product mechanic — a bulk-imported place shouldn't be attributed to an account nobody
real controls, and no amount of account-count tuning makes a one-time curated import
look like a user's posting velocity. Real mechanic instead: an imported POI starts
**unclaimed** (no creator), and the first real user whose check-in (or POI-creation)
photo for it clears moderation becomes its founder, permanently. Separately, whichever
photo is currently the *best* one (highest-voted, same tie-break §7 already uses) can
credit its uploader by name if — and only if — that uploader has opted in.

**Data model** (migration `0006_unclaimed_pois_and_display_name.sql`, §8 delta):
```sql
ALTER TABLE pois ALTER COLUMN creator_id DROP NOT NULL;
ALTER TABLE users ADD COLUMN display_name TEXT;
```
`pois.creator_id` becomes nullable — `NULL` means "unclaimed," a real, permanent state
until claimed (never reset, never defaulted to some placeholder account). `users.
display_name` is new, optional, and user-chosen — entirely distinct from `handle`
(system-generated, immutable, `explorer_xxxxx`, §4). Both `NULL` by default.

**Founder promotion** (`src/moderation/service.ts`'s `applyModerationVerdict`, via a new
`promoteFounderIfUnclaimed`): the moment a photo's verdict becomes `approved`, if that
photo's POI currently has `creator_id IS NULL`, atomically set `creator_id` to that
photo's `uploader_id`:
```sql
UPDATE pois p SET creator_id = ph.uploader_id
FROM photos ph
WHERE ph.id = <photoId> AND p.id = ph.poi_id AND p.creator_id IS NULL
```
One statement, guarded by the `IS NULL` check, so it's race-safe and one-shot: whichever
approval reaches Postgres first wins; a later approval for the same POI matches zero rows
and no-ops. Applies uniformly regardless of `photos.source` (`poi_creation` or
`checkin`) — a normal user-created POI already has a creator at insert time, so this only
ever fires for POIs that started unclaimed (i.e. seeded ones).

**Unclaimed POIs behave normally everywhere else**: browsable (`GET /pois`,
`/pois/nearby`, `/pois/:id`), checkin-able, categorized/radius'd exactly like any other
active POI. `Poi.creator` becomes `{id, handle} | null` (§7). Every existing query that
filters "POIs I created" by `creator_id = <userId>` (`GET /me`'s `poisCreated`/
`creatorScore`, `GET /me/map`'s `created`) already excludes unclaimed POIs for free —
SQL's `NULL = x` is never true, no code change needed there. `poi_milestone_*` badges
(§16) simply have no one to award to until a POI is claimed — `awardPoiMilestones` is a
no-op when `poiCreatorId` is `null`; once claimed, future check-ins award normally.

**Named photo credit** (`GET /pois/:id`'s gallery, §7): each gallery `Photo` gains
`contributorName: string | null` — the uploader's `display_name` if they've set one, else
`null`. Never falls back to `handle`: an un-named contributor is uncredited, not credited
by their auto-generated handle. Independent of founder status and can change over time as
new photos out-vote the current best one (§7's existing `vote_score DESC, created_at ASC`
tie-break) — unlike founder status, which is permanent once set.

**Setting a display name** (new API, §7):
| Endpoint | Auth | Request → Response |
| --- | --- | --- |
| `PATCH /me/display-name` | ✅ | `{displayName: string(1..40 code points) \| null}` → `{displayName}`. `null` clears it (reverts to uncredited). Passed through a `TextModerationProvider` (mirrors §20's shape) — a flagged name ⇒ `request/invalid` (`details.reason: 'profanity'`) rather than being silently stored unrendered like §20's postcard messages; the caller is actively choosing this name and can immediately try another, unlike a one-shot async send. |

`GET /me`'s `user` gains `displayName: string | null` alongside `handle` (§7) so the
caller can read back their own current choice.

**Text moderation for display names** (`src/moderation/text_provider.ts`): a new
`keywordTextModerationProvider(blocklist)` — normalizes (lowercase, strips diacritics,
folds common leetspeak substitutions, drops remaining non-alphanumerics) then checks for
a blocklisted whole word as a substring of the normalized text. A real (if simple)
detector — deliberately not another `dev...always-approves` stub, and it needs no
credentials/config, so it's the *default* `displayNameModeration` dependency (optional on
`AppDeps`) rather than needing an explicit per-deployment choice the way photo moderation
does. Known, accepted limitation: a short substring match can false-positive on innocuous
words containing a blocked one (the "Scunthorpe problem") — mitigated, not solved, by
keeping the default blocklist to whole profanity words rather than short fragments.
`devTextModerationProvider()` (§20, postcard messages) is unchanged and out of scope here
— nothing stops a later PR from moving postcards onto a real provider too.

**Seeding** (`server/src/scripts/seed_osm_pois.ts`): imported POIs are now inserted with
`creator_id = NULL` via a new `importUnclaimedPoi` (`server/src/pois/service.ts`) — the
same real dedupe/insert path `createPoi` uses, minus the per-user rate limit and
pin-adjust check (neither applies: there's no user and no GPS fix behind a bulk import).
This retires the "founder account" mechanism the previous iteration of this tooling
added (synthetic `<city>_founder_N` accounts sized to `POI_CREATE_PER_DAY`) — there's
nothing left to rate-limit or bypass, since an unclaimed POI has no creator at all.

**Deferred, flagged, not built here:** mobile UI surfacing (a "Founded by" line on the POI
detail screen, a "Photo by <name>" credit on gallery images, a settings screen to
set/clear `displayName`) — server-only in this PR, same precedent as §16's badges landing
server-first; a stronger (non-keyword) profanity/abuse detector if the starter blocklist
proves insufficient; extending named credit to postcards' photographer line (§20, still
`handle`-only) or to `Photo.uploader` elsewhere — left as noted, not silently changed.

## 22. Definition of done (every PR)

1. Implements only SPEC'd behavior; SPEC updated in-PR if it had to change (called out).
2. `npm run check` green locally and in CI.
3. New behavior has tests at the layer it lives in (§10 minimums).
4. No new dependencies outside the allowlist (§1).
5. No TODOs without an issue reference; no commented-out code; no `console.log` (use the
   Fastify logger).
6. Errors use §3 envelope/codes exactly.
7. PR description lists SPEC sections touched.
