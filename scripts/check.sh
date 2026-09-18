#!/usr/bin/env bash
# Enforce the naming rules in README.md. This file is the authority: if a rule
# changes, change it here and in README.md in the same commit.
#
# Product folders live in two places, and each has its own rules:
#
#   the repository     <slug>/VERSION and nothing else. Models never enter git.
#   the source folder  <slug>/<slug><suffix>, the files a release publishes.
#                      It is outside git; $CAD_SOURCE points at it.
#
# In the repository it checks what git would commit (tracked + untracked, minus
# .gitignore), so a stray .DS_Store on your disk does not fail the run. Written
# for bash 3.2, which is what macOS still ships.
#
# Usage: scripts/check.sh                           check the repository
#        scripts/check.sh <slug>                    check one product in it
#        scripts/check.sh --source <dir> [<slug>]   check a source folder
set -euo pipefail

source=''
if [ "${1:-}" = "--source" ]; then
  [ -n "${2:-}" ] || { echo "usage: scripts/check.sh --source <dir> [<slug>]" >&2; exit 2; }
  [ -d "$2" ] || { echo "error: source folder '$2' does not exist" >&2; exit 1; }
  source=$(cd "$2" && pwd)
  shift 2
fi
cd "$(dirname "$0")/.."

# Every list below is one item per line, and so is every loop: a file name
# with a space in it has to reach the name check whole, and fail it.
IFS=$'\n'

# Suffixes a product folder in the source folder may hold, after the slug.
# Nothing else is allowed.
SUFFIXES='.step
.glb
-mechanical.pdf
-mechanical.dxf'
# Suffixes every product must have.
REQUIRED='.step
.glb'
# Top-level entries in the repository that are not products.
TOP_LEVEL='README.md
AGENTS.md
CLAUDE.md
LICENSE
.gitignore
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

# Size and placeholder state come from stat, never from reading the file: on a
# synced drive, reading a cloud-only file starts a download.
if [ "$(uname)" = Darwin ]; then
  size_of() { stat -L -f %z "$1"; }
  # iCloud and Google Drive leave a "dataless" placeholder of the right size
  # when a file is kept only in the cloud.
  dataless() { stat -L -f %Sf "$1" | grep -q dataless; }
else
  size_of() { stat -L -c %s "$1"; }
  dataless() { return 1; }
fi

if [ -n "$source" ]; then
  root=$source
  files=$(cd "$source" && find . \( -type f -o -type l \) | sed 's|^\./||' | while read -r f; do
    case "${f##*/}" in (.DS_Store | ._* | Thumbs.db | desktop.ini | Icon$'\r') continue ;; esac
    echo "$f"
  done | sort)
else
  root=.
  files=$(git ls-files --cached --others --exclude-standard | sort -u | while read -r f; do
    if [ -e "$f" ]; then echo "$f"; fi
  done)
fi

slugs=''
for f in $files; do
  top=${f%%/*}
  if [ -z "$source" ] && has "$TOP_LEVEL" "$top"; then
    continue
  elif [ "$top" = "$f" ]; then
    if [ $# -eq 0 ]; then fail "$f: loose file at the top level; files go in a product folder"; fi
  elif ! has "$slugs" "$top"; then
    slugs="$slugs$top"$'\n'
  fi
done

if [ $# -gt 0 ]; then
  if ! has "$slugs" "$1"; then echo "error: no product folder named '$1' in $root" >&2; exit 1; fi
  slugs=$1
fi

for slug in $slugs; do
  if ! echo "$slug" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    fail "$slug/: folder name must be lowercase letters, digits and single hyphens"
  fi
  if echo "$slug" | grep -Eq '(^|-)v[0-9]'; then
    fail "$slug/: folder name carries a version; the version lives in $slug/VERSION and the tag"
  fi

  if [ -z "$source" ]; then
    if [ ! -f "$slug/VERSION" ]; then
      fail "$slug/VERSION is missing"
    elif ! grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)?$' "$slug/VERSION" || [ "$(wc -l < "$slug/VERSION")" -gt 1 ]; then
      fail "$slug/VERSION must be one line like 4.0 or 4.0.1, got: $(head -c 40 "$slug/VERSION")"
    fi
    for f in $files; do
      case "$f" in "$slug"/*) ;; *) continue ;; esac
      if [ "$f" != "$slug/VERSION" ]; then
        fail "$f: only VERSION goes in git; the files go in the source folder and ship in a release"
      fi
    done
    continue
  fi

  for f in $files; do
    case "$f" in "$slug"/*) ;; *) continue ;; esac
    name=${f#"$slug"/}
    if [ "${name#*/}" != "$name" ]; then
      fail "$f: no subfolders inside a product folder"
      continue
    fi
    ok=0
    for s in $SUFFIXES; do if [ "$name" = "$slug$s" ]; then ok=1; fi; done
    if [ $ok = 0 ]; then
      fail "$f: not an allowed name; allowed: $(for s in $SUFFIXES; do printf '%s ' "$slug$s"; done)"
      continue
    fi

    if dataless "$source/$f"; then
      fail "$f: only in the cloud, not on this disk; make the folder available offline"
      continue
    fi
    size=$(size_of "$source/$f")
    if [ "$size" -gt $((2048 * MIB)) ]; then
      fail "$f: $((size / MIB)) MiB; a release asset can be at most 2 GiB"
    elif [ "$size" -gt $((50 * MIB)) ]; then
      warn "$f: $((size / MIB)) MiB; a STEP file this large usually carries more than the board"
    fi
  done

  for s in $REQUIRED; do
    if [ ! -f "$source/$slug/$slug$s" ]; then fail "$slug/$slug$s is missing"; fi
  done
done

if [ $errors -gt 0 ]; then
  echo "$errors problem(s). The rules are in README.md." >&2
  exit 1
fi
echo "ok: $(for s in $slugs; do printf '%s ' "$s"; done)"
