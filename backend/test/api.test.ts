import request from 'supertest';
import { describe, it, beforeAll, afterAll, expect } from 'vitest';
import { app } from '../src/index.js';
import fs from 'fs-extra';
import path from 'path';
import { docsDir, logsDir, artifactsDir } from '../src/utils/paths.js';

const TEST_SCHEDULE_DATE = new Date().toISOString();

describe('API routes', () => {
  beforeAll(async () => {
    await fs.ensureDir(docsDir);
  });

  afterAll(async () => {
    await fs.remove(artifactsDir);
    await fs.remove(logsDir);
    await fs.outputFile(path.join(docsDir, 'PRD.md'), '# Product Requirements Document\n\n_No PRD has been generated yet. Use the voice intake workflow to populate this file._\n');
    await fs.writeJson(path.join(docsDir, 'prd.json'), { id: null, sessionId: null, approved: false, sections: {} }, { spaces: 2 });
  });

  it('schedules an interview and creates a PRD', async () => {
    const interview = await request(app)
      .post('/api/interview/start')
      .send({ clientId: 'client-1', scheduledAt: TEST_SCHEDULE_DATE })
      .expect(201);

    const sessionId = interview.body.id;

    const prd = await request(app)
      .post('/api/voice/prd')
      .send({ sessionId, sections: { Overview: 'Test overview' } })
      .expect(201);

    expect(prd.body.approved).toBe(false);
    expect(prd.body.sections.Overview).toBe('Test overview');

    const approval = await request(app).post(`/api/prds/${prd.body.id}/approve`).send().expect(200);
    expect(approval.body.approved).toBe(true);
  });
});
