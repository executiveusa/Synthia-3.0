
# Synthia 3.0 – Multi-Agent Design Orchestrator

Synthia 3.0 transforms the original Lemon AI desktop stack into a mono-repo backend that orchestrates containerised design agents, captures BMAD voice interviews, and deploys deliverables to Google Cloud Run. The repository now bundles:

- **Backend (`/backend`)** – TypeScript/Node service powering the agent orchestrator, BMAD voice intake flows, REST APIs, OAuth/IAP hooks, and OpenTelemetry instrumentation.
- **Frontend (`/frontend`)** – Desktop/admin interface with reusable templates for orchestrated builds.
- **Docs (`/docs`)** – Living documentation for PRDs, retrospectives, architecture decisions, and component inventories.

## 🚀 Railway Zero-Secrets Deployment

**NEW**: Deploy Synthia 3.0 to production in minutes with the Railway Zero-Secrets Bootstrapper!

### One-Command Deployment

```bash
# Initialize zero-secrets system
./scripts/setup-zero-secrets.sh

# Deploy to Railway (free tier)
./scripts/railway/deploy.sh
```

**Features:**
- ✅ First deploy guaranteed to work
- ✅ Zero secrets committed to git
- ✅ Cost protection built-in
- ✅ Auto-maintenance mode when limits reached
- ✅ Easy migration to Coolify for cost optimization

**Supports:**
- **Railway**: Quick start with free tier
- **Coolify**: Self-hosted with Hostinger VPN
- **Google Cloud Run**: Enterprise scale
- **Local Docker**: Development and testing

📖 **See [RAILWAY_ZERO_SECRETS.md](./RAILWAY_ZERO_SECRETS.md) for architecture details**  
📖 **See [DEPLOYMENT.md](./DEPLOYMENT.md) for full deployment guide**

## Quick Start

> Prerequisites: Node.js 20+, pnpm, Docker, and (optional) Google Cloud CLI.

```bash
pnpm install
pnpm --filter synthia-backend dev
```

The API server defaults to `http://localhost:8080` with health checks at `/healthz` and REST endpoints under `/api`.

## Offline / Desktop Development

The provided `docker-compose.yml` provisions:

- `backend` – Runs the orchestrator API with hot reload.
- `postgres` – Persists agent memories, voice sessions, and run metadata.
- `ollama` – Serves local language models for air-gapped development.
- `playwright-mcp` – Enables automated accessibility and regression audits.

```bash
docker compose up --build
```

Set the following environment variables (use `.env` or export them before starting services):

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Postgres connection string, default matches the compose file. |
| `MODEL_PROVIDER` | `ollama`, `openrouter`, or `gemini`. Defaults to `openrouter`. |
| `OLLAMA_MODEL` | Model alias loaded by the local Ollama instance. |
| `OTLP_ENDPOINT` | Optional OTLP HTTP collector for tracing. |
| `GOOGLE_PROJECT_ID` | Required for deployment scripts and Cloud Run builds. |

## Google Cloud Deployment

1. Authenticate with Google Cloud and configure the target project:
   ```bash
   gcloud auth login
   gcloud config set project <your-project-id>
   ```
2. Build and push the universal Docker image using the GitHub Actions workflow or manually:
   ```bash
   docker build -f Dockerfile.backend -t gcr.io/<project>/synthia-backend:latest .
   docker push gcr.io/<project>/synthia-backend:latest
   ```
3. Deploy to Cloud Run:
   ```bash
   gcloud run deploy synthia-backend \
     --image gcr.io/<project>/synthia-backend:latest \
     --platform managed \
     --allow-unauthenticated=false \
     --set-env-vars MODEL_PROVIDER=openrouter
   ```

To export an image for Contabo or Coolify, run:

```bash
GOOGLE_PROJECT_ID=<project> REGISTRY=<registry.example.com> ./backend/scripts/export-image.sh synthia-backend latest
```

