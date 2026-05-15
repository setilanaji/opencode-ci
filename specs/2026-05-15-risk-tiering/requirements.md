# Requirements — Risk Tiering

## Context

Every PR currently gets the same review treatment: full prompt, full rules,
full skill files, default model. A 3-LOC README typo costs the same as a
500-LOC refactor. Meanwhile, a 5-LOC change to authentication code gets the
same depth as a 5-LOC docs tweak — even though the auth change is exactly
where review matters most.

Cloudflare's pipeline tiers reviews into Trivial / Lite / Full based on
diff size, with sensitive paths (`auth/`, `crypto/`) forced to Full
regardless. This shapes both spend and signal: cheap PRs cost ~5x less,
risky PRs get full attention.

For this framework's audience (OSS consumers paying out-of-pocket for API
calls), the **skip-trivial** end of that pattern is the headline. The
sensitive-path force-up is a small addition that prevents the obvious
foot-gun where a "tiny" PR slips through with a real security change.

## Scope

### In
- Compute lines-changed and files-changed in
  `.github/workflows/pr-review.yml` from `pr-diff.txt` and
  `changed-files.txt`.
- **Trivial tier:** PR with ≤10 LOC changed AND ≤2 files changed AND no
  files in the sensitive-path list → skip the AI review entirely; post a
  one-line "skipped (trivial)" comment.
- **Full tier:** any PR touching the sensitive-path list → always reviewed
  with the default model, regardless of size.
- **Standard tier:** everything else → reviewed as today.
- Sensitive-path globs are hardcoded in v1. (Mirror's the diff-filtering
  spec's stance: config knobs come later if multiple consumers ask.)

### Out
- **Per-tier model overrides** (`OPENCODE_MODEL_TRIVIAL`, `OPENCODE_MODEL_FULL`).
  Out for v1 — trivial PRs skip outright, full PRs use the default. Revisit
  when role-split reviewers land.
- **Configurable thresholds.** The ≤10 LOC / ≤2 files numbers are fixed in
  v1. Consumers fork the YAML to change them.
- **A "Lite" tier between trivial and standard.** Cloudflare has one; we
  start with three tiers (skip / standard / sensitive-full) to keep the
  config surface small. Lite is a candidate for "Then (architecture)".
- **Auto-detection of sensitive paths from filenames** (e.g. anything
  matching `*auth*`). The v1 list is path-glob explicit so reviews are
  predictable.

## Decisions

| Decision | Choice | Why |
|---|---|---|
| Tier computation | Inline in `pr-review.yml` | Mirrors diff-filtering's "workflows orchestrate" placement. |
| Trivial threshold | ≤10 LOC AND ≤2 files | Mirrors Cloudflare's "Trivial" tier. |
| Trivial behavior | Skip review entirely | Lowest cost; matches user's answer in the spec questionnaire. |
| Sensitive-path force | Override trivial → full | "Tiny auth change" foot-gun closure. |
| Sensitive list | Hardcoded glob list (v1) | Smallest surface; consumers fork to extend. |
| Verdict on skip | Post a comment, no PR review | A "review" with no body looks broken; a comment reads as intentional. |

## Tier matrix

| Files changed | LOC changed | Sensitive path? | Result |
|---|---|---|---|
| ≤2 | ≤10 | no | **Skip** — post comment |
| ≤2 | ≤10 | yes | **Full** — standard review |
| any | any | yes | **Full** — standard review |
| anything else | | no | **Standard** — standard review |

Standard and Full collapse to the same behavior in v1 (default model, full
rules). They're tracked separately because the **Then (architecture)** phase
will introduce per-tier model overrides where they diverge.

## Sensitive-path glob list (v1)

```
**/auth/**
**/authentication/**
**/security/**
**/crypto/**
**/secrets/**
**/oauth/**
**/saml/**
**/.env*
**/credentials*
**/iam/**
**/Dockerfile
**/docker-compose*.yml
**/.github/workflows/**
**/terraform/**
**/k8s/**
**/migrations/**
**/migrate/**
db/migrate/**
```

Rationale per category:
- **Auth / security / crypto:** primary attack surface.
- **Env / credentials:** secret leakage risk.
- **Infra (Dockerfile, compose, workflows, terraform, k8s):** mistakes here
  affect every subsequent deploy.
- **Migrations:** irreversible-in-prod risk; tiny diffs can have huge blast
  radius.

## Interaction with diff-filtering (Phase 1.1)

Tier computation happens **after** diff filtering. If diff filtering drops
the diff to zero reviewable files, the "skip — no reviewable files"
comment from Phase 1.1 wins; Phase 1.2 doesn't run. If filtering leaves 8
LOC across 1 file and that file is in `src/auth/`, Phase 1.2 routes to
Full tier (sensitive-path override beats trivial).

## Constraints

- Provider-agnostic (`mission.md`).
- Drop-in (no new required vars).
- Works on `ubuntu-latest` runner without extra installs.
- Skip-comment text must clearly state the reason ("trivial" — not "error"
  or "no review") so consumers don't think the bot is broken.

## References

- Branch: `main` (work will be done on a feature branch off main)
- Roadmap entry: `specs/roadmap.md` Phase 1.2
- Cloudflare reference: `blog.cloudflare.com/ai-code-review/` § "Risk
  Tiering System"
- Touched files (planned):
  - `.github/workflows/pr-review.yml` (insert tier-computation step after
    diff-filtering step, gate the OpenCode-run step)
  - `.github/workflows/pr-describe.yml` (PR description always runs;
    tiering is review-only)
- Sibling spec: `specs/2026-05-15-diff-filtering/` (shares the
  "filter / tier / run" pipeline shape)
- Fixtures: `specs/2026-05-15-risk-tiering/fixtures/`
