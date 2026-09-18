# cad

3D models and mechanical drawings for Lonely Binary boards, one folder per
product.

The files are not kept in git. Each revision of a product is published as a
GitHub Release of this repository, and the releases are the one copy: a file a
reader downloads from [learn.lonelybinary.com](https://learn.lonelybinary.com)
is a release asset here, not a second copy kept on the website, so there is one
place to update and nothing to drift out of step. Git keeps the version of each
product and the scripts that check and publish the files.

## Where the files live

| Where | What |
|---|---|
| This repository | `<slug>/VERSION`, these rules, and the scripts |
| The source folder | The files of each product, outside git |
| GitHub Releases | Every published revision, final |

Models stay out of git because git keeps every revision of every file forever,
and every clone downloads all of it. Three boards took 30 MB; three hundred
would take gigabytes before a single revision, past what GitHub asks a
repository to stay under. A release asset costs the repository nothing.

The source folder is any folder outside this repository, usually on a synced
drive, laid out like the one below. Point `CAD_SOURCE` at it:

```sh
export CAD_SOURCE="$HOME/path/to/cad-source"
```

Make the folder available offline. A synced drive can keep a file only in the
cloud and leave a placeholder of the right size on disk, and a release that
reads one stalls or fails halfway. `scripts/check.sh --source` refuses such a
file instead.

The source folder is not the only copy of what is published. `package.sh` only
renames the files and zips some of them, so each release asset holds the same
bytes as the file it was built from, and every revision stays downloadable.

The models committed before this rule are still in the history, about 30 MB.
They stay there: removing them would rewrite every commit and move every
published tag.

## Layout

The repository:

```
esp32-s3-pinpulse/
  VERSION                            4.0
tk104-microsd/
  VERSION                            1.0
```

The source folder:

```
esp32-s3-pinpulse/
  esp32-s3-pinpulse.step
  esp32-s3-pinpulse.glb
  esp32-s3-pinpulse-mechanical.pdf
  esp32-s3-pinpulse-mechanical.dxf
tk104-microsd/
  ...
```

## Naming rules

`scripts/check.sh` enforces these rules as far as a script can: on the
repository locally and in CI on every push, and on the source folder before
every release. If a rule changes, it changes in that script and in this file in
the same commit.

**1. The folder name is the product's slug**, in both places. Lowercase
letters, digits and single hyphens. TinkerBlock modules are
`tk<number>-<what-it-is>` (`tk104-microsd`); other boards are
`<platform>-<product>` (`esp32-s3-pinpulse`).

A slug is permanent once it has been tagged. Tags, release URLs and links on the
website are all built from it, so renaming a folder breaks every one of them.

**2. In the repository, a product folder holds `VERSION` and nothing else.**

**3. In the source folder, a file's name is the slug plus one of these
suffixes.** Nothing else is allowed in a product folder, and there are no
subfolders.

| File | What it is | Required |
|---|---|---|
| `<slug>.step` | CAD model, as exported from EasyEDA Pro | yes |
| `<slug>.glb` | Web model, for 3D viewers | yes |
| `<slug>-mechanical.pdf` | Mechanical drawing: outline, holes, dimensions | |
| `<slug>-mechanical.dxf` | The same drawing, for CAD | |

A new kind of file gets a new suffix added to the table and to `SUFFIXES` in
`scripts/check.sh`. Do not invent one ad hoc.

**4. No version in any folder or file name.** The version lives in
`<slug>/VERSION` and in the tag. A new revision replaces the files under the
same names, so links do not move.

**5. Nothing zipped, and no Git LFS.** The release zips what is worth zipping.
LFS would bill every public download against a small bandwidth quota.

**6. No file over 2 GiB**, the most a release asset can be. The check warns
above 50 MiB: a STEP file this large is a sign the export carries more than the
board.

`.DS_Store` and other OS clutter are ignored in both places. Never force-add
them.

## Versions

`<slug>/VERSION` holds one line: `MAJOR.MINOR` or `MAJOR.MINOR.PATCH`.

- `MAJOR.MINOR` is the board's hardware revision: `4.0` is the v4.0 board.
- `PATCH` is for the same board with corrected files, such as a wrong
  dimension in the drawing or a missing part in the model: `4.0.1`.

## Releasing

1. Put the files in `$CAD_SOURCE/<slug>/`, replacing the old ones under the
   same names.
2. Check them:

   ```sh
   scripts/check.sh --source "$CAD_SOURCE" esp32-s3-pinpulse
   ```

3. Release them, from an up-to-date `main` with no uncommitted changes:

   ```sh
   scripts/release.sh esp32-s3-pinpulse 4.0.1
   ```

`scripts/release.sh` checks the files again, writes the version to
`<slug>/VERSION`, commits it on `main` and pushes it. It then runs
`scripts/package.sh`, which renames every file with the version after the slug
and zips the STEP and DXF files, and publishes the result as a GitHub Release.
The release creates the tag `<slug>-v<version>` on the commit that holds that
`VERSION`:

| In the source folder | In the release |
|---|---|
| `esp32-s3-pinpulse.step` | `esp32-s3-pinpulse-v4.0.step.zip` |
| `esp32-s3-pinpulse-mechanical.dxf` | `esp32-s3-pinpulse-v4.0-mechanical.dxf.zip` |
| `esp32-s3-pinpulse.glb` | `esp32-s3-pinpulse-v4.0.glb` |
| `esp32-s3-pinpulse-mechanical.pdf` | `esp32-s3-pinpulse-v4.0-mechanical.pdf` |

The version is in the asset name so that a downloaded file still says which
board it belongs to. STEP and DXF are text and shrink about six and fifteen
times. GLB and PDF are already compressed and ship as they are.

If a release fails after the `VERSION` commit, run the same command again: it
sees `VERSION` already says that version and carries on from there.

To see what a tag would publish without publishing it, run
`scripts/package.sh <slug>-v<version>` once `VERSION` says that version. It
writes to `dist/`, which is ignored.

**A published tag is final.** Never move, delete or re-push a tag, and never
edit a release's assets by hand, because a link on the website may already
point at them. A wrong file is fixed by a new version, usually a `PATCH`.

The first three releases also carry `-top.png`, `-bottom.png` and
`-line-art.png`. Nothing uses them, and no later release has them.

## Linking from the website

Link to a release asset, pinned to its tag:

```
https://github.com/Lonely-Binary/cad/releases/download/<slug>-v<version>/<asset>
https://github.com/Lonely-Binary/cad/releases/download/esp32-s3-pinpulse-v4.0/esp32-s3-pinpulse-v4.0.step.zip
```

Two links that look right and are not:

- `…/raw/main/<slug>/…` points at nothing: the files are not in git.
- `…/releases/latest/download/…` means the latest release of the whole
  repository, which is whichever product was released last, not this product.

A page that renders a model in the browser serves its own copy of the GLB
rather than hot-linking GitHub, which is not a CDN. That copy is taken from a
release and never edited in place.

## GitHub limits

As of 2026. Check GitHub's documentation before relying on a number.

- Each release asset can be up to 2 GiB. Neither the total size of releases
  nor their download bandwidth is limited, which is why the files live there.
- A repository should stay under 1 GB, and must stay under 5 GB. This one
  holds text, so it only grows if a model is committed by mistake, which
  `scripts/check.sh` refuses.
