# Contributing to opencode-ci

Thanks for your interest in contributing! This project is a CI/CD template, so changes typically fall into one of three categories:

1. **New review rule or skill** — markdown file under `.opencode/rules/` or `.opencode/skills/`.
2. **Workflow improvement** — changes to a file under `.github/workflows/`.
3. **Docker / deployment change** — changes under `docker/`.

## Ground rules

- Keep PRs focused. One concern per PR.
- Match existing tone and length in rule/skill markdown files — terse, imperative, examples over explanations.
- Don't add features for hypothetical use cases. If a rule isn't widely applicable, make it a skill.
- Update [`SETUP.md`](SETUP.md) and [`README.md`](README.md) when adding a new required secret, variable, or skill.

## Adding a new stack skill

1. Create `.opencode/skills/<stack>.md` following the structure of [`general.md`](.opencode/skills/general.md).
2. Add a detection branch in `docker/entrypoint.sh`:
   ```sh
   if grep -qE '\.<ext>$' "$FILES_FILE"; then
     echo "===== SKILL: <stack> ====="
     cat "$RULES_DIR/skills/<stack>.md"; echo
   fi
   ```
3. Update the table in `README.md` and the file-extension list in `CLAUDE.md`.

## Adding a new always-on rule

1. Create `.opencode/rules/<topic>.md`.
2. Add it to the `instructions` array in `.opencode/config.json`.
3. Append a `===== RULES: <topic> =====` block to `docker/entrypoint.sh` in the review-mode section.

## Testing your changes locally

You can dry-run the reviewer image against any diff:

```sh
# Build the reviewer image
docker build -t opencode-reviewer:dev -f docker/Dockerfile.reviewer .

# Generate a sample diff
git diff main...HEAD > /tmp/pr-diff.txt
git diff --name-only main...HEAD > /tmp/changed-files.txt

# Run the reviewer (Anthropic example)
docker run --rm \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  -e OPENCODE_MODEL="claude-sonnet-4-20250514" \
  -v /tmp/pr-diff.txt:/workspace/pr-diff.txt:ro \
  -v /tmp/changed-files.txt:/workspace/changed-files.txt:ro \
  opencode-reviewer:dev
```

The output should be a single JSON object — if it isn't, the prompt is leaking prose.

## Pull request process

1. Fork and create a feature branch.
2. Make your change, keeping commits small and self-explanatory.
3. Open a PR using the template — describe what changed and why.
4. The repo's own PR review and description workflows will run on your PR.

## Reporting issues

Use the GitHub issue tracker. The templates under `.github/ISSUE_TEMPLATE/` cover bugs, feature requests, and new-skill proposals.
