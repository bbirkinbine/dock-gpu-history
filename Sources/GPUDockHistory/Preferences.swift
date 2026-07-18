import AppKit

/// Graph tint, shared by the dock tile and the window scope. Green is default
/// (matches the app icon and Activity Monitor's family).
enum GraphColor: Int, CaseIterable {
    case green = 0, blue, orange, purple

    var nsColor: NSColor {
        switch self {
        case .green:  return .systemGreen
        case .blue:   return .systemBlue
        case .orange: return .systemOrange
        case .purple: return .systemPurple
        }
    }
}

extension Notification.Name {
    /// Posted when a user-facing preference (sample interval, graph color)
    /// changes, so the app can rebuild the timer and redraw.
    static let gpuPrefsChanged = Notification.Name("gpuPrefsChanged")
}

/// UserDefaults-backed settings. Launch-at-login is NOT stored here — its
/// source of truth is `SMAppService.mainApp.status` (see DetailsView).
enum Preferences {
    private static let defaults = UserDefaults.standard

    private enum Key {
        static let sampleInterval = "sampleInterval"
        static let graphColor = "graphColor"
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }

    /// Seconds between samples. Allowed: 1, 2, 5. Defaults to 1.
    static var sampleInterval: Double {
        get {
            let v = defaults.double(forKey: Key.sampleInterval)
            return v == 0 ? 1.0 : v
        }
        set { defaults.set(newValue, forKey: Key.sampleInterval) }
    }

    static var graphColor: GraphColor {
        get { GraphColor(rawValue: defaults.integer(forKey: Key.graphColor)) ?? .green }
        set { defaults.set(newValue.rawValue, forKey: Key.graphColor) }
    }

    /// Used to open the window once, the first time the app runs, so the
    /// dock-tile model isn't a mystery.
    static var hasLaunchedBefore: Bool {
        get { defaults.bool(forKey: Key.hasLaunchedBefore) }
        set { defaults.set(newValue, forKey: Key.hasLaunchedBefore) }
    }
}
