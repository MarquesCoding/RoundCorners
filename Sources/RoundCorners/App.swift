import SwiftUI
import ServiceManagement

@main
struct RoundCornersApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Round Corners", systemImage: "rectangle.roundedbottom") {
            SettingsPanel(settings: .shared)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlay = OverlayController()
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        overlay.start()
    }
}

struct SettingsPanel: View {
    @Bindable var settings: Settings
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Round corners", isOn: $settings.enabled)
                .toggleStyle(.switch).font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Radius")
                    Spacer()
                    Text(String(format: "%.1f pt", settings.radius)).monospacedDigit().foregroundStyle(.secondary)
                    Stepper("", value: $settings.radius, in: 0...40, step: 0.5).labelsHidden()
                }
                Slider(value: $settings.radius, in: 0...40)
            }

            Toggle("Continuous curve (Apple-style)", isOn: $settings.continuous)
            Toggle("Also round top corners", isOn: $settings.roundTop)
            Toggle("Built-in display only", isOn: $settings.builtInOnly)

            Divider()

            Toggle("Calibrate against top corners", isOn: $settings.calibrating)
            if settings.calibrating {
                Text("Lower the radius until the red line on the top corners just disappears behind the hardware edge. The bottom corners will then match.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, on in
                    do { on ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister() }
                    catch { launchAtLogin = SMAppService.mainApp.status == .enabled }
                }

            HStack {
                Button("Reset to 10 pt") { settings.radius = 10; settings.continuous = true }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
        }
        .padding()
        .frame(width: 300)
    }
}
