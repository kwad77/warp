import type { PoiCategory } from '../constants.js';
// Ops tooling, not part of the served API — imports real POIs from OpenStreetMap
// (Overpass API, no key/credential needed) as founder-seeded data for a new city
// (docs/MILESTONES.md M2: "Seed 50-100 founder POIs per city; onboard founding
// creators"). Run directly via tsx, same convention as db/migrate.ts. Every insert goes
// through the real `createPoi` service function — same validation, dedupe, and
// checkin-radius-by-category logic a real user's `POST /pois` call gets, not a
// hand-rolled INSERT that could drift from it.
import { type Db, type Pg, createDb } from '../db/client.js';
import { type LatLng, haversineM } from '../geo/distance.js';
import { uuidv7 } from '../lib/uuid.js';
import { createPoi } from '../pois/service.js';

// Beyond single-town scale, exact-name dedup silently discards genuinely distinct real
// places that happen to share a name (chain churches, national-park-style peak names,
// "City Park" in five different towns) — confirmed at both Oregon-wide (805 name
// collisions with occurrences >5km apart, e.g. "Elk Mountain" 13 times, up to 682km
// apart) and Portland scale (25 collisions >1km apart, e.g. "The Church of Jesus Christ
// of Latter-day Saints" 15 times, 33km apart) before this fix. Two elements sharing a
// name only merge into one candidate if they're ALSO within this radius — generous
// enough to cover one real park's several OSM representations (boundary way + label
// node + entrance nodes), tight enough that same-named-but-different places a town or
// more apart are kept as separate candidates.
const NAME_DEDUPE_RADIUS_M = 2000;

export interface OsmElement {
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: Record<string, string>;
}

export interface CityBbox {
  name: string;
  south: number;
  west: number;
  north: number;
  east: number;
}

const OVERPASS_URL = 'https://overpass-api.de/api/interpreter';

function overpassQuery(bbox: CityBbox): string {
  const b = `${bbox.south},${bbox.west},${bbox.north},${bbox.east}`;
  return `[out:json][timeout:60];(
    node["tourism"~"viewpoint|artwork|attraction|picnic_site"](${b});
    node["historic"](${b});
    node["leisure"~"park|nature_reserve|garden|dog_park"](${b});
    node["natural"~"wood|water|beach|peak"](${b});
    node["amenity"="place_of_worship"](${b});
    node["man_made"="tower"](${b});
    way["leisure"~"park|nature_reserve|garden|dog_park"](${b});
    way["historic"](${b});
    way["amenity"="place_of_worship"](${b});
    way["tourism"~"attraction"](${b});
  );out center tags;`;
}

/**
 * OSM tag → SPEC §2 category mapping. Proposed here, not pre-existing: OSM's tagging
 * scheme has no 1:1 correspondence to our 6-category enum, so this is a judgment call —
 * `amenity=place_of_worship` and `historic=building` both read as "architecture" (a
 * building worth checking in for, not the landmark event a memorial marks); `historic=
 * memorial|monument|wayside_cross` and `tourism=attraction` read as "landmark" (the
 * significance is the site/event, not necessarily an interesting structure);
 * `tourism=artwork` is always "street_art" regardless of `artwork_type` (statue vs.
 * mural vs. installation — SPEC's category is coarser than OSM's own subtyping).
 */
export function categoryFor(tags: Record<string, string>): PoiCategory {
  if (tags.tourism === 'viewpoint') return 'viewpoint';
  if (tags.tourism === 'artwork') return 'street_art';
  if (tags.tourism === 'attraction' || tags.tourism === 'picnic_site') return 'landmark';
  if (
    tags.historic === 'memorial' ||
    tags.historic === 'monument' ||
    tags.historic === 'wayside_cross'
  ) {
    return 'landmark';
  }
  if (tags.historic === 'train_station' || tags.historic === 'building') return 'architecture';
  if (tags.amenity === 'place_of_worship') return 'architecture';
  if (tags.man_made === 'tower') return 'landmark';
  if (tags.leisure && ['park', 'nature_reserve', 'garden', 'dog_park'].includes(tags.leisure)) {
    return 'nature';
  }
  if (tags.natural && ['wood', 'water', 'beach', 'peak'].includes(tags.natural)) return 'nature';
  return 'other';
}

export interface CandidatePoi {
  title: string;
  description: string | undefined;
  category: PoiCategory;
  location: LatLng;
}

