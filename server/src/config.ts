import { z } from 'zod';

const configSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(8080),
  DATABASE_URL: z.string().url().optional(),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
  // R2 / S3-compatible storage. Optional until the photo routes are enabled.
  R2_ENDPOINT: z.string().url().optional(),
  R2_BUCKET: z.string().min(1).optional(),
  R2_ACCESS_KEY_ID: z.string().min(1).optional(),
  R2_SECRET_ACCESS_KEY: z.string().min(1).optional(),
  // SPEC §6: 'rekognition' is a named seam only, not a working integration — selecting it
  // returns 501 rather than silently pulling in an undecided AWS SDK dependency.
  MODERATION_PROVIDER: z.enum(['dev', 'rekognition']).default('dev'),
  // SPEC §4: Sign in with Apple/Google. The verification code is real (jose + the
  // provider's public JWKS); these are the app registration's client id / bundle id,
  // which only a human with Apple Developer / Google Cloud console access can create.
  // Unset (the default) ⇒ 501 service/unavailable, same as before this was implemented.
  APPLE_CLIENT_ID: z.string().min(1).optional(),
  GOOGLE_CLIENT_ID: z.string().min(1).optional(),
  // SPEC §20: the postcard web renderer needs its own absolute URL to embed in the
  // shared link and the photo <img> src (unlike PoiPin/Photo's paths, which the MOBILE
  // app resolves against its own API_BASE_URL — a plain browser has no such client to
  // do that). Defaults to local dev; a real deployment sets this to its public origin.
  PUBLIC_BASE_URL: z.string().url().default('http://localhost:8080'),
  // Store links for the postcard page's "Get the app" prompt — both optional; the
  // prompt is omitted entirely rather than shown with a placeholder/broken link when
  // unset (no real store listing exists yet to link to).
  APP_STORE_URL: z.string().url().optional(),
  PLAY_STORE_URL: z.string().url().optional(),
});

export type Config = z.infer<typeof configSchema>;

export function loadConfig(env: Record<string, string | undefined>): Config {
  const parsed = configSchema.safeParse(env);
  if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
    throw new Error(`Invalid configuration: ${issues}`);
  }
  return parsed.data;
}
