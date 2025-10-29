import { Pool } from 'pg';
import { env } from '../config/env.js';
import pino from 'pino';

const logger = pino({ name: 'db', level: env.NODE_ENV === 'development' ? 'debug' : 'info' });

let pool: Pool | undefined;

export function getPool() {
  if (pool) return pool;
  if (!env.DATABASE_URL) {
    logger.warn('DATABASE_URL not provided – using no-op pool');
    pool = new Pool({ connectionString: 'postgres://postgres:postgres@localhost:5432/synthia', max: 1 });
    return pool;
  }
  pool = new Pool({ connectionString: env.DATABASE_URL, max: 10 });
  pool.on('error', (err) => {
    logger.error({ err }, 'Unexpected error on idle client');
  });
  return pool;
}

export async function withClient<T>(fn: (client: Pool) => Promise<T>) {
  const client = getPool();
  return fn(client);
}
