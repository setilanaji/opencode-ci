# Tech Stack

The canonical record of what this framework is built on. When choosing a
library, tool, or pattern for new work, defer to what is already here.

This repo ships **no application code** — it is a template/distribution
package. The "stack" is the runtime that GitHub Actions provides plus the
container image we publish.

## Platform

| Item | Value | Notes |
|---|---|---|
| Distribution model | Files copied into target repo | `.opencode/`, `.github/workflows/`, `docker/` |
| Execution environment | GitHub Actions (`ubuntu-latest`) | All workflows pin `runs-on: ubuntu-latest` |
| Reviewer image base | `node:22-slim` | `docker/Dockerfile.reviewer:1` |
| Reviewer image registry | `ghcr.io/setilanaji/opencode-ci/reviewer` | Public, anonymously pullable |
| Image platforms | `linux/amd64`, `linux/arm64` | `.github/workflows/build-reviewer.yml:52` |

## Build system

| Item | Value | Notes |
|---|---|---|
| Workflow definition | GitHub Actions YAML | `.github/workflows/*.yml` |
| Image build | `docker/build-push-action@v6` with `setup-buildx-action@v3` | Multi-arch via Buildx |
| Image cache | `type=gha,mode=max` | GitHub Actions cache |
| Reviewer runtime install | `npm install -g opencode-ai` | `docker/Dockerfile.reviewer:2` |
| Code style | None enforced today | Shell + YAML + Markdown only |
| Static analysis | None today — planned | Could add `shellcheck`, `actionlint`, markdown linter |

## Components

The repo is small enough that "module structure" is overkill. The four
moving pieces are:

```
.opencode/        — rule + skill markdown and the manifest that loads them
.github/workflows/ — pr-review, pr-describe, build-reviewer, deploy
docker/           — Dockerfile (example app), Dockerfile.reviewer, entrypoint.sh, docker-compose.yml
specs/            — this directory; product specs
```

### Layering rules

- **Workflows orchestrate; the reviewer image executes.** YAML in
  `.github/workflows/` does git diff, env mapping, and posting back to
  GitHub. The container handles prompt assembly and `opencode-ai`
  invocation.
- **No app-build logic in the reviewer image.** `docker/Dockerfile.reviewer`
  must only contain reviewer runtime concerns. App-build belongs in
  `docker/Dockerfile`.
- **Rule files declarative, skill files conditional.** Rules in
  `.opencode/rules/` are always loaded; skills in `.opencode/skills/` load
  only when their file-extension trigger matches.

### Dependency direction

Target repo → copies workflows → workflows pull `ghcr.io/.../reviewer` →
reviewer reads mounted `.opencode/` or falls back to baked defaults →
reviewer shells out to `opencode-ai` → `opencode-ai` calls the configured
provider.

## Core libraries (locked-in)

| Concern | Library / Tool | Version |
|---|---|---|
| AI agent runtime | `opencode-ai` (npm, global) | unpinned in `Dockerfile.reviewer:2` — `<TBD: pin via image rebuild>` |
| Reviewer image base | `node:22-slim` | `Dockerfile.reviewer:1` |
| Example app base | `node:22-alpine` | `docker/Dockerfile:4,11` |
| Workflow runners | `actions/checkout@v4`, `actions/github-script@v7` | `pr-review.yml:17,67` |
| Image build | `docker/setup-buildx-action@v3`, `docker/build-push-action@v6`, `docker/login-action@v3`, `docker/metadata-action@v5` | `build-reviewer.yml:27,38,47` |

## AI providers

Selected at runtime via `vars.OPENCODE_PROVIDER` and `secrets.OPENCODE_API_KEY`.

| Provider | Provider value | Env var the reviewer image expects |
|---|---|---|
| Anthropic | `anthropic` | `ANTHROPIC_API_KEY` |
| OpenAI | `openai` | `OPENAI_API_KEY` |
| Google | `google` | `GOOGLE_GENERATIVE_AI_API_KEY` |

Mapping lives in `pr-review.yml:39-44` and `pr-describe.yml`. New providers
require adding a case to that switch.

## Cross-cutting patterns

- **Prompt assembled in `entrypoint.sh`, not in YAML.** YAML stages the diff
  and changed-files list; the shell script builds the prompt.
- **Heredoc-style section delimiters** (`===== RULES: ... =====`) separate
  prompt sections in `entrypoint.sh`. Phase 1.3 will harden these against
  diff-embedded payloads.
- **JSON-only AI response.** Prompts require a JSON object; the workflow
  strips fences and parses with a fallback that posts raw output if parse
  fails (`pr-review.yml:73-89`).
- **Diff truncated at 100KB** in `pr-review.yml:27` (`head -c 100000`). Hard
  cap; Phase 1.1 will reduce input size by filtering instead of truncating.
- **Image override via `vars.OPENCODE_REVIEWER_IMAGE`** (`pr-review.yml:36`)
  — consumers can pin to a SHA or use a custom-built image.

## Observability

None today. No telemetry, no metrics export, no error aggregation. Each
workflow run is self-contained; failures show up in GitHub Actions logs.

## Security posture

- **Secrets via GitHub Secrets**, never in code: `OPENCODE_API_KEY`,
  `AZURE_VM_HOST`, `AZURE_VM_USER`, `AZURE_SSH_KEY`, `DOCKER_REGISTRY`,
  `DOCKER_USERNAME`, `DOCKER_PASSWORD`.
- **Reviewer image runs as root** in the container today — acceptable since
  the container is ephemeral and has no persistent volumes.
- **App image runs as non-root** (`USER app` in `docker/Dockerfile:18`).
- **No telemetry.** Diffs are not stored or transmitted anywhere beyond the
  chosen AI provider.
- **Prompt-injection attack surface exists** today (raw diff in prompt).
  Phase 1.3 closes it.

## Versioning and release

- **Commit format:** Conventional Commits (e.g. `chore: prepare project for
  OSS release (v0.1.0)`). No enforcement tool configured.
- **Branch model:** Trunk-based on `main`. No long-lived release branches.
- **Image tagging:** every push to `main` rebuilds the reviewer image
  tagged with the commit SHA and `latest`
  (`build-reviewer.yml:42-44`). Image rebuild triggers on changes to
  `.opencode/**`, `docker/Dockerfile.reviewer`, or `docker/entrypoint.sh`.
- **Version bump:** `CHANGELOG.md` updated by hand; no automated release
  tagging today.

## What is intentionally NOT here

- **No application code.** This repo is files-you-copy, not a runnable app.
- **No multi-VCS support.** GitHub Actions only; GitLab/Bitbucket are out
  of scope.
- **No coordinator/sub-reviewer orchestration.** One prompt, one
  `opencode run` invocation, one response. Cloudflare's 7-agent pattern is
  explicitly out of scope.
- **No hosted control plane.** No Worker, no KV, no live config flips.
- **No provider-specific features.** Anthropic prompt caching headers,
  OpenAI structured-output schemas, and Google Gemini-specific knobs are
  not used; the framework treats all three as interchangeable.
- **No linter / formatter on the framework code.** Shell + YAML + Markdown
  are reviewed by hand. Could change if maintenance burden grows.
