# Synthia 3.0 Backend Architecture

Synthia 3.0 evolves Lemon AI into a multi-agent orchestration platform designed for deterministic design delivery. The backend is implemented as a TypeScript/Node.js service and exposes REST APIs for orchestrating agent runs, capturing product requirements through voice interviews, and automating deployments.

## High-Level Components

- **Master Orchestrator** – Coordinates Lemon AI compatible agents (UI, UX, Accessibility, Performance, Test, and Copy) using the Analyse → Plan → Execute → Validate → Deliver loop until a target quality score is achieved.
- **Agent Containers** – Each agent is isolated via container boundaries. Their persistent memory is stored in Postgres tables keyed by `client_id`.
- **Voice Intake Service** – Handles BMAD voice interviews, persists transcripts to `/logs/voice`, and generates structured PRDs (`docs/prd.json` and `docs/PRD.md`). Human approval is required before the orchestrator continues.
- **API Gateway** – Express server providing `/api` routes secured by OAuth/IAP (pluggable through environment variables). Includes rate limiting, CORS protection, and JSON schema validation.
- **Telemetry & Observability** – OpenTelemetry instrumentation exports spans to Google Cloud Trace when configured. Logs are emitted via Pino and can be forwarded to Cloud Logging.
- **Deployment Interfaces** – Dockerfile for universal builds, docker-compose for offline operation, and GitHub Actions pipeline for CI/CD targeting Google Cloud Run.

## Data Flow Overview

1. **Voice Intake**
   - Admin schedules an interview via `POST /api/interview/start`.
   - Voice agent stores transcripts incrementally at `logs/voice/<session>.jsonl`.
   - The collected Q&A is transformed into JSON and Markdown PRDs.
   - Human approval is recorded with `POST /api/prds/{id}/approve`.

2. **Design Orchestration**
   - After approval, the orchestrator selects templates and spawns agents per creative direction.
   - Each iteration is tracked as a run in Postgres with aggregated scores, reflections, and artifact links.
   - Validation loops call Playwright MCP and Stagehand (stubs ready for integration) to ensure quality gates are satisfied.

3. **Deployment**
   - A completed run can be deployed with `POST /api/deploy/{id}` which triggers container image promotion and returns trace metadata for Cloud Run.

## Storage

- **Postgres** persists clients, runs, and voice sessions.
- **File System** stores voice transcripts, PRDs, retrospectives, and generated components.
- **Docs** catalogue learnings and design inventory for future improvements.

## Security

- OAuth/IAP integration ensures admin actions require authentication tokens.
- Rate limiting and schema validation mitigate abusive access.
- Secrets are loaded exclusively via environment variables.

## Future Work

- Connect to real Lemon AI MCP implementations and container runtimes.
- Complete Google Realtime API integration for live transcription.
- Expand automated auditing with Playwright MCP and Stagehand runners.
