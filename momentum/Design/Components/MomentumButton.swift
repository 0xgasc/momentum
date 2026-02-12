import SwiftUI

enum MomentumButtonStyle {
    case primary
    case secondary
    case ghost
}

struct MomentumButton: View {
    let title: String
    let icon: String?
    let style: MomentumButtonStyle
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: MomentumButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.titleSmall)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: style == .primary ? .infinity : nil)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: style == .ghost ? 1.5 : 0)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return Color.momentum.coral
        case .secondary: return Color.momentum.cream
        case .ghost: return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return Color.momentum.white
        case .secondary: return Color.momentum.charcoal
        case .ghost: return Color.momentum.charcoal
        }
    }

    private var borderColor: Color {
        switch style {
        case .ghost: return Color.momentum.gray.opacity(0.3)
        default: return .clear
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Icon Button
struct IconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let action: () -> Void

    init(
        icon: String,
        size: CGFloat = 44,
        color: Color = Color.momentum.charcoal,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(Color.momentum.cream)
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        MomentumButton("Get Started", icon: "arrow.right") {}
        MomentumButton("Learn More", style: .secondary) {}
        MomentumButton("Cancel", style: .ghost) {}
        IconButton(icon: "plus") {}
    }
    .padding()
    .background(Color.momentum.cream)
}
