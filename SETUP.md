# Setup

These steps integrate `opencode-ci` into a target repository.

## 1. Copy files into your repo

Drop the runtime files at the root of your project so you end up with `.opencode/`, `.github/` (workflows + scripts), and `docker/` at the root.

The consumer-facing workflows and helper scripts live under `templates/.github/` in this repo so they don't run against `opencode-ci` itself. Copy that subtree into your repo's `.github/`:

```sh
git clone --depth=1 https://github.com/setilanaji/opencode-ci.git /tmp/opencode-ci
cp -R /tmp/opencode-ci/.opencode /tmp/opencode-ci/docker .
cp -R /tmp/opencode-ci/templates/.github .
```

After the copy you should have `.github/workflows/{pr-review,pr-describe,deploy}.yml` and `.github/scripts/{filter-diff,compute-tier}.sh` in your project.

## 2. GitHub Repository Secrets

Settings → Secrets and variables → Actions → **Secrets**:

| Secret | Purpose |
|--------|---------|
| `OPENCODE_API_KEY` | API key for chosen AI provider |
| `AZURE_VM_HOST` | VM IP/hostname (deploy) |
| `AZURE_VM_USER` | SSH user (deploy) |
| `AZURE_SSH_KEY` | SSH private key, PEM format (deploy) |
| `DOCKER_REGISTRY` | e.g. `ghcr.io/yourorg` or your ACR URL (deploy) |
| `DOCKER_USERNAME` | Registry username (deploy) |
| `DOCKER_PASSWORD` | Registry password / token (deploy) |

The `DOCKER_*` and `AZURE_*` secrets are only required if you use `deploy.yml`.

## 3. GitHub Repository Variables

Settings → Secrets and variables → Actions → **Variables**:

| Variable | Values | Purpose |
|----------|--------|---------|
| `OPENCODE_PROVIDER` | `anthropic` / `openai` / `google` | AI provider |
| `OPENCODE_MODEL` | e.g. `claude-sonnet-4-20250514` | Model ID |
| `DEPLOY_TARGET` | `azure-vm` / `docker` | Deploy mode |
| `APP_PORT` | e.g. `8080` | Port your app exposes |
| `OPENCODE_REVIEWER_IMAGE` | _(optional)_ | Override the reviewer image. Defaults to the official `ghcr.io/setilanaji/opencode-ci/reviewer:latest`. |

## 4. Prepare the deployment VM

- Install Docker + Docker Compose plugin
- Open SSH (port 22) and your `APP_PORT`
- Create `~/app` and copy `docker/docker-compose.yml` there
- Add your GitHub Actions runner's SSH public key to `~/.ssh/authorized_keys`

## 5. Adjust the Dockerfile

The provided `docker/Dockerfile` is a Node.js example. Replace stages to match your stack (Java, Python, Go, etc.). Your app must expose `/health` on the configured `APP_PORT` so the deploy step's health check passes.

## 6. Test

1. Open a PR with intentional issues (hardcoded secret, empty catch, N+1 query). The AI review should post within a couple of minutes.
2. Merge to main; watch the deploy workflow build, push, and SSH-deploy.
3. Iterate on `.opencode/rules/*` and `.opencode/skills/*` based on review quality.

## Optional: build your own reviewer image

The default reviewer image lives at `ghcr.io/setilanaji/opencode-ci/reviewer:latest`. If you want to bake in custom rules:

```sh
docker build -t ghcr.io/<you>/opencode-ci-reviewer:latest -f docker/Dockerfile.reviewer .
docker push ghcr.io/<you>/opencode-ci-reviewer:latest
```

Then set `OPENCODE_REVIEWER_IMAGE` to your image path in repository variables.
