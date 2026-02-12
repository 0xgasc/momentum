import SwiftUI

// MARK: - Share Card Style
/// Customization options for shareable cards
struct ShareCardStyle {
    var backgroundTheme: BackgroundTheme
    var showStats: Bool
    var showStreak: Bool
    var showBranding: Bool

    init(
        backgroundTheme: BackgroundTheme = .coral,
        showStats: Bool = true,
        showStreak: Bool = true,
        showBranding: Bool = true
    ) {
        self.backgroundTheme = backgroundTheme
        self.showStats = showStats
        self.showStreak = showStreak
        self.showBranding = showBranding
    }

    static var `default`: ShareCardStyle {
        ShareCardStyle()
    }
}

// MARK: - Background Theme
extension ShareCardStyle {
    enum BackgroundTheme: String, CaseIterable, Identifiable {
        case coral = "Coral Sunset"
        case sage = "Sage Garden"
        case plum = "Plum Royale"
        case charcoal = "Dark Mode"
        case cream = "Light Minimal"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .coral: return "sun.max.fill"
            case .sage: return "leaf.fill"
            case .plum: return "crown.fill"
            case .charcoal: return "moon.fill"
            case .cream: return "cloud.fill"
            }
        }

        var gradient: LinearGradient {
            switch self {
            case .coral:
                return LinearGradient(
                    colors: [Color.momentum.coral, Color.momentum.gold],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .sage:
                return LinearGradient(
                    colors: [Color.momentum.sage, Color.momentum.cream],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .plum:
                return LinearGradient(
                    colors: [Color.momentum.plum, Color.momentum.coral.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .charcoal:
                return LinearGradient(
                    colors: [Color.momentum.charcoal, Color.momentum.plum.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .cream:
                return LinearGradient(
                    colors: [Color.momentum.cream, Color.momentum.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }

        var textColor: Color {
            switch self {
            case .coral, .plum, .charcoal:
                return .white
            case .sage, .cream:
                return Color.momentum.charcoal
            }
        }

        var secondaryTextColor: Color {
            switch self {
            case .coral, .plum, .charcoal:
                return .white.opacity(0.8)
            case .sage, .cream:
                return Color.momentum.gray
            }
        }

        var accentColor: Color {
            switch self {
            case .coral: return Color.momentum.gold
            case .sage: return Color.momentum.sage
            case .plum: return Color.momentum.coral
            case .charcoal: return Color.momentum.plum
            case .cream: return Color.momentum.coral
            }
        }
    }
}

// MARK: - Convenience
extension ShareCardStyle {
    var backgroundGradient: LinearGradient {
        backgroundTheme.gradient
    }

    var textColor: Color {
        backgroundTheme.textColor
    }

    var secondaryTextColor: Color {
        backgroundTheme.secondaryTextColor
    }

    var accentColor: Color {
        backgroundTheme.accentColor
    }
}

// MARK: - Preview Helper
#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(ShareCardStyle.BackgroundTheme.allCases) { theme in
                VStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.gradient)
                        .frame(width: 100, height: 150)
                        .overlay(
                            VStack {
                                Image(systemName: theme.icon)
                                    .font(.title)
                                Text(theme.rawValue)
                                    .font(.caption)
                            }
                            .foregroundColor(theme.textColor)
                        )
                }
            }
        }
        .padding()
    }
}
