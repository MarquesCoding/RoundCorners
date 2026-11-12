import SwiftUI

/// Black fill covering everything outside a rounded rectangle, plus an optional calibration guide.
struct CornerMask: View {
    let settings: Settings
    let isBuiltIn: Bool

    var body: some View {
        let r = settings.radius
        // The built-in panel already has hardware-rounded top corners; only mask the bottom
        // unless asked (or on an external display with square corners everywhere).
        let top = (settings.roundTop || !isBuiltIn) ? r : 0
        let style: RoundedCornerStyle = settings.continuous ? .continuous : .circular
        let shape = UnevenRoundedRectangle(topLeadingRadius: top, bottomLeadingRadius: r,
                                           bottomTrailingRadius: r, topTrailingRadius: top,
                                           style: style)
        ZStack {
            Rectangle().subtracting(shape).fill(.black)

            if settings.calibrating {
                // A curve with the chosen radius on the top corners. When it lines up with the
                // hardware edge, the line is hidden by the physical corner.
                UnevenRoundedRectangle(topLeadingRadius: r, topTrailingRadius: r, style: style)
                    .inset(by: 0.5)
                    .stroke(.red, lineWidth: 1)
                    .mask(alignment: .top) {
                        HStack {
                            Rectangle().frame(width: r * 2, height: r * 2)
                            Spacer()
                            Rectangle().frame(width: r * 2, height: r * 2)
                        }
                    }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
