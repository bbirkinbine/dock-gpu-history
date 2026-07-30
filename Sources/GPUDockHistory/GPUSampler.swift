import Foundation
import IOKit

/// One reading of GPU state. The two memory figures are different quantities
/// and neither substitutes for the other — see `GPUSampler` for the
/// measurements that pin down what each one means.
struct GPUSample {
    let utilization: Double            // 0-100
    /// System-wide GPU memory currently allocated, across all processes.
    /// 0 when the accelerator did not publish the key.
    let memoryAllocatedBytes: UInt64
    /// System-wide GPU memory the driver has resident for in-flight work right
    /// now — a small fraction of allocated except during active GPU work.
    /// 0 when the accelerator did not publish the key.
    let memoryActiveBytes: UInt64
}

/// Reads GPU state from the IORegistry (public IOKit API, no sudo).
/// On Apple Silicon the AGX accelerator publishes a `PerformanceStatistics`
/// dictionary with `Device Utilization %`, `Alloc system memory` and
/// `In use system memory`.
///
/// Those two memory keys were measured on the M2 Max (2026-07-29) by
/// allocating 4 GiB of `.storageModeShared` MTLBuffers, faulting the pages in,
/// then having the GPU blit between two of them:
///
///     baseline                alloc=67.42 GB  inUse=0.81 GB
///     after alloc 4 GB        alloc=71.42 GB  inUse=0.83 GB
///     during/after GPU blit   alloc=71.44 GB  inUse=2.71 GB
///     3s idle after the blit  alloc=71.50 GB  inUse=0.82 GB
///     after process exit      alloc=67.59 GB  inUse=0.93 GB
///
/// So `Alloc system memory` tracks allocation (+4.00 GB exactly, released when
/// the owner exits — it is live, not monotonic) while `In use system memory`
/// ignores allocation entirely and reports only what a command buffer is
/// touching, decaying to baseline seconds after the work finishes. The window
/// leads with allocated because that is the figure that answers "will a bigger
/// model fit": with a 60 GB LLM loaded but idle, in-use alone reads 0.5 GB and
/// looks like a broken gauge.
///
/// Both entry points return nil when no accelerator publishes
/// `Device Utilization %` at all. That is deliberately distinct from a reading
/// of 0: the key is undocumented and verified on one machine, so a future OS,
/// an unreleased GPU, or a paravirtualized GPU in a VM could stop supplying it
/// — and "absent" must never render as "idle", which is what a plain 0 would
/// look like on the dock tile.
enum GPUSampler {

    /// Utilization only (0-100), or nil when unavailable. Kept as the headless
    /// `--sample` entry point.
    static func utilization() -> Double? {
        sample()?.utilization
    }

    /// Utilization plus both GPU memory figures, or nil when no accelerator
    /// publishes the utilization key. Takes the max across accelerators if more
    /// than one is present. Memory is best-effort: a missing memory key on an
    /// otherwise readable accelerator yields 0 rather than failing the sample,
    /// since the memory gauge is secondary to the graph. The window renders a 0
    /// allocated figure as "—" — a live Mac always has hundreds of MB allocated
    /// by WindowServer alone, so 0 means "key absent", not "nothing allocated".
    static func sample() -> GPUSample? {
        var util: Double?
        var allocated: UInt64 = 0
        var active: UInt64 = 0
        forEachPerformanceStatistics { stats in
            if let u = deviceUtilization(stats) {
                util = max(util ?? 0, u)
            }
            if let m = stats["Alloc system memory"] as? Int, m > 0 {
                allocated = max(allocated, UInt64(m))
            }
            if let m = stats["In use system memory"] as? Int, m > 0 {
                active = max(active, UInt64(m))
            }
        }
        guard let util else { return nil }
        return GPUSample(utilization: min(max(util, 0), 100),
                         memoryAllocatedBytes: allocated,
                         memoryActiveBytes: active)
    }

    // MARK: - Private

    private static func deviceUtilization(_ stats: [String: Any]) -> Double? {
        if let v = stats["Device Utilization %"] as? Int { return Double(v) }
        if let v = stats["Device Utilization %"] as? Double { return v }
        return nil
    }

    /// Iterates every IOAccelerator's `PerformanceStatistics` dictionary.
    private static func forEachPerformanceStatistics(_ body: ([String: Any]) -> Void) {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOAccelerator")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return
        }
        defer { IOObjectRelease(iterator) }

        var entry: io_registry_entry_t = IOIteratorNext(iterator)
        while entry != 0 {
            var propsRef: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(entry, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let props = propsRef?.takeRetainedValue() as? [String: Any],
               let stats = props["PerformanceStatistics"] as? [String: Any] {
                body(stats)
            }
            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }
    }
}
