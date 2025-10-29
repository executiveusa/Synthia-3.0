import fs from 'fs-extra';
import { v4 as uuid } from 'uuid';
import path from 'path';
import { docsDir, logsDir } from '../utils/paths.js';

export interface InterviewSession {
  id: string;
  clientId: string;
  scheduledAt: string;
  stage: 'Brainstorm' | 'PM/Scope' | 'PRD Draft' | 'Architect' | 'Build' | 'QA';
}

export interface VoiceMessage {
  timestamp: string;
  speaker: 'human' | 'agent';
  content: string;
}

const LOG_DIR = path.join(logsDir, 'voice');

export async function scheduleInterview(clientId: string, scheduledAt: string): Promise<InterviewSession> {
  await fs.ensureDir(LOG_DIR);
  const session: InterviewSession = {
    id: uuid(),
    clientId,
    scheduledAt,
    stage: 'Brainstorm'
  };
  const file = path.join(LOG_DIR, `${session.id}.jsonl`);
  await fs.writeFile(file, JSON.stringify({ session, messages: [] }) + '\n');
  return session;
}

export async function appendVoiceMessage(sessionId: string, message: VoiceMessage) {
  const file = path.join(LOG_DIR, `${sessionId}.jsonl`);
  await fs.appendFile(file, JSON.stringify({ message }) + '\n');
}

export interface PrdData {
  id: string;
  sessionId: string;
  approved: boolean;
  sections: Record<string, string>;
}

const PRD_JSON = path.join(docsDir, 'prd.json');
const PRD_MARKDOWN = path.join(docsDir, 'PRD.md');

export async function createPrdFromInterview(sessionId: string, sections: Record<string, string>) {
  await fs.ensureFile(PRD_JSON);
  const prd: PrdData = {
    id: uuid(),
    sessionId,
    approved: false,
    sections
  };
  await fs.writeJson(PRD_JSON, prd, { spaces: 2 });

  const markdown = Object.entries(sections)
    .map(([key, value]) => `## ${key}\n\n${value}`)
    .join('\n\n');
  await fs.outputFile(PRD_MARKDOWN, `# Product Requirements Document\n\nSession: ${sessionId}\n\n${markdown}\n`);

  return prd;
}

export async function markPrdApproved() {
  if (!(await fs.pathExists(PRD_JSON))) {
    throw new Error('PRD not found');
  }
  const prd = (await fs.readJson(PRD_JSON)) as PrdData;
  prd.approved = true;
  await fs.writeJson(PRD_JSON, prd, { spaces: 2 });
  return prd;
}
