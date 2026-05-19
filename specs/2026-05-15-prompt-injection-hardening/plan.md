# Plan — Prompt-Injection Hardening

This phase changes `docker/entrypoint.sh`, so it triggers a reviewer image
rebuild via `build-reviewer.yml`. Plan accordingly — the rebuild must
complete before consumers see the new behavior.

## 1. Sanitizer function in entrypoint.sh
- [ ] Add a `sanitize_untrusted` shell function near the top of
      `docker/entrypoint.sh`. It reads stdin, applies the filters from
      `requirements.md`, writes to stdout. Replacement sentinel:
      `[redacted: matched injection-filter pattern]`.
- [ ] Apply to the diff: `sanitize_untrusted < "$DIFF_FILE" >
      /tmp/diff-sanitized.txt`. Use `/tmp/diff-sanitized.txt` in the
      heredoc instead of `$DIFF_FILE`.
- [ ] For describe mode (`MODE=describe`), apply the same sanitizer to PR
      title, body, and commit messages before concatenation. The PR
      title/body/commits will need new env vars passed in from the
      workflow (`PR_TITLE`, `PR_BODY`, both already passed or to be
      added — verify against current `pr-describe.yml`).

## 2. Pattern list
- [ ] Encode the strip patterns directly in `entrypoint.sh` as two arrays
      / case branches:
  - **Line-match regexes** (drop the line entirely): the forged-boundary
    regex.
  - **Substring matches** (drop the line if it contains): `<system>`,
    `</system>`, `<|im_start|>`, `<|im_end|>`, `<|start|>`, `<|end|>`,
    `[INST]`, `[/INST]`, `### NEW INSTRUCTIONS`,
    `### INSTRUCTION OVERRIDE`, `### END USER INSTRUCTIONS`.
  - **Case-insensitive substring matches**: `ignore previous instructions`,
    `ignore all previous instructions`, `disregard the above`,
    `disregard above`, `you are now`, `act as if`.
- [ ] Each stripped line is replaced (not deleted) with the sentinel so
      line counts roughly preserve and the AI sees the redaction.

## 3. Workflow wiring for describe mode
- [ ] Inspect `.github/workflows/pr-describe.yml` — confirm whether
      `PR_TITLE` and `PR_BODY` are already passed to the container as env
      vars. If not, add them via `-e PR_TITLE=...` on the `docker run`.
- [ ] Sanitize at the entry point in the container, not at the workflow.
      The workflow's job is to pass raw input; sanitization is a single
      responsibility of `entrypoint.sh`.

## 4. SECURITY.md update
- [ ] Add a new "Prompt injection threat model" section to `SECURITY.md`.
- [ ] Restate the threat model table from `requirements.md`.
- [ ] State the residual risk: novel jailbreak phrasings, non-line-based
      attacks, multi-language attacks. The filter is best-effort, not
      provably complete.
- [ ] Document the sentinel string consumers will see in reviews when a
      strip happens.

## 5. Image rebuild and verification
- [ ] Verify `.github/workflows/build-reviewer.yml` rebuilds the image on
      `docker/entrypoint.sh` changes (currently triggered on `docker/entrypoint.sh`,
      per `build-reviewer.yml:8` — no change needed).
- [ ] After merge, watch the rebuild complete and the `latest` tag move.

## 6. Documentation
- [ ] `README.md`: brief mention under "Security" linking to the new
      `SECURITY.md` section.
- [ ] `CHANGELOG.md`: entry under the next unreleased version, noting the
      reviewer image rebuild requirement.

## 7. Manual smoke
- [ ] Apply `fixtures/injection-section-boundary.diff` as a PR. Confirm
      the captured prompt (visible in workflow logs) shows the sentinel
      line where the forged boundary was, NOT the original text.
- [ ] Apply `fixtures/injection-system-tag.diff`. Same.
- [ ] Apply `fixtures/injection-jailbreak-prose.diff`. Same.
- [ ] Apply `fixtures/legitimate-jsx-fixture.diff` — a diff containing a
      real `<system>` JSX-style tag in code. Confirm the strip happens;
      open a follow-up issue noting the false-positive case if it bites
      real consumers (acceptable for v1 per `requirements.md`).
- [ ] Apply `fixtures/clean.diff` (no payloads). Confirm no false strips.

## 8. Merge train
- [ ] PR review and approval from a second maintainer.
- [ ] Merge to `main`. Image rebuilds via `build-reviewer.yml`.
- [ ] After rebuild lands, run smoke tests against the new `latest` image
      on a fork.
- [ ] Update `specs/roadmap.md` — move Phase 1.3 to `## Done`.
