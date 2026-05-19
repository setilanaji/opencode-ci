# Plan — Diff Filtering

## 1. Filter implementation
- [ ] Add a "Filter noise from diff" step to `.github/workflows/pr-review.yml`,
      inserted between the existing diff-generation step (line 21–28) and
      the OpenCode run (line 30).
- [ ] The step reads `changed-files.txt`, writes a filtered version to
      `changed-files-reviewable.txt` excluding paths matching the path-glob
      list from `requirements.md`.
- [ ] For each surviving file, regenerate `pr-diff.txt` via
      `git diff "origin/$BASE_REF...HEAD" -- <surviving-files...>`.
      Re-truncate to 100KB.
- [ ] For content-marker filtering, read the first 5 lines of each
      surviving file via `git show "HEAD:<path>"` and drop the file from
      the list if any marker is matched (with the migration-path
      exemption).
- [ ] If the survivor list is empty after both filters: set a step output
      `skip_review=true`. The OpenCode-run step gets an `if:
      steps.filter.outputs.skip_review != 'true'` guard.
- [ ] Add a "Post skip comment" step gated on `skip_review == 'true'` that
      uses `actions/github-script@v7` to post: `"OpenCode Review — skipped
      (no reviewable files after filtering: <count> filtered)."`

## 2. Pr-describe parity
- [ ] Apply the same filter step to `.github/workflows/pr-describe.yml`.
- [ ] If all files are filtered, skip the description generation entirely.
      The PR body is left untouched (no "skipped" comment — descriptions
      are silent when not generated).

## 3. Optional extraction
- [ ] **Only if** the inline YAML logic exceeds ~25 lines: extract to
      `docker/filter-diff.sh` (or `.github/scripts/filter-diff.sh` —
      decide based on whether the script is image-bundled or workflow-only;
      it's workflow-only, so use `.github/scripts/`).
- [ ] The script takes `--changed-files <path>` and `--base-ref <ref>`, prints
      surviving files on stdout, and exits 0 with empty stdout when nothing
      survives.

## 4. Verify provider-agnostic behavior
- [ ] Confirm the filter logic uses only POSIX shell tools (`grep`, `awk`,
      `sed`, `head`, `git`). No `jq`, no `yq`, no extra apt installs.
- [ ] No reference to a specific AI provider's behavior — filtering is pure
      file-system / git work.

## 5. Documentation
- [ ] Add a "Diff filtering" section to `README.md` under "Customization"
      explaining what's filtered by default and how to fork to extend.
- [ ] Add an entry to `CHANGELOG.md` under the next unreleased version.
- [ ] Note in `SETUP.md` (or a new doc) that PRs touching only generated
      files will post a "skipped" comment instead of a review.

## 6. Manual smoke
- [ ] Open a PR on a fork that touches only `package-lock.json` and 5 LOC
      of real code. Confirm the captured prompt (visible in workflow logs)
      contains only the real-code hunks.
- [ ] Open a PR that touches only `package-lock.json`. Confirm a "skipped"
      comment posts and the OpenCode-run step is skipped.
- [ ] Open a PR that touches a Rails migration file with `@generated` in
      its header. Confirm the migration is NOT filtered.

## 7. Merge train
- [ ] PR review and approval from a second maintainer.
- [ ] Merge to `main`. The `build-reviewer.yml` workflow does NOT trigger
      (no `.opencode/` or `docker/` changes), so no image rebuild needed.
- [ ] Update `specs/roadmap.md` — move Phase 1.1 to `## Done` with the
      merge SHA.
