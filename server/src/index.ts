import { buildApp } from './app.js';
import { loadConfig } from './config.js';
import { createDb } from './db/client.js';

const config = loadConfig(process.env);
const dbHandle = config.DATABASE_URL ? createDb(config.DATABASE_URL) : null;
const app = buildApp({ config, dbHandle });

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
