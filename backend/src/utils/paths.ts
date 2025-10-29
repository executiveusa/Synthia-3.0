import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const repoRoot = path.resolve(__dirname, '..', '..', '..');
export const docsDir = path.join(repoRoot, 'docs');
export const logsDir = path.join(repoRoot, 'logs');
export const artifactsDir = path.join(repoRoot, 'artifacts');
