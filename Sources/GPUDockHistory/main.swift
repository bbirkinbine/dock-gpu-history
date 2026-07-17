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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.dockTile.contentView = historyView

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.historyView.push(GPUSampler.utilization())
            NSApp.dockTile.display()
        }
        timer?.tolerance = 0.2
        timer?.fire()
    }
}

// Minimal main menu so Cmd-Q works if the app ever gets focus.
let app = NSApplication.shared
let mainMenu = NSMenu()
let appMenuItem = NSMenuItem()
mainMenu.addItem(appMenuItem)
let appMenu = NSMenu()
appMenu.addItem(withTitle: "Quit GPU Dock History",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q")
appMenuItem.submenu = appMenu
app.mainMenu = mainMenu

let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)   // .regular is required to get a dock tile
app.run()
