// Minimal forward-only migration runner: applies migrations/*.sql in filename order,
// tracked in schema_migrations. Never edit an applied migration (CLAUDE.md).
import { readFile, readdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import postgres from 'postgres';

const MIGRATIONS_DIR = fileURLToPath(new URL('../../migrations/', import.meta.url));

export async function migrate(databaseUrl: string, log: (msg: string) => void): Promise<void> {
  const pg = postgres(databaseUrl, { max: 1, onnotice: () => {} });
  try {
    await pg`CREATE TABLE IF NOT EXISTS schema_migrations (
      name TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now())`;
    const applied = new Set(
      (await pg`SELECT name FROM schema_migrations`).map((r) => r.name as string),
    );
    const files = (await readdir(MIGRATIONS_DIR)).filter((f) => f.endsWith('.sql')).sort();
    for (const file of files) {
      if (applied.has(file)) continue;
      const sqlText = await readFile(`${MIGRATIONS_DIR}${file}`, 'utf8');
      await pg.begin(async (tx) => {
        await tx.unsafe(sqlText);
        await tx`INSERT INTO schema_migrations (name) VALUES (${file})`;
      });
      log(`applied ${file}`);
    }
    log(`up to date (${files.length} migrations)`);
  } finally {
    await pg.end({ timeout: 5 });
  }
}

const isMain = process.argv[1] && import.meta.url === new URL(`file://${process.argv[1]}`).href;
if (isMain) {
  const url = process.env.DATABASE_URL;
  if (!url) {
    process.stderr.write('DATABASE_URL is required\n');
    process.exit(1);
  }
  migrate(url, (m) => process.stdout.write(`${m}\n`)).catch((err) => {
    process.stderr.write(`migration failed: ${err}\n`);
    process.exit(1);
  });
}
