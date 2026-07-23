import Metal
import IOKit
import Foundation

/// GPU identity via public APIs: Metal for the name and memory budget,
/// IORegistry for the core count. All values verified present on Apple Silicon
/// (M2 Max: "Apple M2 Max", 38 cores, ~79.6 GB budget). Identity is computed
/// once; the memory budget is re-read live because the OS ceiling can be
/// changed at runtime via `sudo sysctl iogpu.wired_limit_mb=<mb>`.
enum GPUInfo {
    private static let device = MTLCreateSystemDefaultDevice()

    static let name: String = device?.name ?? "GPU"

    /// Metal's recommended working-set size at launch — the practical VRAM
    /// budget when no sysctl override is active. Verified on M2 Max
    /// (2026-07-23): this value freezes per process at first Metal init — a
    /// later `iogpu.wired_limit_mb` change moves neither this device's value
    /// nor a freshly created MTLDevice's — so it serves only as the
    /// no-override fallback. If the app launches while an override is active,
    /// this bakes the override in, and clearing the override later shows the
    /// stale value until relaunch; the true default is not recoverable
    /// in-process.
    private static let launchBudgetBytes: UInt64 = device?.recommendedMaxWorkingSetSize ?? 0

    /// The live `iogpu.wired_limit_mb` override in bytes, or 0 when unset.
    /// Reading a sysctl is public API, sandbox-safe, and takes microseconds.
    private static var overrideBudgetBytes: UInt64 {
        var mb: Int64 = 0
        var size = MemoryLayout<Int64>.size
        guard sysctlbyname("iogpu.wired_limit_mb", &mb, &size, nil, 0) == 0,
              mb > 0 else { return 0 }
        return UInt64(mb) * 1_048_576
    }

    /// The practical VRAM budget right now: the sysctl override when active,
    /// else the launch-time Metal recommendation.
    static var memoryBudgetBytes: UInt64 {
        let limit = overrideBudgetBytes
        return limit > 0 ? limit : launchBudgetBytes
    }

    /// True while a `iogpu.wired_limit_mb` override is in effect.
    static var budgetIsOverridden: Bool { overrideBudgetBytes > 0 }

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
    /// "(custom)" marks an active `iogpu.wired_limit_mb` override.
    static var subtitle: String {
        var parts: [String] = []
        if coreCount > 0 { parts.append("\(coreCount)-core") }
        parts.append("Unified memory")
        if memoryBudgetBytes > 0 {
            let suffix = budgetIsOverridden ? " (custom)" : ""
            parts.append(String(format: "%.0f GB%@", budgetGB, suffix))
        }
        return parts.joined(separator: " · ")
    }
}