/**
 * Dedup by name + proximity (NAME_DEDUPE_RADIUS_M — see its comment): bucket by
 * lowercased name first (OSM frequently represents one real-world POI, e.g. a park, as
 * several nodes/ways — a boundary way plus point nodes for its label, entrances, etc.),
 * then within a bucket only merge entries that are actually near each other. Pure, so
 * it's unit-tested directly rather than only exercised by actually running the script.
 */
export function dedupeOsmElements(elements: OsmElement[]): CandidatePoi[] {
  const byName = new Map<string, CandidatePoi[]>();
  for (const el of elements) {
    const tags = el.tags ?? {};
    const rawName = tags.name?.trim();
    if (!rawName || rawName.length < 3) continue;

    const lat = el.lat ?? el.center?.lat;
    const lng = el.lon ?? el.center?.lon;
    if (lat === undefined || lng === undefined) continue;

    const key = rawName.toLowerCase();
    const kept = byName.get(key) ?? [];
    const isNearAnExisting = kept.some(
      (c) => haversineM(c.location, { lat, lng }) <= NAME_DEDUPE_RADIUS_M,
    );
    if (isNearAnExisting) continue;

    kept.push({
      title: rawName.slice(0, 80),
      description: tags.description?.slice(0, 280),
      category: categoryFor(tags),
      location: { lat, lng },
    });
    byName.set(key, kept);
  }
  return [...byName.values()].flat();
}

async function fetchCandidates(bbox: CityBbox): Promise<CandidatePoi[]> {
  const res = await fetch(OVERPASS_URL, {
    method: 'POST',
    // Overpass's Apache front-end 406s Node's default fetch headers (no User-Agent, an
    // Accept it doesn't like) — not something curl or a browser hits, confirmed by
    // reproducing both ways before adding this.
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent': 'wanderpost-seed-script/1.0',
      Accept: '*/*',
    },
    body: `data=${encodeURIComponent(overpassQuery(bbox))}`,
  });
  if (!res.ok) {
    throw new Error(`Overpass API returned ${res.status}`);
  }
  const body = (await res.json()) as { elements: OsmElement[] };
  return dedupeOsmElements(body.elements);
}

/**
 * Caps a monoculture of parks/churches (OSM tags far more of these than anything else,
 * in a small town or a big city alike) so the seeded set stays visually diverse rather
 * than "however many OSM happens to have tagged." The per-category cap is a FRACTION of
 * `max` (`maxCategoryShare`), not a fixed absolute count — a fixed number tuned for a
 * small town (e.g. "35 nature spots") would either be a no-op for a big city's real
 * count or, worse, badly under-fill a large `max` meant to validate at real-city scale.
 *
 * Categories are round-robin interleaved in the output rather than concatenated as whole
 * blocks: `max` (the CLI's `maxPois`) truncates this list before it ever reaches the
 * creation loop, so whichever category appears first in OSM's raw element order would
 * otherwise consume the whole `max` budget by itself. Confirmed against real Portland
 * data before this fix — an uninterleaved list handed 100 rate-limited creates came back
 * 100% street_art (Portland's ~1,000+ "intersection painting" nodes ran ahead of every
 * other category), despite the per-category cap correctly limiting the candidate *pool*.
 * Interleaving means the first `max` results are a mix regardless of what truncates them.
 */
export function capForDiversity(
  candidates: CandidatePoi[],
  max: number,
  maxCategoryShare = 0.4,
): CandidatePoi[] {
  const perCategoryCap = Math.ceil(max * maxCategoryShare);
  const byCategory = new Map<PoiCategory, CandidatePoi[]>();
  for (const c of candidates) {
    const list = byCategory.get(c.category) ?? [];
    list.push(c);
    byCategory.set(c.category, list);
  }
  const capped = [...byCategory.values()].map((list) => list.slice(0, perCategoryCap));

  const result: CandidatePoi[] = [];
  for (let round = 0; result.length < max; round++) {
    let addedThisRound = false;
    for (const list of capped) {
      if (round >= list.length) continue;
      result.push(list[round] as CandidatePoi);
      addedThisRound = true;
      if (result.length >= max) break;
    }
    if (!addedThisRound) break;
  }
  return result;
}

