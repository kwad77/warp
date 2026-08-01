-- SPEC §16 (M2) — badge taxonomy is a closed enum, same discipline as every other
-- status/category type in this schema. creatorScore is computed from pois.checkin_count,
-- not stored, so no column changes are needed for it.
CREATE TYPE badge_key AS ENUM ('first_in_region', 'poi_milestone_10', 'poi_milestone_50', 'poi_milestone_100');
CREATE TABLE badges (
  user_id UUID NOT NULL REFERENCES users(id),
  badge_key badge_key NOT NULL,
  awarded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, badge_key));
