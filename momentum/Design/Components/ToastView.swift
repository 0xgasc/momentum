import SwiftUI
import Combine

// MARK: - Toast Message Model

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let icon: String
    let style: ToastStyle

    init(message: String, icon: String = "checkmark.circle.fill", style: ToastStyle = .success) {
        self.message = message
        self.icon = icon
        self.style = style
    }
}

enum ToastStyle {
    case success
    case info
    case warning

    var backgroundColor: Color {
        switch self {
        case .success: return Color.momentum.sage
        case .info: return Color.momentum.plum
        case .warning: return Color.momentum.coral
        }
    }

    var iconColor: Color {
        return .white
    }
}

// MARK: - Toast Manager (Singleton)

@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var currentToast: ToastMessage?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(_ message: String, icon: String = "checkmark.circle.fill", style: ToastStyle = .success) {
        // Cancel any pending dismiss
        dismissTask?.cancel()

        // Show new toast with animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentToast = ToastMessage(message: message, icon: icon, style: style)
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Auto-dismiss after 2.5 seconds
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }

    func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            currentToast = nil
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let toast: ToastMessage
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: toast.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(toast.style.iconColor)

            Text(toast.message)
                .font(.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(toast.style.backgroundColor)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            onDismiss()
        }
    }
}

// MARK: - Toast Overlay Modifier

struct ToastOverlayModifier: ViewModifier {
    @ObservedObject private var toastManager = ToastManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast) {
                        toastManager.dismiss()
                    }
                    .padding(.top, 60) // Below safe area / notch
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
            }
    }
}

extension View {
    func toastOverlay() -> some View {
        self.modifier(ToastOverlayModifier())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Button("Show Success Toast") {
            ToastManager.shared.show("Added to Today's Moves!")
        }

        Button("Show Challenge Toast") {
            ToastManager.shared.show("Challenge activated!", icon: "flag.fill")
        }

        Button("Show Info Toast") {
            ToastManager.shared.show("Syncing with community...", icon: "arrow.triangle.2.circlepath", style: .info)
        }

        Button("Show Warning Toast") {
            ToastManager.shared.show("Could not save", icon: "exclamationmark.triangle.fill", style: .warning)
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.momentum.cream)
    .toastOverlay()
}
