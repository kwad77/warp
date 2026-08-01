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
   the gate so far. Live rendering was genuinely attempted, not just skipped, and every
   path is blocked for a distinct, confirmed reason in this environment: Android emulator
   needs `/dev/kvm` (absent — this is a Docker container, no nested virtualization, no
   privilege to attach the device); iOS simulator needs macOS (a Linux container can't run
   one, ever); Flutter Linux desktop builds fine but `maplibre_gl` declares no Linux
   platform support at all; Flutter Web builds but needs CanvasKit from
   `gstatic.com`, and this sandbox's outbound HTTPS proxy fails Chromium's TLS handshake
   for that external fetch (independently confirmed `maplibre_gl_web` 0.21.0 is *also*
   broken against current Flutter stable — ARCHITECTURE.md). None of these are code
   defects in this PR. A real device/emulator run is still owed — first opportunity
   outside this specific sandbox, not a formality to wave through.
4. **Flutter app: create + check in** — in-app camera with on-device face check, POI
   creation with dedupe prompt, both check-in modes, success animation, retry/pending UX.
5. **Moderation loop** — `ModerationProvider` seam wired synchronously into photo
   completion (`DevModerationProvider` auto-approves); reports and photo voting shipped.
   Deferred pending explicit decisions (SPEC §6 M1 note): the real detector (needs an AWS
   SDK dependency not yet approved), pHash (needs image-byte fetch + `sharp`), and the
   human-review admin surface (needs an undesigned admin auth realm).
6. **Personal map + coverage + weekly leaderboard.**

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
