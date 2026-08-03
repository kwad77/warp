# Wanderpost — Milestone Plan

## M1 — Walking skeleton (core loop, one city, TestFlight/internal)

Everything in [MVP.md](MVP.md). Build order inside M1:

1. **Server foundation** — Fastify app, Postgres/PostGIS schema + migrations, auth
   (Apple/Google/email), R2 presigned uploads, CI (typecheck, lint, tests, migration
   check). Deployable from day one.
2. **Verification pipeline** — intent/nonce, integrity verification (both platforms),
   presence + velocity layers, trust events, evidence records. **Test-heaviest code in
   the repo**: table-driven tests per layer, replay-attack tests, fixture devices.
3. **Flutter app: map + POI browse** — MapLibre map with server-driven clustering, POI
   detail sheet, email-code auth flow (SPEC §12). `flutter analyze` + 35 unit tests are
   the gate, **plus one real rendering pass**: a diagnostic Flutter-Web build (map widget
   stubbed — `maplibre_gl` has no Linux desktop support and `maplibre_gl_web` 0.21.0
   doesn't compile against current Flutter stable, see ARCHITECTURE.md) was screenshotted
   with headless Chromium against the real running server. Confirmed live and pixel-real:
   theming, tab navigation, the auth screen's text field/focus/floating-label behavior,
   typing an email, tapping "Send code," the request actually reaching the real Fastify
   backend (visible in its logs), and Riverpod correctly re-rendering the code-entry
   screen with the email interpolated in. Real device/emulator paths remain blocked for
   confirmed environment reasons (no `/dev/kvm` in this Docker container; no macOS for
   iOS). The map itself — the MapLibre widget rendering actual tiles/markers — is still
   unverified and is the one piece a real device run still owes.
4. **Flutter app: create + check in** (SPEC §13) — split in two:
   - **POI creation** (done): pin-adjust map, title/description/category form, camera
     (`camera` package) or gallery (`image_picker`) photo — either gated by on-device
     `google_mlkit_face_detection` before anything uploads — dedupe picker
     (`200 dedupeCandidates` → pick existing or "create mine" with `force: true`), photo
     upload after creation (presign → PUT → complete). New dependencies this slice:
     `camera`, `google_mlkit_face_detection`, `image_picker`, and `geolocator` (a spec
     gap — nothing previously read a GPS fix at all; both this and check-in need one).
     Client-side resize to `UPLOAD_MAX_LONG_EDGE_PX` (§6, originally deferred) is now
     implemented (`core/image_resize.dart`, pure function, no platform channel — new
     dependency `image`) and always re-encodes to JPEG regardless of source format, since
     `contentType` is declared as `image/jpeg`. Also steps JPEG quality down (85 → floor
     30) when the resized encode still exceeds `UPLOAD_MAX_BYTES` — confirmed necessary
     against a synthetic worst-case (noisy, detailed) photo, not a hypothetical: quality
     85 alone left a 2048px-long-edge image at 1.27MB, over the 1MB budget; quality
     stepping brought the same image to 0.85MB. Flagged limitation: the pure-Dart `image`
     package can't decode HEIC (iOS's default gallery format) — surfaced as a new
     `photoProcessingFailed` state, checked pre-flight alongside the face gate, not a
     silent pass-through.
   - **Check-in flow** (done, SPEC §13.2): mode choice (photo/confirm) on POI detail's new
     "Check in" action, lazy device registration, `checkins/intent`, `FixCollector`
     gathering `MIN_FIXES..MAX_FIXES` fixes off each fix's own timestamp (pure, unit
     tested against a synthetic stream), photo mode's in-app-camera-only capture (shared
     screen with POI creation) feeding the SPEC §5.5 capture-token hash (resized via the
     same `image_resize.dart` as POI creation before upload — the capture token itself is
     over the nonce and shutter timestamp only, not the bytes, so resizing doesn't touch
     it), submit, and a result screen covering verified/pending/rejected/duplicate/
     photo-blocked/photo-processing-failed/fix-timeout/error with a retry path per case.
     Flagged scope-back: real platform integrity
     attestation (Play Integrity/App Attest) needs credentials this environment can't
     provision (Google Cloud + Play Console, paid Apple Developer enrollment) — SPEC §5.2
     amended to keep `DevIntegrityVerifier`/`DevIntegrityTokenProvider` as the only M1
     implementation, with a named, unbuilt seam for the real thing (same treatment as
     `RekognitionModerationProvider`). New dependency: `crypto` (dart-lang official,
     already a transitive dep, promoted for the SHA-256 capture token).
   - **Server-side follow-up** (SPEC §4): `POST /auth/apple`/`/google` now really verify
     the platform ID token (`jose`'s remote-JWKS support, no new dependency) instead of
     the 501 placeholder from step 1 — config-gated on `APPLE_CLIENT_ID`/
     `GOOGLE_CLIENT_ID` (unset ⇒ still 501, unchanged from before), since only a human
     with Apple Developer/Google Cloud console access can create those. Mobile UI for
     Apple/Google buttons is still deferred — SPEC §12 built only the email-code screen.
5. **Moderation loop** — `ModerationProvider` seam wired synchronously into photo
   completion (`DevModerationProvider` auto-approves); reports and photo voting shipped.
   pHash (64-bit dHash) and the pixel-dimension check (SPEC §6) are now implemented:
   `storage.get` fetches the real bytes during moderation, `sharp` (newly installed —
   was already SPEC §1-allowlisted, just unused) computes width/height + the hash, and a
   long edge below `UPLOAD_MIN_LONG_EDGE_PX` rejects before the provider runs. This was
   previously bundled with the still-deferred items below under one "needs your call"
   note; corrected once it became clear the stated blocker (bytes + `sharp`) didn't
   actually require a new dependency or credential decision. Still genuinely deferred:
   the real detector (needs an AWS SDK dependency not yet approved) and the human-review
   admin surface (needs an undesigned admin auth realm).
6. **Personal map + coverage + weekly leaderboard** (SPEC §14; done). Replaces the
   Account tab's "Signed in as {handle}" placeholder with a real profile screen: stats
   (`GET /me`), My Places — created/checked-in `PoiPin` lists tappable into the existing
   POI detail sheet (`GET /me/map`), a coverage cell count (`GET /me/coverage` — the raw
   H3 cell list is fetched but not rendered as a map overlay yet, flagged in SPEC §14 as a
   deferred visualization, not a silent gap), the weekly coverage leaderboard (`GET
   /leaderboards/coverage`), and sign-out (wired to the `AuthController.signOut()` method
   that existed since step 3 but had no button). No server changes — all four endpoints
   were already implemented and tested.

Testable: full loop on real devices in one seeded city; spoofing attempts with
mock-location apps and emulators are caught.

## M2 — Beta (1–3 seeded cities, public TestFlight / Play open testing)

- Seed 50–100 founder POIs per city; onboard founding creators.
- Push notifications (opt-in) + weekly "featured near you".
- **Badges v1 and creator score accrual (SPEC §16; done, server + mobile).** Closed 4-key
  badge taxonomy proposed and implemented in the same PR (`ARCHITECTURE.md`'s schema
  sketch named the table and category but not concrete keys/thresholds): `first_in_region`
  (one-time — first ever verified check-in to cover a brand-new H3 r7 cell) and
  `poi_milestone_{10,50,100}` (awarded to a POI's creator when its `checkin_count`
  crosses each threshold, checked ascending so jumping past several in one check-in
  awards them all). Both awarded inside the same transaction as the verified check-in's
  existing coverage-insert/count-increment side effects, so a rolled-back check-in never
  awards one; `INSERT ... ON CONFLICT DO NOTHING` is the only idempotency guard needed.
  `creatorScore` (sum of `checkin_count` across a user's non-removed created POIs) added
  to `GET /me`'s `stats`, deliberately the simplest faithful definition since M2 only
  calls for it being visible, not ranked (that's M3). Mobile UI landed later, in the same
  vertical-slice order M1's moderation loop did (server-first): the profile screen's stats
  line now shows `creatorScore`, and a `Wrap` of `Chip`s renders each earned badge (icon +
  label from a closed switch over the 4-key taxonomy, `features/profile/badge_display.dart`
  — same pattern as `poiCategoryIcon`), fetched via a new `GET /me/badges` call added
  alongside `ProfileController`'s existing four concurrent requests.
- **Personal coverage map — heatmap & drill-down (SPEC §15; done, server + mobile).**
  New `GET /me/coverage/heatmap?zoom=`, bucketing the caller's r7 `user_coverage` cells
  by H3 ancestor at a resolution chosen from the camera zoom (`resolutionForZoom`,
  `[2, 3, 5, 7]`). City/state/country boundary labeling was explicitly decided against for
  now (H3 tiers stand in, with generic "this area" identity rather than real place names) —
  flagged as deferred, gated on choosing a bundled-boundary-dataset vs. reverse-geocoding
  approach later. Mobile `PersonalMapScreen` (reachable from Profile's "View my map")
  renders a MapLibre heatmap layer below the pin-mode zoom threshold (13, shared with
  `GET /pois`) and switches to `CircleManager` pins (own postcards + nearby POIs) above it;
  tapping a heatmap cell resolves to its nearest centroid (`nearestHeatmapCell` — heatmap
  layers have no native per-feature tap the way annotation-manager pins do) and drills in
  one tier. Noted, not fixed here: the discovery `MapScreen` doesn't render any
  pins/clusters at all — a pre-existing gap this feature's `CircleManager` plumbing didn't
  need to touch.
- ~~Shareable map image with precision controls.~~ Done — see SPEC §19 above.
- **Postcard sending v1** (ARCHITECTURE.md §10): share-image + unlisted web-postcard link
  from any verified check-in, message moderation, photographer credit. First job of the
  thin web renderer; the send→open→install funnel is instrumented from day one.
- Steps/distance from HealthKit / Health Connect (read-only, opt-in): daily aggregates,
  weekly friends/city distance boards, explorer streaks. Never app-gathered
  (ARCHITECTURE.md §9).
- **Offline check-in outbox — deferred evidence (SPEC §17; done, server + mobile).** A
  `checkinIntent` that fails with no connectivity falls back to gathering fixes/photo
  locally (neither needs the network) and queuing in a durable local outbox
  (`path_provider`, new mobile dependency, flagged in SPEC §1) rather than surfacing an
  error. `POST /checkins` gains `evidence: "live"|"deferred"` (default `"live"`); a new
  pure `src/verification/freshness.ts` bounds how old fixes/capture may be per mode
  (`CHECKIN_LIVE_MAX_AGE_S` = 150s, `CHECKIN_DEFERRED_MAX_AGE_S` = 24h) — closing a latent
  gap where confirm-mode check-ins had no server-side fix-recency check at all. A cell
  first proven via deferred evidence doesn't count toward the competitive coverage
  leaderboard until re-covered live; `GET /me/coverage`, the heatmap, creatorScore, and
  badges are unaffected. Replay is opportunistic (app launch, or a manual "Retry now" on
  the profile screen's outbox banner) — no background sync. **Narrower than the general
  case, flagged:** only a network failure at the very first intent call queues; one
  striking later in an already-in-progress live flow still surfaces as today's plain error
  (deciding what to do with an already-uploaded photo mid-flow is deferred until it's a
  real problem).
- **Offline POI-creation outbox (SPEC §18; done, mobile-only).** Extends the pattern
  above to `POST /pois` — architecturally simpler, since POI creation has no intent/nonce
  step and the server never reads `gpsFix.capturedAt` for freshness (only lat/lng, for the
  `PIN_ADJUST_MAX_M` distance check), so this needed **zero server-side changes**. A
  network failure on the single `POST /pois` call queues title/description/category/
  location/gpsFix/photo locally; replay resubmits with `force: false`, and — since there's
  no human present to pick a dedupe candidate at replay time — automatically resubmits
  with `force: true` on a `dedupeCandidates` response rather than losing the queued
  creation (flagged: proximity dedupe is a nudge, not a data-integrity gate, so an
  occasional avoidable duplicate is preferred over silently discarding real offline
  effort). The profile screen's outbox banner now shows a combined count across both
  outboxes. Found and fixed along the way: the check-in outbox's replay loop was dropping
  a queued item on `rate/limited` (a transient rate-limit hit, not a real verdict) — now
  treated like a network failure (stop the pass, keep everything queued) in both outboxes.
- **Instagram-style browsing & sharing (SPEC §19; done, server + mobile).** Real photo
  thumbnails (`thumbnailUrl` — best-approved-photo-by-vote-score, same tie-break `GET
  /pois/:id`'s gallery already used) on `GET /pois/nearby`, `GET /me/map`, and `GET
  /pois/:id`; deliberately not computed on the panning-heavy `GET /pois?bbox=&zoom=` to
  avoid per-row query cost on up to 200 results. New bookmark feature: `saved_pois` table
  (migration 0004) + `POST /pois/:id/save`, surfaced via `GET /me/map`'s new `saved` array.
  Mobile: a 3-column Instagram-style profile grid (My Places) that opens a full-screen
  swipeable viewer on tap — feed-style browsing over the caller's *own* content, not a new
  endpoint or a public feed of other users' activity (SPEC §9's check-in-history-is-private
  invariant stays intact). A new Discover tab merges two independently-fetched sources —
  `GET /pois/nearby` (public) and `saved` (needs auth, so a logged-out 401 doesn't blank
  the rest of the feed) — into "places around me" / "places I want to visit" sections.
  Sharing (`share_plus`, new mobile dependency, flagged in SPEC §1): a share action on the
  grid viewer (the current photo), the personal map screen (`RepaintBoundary` capture of
  the map + heatmap as currently zoomed), and the profile's leaderboard — the last one
  captures a small dedicated standing card (handle/rank/cells), not a screenshot of the
  visible entries list, since that list can include other users' handles. This is
  deliberately how M2's "shareable map image with precision controls" item below
  gets satisfied — the already-built H3 zoom-tier heatmap (SPEC §15) *is* the precision
  control, not a new slider. Postcard sending v1 (below) is explicitly out of scope for
  this slice. Not yet verified on a real device: `RepaintBoundary.toImage()` capturing a
  MapLibre `PlatformView` is expected to work for texture-backed platform views on modern
  Flutter, but this sandbox has no device/emulator to confirm it visually (same caveat as
  the map widget itself, see M1 step 3).
- Ops: rejection-rate-by-cause dashboard, trust-event monitoring, moderation SLA.

Testable: retention (D7 second check-in ≥ 30%), verification false-reject < 5% outdoors,
moderation queue stays < 24h, density holds as user count grows.

## M3 — Monetized launch

- RevenueCat + StoreKit 2 / Play Billing; server-side entitlements; restore, family
  sharing, regional pricing.
- Vault goes live: free cap [50], sealed-postcard UI, instant retroactive unseal on
  upgrade. Paywall copy tested in beta cohort first.
- Tier 2 defined and shipped (pricing decision pending — see open questions).
- Full leaderboard matrix (coverage / creator / check-ins × global / country / region /
  friends × weekly / monthly / all-time).
- Region-aware age gate, final legal pass (photo license, guidelines, GDPR/CCPA flows).
- App Store / Play production launch in seed countries; expand city seeding playbook.

Testable: purchase/restore/refund paths on both stores, entitlement webhook resilience,
conversion at the vault moment, no paywalled safety surface.

## Post-launch candidates (unscheduled)

Web map viewer (MapLibre JS on the public API) · cosmetic map themes · advanced stats ·
friends graph import · POI curation/quality tiers · statistical anti-cheat sweeps v2.
