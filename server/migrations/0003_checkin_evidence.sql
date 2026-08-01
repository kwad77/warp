-- SPEC §17 (M2) — offline check-in outbox: a check-in can be submitted well after its
-- fixes/capture were gathered (deferred, offline-captured evidence) rather than only
-- live. Closed enum, same discipline as every other status/category type in this schema.
CREATE TYPE checkin_evidence_mode AS ENUM ('live', 'deferred');
ALTER TABLE checkins ADD COLUMN evidence checkin_evidence_mode NOT NULL DEFAULT 'live';
