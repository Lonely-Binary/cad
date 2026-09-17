#!/usr/bin/env bash
# Enforce the naming rules in README.md. This file is the authority: if a rule
# changes, change it here and in README.md in the same commit.
#
# Checks what git would commit (tracked + untracked, minus .gitignore), so a
# stray .DS_Store on your disk does not fail the run. Written for bash 3.2,
# which is what macOS still ships.
#
# Usage: scripts/check.sh            check the whole repository
#        scripts/check.sh <slug>     check one product
set -euo pipefail
cd "$(dirname "$0")/.."

# Every list below is one item per line, and so is every loop: a file name
# with a space in it has to reach the name check whole, and fail it.
IFS=$'\n'

# Suffixes a product folder may hold, after the slug. Nothing else is allowed.
SUFFIXES='.step
.glb
-mechanical.pdf
-mechanical.dxf
-line-art.png
-top.png
-bottom.png'
# Suffixes every product must have.
REQUIRED='.step
.glb'
# Top-level entries that are not products.
TOP_LEVEL='README.md
AGENTS.md
CLAUDE.md
LICENSE
.gitignore
.gitattributes
.github
scripts'

MIB=$((1024 * 1024))
errors=0
fail() { echo "error: $*" >&2; errors=$((errors + 1)); }
warn() { echo "warning: $*" >&2; }
has() { # has <list> <item>
  local x
  for x in $1; do if [ "$x" = "$2" ]; then return 0; fi; done
  return 1
}

files=$(git ls-files --cached --others --exclude-standard | sort -u | while read -r f; do
  if [ -e "$f" ]; then echo "$f"; fi
done)

slugs=''
for f in $files; do
  top=${f%%/*}
  if has "$TOP_LEVEL" "$top"; then
    continue
  elif [ "$top" = "$f" ]; then
    if [ $# -eq 0 ]; then fail "$f: loose file at the top level; files go in a product folder"; fi
  elif ! has "$slugs" "$top"; then
    slugs="$slugs$top"$'\n'
  fi
done

if [ $# -gt 0 ]; then
  if ! has "$slugs" "$1"; then echo "error: no product folder named '$1'" >&2; exit 1; fi
  slugs=$1
fi

for slug in $slugs; do
  if ! echo "$slug" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    fail "$slug/: folder name must be lowercase letters, digits and single hyphens"
  fi
  if echo "$slug" | grep -Eq '(^|-)v[0-9]'; then
    fail "$slug/: folder name carries a version; the version lives in $slug/VERSION and the tag"
  fi

  if [ ! -f "$slug/VERSION" ]; then
    fail "$slug/VERSION is missing"
  elif ! grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)?$' "$slug/VERSION" || [ "$(wc -l < "$slug/VERSION")" -gt 1 ]; then
    fail "$slug/VERSION must be one line like 4.0 or 4.0.1, got: $(head -c 40 "$slug/VERSION")"
  fi

  for f in $files; do
    case "$f" in "$slug"/*) ;; *) continue ;; esac
    name=${f#"$slug"/}
    if [ "$name" = "VERSION" ]; then continue; fi
    if [ "${name#*/}" != "$name" ]; then
      fail "$f: no subfolders inside a product folder"
      continue
    fi
    ok=0
    for s in $SUFFIXES; do if [ "$name" = "$slug$s" ]; then ok=1; fi; done
    if [ $ok = 0 ]; then
      fail "$f: not an allowed name; allowed: $(for s in $SUFFIXES; do printf '%s ' "$slug$s"; done)"
    fi

    size=$(wc -c < "$f" | tr -d ' ')
    if [ "$size" -gt $((100 * MIB)) ]; then
      fail "$f: $((size / MIB)) MiB; GitHub rejects files over 100 MiB"
    elif [ "$size" -gt $((50 * MIB)) ]; then
      warn "$f: $((size / MIB)) MiB; GitHub warns over 50 MiB and refuses over 100 MiB"
    fi
  done

  for s in $REQUIRED; do
    if [ ! -f "$slug/$slug$s" ]; then fail "$slug/$slug$s is missing"; fi
  done
done

if [ $errors -gt 0 ]; then
  echo "$errors problem(s). The rules are in README.md." >&2
  exit 1
fi
echo "ok: $(for s in $slugs; do printf '%s ' "$s"; done)"
