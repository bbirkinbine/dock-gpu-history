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
