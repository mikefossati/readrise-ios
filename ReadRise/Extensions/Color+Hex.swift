import SwiftUI
import UIKit

// MARK: - Color(hex:) initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: Double
        switch hex.count {
        case 6:
            (r, g, b, a) = (Double((int >> 16) & 0xFF)/255, Double((int >> 8) & 0xFF)/255, Double(int & 0xFF)/255, 1)
        case 8:
            (r, g, b, a) = (Double((int >> 24) & 0xFF)/255, Double((int >> 16) & 0xFF)/255, Double((int >> 8) & 0xFF)/255, Double(int & 0xFF)/255)
        default:
            (r, g, b, a) = (0, 0, 0, 1)
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - UIColor hex helper (used for adaptive dark/light colors)

private extension UIColor {
    convenience init(hex6 string: String) {
        let s = string.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)
        self.init(
            red:   CGFloat((int >> 16) & 0xFF) / 255,
            green: CGFloat((int >> 8)  & 0xFF) / 255,
            blue:  CGFloat(int & 0xFF)          / 255,
            alpha: 1
        )
    }
}

// MARK: - Adaptive brand palette
//
// Light mode: warm parchment/ink tones matching the web app.
// Dark mode:  deep ink backgrounds with lifted card surfaces.
// Only .rrAmber is the same in both modes.

extension Color {
    /// Brand amber accent — identical in light and dark.
    static let rrAmber          = Color(hex: "#e8923a")

    /// Screen / page background.
    static let rrBackground     = Color(UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex6: "#161624") : UIColor(hex6: "#faf8f4")
    })
    /// Card / grouped-content surface.
    static let rrCard           = Color(UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex6: "#21212f") : .white
    })
    /// Warm parchment tint (book header, decorative areas).
    static let rrParchment      = Color(UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex6: "#282832") : UIColor(hex6: "#f0ebe0")
    })
    /// Amber-warm tint (session timer card, goal-complete banner).
    static let rrAmberTint      = Color(UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex6: "#3d3120") : UIColor(hex6: "#fef3e2")
    })
    /// Primary / ink text.
    static let rrLabel          = Color(UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex6: "#f2eee8") : UIColor(hex6: "#1a1a2e")
    })
    /// Secondary / supporting text.
    static let rrSecondaryLabel = Color(UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex6: "#9a8c82") : UIColor(hex6: "#7a7068")
    })
    /// Borders and dividers.
    static let rrBorder         = Color(UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex6: "#38384e") : UIColor(hex6: "#ddd5c8")
    })
    /// Cover placeholder / empty fill.
    static let rrFill           = Color(UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(hex6: "#2c2c3a") : UIColor(hex6: "#ddd5c8")
    })
}

// MARK: - ProgressBar
//
// Replaces `ProgressView(value:).scaleEffect(x: 1, y: 2)` which distorts
// the system style and ignores the fill color in some configurations.

struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.rrBorder)
                Capsule()
                    .fill(Color.rrAmber)
                    .frame(width: max(0, geo.size.width * CGFloat(min(max(value, 0), 1.0))))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Haptics

@MainActor
enum Haptic {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
