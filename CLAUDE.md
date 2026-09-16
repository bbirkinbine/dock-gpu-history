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
2. Flag anything only eyes can verify: dock graph responds under
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
   gets flagged for a human pass rather than assumed.
4. **Reflect** — update the Open work section below; update this file if
   a convention changed. (HANDOFF.md, the original takeover brief, was
   retired 2026-07-20 — this section is the single source of session
   state; the brief survives in git history.)

Ask the maintainer before: making the repo public, adding any UI, adding
dependencies, anything involving his Apple Developer account.

## Open work / current state (updated 2026-07-17)

- Done: IOKit key verified on M2 Max (`Device Utilization %` present);
  dev build compiles and runs; headless verify gate (`scripts/verify.sh`);
  git initialized and pushed to private GitHub repo; XcodeGen build (task 5);
  visual/idle-CPU check confirmed on hardware 2026-07-17 (no flicker, ~0.9%
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
  rendering/interaction still needs a visual check** (not machine-verifiable).
- Done (sandbox / task 6, 2026-07-17): the App Sandbox does NOT block the
  IORegistry GPU read. Verified locally without full Xcode — ad-hoc-signed the
  dev build with the app-sandbox entitlement (genuinely enforced: a container
  was created), sampler returned 94/99% under GPU load. MAS path is viable;
  the Developer ID fallback is no longer forced. Recorded in
  docs/APP_STORE_PUBLISHING.md Section 0.
- Next: no code blockers remain. Open items are a visual check of the
  window, the two queued items below, and the Apple-account steps further down.
- Queued (2026-08-07, from reading exelban/stats' README): two items,
  neither started, both gated by the same event — the repo going public.
  1. **Contribution policy, issue-first.** Stats' wording, verbatim: "Pull
     requests should only be opened for existing issues and after discussion;
     otherwise, they may be closed automatically," justified as "Stats is
     developed and maintained by a single person, and keeping the project stable
     and coherent takes priority over accepting every proposed change."
     Translations and language corrections are its stated exception. This repo
     has no CONTRIBUTING.md and no PR template. Beyond maintainer sanity there is
     a reason specific to this repo, already recorded in the (untracked, local-only) docs/MONETIZATION.md:
     the moment an outside contributor's code lands it is theirs, MIT-licensed
     *to* the maintainer, so relicensing or the Maccy paid-MAS option would then need
     their agreement. Issue-first is what keeps that door open, and it has to
     exist BEFORE the repo goes public — the first drive-by PR is too late.
     Put it in CONTRIBUTING.md rather than the README where Stats keeps it:
     GitHub surfaces CONTRIBUTING.md in the PR-compose sidebar and the issue
     "Contribute" link, which is where it actually gets read. Cross-link from
     the README.
  2. **Make the app localizable** — not: translate it. ~40 user-facing strings,
     all in the details window and the menus; the dock tile is a graph with no
     text, so localization never touches the primary surface. Wrap them in
     `String(localized:)` against an Xcode String Catalog (`.xcstrings` —
     Xcode-native, so no dependency; the 13.0 deployment target clears
     `String(localized:)`'s macOS 12 floor). Cheap now, linearly worse later.
     Two things to verify rather than assume: (a) `scripts/build.sh` is a bare
     swiftc build that cannot compile a catalog — the same seam already handled
     for the app icon — but an uncompiled catalog should fall back to the key,
     and the keys ARE the English text, so the dev build should be unaffected;
     (b) Info.plist currently has no `CFBundleDevelopmentRegion`.
     Honest limit: Stats carries 42 languages because it has 41k stars and a
     translator community. This repo has zero users and would ship English-only,
     possibly forever. The value is not the language count — it is that
     "translations welcome" in item 1 is an empty promise unless the app is
     localizable, and that the pass is small today. Separate and arguably higher
     leverage for a store app: App Store Connect *listing* localizations
     (description/keywords per locale) need no binary change at all — that
     belongs in docs/STORE_LISTING.md, not here.
- Done (2026-07-23): dock icon as details-window toggle.
  `applicationShouldHandleReopen` closes the window when visible and opens it
  otherwise. Handler returns false (default reopen handling would re-show
  the just-closed window); close goes through `window.close()` (red-button
  path, frame autosave keeps position); `showAndActivate()` now
  deminiaturizes first, fixing restore-from-Dock-shelf for the Dock-menu
  "Open" path too. Unchanged: first-launch auto-open, Dock/main-menu "Open"
  items stay open-only, closing never quits the app. Confirmed on hardware: the
  click behavior on hardware. Amended 2026-07-27 — see the raise-if-buried
  entry below; the original pure-toggle tradeoff (buried window closes
  rather than raising) is no longer the behavior.
- Done (2026-07-27): dock click raises a buried window instead of closing it.
  The predicted annoyance showed up in use — clicking with the window open but
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
  than closing. Confirmed on hardware.
- Done (2026-07-27): standard keyboard shortcuts. ⌘W and ⌘H did nothing
  because AppKit dispatches command keys by matching them against menu items,
  and the app menu held only Open / Reset Stats / Quit — the fix is menus, not
  key handling. App menu gained Hide (⌘H) / Hide Others (⌥⌘H) / Show All, and
  Reset Stats gained ⇧⌘R (not plain ⌘R: no undo, and ⌘R is a browser reflex).
  A Window menu (Close ⌘W, Minimize ⌘M, set as `app.windowsMenu`) exists
  solely to host those key equivalents — Close conventionally lives in a File
  menu, but this app has none and an empty File menu would be worse.
  `showAndActivate()` now unhides the app when hidden: the reopen handler
  returns false, so AppKit's default unhide-on-reopen never runs and a Dock
  click after ⌘H would otherwise leave the window off-screen. Sample-interval
  hotkeys were considered and rejected — they would require a Sample Rate
  submenu in the menu bar for a set-once preference already reachable from the
  window and the Dock menu, with no guessable mapping (⌘1/⌘2/⌘5 leaves gaps,
  positional ⌘1/⌘2/⌘3 reads wrong for "5 seconds"). Confirmed on
  hardware. Shortcuts only fire when the app has focus; Dock-menu items never
  take key equivalents.
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
  budget/subtitle follow a live sysctl change; Confirmed on hardware: the live
  window update on hardware 2026-07-23 ("works"), which also prompted
  labeling the subtitle figure "GPU budget" (read like total RAM before).
  In-app slider to *set* the ceiling was
  considered and rejected: requires root (helper daemon / sudo), which the
  hard rules forbid and which would sink MAS eligibility.
- Done (2026-07-27): app-icon redesign ("silkscreen"), `scripts/make-icon.swift`
  rewritten. The old tile read as amateurish, especially the sawtooth
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
  Landed on main via PR #12; Confirmed on hardware: the Dock rendering on hardware
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
  "Normally (5 sec)" (confirmed against Apple's support doc, and the local
  `com.apple.ActivityMonitor UpdatePeriod` reads 5). Consequence: out of the
  box the window scope spans 10:00 and the dock tile covers the most recent
  5:20 of it. Only affects installs with no stored `sampleInterval`.
- Done (2026-07-20): monetization research — `docs/MONETIZATION.md`, untracked
  and gitignored as of 2026-09-16 so the pricing deliberation stays private
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
- Done (2026-07-27, branch `fix/sampler-availability-and-sleep-gap`): three
  correctness fixes for conditions this machine cannot produce. (1) The sampler
  returned 0 both when the GPU was idle and when nothing published
  `Device Utilization %`, so a broken read rendered as a flat graph
  indistinguishable from a healthy idle GPU — on hardware nobody here can test
  (M1/M3/M4, Ultra parts, macOS VMs, a future OS that renames the key).
  `GPUSampler` now returns nil for absent, `SampleHistory.isAvailable` tracks
  it, the window shows "Statistics unavailable" with "—" for every live figure,
  `--sample` prints `unavailable`, and `verify.sh` fails on that. Note the gate
  deliberately does NOT fail on zero samples: a real 0 is legitimate when idle
  (the verify run during this change read `0 7 9`), so failing on zeros would
  be flaky — failing on *absent* is precise. Exercised by compiling GPUSampler
  against a deliberately bogus key name, which printed `unavailable`.
  (2) Sleep/wake: samples are bare values whose age is inferred from position ×
  interval, so after sleep the whole buffer was misdated — the tile scrolled
  stale bars and the window axis lied. Now cleared on
  `NSWorkspace.didWakeNotification` (system wake only; `screensDidWake` would
  discard a good buffer every time the display dozed). SessionStats is spared —
  it means "since launch or last Reset" and no samples were taken while asleep.
  (3) The window's two custom-drawn views (scope, memory meter) were invisible
  to VoiceOver; they now claim accessibility elementhood with live labels. The
  **dock tile itself has no accessibility fix** — the Dock process renders the
  tile and `NSDockTile` exposes only `badgeLabel`, so a label on the contentView
  would do nothing; adding a badge to carry it was rejected as visible clutter.
  Considered and dropped during this work: wiring `--sample` into CI (GitHub's
  `macos-latest` runners are Apple Silicon VMs, so it would answer the paravirt
  question exactly once and then assert nothing a build does not) and bounding
  `--sample`'s argument (hardening against a machine caller that would not
  exist once CI was dropped). Gates pass; **needs a visual check** on the window
  and on a real sleep/wake cycle.
- Done (2026-07-29, same branch, uncommitted): the memory gauge read the wrong
  counter. A 67 GB model loaded in LM Studio showed
  "GPU memory in use 0.5 GB" whenever inference paused, and 64.7 GB while it
  ran. Cause: the app read only `In use system memory`, which reports what a
  command buffer is touching *now*, not what is allocated — and paired it with
  an allocation ceiling, so the bar sat near-empty and carried no information.
  Measured on hardware (probe: allocate 4 GiB of `.storageModeShared`, fault the
  pages in, blit between two buffers): `Alloc system memory` moved +4.00 GB
  exactly with in-use flat, in-use rose only during the blit and decayed to
  baseline ~3s after, and allocated dropped back on process exit (live, not
  monotonic). Fix: `GPUSample` carries both figures; the window row is now
  "GPU memory allocated  67.4 GB · 78 GB budget" with in-use as the meter's
  bright inner segment (alpha, not a second hue) plus a tinted
  "0.8 GB active right now" caption under the bar. The caption is a separate
  line because one line holding both figures plus the budget measures 315pt of
  324pt available and overflows at three digits (192 GB Ultra, or any Mac
  mid-inference) — widths were measured, not eyeballed. Also: 0 allocated is
  now rendered "—" ("not reported on this Mac"), since a live Mac always has
  hundreds of MB allocated by WindowServer alone, so 0 means the key is absent
  — the same absent-vs-zero rule as the utilization guard. Considered and
  rejected: allocated-only (loses the "is it actually working" read that the
  bright segment gives for free) and label-only ("GPU memory active" keeps a
  meter that looks empty with a 67 GB model resident). Gates pass;
  **needs a visual check** on the two-segment bar in both themes, and
  `docs/details-window.png` in the README is now stale (shows the old row).
- Done (2026-07-30): `docs/GPU_TOOLS.md` + `scripts/gpu-by-process.swift`, from
  the question of how to see which processes hold GPU memory. Answer, verified on
  hardware: **you cannot** — no macOS interface publishes per-process GPU
  memory. `AGXDeviceUserClient` nodes (one per Metal process) carry only
  `IOUserClientCreator`, `AppUsage.accumulatedGPUTime` and `CommandQueueCount`;
  `powermetrics --show-process-gpu` is time-only per its own help; `vmmap` on a
  process holding a 67 GB model shows `IOAccelerator (graphics) 7456K`, because
  the driver wires the buffers on its behalf. Per-process GPU *time* is public
  and unprivileged, but Activity Monitor already ships GPU/GPU Time columns
  (his own prefs sort by `GPUUsage`), so putting either in the app was rejected:
  memory cannot be attributed honestly (RSS is all resident memory) and time
  would mean a sortable table in the fixed 360pt window — a new UI surface for
  a shipped feature. The script covers the one real gap, per-process GPU time
  from a terminal with no sudo. Written in Swift against IOKit, not the original
  Python parsing `ioreg` text, which produced two bugs while being written
  (brace-matching merged client nodes and misattributed their sums; filtering
  after a top-N truncation hid every real GPU user). Also documents the
  Activity Monitor trap the LLM case exposes: the default Memory column is
  footprint, which excludes mmap'd model weights — 4.8 GB against 59.1 GB RSS
  for the same process; Real Memory has to be added by hand.
- Done (2026-07-30): `gpu-by-process.swift` gained `--sort gpu|total|rss` plus
  `--help`, and a shebang + exec bit (how to run a non-bash script was
  undocumented, and the invocation was buried in a file comment). The flag is
  `rss`, not `gpu-memory`: naming it after GPU memory would reintroduce exactly
  the false attribution GPU_TOOLS.md exists to refute. `--sort rss` also widens
  the listing — the GPU-activity sorts hide processes that have never run GPU
  work, but a model loaded and not yet queried holds tens of gigabytes at zero
  GPU time, so under `rss` every Metal client is listed. Unreadable RSS sorts
  last rather than as zero.
- Done (2026-07-30): `docs/details-window.png` refreshed from a fresh screenshot
  (the old one predated both the memory-row change and PR #13's time axis).
  Cropped to the detected window bounds and re-clipped to a rounded rect so the
  window behind it stops bleeding into the top-right corner.
- Done (2026-07-30): README's two hero images collapsed into one
  (`docs/dock-and-details-window.png`) — the frame holds the
  details window *and* the Dock strip below it, where Activity Monitor's CPU
  tile sits beside the GPU tile, so a single image carries what the pair
  carried. Left uncropped on purpose: the dock context is the point, and the
  window's own rounded corners land against the desktop, so no re-clipping was
  needed (unlike the window-only shot above). Re-encoded to drop EXIF/XMP and
  flatten the fully opaque alpha (326 KB -> 221 KB); pixels verified identical
  to the capture, and the chunk list is now IHDR/iCCP/IDAT/IEND only — `eXIf`,
  the XMP `iTXt`, `pHYs`, `cICP` and `iDOT` are gone. `iCCP` is kept
  deliberately: macOS captures in the display's color space, so dropping the
  profile would shift the greens in browsers that honor it; the profile is a
  generic Apple "Display" one carrying no serial or device string. Screenshot
  xattrs (`kMDItemScreenCaptureGlobalRect` et al.) do not survive `git add`.
  `docs/dock-tile.png` and `docs/details-window.png` were deleted — nothing
  referenced them once the README collapsed to one image. `docs/dock-screenshot.png`
  was kept: unused in any page, but `docs/STORE_LISTING.md` names it when
  explaining why the store still needs a fresh full-size capture.
- Done (2026-09-16, branch `feat/release-pipeline`): `scripts/release.sh` — the
  channel-1/2 pipeline in one command (build, sign, notarize, staple, zip,
  sha256, and emit the filled-in cask from the new `packaging/gpu-dock-history.rb.in`).
  Rehearsed end to end with `--adhoc`; the artifact verifies as
  `flags=0x10002(adhoc,runtime)` with the sandbox entitlement, arm64, correct
  bundle ID. Three findings worth keeping:
  (1) **The bare swiftc build stamped the host OS as the deployment floor** —
  `vtool` showed `minos 26.0` on the dev binary while `LSMinimumSystemVersion`
  claimed 13.0, so a shipped build would have refused to launch on anything
  below macOS 26. `release.sh` passes `-target arm64-apple-macos13.0`; the
  sources compile clean against it, so no availability guards were missing.
  (2) **`MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` were dead settings** —
  `Resources/Info.plist` hardcoded `1.0.0`/`1` instead of referencing them, so
  RELEASING.md's "bump project.yml" step would have silently shipped the old
  version. The plist now uses `$(MARKETING_VERSION)`/`$(CURRENT_PROJECT_VERSION)`
  and both build.sh and release.sh inline them from project.yml, matching how
  the bundle ID already worked.
  (3) **Channels 1-2 need no Xcode.app at all** — only the Command Line Tools,
  which carry swiftc, codesign, notarytool and stapler. `actool` is the sole
  gap, so the icon goes through `iconutil` as an `.icns` exactly as build.sh
  does it. Full Xcode is a channel-3 requirement only; DISTRIBUTION.md updated.
  Kept that way on purpose even though Xcode is installed: `actool` would make
  the artifact byte-match the store build's icon, but at the cost of an
  Xcode.app dependency in the release path for a result that renders the same.
  Revisit only if the store leg and the cask leg ever visibly diverge.
  Xcode 27.0's license was unaccepted until 2026-09-16 (it gates every
  `xcrun`/`swiftc` routed through Xcode.app, `build.sh` and `verify.sh`
  included); it was accepted, and both gates plus the `--adhoc` rehearsal were
  re-run against Xcode's toolchain (Swift 6.4, SDK 27.0) with identical results —
  `minos 13.0`, arm64, `flags=0x10002(adhoc,runtime)`. release.sh's fallback to
  the Command Line Tools stays as insurance.
  Docs swept: RELEASING.md checklist, HOMEBREW_DISTRIBUTION.md (cask is now
  generated, not pasted), DISTRIBUTION.md. Gates pass. **Needs a human pass**: the two
  credentials above, then a real `./scripts/release.sh` run, then eyes on the
  signed app launching from /Applications (SMAppService launch-at-login is
  signature- and location-sensitive, so it is worth re-testing there).
- Done (2026-08-07): distribution model decided, `docs/DISTRIBUTION.md` written
  as the hub. Maintainer's call, prompted by looking at how exelban/stats ships:
  take Stats' channels and **add the Mac App Store, because this app can and
  Stats cannot**. Stats is off the store by constraint, not preference — it
  installs a privileged SMC helper daemon (`eu.exelban.Stats.SMC.Helper`) that
  the sandbox forbids, whereas the 2026-07-17 sandbox check proved this app
  reads IORegistry fine inside a container. So: free everywhere, public MIT
  repo, donations off-store only (posture 2 in docs/EXAMPLE_REPOS.md, eul is the
  working demo), one sandboxed build through three channels — GitHub Releases
  (the artifact), a Homebrew cask pointing at it, and the MAS. Four consequences
  recorded because none is obvious: (1) one sandboxed configuration for all
  three, since the sandbox costs nothing here and a second unsandboxed build
  would double the test surface; (2) **no in-app updater ever** — Sparkle is a
  third-party dependency and the hard rules forbid it, so `brew upgrade` is the
  update path for the direct channel and a hand-downloaded zip has none, which
  is why install docs must lead with Homebrew; (3) a machine with both the store
  copy and the cask copy has two bundles claiming the same identifier —
  `conflicts_with` cannot see a MAS install, so the cask carries a `caveats`
  block instead; (4) the ordering below inverts, because Developer ID needs far
  less than the store does. RELEASING.md already assumed one version across
  channels, so it needed only pointers. Docs-only change; no Sources/ touched.
- Blocked on maintainer action, in order (channels 1-2 first — see docs/DISTRIBUTION.md):
  1. ~~Developer ID Application certificate~~ **DONE 2026-09-16** —
     `Developer ID Application: Brian Birkinbine (G82L6VKCXZ)` is in the login
     keychain and `./scripts/release.sh --skip-notarize` produces a properly
     signed bundle: `flags=0x10000(runtime)`, chain Developer ID Application ->
     Developer ID Certification Authority -> Apple Root CA, secure timestamp
     present, `TeamIdentifier=G82L6VKCXZ`. `spctl` reports
     `rejected / source=Unnotarized Developer ID`, which is the correct
     remaining state.
     **Caveat worth a January reminder: the cert expires 2027-02-01**, not the
     usual five years. Apple issued it under the legacy `Developer ID
     Certification Authority`, whose own `notAfter` is `Feb 1 22:12:15 2027`, so
     the leaf is clamped to its issuer (the G2 intermediate, good to 2031, is in
     the keychain but was not used). Harmless for shipped builds — a notarized
     signature carries a secure timestamp and Gatekeeper validates against
     signing time, so anything notarized before that date keeps working
     indefinitely — but a new Developer ID cert is needed to sign new builds
     after it. Deliberately NOT re-issued now to chase a G2 chain: speculative,
     and Apple caps the account at 5 Developer ID certs ever.
  1b. ~~notarytool keychain profile~~ **DONE 2026-09-16** — profile
     `gpu-dock-history-notary` stored and validated. Gotcha that cost a 401:
     the Developer Program Apple ID is NOT the git/commit address, and the
     app-specific password must be generated while signed in as the developer
     Apple ID (one made under a different ID fails with the same
     `HTTP 401 Invalid credentials`). Nothing on disk reveals which Apple ID
     owns the account — Xcode keeps it in an unreadable token — so ask rather
     than infer. The address itself stays out of this file on purpose
     (public-repo hygiene); it is in the agent's local memory.
  1c. **First notarized build exists (2026-09-16)** — `./scripts/release.sh`
     ran clean end to end: submission `4908b162-5942-43ad-925a-55d62f347cbb`,
     status **Accepted**, stapled, `spctl` reports
     `accepted / source=Notarized Developer ID`. Verified the way a downloader
     sees it, not just in place: the zip was extracted to a clean directory, a
     `com.apple.quarantine` xattr applied, and Gatekeeper still accepted it —
     so the stapled ticket survives the zip round trip and the app launches
     offline with no right-click-Open. Artifact:
     `GPU-Dock-History-1.0.0.zip`, 660K,
     sha256 `c225ddacbb8b174ae68faa55020644748609d0a77ab79efe10166438f3404d1d`.
     Nothing was published — no tag, no GitHub Release, no cask, no store
     upload; `release.sh` only prints the `gh release create` line for the
     maintainer to run. **Not yet done: a visual check of the notarized bundle** (launch from
     /Applications, dock tile, details window, and SMAppService launch-at-login,
     which is signature- and location-sensitive and has only ever been exercised
     by the ad-hoc `.dev` bundle).
  2. **Make the repo public** — a precondition for the cask, not a nicety: a
     Homebrew cask fetches its artifact unauthenticated, and release assets on a
     private repo require an authenticated request. It also collapses blocker 3,
     since Hidden Bar's accepted store privacy-policy URL is just a markdown
     file in its repo (docs/EXAMPLE_REPOS.md, "Incidental find").
  3. **Privacy Policy URL** — now blocks the **store leg only**, and going
     public solves it for free. Otherwise a Gist/Netlify drop or GitHub Pro
     (see docs/STORE_LISTING.md).
  4. Everything else needing his Apple account, store-only: register the bundle
     ID, create the App Store Connect record (the MAS app name must be globally
     unique — have a fallback if "GPU Dock History" is taken), screenshots at
     2560x1600 or 2880x1800 under real GPU load, archive, TestFlight, submit.
  Note: enrollment type sets the public developer name. **Confirmed Individual**
  (2026-09-16) — Xcode's cached team record reads `teamType = Individual`,
  `isFreeProvisioningTeam = 0`, `teamName = "Brian Birkinbine"`, and the existing
  Apple Development cert carries `O=Brian Birkinbine, OU=G82L6VKCXZ`. Two
  consequences: the role question on blocker 1 cannot fail (an Individual team
  has one member holding every role, Account Holder included), and a store
  listing would publish under his legal name (docs/STORE_LISTING.md covers that
  tradeoff). Useful probe, no network or login needed:
  `defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier`.
