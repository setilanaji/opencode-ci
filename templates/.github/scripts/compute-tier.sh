#!/usr/bin/env bash
# Compute the risk tier for a PR.
#
# Inputs:
#   $1 = path to a file containing the list of changed files (one per line)
#   $2 = path to the diff file (used for LOC counting)
#
# Outputs (to stdout, as GITHUB_OUTPUT-style key=value lines):
#   tier=<trivial|standard|full>
#   loc_changed=<N>
#   files_changed=<N>
#   sensitive_hit=<true|false>
#
# Tier rules (specs/2026-05-15-risk-tiering/requirements.md):
#   - sensitive_hit == true            -> full
#   - files <= 2 AND loc <= 10         -> trivial
#   - otherwise                        -> standard

set -euo pipefail

CHANGED_FILES="${1:?usage: compute-tier.sh <changed-files> <diff-file>}"
DIFF_FILE="${2:?usage: compute-tier.sh <changed-files> <diff-file>}"

SENSITIVE_GLOBS=(
  '*/auth/*' 'auth/*'
  '*/authentication/*' 'authentication/*'
  '*/security/*' 'security/*'
  '*/crypto/*' 'crypto/*'
  '*/secrets/*' 'secrets/*'
  '*/oauth/*' 'oauth/*'
  '*/saml/*' 'saml/*'
  '*/.env*' '.env*'
  '*/credentials*' 'credentials*'
  '*/iam/*' 'iam/*'
  '*/Dockerfile' 'Dockerfile' '*.Dockerfile'
  '*/docker-compose*.yml' 'docker-compose*.yml'
  '*/docker-compose*.yaml' 'docker-compose*.yaml'
  '*/.github/workflows/*' '.github/workflows/*'
  '*/terraform/*' 'terraform/*'
  '*/k8s/*' 'k8s/*'
  '*/migrations/*' 'migrations/*'
  '*/migrate/*' 'migrate/*'
  'db/migrate/*'
)

matches_any_glob() {
  local path="$1"
  shift
  local pattern
  for pattern in "$@"; do
    # shellcheck disable=SC2053
    if [[ "$path" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

FILES_CHANGED=$(grep -c '' "$CHANGED_FILES" 2>/dev/null || true)
FILES_CHANGED=${FILES_CHANGED:-0}

LOC_CHANGED=$(grep -cE '^[+-]([^+-]|$)' "$DIFF_FILE" 2>/dev/null || true)
LOC_CHANGED=${LOC_CHANGED:-0}

SENSITIVE_HIT=false
while IFS= read -r file; do
  [ -z "$file" ] && continue
  if matches_any_glob "$file" "${SENSITIVE_GLOBS[@]}"; then
    SENSITIVE_HIT=true
    break
  fi
done < "$CHANGED_FILES"

if [ "$SENSITIVE_HIT" = "true" ]; then
  TIER=full
elif [ "$FILES_CHANGED" -le 2 ] && [ "$LOC_CHANGED" -le 10 ]; then
  TIER=trivial
else
  TIER=standard
fi

printf 'tier=%s\n' "$TIER"
printf 'loc_changed=%d\n' "$LOC_CHANGED"
printf 'files_changed=%d\n' "$FILES_CHANGED"
printf 'sensitive_hit=%s\n' "$SENSITIVE_HIT"
