#!/usr/bin/env bash
# Publish one product revision: record its version in git, and put its files
# from the source folder in a GitHub Release. Written for bash 3.2.
#
# Usage: CAD_SOURCE=<dir> scripts/release.sh <slug> <version>
#
#   1. checks $CAD_SOURCE/<slug>/ against the naming rules
#   2. writes <slug>/VERSION, commits it on main and pushes it, unless it
#      already says <version> (a rerun after a failed release)
#   3. builds the assets with package.sh
#   4. creates the release, which creates the tag <slug>-v<version> on that
#      commit
#
# A published tag is final, so this refuses a tag or release that exists.
set -euo pipefail

usage='usage: CAD_SOURCE=<dir> scripts/release.sh <slug> <version>'
slug=${1:?$usage}
version=${2:?$usage}
tag="$slug-v$version"
: "${CAD_SOURCE:?set CAD_SOURCE to the source folder, see README.md}"
[ -d "$CAD_SOURCE" ] || { echo "error: CAD_SOURCE '$CAD_SOURCE' does not exist" >&2; exit 1; }
CAD_SOURCE=$(cd "$CAD_SOURCE" && pwd)
export CAD_SOURCE
cd "$(dirname "$0")/.."

die() { echo "error: $*" >&2; exit 1; }

echo "$version" | grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)?$' ||
  die "version '$version' is not MAJOR.MINOR or MAJOR.MINOR.PATCH, e.g. 4.0 or 4.0.1"
[ "$(git symbolic-ref --short HEAD)" = main ] || die "releases are made from main"
git diff --quiet && git diff --cached --quiet || die "commit or stash your changes first"
gh auth status >/dev/null 2>&1 || die "gh is not logged in; run: gh auth login"

git fetch -q origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] ||
  die "main is not the same as origin/main; pull or push first"
[ -z "$(git ls-remote --tags origin "refs/tags/$tag")" ] || die "tag $tag is already published, and a published tag is final"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && die "tag $tag exists locally but not on GitHub; find out why before releasing"
gh release view "$tag" >/dev/null 2>&1 && die "a release named $tag exists, perhaps a draft; see: gh release view $tag"

scripts/check.sh --source "$CAD_SOURCE" "$slug"

if [ "$(cat "$slug/VERSION" 2>/dev/null)" != "$version" ]; then
  mkdir -p "$slug"
  echo "$version" > "$slug/VERSION"
  scripts/check.sh "$slug"
  git add "$slug/VERSION"
  git commit -q -m "Release $slug v$version"
  git push -q origin main
fi
sha=$(git rev-parse HEAD)

scripts/package.sh "$tag" dist

notes=$(mktemp)
trap 'rm -f "$notes"' EXIT
{
  echo "Files for **$slug**, board revision **v$version**."
  echo
  echo "STEP and DXF are zipped. Link to these files by this tag; the URL never changes."
} > "$notes"

if ! gh release create "$tag" "dist/$tag"/* --target "$sha" --title "$slug v$version" --notes-file "$notes"; then
  echo "error: the release did not finish. See what exists: gh release view $tag" >&2
  echo "       If it is there with files missing, add them: gh release upload $tag dist/$tag/*" >&2
  exit 1
fi
git fetch -q origin tag "$tag"
echo "published: $(gh release view "$tag" --json url -q .url)"
