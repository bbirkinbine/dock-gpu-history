# Architecture

Deliberately minimal: no third-party dependencies. The dock tile is the
product; an optional details/settings window is a secondary surface.

## Components

```
main.swift               App entry + AppDelegate. Timer (interval from
                         Preferences) -> GPUSampler.sample() -> SampleHistory +
                         SessionStats -> dockTile.display() + window refresh.
                         Dock menu, app + Window menus (the latter exists only
                         to give the standard shortcuts something to match:
                         AppKit dispatches command keys through menu items),
                         first-launch window; dock-icon click raises the window
                         if buried, closes it if it was already frontmost
                         (reopen handler).
GPUSampler.swift         IOKit sampling. IOServiceMatching("IOAccelerator")
                         -> IORegistryEntryCreateCFProperties
                         -> PerformanceStatistics["Device Utilization %"]
                         and "In use system memory" (GPUSample).
GPUHistoryView.swift     Dock-tile NSView: 64-sample bar graph, black panel.
                         Set as NSApp.dockTile.contentView. Reads SampleHistory.
SampleHistory.swift      Shared ring buffer (one source of truth for both views).
SessionStats.swift       Peak / average / time-at-100% since last Reset.
GPUInfo.swift            Identity (Metal name, IORegistry cores) + live memory
                         budget (iogpu.wired_limit_mb sysctl override, else
                         launch-time Metal recommendation).
Preferences.swift        UserDefaults: sample interval, graph color.

Details window (optional, secondary):
DetailsWindowController  Fixed, non-resizable, position-remembering window.
DetailsView.swift        Content: chrome uses semantic colors (follows theme).
HistoryScopeView.swift   Larger area+line graph on a fixed dark scope.
MeterView.swift          Rounded meter for the GPU-memory-vs-budget gauge.
```

## Key decisions

- **IORegistry over powermetrics**: `powermetrics` needs sudo and process spawning; registry reads are a cheap, unprivileged syscall path. This is the same source Stats/macmon-class tools use for utilization.
- **Dock tile over menu bar**: the whole point. `setActivationPolicy(.regular)` is required — LSUIElement/accessory apps have no dock tile.
- **Optional window, not menu bar**: the details/settings window is a secondary surface for App Review 4.2 and to give the app a home (settings, reopen, first-run orientation). It is theme-adaptive except the graph, which stays a dark scope to match the tile. Closing it does not quit the app (no `applicationShouldTerminateAfterLastWindowClosed`).
- **Only reliable public stats are shown**: on this hardware `Renderer/Tiler Utilization %` returned identical/zero values under load and `recoveryCount` is always 0, so both were cut. Device Utilization %, GPU memory, and static identity are what remain. Power/temp/per-process need private APIs and are out.
- **Top-level main.swift**: works with both bare `swiftc` (scripts/build.sh) and the XcodeGen project. Don't convert to `@main` without keeping the file named main.swift or restructuring.
- **Ring buffer of 120**: the dock tile draws the last 64 (its pixel budget — one bar ≈ 2px at a 128pt tile); the window scope plots all 120. 120 rather than a power of two so the scope spans a round duration at every sample interval: 2:00 at 1s, 4:00 at 2s, 10:00 at 5s. Both views give each sample a fixed slot anchored to the right edge, so a partly-filled buffer scrolls in from the right instead of stretching to fill the width.

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
2. ~~Whether registry reads survive App Sandbox~~ — verified 2026-07-17: they do
   (sandbox enforced via ad-hoc + entitlement, live values under load). See
   docs/APP_STORE_PUBLISHING.md Section 0.
3. Dock tile redraw cadence — 1s should be fine; confirm no visible flicker.

## Extension ideas (not yet built)

- Optional menu bar sparkline mirror.
- Multi-GPU (eGPU) stacked bars — relevant for the Razer Core X setup.
- ANE/memory-bandwidth overlays (would require IOReport private framework —
  keep out of any App Store build).
