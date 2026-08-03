// SPEC §2 — single source of truth. Changing any value is a SPEC change.
export const SPEC_CONSTANTS = {
  geo: {
    H3_RES_COVERAGE: 7,
    H3_RES_DEDUPE: 9,
    DEDUPE_RADIUS_M: 50,
    DEDUPE_PHASH_MAX_HAMMING: 10,
    PIN_ADJUST_MAX_M: 30,
    COVERAGE_HEATMAP_RESOLUTIONS: [2, 3, 5, 7],
  },
  checkinRadiusM: {
    landmark: 75,
    architecture: 75,
    street_art: 50,
    nature: 150,
    viewpoint: 250,
    other: 75,
  },
  presence: {
    ACCURACY_CEILING_M: 150,
    MIN_FIXES: 2,
    MAX_FIXES: 5,
    FIX_SPAN_MIN_S: 8,
    FIX_WINDOW_MAX_S: 25,
    TRACK_CONSISTENCY_FLOOR_M: 150,
    CONF_PASS: 0.9,
    CONF_DEGRADED: 0.6,
    CONF_PENDING: 0.3,
  },
  velocity: {
    MAX_SPEED_KMH: 950,
    TELEPORT_WINDOW_S: 90,
    TELEPORT_DISTANCE_M: 1500,
  },
  nonce: {
    CHECKIN_NONCE_TTL_S: 120,
  },
  evidence: {
    CLOCK_SKEW_S: 30,
    CHECKIN_LIVE_MAX_AGE_S: 150,
    CHECKIN_DEFERRED_MAX_AGE_S: 86_400,
  },
  trust: {
    START: 100,
    MIN: 0,
    MAX: 100,
    D_INTEGRITY_FAIL: -25,
    D_VELOCITY_VIOLATION: -15,
    D_REPORT_UPHELD: -30,
    D_PEOPLE_PHOTO_UPHELD: -10,
    D_CLEAN_30D: 5,
    TRUST_PHOTO_REQUIRED_BELOW: 40,
    TRUST_MANUAL_REVIEW_BELOW: 15,
  },
  photos: {
    UPLOAD_MAX_LONG_EDGE_PX: 2048,
    UPLOAD_MIN_LONG_EDGE_PX: 1024,
    UPLOAD_MAX_BYTES: 1_048_576,
    DERIVED_CARD_PX: 1024,
    DERIVED_THUMB_PX: 256,
    ALLOWED_MIME: ['image/jpeg', 'image/webp'],
    PRESIGN_TTL_S: 600,
  },
  auth: {
    ACCESS_TTL_S: 900,
    REFRESH_TTL_S: 2_592_000,
    EMAIL_CODE_TTL_S: 600,
    EMAIL_CODE_LENGTH: 6,
  },
  rate: {
    AUTH_EMAIL_REQUEST_MAX: 5,
    AUTH_EMAIL_REQUEST_WINDOW_S: 900,
    CHECKIN_INTENT_PER_HOUR: 12,
    POI_CREATE_PER_DAY: 20,
    REPORT_CREATE_PER_DAY: 20,
    POSTCARD_SEND_PER_DAY: 20,
  },
  postcards: {
    MESSAGE_MAX_CODEPOINTS: 280,
  },
  entitlement: {
    FREE_UNLOCKED_CHECKINS: 50,
  },
  leaderboard: {
    LEADERBOARD_ENTRIES_MAX: 100,
  },
  badges: {
    POI_CHECKIN_MILESTONES: [10, 50, 100],
  },
} as const;

export type PoiCategory = keyof typeof SPEC_CONSTANTS.checkinRadiusM;
export const POI_CATEGORIES = Object.keys(SPEC_CONSTANTS.checkinRadiusM) as PoiCategory[];
