import Cocoa

// Headless check for scripts and agents: `gpudockhistory --sample [N]`
// prints N one-second utilization samples (integers, 0-100) and exits
// without starting the app. This is the machine-checkable half of the
// verify gate; the dock graph itself still needs eyes.
if let flagIndex = CommandLine.arguments.firstIndex(of: "--sample") {
    let next = CommandLine.arguments.dropFirst(flagIndex + 1).first
    let count = next.flatMap(Int.init) ?? 5
    for i in 0..<count {
        print(String(format: "%.0f", GPUSampler.utilization()))
        fflush(stdout)
        if i < count - 1 { Thread.sleep(forTimeInterval: 1.0) }
    }
    exit(0)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let historyView = GPUHistoryView(frame: NSRect(x: 0, y: 0, width: 128, height: 128))
    private var timer: Timer?
    private var windowController: DetailsWindowController?
    private var appIsActive = false
    private var becameActiveAt: TimeInterval = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.dockTile.contentView = historyView

        NotificationCenter.default.addObserver(
            self, selector: #selector(prefsChanged), name: .gpuPrefsChanged, object: nil)
        startTimer()

        // Open the window once, the first time the app is ever run, so the
        // dock-tile model isn't a mystery.
        if !Preferences.hasLaunchedBefore {
            Preferences.hasLaunchedBefore = true
            openWindow(nil)
        }
    }

    private func startTimer() {
        timer?.invalidate()
        let interval = Preferences.sampleInterval
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        t.tolerance = interval * 0.2
        timer = t
        t.fire()
    }

    private func tick() {
        let sample = GPUSampler.sample()
        SampleHistory.shared.record(sample)
        SessionStats.shared.add(sample.utilization, interval: Preferences.sampleInterval)
        NSApp.dockTile.display()
        refreshWindowIfVisible()
    }

    private func refreshWindowIfVisible() {
        if let wc = windowController, wc.window?.isVisible == true {
            wc.detailsView.refresh()
        }
    }

    @objc private func prefsChanged() {
        startTimer()               // sample interval may have changed
        NSApp.dockTile.display()   // graph color may have changed
        // A change may have come from the Dock menu, not the window's own
        // controls, so re-sync them before redrawing the live values.
        if let wc = windowController, wc.window?.isVisible == true {
            wc.detailsView.syncControls()
            wc.detailsView.refresh()
        }
    }

    @objc func openWindow(_ sender: Any?) {
        if windowController == nil { windowController = DetailsWindowController() }
        windowController?.showAndActivate()
    }

    @objc func resetStats(_ sender: Any?) {
        SessionStats.shared.reset()
        refreshWindowIfVisible()
    }

    @objc func setSampleRate(_ sender: NSMenuItem) {
        Preferences.sampleInterval = Double(sender.tag)   // tag is 1, 2, or 5
        NotificationCenter.default.post(name: .gpuPrefsChanged, object: nil)
    }

    // Dock-icon click drives the details window: raise it if it was buried,
    // close it if it was already frontmost, open it if it was closed. A
    // miniaturized window reports isVisible == false and takes the open path,
    // which deminiaturizes it. Must return false: the default reopen handling
    // would re-show the window just closed.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard let window = windowController?.window, window.isVisible else {
            openWindow(nil)
            return false
        }
        if appWasFrontmostAtClick {
            window.close()
        } else {
            // The click already activated us (AppKit raises the window as part
            // of activation); this just guarantees focus and a fresh redraw.
            windowController?.showAndActivate()
        }
        return false
    }

    // Was the app already frontmost when the Dock icon was clicked? Activation
    // and the reopen callback race: didBecomeActive normally lands first, but
    // the order isn't contractual, so neither the flag nor the timestamp is
    // trustworthy alone. Together they cover both orderings — either we are
    // still marked inactive, or we were marked active a blink ago by this very
    // click. Cost of the window being slightly too generous: a second click
    // inside 0.5s re-raises instead of closing.
    private var appWasFrontmostAtClick: Bool {
        if !appIsActive { return false }
        return ProcessInfo.processInfo.systemUptime - becameActiveAt > 0.5
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        appIsActive = true
        becameActiveAt = ProcessInfo.processInfo.systemUptime
    }

    func applicationDidResignActive(_ notification: Notification) {
        appIsActive = false
    }

    // Right-click Dock menu.
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        menu.addItem(withTitle: "Open GPU Dock History", action: #selector(openWindow(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Reset Stats", action: #selector(resetStats(_:)), keyEquivalent: "")
        menu.addItem(.separator())

        let rateItem = NSMenuItem(title: "Sample Rate", action: nil, keyEquivalent: "")
        let rateMenu = NSMenu()
        for (title, tag) in [("1 second", 1), ("2 seconds", 2), ("5 seconds", 5)] {
            let item = NSMenuItem(title: title, action: #selector(setSampleRate(_:)), keyEquivalent: "")
            item.tag = tag
            item.target = self
            item.state = Int(Preferences.sampleInterval) == tag ? .on : .off
            rateMenu.addItem(item)
        }
        rateItem.submenu = rateMenu
        menu.addItem(rateItem)

        for item in menu.items where item.action != nil { item.target = self }
        return menu
    }
}

// Main menu: window + reset + quit. Actions resolve through the responder
// chain to the app delegate; Quit works whenever the app has focus.
let app = NSApplication.shared
let mainMenu = NSMenu()
let appMenuItem = NSMenuItem()
mainMenu.addItem(appMenuItem)
let appMenu = NSMenu()
appMenu.addItem(withTitle: "Open GPU Dock History",
                action: #selector(AppDelegate.openWindow(_:)), keyEquivalent: "")
appMenu.addItem(withTitle: "Reset Stats",
                action: #selector(AppDelegate.resetStats(_:)), keyEquivalent: "")
appMenu.addItem(.separator())
appMenu.addItem(withTitle: "Quit GPU Dock History",
                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
appMenuItem.submenu = appMenu
app.mainMenu = mainMenu

let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)   // .regular is required to get a dock tile
app.run()
