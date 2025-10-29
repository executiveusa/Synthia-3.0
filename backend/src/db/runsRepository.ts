import { Pool } from 'pg';
import { withClient } from './client.js';

export interface RunRecord {
  id: string;
  client_id: string;
  status: string;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export async function insertRun(run: RunRecord) {
  return withClient(async (pool: Pool) => {
    await pool.query(
      `INSERT INTO runs (id, client_id, status, metadata, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status, metadata = EXCLUDED.metadata, updated_at = EXCLUDED.updated_at`,
      [run.id, run.client_id, run.status, run.metadata, run.created_at, run.updated_at]
    );
  });
}

export async function getRuns(limit = 100) {
  return withClient(async (pool: Pool) => {
    const res = await pool.query('SELECT * FROM runs ORDER BY created_at DESC LIMIT $1', [limit]);
    return res.rows as RunRecord[];
  });
}

export async function getRunById(id: string) {
  return withClient(async (pool: Pool) => {
    const res = await pool.query('SELECT * FROM runs WHERE id = $1', [id]);
    return res.rows[0] as RunRecord | undefined;
  });
}
