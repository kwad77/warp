-- SPEC §5.7 — rejected check-ins persist for audit but never block an honest retry.
-- 0000 declared the constraint inline, so it carries Postgres's default name.
ALTER TABLE checkins DROP CONSTRAINT checkins_user_id_poi_id_key;
CREATE UNIQUE INDEX checkins_user_poi_active
  ON checkins (user_id, poi_id) WHERE status <> 'rejected';
