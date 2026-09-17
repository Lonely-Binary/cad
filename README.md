# cad

3D models and mechanical drawings for Lonely Binary boards, one folder per
product.

This repository is the only copy. A file a reader downloads from
[learn.lonelybinary.com](https://learn.lonelybinary.com) is an asset of a
Release here, not a second copy kept on the website, so there is one place to
update and nothing to drift out of step.

## Layout

```
esp32-s3-pinpulse/
  VERSION                            4.0
  esp32-s3-pinpulse.step
  esp32-s3-pinpulse.glb
  esp32-s3-pinpulse-mechanical.pdf
  esp32-s3-pinpulse-mechanical.dxf
  esp32-s3-pinpulse-line-art.png
  esp32-s3-pinpulse-top.png
  esp32-s3-pinpulse-bottom.png
tk104-microsd/
  ...
```

## Naming rules

`scripts/check.sh` enforces these rules as far as a script can, locally and in
CI on every push. If a rule changes, it changes in that script and in this file
in the same commit.

**1. The folder name is the product's slug.** Lowercase letters, digits and
single hyphens. TinkerBlock modules are `tk<number>-<what-it-is>`
(`tk104-microsd`); other boards are `<platform>-<product>`
(`esp32-s3-pinpulse`).

A slug is permanent once it has been tagged. Tags, release URLs and links on the
website are all built from it, so renaming a folder breaks every one of them.

**2. A file's name is the slug plus one of these suffixes.** Nothing else is
allowed in a product folder, and there are no subfolders.

| File | What it is | Required |
|---|---|---|
| `<slug>.step` | CAD model, as exported from EasyEDA Pro | yes |
| `<slug>.glb` | Web model, for 3D viewers | yes |
| `<slug>-mechanical.pdf` | Mechanical drawing: outline, holes, dimensions | |
| `<slug>-mechanical.dxf` | The same drawing, for CAD | |
| `<slug>-line-art.png` | Isometric line art, black strokes on transparent | |
| `<slug>-top.png` | Render of the top, on transparent | |
| `<slug>-bottom.png` | Render of the bottom, on transparent | |

A new kind of file gets a new suffix added to the table and to `SUFFIXES` in
`scripts/check.sh`. Do not invent one ad hoc.

**3. No version in any folder or file name.** The version lives in
`<slug>/VERSION` and in the tag. A new revision replaces the files under the
same names, so git keeps one history per file and links do not move.

**4. Nothing zipped, and no Git LFS.** Git already compresses what it stores,
and a zip turns every revision into an unrelated blob. The release zips what is
worth zipping. LFS would bill every public download against a small bandwidth
quota.

**5. No file over 100 MiB.** GitHub refuses the push. The check warns above
50 MiB. A STEP file this large is a sign the export carries more than the board.

`.DS_Store` and other OS clutter are ignored by `.gitignore`. Never force-add
them.

## Versions

`<slug>/VERSION` holds one line: `MAJOR.MINOR` or `MAJOR.MINOR.PATCH`.

- `MAJOR.MINOR` is the board's hardware revision: `4.0` is the v4.0 board.
- `PATCH` is for the same board with corrected files, such as a wrong
  dimension in the drawing or a missing part in the model: `4.0.1`.

## Releasing

1. Replace the files under the same names and update `VERSION`.
2. Run `scripts/check.sh`, then commit and push.
3. Tag the commit and push the tag:

   ```sh
   git tag esp32-s3-pinpulse-v4.0
   git push origin esp32-s3-pinpulse-v4.0
   ```

The tag is always `<slug>-v<version>`, and the version must equal the one in
`VERSION` at that commit. `.github/workflows/release.yml` then runs
`scripts/package.sh`, which renames every file with the version after the slug
and zips the STEP and DXF files, and publishes the result as a GitHub Release:

| In the repository | In the release |
|---|---|
| `esp32-s3-pinpulse.step` | `esp32-s3-pinpulse-v4.0.step.zip` |
| `esp32-s3-pinpulse-mechanical.dxf` | `esp32-s3-pinpulse-v4.0-mechanical.dxf.zip` |
| `esp32-s3-pinpulse.glb` | `esp32-s3-pinpulse-v4.0.glb` |
| `esp32-s3-pinpulse-mechanical.pdf` | `esp32-s3-pinpulse-v4.0-mechanical.pdf` |
| `esp32-s3-pinpulse-top.png` | `esp32-s3-pinpulse-v4.0-top.png` |

The version is in the asset name so that a downloaded file still says which
board it belongs to. STEP and DXF are text and shrink about six and fifteen
times. GLB, PDF and PNG are already compressed and ship as they are.

Run `scripts/package.sh <tag>` locally to see what a tag would publish. It
writes to `dist/`, which is ignored.

**A published tag is final.** Never move, delete or re-push a tag, and never
edit a release's assets by hand, because a link on the website may already
point at them. A wrong file is fixed by a new version, usually a `PATCH`.

## Linking from the website

Link to a release asset, pinned to its tag:

```
https://github.com/Lonely-Binary/cad/releases/download/<slug>-v<version>/<asset>
https://github.com/Lonely-Binary/cad/releases/download/esp32-s3-pinpulse-v4.0/esp32-s3-pinpulse-v4.0.step.zip
```

Two links that look right and are not:

- `…/raw/main/<slug>/…` follows the branch, so the file changes under a page
  that still describes the old one.
- `…/releases/latest/download/…` means the latest release of the whole
  repository, which is whichever product was released last, not this product.

A page that renders a model in the browser serves its own copy of the GLB
rather than hot-linking GitHub, which is not a CDN. That copy is taken from a
release and never edited in place.

## GitHub limits

As of 2026. Check GitHub's documentation before relying on a number.

- A file over 50 MiB draws a warning. Over 100 MiB, the push is refused.
- Keep the repository under 1 GB if possible, and under 5 GB. Every revision
  of every file stays in the history, so a 30 MB STEP file revised ten times
  costs 300 MB before git's compression.
- Each release asset can be up to 2 GiB. Neither the total size of releases
  nor their download bandwidth is limited, which is why downloads are served
  from releases.
