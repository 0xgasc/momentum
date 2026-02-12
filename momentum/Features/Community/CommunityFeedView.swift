import SwiftUI

/// Community feed showing shared wins from other users
struct CommunityFeedView: View {
    @ObservedObject private var cloudKit = CloudKitManager.shared
    @State private var selectedFilter: FeedFilter = .today

    enum FeedFilter: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case all = "All Time"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Community Stats Header
                CommunityStatsHeader()

                // Filter Pills
                HStack(spacing: Spacing.xs) {
                    ForEach(FeedFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            Text(filter.rawValue)
                                .font(.bodySmall)
                                .foregroundColor(selectedFilter == filter ? .white : Color.momentum.charcoal)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(selectedFilter == filter ? Color.momentum.plum : Color.momentum.cream)
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, Spacing.md)

                // Wins Feed
                LazyVStack(spacing: Spacing.md) {
                    ForEach(filteredWins) { win in
                        CommunityWinCard(win: win)
                    }
                }
                .padding(.horizontal, Spacing.md)

                if cloudKit.recentCommunityWins.isEmpty && !cloudKit.isLoading {
                    EmptyCommunityView()
                }
            }
            .padding(.top, Spacing.md)
        }
        .background(Color.momentum.cream.ignoresSafeArea())
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await cloudKit.fetchRecentWins()
            await cloudKit.refreshCommunityStats()
        }
    }

    private var filteredWins: [CommunityWin] {
        let calendar = Calendar.current
        let now = Date()

        return cloudKit.recentCommunityWins.filter { win in
            switch selectedFilter {
            case .today:
                return calendar.isDateInToday(win.createdAt)
            case .thisWeek:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
                return win.createdAt >= weekAgo
            case .all:
                return true
            }
        }
    }
}

// MARK: - Community Stats Header
struct CommunityStatsHeader: View {
    @ObservedObject private var cloudKit = CloudKitManager.shared

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Live indicator
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(Color.momentum.sage)
                    .frame(width: 8, height: 8)

                Text("Live")
                    .font(.caption)
                    .foregroundColor(Color.momentum.sage)
            }

            // Big number
            Text("\(cloudKit.activeUsersCount)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(Color.momentum.charcoal)

            Text("people building momentum right now")
                .font(.bodyMedium)
                .foregroundColor(Color.momentum.gray)
                .multilineTextAlignment(.center)

            // Secondary stats
            HStack(spacing: Spacing.xl) {
                VStack {
                    Text("\(cloudKit.winsToday)")
                        .font(.titleMedium)
                        .foregroundColor(Color.momentum.gold)
                    Text("wins today")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                }

                VStack {
                    Text("\(cloudKit.streakUsersCount)")
                        .font(.titleMedium)
                        .foregroundColor(Color.momentum.coral)
                    Text("on a streak")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                }
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow()
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Community Win Card
struct CommunityWinCard: View {
    let win: CommunityWin

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Size emoji
            Text(win.sizeEmoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Name and time
                HStack {
                    Text(win.displayNameOrAnonymous)
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.charcoal)

                    Text("celebrated")
                        .font(.bodySmall)
                        .foregroundColor(Color.momentum.gray)

                    Spacer()

                    Text(win.timeAgo)
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                }

                // Win description
                Text(win.winDescription)
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.charcoal)
                    .lineLimit(3)

                // Bottom row: Emotion + Celebrate button
                HStack {
                    // Emotion indicator
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < win.emotion ? "heart.fill" : "heart")
                                .font(.system(size: 10))
                                .foregroundColor(i < win.emotion ? Color.momentum.coral : Color.momentum.gray.opacity(0.3))
                        }
                    }

                    Spacer()

                    // Celebrate reaction button
                    CelebrationReactionView(winId: win.id)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow(radius: 2)
    }
}

// MARK: - Empty State
struct EmptyCommunityView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.momentum.sage.opacity(0.5))

            Text("No wins shared yet")
                .font(.titleMedium)
                .foregroundColor(Color.momentum.charcoal)

            Text("Be the first to share a win and inspire the community!")
                .font(.bodySmall)
                .foregroundColor(Color.momentum.gray)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
    }
}

#Preview {
    NavigationStack {
        CommunityFeedView()
    }
}
