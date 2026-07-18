import Cocoa

/// Owns the optional details window: fixed size (sized to its content), not
/// resizable, remembers its screen position. Closing it does not quit the app
/// (activation policy stays `.regular`, so the dock tile keeps running).
final class DetailsWindowController: NSWindowController {

    let detailsView = DetailsView()

    init() {
        detailsView.layoutSubtreeIfNeeded()
        let size = detailsView.fittingSize

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false)
        window.title = "GPU Dock History"
        window.isReleasedWhenClosed = false
        window.contentView = detailsView
        window.center()
        window.setFrameAutosaveName("DetailsWindow")

        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func showAndActivate() {
        detailsView.refresh()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
