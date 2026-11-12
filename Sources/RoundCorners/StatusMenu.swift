import AppKit
import ServiceManagement

/// Native NSMenu (Liquid Glass on macOS 26) with custom rows for the switch and slider.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    private let settings = Settings.shared
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    private let enabledSwitch = NSSwitch()
    private let slider = NSSlider(value: 10, minValue: 0, maxValue: 40, target: nil, action: nil)
    private let radiusValue = NSTextField(labelWithString: "")

    private var continuousItem: NSMenuItem!
    private var circularItem: NSMenuItem!
    private var roundTopItem: NSMenuItem!
    private var builtInItem: NSMenuItem!
    private var calibrateItem: NSMenuItem!
    private var loginItem: NSMenuItem!

    /// Line custom rows up with section headers and separators (past the checkmark column).
    private let leading: CGFloat = 29.5
    private let trailing: CGFloat = 15
    private let width: CGFloat = 270

    override init() {
        super.init()
        item.button?.image = NSImage(systemSymbolName: "rectangle.roundedbottom", accessibilityDescription: "Round Corners")
        build()
        menu.delegate = self
        item.menu = menu
        item.isVisible = !settings.hideIcon
    }

    func open() { item.button?.performClick(nil) }

    /// Called when the app is opened again while running (Spotlight, Finder, `open`).
    func showIcon() {
        settings.hideIcon = false
        item.isVisible = true
        DispatchQueue.main.async { self.open() }
    }

    // MARK: Building

    private func build() {
        menu.addItem(viewItem(headerView(), height: 34))
        menu.addItem(.separator())

        menu.addItem(.sectionHeader(title: "Radius"))
        menu.addItem(viewItem(sliderView(), height: 30))
        menu.addItem(.separator())

        menu.addItem(.sectionHeader(title: "Curve"))
        continuousItem = action("Continuous (Apple)", symbol: "app", #selector(setContinuous))
        circularItem = action("Circular", symbol: "circle", #selector(setCircular))
        menu.addItem(.separator())

        menu.addItem(.sectionHeader(title: "Displays"))
        roundTopItem = action("Round Top Corners Too", symbol: "rectangle.roundedtop", #selector(toggleRoundTop))
        builtInItem = action("Built-in Display Only", symbol: "laptopcomputer", #selector(toggleBuiltIn))
        menu.addItem(.separator())

        calibrateItem = action("Calibrate Against Top Corners", symbol: "scope", #selector(toggleCalibrate))
        _ = action("Reset Radius to 26 pt", symbol: "arrow.counterclockwise", #selector(reset))
        loginItem = action("Launch at Login", symbol: "power", #selector(toggleLogin))
        _ = action("Hide Menu Bar Icon…", symbol: "eye.slash", #selector(hideIcon))
        menu.addItem(.separator())

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
        menu.addItem(.sectionHeader(title: "Version \(version)"))
        let quit = NSMenuItem(title: "Quit Round Corners", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        refresh()
    }

    @discardableResult
    private func action(_ title: String, symbol: String, _ sel: Selector) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: sel, keyEquivalent: "")
        mi.target = self
        mi.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        menu.addItem(mi)
        return mi
    }

    private func viewItem(_ view: NSView, height: CGFloat) -> NSMenuItem {
        view.frame = NSRect(x: 0, y: 0, width: width, height: height)
        let mi = NSMenuItem()
        mi.view = view
        return mi
    }

    private func headerView() -> NSView {
        let title = NSTextField(labelWithString: "Round Corners")
        title.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        enabledSwitch.target = self
        enabledSwitch.action = #selector(toggleEnabled)
        return row([title, spacer(), enabledSwitch])
    }

    private func sliderView() -> NSView {
        slider.target = self
        slider.action = #selector(radiusChanged)
        slider.isContinuous = true
        radiusValue.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        radiusValue.textColor = .secondaryLabelColor
        radiusValue.alignment = .right
        radiusValue.widthAnchor.constraint(equalToConstant: 44).isActive = true
        return row([slider, radiusValue])
    }

    private func row(_ views: [NSView]) -> NSView {
        let stack = NSStackView(views: views)
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView()
        container.autoresizingMask = .width
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: leading),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -trailing),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    private func spacer() -> NSView {
        let v = NSView()
        v.setContentHuggingPriority(.init(1), for: .horizontal)
        return v
    }

    // MARK: State

    /// Controls only draw with the accent colour while their app is active. A menu-bar app is never
    /// frontmost, so force-activate for the lifetime of the menu (plain `activate()` is refused while
    /// another app is frontmost) and hand focus back to the previous app afterwards.
    private var previousApp: NSRunningApplication?

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
        let front = NSWorkspace.shared.frontmostApplication
        if front != .current { previousApp = front }
        Self.forceActivate()
    }

    private static func forceActivate() { (NSApp as LegacyActivation).activate(ignoringOtherApps: true) }

    func menuDidClose(_ menu: NSMenu) {
        previousApp?.activate()
        previousApp = nil
    }

    private func refresh() {
        enabledSwitch.state = settings.enabled ? .on : .off
        slider.doubleValue = settings.radius
        radiusValue.stringValue = String(format: "%.1f pt", settings.radius)
        continuousItem.state = settings.continuous ? .on : .off
        circularItem.state = settings.continuous ? .off : .on
        roundTopItem.state = settings.roundTop ? .on : .off
        builtInItem.state = settings.builtInOnly ? .on : .off
        calibrateItem.state = settings.calibrating ? .on : .off
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    // MARK: Actions

    @objc private func toggleEnabled() { settings.enabled = enabledSwitch.state == .on }
    @objc private func radiusChanged() {
        settings.radius = (slider.doubleValue * 2).rounded() / 2   // 0.5 pt steps
        radiusValue.stringValue = String(format: "%.1f pt", settings.radius)
    }
    @objc private func setContinuous() { settings.continuous = true; refresh() }
    @objc private func setCircular() { settings.continuous = false; refresh() }
    @objc private func toggleRoundTop() { settings.roundTop.toggle(); refresh() }
    @objc private func toggleBuiltIn() { settings.builtInOnly.toggle(); refresh() }
    @objc private func toggleCalibrate() { settings.calibrating.toggle(); refresh() }
    @objc private func reset() { settings.radius = 26; settings.continuous = true; refresh() }
    @objc private func hideIcon() {
        // Let the menu finish closing before presenting the alert.
        DispatchQueue.main.async { [self] in
            Self.forceActivate()
            let alert = NSAlert()
            alert.messageText = "Hide the menu bar icon?"
            alert.informativeText = "Round Corners keeps running. To show the icon again, open Round Corners from Spotlight or Finder."
            alert.addButton(withTitle: "Hide Icon")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            settings.hideIcon = true
            item.isVisible = false
        }
    }
    @objc private func toggleLogin() {
        let svc = SMAppService.mainApp
        try? (svc.status == .enabled ? svc.unregister() : svc.register())
        refresh()
    }
}




/// `activate(ignoringOtherApps:)` is deprecated but still the only call that activates a background
/// app on demand; calling it through a protocol avoids the deprecation warning.
@MainActor private protocol LegacyActivation { func activate(ignoringOtherApps: Bool) }
extension NSApplication: LegacyActivation {}
