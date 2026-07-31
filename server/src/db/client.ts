import { type PostgresJsDatabase, drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema.js';

export type Db = PostgresJsDatabase<typeof schema>;
export type Pg = postgres.Sql;

export interface DbHandle {
  db: Db;
  pg: Pg;
  close(): Promise<void>;
}

export function createDb(databaseUrl: string): DbHandle {
  const pg = postgres(databaseUrl, { max: 10, prepare: true });
  const db = drizzle(pg, { schema });
  return {
    db,
    pg,
    close: () => pg.end({ timeout: 5 }),
  };
}
