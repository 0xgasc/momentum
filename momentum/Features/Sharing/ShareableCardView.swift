import SwiftUI

// MARK: - Shareable Card Type
/// Different types of cards that can be shared
enum ShareableCardType {
    case dailySummary(actions: Int, wins: Int, streak: Int)
    case weeklyRecap(stats: WeeklyStats)
    case goalMilestone(goalTitle: String, category: GoalCategory, milestone: Double)
    case streakCelebration(days: Int)
    case winCelebration(description: String, size: WinSize, emotion: Int)

    var title: String {
        switch self {
        case .dailySummary: return "Today's Momentum"
        case .weeklyRecap: return "Weekly Recap"
        case .goalMilestone: return "Milestone Reached"
        case .streakCelebration: return "Streak Achievement"
        case .winCelebration: return "Win Celebrated"
        }
    }

    var icon: String {
        switch self {
        case .dailySummary: return "sun.max.fill"
        case .weeklyRecap: return "calendar"
        case .goalMilestone: return "flag.fill"
        case .streakCelebration: return "flame.fill"
        case .winCelebration: return "trophy.fill"
        }
    }
}

// MARK: - Shareable Card View
/// The main view that gets rendered to an image for sharing
struct ShareableCardView: View {
    let cardType: ShareableCardType
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ShareableCardHeader(cardType: cardType, style: style)

            Spacer()

            // Dynamic content based on type
            cardContent

            Spacer()

            // Footer with branding
            if style.showBranding {
                ShareableCardFooter(style: style)
            }
        }
        .frame(width: 375, height: 667)
        .background(style.backgroundGradient)
    }

    @ViewBuilder
    private var cardContent: some View {
        switch cardType {
        case .dailySummary(let actions, let wins, let streak):
            DailySummaryContent(
                actions: actions,
                wins: wins,
                streak: streak,
                style: style
            )

        case .weeklyRecap(let stats):
            WeeklyRecapContent(stats: stats, style: style)

        case .goalMilestone(let goalTitle, let category, let milestone):
            GoalMilestoneContent(
                goalTitle: goalTitle,
                category: category,
                milestone: milestone,
                style: style
            )

        case .streakCelebration(let days):
            StreakCelebrationContent(days: days, style: style)

        case .winCelebration(let description, let size, let emotion):
            WinCelebrationContent(
                description: description,
                size: size,
                emotion: emotion,
                style: style
            )
        }
    }
}

// MARK: - Header
struct ShareableCardHeader: View {
    let cardType: ShareableCardType
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Date
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(style.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(1.5)

            // Title
            Text(cardType.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(style.textColor)
        }
        .padding(.top, Spacing.xl)
        .padding(.horizontal, Spacing.lg)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Footer
struct ShareableCardFooter: View {
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // App logo/name
            HStack(spacing: Spacing.xs) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 16))
                Text("momentum")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(style.textColor.opacity(0.7))

            Text("Build your future, one action at a time")
                .font(.caption2)
                .foregroundColor(style.secondaryTextColor.opacity(0.6))
        }
        .padding(.bottom, Spacing.xl)
    }
}

// MARK: - Daily Summary Content
struct DailySummaryContent: View {
    let actions: Int
    let wins: Int
    let streak: Int
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Main stat - streak
            VStack(spacing: Spacing.xs) {
                Text("\(streak)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(style.textColor)

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(style.accentColor)
                    Text("Day Streak")
                        .font(.titleMedium)
                        .foregroundColor(style.textColor)
                }
            }

            // Secondary stats
            HStack(spacing: Spacing.xl) {
                StatBubble(
                    value: "\(actions)",
                    label: "Actions",
                    icon: "checkmark.circle.fill",
                    style: style
                )

                StatBubble(
                    value: "\(wins)",
                    label: "Wins",
                    icon: "trophy.fill",
                    style: style
                )
            }
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Weekly Recap Content
struct WeeklyRecapContent: View {
    let stats: WeeklyStats
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Week stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                ShareStatCard(icon: "checkmark.circle.fill", value: "\(stats.actionsCompleted)", label: "Actions", style: style)
                ShareStatCard(icon: "trophy.fill", value: "\(stats.winsLogged)", label: "Wins", style: style)
                ShareStatCard(icon: "flag.fill", value: "\(stats.challengesCompleted)", label: "Challenges", style: style)
                ShareStatCard(icon: "flame.fill", value: "\(stats.currentStreak)", label: "Day Streak", style: style)
            }

