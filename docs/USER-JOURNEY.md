# Wanderpost — Sample User Journey

Alignment artifact: one user, one Saturday, exercising the core loop end-to-end.
Everything here is MVP scope unless tagged [M2] or [M3].

Persona: **Maya, 29, lives in Lisbon** (a seed city). Found the app through a friend's
recommendation. Mid-range Android phone.

---

## 1. First open — value before signup

No signup wall, no carousel. The app asks for location **while-in-use** with a one-line
primer ("Wanderpost shows you postcard-worthy places nearby — location is only used while
you're exploring"), then opens straight onto the map: warm, muted basemap, postcard-style
pins clustering across Lisbon. The pins have slight depth — they read as tiny framed
photos pinned to the map.

She scrolls and taps a cluster near Alfama. It expands; she taps a pin. A bottom sheet
slides up: the POI's best postcard full-bleed at the top, title ("Miradouro de Santa
Luzia — tiled terrace over the rooftops"), check-in count (142), creator credit, distance
("400 m away"), and a gallery strip of other visitors' postcards ranked by votes. She can
browse the whole city like this without an account.

**Alignment point:** browsing is free, anonymous, and never paywalled. The map itself is
the ad for the game.

## 2. The signup moment

The sheet's primary button is **"I'm here — check in"** (enabled, since she's within the
75 m radius of a café POI she opened) or **"Save for later"** on far ones. She taps check
in → one screen: "Keep your map forever" with Apple / Google / email. She uses Google;
total detour is one tap plus the platform sheet. No profile setup, no interests quiz —
back to the check-in immediately.

## 3. First check-in — confirm mode

She's standing at the café. The check-in screen shows the POI's postcard and a soft
radar-pulse animation with "Confirming you're here…" — this is the 2–3 seconds where the
app requests the nonce, gathers a few GPS fixes, and gets the device integrity verdict.
None of that is narrated; verification is invisible when it passes.

Then the choice, framed as contribution rather than obligation:

> **Add your own postcard** — take a photo, join this place's gallery
> **"I stood here too"** — check in with a postcard from the gallery

The café's light is bad, so she swipes through the gallery, picks a favorite, and taps
"I stood here too." The success moment: the chosen postcard flips over like a real
postcard, gets a **stamped seal** with today's date and a solid haptic thunk, then flies
down onto her map, where the pin fills in. A quiet counter ticks: "1 place · 1 cell of
Lisbon". That stamp animation is the product's signature moment — same every time,
never skipped, under a second.

## 4. Second check-in — photo mode, person in frame

At the miradouro, she wants to contribute. In-app camera only (no roll access in this
flow — structurally, not just policy). As she frames the shot a tourist wanders in; a
gentle overlay appears live in the viewfinder: **"Someone's in frame — postcards are of
places. Wait for the moment."** The shutter stays disabled until the frame is clear —
caught at capture, while retaking costs nothing.

The tourist moves; she shoots. On-device check passes, the check-in verifies, stamp
animation plays immediately. Her photo uploads in the background (compressed on-device)
and shows in the gallery as "In review" with a subtle shimmer — public only after the
server-side moderation gate. Ten minutes later it's live. **The check-in never waited on
the photo** — presence verification and gallery admission are independent.

## 5. When GPS struggles — never call the user a liar

A POI in a narrow Alfama alley: accuracy is 90 m, too poor to verify. The app never says
"rejected." Instead: **"GPS is having trouble in this alley — step toward open sky and
we'll keep trying."** with a live accuracy indicator. She moves 20 m toward the square;
it locks, verifies, stamps. (If it hadn't: "We'll keep confirming this one — it'll stamp
shortly," a *pending* postcard with a faint seal, resolved server-side. Pending, not
failed, is the default posture for honest-looking trouble.)

## 6. Creating a POI

Walking home she passes a tiled facade that stops her — no pin on the map. FAB → "Add a
place." Camera opens (camera roll allowed here, clearly labeled "for creating places
only"); face check runs the same as always. Then: pin confirmation on a small map —
GPS-filled, draggable within a tight radius ("stand near the spot — you can nudge the
pin, not move it across town") — title, optional line of description, category.

Before publishing, dedupe runs: if a visually similar POI existed within ~50 m, she'd see
it — "Is this the same place? Add your postcard to it instead" (primary) vs. "No, this is
different" (secondary). Nothing similar exists, so it publishes: live on the map pending
photo moderation, with a **creator-styled marker** on her personal map. Copy plants the
incentive: "You made the map. You'll earn points whenever someone checks in here."

## 7. Evening — the pull to go again

Her personal map: two filled postcards, one created marker, and the H3 cells she touched
today tinted in. Stats: 3 places · 2 cells · 1 created. The weekly Lisbon coverage
leaderboard shows her at #14 with a nudge that's about geography, not grinding: "3 cells
from #10 — the river cells are wide open." Nearby undiscovered pins glow faintly on her
map. That's the loop closing: the map itself generates the next trip.

- [M2] Monday she gets an opt-in weekly digest: "4 new postcards near you." She connects
  Health — one consent screen stating exactly what's read (daily steps/distance, nothing
  else, drop anytime) — and lands on the friends' weekly distance board. Walked 11 km
  Saturday without noticing.
- [M3] Months later in Porto she crosses her 50th place. The check-in works exactly as
  always — stamp and all — but the postcard appears **sealed, not lost**: "Your vault is
  holding 3 postcards. Unlock your whole collection — $[X]/year." Every check-in she
  makes on the trip keeps being captured and verified. Upgrading that evening unseals
  everything retroactively.

---

## What this journey is meant to prove

1. Value opens before identity: map first, signup only at the moment of commitment.
2. Verification is invisible when it passes, gentle when it struggles, and never
   accusatory — *pending* beats *rejected*.
3. The no-people rule is enforced where it's cheapest: live in the viewfinder.
4. Contribution is framed as joining a gallery, not performing a task.
5. The stamp is the dopamine anchor — one signature moment, relentlessly consistent.
6. The paywall moment [M3] preserves the unrepeatable: nothing is ever blocked or lost.
