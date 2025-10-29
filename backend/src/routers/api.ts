import { Router } from 'express';
import { body, param, validationResult } from 'express-validator';
import { scheduleInterview, createPrdFromInterview, markPrdApproved } from '../services/voiceIntake.js';
import { orchestrator } from '../orchestrator/masterOrchestrator.js';
import { getRuns, getRunById } from '../db/runsRepository.js';
import fs from 'fs-extra';
import path from 'path';
import { artifactsDir } from '../utils/paths.js';

const router = Router();

router.post(
  '/interview/start',
  body('clientId').isString(),
  body('scheduledAt').isISO8601(),
  async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    try {
      const session = await scheduleInterview(req.body.clientId, req.body.scheduledAt);
      res.status(201).json(session);
    } catch (error) {
      next(error);
    }
  }
);

router.post(
  '/prds/:id/approve',
  param('id').isString(),
  async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    try {
      const prd = await markPrdApproved();
      res.json(prd);
    } catch (error) {
      next(error);
    }
  }
);

router.post(
  '/deploy/:id',
  param('id').isString(),
  async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    try {
      const runId = req.params?.id;
      if (!runId) {
        return res.status(400).json({ message: 'Run ID is required' });
      }
      const run = await getRunById(runId);
      if (!run) {
        return res.status(404).json({ message: 'Run not found' });
      }
      if (run.status !== 'completed') {
        return res.status(400).json({ message: 'Run must be completed before deployment' });
      }
      const traceId = `${run.id}-${Date.now()}`;
      res.json({ deployment: 'pending', cloudRunUrl: `https://cloud.run/${run.id}`, traceId });
    } catch (error) {
      next(error);
    }
  }
);

router.post(
  '/ingest/stitch',
  body('html').isString(),
  async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    try {
      const { html, metadata } = req.body;
      const artifactDir = path.join(artifactsDir, 'stitch');
      await fs.ensureDir(artifactDir);
      const file = path.join(artifactDir, `${Date.now()}.html`);
      await fs.writeFile(file, html);
      res.status(201).json({ file, metadata });
    } catch (error) {
      next(error);
    }
  }
);

router.get('/runs', async (_req, res, next) => {
  try {
    const runs = await getRuns();
    res.json(runs);
  } catch (error) {
    next(error);
  }
});

router.get('/runs/:id', async (req, res, next) => {
  try {
    const runId = req.params?.id;
    if (!runId) {
      return res.status(400).json({ message: 'Run ID is required' });
    }
    const run = await getRunById(runId);
    if (!run) {
      return res.status(404).json({ message: 'Run not found' });
    }
    res.json(run);
  } catch (error) {
    next(error);
  }
});

router.post(
  '/orchestrator/start',
  body('clientId').isString(),
  body('goal').isString(),
  async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    try {
      const result = await orchestrator.runInfiniteLoop({
        clientId: req.body.clientId,
        goal: req.body.goal,
        templateId: req.body.templateId,
        niche: req.body.niche,
        constraints: req.body.constraints
      });
      res.status(202).json(result);
    } catch (error) {
      next(error);
    }
  }
);

router.post(
  '/voice/prd',
  body('sessionId').isString(),
  body('sections').isObject(),
  async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    try {
      const prd = await createPrdFromInterview(req.body.sessionId, req.body.sections);
      res.status(201).json(prd);
    } catch (error) {
      next(error);
    }
  }
);

export default router;
