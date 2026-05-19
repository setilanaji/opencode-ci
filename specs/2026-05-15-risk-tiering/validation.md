# Validation — Risk Tiering

The bar is **trivial PRs skip review, sensitive-path PRs are always
reviewed, and the standard case is unchanged**.

## 1. Build gate (local workflow lint)
- [ ] `actionlint .github/workflows/*.yml` exits 0.
- [ ] `shellcheck` on any extracted `.github/scripts/compute-tier.sh`
      exits 0.

## 2. Behavior matrix (run as PRs on a fork)

| # | Scenario | Files / LOC | Expected tier | Expected effect |
|---|---|---|---|---|
| 2.1 | Tiny README typo | 1 file / 1 LOC `README.md` | trivial | Skip comment posts; OpenCode step skipped |
| 2.2 | Threshold edge — 10 LOC | 1 file / 10 LOC `src/foo.ts` | trivial | Skip comment posts |
| 2.3 | Threshold edge — 11 LOC | 1 file / 11 LOC `src/foo.ts` | standard | Full review runs |
| 2.4 | Threshold edge — 3 files | 3 files / 5 LOC total | standard | Full review runs |
| 2.5 | Tiny sensitive change | 1 file / 2 LOC `src/auth/login.ts` | full | Full review runs (NOT skipped) |
| 2.6 | Sensitive + non-sensitive | 2 files / 4 LOC (`src/auth/x.ts` + `README.md`) | full | Full review runs |
| 2.7 | Standard size | 3 files / 50 LOC `src/` | standard | Full review runs (unchanged behavior) |
| 2.8 | Migration file | 1 file / 5 LOC `db/migrate/20260515_xx.rb` | full | Full review runs (migrations are sensitive) |
| 2.9 | Workflow change | 1 file / 3 LOC `.github/workflows/foo.yml` | full | Full review runs |
| 2.10 | Dockerfile change | 1 file / 4 LOC `Dockerfile` | full | Full review runs |
| 2.11 | All files filtered (interaction with Phase 1.1) | 1 file / 200 LOC `package-lock.json` | n/a — Phase 1.1 wins | Phase 1.1 skip comment posts; tier step doesn't run |

## 3. Provider-agnostic gate
- [ ] Re-run scenario 2.5 (sensitive tiny change) with each of
      `anthropic`, `openai`, `google`. Confirm the full review runs on all
      three and the prompt is identical structurally.

## 4. Skip-comment clarity
- [ ] Skip comment in 2.1 reads as intentional (not "error" / not "no
      review available"). The word "trivial" appears. The thresholds
      appear (so the PR author understands the rule).

## 5. Documentation check
- [ ] `README.md` has a "Risk tiering" section showing the tier matrix and
      the sensitive-path globs.
- [ ] `SETUP.md` includes a note for adopters that trivial PRs may skip
      review by default.
- [ ] `CHANGELOG.md` mentions the change with provider-agnostic wording.

## 6. Fixtures
Fixtures used to construct the PRs above live in
`specs/2026-05-15-risk-tiering/fixtures/`.

## Done = mergeable
- All §§ 1–4 boxes checked.
- §§ 2 verified on at least one provider; § 3 spot-checks the other two.
- PR review and approval from a second maintainer.
- `roadmap.md` Phase 1.2 moved to `## Done` with merge SHA.
