#!/bin/sh
set -e

# Use mounted .opencode if present, otherwise fall back to baked-in defaults
if [ -f "/reviewer/.opencode/config.json" ]; then
  RULES_DIR="/reviewer/.opencode"
else
  RULES_DIR="/defaults/.opencode"
fi

MODE="${MODE:-review}"
DIFF_FILE="${DIFF_FILE:-/workspace/pr-diff.txt}"
FILES_FILE="${FILES_FILE:-/workspace/changed-files.txt}"
COMMITS_FILE="${COMMITS_FILE:-/workspace/commits.txt}"

if [ ! -f "$DIFF_FILE" ]; then
  echo "ERROR: diff file not found at $DIFF_FILE" >&2
  echo "Mount your diff: -v \"\$PWD/pr-diff.txt:/workspace/pr-diff.txt\"" >&2
  exit 1
fi

# Strip known prompt-injection patterns from attacker-controlled content
# (diff, changed-files, commit messages) before it lands in the prompt.
# Threat model: SECURITY.md § "Prompt injection threat model".
sanitize_untrusted() {
  awk '
    BEGIN { S = "[redacted: matched injection-filter pattern]" }
    {
      line = $0
      if (line ~ /=====[[:space:]].*[[:space:]]=====/) { print S; next }
      if (index(line, "<system>") || index(line, "</system>")) { print S; next }
      if (index(line, "<|im_start|>") || index(line, "<|im_end|>")) { print S; next }
      if (index(line, "<|start|>") || index(line, "<|end|>")) { print S; next }
      if (index(line, "[INST]") || index(line, "[/INST]")) { print S; next }
      if (index(line, "### NEW INSTRUCTIONS")) { print S; next }
      if (index(line, "### INSTRUCTION OVERRIDE")) { print S; next }
      if (index(line, "### END USER INSTRUCTIONS")) { print S; next }
      lower = tolower(line)
      if (lower ~ /ignore (all )?previous instructions/) { print S; next }
      if (lower ~ /disregard (the )?above/) { print S; next }
      if (lower ~ /you are now/) { print S; next }
      if (lower ~ /act as if/) { print S; next }
      print line
    }
  '
}

sanitize_untrusted < "$DIFF_FILE" > /tmp/diff-sanitized.txt
DIFF_FILE_SAFE=/tmp/diff-sanitized.txt

FILES_FILE_SAFE=""
if [ -f "$FILES_FILE" ]; then
  sanitize_untrusted < "$FILES_FILE" > /tmp/files-sanitized.txt
  FILES_FILE_SAFE=/tmp/files-sanitized.txt
fi

COMMITS_FILE_SAFE=""
if [ -f "$COMMITS_FILE" ]; then
  sanitize_untrusted < "$COMMITS_FILE" > /tmp/commits-sanitized.txt
  COMMITS_FILE_SAFE=/tmp/commits-sanitized.txt
fi

if [ "$MODE" = "describe" ]; then
  # Build PR description prompt
  {
    echo "You are generating a pull request description. Follow ALL instructions below."
    echo

    echo "===== SKILL: pr-description ====="
    cat "$RULES_DIR/skills/pr-description.md"
    echo

    if [ -d "/workspace/repo" ]; then
      echo "===== REPO ACCESS ====="
      echo "The full checkout is mounted read-only at /workspace/repo."
      echo "You are encouraged to open changed files there (using your read tool) to understand context beyond the diff hunks before writing the description."
      echo "Focus on the files listed in CHANGED FILES below — do not browse unrelated code."
      echo
    fi

    if [ -n "$FILES_FILE_SAFE" ]; then
      echo "===== CHANGED FILES ====="
      cat "$FILES_FILE_SAFE"
      echo
    fi

    if [ -n "$COMMITS_FILE_SAFE" ]; then
      echo "===== COMMIT MESSAGES ====="
      cat "$COMMITS_FILE_SAFE"
      echo
    fi

    echo "===== PR DIFF ====="
    cat "$DIFF_FILE_SAFE"
    echo

    echo "Respond with ONLY the JSON object specified by the pr-description skill. No prose, no fences."
  } > /tmp/prompt.txt
else
  # Build code review prompt
  {
    echo "You are an automated code reviewer. Follow ALL rules below."
    echo

    echo "===== RULES: code-review ====="
    cat "$RULES_DIR/rules/code-review.md"
    echo

    echo "===== RULES: security ====="
    cat "$RULES_DIR/rules/security.md"
    echo

    echo "===== RULES: performance ====="
    cat "$RULES_DIR/rules/performance.md"
    echo

    # Stack-aware skill injection (only if changed-files.txt is provided)
    if [ -n "$FILES_FILE_SAFE" ]; then
      if grep -qE '\.(kt|kts|gradle)$' "$FILES_FILE_SAFE"; then
        echo "===== SKILL: android-kotlin ====="
        cat "$RULES_DIR/skills/android-kotlin.md"; echo
      fi
      if grep -qE '\.swift$' "$FILES_FILE_SAFE"; then
        echo "===== SKILL: ios-macos-swift ====="
        cat "$RULES_DIR/skills/ios-swift.md"; echo
      fi
      if grep -qE '\.dart$' "$FILES_FILE_SAFE"; then
        echo "===== SKILL: flutter ====="
        cat "$RULES_DIR/skills/flutter.md"; echo
      fi
    fi

    echo "===== SKILL: general ====="
    cat "$RULES_DIR/skills/general.md"
    echo

    echo "===== PR DIFF ====="
    cat "$DIFF_FILE_SAFE"
    echo

    echo "Respond with ONLY the JSON object specified by the code-review rules. No prose, no fences."
  } > /tmp/prompt.txt
fi

opencode run "$(cat /tmp/prompt.txt)"