            if let topCategory = stats.topCategory {
                Text("Top focus: \(topCategory)")
                    .font(.bodyMedium)
                    .foregroundColor(style.secondaryTextColor)
            }
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Goal Milestone Content
struct GoalMilestoneContent: View {
    let goalTitle: String
    let category: GoalCategory
    let milestone: Double
    let style: ShareCardStyle

    var milestoneText: String {
        switch milestone {
        case 0.25: return "25%"
        case 0.5: return "50%"
        case 0.75: return "75%"
        case 1.0: return "100%"
        default: return "\(Int(milestone * 100))%"
        }
    }

    var celebrationMessage: String {
        switch milestone {
        case 0.25: return "Quarter way there!"
        case 0.5: return "Halfway home!"
        case 0.75: return "Almost there!"
        case 1.0: return "Goal Achieved!"
        default: return "Making progress!"
        }
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Category icon
            ZStack {
                Circle()
                    .fill(style.textColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: category.icon)
                    .font(.system(size: 36))
                    .foregroundColor(style.textColor)
            }

            // Milestone percentage
            Text(milestoneText)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(style.textColor)

            // Celebration message
            Text(celebrationMessage)
                .font(.titleMedium)
                .foregroundColor(style.secondaryTextColor)

            // Goal title
            Text(goalTitle)
                .font(.bodyLarge)
                .foregroundColor(style.textColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, Spacing.lg)
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Streak Celebration Content
struct StreakCelebrationContent: View {
    let days: Int
    let style: ShareCardStyle

    var streakMessage: String {
        switch days {
        case 1...6: return "Building momentum!"
        case 7: return "One week strong!"
        case 8...13: return "Crushing it!"
        case 14: return "Two weeks!"
        case 15...29: return "Unstoppable!"
        case 30: return "One month!"
        case 31...99: return "Legendary!"
        default: return "Icon status!"
        }
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Flame icon with glow effect
            ZStack {
                Circle()
                    .fill(style.accentColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundColor(style.accentColor)
            }

            // Days count
            Text("\(days)")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .foregroundColor(style.textColor)

            Text("Day Streak")
                .font(.titleLarge)
                .foregroundColor(style.textColor)

            Text(streakMessage)
                .font(.bodyMedium)
                .foregroundColor(style.secondaryTextColor)
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Win Celebration Content
struct WinCelebrationContent: View {
    let description: String
    let size: WinSize
    let emotion: Int
    let style: ShareCardStyle

    var emotionEmoji: String {
        switch emotion {
        case 1: return "😊"
        case 2: return "😄"
        case 3: return "🥳"
        case 4: return "🔥"
        case 5: return "🚀"
        default: return "😊"
        }
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Size icon
            Image(systemName: size.icon)
                .font(.system(size: 48))
                .foregroundColor(style.accentColor)

            // Win description
            Text(description)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(style.textColor)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .padding(.horizontal, Spacing.lg)

            // Emotion
            Text(emotionEmoji)
                .font(.system(size: 48))

            // Size label
            Text("\(size.displayName) Win")
                .font(.titleSmall)
                .foregroundColor(style.secondaryTextColor)
                .textCase(.uppercase)
                .tracking(1.2)
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Helper Components
struct StatBubble: View {
    let value: String
    let label: String
    let icon: String
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }
            .foregroundColor(style.textColor)

            Text(label)
                .font(.caption)
                .foregroundColor(style.secondaryTextColor)
        }
        .padding(Spacing.md)
        .background(style.textColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

struct ShareStatCard: View {
    let icon: String
    let value: String
    let label: String
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(style.accentColor)

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(style.textColor)

            Text(label)
                .font(.caption)
                .foregroundColor(style.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(style.textColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

// MARK: - Preview
#Preview("Daily Summary") {
    ShareableCardView(
        cardType: .dailySummary(actions: 5, wins: 2, streak: 14),
        style: ShareCardStyle(backgroundTheme: .coral)
    )
}

#Preview("Streak Celebration") {
    ShareableCardView(
        cardType: .streakCelebration(days: 30),
        style: ShareCardStyle(backgroundTheme: .plum)
    )
}

#Preview("Goal Milestone") {
    ShareableCardView(
        cardType: .goalMilestone(goalTitle: "Launch my side business", category: .career, milestone: 0.5),
        style: ShareCardStyle(backgroundTheme: .sage)
    )
}

#Preview("Win Celebration") {
    ShareableCardView(
        cardType: .winCelebration(description: "Shipped the new feature after 2 weeks of work!", size: .big, emotion: 4),
        style: ShareCardStyle(backgroundTheme: .charcoal)
    )
}
