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
  by `scripts/make-icon.swift` (green GPU-history area chart in a macOS
  squircle tile; redesigned 2026-07-27 — see the icon bullet below) and
  wired into project.yml/Info.plist — structure
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
- Done (2026-07-23): dock icon as details-window toggle.
  `applicationShouldHandleReopen` closes the window when visible and opens it
  otherwise. Handler returns false (default reopen handling would re-show
  the just-closed window); close goes through `window.close()` (red-button
  path, frame autosave keeps position); `showAndActivate()` now
  deminiaturizes first, fixing restore-from-Dock-shelf for the Dock-menu
  "Open" path too. Unchanged: first-launch auto-open, Dock/main-menu "Open"
  items stay open-only, closing never quits the app. Brian confirmed the
  click behavior on hardware. Amended 2026-07-27 — see the raise-if-buried
  entry below; the original pure-toggle tradeoff (buried window closes
  rather than raising) is no longer the behavior.
- Done (2026-07-27): dock click raises a buried window instead of closing it.
  Brian hit the predicted annoyance — clicking with the window open but
  behind other apps dismissed it, so it took two more clicks to see it. Now
  three outcomes: closed -> open, visible but app not frontmost -> raise and
  focus, visible and app already frontmost -> close. The catch is that a Dock
  click activates the app *before* AppKit calls the reopen handler, so
  `NSApp.isActive` is already true there and cannot report the pre-click
  state; AppDelegate tracks it via `applicationDidBecomeActive` /
  `applicationDidResignActive`, and treats the app as having been frontmost
  only if the flag is set *and* activation is older than 0.5s (the two
  signals together cover either ordering of activation vs. reopen, which is
  not contractual). Consequence: a second click inside 0.5s re-raises rather
  than closing. Brian confirmed on hardware.
- Done (2026-07-23, task 8): live GPU-memory budget. Hardware probe on the
  M2 Max settled the open question: `recommendedMaxWorkingSetSize` tracks the
  `iogpu.wired_limit_mb` sysctl but freezes per process at first Metal init
  (a fresh MTLDevice in the same process still returns the stale value; a
  fresh process returns the override exactly, e.g. 81920 MB). Fix: GPUInfo
  now reads the sysctl live (`sysctlbyname`, public API, sandbox-safe) and
  uses it as the budget when non-zero, falling back to the launch-time Metal
  value; subtitle appends "(custom)" while overridden. DetailsView re-reads
  on each refresh tick — already gated on window visibility, so windowless
  cost is zero. Known limit (documented in GPUInfo.swift): launching while
  an override is active bakes it into the fallback, so clearing the override
  then shows the stale value until relaunch. Headless check confirmed
  budget/subtitle follow a live sysctl change; Brian confirmed the live
  window update on hardware 2026-07-23 ("works"), which also prompted
  labeling the subtitle figure "GPU budget" (read like total RAM before).
  In-app slider to *set* the ceiling was
  considered and rejected: requires root (helper daemon / sudo), which the
  hard rules forbid and which would sink MAS eligibility.
- Done (2026-07-27): app-icon redesign ("silkscreen"), `scripts/make-icon.swift`
  rewritten. Brian's read of the old tile: amateurish, especially the sawtooth
  graph. Four tells fixed: (1) the plot was a floating rect inset from the tile
  — the trace now bleeds off both edges and its fill runs to the tile floor;
  (2) the series was a monotonic rising zigzag ("stonks") — now a plausible
  load shape (idle → ramp → sustained with a dip → second climb), Catmull-Rom
  smoothed; (3) iOS-6-era top gloss removed, soft contact shadow added;
  (4) the wordmark was rounded-heavy at 15.5% of the tile and near-opaque —
  now SF Pro semibold (explicitly not `.rounded`) at 10.5%, kern +16%, 62%
  white, and skipped below 64px rather than below 32px (at 32/16 it was a
  smudge; the trace alone carries those sizes). Chosen from 10 rendered
  variants across two rounds; alternates explored and rejected: column
  histogram (reads as an audio equalizer), silicon die with contact pads (too
  literal), radial gauge (drops the history idea, which is the product), light
  tile, and four other GPU-identity treatments (corner brackets, legend
  capsule, inline die glyph, large watermark). Rendering-only change — no
  Sources/ touched; `verify.sh` passes but proves nothing about the pixels.
  Landed on main via PR #12; Brian confirmed the Dock rendering on hardware
  (needed a relaunch of the app to shake the Dock's cached icon loose —
  `lsregister -f` + `killall Dock` alone did not do it).
