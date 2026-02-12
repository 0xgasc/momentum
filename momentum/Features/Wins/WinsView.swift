import SwiftUI
import SwiftData

struct WinsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Win.createdAt, order: .reverse) private var allWins: [Win]
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var goals: [Goal]

    @State private var selectedFilter: WinFilter = .all
    @State private var selectedGoalFilter: Goal?
    @State private var showLogWin = false
    @State private var winToShare: Win?

    enum WinFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Stats Summary
                    WinStatsSummary(wins: allWins)

                    // Filters
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        // Time filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(WinFilter.allCases) { filter in
                                    FilterChip(
                                        title: filter.rawValue,
                                        isSelected: selectedFilter == filter
                                    ) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }

                        // Goal filter
                        if !goals.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.xs) {
                                    FilterChip(
                                        title: "All Goals",
                                        isSelected: selectedGoalFilter == nil
                                    ) {
                                        selectedGoalFilter = nil
                                    }

                                    ForEach(goals) { goal in
                                        FilterChip(
                                            title: goal.title,
                                            icon: goal.category.icon,
                                            color: goal.category.color,
                                            isSelected: selectedGoalFilter == goal
                                        ) {
                                            selectedGoalFilter = goal
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Wins List
                    if filteredWins.isEmpty {
                        EmptyWinsView(onLogWin: { showLogWin = true })
                    } else {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(groupedWins, id: \.0) { date, wins in
                                Section {
                                    ForEach(wins) { win in
                                        WinCard(win: win)
                                            .contextMenu {
                                                Button {
                                                    winToShare = win
                                                } label: {
                                                    Label("Share", systemImage: "square.and.arrow.up")
                                                }

                                                Button(role: .destructive) {
                                                    deleteWin(win)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                } header: {
                                    HStack {
                                        Text(formatSectionDate(date))
                                            .font(.caption)
                                            .foregroundColor(Color.momentum.gray)
                                            .textCase(.uppercase)
                                        Spacer()
                                    }
                                    .padding(.top, Spacing.sm)
                                }
                            }
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationTitle("Wins")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showLogWin = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.momentum.coral)
                    }
                }
            }
            .sheet(isPresented: $showLogWin) {
                LogWinSheet(preselectedAction: nil)
            }
            .sheet(item: $winToShare) { win in
                ShareCustomizationSheet(
                    cardType: .winCelebration(
                        description: win.winDescription,
                        size: win.size,
                        emotion: win.emotion
                    )
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredWins: [Win] {
        var wins = allWins

        // Filter by goal
        if let goal = selectedGoalFilter {
            wins = wins.filter { $0.goal == goal }
        }

        // Filter by time
        switch selectedFilter {
        case .all:
            break
        case .today:
            wins = wins.filter { Calendar.current.isDateInToday($0.createdAt) }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            wins = wins.filter { $0.createdAt >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            wins = wins.filter { $0.createdAt >= monthAgo }
        }

        return wins
    }

    private var groupedWins: [(Date, [Win])] {
        let grouped = Dictionary(grouping: filteredWins) { win in
            Calendar.current.startOfDay(for: win.createdAt)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    // MARK: - Methods

    private func formatSectionDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }

    private func deleteWin(_ win: Win) {
        modelContext.delete(win)
        try? modelContext.save()
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    var icon: String? = nil
    var color: Color = Color.momentum.coral
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: Spacing.xxs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? color : Color.momentum.white)
            .foregroundColor(isSelected ? .white : Color.momentum.charcoal)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? color : Color.momentum.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Win Stats Summary
struct WinStatsSummary: View {
    let wins: [Win]

    private var totalWins: Int { wins.count }

    private var thisWeekWins: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return wins.filter { $0.createdAt >= weekAgo }.count
    }

    private var biggestWin: WinSize {
        wins.map { $0.size }.max { a, b in
            WinSize.allCases.firstIndex(of: a)! < WinSize.allCases.firstIndex(of: b)!
        } ?? .tiny
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            WinStatCard(
                icon: "trophy.fill",
                value: "\(totalWins)",
                label: "Total Wins",
                color: Color.momentum.gold
            )

            WinStatCard(
                icon: "calendar",
                value: "\(thisWeekWins)",
                label: "This Week",
                color: Color.momentum.coral
            )

            WinStatCard(
                icon: biggestWin.icon,
                value: biggestWin.displayName,
                label: "Biggest",
                color: Color.momentum.plum
            )
        }
        .padding(Spacing.md)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow()
    }
}

struct WinStatCard: View {
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
                .font(.titleSmall)
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

// MARK: - Empty State
struct EmptyWinsView: View {
    let onLogWin: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(Color.momentum.gold.opacity(0.5))

            VStack(spacing: Spacing.sm) {
                Text("No wins logged yet")
                    .font(.displaySmall)
                    .foregroundColor(Color.momentum.charcoal)

                Text("Start celebrating your progress, no matter how small. Every win counts!")
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.center)
            }

            MomentumButton("Log Your First Win", icon: "trophy.fill") {
                onLogWin()
            }
        }
        .padding(Spacing.xl)
    }
}

#Preview {
    WinsView()
}
