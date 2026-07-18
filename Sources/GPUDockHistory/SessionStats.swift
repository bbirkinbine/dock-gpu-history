import Foundation

/// Peak / average / time-at-100% accumulated since the app launched or since
/// the user last hit Reset. Deliberately app-level ("since last reset"), not
/// tied to system boot. `timeAtMax` accumulates real seconds so it stays
/// correct even if the sample interval changes mid-session.
final class SessionStats {
    static let shared = SessionStats()

    private(set) var peak: Double = 0
    private var sum: Double = 0
    private var count: Int = 0
    private var maxedSeconds: TimeInterval = 0

    /// `interval` is the seconds represented by this sample, used to accumulate
    /// time-at-max accurately.
    func add(_ value: Double, interval: Double) {
        peak = max(peak, value)
        sum += value
        count += 1
        if value >= 99 { maxedSeconds += interval }
    }

    var average: Double { count == 0 ? 0 : sum / Double(count) }
    var timeAtMax: TimeInterval { maxedSeconds }

    func reset() {
        peak = 0
        sum = 0
        count = 0
        maxedSeconds = 0
    }
}
