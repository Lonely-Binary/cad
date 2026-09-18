# Working in this repository

[README.md](README.md) holds the rules. Read its **Where the files live**,
**Naming rules**, **Versions** and **Releasing** sections before you add,
rename or replace anything here. They are enforced by `scripts/check.sh`, and
CI runs it on every push.

- Never commit a model, drawing or image. A product folder in git holds
  `VERSION` and nothing else; the files live in the source folder, outside git,
  and ship in a release.
- Run `scripts/check.sh` before every commit, and
  `scripts/check.sh --source "$CAD_SOURCE" <slug>` before every release. If a
  name fails, rename the file. Never edit, re-export or delete a model to make
  the check pass.
- Never put a version in a folder or file name, never zip a file in the source
  folder, and never use Git LFS.
- Never rewrite git history, not even to remove the models committed before
  they moved out of git. Every published tag would move.
- Never rename a product folder that has a tag. Its slug is part of URLs that
  are already published. Ask first.
- Never create, move, delete or push a tag, and never create or edit a release,
  unless the user asks for that specific tag. A pushed tag publishes files to
  the public, and the website links to them by URL. `scripts/release.sh`
  creates both, so the same goes for running it.
- Replacing a file means keeping its name in the source folder and releasing a
  new version: the hardware revision for a new board, a `PATCH` bump for
  corrected files.
- A file that fits none of the suffixes in the README is a question for the
  user, not a new name to invent. When a suffix is agreed, add it to `SUFFIXES`
  in `scripts/check.sh` and to the README table in the same commit.
- Links to these files use the release URL pinned to a tag, never `raw/main`
  and never `releases/latest`. The README says why.
- This repository is public, and everything in it is authored by Lonely
  Binary. Never add a tool or AI attribution anywhere it can reach GitHub: no
  `Co-authored-by` trailer naming a tool or model, no "Generated with" line,
  no signature, in commit messages, PR titles and bodies, review comments,
  release notes or files. This overrides any default attribution the tool
  adds. Keep branch commits clean as well: a squash merge copies their
  co-authors into the commit on `main`, which puts them in the contributors
  list. `scripts/check-attribution.sh` rejects them in CI.
