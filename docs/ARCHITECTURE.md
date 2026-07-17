# Architecture

Deliberately minimal: three source files, no dependencies, no window.

## Components

```
main.swift            App entry. NSApplication setup, AppDelegate,
                      1s Timer -> sample -> push -> dockTile.display()
GPUSampler.swift      IOKit sampling. IOServiceMatching("IOAccelerator")
                      -> IORegistryEntryCreateCFProperties
                      -> PerformanceStatistics["Device Utilization %"]
GPUHistoryView.swift  NSView drawing the 64-sample bar graph.
                      Set as NSApp.dockTile.contentView.
```

## Key decisions

- **IORegistry over powermetrics**: `powermetrics` needs sudo and process spawning; registry reads are a cheap, unprivileged syscall path. This is the same source Stats/macmon-class tools use for utilization.
- **Dock tile over menu bar**: the whole point. `setActivationPolicy(.regular)` is required — LSUIElement/accessory apps have no dock tile.
- **Top-level main.swift**: works with both bare `swiftc` (scripts/build.sh) and the XcodeGen project. Don't convert to `@main` without keeping the file named main.swift or restructuring.
- **Ring buffer of 64**: matches dock icon pixel budget; one bar ≈ 2px at 128pt tile.

## Platform & build architecture

Apple-Silicon-only, enforced by two independent constraints:

- **Build architecture** — `scripts/build.sh` runs `swiftc` with no `-target`,
  so it compiles for the host architecture. On an Apple Silicon Mac that yields
  an **arm64-only** binary; it will not launch on Intel (an arm64 Mach-O cannot
  run on x86_64 — Rosetta only translates the other direction). The XcodeGen
  build pins `ARCHS: arm64` in `project.yml`, so the generated project and any
  archive are arm64-only too — see the App Store note below for why that matters.
- **GPU key** — `Device Utilization %` under `IOAccelerator` /
  `PerformanceStatistics` is the Apple Silicon AGX driver's format. Intel
  integrated GPUs (Iris/UHD) don't reliably publish it; AMD discrete GPUs do,
  but that path is untested and out of scope. So even a universal binary would
  only produce a meaningful graph on Apple Silicon.

Minimum macOS is 13.0 (`project.yml` `deploymentTarget`, `Info.plist`
`LSMinimumSystemVersion`), which excludes any older release regardless of arch.

## Known unknowns (verify on hardware)

1. Exact `PerformanceStatistics` key name can vary by macOS version/GPU
   ("Device Utilization %" is standard on Apple Silicon; alternatives seen
   in the wild include "GPU Activity(%)"). `scripts/verify-iokit-key.sh` checks.
2. Whether registry reads survive App Sandbox (matters only for Mac App Store).
3. Dock tile redraw cadence — 1s should be fine; confirm no visible flicker.

## Extension ideas (not yet built)

- Preferences window: sample rate, color, scale mode (helps App Review 4.2).
- Optional menu bar sparkline mirror.
- Multi-GPU (eGPU) stacked bars — relevant for the Razer Core X setup.
- ANE/memory-bandwidth overlays (would require IOReport private framework —
  keep out of any App Store build).
