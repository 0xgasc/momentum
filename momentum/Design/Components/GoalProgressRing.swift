import SwiftUI

// MARK: - Goal Progress Ring
/// Circular progress indicator with milestone markers at 25%, 50%, 75%
struct GoalProgressRing: View {
    let goal: Goal
    var size: CGFloat = 120
    var lineWidth: CGFloat = 12

    private var progress: Double {
        goal.progressPercentage
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(goal.category.color.opacity(0.2), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    goal.category.color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: progress)

            // Milestone markers
            ForEach([0.25, 0.5, 0.75], id: \.self) { milestone in
                MilestoneMarker(
                    milestone: milestone,
                    isReached: progress >= milestone,
                    color: goal.category.color,
                    ringSize: size,
                    lineWidth: lineWidth
                )
            }

            // Center content
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.titleMedium)
                    .foregroundColor(Color.momentum.charcoal)

                Text("\(goal.completedActions.count)/\(goal.actions.count)")
                    .font(.caption)
                    .foregroundColor(Color.momentum.gray)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Milestone Marker
struct MilestoneMarker: View {
    let milestone: Double
    let isReached: Bool
    let color: Color
    let ringSize: CGFloat
    let lineWidth: CGFloat

    private var angle: Double {
        (milestone * 360) - 90 // Offset by -90 to start from top
    }

    private var markerSize: CGFloat {
        lineWidth + 8
    }

    var body: some View {
        Circle()
            .fill(isReached ? color : Color.momentum.cream)
            .frame(width: markerSize, height: markerSize)
            .overlay(
                Circle()
                    .strokeBorder(
                        isReached ? color : Color.momentum.gray.opacity(0.3),
                        lineWidth: 2
                    )
            )
            .overlay(
                Group {
                    if isReached {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            )
            .offset(x: (ringSize / 2) * cos(angle * .pi / 180),
                    y: (ringSize / 2) * sin(angle * .pi / 180))
    }
}

// MARK: - Compact Progress Ring
/// Smaller version for list items
struct CompactProgressRing: View {
    let progress: Double
    let color: Color
    var size: CGFloat = 44
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 32) {
        GoalProgressRing(
            goal: Goal(
                title: "Launch My Business",
                affirmation: "I am a successful entrepreneur",
                category: .career
            )
        )

        HStack(spacing: 24) {
            CompactProgressRing(progress: 0.25, color: Color.momentum.coral)
            CompactProgressRing(progress: 0.50, color: Color.momentum.sage)
            CompactProgressRing(progress: 0.75, color: Color.momentum.plum)
            CompactProgressRing(progress: 1.0, color: Color.momentum.gold)
        }
    }
    .padding()
    .background(Color.momentum.cream)
}
