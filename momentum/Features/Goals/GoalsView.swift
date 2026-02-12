import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var activeGoals: [Goal]
    @Query(filter: #Predicate<Goal> { $0.isArchived }) private var archivedGoals: [Goal]

    @State private var showCreateGoal = false
    @State private var selectedGoal: Goal?
    @State private var viewMode: ViewMode = .grid

    @EnvironmentObject private var purchaseService: PurchaseService

    private let maxFreeGoals = 3

    enum ViewMode {
        case grid, list
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // View Mode Toggle
                    HStack {
                        Spacer()
                        Picker("View", selection: $viewMode) {
                            Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                            Image(systemName: "list.bullet").tag(ViewMode.list)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }

                    if activeGoals.isEmpty {
                        EmptyGoalsView(onCreateGoal: {
                            showCreateGoal = true
                        })
                    } else {
                        // Active Goals
                        if viewMode == .grid {
                            LazyVGrid(columns: columns, spacing: Spacing.md) {
                                ForEach(activeGoals) { goal in
                                    GoalGridItem(goal: goal) {
                                        selectedGoal = goal
                                    }
                                }

                                // Add Goal Card
                                AddGoalCard {
                                    checkAndShowCreateGoal()
                                }
                            }
                        } else {
                            VStack(spacing: Spacing.md) {
                                ForEach(activeGoals) { goal in
                                    GoalCard(goal: goal) {
                                        selectedGoal = goal
                                    }
                                }
                            }
                        }
                    }

                    // Archived Goals Section
                    if !archivedGoals.isEmpty {
                        DisclosureGroup {
                            VStack(spacing: Spacing.sm) {
                                ForEach(archivedGoals) { goal in
                                    ArchivedGoalRow(goal: goal) {
                                        selectedGoal = goal
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "archivebox.fill")
                                Text("Archived (\(archivedGoals.count))")
                            }
                            .font(.bodySmall)
                            .foregroundColor(Color.momentum.gray)
                        }
                        .padding(.top, Spacing.lg)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        checkAndShowCreateGoal()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.momentum.coral)
                    }
                }
            }
            .sheet(isPresented: $showCreateGoal) {
                CreateGoalFlow()
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(goal: goal)
            }
        }
    }

    private func checkAndShowCreateGoal() {
        if !purchaseService.isPlus && activeGoals.count >= maxFreeGoals {
            purchaseService.showPaywall = true
        } else {
            showCreateGoal = true
        }
    }
}

// MARK: - Empty State
struct EmptyGoalsView: View {
    let onCreateGoal: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(Color.momentum.coral.opacity(0.5))

            VStack(spacing: Spacing.sm) {
                Text("No goals yet")
                    .font(.displaySmall)
                    .foregroundColor(Color.momentum.charcoal)

                Text("What do you want to achieve? Set your first goal and start making moves.")
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.center)
            }

            MomentumButton("Create Your First Goal", icon: "plus") {
                onCreateGoal()
            }
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Add Goal Card
struct AddGoalCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Circle()
                    .strokeBorder(Color.momentum.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Color.momentum.gray)
                    )

                Text("Add Goal")
                    .font(.bodySmall)
                    .foregroundColor(Color.momentum.gray)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.momentum.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(Color.momentum.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [8]))
            )
        }
    }
}

// MARK: - Archived Goal Row
struct ArchivedGoalRow: View {
    let goal: Goal
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: goal.category.icon)
                    .foregroundColor(Color.momentum.gray)

                Text(goal.title)
                    .font(.bodySmall)
                    .foregroundColor(Color.momentum.gray)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color.momentum.gray)
            }
            .padding(Spacing.sm)
            .background(Color.momentum.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        }
    }
}

#Preview {
    GoalsView()
        .environmentObject(PurchaseService())
}
