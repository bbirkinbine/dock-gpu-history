import Foundation

/// Shared ring buffer of GPU utilization samples (0-100). Single source of
/// truth for both the dock tile (GPUHistoryView) and the window scope
/// (HistoryScopeView), so they never drift apart. Also carries the latest
/// GPU memory reading for the window's memory gauge.
final class SampleHistory {
    static let shared = SampleHistory()

    let capacity: Int
    private(set) var values: [Double] = []
    private(set) var latestMemoryBytes: UInt64 = 0

    init(capacity: Int = 128) { self.capacity = capacity }

    func record(_ sample: GPUSample) {
        values.append(sample.utilization)
        if values.count > capacity {
            values.removeFirst(values.count - capacity)
        }
        latestMemoryBytes = sample.memoryInUseBytes
    }

    var latest: Double { values.last ?? 0 }
}
