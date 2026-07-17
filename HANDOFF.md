# HANDOFF.md — Claude Code takeover brief

**From:** Claude (claude.ai chat session, 2026-07-17)
**To:** Claude Code CLI, running locally in this repo on Brian's M2 Max MacBook Pro
**Repo:** `~/Downloads/src/bbirkinbine/dock-gpu-history`

## Context

Brian wants a macOS app whose Dock icon is a live GPU utilization history graph — exactly like Activity Monitor's "Show CPU History" dock icon, but for the GPU. No other features. Motivation: local LLM/AI work (MLX, Ollama, ComfyUI) where glanceable GPU load matters.

The chat session produced the full app and repo structure, but **ran in a Linux sandbox with no macOS toolchain and no access to this machine** — so nothing here has been compiled or run on hardware. That's your job. Everything below marked UNVERIFIED needs empirical confirmation.

## Current state

Written and believed-correct, but unverified on hardware:

- `Sources/GPUDockHistory/` — GPUSampler (IOKit), GPUHistoryView (dock tile drawing), main.swift (app shell). ~150 lines total.
- `scripts/build.sh` — swiftc dev build → ad-hoc-signed .app bundle.
- `scripts/verify-iokit-key.sh` — checks the IORegistry key exists on this machine.
- `project.yml` — XcodeGen spec for the App Store path (sandbox + hardened runtime).
- `Resources/` — Info.plist (build-variable style), entitlements (sandbox enabled).
- `docs/APP_STORE_PUBLISHING.md` — full MAS submission path + Developer ID fallback.
- `docs/ARCHITECTURE.md`, `CLAUDE.md`, CI workflow, MIT license, .gitignore.

Git is NOT initialized (chat session couldn't know if this dir already had history).

## Tasks, in order

### 1. Port the agentic loop from agentic-scaffold
The chat session could not read `~/Downloads/src/bbirkinbine/agentic-scaffold` (sandboxed, repo not public). You can. Read it, extract the agentic loop structure (the plan/act/verify/reflect cycle, task tracking, whatever conventions Brian built there), and adapt it for this repo:
- Skip all Python-specific parts (this is a Swift/AppKit project — no uv, no pytest).
- Land the adapted loop in `CLAUDE.md` (replace the placeholder "Agentic loop" section) and any companion files the scaffold uses (e.g., task/state files), keeping the same file naming conventions the scaffold uses so Brian's muscle memory transfers.
- The verify step for this repo is: `./scripts/build.sh` succeeds + app launches + dock graph responds to GPU load.

### 2. Verify the IOKit sampling key — UNVERIFIED
```bash
./scripts/verify-iokit-key.sh
```
`GPUSampler.utilization()` reads `PerformanceStatistics["Device Utilization %"]` from `IOAccelerator`. This is the standard key on Apple Silicon but names vary by macOS version (alternatives seen: `"GPU Activity(%)"`). If the key differs on this machine, fix `GPUSampler.swift`. Consider making the sampler try a small ordered list of known key names.

### 3. First build and hardware test — UNVERIFIED
```bash
./scripts/build.sh && open "build/GPU Dock History.app"
```
Then generate GPU load (an Ollama prompt or MLX run) and confirm the dock bars respond. Check: no flicker, ~0% CPU when idle, right-click → Quit works. Fix anything that doesn't survive contact with reality — the drawing math, tile sizing, and `dockTile.display()` cadence are the likely suspects.

### 4. Initialize the repo and push to GitHub
If this directory has no `.git`:
```bash
git init && git add -A && git commit -m "feat: initial GPU dock history app"
gh repo create bbirkinbine/dock-gpu-history --public --source=. --push
```
(Adjust `--public`/`--private` per Brian's call — ask him.) Confirm CI passes on the macos runner; fix the workflow if xcodegen/xcodebuild flags have drifted.

### 5. XcodeGen project sanity — UNVERIFIED
```bash
brew install xcodegen  # if needed
xcodegen generate
xcodebuild -project GPUDockHistory.xcodeproj -scheme GPUDockHistory -configuration Release CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build
```
The project.yml was written blind; expect minor fixes (scheme name, Info.plist path resolution).

### 6. Sandbox check (gates the App Store path)
Build via the Xcode project WITH the sandbox entitlement, run, and confirm the graph still moves under load. Record the result in docs/APP_STORE_PUBLISHING.md Section 0. If sandbox blocks the IORegistry read, the MAS path is dead and the Developer ID fallback (documented there) becomes the plan.

### 7. App Store prerequisites (only if Brian says go)
- App icon: `Assets.xcassets` with full AppIcon set (1024 master). Ask Brian for art direction or generate a placeholder.
- Consider the small preferences window suggested in docs/APP_STORE_PUBLISHING.md Section 0 (App Review 4.2 mitigation) — get Brian's sign-off before adding UI; it violates the "windowless" rule in CLAUDE.md, which should then be amended.

## Rules of engagement

- Follow `CLAUDE.md`. Public APIs only, no dependencies without asking, Swift stays minimal.
- Ask Brian before: making the repo public, adding any UI, adding dependencies, anything involving his Apple Developer account.
- Update this file's checkboxes as you go; it's the shared state between sessions.

## Task checklist

- [x] 1. Agentic loop ported from agentic-scaffold (slim port: CLAUDE.md conventions + AGENTS.md stub + scripts/verify.sh gate; specs/ADR machinery deliberately skipped — wrong scale for this repo)
- [x] 2. IOKit key verified on M2 Max — `Device Utilization %` present in PerformanceStatistics
- [x] 3. Dev build runs, sampler returns real values (95/96/94 under load via `--sample`); visual polish confirmed by Brian 2026-07-17 — no flicker, black with small bottom bars at idle, matches Activity Monitor's look sitting next to it; measured ~0.9% CPU idle (0% between 1s sample ticks)
- [x] 4. Git initialized, pushed to GitHub (private repo), CI green on first run
- [x] 5. XcodeGen project builds — needed a schemes section in project.yml (XcodeGen writes no scheme files without one); xcodegen generate verified locally, xcodebuild verified in CI (no local Xcode.app)
- [ ] 6. Sandbox verification result recorded
- [ ] 7. App Store prerequisites (icon, 4.2 mitigation) — pending Brian's go
