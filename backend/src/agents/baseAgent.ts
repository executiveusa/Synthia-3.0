import pino from 'pino';

export type AgentType = 'ui' | 'ux' | 'a11y' | 'performance' | 'test' | 'copy';

export interface AgentContext {
  clientId: string;
  runId: string;
  goal: string;
  memory: Record<string, unknown>;
}

export interface AgentResult {
  summary: string;
  score: number;
  artifacts?: string[];
  metadata?: Record<string, unknown>;
}

export abstract class BaseAgent {
  protected logger: pino.Logger;

  constructor(public readonly type: AgentType) {
    this.logger = pino({ name: `agent-${type}` });
  }

  abstract execute(context: AgentContext): Promise<AgentResult>;
}
