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
- Badges v1 (first-in-region, POI milestones) and creator score accrual (visible, not yet
  a leaderboard).
- Shareable map image with precision controls.
- **Postcard sending v1** (ARCHITECTURE.md §10): share-image + unlisted web-postcard link
  from any verified check-in, message moderation, photographer credit. First job of the
  thin web renderer; the send→open→install funnel is instrumented from day one.
- Steps/distance from HealthKit / Health Connect (read-only, opt-in): daily aggregates,
  weekly friends/city distance boards, explorer streaks. Never app-gathered
  (ARCHITECTURE.md §9).
- Offline check-in outbox (deferred-evidence flow).
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
