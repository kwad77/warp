-- SPEC §19 (M2) — a plain bookmark ("places I want to visit"), same shape discipline as
-- `votes`/`badges`: composite PK on (user_id, poi_id), no separate id.
CREATE TABLE saved_pois (
  user_id UUID NOT NULL REFERENCES users(id),
  poi_id UUID NOT NULL REFERENCES pois(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, poi_id));
