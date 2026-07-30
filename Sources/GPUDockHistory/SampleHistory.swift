import Foundation

/// Shared ring buffer of GPU utilization samples (0-100). Single source of
/// truth for both the dock tile (GPUHistoryView) and the window scope
/// (HistoryScopeView), so they never drift apart. Also carries the latest
/// GPU memory readings for the window's memory gauge.
final class SampleHistory {
    static let shared = SampleHistory()

    let capacity: Int
    private(set) var values: [Double] = []
    private(set) var latestAllocatedBytes: UInt64 = 0
    private(set) var latestActiveBytes: UInt64 = 0

    /// False once the sampler reports that nothing publishes the utilization
    /// key. Distinct from a run of 0% samples — there is no reading at all, so
    /// the window says so instead of drawing a flat line that looks idle.
    /// Starts true: the first sample lands before any UI is built, and an
    /// optimistic default avoids a flash of "unavailable" on a healthy Mac.
    private(set) var isAvailable = true

    /// 120 rather than a power of two so the window scope spans a round
    /// duration at every sample interval: 2:00 at 1s, 4:00 at 2s, 10:00 at 5s.
    /// The dock tile is unaffected — it draws the last 64 samples regardless.
    init(capacity: Int = 120) { self.capacity = capacity }

    /// Records a sample, or marks the GPU unreadable when passed nil. Nothing is
    /// appended in the unavailable case: an absent reading is not a data point,
    /// and plotting it as one is the exact confusion this guards against.
    func record(_ sample: GPUSample?) {
        guard let sample else {
            isAvailable = false
            return
        }
        isAvailable = true
        values.append(sample.utilization)
        if values.count > capacity {
            values.removeFirst(values.count - capacity)
        }
        latestAllocatedBytes = sample.memoryAllocatedBytes
        latestActiveBytes = sample.memoryActiveBytes
    }

    /// Drops all history. Used on wake from sleep, where the buffered samples
    /// predate a gap that nothing in the buffer records.
    func clear() {
        values.removeAll(keepingCapacity: true)
        latestAllocatedBytes = 0
        latestActiveBytes = 0
    }

    var latest: Double { values.last ?? 0 }
}
