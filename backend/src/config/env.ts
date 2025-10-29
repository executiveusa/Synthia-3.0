import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  PORT: z.string().transform(Number).default('8080'),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  DATABASE_URL: z.string().url().optional(),
  OTLP_ENDPOINT: z.string().optional(),
  GOOGLE_PROJECT_ID: z.string().optional(),
  MODEL_PROVIDER: z.enum(['ollama', 'openrouter', 'gemini']).default('openrouter'),
  OPENROUTER_MODEL: z.string().default('openrouter/free'),
  OLLAMA_MODEL: z.string().default('llama3'),
  GEMINI_MODEL: z.string().default('gemini-2.0-flash'),
  JWT_AUDIENCE: z.string().optional(),
  JWT_ISSUER: z.string().optional(),
  OAUTH_CLIENT_ID: z.string().optional(),
  OAUTH_CLIENT_SECRET: z.string().optional()
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment configuration', parsed.error.format());
  throw new Error('Invalid environment configuration');
}

export const env = parsed.data;
