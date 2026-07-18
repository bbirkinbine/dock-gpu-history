import Foundation
import IOKit

/// One reading of GPU state.
struct GPUSample {
    let utilization: Double        // 0-100
    let memoryInUseBytes: UInt64   // system-wide GPU memory in use
}

/// Reads GPU state from the IORegistry (public IOKit API, no sudo).
/// On Apple Silicon the AGX accelerator publishes a `PerformanceStatistics`
/// dictionary with `Device Utilization %` and `In use system memory`.
enum GPUSampler {

    /// Utilization only (0-100). Kept as the headless `--sample` entry point;
    /// returns the max across accelerators if more than one is present.
    static func utilization() -> Double {
        var value: Double = 0
        forEachPerformanceStatistics { stats in
            value = max(value, deviceUtilization(stats))
        }
        return min(max(value, 0), 100)
    }

    /// Utilization plus GPU memory in use.
    static func sample() -> GPUSample {
        var util: Double = 0
        var mem: UInt64 = 0
        forEachPerformanceStatistics { stats in
            util = max(util, deviceUtilization(stats))
            if let m = stats["In use system memory"] as? Int, m > 0 {
                mem = max(mem, UInt64(m))
            }
        }
        return GPUSample(utilization: min(max(util, 0), 100), memoryInUseBytes: mem)
    }

    // MARK: - Private

    private static func deviceUtilization(_ stats: [String: Any]) -> Double {
        if let v = stats["Device Utilization %"] as? Int { return Double(v) }
        if let v = stats["Device Utilization %"] as? Double { return v }
        return 0
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
