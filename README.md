# mapio (working title: "Postcards")

A location-based collection game built on one loop: **"I've been there — and here's the proof."**

Users discover community-created Points of Interest (POIs) anchored by postcard-style photos
(places, never people). Standing at a POI, they check in — either by taking a live photo that
joins the POI's postcard gallery, or by confirming an existing photo ("I stood here too").
Verified check-ins build each user's personal world map; creators earn points when others
check into their POIs. Trust in the check-in is the product's foundation.

## Documents

| Doc | Contents |
| --- | --- |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Stack choices and justification, data model, API surface, verification pipeline, cost strategy, top risks |
| [docs/MVP.md](docs/MVP.md) | Smallest scope that proves the core loop |
| [docs/MILESTONES.md](docs/MILESTONES.md) | MVP → beta → monetized launch plan |

## Decisions made so far

- **Mobile:** Flutter (single codebase, iOS + Android; web map viewer comes later as a separate thin client on the same API)
- **Backend:** TypeScript (Fastify) API in a container + managed Postgres/PostGIS + Cloudflare R2/CDN for photos
- **Paywall:** "Vault" model — check-ins are never blocked; beyond the free cap they're captured, verified, and sealed until upgrade
- **Launch:** seeded beta in 1–3 cities, not a global cold start

## Repository layout (planned)

```
app/       Flutter application
server/    TypeScript API (Fastify), verification pipeline, workers
infra/     Deployment config (Fly.io/Cloud Run, migrations, CI)
docs/      Product & architecture documents
```
