#!/usr/bin/env bash
# Build the release assets for one tag. The release workflow runs this; you can
# run it locally to see exactly what a tag would publish.
#
# Usage: scripts/package.sh <slug>-v<version> [outdir]    (outdir defaults to dist)
#
# Every asset gets -v<version> after the slug, so a file on a reader's disk
# still says which board it belongs to. STEP and DXF are text and shrink about
# 6x and 15x, so they ship zipped; GLB, PDF and PNG are already compressed and
# ship as they are.
set -euo pipefail
cd "$(dirname "$0")/.."

tag=${1:?usage: scripts/package.sh <slug>-v<version> [outdir]}
out=${2:-dist}

if ! echo "$tag" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*-v[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
  echo "error: tag '$tag' is not <slug>-v<version>, e.g. esp32-s3-pinpulse-v4.0" >&2
  exit 1
fi
slug=${tag%-v*}
version=${tag##*-v}

[ -d "$slug" ] || { echo "error: no product folder '$slug/' for tag '$tag'" >&2; exit 1; }
scripts/check.sh "$slug"

actual=$(cat "$slug/VERSION")
if [ "$actual" != "$version" ]; then
  echo "error: tag says $version but $slug/VERSION says $actual; bump VERSION, commit, then tag" >&2
  exit 1
fi

dest="$out/$tag"
rm -rf "$dest"
mkdir -p "$dest"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for f in "$slug/$slug".* "$slug/$slug"-*; do
  [ -f "$f" ] || continue
  suffix=${f#"$slug/$slug"}
  name="$slug-v$version$suffix"
  case "$suffix" in
    *.step | *.dxf)
      cp "$f" "$tmp/$name"
      (cd "$tmp" && zip -q -X -9 "$name.zip" "$name")
      mv "$tmp/$name.zip" "$dest/"
      ;;
    *) cp "$f" "$dest/$name" ;;
  esac
done

ls -l "$dest" | tail -n +2 | awk '{printf "%8.1f MB  %s\n", $5 / 1048576, $9}'
