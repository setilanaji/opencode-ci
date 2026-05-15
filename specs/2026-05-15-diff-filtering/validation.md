# Validation — Diff Filtering

The bar is **the AI reviewer sees only reviewable code, and PRs with no
reviewable code skip review entirely**.

## 1. Build gate (local workflow lint)
- [ ] `actionlint .github/workflows/*.yml` exits 0 (install if not already
      present).
- [ ] `shellcheck` on any extracted `.github/scripts/*.sh` exits 0.

## 2. Behavior matrix (run as PRs on a fork)

| # | Scenario | Setup | Expected |
|---|---|---|---|
| 2.1 | Real code only | PR with 5 LOC in `src/foo.ts`, no other files | Review runs, prompt contains the foo.ts hunk |
| 2.2 | Lockfile + real code | PR touches `package-lock.json` (200 LOC) and `src/foo.ts` (5 LOC) | Review runs; prompt contains foo.ts; prompt does NOT contain package-lock.json |
| 2.3 | Lockfile only | PR touches only `package-lock.json` | Skip comment posted; OpenCode-run step skipped (visible in workflow log) |
| 2.4 | Minified bundle | PR touches `dist/app.min.js` and `src/foo.ts` | Review runs; prompt excludes dist/app.min.js |
| 2.5 | Source map | PR includes a `*.map` file | The `.map` file is excluded from the prompt |
| 2.6 | `@generated` marker | PR touches `src/generated/types.ts` with `// @generated` on line 1 | File excluded from the prompt |
| 2.7 | Migration exemption | PR touches `db/migrate/202605151200_add_index.rb` containing `# auto-generated` | Migration file is INCLUDED in the prompt (exemption holds) |
| 2.8 | All files filtered | PR touches `package-lock.json` and `dist/app.min.js` only | Skip comment posted; counts in comment match what was filtered |
| 2.9 | Diff > 100KB after filter | PR with large real-code diff (>100KB) | Diff truncated at 100KB after filtering (unchanged behavior) |
| 2.10 | Empty survivor + describe workflow | PR touches only `package-lock.json` | `pr-describe.yml` does not post a description; no error in logs |

## 3. Provider-agnostic gate
- [ ] Switch `vars.OPENCODE_PROVIDER` to `anthropic`, run scenario 2.1.
- [ ] Switch to `openai`, re-run 2.1. Confirm prompt structure identical.
- [ ] Switch to `google`, re-run 2.1. Confirm prompt structure identical.

## 4. Fixtures
Fixtures used to construct the PRs above live in
`specs/2026-05-15-diff-filtering/fixtures/`. They are reference diffs —
not consumed by automation today, but used as the source-of-truth when
constructing the scenario PRs.

## 5. Documentation check
- [ ] `README.md` "Customization" table mentions filter behavior or links
      to the new section.
- [ ] `CHANGELOG.md` lists the change under the next unreleased version
      with provider-agnostic wording.

## Done = mergeable
- All §§ 1–3 boxes checked.
- §§ 2 verified on at least one provider (run the full matrix once,
  cross-provider spot-check via § 3).
- PR review and approval from a second maintainer.
- `roadmap.md` Phase 1.1 moved to `## Done` with merge SHA.
