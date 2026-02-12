import SwiftUI

struct BadgesView: View {
    @StateObject private var gamification = GamificationManager.shared
    @State private var selectedBadge: Badge?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Progress Summary
                    BadgeProgressCard()

                    // Earned Badges
                    if !gamification.earnedBadges.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Earned Badges")
                                .font(.titleMedium)
                                .foregroundColor(Color.momentum.charcoal)

                            LazyVGrid(columns: columns, spacing: Spacing.md) {
                                ForEach(Array(gamification.earnedBadges), id: \.self) { badge in
                                    BadgeCard(badge: badge, isEarned: true) {
                                        selectedBadge = badge
                                    }
                                }
                            }
                        }
                    }

                    // Locked Badges
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Badges to Unlock")
                            .font(.titleMedium)
                            .foregroundColor(Color.momentum.charcoal)

                        let lockedBadges = Badge.allCases.filter { !gamification.earnedBadges.contains($0) }

                        LazyVGrid(columns: columns, spacing: Spacing.md) {
                            ForEach(lockedBadges) { badge in
                                BadgeCard(badge: badge, isEarned: false) {
                                    selectedBadge = badge
                                }
                            }
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationTitle("Badges")
            .sheet(item: $selectedBadge) { badge in
                BadgeDetailSheet(badge: badge, isEarned: gamification.earnedBadges.contains(badge))
            }
        }
    }
}

// MARK: - Badge Progress Card
struct BadgeProgressCard: View {
    @StateObject private var gamification = GamificationManager.shared

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(gamification.earnedBadges.count)")
                        .font(.displayLarge)
                        .foregroundColor(Color.momentum.coral)

                    Text("of \(Badge.allCases.count) badges earned")
                        .font(.bodySmall)
                        .foregroundColor(Color.momentum.gray)
                }

                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.momentum.cream, lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: Double(gamification.earnedBadges.count) / Double(Badge.allCases.count))
                        .stroke(
                            LinearGradient(
                                colors: [Color.momentum.coral, Color.momentum.plum],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(Double(gamification.earnedBadges.count) / Double(Badge.allCases.count) * 100))%")
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.charcoal)
                }
            }

            // Next badge hint
            if let nextBadge = Badge.allCases.first(where: { !gamification.earnedBadges.contains($0) }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(Color.momentum.gold)

                    Text("Next: \(nextBadge.rawValue) - \(nextBadge.description)")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)

                    Spacer()
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.lg)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow()
    }
}

// MARK: - Badge Card
struct BadgeCard: View {
    let badge: Badge
    let isEarned: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(isEarned ? badge.color.opacity(0.15) : Color.momentum.gray.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: badge.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isEarned ? badge.color : Color.momentum.gray.opacity(0.4))
                }

                Text(badge.rawValue)
                    .font(.caption)
                    .foregroundColor(isEarned ? Color.momentum.charcoal : Color.momentum.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(Color.momentum.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .opacity(isEarned ? 1 : 0.6)
        }
    }
}

// MARK: - Badge Detail Sheet
struct BadgeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let badge: Badge
    let isEarned: Bool

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Badge icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isEarned ? [badge.color, badge.color.opacity(0.7)] : [Color.momentum.gray.opacity(0.3), Color.momentum.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: badge.icon)
                    .font(.system(size: 50))
                    .foregroundColor(.white)

                if !isEarned {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.momentum.gray)
                        .offset(x: 40, y: 40)
                }
            }

            VStack(spacing: Spacing.md) {
                Text(badge.rawValue)
                    .font(.displayMedium)
                    .foregroundColor(Color.momentum.charcoal)

                Text(badge.description)
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.center)

                HStack(spacing: Spacing.sm) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color.momentum.gold)
                    Text("+\(badge.xpReward) XP")
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.gold)
                }
                .padding(.top, Spacing.sm)
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()

            if isEarned {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.momentum.sage)

                    Text("Badge Earned!")
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.sage)
                }
            } else {
                Text("Keep going to unlock this badge!")
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
            }

            Button("Close") {
                dismiss()
            }
            .font(.bodyMedium)
            .foregroundColor(Color.momentum.coral)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.momentum.cream.ignoresSafeArea())
    }
}

// MARK: - Badge Unlock Overlay
struct BadgeUnlockOverlay: View {
    let badge: Badge
    let onDismiss: () -> Void

    @State private var showBadge = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                Text("Badge Unlocked!")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(2)

                ZStack {
                    // Glow effect
                    Circle()
                        .fill(badge.color.opacity(0.3))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)

                    Circle()
                        .fill(badge.color)
                        .frame(width: 120, height: 120)

                    Image(systemName: badge.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                .scaleEffect(showBadge ? 1 : 0.5)
                .opacity(showBadge ? 1 : 0)

                VStack(spacing: Spacing.sm) {
                    Text(badge.rawValue)
                        .font(.displayMedium)
                        .foregroundColor(.white)

                    Text(badge.description)
                        .font(.bodyMedium)
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "star.fill")
                        Text("+\(badge.xpReward) XP")
                    }
                    .font(.titleSmall)
                    .foregroundColor(Color.momentum.gold)
                    .padding(.top, Spacing.sm)
                }

                Spacer()

                Button(action: onDismiss) {
                    Text("Awesome!")
                        .font(.titleSmall)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(badge.color)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
            }
        }
        .confetti(isShowing: $showConfetti, intensity: 70)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showBadge = true
            }
            showConfetti = true
        }
    }
}

#Preview {
    BadgesView()
}
