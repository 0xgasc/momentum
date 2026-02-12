import SwiftUI
import SwiftData

struct ChallengesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activeChallenges: [Challenge]
    @StateObject private var gamification = GamificationManager.shared

    @State private var showRandomChallenge = false
    @State private var randomChallenge: ChallengeTemplate?
    @State private var selectedDuration: ChallengeDuration = .daily
    @State private var challengeToComplete: Challenge?

    private var focusAreas: Set<GoalCategory> {
        UserProfileManager.shared.profile.focusAreas
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Daily Challenge
                    TodaysChallengeCard(
                        onAccept: { challenge in
                            acceptChallenge(challenge)
                        },
                        onRandomize: {
                            generateRandomChallenge()
                        }
                    )

                    // Active Challenges
                    if !activeChallenges.filter({ $0.isActive && !$0.isCompleted }).isEmpty {
                        ActiveChallengesSection(
                            challenges: activeChallenges.filter { $0.isActive && !$0.isCompleted },
                            onComplete: { challenge in
                                // Open completion sheet instead of direct completion
                                challengeToComplete = challenge
                            }
                        )
                    }

                    // Challenge Categories
                    ChallengeCategoriesSection(
                        selectedDuration: $selectedDuration,
                        onSelectChallenge: { template in
                            acceptChallenge(template.toChallenge())
                        }
                    )

                    // Completed Challenges
                    let completed = activeChallenges.filter { $0.isCompleted }
                    if !completed.isEmpty {
                        CompletedChallengesSection(challenges: completed)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationTitle("Challenges")
        }
        .sheet(isPresented: $showRandomChallenge) {
            if let challenge = randomChallenge {
                RandomChallengeSheet(
                    challenge: challenge,
                    onAccept: {
                        acceptChallenge(challenge.toChallenge())
                        showRandomChallenge = false
                    },
                    onReroll: {
                        generateRandomChallenge()
                    }
                )
            }
        }
        .sheet(item: $challengeToComplete) { challenge in
            ChallengeCompletionSheet(
                challenge: challenge,
                onComplete: {
                    handleChallengeCompletion(challenge)
                }
            )
        }
    }

    private func generateRandomChallenge() {
        let allChallenges = ChallengeTemplates.dailyChallenges(for: focusAreas)
            + ChallengeTemplates.weeklyChallenges(for: focusAreas)

        randomChallenge = allChallenges.randomElement()
        showRandomChallenge = true
    }

    private func acceptChallenge(_ challenge: Challenge) {
        challenge.isActive = true
        challenge.startedAt = Date()

        // Set expiration based on duration
        switch challenge.duration {
        case .daily:
            challenge.expiresAt = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .weekly:
            challenge.expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        case .monthly:
            challenge.expiresAt = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        }

        modelContext.insert(challenge)
        try? modelContext.save()

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    /// Called after the ChallengeCompletionSheet completes a challenge
    /// Handles XP, badges, and pattern tracking (completion state is already saved by the sheet)
    private func handleChallengeCompletion(_ challenge: Challenge) {
        // Award XP
        gamification.addXP(challenge.xpReward)

        // Check badges
        let completedCount = activeChallenges.filter { $0.isCompleted }.count
        if completedCount == 1 { gamification.unlockBadge(.challengeAccepted) }
        if completedCount >= 10 { gamification.unlockBadge(.challengeChamp) }
        if challenge.difficulty == .epic { gamification.unlockBadge(.epicConqueror) }

        // Record completion for pattern-based badges and milestone wins
        gamification.recordChallengeCompletion(challenge: challenge, context: modelContext)
    }
}

// MARK: - Today's Challenge Card
struct TodaysChallengeCard: View {
    let onAccept: (Challenge) -> Void
    let onRandomize: () -> Void

    @State private var todaysChallenge: ChallengeTemplate?

    private var focusAreas: Set<GoalCategory> {
        UserProfileManager.shared.profile.focusAreas
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Challenge")
                        .font(.caption)
                        .foregroundColor(Color.momentum.coral)
                        .textCase(.uppercase)
                        .tracking(1.2)

                    if let challenge = todaysChallenge {
                        Text(challenge.title)
                            .font(.titleMedium)
                            .foregroundColor(Color.momentum.charcoal)
                    }
                }

                Spacer()

                Button(action: onRandomize) {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.momentum.plum)
                }
            }

            if let challenge = todaysChallenge {
                Text(challenge.description)
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)

                HStack {
                    // Difficulty badge
                    Text(challenge.difficulty.rawValue)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(challenge.difficulty.color)
                        .clipShape(Capsule())

                    // XP reward
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("+\(challenge.xpReward) XP")
                            .font(.caption)
                    }
                    .foregroundColor(Color.momentum.gold)

                    Spacer()

                    Button {
                        onAccept(challenge.toChallenge())
                        generateNewChallenge()
                    } label: {
                        Text("Accept")
                            .font(.titleSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.momentum.coral)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(
            LinearGradient(
                colors: [Color.momentum.coral.opacity(0.1), Color.momentum.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(Color.momentum.coral.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            generateNewChallenge()
        }
    }

    private func generateNewChallenge() {
        let dailyChallenges = ChallengeTemplates.dailyChallenges(for: focusAreas)
        todaysChallenge = dailyChallenges.randomElement()
    }
}

// MARK: - Active Challenges Section
struct ActiveChallengesSection: View {
    let challenges: [Challenge]
    let onComplete: (Challenge) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Active Challenges")
                .font(.titleMedium)
                .foregroundColor(Color.momentum.charcoal)

            ForEach(challenges) { challenge in
                ActiveChallengeCard(challenge: challenge, onComplete: {
                    onComplete(challenge)
                })
            }
        }
    }
}

