// Unit tests for the pure logic in the OSM-seeding ops script (server/src/scripts/):
// the OSM-tag → SPEC §2 category mapping, and the per-category diversity cap. No
// network/DB — those are exercised only by actually running the script.
import { describe, expect, it } from 'vitest';
import type { CandidatePoi } from '../src/scripts/seed_osm_pois.js';
import { capForDiversity, categoryFor } from '../src/scripts/seed_osm_pois.js';

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
  it('caps nature and architecture but keeps other categories in full', () => {
    const candidates = [
      ...Array.from({ length: 50 }, () => candidate({ category: 'nature' })),
      ...Array.from({ length: 40 }, () => candidate({ category: 'architecture' })),
      ...Array.from({ length: 5 }, () => candidate({ category: 'landmark' })),
      ...Array.from({ length: 3 }, () => candidate({ category: 'street_art' })),
    ];

    const result = capForDiversity(candidates, 200);

    expect(result.filter((c) => c.category === 'nature')).toHaveLength(35);
    expect(result.filter((c) => c.category === 'architecture')).toHaveLength(25);
    expect(result.filter((c) => c.category === 'landmark')).toHaveLength(5);
    expect(result.filter((c) => c.category === 'street_art')).toHaveLength(3);
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
});
