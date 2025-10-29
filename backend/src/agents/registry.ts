import { BaseAgent, AgentContext, AgentResult, AgentType } from './baseAgent.js';

class DefaultAgent extends BaseAgent {
  async execute(context: AgentContext): Promise<AgentResult> {
    this.logger.info({ context }, `Executing ${this.type} agent iteration`);
    return {
      summary: `${this.type} agent generated placeholder output for ${context.goal}`,
      score: 8.0,
      metadata: { notes: 'Replace with real Lemon AI agent invocation' }
    };
  }
}

const agentCache = new Map<AgentType, BaseAgent>();

export function resolveAgent(type: AgentType): BaseAgent {
  if (!agentCache.has(type)) {
    agentCache.set(type, new DefaultAgent(type));
  }
  return agentCache.get(type)!;
}
