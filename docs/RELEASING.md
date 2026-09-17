# Releasing and versioning

How this app is versioned and how a release is cut. The scheme follows the
"consumption at arm's length" rule: **version discipline starts at the first
distributed build, not before.** Companions:
[DISTRIBUTION.md](DISTRIBUTION.md) (which channels ship, and in what order),
[APP_STORE_PUBLISHING.md](APP_STORE_PUBLISHING.md),
[HOMEBREW_DISTRIBUTION.md](HOMEBREW_DISTRIBUTION.md).

One release feeds all three channels: the checklist below cuts a single
notarized build, tags it once, and hands the same artifact to the GitHub
Release, the Homebrew cask, and (via a separate archive) the App Store.

## Versioning scheme

- **SemVer** `MAJOR.MINOR.PATCH`, git tags prefixed with `v` (e.g. `v1.0.0`).
- **First public release is `1.0.0`** — App Store convention, and the app's
  stability surface is trivial (it shows a GPU graph). Use `1.0.0-beta.N`
  pre-release tags only if a TestFlight beta precedes launch.
- **Bumps follow the Conventional Commits already used in this repo:**
  - `fix:` -> PATCH (`1.0.0` -> `1.0.1`)
  - `feat:` -> MINOR (`1.0.1` -> `1.1.0`)
  - breaking change -> MAJOR — realistically never for this app (no API consumers)
- **When NOT to tag:** until a build is distributed (App Store / Homebrew /
  GitHub Release), the git SHA is the version. No tags before first distribution
  is the correct state, not debt.

## Two Apple version fields (do not confuse them)

`project.yml` carries both, and they mean different things:

| Field | Becomes | Meaning | Changes when |
|---|---|---|---|
| `MARKETING_VERSION` | `CFBundleShortVersionString` | user-facing SemVer, e.g. `1.0.0` | each release |
| `CURRENT_PROJECT_VERSION` | `CFBundleVersion` | build number, must strictly increase | **every release**, and again for every App Store re-upload of the same version |

**Bump the build number on every release, not only on App Store uploads.** It is
a plain monotonic counter across all three channels: `1.0.0 (1)`, `1.1.0 (2)`,
`1.2.0 (3)`. Two reasons it is worth the extra edit:

- The About panel displays it as `Version 1.0.0 (1)`. Bumping only for the store
  would leave every Homebrew and direct-download build reading `(1)` forever,
  which is both wrong-looking and carries no information.
- It satisfies the App Store's strictly-increasing requirement for free, so a
  store submission never needs a separate bump to be valid.

The store adds one extra case on top: a rejected `1.0.0` (build 1), fixed and
resubmitted, is still `MARKETING_VERSION 1.0.0` but must go to
`CURRENT_PROJECT_VERSION 2` — the same version re-uploaded needs a new build
number. The Homebrew cask `version` tracks `MARKETING_VERSION` only; the build
number never appears in the cask.

## Git tags vs GitHub Releases (the mechanics)

Two different layers:

- **A git tag** is an immutable pointer to one commit — the marker that says
  "this commit is v1.0.0." Use **annotated** tags (`-a`) for releases (they carry
  a tagger, date, and message); lightweight tags are just names. Tags are local
  until pushed.
  ```bash
  git tag -a v1.0.0 -m "GPU Dock History 1.0.0"
  git push origin v1.0.0        # tags are NOT pushed by a plain git push
  ```
- **A GitHub Release** is a GitHub-layer object built on top of a tag: tag +
  title + release notes (changelog) + optional **attached binary assets** (the
  notarized `.app` zip). GitHub also auto-attaches a "Source code" archive. A tag
  can exist without a Release; a Release always references a tag (and can create
  one).
  ```bash
  gh release create v1.0.0 \
    GPU-Dock-History-1.0.0.zip \
    --title "GPU Dock History 1.0.0" \
    --notes "First release. Live GPU utilization history in the Dock."
  ```
  The attached zip is exactly what the Homebrew cask's `url` points at, and its
  `sha256` is the checksum of that file.

## Cutting a release (checklist)

1. Decide the new version from the merged Conventional Commits since the last tag
   (`fix` -> PATCH, `feat` -> MINOR).
2. Bump `MARKETING_VERSION` to the new SemVer, and increment
   `CURRENT_PROJECT_VERSION` by one — every release, not just store uploads.
3. Build, sign, notarize, staple, zip, and emit the cask in one step:
   ```bash
   ./scripts/release.sh
   ```
   It prints the artifact path, its SHA-256, and a filled-in cask file. Add
   `--adhoc` to rehearse the pipeline without a certificate (the result is not
   distributable), or `--skip-notarize` to stop after signing. The script needs
   only the Command Line Tools — **no Xcode.app** — so the store leg's toolchain
   requirements do not gate this channel.
4. Tag and push. With branch protection on `main`, tag the merge commit on `main`
   after the release PR merges:
   `git tag -a vX.Y.Z -m "…" && git push origin vX.Y.Z`
5. `gh release create vX.Y.Z <zip> --title "…" --notes "…"`
6. Homebrew: copy the emitted cask into `bbirkinbine/homebrew-tap` as
   `Casks/gpu-dock-history.rb`, commit and push. Verify with
   `brew update && brew livecheck --cask bbirkinbine/tap/gpu-dock-history`,
   which should report the new version. Full validation sequence and the
   `brew trust` requirement are in
   [HOMEBREW_DISTRIBUTION.md](HOMEBREW_DISTRIBUTION.md).
7. App Store, separately: Archive in Xcode, upload to App Store Connect, attach
   the build, submit. That leg does not use `release.sh`.

## When to automate

Hand-tagging is correct while releases are occasional. If cutting releases becomes
toil, move to `release-please`: merged Conventional Commits become a running
"release PR" that, when merged, tags and creates the GitHub Release with a
generated changelog. Not needed yet — adopt it only when hand-tagging starts to
hurt.

## Current status

**No tags yet, and that is correct** — no distributed build exists. The Apple
Developer Program membership is active (2026-07-27) and `scripts/release.sh`
exists and has been rehearsed end to end under `--adhoc` (2026-09-16), so the
remaining gap is exactly two credentials: a **Developer ID Application
certificate** and a **notarytool keychain profile** built from an app-specific
password. The script refuses to run without them and names the command that
creates each. `project.yml` holds the
placeholder `MARKETING_VERSION 1.0.0` / `CURRENT_PROJECT_VERSION 1` that the Apple
toolchain requires to build. The first tag and GitHub Release happen at first
distribution — which, per [DISTRIBUTION.md](DISTRIBUTION.md), is the Developer ID
channel rather than the App Store.
