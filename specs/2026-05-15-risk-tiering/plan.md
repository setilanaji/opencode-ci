# Plan — Risk Tiering

Depends on Phase 1.1 (diff-filtering) landing first — tiering computes on
the filtered file list, not the raw one. If Phase 1.1 is not yet merged,
this plan still applies but tier computation should consume
`changed-files.txt` directly until the filtered list exists.

## 1. Tier computation
- [ ] Add a "Compute review tier" step to `.github/workflows/pr-review.yml`,
      inserted after Phase 1.1's filter step and before the OpenCode-run
      step.
- [ ] Read the post-filter file list (`changed-files-reviewable.txt` from
      Phase 1.1, or `changed-files.txt` if filtering hasn't landed).
- [ ] Compute:
  - `FILES_CHANGED` = line count of the file list.
  - `LOC_CHANGED` = sum of `+`/`-` line counts in `pr-diff.txt` (excluding
    diff headers — `awk` on lines starting with `+`/`-` but not `+++`/`---`).
  - `SENSITIVE_HIT` = boolean — true if any file in the list matches any
    glob in the hardcoded sensitive-path list.
- [ ] Determine tier:
  - `SENSITIVE_HIT == true` → `tier=full`
  - Else `FILES_CHANGED <= 2 AND LOC_CHANGED <= 10` → `tier=trivial`
  - Else → `tier=standard`
- [ ] Set step outputs `tier=$tier`, `loc_changed=$LOC_CHANGED`,
      `files_changed=$FILES_CHANGED`.

## 2. Gate the review step
- [ ] Add `if: steps.tier.outputs.tier != 'trivial'` to the OpenCode-run
      step.
- [ ] Add a "Post trivial-skip comment" step gated on
      `steps.tier.outputs.tier == 'trivial'` that posts:
      `"OpenCode Review — skipped (trivial: <N> file(s), <M> LOC). PRs ≤10
      LOC across ≤2 files skip AI review by default."`

## 3. Sensitive-path glob list
- [ ] Encode the sensitive-path glob list from `requirements.md` directly
      in the workflow step (a shell variable + grep loop, or a small
      `case` statement).
- [ ] If the list-matching logic exceeds ~15 lines inline, extract to
      `.github/scripts/compute-tier.sh` and call from the workflow.

## 4. Verify standard tier is unchanged
- [ ] Confirm that PRs hitting the standard tier produce identical prompts
      to today (no behavior change for the common case).

## 5. Documentation
- [ ] Add a "Risk tiering" section to `README.md` listing the tier rules and
      the sensitive-path globs.
- [ ] `SETUP.md`: document the new "trivial PR may skip review" behavior so
      consumers don't file confused issues.
- [ ] `CHANGELOG.md`: entry under next unreleased version.

## 6. Manual smoke
- [ ] PR with 3 LOC changed in `README.md` → expect trivial-skip comment.
- [ ] PR with 3 LOC changed in `src/auth/login.ts` → expect a full review
      (sensitive-path override).
- [ ] PR with 50 LOC across 3 files in `src/` → expect a standard review
      (unchanged behavior).
- [ ] PR with 8 LOC in `package.json` and 2 LOC in `README.md` → expect a
      trivial-skip comment (within thresholds, no sensitive path).
- [ ] PR that touches both a sensitive path AND a non-sensitive path,
      total 4 LOC → expect a full review.

## 7. Merge train
- [ ] PR review and approval from a second maintainer.
- [ ] Merge to `main`. The `build-reviewer.yml` workflow does NOT trigger.
- [ ] Update `specs/roadmap.md` — move Phase 1.2 to `## Done`.
