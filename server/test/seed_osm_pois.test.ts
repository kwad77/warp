// Unit tests for the pure logic in the OSM-seeding ops script (server/src/scripts/):
// the OSM-tag → SPEC §2 category mapping, and the per-category diversity cap. No
// network/DB — those are exercised only by actually running the script.
import { describe, expect, it } from 'vitest';
import type { CandidatePoi, OsmElement } from '../src/scripts/seed_osm_pois.js';
import { capForDiversity, categoryFor, dedupeOsmElements } from '../src/scripts/seed_osm_pois.js';

describe('categoryFor', () => {
  it('maps tourism tags', () => {
    expect(categoryFor({ tourism: 'viewpoint' })).toBe('viewpoint');
    expect(categoryFor({ tourism: 'artwork', artwork_type: 'mural' })).toBe('street_art');
    expect(categoryFor({ tourism: 'attraction' })).toBe('landmark');
    expect(categoryFor({ tourism: 'picnic_site' })).toBe('landmark');
  });

  it('maps historic tags', () => {
    expect(categoryFor({ historic: 'memorial' })).toBe('landmark');
    expect(categoryFor({ historic: 'monument' })).toBe('landmark');
    expect(categoryFor({ historic: 'wayside_cross' })).toBe('landmark');
    expect(categoryFor({ historic: 'train_station' })).toBe('architecture');
    expect(categoryFor({ historic: 'building' })).toBe('architecture');
  });

  it('maps amenity/man_made tags', () => {
    expect(categoryFor({ amenity: 'place_of_worship' })).toBe('architecture');
    expect(categoryFor({ man_made: 'tower' })).toBe('landmark');
  });

  it('maps leisure/natural tags to nature', () => {
    for (const leisure of ['park', 'nature_reserve', 'garden', 'dog_park']) {
      expect(categoryFor({ leisure })).toBe('nature');
    }
    for (const natural of ['wood', 'water', 'beach', 'peak']) {
      expect(categoryFor({ natural })).toBe('nature');
    }
  });

  it('falls back to other for anything unrecognized', () => {
    expect(categoryFor({ shop: 'bakery' })).toBe('other');
    expect(categoryFor({})).toBe('other');
  });

  it('checks tourism before historic (tourism=attraction with an unrelated historic tag)', () => {
    expect(categoryFor({ tourism: 'viewpoint', historic: 'building' })).toBe('viewpoint');
  });
});

function osmNode(
  tags: Record<string, string>,
  coords: { lat: number; lon: number } | { center: { lat: number; lon: number } } = {
    lat: 45.4,
    lon: -122.77,
  },
): OsmElement {
  return { ...coords, tags };
}

describe('dedupeOsmElements', () => {
  it('merges same-named elements that are close together (one real place, several OSM representations)', () => {
    const elements = [
      osmNode({ name: 'Fanno Creek Park', leisure: 'park' }, { lat: 45.4, lon: -122.77 }),
      // A second node for the same park, ~100m away (well within NAME_DEDUPE_RADIUS_M).
      osmNode({ name: 'Fanno Creek Park', leisure: 'park' }, { lat: 45.4009, lon: -122.77 }),
    ];

    expect(dedupeOsmElements(elements)).toHaveLength(1);
  });

  it('keeps same-named elements that are genuinely far apart as separate candidates', () => {
    // "Elk Mountain" — confirmed in the wild to name 13 distinct real Oregon peaks up
    // to 682km apart; this reproduces that shape at a smaller distance.
    const elements = [
      osmNode({ name: 'Elk Mountain', natural: 'peak' }, { lat: 45.4, lon: -122.77 }),
      osmNode({ name: 'Elk Mountain', natural: 'peak' }, { lat: 44.0, lon: -121.0 }),
    ];

    const result = dedupeOsmElements(elements);
    expect(result).toHaveLength(2);
    expect(result.every((c) => c.title === 'Elk Mountain')).toBe(true);
  });

  it('skips elements with no name, a too-short name, or no coordinates', () => {
    const elements: OsmElement[] = [
      osmNode({ leisure: 'park' }),
      osmNode({ name: '  ' }),
      osmNode({ name: 'Hi' }),
      { tags: { name: 'Real Named Place' } }, // no lat/lon and no center
    ];

    expect(dedupeOsmElements(elements)).toHaveLength(0);
  });

  it('resolves a way element\'s location from its "center", not lat/lon', () => {
    const elements = [
      osmNode({ name: 'A Way Element', leisure: 'park' }, { center: { lat: 45.5, lon: -122.6 } }),
    ];

    const result = dedupeOsmElements(elements);
    expect(result).toHaveLength(1);
    expect(result[0]?.location).toEqual({ lat: 45.5, lng: -122.6 });
  });
});

