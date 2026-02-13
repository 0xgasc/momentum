import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var goal: Goal

    @State private var showAddAction = false
    @State private var showEditGoal = false
    @State private var showCelebration = false
    @State private var celebrationMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header Card
                    GoalHeaderCard(goal: goal)

                    // Affirmation
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Your Affirmation")
                            .font(.caption)
                            .foregroundColor(Color.momentum.plum)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        Text(goal.affirmation)
                            .font(.displaySmall)
                            .foregroundColor(Color.momentum.charcoal)
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.momentum.plum.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                    // Progress Section
                    if !goal.actions.isEmpty {
                        ProgressSection(goal: goal)
                    }

                    // Actions Section
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Actions")
                                .font(.titleMedium)
                                .foregroundColor(Color.momentum.charcoal)

                            Spacer()

                            Button(action: { showAddAction = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.momentum.coral)
                            }
                        }

                        if goal.activeActions.isEmpty {
                            EmptyActionsCard(onAdd: { showAddAction = true })
                        } else {
                            ForEach(goal.activeActions) { action in
                                ActionCard(
                                    action: action,
                                    onComplete: {
                                        completeAction(action)
                                    },
                                    onTap: {}
                                )
                            }
                        }

                        // Completed actions
                        if !goal.completedActions.isEmpty {
                            DisclosureGroup {
                                ForEach(goal.completedActions) { action in
                                    CompletedActionCard(action: action)
                                }
                            } label: {
                                Text("Completed (\(goal.completedActions.count))")
                                    .font(.bodySmall)
                                    .foregroundColor(Color.momentum.gray)
                            }
                        }
                    }

                    // Wins Section
                    if !goal.wins.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Wins")
                                .font(.titleMedium)
                                .foregroundColor(Color.momentum.charcoal)

                            ForEach(goal.wins.prefix(3)) { win in
                                WinCard(win: win)
                            }

                            if goal.wins.count > 3 {
                                Text("+ \(goal.wins.count - 3) more wins")
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)
                            }
                        }
                    }

                    // Archive Button
                    VStack(spacing: Spacing.sm) {
                        MomentumButton(
                            goal.isArchived ? "Unarchive Goal" : "Archive Goal",
                            icon: "archivebox.fill",
                            style: .ghost
                        ) {
                            toggleArchive()
                        }

                        if goal.isArchived {
                            Button(action: deleteGoal) {
                                Text("Delete Goal")
                                    .font(.bodySmall)
                                    .foregroundColor(Color.momentum.coral)
                            }
                        }
                    }
                    .padding(.top, Spacing.lg)
                }
                .padding(Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationTitle(goal.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showEditGoal = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(Color.momentum.charcoal)
                    }
                }
            }
            .sheet(isPresented: $showAddAction) {
                AddActionToGoalSheet(goal: goal)
            }
            .sheet(isPresented: $showEditGoal) {
                EditGoalSheet(goal: goal)
            }
            .overlay {
                if showCelebration {
                    CelebrationView(
                        message: celebrationMessage,
                        winSize: .small,
                        isShowing: $showCelebration
                    )
                }
            }
        }
    }

    private func completeAction(_ action: MicroAction) {
        action.complete()
        celebrationMessage = AffirmationContent.randomCompletionMessage()

        withAnimation {
            showCelebration = true
        }

        try? modelContext.save()
    }

    private func toggleArchive() {
        goal.isArchived.toggle()
        try? modelContext.save()

        if goal.isArchived {
            dismiss()
        }
    }

    private func deleteGoal() {
        modelContext.delete(goal)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Goal Header Card
struct GoalHeaderCard: View {
    let goal: Goal

    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(goal.category.color.opacity(0.15))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: goal.category.icon)
                        .font(.system(size: 28))
                        .foregroundColor(goal.category.color)
                )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(goal.category.displayName)
                    .font(.caption)
                    .foregroundColor(goal.category.color)
                    .textCase(.uppercase)

                if let targetDate = goal.targetDate {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "calendar")
                        Text("Target: \(targetDate.formatted(date: .abbreviated, time: .omitted))")
                    }
                    .font(.bodySmall)
                    .foregroundColor(Color.momentum.gray)
                }

                Text("Created \(goal.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(Color.momentum.gray)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow()
    }
}

// MARK: - Progress Section
struct ProgressSection: View {
    let goal: Goal

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(goal.category.color.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: goal.progressPercentage)
                    .stroke(goal.category.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(goal.progressPercentage * 100))%")
                        .font(.titleMedium)
                        .foregroundColor(goal.category.color)
                    Text("done")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                }
            }
            .frame(width: 80, height: 80)

            // Stats
            VStack(alignment: .leading, spacing: Spacing.sm) {
                StatRow(icon: "checkmark.circle.fill", value: "\(goal.completedActions.count)", label: "completed", color: Color.momentum.sage)
                StatRow(icon: "circle", value: "\(goal.activeActions.count)", label: "remaining", color: Color.momentum.coral)
                StatRow(icon: "trophy.fill", value: "\(goal.wins.count)", label: "wins", color: Color.momentum.gold)
            }
        }
        .padding(Spacing.md)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow()
    }
}

struct StatRow: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(value)
                .font(.titleSmall)
                .foregroundColor(Color.momentum.charcoal)

            Text(label)
                .font(.caption)
                .foregroundColor(Color.momentum.gray)
        }
    }
}

// MARK: - Empty Actions Card
struct EmptyActionsCard: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("No actions yet")
                .font(.bodyMedium)
                .foregroundColor(Color.momentum.gray)

            MomentumButton("Add First Action", icon: "plus", style: .secondary) {
                onAdd()
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.momentum.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

// MARK: - Add Action to Goal Sheet
struct AddActionToGoalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let goal: Goal

    @State private var title = ""
    @State private var actionType: ActionType = .doIt
    @State private var scheduledDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Action") {
                    TextField("What needs to be done?", text: $title)
                }

                Section("Type") {
                    Picker("Action Type", selection: $actionType) {
                        ForEach(ActionType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Schedule") {
                    DatePicker("Date", selection: $scheduledDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addAction() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addAction() {
        let action = MicroAction(
            title: title,
            actionType: actionType,
            scheduledDate: scheduledDate,
            goal: goal
        )

        goal.actions.append(action)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Edit Goal Sheet
struct EditGoalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var goal: Goal

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Title", text: $goal.title)
                }

                Section("Affirmation") {
                    TextField("Your affirmation", text: $goal.affirmation, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("Category") {
                    Picker("Category", selection: $goal.category) {
                        ForEach(GoalCategory.userFacing, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }

                Section("Target Date") {
                    if let targetDate = goal.targetDate {
                        DatePicker("Date", selection: Binding(
                            get: { targetDate },
                            set: { goal.targetDate = $0 }
                        ), displayedComponents: .date)
                    }

                    Toggle("Has Target Date", isOn: Binding(
                        get: { goal.targetDate != nil },
                        set: { hasDate in
                            goal.targetDate = hasDate ? Date().addingTimeInterval(86400 * 30) : nil
                        }
                    ))
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let goal = Goal(
        title: "Launch my side project",
        affirmation: "I am a successful entrepreneur with a thriving business",
        category: .career,
        targetDate: Date().addingTimeInterval(86400 * 30)
    )

    GoalDetailView(goal: goal)
}
