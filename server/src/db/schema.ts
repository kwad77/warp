// Drizzle mirror of migrations/0000_init.sql (SPEC §8). Drift between the two is a defect.
import { sql } from 'drizzle-orm';
import {
  bigint,
  boolean,
  customType,
  index,
  integer,
  jsonb,
  pgEnum,
  pgTable,
  primaryKey,
  smallint,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core';

/** geography(Point,4326); written as EWKT, read via ST_X/ST_Y in raw SQL when needed. */
const geographyPoint = customType<{ data: string; driverData: string }>({
  dataType() {
    return 'geography(Point,4326)';
  },
});

export const poiCategory = pgEnum('poi_category', [
  'landmark',
  'viewpoint',
  'nature',
  'architecture',
  'street_art',
  'other',
]);
export const poiStatus = pgEnum('poi_status', ['active', 'pending_review', 'flagged', 'removed']);
export const photoSource = pgEnum('photo_source', ['poi_creation', 'checkin']);
export const photoModeration = pgEnum('photo_moderation', [
  'pending',
  'approved',
  'rejected',
  'escalated',
]);
export const photoRejection = pgEnum('photo_rejection', ['people', 'unsafe', 'quality', 'other']);
export const checkinMode = pgEnum('checkin_mode', ['photo', 'confirm']);
export const checkinStatus = pgEnum('checkin_status', ['verified', 'pending', 'rejected']);
export const devicePlatform = pgEnum('device_platform', ['ios', 'android']);
export const integrityState = pgEnum('integrity_state', [
  'untested',
  'passed',
  'degraded',
  'failed',
]);
export const badgeKey = pgEnum('badge_key', [
  'first_in_region',
  'poi_milestone_10',
  'poi_milestone_50',
  'poi_milestone_100',
]);

export const users = pgTable('users', {
  id: uuid('id').primaryKey(),
  handle: text('handle').notNull().unique(),
  email: text('email').unique(),
  appleSub: text('apple_sub').unique(),
  googleSub: text('google_sub').unique(),
  trustScore: smallint('trust_score').notNull().default(100),
  privacy: jsonb('privacy').notNull().default({}),
  deletedAt: timestamp('deleted_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const refreshTokens = pgTable(
  'refresh_tokens',
  {
    jti: uuid('jti').primaryKey(),
    fam: uuid('fam').notNull(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id),
    used: boolean('used').notNull().default(false),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  },
  (t) => [index('refresh_tokens_fam_idx').on(t.fam)],
);

export const emailLoginCodes = pgTable(
  'email_login_codes',
  {
    email: text('email').notNull(),
    codeHash: text('code_hash').notNull(),
    used: boolean('used').notNull().default(false),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index('email_login_codes_email_idx').on(t.email, t.createdAt)],
);

export const devices = pgTable('devices', {
  id: uuid('id').primaryKey(),
  userId: uuid('user_id')
    .notNull()
    .references(() => users.id),
  platform: devicePlatform('platform').notNull(),
  model: text('model'),
  integrityState: integrityState('integrity_state').notNull().default('untested'),
  firstSeen: timestamp('first_seen', { withTimezone: true }).notNull().defaultNow(),
  lastSeen: timestamp('last_seen', { withTimezone: true }).notNull().defaultNow(),
});

export const pois = pgTable(
  'pois',
  {
    id: uuid('id').primaryKey(),
    creatorId: uuid('creator_id')
      .notNull()
      .references(() => users.id),
    title: text('title').notNull(),
    description: text('description'),
    category: poiCategory('category').notNull(),
    location: geographyPoint('location').notNull(),
    h3R9: bigint('h3_r9', { mode: 'bigint' }).notNull(),
    checkinRadiusM: integer('checkin_radius_m').notNull(),
    status: poiStatus('status').notNull().default('active'),
    checkinCount: integer('checkin_count').notNull().default(0),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index('pois_h3_r9_idx').on(t.h3R9)],
);

export const photos = pgTable(
  'photos',
  {
    id: uuid('id').primaryKey(),
    poiId: uuid('poi_id')
      .notNull()
      .references(() => pois.id),
    uploaderId: uuid('uploader_id')
      .notNull()
      .references(() => users.id),
    storageKey: text('storage_key').notNull().unique(),
    width: integer('width'),
    height: integer('height'),
    bytes: integer('bytes'),
    phash: bigint('phash', { mode: 'bigint' }),
    source: photoSource('source').notNull(),
    moderation: photoModeration('moderation').notNull().default('pending'),
    rejectionReason: photoRejection('rejection_reason'),
    voteScore: integer('vote_score').notNull().default(0),
    exifSummary: jsonb('exif_summary'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index('photos_poi_moderation_idx').on(t.poiId, t.moderation, t.voteScore)],
);

export const checkinNonces = pgTable('checkin_nonces', {
  nonceHash: text('nonce_hash').primaryKey(),
  userId: uuid('user_id').notNull(),
  deviceId: uuid('device_id').notNull(),
  poiId: uuid('poi_id').notNull(),
  used: boolean('used').notNull().default(false),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
});

export const checkins = pgTable(
  'checkins',
  {
    id: uuid('id').primaryKey(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id),
    poiId: uuid('poi_id')
      .notNull()
      .references(() => pois.id),
    mode: checkinMode('mode').notNull(),
    photoId: uuid('photo_id').references(() => photos.id),
    status: checkinStatus('status').notNull(),
    vaulted: boolean('vaulted').notNull().default(false),
    h3R7: bigint('h3_r7', { mode: 'bigint' }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    verifiedAt: timestamp('verified_at', { withTimezone: true }),
  },
  (t) => [
    // 0001: partial unique — rejected rows persist without blocking retries (SPEC §5.7)
    uniqueIndex('checkins_user_poi_active')
      .on(t.userId, t.poiId)
      .where(sql`status <> 'rejected'`),
    index('checkins_user_created_idx').on(t.userId, t.createdAt),
  ],
);

export const checkinEvidence = pgTable('checkin_evidence', {
  checkinId: uuid('checkin_id')
    .primaryKey()
    .references(() => checkins.id),
  fixes: jsonb('fixes').notNull(),
  bestFix: jsonb('best_fix').notNull(),
  distanceM: text('distance_m'),
  integrity: jsonb('integrity').notNull(),
  velocity: jsonb('velocity'),
  capture: jsonb('capture'),
  verdicts: jsonb('verdicts').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const trustEvents = pgTable(
  'trust_events',
  {
    id: uuid('id').primaryKey(),
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id),
    type: text('type').notNull(),
    delta: smallint('delta').notNull(),
    metadata: jsonb('metadata'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [index('trust_events_user_created_idx').on(t.userId, t.createdAt)],
);

export const userCoverage = pgTable(
  'user_coverage',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id),
    h3R7: bigint('h3_r7', { mode: 'bigint' }).notNull(),
    firstCheckinId: uuid('first_checkin_id')
      .notNull()
      .references(() => checkins.id),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.userId, t.h3R7] })],
);

export const votes = pgTable(
  'votes',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id),
    photoId: uuid('photo_id')
      .notNull()
      .references(() => photos.id),
    value: smallint('value').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.userId, t.photoId] })],
);

export const badges = pgTable(
  'badges',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => users.id),
    badgeKey: badgeKey('badge_key').notNull(),
    awardedAt: timestamp('awarded_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.userId, t.badgeKey] })],
);

export const reports = pgTable('reports', {
  id: uuid('id').primaryKey(),
  reporterId: uuid('reporter_id')
    .notNull()
    .references(() => users.id),
  targetType: text('target_type').notNull(),
  targetId: uuid('target_id').notNull(),
  reason: text('reason').notNull(),
  note: text('note'),
  status: text('status').notNull().default('open'),
  resolvedBy: uuid('resolved_by'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});
