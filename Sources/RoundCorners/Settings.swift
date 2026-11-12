import Foundation
import Observation

/// User-tunable settings, persisted to UserDefaults.
@MainActor @Observable
final class Settings {
    static let shared = Settings()
    private let d = UserDefaults.standard

    /// Corner radius in points. Default 26pt; use Calibrate to match the hardware top corners.
    var radius: Double { didSet { d.set(radius, forKey: "radius") } }
    /// Apple's hardware uses a continuous (squircle-like) curve, not a circular arc.
    var continuous: Bool { didSet { d.set(continuous, forKey: "continuous") } }
    var enabled: Bool { didSet { d.set(enabled, forKey: "enabled") } }
    /// Also mask the top corners (useful on external displays, which have none).
    var roundTop: Bool { didSet { d.set(roundTop, forKey: "roundTop") } }
    var builtInOnly: Bool { didSet { d.set(builtInOnly, forKey: "builtInOnly") } }
    /// Hide the status item; reopening the app brings it back.
    var hideIcon: Bool { didSet { d.set(hideIcon, forKey: "hideIcon") } }
    /// Draws a red guide on the top corners so the radius can be matched to the hardware.
    var calibrating = false

    private init() {
        d.register(defaults: ["radius": 26.0, "continuous": true, "enabled": true,
                              "roundTop": false, "builtInOnly": true, "hideIcon": false])
        radius = d.double(forKey: "radius")
        continuous = d.bool(forKey: "continuous")
        enabled = d.bool(forKey: "enabled")
        roundTop = d.bool(forKey: "roundTop")
        builtInOnly = d.bool(forKey: "builtInOnly")
        hideIcon = d.bool(forKey: "hideIcon")
    }
}
