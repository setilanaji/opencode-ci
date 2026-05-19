# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Diff filtering before review/describe: lockfiles, minified bundles, source
  maps, and `@generated`-marked files are stripped from the prompt by
  `.github/scripts/filter-diff.sh`. Database migrations are exempt from
  the `@generated`-marker rule. PRs with only filtered files post a
  one-line "skipped" comment instead of a full review. Provider-agnostic;
  works on any of `anthropic`, `openai`, `google`. (Phase 1.1; see
  `specs/2026-05-15-diff-filtering/`.)

## [0.1.0] - 2026-04-28

### Added
- AI-powered PR review workflow (`pr-review.yml`)
- AI-generated PR description workflow (`pr-describe.yml`)
- Build/push/SSH-deploy workflow (`deploy.yml`)
- Reviewer Docker image with bundled rules and skills
- Default rule files: `code-review.md`, `security.md`, `performance.md`
- Default skill files: `general.md`, `android-kotlin.md`, `ios-swift.md`, `flutter.md`, `pr-description.md`
- Node.js example `Dockerfile` and `docker-compose.yml`
- Setup documentation
