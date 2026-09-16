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
                         (reopen handler). Clears history on
                         NSWorkspace.didWakeNotification.
GPUSampler.swift         IOKit sampling. IOServiceMatching("IOAccelerator")
                         -> IORegistryEntryCreateCFProperties
                         -> PerformanceStatistics["Device Utilization %"],
                         "Alloc system memory" and "In use system memory"
                         (GPUSample). Returns nil, not 0, when nothing
                         publishes the utilization key.
GPUHistoryView.swift     Dock-tile NSView: 64-sample bar graph, black panel.
                         Set as NSApp.dockTile.contentView. Reads SampleHistory.
SampleHistory.swift      Shared ring buffer (one source of truth for both views),
                         plus isAvailable and clear().
SessionStats.swift       Peak / average / time-at-100% since last Reset.
GPUInfo.swift            Identity (Metal name, IORegistry cores) + live memory
                         budget (iogpu.wired_limit_mb sysctl override, else
                         launch-time Metal recommendation).
Preferences.swift        UserDefaults: sample interval, graph color.

Details window (optional, secondary):
DetailsWindowController  Fixed, non-resizable, position-remembering window.
DetailsView.swift        Content: chrome uses semantic colors (follows theme).
HistoryScopeView.swift   Larger area+line graph on a fixed dark scope.
MeterView.swift          Rounded meter for the GPU-memory-vs-budget gauge:
                         two nested segments, allocated (dim) and active
                         (bright), separated by alpha not hue.
