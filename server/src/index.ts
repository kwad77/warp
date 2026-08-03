import { buildApp } from './app.js';
import { createAppleVerifier, createGoogleVerifier } from './auth/oidc.js';
import { loadConfig } from './config.js';
import { createDb } from './db/client.js';
import { createModerationProvider } from './moderation/provider.js';
import { devTextModerationProvider } from './moderation/text_provider.js';
import { createR2Storage } from './storage/r2.js';

const config = loadConfig(process.env);
const dbHandle = config.DATABASE_URL ? createDb(config.DATABASE_URL) : null;
const storage = createR2Storage(config);
const moderation = createModerationProvider(config.MODERATION_PROVIDER, (msg) =>
  process.stdout.write(`${msg}\n`),
);
// SPEC §20 — no config knob yet: unlike photo moderation, there's no real text-detector
// seam named to select between (nothing analogous to `rekognition` exists for text yet).
const textModeration = devTextModerationProvider();
const oidcVerifiers = {
  apple: config.APPLE_CLIENT_ID ? createAppleVerifier(config.APPLE_CLIENT_ID) : null,
  google: config.GOOGLE_CLIENT_ID ? createGoogleVerifier(config.GOOGLE_CLIENT_ID) : null,
};
const app = buildApp({ config, dbHandle, storage, moderation, textModeration, oidcVerifiers });

const shutdown = async () => {
  await app.close();
  await dbHandle?.close();
  process.exit(0);
};
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

app.listen({ host: '0.0.0.0', port: config.PORT }).catch((err) => {
  app.log.error(err);
  process.exit(1);
});
