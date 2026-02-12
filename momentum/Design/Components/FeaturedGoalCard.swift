import SwiftUI

// MARK: - Featured Goal Card
/// Large, bold card for the hero/priority goal on the vision board
struct FeaturedGoalCard: View {
    let goal: Goal
    var onTap: (() -> Void)?
    var onShare: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: Spacing.lg) {
                // Top section: Icon + Category
                HStack {
                    // Large category icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        goal.category.color,
                                        goal.category.color.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: goal.category.icon)
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Share button
                    if onShare != nil {
                        Button {
                            onShare?()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(goal.category.color)
                                .padding(Spacing.sm)
                                .background(goal.category.color.opacity(0.15))
                                .clipShape(Circle())
                        }
                    }
                }

                // Title
                Text(goal.title)
                    .font(.displayLarge)
                    .foregroundColor(Color.momentum.charcoal)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Affirmation (italic)
                Text("\"\(goal.affirmation)\"")
                    .font(.bodyMedium)
                    .italic()
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Progress ring + Stats row
                HStack(spacing: Spacing.lg) {
                    GoalProgressRing(goal: goal, size: 100, lineWidth: 10)

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        // Actions stat
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.momentum.sage)
                            Text("\(goal.completedActions.count) of \(goal.actions.count) actions")
                                .font(.bodySmall)
                                .foregroundColor(Color.momentum.charcoal)
                        }

                        // Wins stat
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(Color.momentum.gold)
                            Text("\(goal.wins.count) wins logged")
                                .font(.bodySmall)
                                .foregroundColor(Color.momentum.charcoal)
                        }

                        // Target date if set
                        if let targetDate = goal.targetDate {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "calendar")
                                    .foregroundColor(Color.momentum.coral)
                                Text("Target: \(targetDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.bodySmall)
                                    .foregroundColor(Color.momentum.charcoal)
                            }
                        }
                    }

                    Spacer()
                }

                // Next action preview (if available)
                if let nextAction = goal.activeActions.first {
                    NextActionPreview(action: nextAction)
                }
            }
            .padding(Spacing.lg)
            .background(
                LinearGradient(
                    colors: [
                        goal.category.color.opacity(0.1),
                        Color.momentum.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(goal.category.color.opacity(0.2), lineWidth: 1)
            )
            .momentumShadow(radius: 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Next Action Preview
struct NextActionPreview: View {
    let action: MicroAction

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(Color.momentum.coral)

            Text("Next: \(action.title)")
                .font(.bodySmall)
                .foregroundColor(Color.momentum.charcoal)
                .lineLimit(1)

            Spacer()

            Image(systemName: action.actionType.icon)
                .font(.system(size: 12))
                .foregroundColor(Color.momentum.gray)
        }
        .padding(Spacing.sm)
        .background(Color.momentum.cream)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

// MARK: - Compact Goal Card
/// Smaller card for category sections in the vision board
struct CompactGoalCard: View {
    let goal: Goal
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(goal.category.color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: goal.category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(goal.category.color)
                }

                // Title
                Text(goal.title)
                    .font(.titleSmall)
                    .foregroundColor(Color.momentum.charcoal)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Spacer()

                // Progress
                HStack {
                    CompactProgressRing(
                        progress: goal.progressPercentage,
                        color: goal.category.color,
                        size: 32,
                        lineWidth: 3
                    )

                    Spacer()

                    Text("\(goal.activeActions.count) actions")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                }
            }
            .padding(Spacing.md)
            .frame(width: 160, height: 180)
            .background(Color.momentum.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .momentumShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            FeaturedGoalCard(
                goal: Goal(
                    title: "Launch My Online Business",
                    affirmation: "I am building something meaningful",
                    category: .career,
                    targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())
                ),
                onTap: {},
                onShare: {}
            )

            HStack(spacing: Spacing.md) {
                CompactGoalCard(
                    goal: Goal(
                        title: "Get Fit",
                        affirmation: "I am healthy",
                        category: .wellness
                    )
                )

                CompactGoalCard(
                    goal: Goal(
                        title: "Learn Spanish",
                        affirmation: "I am fluent",
                        category: .growth
                    )
                )
            }
        }
        .padding()
    }
    .background(Color.momentum.cream)
}
