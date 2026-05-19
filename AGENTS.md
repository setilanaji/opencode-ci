# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## What This Repo Is

A drop-in CI/CD framework that adds AI-powered PR review and Docker-based deployment to any repository. Users copy `.opencode/`, `.github/workflows/`, and `docker/` into their own repo and configure GitHub secrets/variables.

There is no application to build or test here — this repo is a template/distribution package.

## Integration into a Target Repo

### Required GitHub Secrets
- `OPENCODE_API_KEY` — API key for the chosen AI provider
- `AZURE_VM_HOST`, `AZURE_VM_USER`, `AZURE_SSH_KEY` — SSH access to deployment VM
- `DOCKER_REGISTRY`, `DOCKER_USERNAME`, `DOCKER_PASSWORD` — Container registry credentials

### Required GitHub Variables
- `OPENCODE_PROVIDER` — `anthropic` | `openai` | `google`
- `OPENCODE_MODEL` — e.g. `Codex-sonnet-4-20250514`
- `DEPLOY_TARGET` — `azure-vm` | `docker`
- `APP_PORT` — e.g. `8080`

## Architecture

### PR Review Pipeline (`.github/workflows/pr-review.yml`)

1. Triggered on PR open/synchronize
2. Detects changed files and selects stack-aware skill files (`.kt`/`.gradle` → `android-kotlin.md`, `.swift` → `ios-swift.md`, `.dart` → `flutter.md`; `general.md` always included)
3. Builds a prompt combining all applicable rules + skill files + PR diff (truncated to 100KB)
4. Runs `opencode -p "$PROMPT" --no-input` via `npm install -g opencode-ai`
5. Parses JSON response and posts as a GitHub PR review (verdict + issue table)

### Deploy Pipeline (`.github/workflows/deploy.yml`)

1. Triggered on push to `main`/`master`
2. Multi-stage Docker build (`docker/Dockerfile`) → push tagged image to registry
3. SSH into Azure VM or Docker host → `docker compose up -d`
4. Health check: `curl http://localhost:$APP_PORT/health`

### AI Review Rules & Skills

- **`.opencode/config.json`** — lists which rule files the AI loads
- **`.opencode/rules/`** — always-on rules: `code-review.md` (style, structure, error handling), `security.md` (OWASP checks, hardcoded secrets), `performance.md` (memory leaks, N+1, missing pagination)
- **`.opencode/skills/`** — stack-specific guidance loaded conditionally based on file extensions in the PR

## Customization Points

- Add new rules to `.opencode/rules/` and reference them in `.opencode/config.json`
- Add new stack skills to `.opencode/skills/` and add detection logic in `pr-review.yml`
- Adapt `docker/Dockerfile` to the target stack (the provided example is Node.js); the app must expose `/health` on `APP_PORT`
- Adjust `docker/docker-compose.yml` for production service configuration