- Done (2026-07-27): window-scope time axis corrected (branch
  `fix/scope-right-anchored`). Two bugs, both in the details window only —
  the dock tile was always right-anchored. (1) `HistoryScopeView` mapped
  samples as `width * i / (n-1)`, spreading whatever history existed across
  the full width, so the trace stretched and slid leftward until the buffer
  filled (~2 min at 1s, ~11 min at 5s, and again on every relaunch); it now
  uses fixed capacity-sized slots anchored right, mirroring
  `GPUHistoryView`'s slot math. (2) The time axis was hardcoded
  `−60s/−40s/−20s/now` while the scope actually spanned capacity × interval,
  so it never matched at any interval and never moved when the interval
  changed; labels are now computed from the real span. `SampleHistory`
  capacity 128 → 120 so those spans are round (2:00 / 4:00 / 10:00). Axis
  refresh rides on `syncControls()`, which both the window's own control and
  the Dock-menu path already call via `prefsChanged`. Also in this change:
  default sample interval 2s → 5s for parity with Activity Monitor, whose
  View > Update Frequency offers the same 1/2/5s choices and ships on
  "Normally (5 sec)" (confirmed against Apple's support doc, and Brian's own
  `com.apple.ActivityMonitor UpdatePeriod` reads 5). Consequence: out of the
  box the window scope spans 10:00 and the dock tile covers the most recent
  5:20 of it. Only affects installs with no stored `sampleInterval`.
- Done (2026-07-20): monetization research — `docs/MONETIZATION.md` (canonical)
  + vault mirror `Projects/dock-gpu-history/Monetization Options.md`, linked
  from the Publishing MOC. Recommendation: stay free, take donations outside
  the app (GitHub Sponsors + Ko-fi); any charging (incl. IAP tips) triggers
  Paid Apps agreement + EU trader status (public address/phone). Paid-MAS
  (Maccy model) deferred until traction. Landed on main via PR #7. Also
  covers: the App-Review-rejection fallback (Developer ID/Homebrew ships
  regardless; donation links then legal even in-app), the argued flat-$1
  case (verdict: never $1), and open-vs-closed posture (author unbound by
  own MIT grant; private-repo MIT = clean closed-binary distribution).
- Done (2026-07-27): Apple Developer Program membership renewed;
  `DEVELOPMENT_TEAM: G82L6VKCXZ` set in project.yml alongside
  `CODE_SIGN_STYLE: Automatic`. Verified by `xcodegen generate` — the Team ID
  lands in both Debug and Release configs of the generated pbxproj (which stays
  gitignored). CI is unaffected: it builds with `CODE_SIGNING_REQUIRED=NO`,
  which overrides the team. Committing the Team ID is fine — it is public on
  every shipped binary; the signing identity never enters the repo.
- Blocked on Brian, in order:
  1. **Install full Xcode.app** — the machine has Command Line Tools only, so
     `xcodebuild` will not run and there is no Archive/upload path. This gates
     every remaining step. Details in docs/APP_STORE_PUBLISHING.md Section 1.
  2. **Privacy Policy URL** — required field, still unhosted. Pages on a private
     repo needs a paid plan; options are make the repo public, a Gist/Netlify
     drop, or GitHub Pro (see docs/STORE_LISTING.md). Making the repo public is
     Brian's call.
  3. Everything needing his Apple account: register the bundle ID, create the
     App Store Connect record (the MAS app name must be globally unique — have a
     fallback if "GPU Dock History" is taken), screenshots at 2560x1600 or
     2880x1800 under real GPU load, archive, TestFlight, submit.
  Note: enrollment type sets the public developer name — Individual publishes
  under Brian's legal name (docs/STORE_LISTING.md covers the tradeoff).
