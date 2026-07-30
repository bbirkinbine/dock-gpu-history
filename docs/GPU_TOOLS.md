# Seeing GPU usage on Apple Silicon

What is using the GPU, and who is holding its memory — answered with what
macOS already ships, plus one script in this repo for the case none of them
cover. Everything here was verified on an M2 Max on 2026-07-30; the IORegistry
keys are undocumented and may change between OS releases.

The short version:

| Question | Best tool |
|---|---|
| Which processes are using the GPU right now | Activity Monitor, GPU column |
| Same, from a terminal, no sudo | `./scripts/gpu-by-process.swift` |
| Same, with power and frequency | `sudo powermetrics --samplers gpu_power --show-process-gpu` |
| How much GPU memory is committed system-wide | This app's details window |
| How much GPU memory **a given process** holds | Not available on macOS — see below |

## Activity Monitor (native, no sudo)

Per-process GPU **time** is a shipped feature and most people miss it because
the columns are off by default:

- **CPU tab -> View > Columns -> GPU** and **GPU Time**. GPU is the share of
  the GPU a process is using now; GPU Time is its cumulative total.
- **Window > GPU History** draws the system-wide utilization graph. It is a
  window only — unlike CPU History, it cannot go in the Dock, which is the
  reason this app exists.

For memory there is a trap worth knowing about. The Memory tab's default
**Memory** column shows *footprint*, which excludes clean file-backed pages.
A local LLM usually mmaps its weights from a model file, so footprint reports a
fraction of what the process actually holds resident:

```
llama-server, 67 GB model loaded
  Memory (footprint)   4.8 GB      <- Activity Monitor's default column
  Real Memory (RSS)   59.1 GB      <- the weights
```

Add **Real Memory** via View > Columns or the default column will understate a
loaded model by more than tenfold.

## powermetrics (native, sudo)

```bash
sudo powermetrics --samplers gpu_power --show-process-gpu -n 1
```

`--show-process-gpu` is documented in `powermetrics --help` as "show
per-process gpu time" — time, not memory. The `gpu_power` sampler also reports
GPU frequency and residency, which nothing else exposes without private APIs.

## scripts/gpu-by-process.swift (this repo, no sudo)

A Swift script, not a shell one — it runs through the Swift interpreter that
ships with the Command Line Tools, so expect a second or two of compilation
before it starts sampling. The argument is the sampling window in seconds
(default 2). Both forms work:

```bash
./scripts/gpu-by-process.swift 3        # executable, via the shebang
swift scripts/gpu-by-process.swift 3    # equivalent
```

```
$ ./scripts/gpu-by-process.swift 3
GPU busy time over 3s, by process (IORegistry AppUsage, no sudo)
   GPU%   GPU s (total)        RSS      PID  process
  0.46%        18142.6s          —      420  WindowServer
  0.38%          229.3s      0.2GB    46484  cmux
  0.00%           42.2s     63.3GB    64563  llama-server
```

Fills the one gap the native tools leave: per-process GPU time in a terminal
without sudo, so it works over SSH and in scripts. Every Metal-using process
owns an `AGXDeviceUserClient` node in the IORegistry carrying
`IOUserClientCreator` (pid and name) and `AppUsage.accumulatedGPUTime`;
sampling twice and diffing gives each process's share.

Reading notes:

- **RSS is not GPU memory.** It is everything the process holds resident. It is
  in the table because on unified memory a process's GPU buffers are counted in
  it, which makes it a useful lead — the `llama-server` row above is how you
  find the owner of a large allocation. It is not an attribution.
- **A dash means unreadable, not zero.** WindowServer runs as `_windowserver`,
  so `proc_pidinfo` refuses it. Printing 0.0 GB there would read as "holds no
  memory", which is the opposite of the truth.
- Names come from the kernel's 16-character `comm`, so longer ones are
  truncated ("Google Chrome He").

## What is not available: per-process GPU memory

No macOS interface reports how much GPU memory a given process holds. This is
not a permissions problem or a private-API problem — the data is not published:

- The `AGXDeviceUserClient` nodes carry only `IOUserClientCreator`, `AppUsage`
  and `CommandQueueCount`. No byte counts, on any of them.
- `powermetrics --show-process-gpu` is time-only, per its own help text.
- `vmmap` sees almost nothing. For a process holding a 67 GB model:
  `IOAccelerator 64K`, `IOAccelerator (graphics) 7456K`. The buffers are wired
  by the driver on the process's behalf and do not appear as its own mapped
  regions.
- Activity Monitor has no GPU memory column, at any granularity.

So any per-process "GPU memory" figure is really RSS wearing a different label,
and RSS counts all resident memory — a browser with 700 MB resident is holding
almost no GPU memory. Use the system-wide total to learn that memory is
committed, then RSS to find the likely owner, and keep the two ideas separate.

## Where this app fits

The details window shows the system-wide figures that Activity Monitor omits
entirely:

```
GPU memory allocated          67.4 GB · 78 GB budget
0.5 GB active right now
```

**Allocated** is what processes have committed, and it is what tells you
whether a bigger model or scene will fit. **Active** is what the GPU is
touching right now; it collapses to well under a gigabyte within seconds of
work finishing, even with tens of gigabytes still allocated. Both come from
`PerformanceStatistics` (`Alloc system memory` and `In use system memory`) —
see docs/ARCHITECTURE.md for the measurements that pin down the difference.
