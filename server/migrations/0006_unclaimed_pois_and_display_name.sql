-- SPEC §21 — unclaimed POIs (seeded, no creator yet) and opt-in named photo credit.
ALTER TABLE pois ALTER COLUMN creator_id DROP NOT NULL;
ALTER TABLE users ADD COLUMN display_name TEXT;