function candidate(overrides: Partial<CandidatePoi> = {}): CandidatePoi {
  return {
    title: 'Test Place',
    description: undefined,
    category: 'nature',
    location: { lat: 45.4, lng: -122.77 },
    ...overrides,
  };
}

describe('capForDiversity', () => {
  it('caps a category at maxCategoryShare of max, keeps smaller categories in full', () => {
    const candidates = [
      ...Array.from({ length: 500 }, () => candidate({ category: 'nature' })),
      ...Array.from({ length: 400 }, () => candidate({ category: 'architecture' })),
      ...Array.from({ length: 50 }, () => candidate({ category: 'landmark' })),
      ...Array.from({ length: 30 }, () => candidate({ category: 'street_art' })),
    ];

    // maxCategoryShare 0.4 of 1000 = cap of 400 per category.
    const result = capForDiversity(candidates, 1000, 0.4);

    expect(result.filter((c) => c.category === 'nature')).toHaveLength(400);
    expect(result.filter((c) => c.category === 'architecture')).toHaveLength(400);
    expect(result.filter((c) => c.category === 'landmark')).toHaveLength(50);
    expect(result.filter((c) => c.category === 'street_art')).toHaveLength(30);
  });

  it('scales the per-category cap with max, not a fixed absolute count', () => {
    const candidates = Array.from({ length: 5000 }, () => candidate({ category: 'nature' }));

    // A cap tuned for a small town (a fixed "35") would badly under-fill a big-city run;
    // the cap must scale with whatever max the caller actually asked for.
    expect(capForDiversity(candidates, 2000, 0.4)).toHaveLength(800);
    expect(capForDiversity(candidates, 80, 0.4)).toHaveLength(32);
  });

  it('still respects the overall max after per-category capping', () => {
    const candidates = [
      ...Array.from({ length: 35 }, () => candidate({ category: 'nature' })),
      ...Array.from({ length: 25 }, () => candidate({ category: 'architecture' })),
      ...Array.from({ length: 20 }, () => candidate({ category: 'landmark' })),
    ];

    const result = capForDiversity(candidates, 50);

    expect(result).toHaveLength(50);
  });

  it('passes through everything when under both caps', () => {
    const candidates = [candidate({ category: 'viewpoint' }), candidate({ category: 'landmark' })];

    expect(capForDiversity(candidates, 80)).toHaveLength(2);
  });

  it('interleaves categories so a capacity-limited run still gets a mix, not a monoculture', () => {
    // Reproduces the real Portland finding: street_art vastly outnumbered every other
    // category in OSM's raw element order, and a rate-limited creation run that only gets
    // through the first `max` candidates must not have all of them come from one category.
    const candidates = [
      ...Array.from({ length: 1000 }, () => candidate({ category: 'street_art' })),
      ...Array.from({ length: 10 }, () => candidate({ category: 'nature' })),
      ...Array.from({ length: 10 }, () => candidate({ category: 'landmark' })),
    ];

    const result = capForDiversity(candidates, 30, 0.4);
    const categories = new Set(result.map((c) => c.category));
    expect(categories.has('nature')).toBe(true);
    expect(categories.has('landmark')).toBe(true);
    expect(categories.has('street_art')).toBe(true);
  });
});
