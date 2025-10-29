import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import bodyParser from 'body-parser';
import morgan from 'morgan';
import pino from 'pino';
import { Server } from 'http';
import apiRouter from './routers/api.js';
import { initTracing } from './telemetry/tracing.js';
import { env } from './config/env.js';

const logger = pino({ name: 'server', level: env.NODE_ENV === 'development' ? 'debug' : 'info' });

initTracing();

export const app = express();

app.use(helmet());
app.use(cors({ origin: false }));
app.use(bodyParser.json({ limit: '10mb' }));
app.use(morgan('combined'));
app.use(
  rateLimit({
    windowMs: 60 * 1000,
    max: 60,
    standardHeaders: true,
    legacyHeaders: false
  })
);

app.get('/healthz', (_req, res) => {
  res.json({ status: 'ok', mode: env.MODEL_PROVIDER });
});

app.use('/api', apiRouter);

app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error({ err }, 'Unhandled error');
  res.status(500).json({ message: err.message });
});

let server: Server | undefined;

export function startServer(port = env.PORT) {
  if (server) {
    return server;
  }
  server = app.listen(port, () => {
    logger.info({ port }, 'Backend server ready');
  });
  return server;
}

if (env.NODE_ENV !== 'test') {
  startServer();
}

process.on('SIGTERM', () => {
  if (!server) return;
  server.close(() => {
    logger.info('HTTP server closed');
  });
});

export default app;
