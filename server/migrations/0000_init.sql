-- SPEC §8 — authoritative initial schema. Never edit after it has been applied anywhere.
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TYPE poi_category AS ENUM ('landmark','viewpoint','nature','architecture','street_art','other');
CREATE TYPE poi_status AS ENUM ('active','pending_review','flagged','removed');
CREATE TYPE photo_source AS ENUM ('poi_creation','checkin');
CREATE TYPE photo_moderation AS ENUM ('pending','approved','rejected','escalated');
CREATE TYPE photo_rejection AS ENUM ('people','unsafe','quality','other');
CREATE TYPE checkin_mode AS ENUM ('photo','confirm');
CREATE TYPE checkin_status AS ENUM ('verified','pending','rejected');
CREATE TYPE device_platform AS ENUM ('ios','android');
CREATE TYPE integrity_state AS ENUM ('untested','passed','degraded','failed');

CREATE TABLE users (
  id UUID PRIMARY KEY, handle TEXT NOT NULL UNIQUE,
  email TEXT UNIQUE, apple_sub TEXT UNIQUE, google_sub TEXT UNIQUE,
  trust_score SMALLINT NOT NULL DEFAULT 100,
  privacy JSONB NOT NULL DEFAULT '{}',
  deleted_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT now());

CREATE TABLE refresh_tokens (
  jti UUID PRIMARY KEY, fam UUID NOT NULL, user_id UUID NOT NULL REFERENCES users(id),
  used BOOLEAN NOT NULL DEFAULT false, expires_at TIMESTAMPTZ NOT NULL);
CREATE INDEX ON refresh_tokens (fam);

CREATE TABLE email_login_codes (
  email TEXT NOT NULL, code_hash TEXT NOT NULL, used BOOLEAN NOT NULL DEFAULT false,
  expires_at TIMESTAMPTZ NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX ON email_login_codes (email, created_at);

CREATE TABLE devices (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES users(id),
  platform device_platform NOT NULL, model TEXT,
  integrity_state integrity_state NOT NULL DEFAULT 'untested',
  first_seen TIMESTAMPTZ NOT NULL DEFAULT now(), last_seen TIMESTAMPTZ NOT NULL DEFAULT now());

CREATE TABLE pois (
  id UUID PRIMARY KEY, creator_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL, description TEXT, category poi_category NOT NULL,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  h3_r9 BIGINT NOT NULL, checkin_radius_m INT NOT NULL,
  status poi_status NOT NULL DEFAULT 'active',
  checkin_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX ON pois USING GIST (location);
CREATE INDEX ON pois (h3_r9);

CREATE TABLE photos (
  id UUID PRIMARY KEY, poi_id UUID NOT NULL REFERENCES pois(id),
  uploader_id UUID NOT NULL REFERENCES users(id),
  storage_key TEXT NOT NULL UNIQUE, width INT, height INT, bytes INT,
  phash BIGINT, source photo_source NOT NULL,
  moderation photo_moderation NOT NULL DEFAULT 'pending',
  rejection_reason photo_rejection,
  vote_score INT NOT NULL DEFAULT 0, exif_summary JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX ON photos (poi_id, moderation, vote_score DESC);

CREATE TABLE checkin_nonces (
  nonce_hash TEXT PRIMARY KEY, user_id UUID NOT NULL, device_id UUID NOT NULL,
  poi_id UUID NOT NULL, used BOOLEAN NOT NULL DEFAULT false, expires_at TIMESTAMPTZ NOT NULL);

CREATE TABLE checkins (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES users(id),
  poi_id UUID NOT NULL REFERENCES pois(id),
  mode checkin_mode NOT NULL, photo_id UUID REFERENCES photos(id),
  status checkin_status NOT NULL, vaulted BOOLEAN NOT NULL DEFAULT false,
  h3_r7 BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), verified_at TIMESTAMPTZ,
  UNIQUE (user_id, poi_id));
CREATE INDEX ON checkins (user_id, created_at DESC);

CREATE TABLE checkin_evidence (
  checkin_id UUID PRIMARY KEY REFERENCES checkins(id),
  fixes JSONB NOT NULL, best_fix JSONB NOT NULL, distance_m NUMERIC,
  integrity JSONB NOT NULL, velocity JSONB, capture JSONB,
  verdicts JSONB NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now());

CREATE TABLE trust_events (
  id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES users(id),
  type TEXT NOT NULL, delta SMALLINT NOT NULL, metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE INDEX ON trust_events (user_id, created_at DESC);

CREATE TABLE user_coverage (
  user_id UUID NOT NULL REFERENCES users(id), h3_r7 BIGINT NOT NULL,
  first_checkin_id UUID NOT NULL REFERENCES checkins(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY (user_id, h3_r7));

CREATE TABLE votes (
  user_id UUID NOT NULL REFERENCES users(id), photo_id UUID NOT NULL REFERENCES photos(id),
  value SMALLINT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, photo_id));

CREATE TABLE reports (
  id UUID PRIMARY KEY, reporter_id UUID NOT NULL REFERENCES users(id),
  target_type TEXT NOT NULL, target_id UUID NOT NULL, reason TEXT NOT NULL, note TEXT,
  status TEXT NOT NULL DEFAULT 'open', resolved_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now());
