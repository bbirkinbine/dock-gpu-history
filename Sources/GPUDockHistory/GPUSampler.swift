import Foundation
import IOKit

/// Reads GPU utilization from the IORegistry (public IOKit API, no sudo).
/// On Apple Silicon the AGX accelerator publishes a `PerformanceStatistics`
/// dictionary containing `Device Utilization %`.
enum GPUSampler {

    /// Returns 0-100. If multiple accelerators are present, returns the max.
    static func utilization() -> Double {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOAccelerator")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return 0
        }
        defer { IOObjectRelease(iterator) }

        var utilization: Double = 0
        var entry: io_registry_entry_t = IOIteratorNext(iterator)
        while entry != 0 {
            var propsRef: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(entry, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let props = propsRef?.takeRetainedValue() as? [String: Any],
               let stats = props["PerformanceStatistics"] as? [String: Any] {
                if let v = stats["Device Utilization %"] as? Int {
                    utilization = max(utilization, Double(v))
                } else if let v = stats["Device Utilization %"] as? Double {
                    utilization = max(utilization, v)
                }
            }
            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }
        return min(max(utilization, 0), 100)
    }
}
