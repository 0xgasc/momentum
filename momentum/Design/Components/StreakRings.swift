import SwiftUI

struct StreakRings: View {
    let actionsCompleted: Int
    let actionsGoal: Int
    let winsLogged: Int
    let winsGoal: Int

    var body: some View {
        ZStack {
            // Outer ring - Actions
            Circle()
                .stroke(Color.momentum.coral.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: actionsProgress)
                .stroke(
                    Color.momentum.coral,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: actionsProgress)

            // Inner ring - Wins
            Circle()
                .stroke(Color.momentum.gold.opacity(0.2), lineWidth: 6)
                .padding(12)

            Circle()
                .trim(from: 0, to: winsProgress)
                .stroke(
                    Color.momentum.gold,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(12)
                .animation(.spring(response: 0.6), value: winsProgress)

            // Center content
            VStack(spacing: 2) {
                Text("\(actionsCompleted)")
                    .font(.titleLarge)
                    .foregroundColor(Color.momentum.charcoal)
                Text("today")
                    .font(.caption)
                    .foregroundColor(Color.momentum.gray)
            }
        }
    }

    private var actionsProgress: CGFloat {
        guard actionsGoal > 0 else { return 0 }
        return min(1, CGFloat(actionsCompleted) / CGFloat(actionsGoal))
    }

    private var winsProgress: CGFloat {
        guard winsGoal > 0 else { return 0 }
        return min(1, CGFloat(winsLogged) / CGFloat(winsGoal))
    }
}

// MARK: - Stats Row
struct StatsRow: View {
    let totalWins: Int
    let currentStreak: Int
    let actionsToday: Int
    let actionsGoal: Int

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Win counter
            StatCard(
                icon: "trophy.fill",
                value: "\(totalWins)",
                label: "Total Wins",
                color: Color.momentum.gold
            )

            // Streak rings
            StreakRings(
                actionsCompleted: actionsToday,
                actionsGoal: actionsGoal,
                winsLogged: min(actionsToday, 3),
                winsGoal: 3
            )
            .frame(width: 80, height: 80)

            // Streak counter
            StatCard(
                icon: "flame.fill",
                value: "\(currentStreak)",
                label: "Day Streak",
                color: Color.momentum.coral
            )
        }
        .padding(Spacing.md)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow()
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.titleLarge)
                .foregroundColor(Color.momentum.charcoal)

            Text(label)
                .font(.caption)
                .foregroundColor(Color.momentum.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakRings(
            actionsCompleted: 3,
            actionsGoal: 5,
            winsLogged: 2,
            winsGoal: 3
        )
        .frame(width: 120, height: 120)

        StatsRow(
            totalWins: 47,
            currentStreak: 12,
            actionsToday: 3,
            actionsGoal: 5
        )
        .padding()
    }
    .background(Color.momentum.cream)
}
