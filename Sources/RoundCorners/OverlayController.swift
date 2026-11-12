import AppKit
import SwiftUI

/// Borderless, click-through window that ignores the usual "stay below the menu bar" constraint.
final class OverlayWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class OverlayController {
    private var windows: [CGDirectDisplayID: OverlayWindow] = [:]
    private let settings = Settings.shared

    func start() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.rebuild() } }
        observe()
    }

    /// Re-run `rebuild` whenever a setting that changes which screens get windows changes.
    private func observe() {
        withObservationTracking {
            _ = settings.enabled
            _ = settings.builtInOnly
        } onChange: { [weak self] in
            Task { @MainActor in self?.rebuild(); self?.observe() }
        }
        rebuild()
    }

    private func rebuild() {
        windows.values.forEach { $0.orderOut(nil) }
        windows.removeAll()
        guard settings.enabled else { return }

        for screen in NSScreen.screens {
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            else { continue }
            let builtIn = CGDisplayIsBuiltin(id) != 0
            if settings.builtInOnly && !builtIn { continue }
            windows[id] = makeWindow(for: screen, builtIn: builtIn)
        }
    }

    private func makeWindow(for screen: NSScreen, builtIn: Bool) -> OverlayWindow {
        let w = OverlayWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.ignoresMouseEvents = true
        w.isReleasedWhenClosed = false
        // Above the menu bar, Dock, and full-screen apps.
        w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        let host = NSHostingView(rootView: CornerMask(settings: settings, isBuiltIn: builtIn))
        host.sizingOptions = []
        w.contentView = host
        w.setFrame(screen.frame, display: true)
        w.orderFrontRegardless()
        return w
    }
}