## Continuous Integration

- `.github/workflows/backend.yml` performs linting, unit tests (including Playwright MCP stubs), Docker image builds, and Cloud Run deployments on `main` merges.
- Secrets should be stored as GitHub Action secrets: `GOOGLE_PROJECT_ID`, `GOOGLE_CLOUD_SERVICE_KEY`, `OTLP_ENDPOINT`, etc.

## API Overview

| Method & Path | Purpose |
|---------------|---------|
| `POST /api/interview/start` | Schedule a BMAD voice interview and create a session. |
| `POST /api/voice/prd` | Convert captured Q&A into structured PRD artefacts. |
| `POST /api/prds/{id}/approve` | Record human approval before orchestration. |
| `POST /api/orchestrator/start` | Trigger Lemon AI agent orchestration and infinite improvement loops. |
| `POST /api/deploy/{id}` | Deploy a completed run to Cloud Run and return trace metadata. |
| `POST /api/ingest/stitch` | Convert Stitch/Figma exports into React-ready components. |
| `GET /api/runs` | List historical orchestrator runs. |
| `GET /api/runs/{id}` | Inspect run status, logs, and artefacts. |

## Security

### Zero-Secrets Architecture

This repository implements a comprehensive zero-secrets deployment architecture:

- **`.agents` file**: Machine-readable inventory of all required and optional secrets
- **`master.secrets.json`**: Local secret storage (never committed to git)
- **Environment Variables**: All secrets injected via platform-specific mechanisms
- **No Hardcoded Secrets**: Code references only environment variables

### Secret Management

- OAuth/IAP integration is configurable via `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`, `JWT_ISSUER`, and `JWT_AUDIENCE` variables.
- Rate limiting, Helmet, and schema validation protect the API surface.
- Keys for Anthropic, Figma, OpenRouter, Gemini, and Google Cloud must be supplied through environment variables or secret stores.
- **Never commit secrets to the repo** - use `master.secrets.json` locally (excluded in `.gitignore`)
- Review `.agents` file for complete secret inventory and integration stubs

### Cost Protection

- Resource limits enforced in `railway.toml`
- Usage monitoring via `./scripts/railway/check-usage.sh`
- Automatic maintenance mode when free tier exceeded
- Migration path to cost-effective platforms (Coolify)

---

# Lemon AI​ is the first Full-stack, Open-source, Agentic AI framework, offering a ​fully local alternative​ to platforms like Manus & Genspark AI. It features an integrated Code Interpreter VM sandbox for safe execution.​​

<div align=center>
  <img src="./public/img/Lemon_logo.png" width="400">
</div>
<p align="center">
  <a href="https://lemon-11.gitbook.io/lemonai">Get to know Lemon AI quickly</a> ·
  <a href="https://lemon-11.gitbook.io/lemonai/development-deployment-guidelines/docker-quick-deployment">Docker Quick Deployment</a> ·
  <a href="https://lemon-11.gitbook.io/lemonai/">Documentation</a> ·
  <a href="https://lemonai.cc/">Download the desktop app for macOS & Windows</a> ·
  <a href="https://deepwiki.com/hexdocom/lemonai">DeepWiki</a> 
</p>

<p align="center">
  <a href="./README.md"><img alt="README in English" src="https://img.shields.io/badge/English-d9d9d9"></a>
  <a href="./README_CN.md"><img alt="简体中文版自述文件" src="https://img.shields.io/badge/简体中文-d9d9d9"></a>
</p>


**Lemon AI​** is the first **​full-stack, open-source, agentic AI framework**, offering a **​fully local alternative​** to platforms like **Manus & Genspark AI. It features an integrated Code Interpreter VM sandbox for safe execution**.​​

**​Lemon AI empowers deep research, web browsing, viable coding, and data analysis – running entirely on your local hardware.​​** It supports ​**planning, action, reflection, and memory​** functionalities using **​local LLMs**​ (like DeepSeek, Qwen, Llama, Gemma) via **Ollama**, ensuring **​complete privacy and zero cloud dependency.**

