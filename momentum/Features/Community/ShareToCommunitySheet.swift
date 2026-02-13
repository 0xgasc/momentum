import SwiftUI

// MARK: - Shareable Content
enum ShareableContent {
    case win(description: String, size: WinSize, emotion: Int)
    case goalMilestone(goalTitle: String, category: GoalCategory, milestone: Double)
    case streak(days: Int)
    case dailySummary(actions: Int, wins: Int, streak: Int)

    var title: String {
        switch self {
        case .win: return "Share Win"
        case .goalMilestone: return "Share Milestone"
        case .streak: return "Share Streak"
        case .dailySummary: return "Share Summary"
        }
    }

    var icon: String {
        switch self {
        case .win: return "trophy.fill"
        case .goalMilestone: return "target"
        case .streak: return "flame.fill"
        case .dailySummary: return "chart.bar.fill"
        }
    }

    var previewText: String {
        switch self {
        case .win(let desc, _, _): return desc
        case .goalMilestone(let title, _, let milestone):
            return "\(Int(milestone * 100))% on \(title)"
        case .streak(let days): return "\(days) day streak"
        case .dailySummary(let actions, let wins, _):
            return "\(actions) actions, \(wins) wins today"
        }
    }
}

// MARK: - Share To Community Sheet
struct ShareToCommunitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseService: PurchaseService

    let content: ShareableContent
    var onShareComplete: (() -> Void)?

    @State private var isAnonymous = true
    @State private var shareMessage = ""
    @State private var isSharing = false
    @State private var shareComplete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Preview card
                    CommunitySharePreview(content: content, message: shareMessage)

                    // Custom message
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Add a message")
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)

                        TextField("Share your thoughts... (optional)", text: $shareMessage, axis: .vertical)
                            .lineLimit(2...4)
                            .font(.bodyMedium)
                            .padding(Spacing.md)
                            .background(Color.momentum.cream)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                    }

                    // Privacy toggle
                    VStack(spacing: Spacing.sm) {
                        Toggle(isOn: $isAnonymous) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: isAnonymous ? "person.fill.questionmark" : "person.fill")
                                    .foregroundColor(Color.momentum.plum)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isAnonymous ? "Share Anonymously" : "Share with Name")
                                        .font(.bodyMedium)
                                        .foregroundColor(Color.momentum.charcoal)
                                    Text(isAnonymous ? "Your name won't be shown" : "First name will be visible")
                                        .font(.caption)
                                        .foregroundColor(Color.momentum.gray)
                                }
                            }
                        }
                        .tint(Color.momentum.plum)
                    }
                    .padding(Spacing.md)
                    .background(Color.momentum.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                    Spacer().frame(height: Spacing.md)

                    // Share buttons
                    VStack(spacing: Spacing.md) {
                        // Community share
                        Button {
                            shareToCommunity()
                        } label: {
                            HStack {
                                if isSharing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "person.3.fill")
                                    Text("Share to Community")
                                }
                            }
                            .font(.titleSmall)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.momentum.sage)
                            .clipShape(Capsule())
                        }
                        .disabled(isSharing)

                        // External share
                        Button {
                            shareExternally()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Externally")
                            }
                            .font(.bodyMedium)
                            .foregroundColor(Color.momentum.charcoal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.momentum.cream)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.momentum.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(isSharing)
                    }
                }
                .padding(Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationTitle(content.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.momentum.gray)
                }
            }
            .overlay {
                if shareComplete {
                    ShareCompleteOverlay {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func shareToCommunity() {
        isSharing = true

        Task { @MainActor in
            let displayName = isAnonymous ? nil : UserProfileManager.shared.profile.name.components(separatedBy: " ").first

            do {
                switch content {
                case .win(let description, let size, let emotion):
                    try await CloudKitManager.shared.shareWin(
                        description: shareMessage.isEmpty ? description : shareMessage,
                        size: size,
                        emotion: emotion,
                        displayName: displayName,
                        isAnonymous: isAnonymous
                    )

                case .goalMilestone(let title, _, let milestone):
                    try await CloudKitManager.shared.shareMilestone(
                        goalTitle: title,
                        milestone: milestone,
                        message: shareMessage.isEmpty ? nil : shareMessage,
                        displayName: displayName,
                        isAnonymous: isAnonymous
                    )

                case .streak(let days):
                    try await CloudKitManager.shared.shareStreak(
                        days: days,
                        message: shareMessage.isEmpty ? nil : shareMessage,
                        displayName: displayName,
                        isAnonymous: isAnonymous
                    )

                case .dailySummary(let actions, let wins, let streak):
                    try await CloudKitManager.shared.shareDailySummary(
                        actions: actions,
                        wins: wins,
                        streak: streak,
                        message: shareMessage.isEmpty ? nil : shareMessage,
                        displayName: displayName,
                        isAnonymous: isAnonymous
                    )
                }

                // Success
                isSharing = false
                withAnimation {
                    shareComplete = true
                }
                onShareComplete?()

            } catch {
                isSharing = false
                ToastManager.shared.show("Failed to share. Try again.", icon: "exclamationmark.triangle.fill")
            }
        }
    }

    private func shareExternally() {
        // Convert to shareable card and present share sheet
        let cardType: ShareableCardType

        switch content {
        case .win(let description, let size, let emotion):
            cardType = .winCelebration(description: description, size: size, emotion: emotion)
        case .goalMilestone(let title, let category, let milestone):
            cardType = .goalMilestone(goalTitle: title, category: category, milestone: milestone)
        case .streak(let days):
            cardType = .streakCelebration(days: days)
        case .dailySummary(let actions, let wins, let streak):
            cardType = .dailySummary(actions: actions, wins: wins, streak: streak)
        }

        ShareService.shared.shareCard(cardType: cardType, style: .default)
    }
}

// MARK: - Community Share Preview
struct CommunitySharePreview: View {
    let content: ShareableContent
    let message: String

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.momentum.sage.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: content.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color.momentum.sage)
            }

            // Content preview
            VStack(spacing: Spacing.xs) {
                Text(content.previewText)
                    .font(.titleMedium)
                    .foregroundColor(Color.momentum.charcoal)
                    .multilineTextAlignment(.center)

                if !message.isEmpty {
                    Text("\"\(message)\"")
                        .font(.bodySmall)
                        .italic()
                        .foregroundColor(Color.momentum.gray)
                        .multilineTextAlignment(.center)
                }
            }

            // Community badge
            HStack(spacing: Spacing.xs) {
                Image(systemName: "person.3.fill")
                    .font(.caption)
                Text("Shared with Momentum Community")
                    .font(.caption)
            }
            .foregroundColor(Color.momentum.sage)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.momentum.sage.opacity(0.1), Color.momentum.white],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

// MARK: - Share Complete Overlay
struct ShareCompleteOverlay: View {
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5

    var body: some View {
        ZStack {
            Color.momentum.charcoal.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.momentum.sage)
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)

                Text("Shared!")
                    .font(.displayMedium)
                    .foregroundColor(.white)

                Text("Your momentum inspires others")
                    .font(.bodyMedium)
                    .foregroundColor(.white.opacity(0.8))
            }
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
            }

            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ShareToCommunitySheet(
        content: .win(
            description: "Completed my morning routine!",
            size: .medium,
            emotion: 4
        )
    )
    .environmentObject(PurchaseService())
}