// SPEC §2's POI_CREATE_PER_DAY (20) models a real user's posting velocity — a one-time
// curated import of real-world places from OSM isn't that, so createPoi is called with
// skipRateLimit: true (see its definition) rather than sizing a pile of synthetic
// "founder" accounts to the day's quota, which was the wrong shape entirely: real users
// seeding a brand-new city won't bulk-load a few hundred places in one sitting either, so
// there's no "N accounts × 20/day" number that's actually representative of anything.
// Founder accounts still exist — attributing every seeded POI to one shared "seed bot"
// would look wrong in the product (MILESTONES.md's own "onboard founding creators,"
// plural) — but their count is now a product/variety choice, not a capacity workaround.
// Handles are namespaced PER CITY (by `founderPrefix`) since distinct local founding
// creators per city is more realistic anyway.
function founderHandles(founderPrefix: string, count: number): string[] {
  return Array.from({ length: count }, (_, i) => `${founderPrefix}_founder_${i + 1}`);
}

async function ensureFounders(pg: Pg, handles: string[]): Promise<string[]> {
  const ids: string[] = [];
  for (const handle of handles) {
    const existing = await pg`SELECT id FROM users WHERE handle = ${handle}`;
    if (existing.length > 0) {
      ids.push((existing[0] as { id: string }).id);
      continue;
    }
    const id = uuidv7();
    await pg`INSERT INTO users (id, handle, email) VALUES (${id}, ${handle}, ${`${handle}@wanderpost.seed`})`;
    ids.push(id);
  }
  return ids;
}

export async function seedCityFromOsm(
  databaseUrl: string,
  bbox: CityBbox,
  maxPois: number,
  log: (msg: string) => void,
  founderPrefix: string,
  founderCount = 3,
): Promise<void> {
  const { db, pg, close } = createDb(databaseUrl);
  try {
    log(`Querying OSM for ${bbox.name}...`);
    const raw = await fetchCandidates(bbox);
    const candidates = capForDiversity(raw, maxPois);
    log(`${raw.length} unique named candidates found, seeding ${candidates.length}`);

    const handles = founderHandles(founderPrefix, founderCount);
    const founders = await ensureFounders(pg, handles);
    log(`Using ${founders.length} founder accounts (${handles.join(', ')})`);

    let created = 0;
    let skippedDuplicate = 0;
    let skippedError = 0;
    for (let i = 0; i < candidates.length; i++) {
      const c = candidates[i] as CandidatePoi;
      const founderId = founders[i % founders.length] as string;
      try {
        const result = await createPoi(
          db as Db,
          pg,
          founderId,
          {
            title: c.title,
            ...(c.description !== undefined ? { description: c.description } : {}),
            category: c.category,
            location: c.location,
            gpsFix: c.location,
            skipRateLimit: true,
          },
          new Date(),
        );
        if ('dedupeCandidates' in result) {
          skippedDuplicate++;
        } else {
          created++;
        }
      } catch (err) {
        skippedError++;
        log(`  skipped "${c.title}": ${(err as Error).message}`);
      }
    }
    log(
      `Done: ${created} created, ${skippedDuplicate} skipped as duplicates, ${skippedError} errors`,
    );
  } finally {
    await close();
  }
}

// Add a new bbox here for each future city this ops script seeds — bounds eyeballed
// generously around the actual city limits, not surveyed precisely (a few hundred
// meters of slack either way doesn't matter for this).
export const CITY_BBOXES: Record<string, CityBbox> = {
  tigard_or: { name: 'Tigard, OR', south: 45.38, west: -122.82, north: 45.46, east: -122.72 },
  portland_or: { name: 'Portland, OR', south: 45.43, west: -122.84, north: 45.65, east: -122.47 },
};

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;
if (isMain) {
  const url = process.env.DATABASE_URL;
  const cityKey = process.argv[2] ?? 'tigard_or';
  // Default (80) matches MILESTONES.md's "50-100 founder POIs" for a small town; a real
  // city needs a much higher cap to validate the pipeline at real scale — pass a third
  // CLI arg to override, e.g. `npm run db:seed -- portland_or 2000`.
  const maxPois = process.argv[3] ? Number(process.argv[3]) : 80;
  const bbox = CITY_BBOXES[cityKey];
  if (!url) {
    process.stderr.write('DATABASE_URL is required\n');
    process.exit(1);
  }
  if (!bbox) {
    process.stderr.write(
      `Unknown city "${cityKey}" — known: ${Object.keys(CITY_BBOXES).join(', ')}\n`,
    );
    process.exit(1);
  }
  const founderCount = process.argv[4] ? Number(process.argv[4]) : 3;
  seedCityFromOsm(
    url,
    bbox,
    maxPois,
    (msg) => process.stdout.write(`${msg}\n`),
    cityKey,
    founderCount,
  ).catch((err) => {
    process.stderr.write(`${(err as Error).stack ?? err}\n`);
    process.exit(1);
  });
}
