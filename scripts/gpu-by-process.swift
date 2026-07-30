#!/usr/bin/env swift
// gpu-by-process.swift — which processes are using the GPU, and how much
// memory they hold. No sudo, no dependencies; IOKit and libproc only, the same
// public-API constraint the app itself works under.
//
//   ./scripts/gpu-by-process.swift [seconds] [--sort gpu|total|rss]
//   swift scripts/gpu-by-process.swift [seconds]     (equivalent)
//   ./scripts/gpu-by-process.swift --help
//
// Runs through the Swift interpreter that ships with the Command Line Tools,
// so the first couple of seconds are compilation, not sampling.
//
// Every Metal-using process owns one or more AGXDeviceUserClient nodes in the
// IORegistry carrying "IOUserClientCreator" (pid + name) and "AppUsage"
// (accumulatedGPUTime, ns). Sampling that twice and diffing gives each
// process's share of GPU busy time over the window.
//
// GPU *memory* cannot be attributed this way — see docs/GPU_TOOLS.md. Those
// client nodes publish no byte counts and neither does anything else, so this
// prints resident size instead, which on unified memory includes a process's
// GPU buffers but also everything else it has resident. Treat it as a lead,
// not an attribution.

import Darwin
import Foundation
import IOKit

struct Client {
    var name: String
    var gpuNanos: UInt64
}

/// Every AGXDeviceUserClient in the registry, aggregated per pid. Iterates the
/// service plane and filters by class rather than using IOServiceGetMatchingServices:
/// user clients are not published services, so class *matching* does not find them.
func sampleClients() -> [pid_t: Client] {
    var iterator: io_iterator_t = 0
    guard IORegistryCreateIterator(kIOMainPortDefault, kIOServicePlane,
                                   IOOptionBits(kIORegistryIterateRecursively),
                                   &iterator) == KERN_SUCCESS else { return [:] }
    defer { IOObjectRelease(iterator) }

    var result: [pid_t: Client] = [:]
    var entry = IOIteratorNext(iterator)
    while entry != 0 {
        defer {
            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }

        var className = [CChar](repeating: 0, count: 128)
        guard IOObjectGetClass(entry, &className) == KERN_SUCCESS,
              String(cString: className) == "AGXDeviceUserClient" else { continue }

        var propsRef: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entry, &propsRef, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let props = propsRef?.takeRetainedValue() as? [String: Any],
              let creator = props["IOUserClientCreator"] as? String,
              let (pid, name) = parseCreator(creator) else { continue }

        // AppUsage holds one entry per command queue; a process with several
        // queues (WindowServer runs five) reports each separately, so they sum.
        var nanos: UInt64 = 0
        if let usage = props["AppUsage"] as? [[String: Any]] {
            for u in usage {
                if let t = u["accumulatedGPUTime"] as? UInt64 { nanos += t }
                else if let t = u["accumulatedGPUTime"] as? Int, t > 0 { nanos += UInt64(t) }
            }
        }

        var client = result[pid] ?? Client(name: name, gpuNanos: 0)
        client.gpuNanos += nanos
        result[pid] = client
    }
    return result
}

/// "pid 46259, llama-server" -> (46259, "llama-server"). The name is the
/// kernel's 16-character comm, so longer ones arrive truncated.
func parseCreator(_ s: String) -> (pid_t, String)? {
    guard s.hasPrefix("pid ") else { return nil }
    let rest = s.dropFirst(4)
    guard let comma = rest.firstIndex(of: ",") else { return nil }
    guard let pid = pid_t(rest[rest.startIndex..<comma]) else { return nil }
    return (pid, rest[rest.index(after: comma)...].trimmingCharacters(in: .whitespaces))
}

/// Resident size in bytes, or nil when the process cannot be read — processes
/// owned by another user (WindowServer runs as _windowserver) refuse
/// proc_pidinfo. nil rather than 0: a zero here would read as "holds no
/// memory", which is the opposite of what an unreadable process means.
func residentBytes(_ pid: pid_t) -> UInt64? {
    var info = proc_taskinfo()
    let size = Int32(MemoryLayout<proc_taskinfo>.size)
    guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, size) == size else { return nil }
    return info.pti_resident_size
}

enum Sort: String {
    case gpu, total, rss
}