For enhanced security, Lemon AI operates within a ​**local Virtual Machine (VM) sandbox.** This sandbox **​protects your machine's files and operating system​** by safely handling all code writing, execution, and editing tasks.

Additionally, Lemon AI provides the **​flexibility to configure enhanced results**​ using APIs from leading cloud models like **​Claude, GPT, Gemini, and Grok.**

<a href="https://youtu.be/OmU_4rrZUHE?si=iseqOl5TV2n2kovy">
  <figure>
    <img src="./public/img/githubvideo.png" alt="">
  </figure>
</a>

### function and characteristic
The world's first full-stack open-source AI Agentic framework with comprehensive capabilities
#### Multi: Infinite possibilities
Universal AI Agent capabilities supporting unlimited task scenarios, including:
- Deep search & research reports
- Code generation & data analysis
- Content creation & document processing
Supports experience repository for self-learning and extending enterprise-specific customizations.

**Deployment options:** Open source code, Container, Client application, Online subscription - compatible with cloud/local/all-in-one systems

#### Fast: Rapid Deploy
One-click deployment for immediate usage with minimal technical requirements:
- Simplified installation process for all deployment options
- Quick setup without complex configurations
- Ready-to-use system within minutes

Supporting various deployment environments from personal computers to enterprise servers, with comprehensive documentation for smooth implementation.

#### Good: Powerful & Flexibility
Feature-rich framework with extensive capabilities:
- Virtual machine integration
- Code generation & execution
- Browser operations & web search
- Multi-tool integration

Highly adaptable architecture allows for custom modifications and extensions to fit specific business requirements and integration with existing systems.

#### Economic: Same quality，10x cheaper
Dramatically reduced operational costs:
- Task execution costs 1/10 - 1/100 of other agent products
- Open source subscription model
- Based on open source DeepSeekV3 model

Significant cost savings without compromising on quality or performance, making advanced AI capabilities accessible to organizations of all sizes.

### Lemon AI Editor

**The world’s first General AI Agent Editor---Lemon AI Editor**

#### Why do we need a General AI Agent Editor? 

When you use an Agent to creating a research report, Vibe coding, or generating a data analysis chart, the results often are not perfect. And when you try to fix one part, the rest may get messed up . What we really need is seamless collaboration between humans and AI. Lemon AI Editor empowers you to refine all this results as many times as needed ,until you’re completely satisfied. You can Edit it Over and over and over again. 

#### function and characteristic

Lemon AI Editor lets you continuously edit, modify, and refine your generated HTML pages. What you see is what you get, and you can change anything just by clicking on it.

1.AI Editing Mode：

 - Let AI modify any section content on the page.

 - Let AI insert new paragraphs or content.

- Let AI reformat the entire page.

2.Advanced Edit Mode：Direct editing for quick manual text adjustments.

<a href="https://youtu.be/XaU4Vnt1lTI?si=iQJRSAaiUcqaN45k">
  <figure>
    <img src="./public/img/githubEditor2.png" alt="">
  </figure>
</a>


### Using Lemon AI