```

## Key decisions

- **IORegistry over powermetrics**: `powermetrics` needs sudo and process spawning; registry reads are a cheap, unprivileged syscall path. This is the same source Stats/macmon-class tools use for utilization.
- **Dock tile over menu bar**: the whole point. `setActivationPolicy(.regular)` is required — LSUIElement/accessory apps have no dock tile.
- **Optional window, not menu bar**: the details/settings window is a secondary surface for App Review 4.2 and to give the app a home (settings, reopen, first-run orientation). It is theme-adaptive except the graph, which stays a dark scope to match the tile. Closing it does not quit the app (no `applicationShouldTerminateAfterLastWindowClosed`).
- **Only reliable public stats are shown**: on this hardware `Renderer/Tiler Utilization %` returned identical/zero values under load and `recoveryCount` is always 0, so both were cut. Device Utilization %, GPU memory, and static identity are what remain. Power and temperature need private APIs and are out.
- **No per-process breakdown**, checked on hardware 2026-07-30. Per-process GPU *time* is public and unprivileged — every Metal-using process owns an `AGXDeviceUserClient` node carrying `IOUserClientCreator` (pid + name) and `AppUsage.accumulatedGPUTime`, and sampling it twice gives each process's share of GPU busy time. Per-process GPU *memory* does not exist anywhere: those client nodes publish no byte counts, and `powermetrics --show-process-gpu` is likewise time-only. Neither is shown here. Memory cannot be attributed honestly — the only proxy is RSS, which counts all resident memory, so a process list under a "GPU memory" heading would assign a number to a cause the data does not support. Time could be shown, but Activity Monitor already ships per-process `GPUUsage` and `GPUTime` columns, so cloning it would mean a sortable table inside the fixed 360pt window (a new UI surface) for a feature one Cmd-Tab away. What this app has that Activity Monitor does not is GPU memory at all — Activity Monitor shows none, at any granularity. The full survey, including the native tools that do answer "what is using my GPU", is in [GPU_TOOLS.md](GPU_TOOLS.md); `scripts/gpu-by-process.swift` covers the one case they miss (per-process GPU time from a terminal, no sudo).
- **Top-level main.swift**: works with both bare `swiftc` (scripts/build.sh) and the XcodeGen project. Don't convert to `@main` without keeping the file named main.swift or restructuring.
- **Memory leads with allocated, not in-use**: `PerformanceStatistics` publishes both `Alloc system memory` and `In use system memory`, and they are different quantities. Measured on the M2 Max (2026-07-29) by allocating 4 GiB of `.storageModeShared` buffers, faulting the pages in, then blitting between two of them: allocated moved +4.00 GB exactly and in-use did not budge; in-use rose only while a command buffer touched the buffers and fell back to baseline ~3s after the work finished; allocated dropped back when the owning process exited, so it is live rather than monotonic. The app originally showed in-use alone against the budget, which meant a Mac holding a 67 GB LLM in GPU memory read "0.5 GB in use" whenever inference paused — indistinguishable from a broken gauge, and pairing a transient wired figure with an allocation ceiling made the bar carry no information. The window now leads with allocated (the figure that answers "will a bigger model fit", and the one llama.cpp and MLX check against `recommendedMaxWorkingSetSize`) and shows in-use as the meter's bright inner segment plus a tinted caption. Allocated is system-wide across all processes, so its floor is never zero on a live Mac — which is why 0 is treated as "key absent" and rendered "—". Allocation is not residency, so allocated can in principle exceed the budget; the meter clamps, the numbers do not.
- **Absent statistics are not zero**: the utilization key is undocumented and verified on one machine, so a future OS, an unreleased GPU, or a paravirtualized GPU in a VM could stop supplying it. `GPUSampler` returns nil in that case rather than 0, `SampleHistory` records no sample and flips `isAvailable`, and the window replaces every live figure with "—" plus a "Statistics unavailable" caption. Without this the failure renders as a flat graph, which is pixel-identical to an idle GPU — the app would look like it worked. `--sample` prints `unavailable` for the same reason, and `verify.sh` fails on it. The converse is deliberately not an error: a real 0 is legitimate on an idle machine, so the gate does not fail on zero samples.
- **History is dropped on wake, not stitched**: samples are bare values whose age is inferred from position × sample interval, so a sleep gap misdates every buffered sample (the dock tile scrolls stale bars; the window's time axis lies). Clearing on `NSWorkspace.didWakeNotification` restarts the scope from the right edge, exactly as on a cold launch. `screensDidWake` is deliberately not used — display sleep leaves the machine awake and sampling. `SessionStats` is spared: it means "since launch or last Reset", and no samples were taken while asleep.
- **Ring buffer of 120**: the dock tile draws the last 64 (its pixel budget — one bar ≈ 2px at a 128pt tile); the window scope plots all 120. 120 rather than a power of two so the scope spans a round duration at every sample interval: 2:00 at 1s, 4:00 at 2s, 10:00 at 5s. Both views give each sample a fixed slot anchored to the right edge, so a partly-filled buffer scrolls in from the right instead of stretching to fill the width.

## Platform & build architecture

Apple-Silicon-only, enforced by two independent constraints:

- **Build architecture** — `scripts/build.sh` runs `swiftc` with no `-target`,
  so it compiles for the host architecture. On an Apple Silicon Mac that yields
  an **arm64-only** binary; it will not launch on Intel (an arm64 Mach-O cannot
  run on x86_64 — Rosetta only translates the other direction). The XcodeGen
  build pins `ARCHS: arm64` in `project.yml`, so the generated project and any
  archive are arm64-only too — see the App Store note below for why that matters.

  `-target` also carries the **deployment floor**, and omitting it is why the
  dev build must never be shipped: `swiftc` then stamps the host OS into
  `LC_BUILD_VERSION`, which `vtool -show-build-version` will report as e.g.
  `minos 26.0` even though `LSMinimumSystemVersion` claims 13.0 — a binary that
  refuses to launch on most of the range it advertises. `scripts/release.sh`
  pins `-target arm64-apple-macos13.0` for every distributable build, and the
  Xcode path gets the same floor from `deploymentTarget` in `project.yml`.
- **GPU key** — `Device Utilization %` under `IOAccelerator` /
  `PerformanceStatistics` is the Apple Silicon AGX driver's format. Intel
  integrated GPUs (Iris/UHD) don't reliably publish it; AMD discrete GPUs do,
  but that path is untested and out of scope. So even a universal binary would
  only produce a meaningful graph on Apple Silicon.

Minimum macOS is 13.0 (`project.yml` `deploymentTarget`, `Info.plist`
`LSMinimumSystemVersion`), which excludes any older release regardless of arch.

## Building from source

Three build paths, for three different purposes. All need the Xcode Command
Line Tools; only the third needs Xcode.app.

```bash
./scripts/build.sh                  # dev build -> build/GPU Dock History.app
open "build/GPU Dock History.app"
```

Ad-hoc signed, bundle identifier suffixed `.dev`, host deployment target. Fast
to iterate on and **not distributable** — see the deployment-floor note above.

```bash
./scripts/verify.sh                 # the machine-checkable gate
```

Builds, then checks the sampling pipeline headlessly: `gpudockhistory --sample N`
prints N utilization values without starting the app. Where the GPU statistics
cannot be read at all it prints `unavailable`, `verify.sh` fails, and the
details window says "Statistics unavailable" rather than showing 0% — then run
`./scripts/verify-iokit-key.sh` to check the IORegistry key directly.

```bash
./scripts/release.sh                # signed, notarized, stapled, packaged
```

The distributable build. Needs a Developer ID Application certificate and a
notarytool keychain profile; `--adhoc` rehearses the pipeline without either.
See [RELEASING.md](RELEASING.md).

For the App Store path only, the Xcode project is generated from `project.yml`
via [XcodeGen](https://github.com/yonaskolb/XcodeGen) — the generated
`.xcodeproj` is gitignored:

```bash
brew install xcodegen
xcodegen generate
open GPUDockHistory.xcodeproj
```

See [APP_STORE_PUBLISHING.md](APP_STORE_PUBLISHING.md) for the submission path
and [GPU_TOOLS.md](GPU_TOOLS.md) plus `scripts/gpu-by-process.swift` for
per-process GPU attribution from a terminal.

## Known unknowns (verify on hardware)

1. Exact `PerformanceStatistics` key name can vary by macOS version/GPU
   ("Device Utilization %" is standard on Apple Silicon; alternatives seen
   in the wild include "GPU Activity(%)"). `scripts/verify-iokit-key.sh` checks.
   No longer silent if it drifts: the app shows "Statistics unavailable" and
   `verify.sh` fails, instead of both reporting a healthy 0%. Only M2 Max has
   ever been checked — M1/M3/M4, Ultra parts, and macOS VMs are unverified.
2. ~~Whether registry reads survive App Sandbox~~ — verified 2026-07-17: they do
   (sandbox enforced via ad-hoc + entitlement, live values under load). See
   docs/APP_STORE_PUBLISHING.md Section 0.
3. Dock tile redraw cadence — 1s should be fine; confirm no visible flicker.

## Extension ideas (not yet built)

- Optional menu bar sparkline mirror.
- Multi-GPU (eGPU) stacked bars — relevant for the Razer Core X setup.
- ANE/memory-bandwidth overlays (would require IOReport private framework —
  keep out of any App Store build).