struct ActiveChallengeCard: View {
    let challenge: Challenge
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Category icon
            ZStack {
                Circle()
                    .fill(challenge.category.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: challenge.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(challenge.category.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.titleSmall)
                    .foregroundColor(Color.momentum.charcoal)

                HStack(spacing: Spacing.xs) {
                    Text(challenge.duration.rawValue)
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)

                    if let expires = challenge.expiresAt {
                        Text("• \(timeRemaining(until: expires))")
                            .font(.caption)
                            .foregroundColor(Color.momentum.coral)
                    }
                }
            }

            Spacer()

            Button(action: onComplete) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.momentum.sage)
            }
        }
        .padding(Spacing.md)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow(radius: 2)
    }

    private func timeRemaining(until date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        if diff < 3600 {
            return "\(Int(diff / 60))m left"
        } else if diff < 86400 {
            return "\(Int(diff / 3600))h left"
        } else {
            return "\(Int(diff / 86400))d left"
        }
    }
}

// MARK: - Challenge Categories Section
struct ChallengeCategoriesSection: View {
    @Binding var selectedDuration: ChallengeDuration
    let onSelectChallenge: (ChallengeTemplate) -> Void

    private var focusAreas: Set<GoalCategory> {
        UserProfileManager.shared.profile.focusAreas
    }

    private var challenges: [ChallengeTemplate] {
        switch selectedDuration {
        case .daily:
            return ChallengeTemplates.dailyChallenges(for: focusAreas)
        case .weekly:
            return ChallengeTemplates.weeklyChallenges(for: focusAreas)
        case .monthly:
            return ChallengeTemplates.monthlyChallenges(for: focusAreas)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Browse Challenges")
                .font(.titleMedium)
                .foregroundColor(Color.momentum.charcoal)

            // Duration picker
            HStack(spacing: Spacing.xs) {
                ForEach(ChallengeDuration.allCases, id: \.self) { duration in
                    Button {
                        selectedDuration = duration
                    } label: {
                        Text(duration.rawValue)
                            .font(.bodySmall)
                            .foregroundColor(selectedDuration == duration ? .white : Color.momentum.charcoal)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(selectedDuration == duration ? Color.momentum.plum : Color.momentum.cream)
                            .clipShape(Capsule())
                    }
                }
            }

            // Challenge list
            ForEach(challenges.prefix(5), id: \.title) { template in
                ChallengeBrowseCard(template: template) {
                    onSelectChallenge(template)
                }
            }
        }
    }
}

struct ChallengeBrowseCard: View {
    let template: ChallengeTemplate
    let onAccept: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(template.category.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: template.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(template.category.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(template.title)
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.charcoal)

                HStack(spacing: Spacing.xs) {
                    Text(template.difficulty.rawValue)
                        .font(.caption)
                        .foregroundColor(template.difficulty.color)

                    Text("• +\(template.xpReward) XP")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gold)
                }
            }

            Spacer()

            Button(action: onAccept) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.momentum.coral)
            }
        }
        .padding(Spacing.sm)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

// MARK: - Completed Challenges Section
struct CompletedChallengesSection: View {
    let challenges: [Challenge]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Completed")
                    .font(.titleMedium)
                    .foregroundColor(Color.momentum.charcoal)

                Spacer()

                Text("\(challenges.count) total")
                    .font(.caption)
                    .foregroundColor(Color.momentum.gray)
            }

            ForEach(challenges.prefix(3)) { challenge in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.momentum.sage)

                    Text(challenge.title)
                        .font(.bodySmall)
                        .foregroundColor(Color.momentum.gray)
                        .strikethrough()

                    Spacer()

                    Text("+\(challenge.xpReward) XP")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gold)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.momentum.sage.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

// MARK: - Random Challenge Sheet
struct RandomChallengeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let challenge: ChallengeTemplate
    let onAccept: () -> Void
    let onReroll: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Dice animation
            Image(systemName: "dice.fill")
                .font(.system(size: 80))
                .foregroundColor(Color.momentum.plum)

            VStack(spacing: Spacing.md) {
                Text("Your Challenge")
                    .font(.caption)
                    .foregroundColor(Color.momentum.gray)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text(challenge.title)
                    .font(.displayMedium)
                    .foregroundColor(Color.momentum.charcoal)
                    .multilineTextAlignment(.center)

                Text(challenge.description)
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: Spacing.md) {
                    // Difficulty
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                        Text(challenge.difficulty.rawValue)
                            .font(.bodySmall)
                    }
                    .foregroundColor(challenge.difficulty.color)

                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(challenge.duration.rawValue)
                            .font(.bodySmall)
                    }
                    .foregroundColor(Color.momentum.gray)

                    // XP
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("+\(challenge.xpReward) XP")
                            .font(.bodySmall)
                    }
                    .foregroundColor(Color.momentum.gold)
                }
            }

            Spacer()

            VStack(spacing: Spacing.md) {
                Button(action: onAccept) {
                    Text("Accept Challenge")
                        .font(.titleSmall)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.momentum.coral)
                        .clipShape(Capsule())
                }

                Button(action: onReroll) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Roll Again")
                    }
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.plum)
                }

                Button("Maybe Later") {
                    dismiss()
                }
                .font(.bodySmall)
                .foregroundColor(Color.momentum.gray)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.momentum.cream.ignoresSafeArea())
    }
}

#Preview {
    ChallengesView()
}