* Quickly get Lemon AI running in your environment with this starter guide. Use our [documentation](https://document.lemonai.cc/) for further references and more in-depth instructions.

### System Requirements[​](https://docs.all-hands.dev/modules/usage/installation#system-requirements) <a href="#system-requirements" id="system-requirements"></a>

* MacOS with [Docker Desktop support](https://docs.docker.com/desktop/setup/install/mac-install/#system-requirements)
* Linux
* Windows with [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) and [Docker Desktop support](https://docs.docker.com/desktop/setup/install/windows-install/#system-requirements)

A system with a modern processor and a minimum of **4GB RAM** is recommended to run Lemon AI.

### Prerequisites <a href="#prerequisites" id="prerequisites"></a>

#### MacOS

**Docker Desktop**

1. [Install Docker Desktop on Mac](https://docs.docker.com/desktop/setup/install/mac-install).
2. Open Docker Desktop, go to `Settings > Advanced` and ensure `Allow the default Docker socket to be used` is enabled.

#### Linux

Tested with Ubuntu 22.04.

**Docker Desktop**

1. [Install Docker Desktop on Linux](https://docs.docker.com/desktop/setup/install/linux/).

#### Windows

**WSL**

1. [Install WSL](https://learn.microsoft.com/en-us/windows/wsl/install).
2. Run `wsl --version` in powershell and confirm `Default Version: 2`.

**Docker Desktop**

1. [Install Docker Desktop on Windows](https://docs.docker.com/desktop/setup/install/windows-install).
2. Open Docker Desktop, go to `Settings` and confirm the following:

* General: `Use the WSL 2 based engine` is enabled.
* Resources > WSL Integration: `Enable integration with my default WSL distro` is enabled.

**note**

The docker command below to start the app must be run inside the WSL terminal.

### Start the App <a href="#start-the-app" id="start-the-app"></a>

The easiest way to run Lemon AI is in Docker.

```bash
docker pull hexdolemonai/lemon-runtime-sandbox:latest

docker run -it --rm --pull=always \
  --name lemon-app \
  --env DOCKER_HOST_ADDR=host.docker.internal \
  --env ACTUAL_HOST_WORKSPACE_PATH=${WORKSPACE_BASE:-$PWD/workspace} \
  --publish 5005:5005 \
  --add-host host.docker.internal:host-gateway \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume ~/.cache:/.cache \
  --volume ${WORKSPACE_BASE:-$PWD/workspace}:/workspace \
  --volume ${WORKSPACE_BASE:-$PWD/data}:/app/data \
  --interactive \
  --tty \
  hexdolemonai/lemon:latest make run
```

### Contributing

For those who'd like to contribute code, see our [Contribution Guide](https://github.com/hexdocom/lemon/blob/main/CONTRIBUTING.md). At the same time, please consider supporting Lemon AI by sharing it on social media and at events and conferences.

#### contributors

<a href="https://github.com/hexdocom/lemonai/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=hexdocom/lemonai" />
</a>

### Community & contact

We welcome your contribution to lemon AI to help improve lemon AI. Include: submit code, questions, new ideas, or share interesting and useful AI applications you have created based on lemon AI. We also welcome you to share lemon AI at different events, conferences and social media.

* [GitHub Discussion](https://github.com/hexdocom/lemonai/discussions). Best for: sharing feedback and asking questions.
* [GitHub Issues](https://github.com/hexdocom/Lemon/issues).Best for: bugs you encounter using Lemon.AI, and feature proposals. See our [Contribution Guide](https://github.com/hexdocom/lemon/blob/main/CONTRIBUTING.md).
* [X(Twitter)](https://x.com/LemonAI_cc). Best for: sharing your applications and hanging out with the community.
* [Discord](https://discord.com/invite/gjEXg4UBR4). Best for: sharing your applications and hanging out with the community.
* commercial license（[feedback@lemonai.ai](mailto:feedback@lemonai.ai)）. Business consulting on commercial use licensing lemon AI.

### Star History

[![Star History Chart](https://api.star-history.com/svg?repos=hexdocom/lemonai&type=Date)](https://www.star-history.com/#hexdocom/lemonai&Date)

### Security disclosure

To protect your privacy, please avoid posting security issues on GitHub. Instead, send your questions to [feedback@lemonai.ai](mailto:feedback@lemonai.ai) and we will provide you with a more detailed answer.

### License

This repository is available under the [Lemon AI Open Source License](https://github.com/hexdocom/lemon/blob/main/LICENSE), which is essentially Apache 2.0 with a few additional restrictions.
