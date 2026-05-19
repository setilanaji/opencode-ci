# Mission

## One-line mission

**<TBD: one-line mission — a single declarative sentence that answers "what
does this product do and for whom?". Keep it short enough to fit on a
sticker. Suggested seed: "Drop-in AI PR review and Docker deploy for any
GitHub repo, provider-agnostic."**

## Why we exist

AI-assisted PR review is becoming table-stakes, but the existing options
either lock you into one model vendor, require running your own infra, or
demand a heavy in-repo install. Most small and mid-size repos can't justify
that overhead.

This project packages a working PR-review + deploy pipeline as files you
copy into your repo — `.opencode/`, `.github/workflows/`, and `docker/`.
GitHub Actions runs it; your repo's secrets pick the model provider; the
default rules and skills do the rest. Adoption should be a single PR
against a target repo, not an integration project.

The same prompt rules must produce comparable reviews whether the target
repo points OPENCODE_PROVIDER at Anthropic, OpenAI, or Google. Provider
choice is a cost / latency knob the consumer holds — not an architectural
decision the framework makes for them.

## Who we serve

**Primary user:** OSS consumers adopting the template — developers copying
the workflows into their own repos and configuring GitHub secrets to enable
PR review and deploy.

Everything else — maintainers of this framework, internal-org adopters who
fork heavily — is **secondary**. When a design tradeoff pits drop-in
adoptability against any other persona, the primary user wins.

### What "OSS consumers adopting the template" implies for design

- **Zero-config defaults.** A consumer who copies the three directories and
  sets the documented secrets/variables must get a working pipeline on the
  next PR. No required edits to YAML, Dockerfiles, or rule files.
- **Sane fallbacks over required configuration.** Every variable should have
  a documented default; missing optional config should degrade gracefully,
  not fail the workflow.
- **Provider-agnostic by construction.** No feature, rule, or skill may
  depend on a single provider's quirks (e.g. Anthropic-only XML tags,
  OpenAI-only function-calling). If a feature needs provider-specific
  behavior, it must detect-and-degrade, not require.
- **Public reviewer image.** The default reviewer image is
  `ghcr.io/setilanaji/opencode-ci/reviewer:latest` and must remain pullable
  without authentication. Consumers can override via
  `vars.OPENCODE_REVIEWER_IMAGE` but the default path must work.
- **Documentation as part of the product.** README, SETUP.md, and
  CONTRIBUTING.md are first-class shipped artifacts, not afterthoughts.

## Non-goals

The following are explicitly **not** part of this product's mission:

- **Hosted/SaaS offering.** No control plane, no per-org dashboards, no
  Worker-style live config. Consumers run it in their own GitHub Actions.
- **Custom agent runtimes.** We use `opencode-ai` as-is. We don't fork it,
  we don't ship patches to it; we contribute upstream if needed.
- **Multi-agent orchestration at Cloudflare scale.** A coordinator LLM
  deduplicating across seven sub-reviewers is overkill for this audience.
- **Non-GitHub VCS support.** GitLab, Bitbucket, Gitea, etc. are out of
  scope. Adapting the workflow is a fork problem, not a framework problem.
- **Application-stack opinions.** The example `docker/Dockerfile` is Node;
  consumers are expected to replace it. We don't bundle stack-specific
  Dockerfiles.
- **Telemetry collection.** No phone-home, no usage metrics. Consumers'
  diffs are theirs.

## Success looks like

- A new consumer can copy the three directories, set the documented secrets,
  open a PR, and receive an AI review within ~2 minutes.
- The same rule/skill set produces comparable reviews against Anthropic,
  OpenAI, and Google providers without per-provider branching in workflows.
- Zero hardcoded references to a specific provider's model API beyond the
  documented `OPENCODE_PROVIDER` switch and `KEY_VAR` mapping in
  `pr-review.yml:39-44`.
- The reviewer image at `ghcr.io/setilanaji/opencode-ci/reviewer:latest` is
  pullable anonymously and rebuilt on every change to `.opencode/` or
  `docker/Dockerfile.reviewer`.
- Adding a new stack skill is a one-PR change: drop a markdown file in
  `.opencode/skills/`, add a `grep` branch in `docker/entrypoint.sh`.
