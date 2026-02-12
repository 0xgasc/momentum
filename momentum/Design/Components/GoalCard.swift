import SwiftUI

struct GoalCard: View {
    let goal: Goal
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    // Category icon
                    Circle()
                        .fill(goal.category.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: goal.category.icon)
                                .font(.system(size: 18))
                                .foregroundColor(goal.category.color)
                        )

                    Spacer()

                    // Progress indicator
                    if !goal.actions.isEmpty {
                        CircularProgress(progress: goal.progressPercentage, color: goal.category.color)
                            .frame(width: 32, height: 32)
                    }
                }

                Text(goal.title)
                    .font(.titleSmall)
                    .foregroundColor(Color.momentum.charcoal)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let targetDate = goal.targetDate {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(targetDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                    }
                    .foregroundColor(Color.momentum.gray)
                }

                // Stats
                HStack(spacing: Spacing.md) {
                    Label("\(goal.activeActions.count)", systemImage: "checklist")
                    Label("\(goal.wins.count)", systemImage: "trophy.fill")
                }
                .font(.caption)
                .foregroundColor(Color.momentum.gray)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.momentum.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .momentumShadow(radius: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct CircularProgress: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    init(progress: Double, color: Color, lineWidth: CGFloat = 3) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

// MARK: - Goal Grid Item
struct GoalGridItem: View {
    let goal: Goal
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                Circle()
                    .fill(goal.category.color.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: goal.category.icon)
                            .font(.system(size: 24))
                            .foregroundColor(goal.category.color)
                    )

                Text(goal.title)
                    .font(.bodySmall)
                    .foregroundColor(Color.momentum.charcoal)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if !goal.actions.isEmpty {
                    CircularProgress(progress: goal.progressPercentage, color: goal.category.color)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.momentum.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .momentumShadow(radius: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    let goal = Goal(
        title: "Launch my side project",
        affirmation: "I am a successful entrepreneur",
        category: .career,
        targetDate: Date().addingTimeInterval(86400 * 30)
    )

    VStack(spacing: 20) {
        GoalCard(goal: goal, onTap: {})

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            GoalGridItem(goal: goal, onTap: {})
            GoalGridItem(goal: goal, onTap: {})
        }
    }
    .padding()
    .background(Color.momentum.cream)
}
