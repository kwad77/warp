# mapio — MVP Scope

Goal: prove the core loop end-to-end with real users in seeded beta cities —
**discover → travel → verify → check in → see it on my map → want the next one.**

## In scope

**POI creation**
- Live photo or camera-roll upload (creation only, labeled), GPS auto-fill with pin
  adjustment, title + optional description, category (small fixed set).
- On-device face/person detection blocks people photos at capture; server-side moderation
  before the photo is publicly visible; human review queue (minimal admin page).
- Dedupe prompt: nearby (r9 + distance) POI with pHash-similar photo → "add your photo to
  this POI instead?"

**Check-in — both modes, full verification**
- Photo mode (in-app live capture only) and existing-photo confirm mode.
- No-people rule enforced on check-in photos too (on-device block with retake prompt,
  server-side gate before gallery). A person in frame never fails the check-in itself —
  retake, or fall back to confirm mode (see ARCHITECTURE.md §5).
- Full pipeline: nonce intent, platform integrity (Play Integrity + App Attest), multi-fix
  GPS presence, velocity check, trust events. Pending/retry states, never a dead end.
- This is the MVP's engineering center of gravity — it ships complete, not stubbed.

**Personal map & collection**
- Map with checked-in (filled), created (special), and nearby undiscovered POIs.
- Basic stats: total check-ins, cities/regions, H3 r7 coverage count.
- Check-in success animation — the one moment of polish the MVP does not skip.

**Community map**
- Global public POI map, clustering at low zoom, category filter, POI page with
  vote-ranked gallery, check-in count, creator credit.
- Report/flag on every POI and photo.

**One leaderboard**
- Coverage (r7 cells), weekly + all-time, global + per-seed-city. Proves the
  competitive hook without building the full matrix.

**Accounts & privacy floor**
- Apple / Google / email auth; read-only browsing without an account.
- History private by default; GDPR-grade deletion and export from day one (retrofitting
  deletion is far harder than building it first).

**Free tier only** — the vault flag exists in the schema (`checkins.vaulted`) but nothing
is vaulted yet; no payments, no entitlements service.

## Explicitly out (deferred)

- Payments/tiers, RevenueCat, vault UI (schema-ready, dark)
- Badges, streaks, push notifications, "featured POIs near you"
- Steps/distance via HealthKit / Health Connect reads (M2; see ARCHITECTURE.md §9)
- Friends graph and friends leaderboards; creator-score and check-in-count leaderboards
- Shareable map image generation
- Delayed-visibility privacy option (private-by-default covers the MVP risk)
- Offline check-in outbox (MVP requires connectivity; the deferred-evidence design is
  documented and schema-compatible)
- Web map viewer

## MVP success criteria

- A stranger in a seed city can: find a POI, walk to it, check in first try ≥ 80% of the
  time outdoors, and see their map update — with zero explanation from us.
- Verification: < 5% false-rejection rate outdoors; spoofing via mock-location app on a
  stock device is caught in testing.
- ≥ 30% of new users perform a second check-in within 7 days (early loop signal).
