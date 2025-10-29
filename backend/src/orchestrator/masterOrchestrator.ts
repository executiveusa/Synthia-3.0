import { v4 as uuid } from 'uuid';
import { resolveAgent } from '../agents/registry.js';
import { AgentResult, AgentType } from '../agents/baseAgent.js';
import pino from 'pino';
import { insertRun } from '../db/runsRepository.js';
import fs from 'fs-extra';
import path from 'path';
import { docsDir } from '../utils/paths.js';

export interface OrchestratorOptions {
  clientId: string;
  goal: string;
  templateId?: string;
  niche?: string;
  constraints?: Record<string, unknown>;
}

export interface OrchestratorResult {
  runId: string;
  iterations: number;
  finalScore: number;
  artifacts: string[];
  reflections: string[];
}

const logger = pino({ name: 'orchestrator' });

const AGENT_ORDER: AgentType[] = ['ui', 'ux', 'a11y', 'performance', 'copy', 'test'];

export class MasterOrchestrator {
  async runInfiniteLoop(options: OrchestratorOptions): Promise<OrchestratorResult> {
    const runId = uuid();
    const reflections: string[] = [];
    let iterations = 0;
    let bestScore = 0;
    const artifacts: string[] = [];

    logger.info({ runId, options }, 'Starting orchestrator loop');

    while (bestScore < 9.5 && iterations < 10) {
      iterations += 1;
      logger.info({ runId, iteration: iterations }, 'Starting iteration');

      const results: AgentResult[] = [];

      for (const agentType of AGENT_ORDER) {
        const agent = resolveAgent(agentType);
        const result = await agent.execute({
          clientId: options.clientId,
          runId,
          goal: options.goal,
          memory: { templateId: options.templateId, niche: options.niche, constraints: options.constraints }
        });
        results.push(result);
        reflections.push(`${agentType.toUpperCase()} iteration ${iterations}: ${result.summary}`);
        if (result.artifacts) {
          artifacts.push(...result.artifacts);
        }
        bestScore = Math.max(bestScore, result.score);
      }

      const iterationRecord = {
        id: runId,
        client_id: options.clientId,
        status: bestScore >= 9.5 ? 'completed' : 'running',
        metadata: { iterations, results },
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      await insertRun(iterationRecord);
    }

    const retroPath = path.join(docsDir, 'retro.md');
    await fs.ensureFile(retroPath);
    await fs.appendFile(retroPath, `\n${new Date().toISOString()} - Run ${runId} reflections:\n${reflections.join('\n')}\n`);

    return { runId, iterations, finalScore: bestScore, artifacts, reflections };
  }
}

export const orchestrator = new MasterOrchestrator();
