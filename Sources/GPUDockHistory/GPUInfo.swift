import Metal
import IOKit
import Foundation

/// Static GPU identity via public APIs: Metal for the name and memory budget,
/// IORegistry for the core count. All values verified present on Apple Silicon
/// (M2 Max: "Apple M2 Max", 38 cores, ~79.6 GB budget). Computed once.
enum GPUInfo {
    private static let device = MTLCreateSystemDefaultDevice()

    static let name: String = device?.name ?? "GPU"

    /// Metal's recommended working-set size — the practical VRAM budget. On a
    /// unified-memory Mac this is a large fraction of system RAM.
    static let memoryBudgetBytes: UInt64 = device?.recommendedMaxWorkingSetSize ?? 0

    /// `gpu-core-count` from the IORegistry (0 if unavailable). Searches parents
    /// and children of the accelerator node, where the property actually lives.
    static let coreCount: Int = {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault,
                                           IOServiceMatching("IOAccelerator"),
                                           &iterator) == KERN_SUCCESS else { return 0 }
        defer { IOObjectRelease(iterator) }

        let options = IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            let value = IORegistryEntrySearchCFProperty(
                entry, kIOServicePlane, "gpu-core-count" as CFString,
                kCFAllocatorDefault, options) as? Int
            IOObjectRelease(entry)
            if let value, value > 0 { return value }
            entry = IOIteratorNext(iterator)
        }
        return 0
    }()

    static var budgetGB: Double { Double(memoryBudgetBytes) / 1_073_741_824.0 }

    /// "38-core · Unified memory · 80 GB" — parts omitted if unavailable.
    static var subtitle: String {
        var parts: [String] = []
        if coreCount > 0 { parts.append("\(coreCount)-core") }
        parts.append("Unified memory")
        if memoryBudgetBytes > 0 { parts.append(String(format: "%.0f GB", budgetGB)) }
        return parts.joined(separator: " · ")
    }
}
