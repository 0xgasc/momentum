import SwiftUI

// MARK: - Celebration Reaction View
/// "Celebrate" button for reacting to others' wins in the community feed
struct CelebrationReactionView: View {
    let winId: String
    @State private var hasCelebrated = false
    @State private var celebrationCount: Int
    @State private var showAnimation = false

    init(winId: String, initialCount: Int = 0) {
        self.winId = winId
        self._celebrationCount = State(initialValue: initialCount)
    }

    var body: some View {
        Button {
            celebrate()
        } label: {
            HStack(spacing: Spacing.xs) {
                // Clap emoji with animation
                Text("👏")
                    .font(.system(size: 16))
                    .scaleEffect(showAnimation ? 1.3 : 1.0)
                    .rotationEffect(.degrees(showAnimation ? 15 : 0))

                // Count
                if celebrationCount > 0 {
                    Text("\(celebrationCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(hasCelebrated ? Color.momentum.coral : Color.momentum.gray)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                hasCelebrated
                    ? Color.momentum.coral.opacity(0.15)
                    : Color.momentum.gray.opacity(0.1)
            )
            .clipShape(Capsule())
        }
        .disabled(hasCelebrated)
    }

    private func celebrate() {
        guard !hasCelebrated else { return }

        hasCelebrated = true
        celebrationCount += 1

        // Animate
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            showAnimation = true
        }

        // Reset animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showAnimation = false
            }
        }

        // Haptic
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Send to CloudKit
        Task {
            await CloudKitManager.shared.celebrateWin(winId: winId)
        }
    }
}

// MARK: - Multiple Reaction Options
struct ReactionBar: View {
    let winId: String
    @State private var selectedReaction: ReactionType?
    @State private var reactions: [ReactionType: Int] = [:]

    enum ReactionType: String, CaseIterable {
        case celebrate = "👏"
        case love = "❤️"
        case fire = "🔥"
        case star = "⭐️"

        var color: Color {
            switch self {
            case .celebrate: return Color.momentum.coral
            case .love: return Color.momentum.plum
            case .fire: return Color.momentum.gold
            case .star: return Color.momentum.sage
            }
        }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(ReactionType.allCases, id: \.self) { reaction in
                ReactionButton(
                    emoji: reaction.rawValue,
                    count: reactions[reaction] ?? 0,
                    isSelected: selectedReaction == reaction,
                    color: reaction.color
                ) {
                    toggleReaction(reaction)
                }
            }
        }
    }

    private func toggleReaction(_ reaction: ReactionType) {
        if selectedReaction == reaction {
            // Deselect
            selectedReaction = nil
            reactions[reaction] = max(0, (reactions[reaction] ?? 1) - 1)
        } else {
            // Remove previous selection if any
            if let previous = selectedReaction {
                reactions[previous] = max(0, (reactions[previous] ?? 1) - 1)
            }
            // Select new
            selectedReaction = reaction
            reactions[reaction] = (reactions[reaction] ?? 0) + 1
        }

        // Haptic
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // TODO: Send to CloudKit
    }
}

struct ReactionButton: View {
    let emoji: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    @State private var animating = false

    var body: some View {
        Button(action: {
            action()
            animate()
        }) {
            HStack(spacing: 2) {
                Text(emoji)
                    .font(.system(size: 14))
                    .scaleEffect(animating ? 1.3 : 1.0)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? color : Color.momentum.gray)
                }
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 4)
            .background(
                isSelected ? color.opacity(0.15) : Color.clear
            )
            .clipShape(Capsule())
        }
    }

    private func animate() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            animating = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animating = false
        }
    }
}

// MARK: - Compact Celebrate Button
/// Simpler single-button version for tight spaces
struct CompactCelebrateButton: View {
    let winId: String
    var size: CGFloat = 32

    @State private var hasCelebrated = false
    @State private var animating = false

    var body: some View {
        Button {
            celebrate()
        } label: {
            ZStack {
                Circle()
                    .fill(hasCelebrated ? Color.momentum.coral.opacity(0.15) : Color.momentum.cream)
                    .frame(width: size, height: size)

                Text("👏")
                    .font(.system(size: size * 0.5))
                    .scaleEffect(animating ? 1.3 : 1.0)
            }
        }
        .disabled(hasCelebrated)
    }

    private func celebrate() {
        guard !hasCelebrated else { return }

        hasCelebrated = true

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            animating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animating = false
        }

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        Task {
            await CloudKitManager.shared.celebrateWin(winId: winId)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        // Single celebrate button
        CelebrationReactionView(winId: "test1", initialCount: 5)

        // Compact version
        CompactCelebrateButton(winId: "test2")

        // Full reaction bar
        ReactionBar(winId: "test3")
    }
    .padding()
    .background(Color.momentum.cream)
}