let usage = """
usage: gpu-by-process.swift [seconds] [--sort gpu|total|rss]

  seconds        sampling window for the GPU% column (default 2)
  --sort gpu     current GPU share, highest first (default)
  --sort total   cumulative GPU time since each process started
  --sort rss     resident memory, highest first

--sort rss is deliberately NOT "sort by GPU memory": no per-process GPU memory
figure exists on macOS (see docs/GPU_TOOLS.md). RSS is all of a process's
resident memory, which on unified memory includes its GPU buffers — enough to
find the owner of a large allocation, not enough to call it an attribution.
"""

var window: Double = 2
var sort: Sort = .gpu
var args = Array(CommandLine.arguments.dropFirst())
while let arg = args.first {
    args.removeFirst()
    switch arg {
    case "-h", "--help":
        print(usage)
        exit(0)
    case "--sort":
        guard let raw = args.first, let s = Sort(rawValue: raw) else {
            FileHandle.standardError.write(Data("--sort needs one of: gpu, total, rss\n".utf8))
            exit(2)
        }
        sort = s
        args.removeFirst()
    default:
        if arg.hasPrefix("--sort=") {
            guard let s = Sort(rawValue: String(arg.dropFirst(7))) else {
                FileHandle.standardError.write(Data("--sort needs one of: gpu, total, rss\n".utf8))
                exit(2)
            }
            sort = s
        } else if let seconds = Double(arg), seconds > 0 {
            window = seconds
        } else {
            FileHandle.standardError.write(Data("unrecognised argument: \(arg)\n\(usage)\n".utf8))
            exit(2)
        }
    }
}

let first = sampleClients()
Thread.sleep(forTimeInterval: window)
let second = sampleClients()

struct Row {
    let pid: pid_t, name: String, delta: UInt64, total: UInt64, rss: UInt64?
}

var rows: [Row] = []
for (pid, client) in second {
    let before = first[pid]?.gpuNanos ?? client.gpuNanos
    let delta = client.gpuNanos > before ? client.gpuNanos - before : 0
    // Processes holding a client node that have never run GPU work are noise
    // when ranking by GPU activity — but not when ranking by memory. A model
    // that has been loaded but not yet queried holds tens of gigabytes at zero
    // GPU time, and it is the row you came for. Owning a client node at all
    // means the process is a Metal client, which is the population that matters
    // here, so --sort rss keeps them.
    if sort != .rss && delta == 0 && client.gpuNanos == 0 { continue }
    rows.append(Row(pid: pid, name: client.name, delta: delta,
                    total: client.gpuNanos, rss: residentBytes(pid)))
}
switch sort {
case .gpu:   rows.sort { ($0.delta, $0.total) > ($1.delta, $1.total) }
case .total: rows.sort { ($0.total, $0.delta) > ($1.total, $1.delta) }
// Unreadable RSS sorts last rather than as zero: it is unknown, not empty.
case .rss:   rows.sort { ($0.rss ?? 0, $0.delta) > ($1.rss ?? 0, $1.delta) }
}

func pad(_ s: String, _ width: Int) -> String {
    s.count >= width ? s : String(repeating: " ", count: width - s.count) + s
}

let sortedBy = ["gpu": "GPU share now", "total": "cumulative GPU time",
                "rss": "resident memory"][sort.rawValue]!
print(String(format: "GPU busy time over %gs, by process — sorted by %@ (IORegistry AppUsage, no sudo)",
             window, sortedBy as NSString))
print("\(pad("GPU%", 7))  \(pad("GPU s (total)", 14))  \(pad("RSS", 9))  \(pad("PID", 7))  process")
for r in rows.prefix(15) {
    let pct = 100 * Double(r.delta) / (window * 1e9)
    let rss = r.rss.map { String(format: "%.1fGB", Double($0) / 1_073_741_824) } ?? "—"
    print(String(format: "%6.2f%%  %13.1fs  %@  %7d  %@",
                 pct, Double(r.total) / 1e9, pad(rss, 9) as NSString, r.pid, r.name))
}
if rows.isEmpty {
    print("(no process has run GPU work — AGXDeviceUserClient nodes report no AppUsage)")
}
print("""

RSS is resident memory, not GPU memory: no per-process GPU byte count exists.
See docs/GPU_TOOLS.md.
""")
