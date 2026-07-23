import Cocoa
import ServiceManagement

/// Contents of the optional details window. Chrome uses semantic colors so it
/// follows the system theme; the embedded HistoryScopeView stays a dark scope.
/// Call `refresh()` to update the live values.
final class DetailsView: NSView {

    // Dynamic elements updated by refresh()
    private let subtitleLabel = NSTextField(labelWithString: "—")
    private let utilLabel = NSTextField(labelWithString: "0")
    private let percentLabel = NSTextField(labelWithString: "%")
    private let memoryValue = NSTextField(labelWithString: "—")
    private let memoryMeter = MeterView()
    private let peakAvgValue = NSTextField(labelWithString: "—")
    private let timeValue = NSTextField(labelWithString: "—")
    private let scope = HistoryScopeView(frame: .zero)

    // Controls
    private let intervalControl = NSSegmentedControl(
        labels: ["1s", "2s", "5s"], trackingMode: .selectOne, target: nil, action: nil)
    private let colorControl = NSSegmentedControl(
        images: GraphColor.allCases.map { DetailsView.swatch($0.nsColor) },
        trackingMode: .selectOne, target: nil, action: nil)
    private let loginSwitch = NSSwitch()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        build()
        syncControls()
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    convenience init() { self.init(frame: NSRect(x: 0, y: 0, width: 360, height: 10)) }

    // MARK: - Layout

