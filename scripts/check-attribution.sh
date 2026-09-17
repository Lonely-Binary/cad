#!/usr/bin/env bash
# Reject tool and AI attribution in text that is published on GitHub: commit
# messages, and PR titles and bodies. AGENTS.md says why. Written for bash 3.2.
#
# Usage: scripts/check-attribution.sh <rev-range>   check commit messages,
#                                                   e.g. origin/main..HEAD
#        scripts/check-attribution.sh --file <path> check the text in a file,
#                                                   e.g. a commit message or
#                                                   a PR body ("-" is stdin)
set -euo pipefail
cd "$(dirname "$0")/.."

TOOLS='claude|anthropic|openai|chatgpt|gpt-[0-9]|codex|copilot|gemini|cursor|devin|aider|windsurf'
PATTERNS="^[[:space:]]*co-authored-by:.*($TOOLS)
generated (with|by) .*($TOOLS)
claude\\.com/claude-code|claude\\.ai/code
noreply@anthropic\\.com"

found() { # found <label> <text>
  local p hits=''
  local IFS=$'\n'
  for p in $PATTERNS; do
    hits="$hits$(printf '%s\n' "$2" | grep -Ei -- "$p" || true)"$'\n'
  done
  hits=$(printf '%s' "$hits" | grep . || true)
  if [ -n "$hits" ]; then
    echo "error: $1 carries tool attribution:" >&2
    printf '%s\n' "$hits" | sort -u | sed 's/^/    /' >&2
    return 0
  fi
  return 1
}

if [ $# -eq 2 ] && [ "$1" = "--file" ]; then
  if [ "$2" = "-" ]; then text=$(cat); else text=$(cat "$2"); fi
  if found "the text" "$text"; then exit 1; fi
  echo "ok: no tool attribution"
  exit 0
fi

if [ $# -ne 1 ]; then
  sed -n '5,10p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
fi

errors=0
for sha in $(git rev-list "$1"); do
  if found "commit $(git log -1 --format='%h %s' "$sha")" "$(git log -1 --format=%B "$sha")"; then
    errors=$((errors + 1))
  fi
done
if [ $errors -gt 0 ]; then
  echo "$errors commit(s). Reword them without the attribution; AGENTS.md says why." >&2
  exit 1
fi
echo "ok: no tool attribution in $1"
