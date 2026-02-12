import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let momentum = MomentumColors()
}

struct MomentumColors {
    let charcoal = Color(hex: "1C1C1E")
    let cream = Color(hex: "FAF8F5")
    let white = Color(hex: "FEFEFE")
    let coral = Color(hex: "E8725C")
    let gold = Color(hex: "D4A574")
    let plum = Color(hex: "6B4E71")
    let sage = Color(hex: "8FAE8B")
    let gray = Color(hex: "A8A29E")

    // Confetti colors array
    var confettiColors: [Color] {
        [coral, gold, sage, plum, white]
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    static func momentumDisplay(_ size: CGFloat) -> Font {
        .system(size: size, design: .serif)
    }

    static func momentumBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // Preset sizes
    static let displayLarge = momentumDisplay(32)
    static let displayMedium = momentumDisplay(24)
    static let displaySmall = momentumDisplay(20)

    static let titleLarge = momentumBody(20, weight: .semibold)
    static let titleMedium = momentumBody(17, weight: .semibold)
    static let titleSmall = momentumBody(15, weight: .semibold)

    static let bodyLarge = momentumBody(17)
    static let bodyMedium = momentumBody(15)
    static let bodySmall = momentumBody(13)

    static let caption = momentumBody(12, weight: .medium)
}

// MARK: - Spacing
struct Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct CornerRadius {
    static let small: CGFloat = 8
    static let card: CGFloat = 16
    static let modal: CGFloat = 20
    static let button: CGFloat = 100 // Full round
}

// MARK: - Shadows
extension View {
    func momentumShadow(radius: CGFloat = 8) -> some View {
        self.shadow(
            color: Color.momentum.charcoal.opacity(0.08),
            radius: radius,
            x: 0,
            y: 4
        )
    }

    func warmShadow() -> some View {
        self.shadow(
            color: Color.momentum.coral.opacity(0.15),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

// MARK: - Category Colors
extension GoalCategory {
    var color: Color {
        switch self {
        case .adventure: return Color.momentum.coral
        case .career: return Color.momentum.plum
        case .wealth: return Color.momentum.gold
        case .relationships: return Color.momentum.sage
        case .growth: return Color.momentum.plum
        case .wellness: return Color.momentum.sage
        case .wildcard: return Color.momentum.coral
        }
    }

    var icon: String {
        switch self {
        case .adventure: return "airplane"
        case .career: return "briefcase.fill"
        case .wealth: return "dollarsign.circle.fill"
        case .relationships: return "heart.fill"
        case .growth: return "brain.head.profile"
        case .wellness: return "leaf.fill"
        case .wildcard: return "sparkles"
        }
    }
}

// MARK: - Relationship Category Colors
extension RelationshipCategory {
    var color: Color {
        switch self {
        case .mentor: return Color.momentum.gold
        case .peer: return Color.momentum.sage
        case .supporter: return Color.momentum.coral
        case .aspirational: return Color.momentum.plum
        case .professional: return Color.momentum.charcoal
        case .personal: return Color.momentum.coral
        }
    }
}

// MARK: - App Name
struct AppName {
    static let full = "momentum"
    static let short = "m"
}