    private func build() {
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 12
        root.translatesAutoresizingMaskIntoConstraints = false
        addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            root.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            root.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            root.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            widthAnchor.constraint(equalToConstant: 360),
        ])

        // Identity
        let name = label(GPUInfo.name, .systemFont(ofSize: 14, weight: .semibold))
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor
        let identity = NSStackView(views: [name, subtitleLabel])
        identity.orientation = .vertical
        identity.alignment = .leading
        identity.spacing = 1
        addFullWidth(identity, to: root)

        // Big read
        utilLabel.font = .monospacedDigitSystemFont(ofSize: 34, weight: .bold)
        percentLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        percentLabel.textColor = Preferences.graphColor.nsColor
        let bigLeft = NSStackView(views: [utilLabel, percentLabel])
        bigLeft.orientation = .horizontal
        bigLeft.alignment = .firstBaseline
        bigLeft.spacing = 3
        let caption = label("GPU utilization", .systemFont(ofSize: 12), .secondaryLabelColor)
        addFullWidth(row(bigLeft, caption), to: root)

        // Scope graph
        scope.translatesAutoresizingMaskIntoConstraints = false
        scope.heightAnchor.constraint(equalToConstant: 100).isActive = true
        addFullWidth(scope, to: root)

        // Time axis
        let axis = NSStackView(views: [
            axisLabel("−60s"), axisLabel("−40s"), axisLabel("−20s"), axisLabel("now"),
        ])
        axis.orientation = .horizontal
        axis.distribution = .equalSpacing
        addFullWidth(axis, to: root)
        root.setCustomSpacing(16, after: axis)

        // Memory
        addFullWidth(row(key("GPU memory in use"), value(memoryValue)), to: root)
        memoryMeter.translatesAutoresizingMaskIntoConstraints = false
        memoryMeter.heightAnchor.constraint(equalToConstant: 6).isActive = true
        addFullWidth(memoryMeter, to: root)
        root.setCustomSpacing(18, after: memoryMeter)

        // Since-reset stats
        let resetButton = NSButton(title: "Reset", target: self, action: #selector(resetTapped))
        resetButton.bezelStyle = .rounded
        resetButton.controlSize = .small
        resetButton.font = .systemFont(ofSize: 11)
        let resetRow = NSStackView(views: [spacer(), resetButton])
        resetRow.orientation = .horizontal
        addFullWidth(resetRow, to: root)
        addFullWidth(row(key("Peak · average"), value(peakAvgValue)), to: root)
        addFullWidth(row(key("Time at 100%"), value(timeValue)), to: root)

        // Settings
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        addFullWidth(sep, to: root)
        root.setCustomSpacing(16, after: sep)

        intervalControl.target = self
        intervalControl.action = #selector(intervalChanged)
        addFullWidth(row(key("Sample interval"), intervalControl), to: root)

        colorControl.target = self
        colorControl.action = #selector(colorChanged)
        addFullWidth(row(key("Graph color"), colorControl), to: root)

        loginSwitch.target = self
        loginSwitch.action = #selector(loginToggled)
        addFullWidth(row(key("Launch at login"), loginSwitch), to: root)
    }

    /// Pull the settings controls back into agreement with `Preferences`.
    /// Called at init and again whenever a preference may have changed behind
    /// the window's back (e.g. the Dock menu's Sample Rate submenu).
    func syncControls() {
        intervalControl.selectedSegment = [1.0, 2.0, 5.0].firstIndex(of: Preferences.sampleInterval) ?? 0
        colorControl.selectedSegment = Preferences.graphColor.rawValue
        loginSwitch.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
    }

    // MARK: - Live update

    func refresh() {
        utilLabel.stringValue = String(format: "%.0f", SampleHistory.shared.latest)
        percentLabel.textColor = Preferences.graphColor.nsColor

        // Budget is re-read each refresh: the OS ceiling can change at runtime
        // (sudo sysctl iogpu.wired_limit_mb), and GPUInfo tracks it live.
        subtitleLabel.stringValue = GPUInfo.subtitle
        let gb = Double(SampleHistory.shared.latestMemoryBytes) / 1_073_741_824.0
        let budgetGB = GPUInfo.budgetGB
        memoryValue.stringValue = String(format: "%.1f GB · %.0f GB budget", gb, budgetGB)
        memoryMeter.color = Preferences.graphColor.nsColor
        memoryMeter.fraction = budgetGB > 0 ? CGFloat(gb / budgetGB) : 0

        peakAvgValue.stringValue = String(format: "%.0f%% · %.0f%%",
                                          SessionStats.shared.peak, SessionStats.shared.average)
        timeValue.stringValue = formatDuration(SessionStats.shared.timeAtMax)

        scope.needsDisplay = true
    }

    // MARK: - Actions

    @objc private func resetTapped() {
        SessionStats.shared.reset()
        refresh()
    }

    @objc private func intervalChanged() {
        Preferences.sampleInterval = [1.0, 2.0, 5.0][intervalControl.selectedSegment]
        NotificationCenter.default.post(name: .gpuPrefsChanged, object: nil)
    }

    @objc private func colorChanged() {
        Preferences.graphColor = GraphColor(rawValue: colorControl.selectedSegment) ?? .green
        NotificationCenter.default.post(name: .gpuPrefsChanged, object: nil)
        refresh()
    }

    @objc private func loginToggled() {
        do {
            if loginSwitch.state == .on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Registration can fail (e.g. the ad-hoc dev build). Reflect reality.
            loginSwitch.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        }
    }

    // MARK: - Helpers

    private func label(_ text: String, _ font: NSFont, _ color: NSColor = .labelColor) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = font
        l.textColor = color
        return l
    }

    private func key(_ text: String) -> NSTextField {
        label(text, .systemFont(ofSize: 13), .secondaryLabelColor)
    }

    private func value(_ field: NSTextField) -> NSTextField {
        field.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        field.textColor = .labelColor
        field.alignment = .right
        return field
    }

    private func axisLabel(_ text: String) -> NSTextField {
        label(text, .monospacedDigitSystemFont(ofSize: 10, weight: .regular), .tertiaryLabelColor)
    }

    private func spacer() -> NSView {
        let v = NSView()
        v.setContentHuggingPriority(.defaultLow, for: .horizontal)
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return v
    }

    private func row(_ left: NSView, _ right: NSView) -> NSStackView {
        let s = NSStackView(views: [left, spacer(), right])
        s.orientation = .horizontal
        s.alignment = .centerY
        s.spacing = 8
        return s
    }

    private func addFullWidth(_ view: NSView, to stack: NSStackView) {
        stack.addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        if s < 60 { return "\(s)s" }
        return "\(s / 60)m \(s % 60)s"
    }

    private static func swatch(_ color: NSColor) -> NSImage {
        let size = NSSize(width: 14, height: 14)
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSBezierPath(ovalIn: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        return image
    }
}
