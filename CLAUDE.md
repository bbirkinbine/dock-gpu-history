# CLAUDE.md — agent context for dock-gpu-history

> Persistent project context for Claude Code (and other AI coding agents)
> working in this repository. Read this before suggesting changes.
> `README.md` is for humans; this file is for the agent. `AGENTS.md` is a
> pointer stub for non-Claude agents. Machine-local preferences go in
> `CLAUDE.local.md` / `.claude/settings.local.json`, gitignored.

## What this is

A single-purpose macOS AppKit app: the Dock icon is a live GPU utilization
history graph (Activity Monitor CPU-history clone, but GPU). Swift, no
third-party dependencies, windowless by default with one optional
details/settings window. See docs/ARCHITECTURE.md.

## Environment facts

- Target machine: MacBook Pro M2 Max, 96GB, Apple Silicon only. macOS 13+.
- Dev build: `./scripts/build.sh` (swiftc, ad-hoc signed, no Xcode project).
- Store build: `xcodegen generate` from project.yml, then Xcode.
- This is NOT a Python project. uv/pytest conventions from other repos do not apply.

## Hard rules

- Public API only in anything that might ship to the App Store. No IOReport,
  no private frameworks, no sudo, no helper daemons.
- The dock tile is the product and stays primary. One optional
  details/settings window is permitted as a secondary surface (added
  2026-07-17): it opens on first launch and from the Dock menu, and closing it
  must never quit the app. Do not add further UI surfaces without asking.
- Stay dependency-free — no third-party dependencies. System frameworks
  (AppKit, Metal, IOKit, ServiceManagement) are fine and public-API-only.
- main.swift must stay named main.swift (top-level code entry point).
- Never commit signing identities. Team IDs in committed files are OK but
  keep DEVELOPMENT_TEAM commented in project.yml until publishing.
- Verify claims on hardware; don't assume IOKit keys — run
  scripts/verify-iokit-key.sh when touching GPUSampler.

## Conventions

- Swift 5.9+, AppKit (not SwiftUI — dock tile contentView is AppKit-native).
- Small files, one type per file.
- Markdown docs in docs/, Obsidian-friendly (plain md, no HTML).

## Commit / attribution style

- Conventional commits (`feat:`, `fix:`, `docs:`, `chore:`); body explains
  the why when non-obvious.
- **No `Co-Authored-By: Claude` (or any AI co-author) trailers** and no
  "Generated with Claude Code" footers in commits or PR descriptions. The
  `## Acknowledgements` section at the bottom of `README.md` carries the
  single AI-assistance acknowledgment (vendor-neutral wording, matching
  agentic-scaffold), mirrored by the `ai-assisted` GitHub topic.
  This overrides Claude Code's default behavior.
- Avoid emojis in repo files. Direct, technical tone.

## Public-repo hygiene

The repo is private today; treat it as **public from commit #1** — it may
flip later, and rewriting history after that is destructive. Applies to
file contents, commit messages, branch names, PR/issue text, and CI logs:

- No live credentials of any kind. If one ever lands in a commit, rotate
  it immediately.
- No employer references, internal hostnames, or coworker names.
- No identity-leaking absolute paths (`/Users/<name>/...`) in committed
  files — use `~/` or repo-relative paths.

## Validation gates before claiming done

```bash
bash -n scripts/*.sh        # shell syntax (shellcheck too, if installed)
./scripts/verify.sh         # build + headless sampler plausibility check
```

Both must pass for any change touching Sources/ or scripts/. Then:

1. Sweep `docs/` (and README) for statements the change made false.
2. Flag for Brian anything only eyes can verify: dock graph responds under
   GPU load, no flicker, ~0% CPU when idle. `verify.sh` proves the
   sampling pipeline, not the pixels.

## Don't touch

- `build/` — generated output, never committed.
- `Resources/Info.plist` `$(...)` build variables — the Xcode build
  substitutes them; build.sh inlines them via sed. Don't hardcode.
- `LICENSE`.

## Agentic loop

Plan → act → verify → reflect, sized to the task (a typo fix needs none
of this):

1. **Plan** — read the Open work section below; pick the top unchecked
   item; state the smallest verifiable change.
2. **Act** — make that change and nothing else.
3. **Verify** — run the validation gates above; anything hardware/visual
   gets flagged to Brian rather than assumed.
4. **Reflect** — update the Open work section below; update this file if
   a convention changed. (HANDOFF.md, the original takeover brief, was
   retired 2026-07-20 — this section is the single source of session
   state; the brief survives in git history.)

Ask Brian before: making the repo public, adding any UI, adding
dependencies, anything involving his Apple Developer account.

## Open work / current state (updated 2026-07-17)

- Done: IOKit key verified on M2 Max (`Device Utilization %` present);
  dev build compiles and runs; headless verify gate (`scripts/verify.sh`);
  git initialized and pushed to private GitHub repo; XcodeGen build (task 5);
  visual/idle-CPU check confirmed by Brian 2026-07-17 (no flicker, ~0.9%
  CPU idle, matches Activity Monitor beside it).
- Done (App Store prep, account-independent): AppIcon.appiconset generated
  by `scripts/make-icon.swift` (filled green GPU-history area chart in a
  macOS squircle tile) and wired into project.yml/Info.plist — structure
  validated locally, but the `actool`/`xcodebuild` compile is a CI gate (no
  local Xcode.app, same constraint as the sandbox gate). Privacy page
  (`docs/privacy-policy.md`) and store metadata + review notes
  (`docs/STORE_LISTING.md`) drafted.
- Done (4.2 mitigation): optional details/settings window (Option A) —
  Device Utilization % graph + big number, GPU memory-vs-budget gauge, GPU
  identity (name/38-core/budget), peak/avg + time-at-100% since Reset, and
  settings (sample interval 1/2/5s, graph color, launch-at-login via
  SMAppService). Chrome follows the system theme; the graph stays a dark
  scope. Renderer/Tiler and recoveryCount were tested on hardware and cut
  (unreliable / always-zero). New files: GPUInfo, SampleHistory, SessionStats,
  Preferences, HistoryScopeView, MeterView, DetailsView,
  DetailsWindowController. Compiles + headless verify passes; **window
  rendering/interaction still needs Brian's eyes** (not machine-verifiable).
- Done (sandbox / task 6, 2026-07-17): the App Sandbox does NOT block the
  IORegistry GPU read. Verified locally without full Xcode — ad-hoc-signed the
  dev build with the app-sandbox entitlement (genuinely enforced: a container
  was created), sampler returned 94/99% under GPU load. MAS path is viable;
  the Developer ID fallback is no longer forced. Recorded in
  docs/APP_STORE_PUBLISHING.md Section 0.
- Next: no code blockers remain. Open items are Brian's visual check of the
  window and the Apple-account steps below.
- Open (low priority): the details-window GPU-memory
  gauge uses `recommendedMaxWorkingSetSize`, cached once as a `static let`
  (GPUInfo.swift). Apple Silicon's GPU wired-memory ceiling is live-adjustable
  via `sudo sysctl iogpu.wired_limit_mb=<mb>` (`=0` resets). Verify on hardware
  whether that value tracks the sysctl; if so, re-read it live so the gauge
  denominator follows a bumped budget.
- Blocked on Brian: `DEVELOPMENT_TEAM` (needs Team ID + go), and everything
  needing his Apple account
  (enrollment, App Store Connect, screenshots, upload, submit). Privacy URL
  also needs hosting — Pages on a private repo requires a paid plan or a
  public repo (see docs/STORE_LISTING.md).
