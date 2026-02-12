import SwiftUI

// MARK: - Milestone Type
enum MilestoneType: Int, CaseIterable {
    case quarter = 25
    case half = 50
    case threeQuarter = 75
    case complete = 100

    var displayName: String {
        switch self {
        case .quarter: return "25% Complete"
        case .half: return "Halfway There"
        case .threeQuarter: return "75% Complete"
        case .complete: return "Goal Complete"
        }
    }

    var emoji: String {
        switch self {
        case .quarter: return "🌱"
        case .half: return "🔥"
        case .threeQuarter: return "🚀"
        case .complete: return "🏆"
        }
    }

    var message: String {
        switch self {
        case .quarter: return "You're building momentum!"
        case .half: return "You're halfway to your goal!"
        case .threeQuarter: return "The finish line is in sight!"
        case .complete: return "You did it! Time to celebrate!"
        }
    }

    var confettiIntensity: Int {
        switch self {
        case .quarter: return 30
        case .half: return 50
        case .threeQuarter: return 75
        case .complete: return 100
        }
    }

    var xpBonus: Int {
        switch self {
        case .quarter: return 50
        case .half: return 100
        case .threeQuarter: return 150
        case .complete: return 300
        }
    }

    static func from(progress: Double) -> MilestoneType? {
        let percentage = Int(progress * 100)
        switch percentage {
        case 25: return .quarter
        case 50: return .half
        case 75: return .threeQuarter
        case 100: return .complete
        default: return nil
        }
    }
}

// MARK: - Milestone Sheet
struct MilestoneSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gamification = GamificationManager.shared

    let goal: Goal
    let milestone: MilestoneType
    var onShare: (() -> Void)?

    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Milestone emoji (animated)
            Text(milestone.emoji)
                .font(.system(size: 80))
                .scaleEffect(showConfetti ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)

            // Milestone title
            VStack(spacing: Spacing.md) {
                Text(milestone.displayName)
                    .font(.displayLarge)
                    .foregroundColor(Color.momentum.charcoal)

                Text(milestone.message)
                    .font(.bodyLarge)
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.center)
            }

            // Goal info
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: goal.category.icon)
                        .foregroundColor(goal.category.color)
                    Text(goal.title)
                        .font(.titleMedium)
                        .foregroundColor(Color.momentum.charcoal)
                }

                // Progress ring
                GoalProgressRing(goal: goal, size: 100, lineWidth: 10)
            }
            .padding(Spacing.lg)
            .background(Color.momentum.cream)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

            // XP reward
            HStack(spacing: Spacing.xs) {
                Image(systemName: "star.fill")
                    .foregroundColor(Color.momentum.gold)
                Text("+\(milestone.xpBonus) XP")
                    .font(.titleMedium)
                    .foregroundColor(Color.momentum.gold)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(Color.momentum.gold.opacity(0.15))
            .clipShape(Capsule())

            Spacer()

            // Actions
            VStack(spacing: Spacing.md) {
                // Share button
                Button {
                    onShare?()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Your Progress")
                    }
                    .font(.titleSmall)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.momentum.coral)
                    .clipShape(Capsule())
                }

                // Continue button
                Button {
                    dismiss()
                } label: {
                    Text("Keep Going!")
                        .font(.bodyMedium)
                        .foregroundColor(Color.momentum.gray)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.momentum.white.ignoresSafeArea())
        .confetti(isShowing: $showConfetti, intensity: milestone.confettiIntensity)
        .onAppear {
            // Award XP
            gamification.addXP(milestone.xpBonus)

            // Trigger confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }

            // Haptic
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        }
    }
}

// MARK: - Milestone Detection Helper
struct MilestoneTracker {
    /// Checks if the goal just crossed a milestone threshold
    /// Returns the milestone if crossed, nil otherwise
    static func checkMilestone(previousProgress: Double, currentProgress: Double) -> MilestoneType? {
        let milestones: [Double] = [0.25, 0.50, 0.75, 1.0]

        for threshold in milestones {
            if previousProgress < threshold && currentProgress >= threshold {
                return MilestoneType.from(progress: threshold)
            }
        }

        return nil
    }
}

// MARK: - Preview
#Preview {
    MilestoneSheet(
        goal: Goal(
            title: "Launch My Business",
            affirmation: "I am a successful entrepreneur",
            category: .career
        ),
        milestone: .half
    )
}
