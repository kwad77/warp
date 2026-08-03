-- SPEC §20 (M2) — postcard sending v1. `token` is a separate high-entropy value from
-- `id` (18 random bytes, base64url) rather than the id itself, so the public/unlisted
-- share URL never doubles as an internal, sequential-ish (uuidv7) row identifier.
CREATE TABLE postcards (
  id UUID PRIMARY KEY,
  checkin_id UUID NOT NULL REFERENCES checkins(id),
  sender_id UUID NOT NULL REFERENCES users(id),
  token TEXT NOT NULL,
  message TEXT,
  message_approved BOOLEAN NOT NULL DEFAULT true,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX postcards_token_idx ON postcards (token);
CREATE INDEX postcards_checkin_idx ON postcards (checkin_id);
