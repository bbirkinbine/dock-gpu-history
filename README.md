# GPU Dock History

A tiny macOS app whose Dock icon is a live GPU utilization history graph — the GPU equivalent of Activity Monitor's "Show CPU History" dock icon. Built for Apple Silicon. Runs windowless; the dock tile is the entire UI.

Why: Activity Monitor can put **CPU** history in the Dock, but GPU History only exists as a floating window. When doing local LLM/AI work (MLX, Ollama, ComfyUI), a glanceable GPU graph in the Dock alongside the CPU one is what you actually want.

![Activity Monitor's CPU history dock icon (left) next to the GPU Dock History tile (right)](docs/dock-screenshot.png)

*Installed: Activity Monitor's CPU history (left) and GPU Dock History (right), side by side in the Dock.*

## How it works

- **Sampling** — reads `Device Utilization %` from the AGX accelerator's `PerformanceStatistics` dictionary in the IORegistry (public IOKit API, no sudo, no kexts). 1s interval, negligible overhead.
- **Display** — a custom `NSView` set as `NSApp.dockTile.contentView`, redrawn each sample: rounded black panel, green bars, 64-sample history, newest at the right.

## Quick start (dev build, no Xcode project)

```bash
./scripts/build.sh
open "build/GPU Dock History.app"
```

Requires Xcode Command Line Tools. Right-click the dock icon → Quit to stop. Add to **System Settings → General → Login Items** to keep it running.

`./scripts/verify.sh` builds and checks the sampling pipeline headlessly (`gpudockhistory --sample` prints utilization values without starting the app). If the graph stays flat under GPU load, run `./scripts/verify-iokit-key.sh`.

## Xcode / App Store build

The Xcode project is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open GPUDockHistory.xcodeproj
```

See `docs/APP_STORE_PUBLISHING.md` for the full path to Mac App Store submission.

## Repo layout

```
Sources/GPUDockHistory/   Swift sources (main.swift, GPUSampler, GPUHistoryView)
Resources/                Info.plist, entitlements
scripts/                  dev build, verify gate, IOKit key verification
docs/                     architecture, App Store publishing guide, screenshot
project.yml               XcodeGen spec (generates the .xcodeproj)
HANDOFF.md                handoff brief / task checklist for agent sessions
CLAUDE.md                 agent working context/conventions (AGENTS.md points here)
```

## Status

- [x] Core app written (sampler, dock tile view, app shell)
- [x] Verified on hardware (M2 Max): IOKit key present, builds, runs, sampler returns real values
- [x] Agentic loop ported from `agentic-scaffold` — see CLAUDE.md
- [ ] Visual polish confirmed under sustained GPU load (flicker, idle CPU)
- [ ] App icon + App Store assets
- [ ] Sandbox verification for MAS

## License

MIT

## Acknowledgements

This project was developed with the assistance of AI tools.
