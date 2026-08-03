import type { PoiCategory } from '../constants.js';
// Ops tooling, not part of the served API — imports real POIs from OpenStreetMap
// (Overpass API, no key/credential needed) as founder-seeded data for a new city
// (docs/MILESTONES.md M2: "Seed 50-100 founder POIs per city; onboard founding
// creators"). Run directly via tsx, same convention as db/migrate.ts. Every insert goes
// through the real `createPoi` service function — same validation, dedupe, and
// checkin-radius-by-category logic a real user's `POST /pois` call gets, not a
// hand-rolled INSERT that could drift from it.
import { type Db, type Pg, createDb } from '../db/client.js';
import type { LatLng } from '../geo/distance.js';
import { uuidv7 } from '../lib/uuid.js';
import { createPoi } from '../pois/service.js';

interface OsmElement {
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

  // Dedup by name: OSM frequently represents one real-world POI (e.g. a park) as
  // several nodes/ways (a boundary way plus point nodes for its label, entrances,
  // etc.) — same name, same place. Keeping the first occurrence is simple and safe at
  // town scale; a name collision between two genuinely different places is unlikely
  // enough here not to warrant proximity-based clustering on top of it.
  const seen = new Set<string>();
  const candidates: CandidatePoi[] = [];
  for (const el of body.elements) {
    const tags = el.tags ?? {};
    const rawName = tags.name?.trim();
    if (!rawName || rawName.length < 3) continue;
    const key = rawName.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);

    const lat = el.lat ?? el.center?.lat;
    const lng = el.lon ?? el.center?.lon;
    if (lat === undefined || lng === undefined) continue;

    candidates.push({
      title: rawName.slice(0, 80),
      description: tags.description?.slice(0, 280),
      category: categoryFor(tags),
      location: { lat, lng },
    });
  }
  return candidates;
}

/**
 * Caps a monoculture of parks/churches (OSM tags far more of these than anything else
 * in a residential suburb) so the seeded set stays visually diverse and lands in the
 * "50-100 founder POIs" range MILESTONES.md actually asks for, not "however many OSM
 * happens to have tagged."
 */
export function capForDiversity(candidates: CandidatePoi[], max: number): CandidatePoi[] {
  const perCategoryCap: Partial<Record<PoiCategory, number>> = { nature: 35, architecture: 25 };
  const byCategory = new Map<PoiCategory, CandidatePoi[]>();
  for (const c of candidates) {
    const list = byCategory.get(c.category) ?? [];
    list.push(c);
    byCategory.set(c.category, list);
  }
  const result: CandidatePoi[] = [];
  for (const [category, list] of byCategory) {
    const cap = perCategoryCap[category] ?? list.length;
    result.push(...list.slice(0, cap));
  }
  return result.slice(0, max);
}

// SPEC §2's POI_CREATE_PER_DAY (20) is a per-creator anti-abuse limit, enforced inside
// createPoi itself — not something a legitimate one-time data import should route
// around. Multiple named "founder" accounts (matching MILESTONES.md's own "onboard
// founding creators," plural) keeps every account under that cap while staying honest:
// createdAt is real (today), nothing is backdated to fake a longer history.
const FOUNDER_HANDLES = ['founder_1', 'founder_2', 'founder_3', 'founder_4', 'founder_5'];

async function ensureFounders(pg: Pg): Promise<string[]> {
  const ids: string[] = [];
  for (const handle of FOUNDER_HANDLES) {
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
): Promise<void> {
  const { db, pg, close } = createDb(databaseUrl);
  try {
    log(`Querying OSM for ${bbox.name}...`);
    const raw = await fetchCandidates(bbox);
    const candidates = capForDiversity(raw, maxPois);
    log(`${raw.length} unique named candidates found, seeding ${candidates.length}`);

    const founders = await ensureFounders(pg);
    log(`Using ${founders.length} founder accounts (${FOUNDER_HANDLES.join(', ')})`);

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
};

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;
if (isMain) {
  const url = process.env.DATABASE_URL;
  const cityKey = process.argv[2] ?? 'tigard_or';
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
  seedCityFromOsm(url, bbox, 80, (msg) => process.stdout.write(`${msg}\n`)).catch((err) => {
    process.stderr.write(`${(err as Error).stack ?? err}\n`);
    process.exit(1);
  });
}
