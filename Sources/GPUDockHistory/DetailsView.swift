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
    /// Caption beside the big number. Doubles as the notice when the GPU cannot
    /// be read, so no row has to appear or disappear.
    private let captionLabel = NSTextField(labelWithString: "GPU utilization")
    private let memoryValue = NSTextField(labelWithString: "—")
    private let memoryMeter = MeterView()
    /// Names the meter's bright segment. Carried under the bar rather than
    /// appended to `memoryValue` because one line holding both figures plus the
    /// budget measures 315pt of the 324pt available and overflows at three
    /// digits — which is exactly the machine (192 GB Ultra, or any Mac mid-
    /// inference) where the numbers matter most.
    private let memoryActiveCaption = NSTextField(labelWithString: "—")
    private let peakAvgValue = NSTextField(labelWithString: "—")
    private let timeValue = NSTextField(labelWithString: "—")
    private let scope = HistoryScopeView(frame: .zero)
    /// Time-axis ticks under the scope. Not constant: the scope plots
    /// `SampleHistory.capacity` samples, so the span it covers is
    /// capacity × sample interval and changes with the interval setting.
    private var axisFields: [NSTextField] = []

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
        captionLabel.font = .systemFont(ofSize: 12)
        captionLabel.textColor = .secondaryLabelColor
        addFullWidth(row(bigLeft, captionLabel), to: root)

        // Scope graph
        scope.translatesAutoresizingMaskIntoConstraints = false
        scope.heightAnchor.constraint(equalToConstant: 100).isActive = true
        addFullWidth(scope, to: root)

        // Custom-drawn views are invisible to VoiceOver until they claim to be
        // accessibility elements; the text rows around them are exposed for
        // free. Labels are filled in by refresh(), which owns the live values.
        scope.setAccessibilityElement(true)
        scope.setAccessibilityRole(.image)
        memoryMeter.setAccessibilityElement(true)
        memoryMeter.setAccessibilityRole(.levelIndicator)

        // Time axis — filled in by updateAxis(), which syncControls() drives.
        axisFields = (0..<4).map { _ in axisLabel("") }
        let axis = NSStackView(views: axisFields)
        axis.orientation = .horizontal
        axis.distribution = .equalSpacing
        addFullWidth(axis, to: root)
        root.setCustomSpacing(16, after: axis)

        // Memory. Leads with allocated, not in-use: in-use collapses to under a
        // gigabyte seconds after any GPU work finishes, so on a Mac holding a
        // 60 GB model in GPU memory it reads ~0.5 GB and looks broken. See
        // GPUSampler for the measurements behind that.
        addFullWidth(row(key("GPU memory allocated"), value(memoryValue)), to: root)
        memoryMeter.translatesAutoresizingMaskIntoConstraints = false
        memoryMeter.heightAnchor.constraint(equalToConstant: 6).isActive = true
        addFullWidth(memoryMeter, to: root)
        root.setCustomSpacing(5, after: memoryMeter)

        memoryActiveCaption.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        addFullWidth(memoryActiveCaption, to: root)
        root.setCustomSpacing(18, after: memoryActiveCaption)

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
        updateAxis()
    }

    /// Label the time axis with the span the scope actually covers, in even
    /// thirds from oldest to newest.
    private func updateAxis() {
        let span = Double(SampleHistory.shared.capacity) * Preferences.sampleInterval
        // One unit across the whole axis — mixing "−2:00" with "−40s" on the
        // same row reads as sloppy. The span decides which.
        let useMinutes = span >= 60
        for (field, fraction) in zip(axisFields, [1.0, 2.0 / 3.0, 1.0 / 3.0, 0.0]) {
            let s = Int((span * fraction).rounded())
            if s == 0 {
                field.stringValue = "now"
            } else if useMinutes {
                field.stringValue = String(format: "−%d:%02d", s / 60, s % 60)
            } else {
                field.stringValue = "−\(s)s"
            }
        }
    }

    // MARK: - Live update

    func refresh() {
        percentLabel.textColor = Preferences.graphColor.nsColor
        memoryMeter.color = Preferences.graphColor.nsColor
        // Budget is re-read each refresh: the OS ceiling can change at runtime
        // (sudo sysctl iogpu.wired_limit_mb), and GPUInfo tracks it live.
        subtitleLabel.stringValue = GPUInfo.subtitle
        scope.needsDisplay = true

        // Nothing publishes the utilization key on this Mac. Every live figure
        // below is derived from readings that do not exist, so none of them are
        // shown as numbers — a "0%" here is indistinguishable from a genuinely
        // idle GPU, which is the whole failure this guards against.
        guard SampleHistory.shared.isAvailable else {
            utilLabel.stringValue = "—"
            percentLabel.isHidden = true
            captionLabel.stringValue = "Statistics unavailable"
            memoryValue.stringValue = "—"
            memoryMeter.fraction = 0
            memoryMeter.activeFraction = 0
            memoryActiveCaption.stringValue = "—"
            memoryActiveCaption.textColor = .tertiaryLabelColor
            peakAvgValue.stringValue = "—"
            timeValue.stringValue = "—"
            scope.setAccessibilityLabel("GPU utilization history: statistics unavailable on this Mac")
            memoryMeter.setAccessibilityLabel("GPU memory: unavailable")
            return
        }

        percentLabel.isHidden = false
        captionLabel.stringValue = "GPU utilization"

        let util = SampleHistory.shared.latest
        utilLabel.stringValue = String(format: "%.0f", util)

        updateMemory()

        peakAvgValue.stringValue = String(format: "%.0f%% · %.0f%%",
                                          SessionStats.shared.peak, SessionStats.shared.average)
        timeValue.stringValue = formatDuration(SessionStats.shared.timeAtMax)

        scope.setAccessibilityLabel(String(format: "GPU utilization history, currently %.0f percent", util))
    }

    /// The memory row, meter and caption. Split out of `refresh()` because it
    /// has its own absent-vs-zero case: a Mac that is awake always has some GPU
    /// memory allocated (WindowServer alone accounts for hundreds of megabytes),
    /// so 0 allocated means the accelerator did not publish the key — the same
    /// distinction the utilization guard above draws, and worth drawing here
    /// too rather than rendering an absent key as an empty bar.
    private func updateMemory() {
        let allocatedGB = Double(SampleHistory.shared.latestAllocatedBytes) / 1_073_741_824.0
        let activeGB = Double(SampleHistory.shared.latestActiveBytes) / 1_073_741_824.0
        let budgetGB = GPUInfo.budgetGB

        guard allocatedGB > 0 else {
            memoryValue.stringValue = "—"
            memoryMeter.fraction = 0
            memoryMeter.activeFraction = 0
            memoryActiveCaption.stringValue = "not reported on this Mac"
            memoryActiveCaption.textColor = .tertiaryLabelColor
            memoryMeter.setAccessibilityLabel("GPU memory: not reported on this Mac")
            return
        }

        memoryValue.stringValue = String(format: "%.1f GB · %.0f GB budget", allocatedGB, budgetGB)
        // Allocation is not residency, so it can in principle exceed the wired
        // budget; MeterView clamps the bar, and the numbers above it stay honest
        // about the overshoot.
        memoryMeter.fraction = budgetGB > 0 ? CGFloat(allocatedGB / budgetGB) : 0
        memoryMeter.activeFraction = budgetGB > 0 ? CGFloat(activeGB / budgetGB) : 0

        // Tinted to match the meter's bright segment — that colour match is the
        // legend, so no swatch is needed.
        memoryActiveCaption.textColor = Preferences.graphColor.nsColor
        memoryActiveCaption.stringValue = String(format: "%.1f GB active right now", activeGB)

        memoryMeter.setAccessibilityLabel(String(
            format: "GPU memory, %.1f of %.0f gigabytes allocated, %.1f gigabytes active right now",
            allocatedGB, budgetGB, activeGB))
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
