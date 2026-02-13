import SwiftUI
import SwiftData

// MARK: - Goal Vision Board
/// Pinterest-style vision board view for goals
struct GoalVisionBoard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var goals: [Goal]

    @EnvironmentObject private var purchaseService: PurchaseService

    @State private var selectedGoal: Goal?
    @State private var showAddGoal = false
    @State private var showShareSheet = false
    @State private var goalToShare: Goal?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Hero - featured/priority goal
                if let featured = featuredGoal {
                    FeaturedGoalCard(
                        goal: featured,
                        onTap: {
                            selectedGoal = featured
                        },
                        onShare: {
                            if purchaseService.isPlus {
                                goalToShare = featured
                                showShareSheet = true
                            } else {
                                purchaseService.showPaywall = true
                            }
                        }
                    )
                } else {
                    EmptyFeaturedCard(onAdd: { showAddGoal = true })
                }

                // Category sections (horizontal scroll per category)
                ForEach(GoalCategory.userFacing, id: \.self) { category in
                    let categoryGoals = goalsFor(category)
                    if !categoryGoals.isEmpty {
                        CategorySection(
                            category: category,
                            goals: categoryGoals,
                            onSelectGoal: { goal in
                                selectedGoal = goal
                            }
                        )
                    }
                }

                // Quick add section
                QuickAddGoalSection(onAdd: { showAddGoal = true })

                Spacer().frame(height: Spacing.xxl)
            }
            .padding(Spacing.md)
        }
        .background(Color.momentum.cream.ignoresSafeArea())
        .navigationDestination(item: $selectedGoal) { goal in
            GoalDetailView(goal: goal)
        }
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet()
        }
        .sheet(isPresented: $showShareSheet) {
            if let goal = goalToShare {
                ShareCustomizationSheet(
                    cardType: .goalMilestone(
                        goalTitle: goal.title,
                        category: goal.category,
                        milestone: goal.progressPercentage
                    )
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var featuredGoal: Goal? {
        // Priority: most progress but not complete, or most recent if all 0%
        goals.sorted { g1, g2 in
            if g1.progressPercentage > 0 && g2.progressPercentage == 0 {
                return true
            }
            if g1.progressPercentage == 0 && g2.progressPercentage > 0 {
                return false
            }
            return g1.createdAt > g2.createdAt
        }.first
    }

    private func goalsFor(_ category: GoalCategory) -> [Goal] {
        goals.filter { $0.category == category }
            .sorted { $0.progressPercentage > $1.progressPercentage }
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: GoalCategory
    let goals: [Goal]
    let onSelectGoal: (Goal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section header
            HStack(spacing: Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(category.color)

                Text(category.displayName)
                    .font(.titleMedium)
                    .foregroundColor(Color.momentum.charcoal)

                Text("(\(goals.count))")
                    .font(.bodySmall)
                    .foregroundColor(Color.momentum.gray)

                Spacer()
            }

            // Horizontal scroll of compact cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(goals) { goal in
                        CompactGoalCard(goal: goal) {
                            onSelectGoal(goal)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Empty Featured Card
struct EmptyFeaturedCard: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.momentum.coral.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "target")
                    .font(.system(size: 36))
                    .foregroundColor(Color.momentum.coral)
            }

            VStack(spacing: Spacing.sm) {
                Text("Set Your First Goal")
                    .font(.displayMedium)
                    .foregroundColor(Color.momentum.charcoal)

                Text("Start building your vision board")
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
            }

            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Goal")
                }
                .font(.titleSmall)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color.momentum.coral)
                .clipShape(Capsule())
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
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
    }
}

// MARK: - Quick Add Goal Section
struct QuickAddGoalSection: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("Ready for more?")
                .font(.titleSmall)
                .foregroundColor(Color.momentum.charcoal)

            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Another Goal")
                }
                .font(.bodyMedium)
                .foregroundColor(Color.momentum.coral)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color.momentum.coral.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

// MARK: - Add Goal Sheet (Magic Goal Creation)
struct AddGoalSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var affirmation = ""
    @State private var selectedCategory: GoalCategory?
    @State private var selectedTemplate: GoalTemplate?
    @State private var hasTargetDate = false
    @State private var targetDate = Date()
    @State private var showForm = false
    @State private var showConfetti = false

    private var templates: [GoalTemplate] {
        guard let category = selectedCategory else { return [] }
        return GoalTemplates.templates(for: category)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Text("What's your next big thing?")
                            .font(.displaySmall)
                            .foregroundColor(Color.momentum.charcoal)
                            .multilineTextAlignment(.center)

                        Text("Pick a category, then get inspired")
                            .font(.bodyMedium)
                            .foregroundColor(Color.momentum.gray)
                    }
                    .padding(.top, Spacing.lg)

                    // Category chips (no wildcard)
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.sm) {
                        ForEach(GoalCategory.userFacing, id: \.self) { cat in
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                withAnimation(.spring(response: 0.35)) {
                                    if selectedCategory == cat {
                                        selectedCategory = nil
                                        showForm = false
                                        selectedTemplate = nil
                                    } else {
                                        selectedCategory = cat
                                        showForm = false
                                        selectedTemplate = nil
                                        title = ""
                                        affirmation = ""
                                    }
                                }
                            } label: {
                                VStack(spacing: Spacing.xs) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 22))
                                    Text(cat.displayName)
                                        .font(.caption)
                                }
                                .foregroundColor(selectedCategory == cat ? .white : cat.color)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(selectedCategory == cat ? cat.color : cat.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.card)
                                        .strokeBorder(selectedCategory == cat ? Color.clear : cat.color.opacity(0.25), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)

                    // Template suggestions (shown after category selection)
                    if let category = selectedCategory, !templates.isEmpty, !showForm {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Perfect for you:")
                                .font(.titleSmall)
                                .foregroundColor(Color.momentum.charcoal)

                            ForEach(templates) { template in
                                Button {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    selectedTemplate = template
                                    title = template.title
                                    affirmation = template.affirmation
                                    withAnimation(.spring(response: 0.4)) {
                                        showForm = true
                                    }
                                } label: {
                                    HStack(spacing: Spacing.sm) {
                                        Text(template.emoji)
                                            .font(.title3)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(template.title)
                                                .font(.bodyMedium)
                                                .foregroundColor(Color.momentum.charcoal)
                                            Text(template.affirmation)
                                                .font(.caption)
                                                .foregroundColor(Color.momentum.gray)
                                                .italic()
                                        }

                                        Spacer()

                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(category.color)
                                    }
                                    .padding(Spacing.md)
                                    .background(Color.momentum.white)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                                    .momentumShadow(radius: 3)
                                }
                            }

                            // Start from scratch
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                selectedTemplate = nil
                                title = ""
                                affirmation = ""
                                withAnimation(.spring(response: 0.4)) {
                                    showForm = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "pencil.line")
                                        .font(.system(size: 14))
                                    Text("Start from scratch")
                                        .font(.bodySmall)
                                }
                                .foregroundColor(Color.momentum.gray)
                                .padding(.top, Spacing.xs)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Form fields (shown after template tap or "start from scratch")
                    if showForm, selectedCategory != nil {
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            // Goal title
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Your Goal")
                                    .font(.titleSmall)
                                    .foregroundColor(Color.momentum.charcoal)

                                TextField("What do you want to achieve?", text: $title)
                                    .font(.bodyLarge)
                                    .padding(Spacing.md)
                                    .background(Color.momentum.white)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                                    .momentumShadow(radius: 4)
                            }

                            // Affirmation
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Your Affirmation")
                                    .font(.titleSmall)
                                    .foregroundColor(Color.momentum.charcoal)

                                TextField("I am...", text: $affirmation)
                                    .font(.bodyMedium)
                                    .italic()
                                    .padding(Spacing.md)
                                    .background(Color.momentum.white)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                                    .momentumShadow(radius: 4)
                            }

                            // Target date
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Toggle(isOn: $hasTargetDate) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Set a deadline")
                                            .font(.titleSmall)
                                            .foregroundColor(Color.momentum.charcoal)
                                        Text("Optional but powerful")
                                            .font(.caption)
                                            .foregroundColor(Color.momentum.gray)
                                    }
                                }
                                .tint(Color.momentum.coral)

                                if hasTargetDate {
                                    DatePicker("Target", selection: $targetDate, in: Date()..., displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .tint(Color.momentum.coral)
                                }
                            }
                            .padding(Spacing.md)
                            .background(Color.momentum.white)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                            .momentumShadow(radius: 4)

                            // Create button
                            Button(action: createGoal) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Create Goal")
                                }
                                .font(.titleSmall)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(
                                    (title.isEmpty || affirmation.isEmpty)
                                        ? Color.momentum.gray
                                        : Color.momentum.coral
                                )
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                            }
                            .disabled(title.isEmpty || affirmation.isEmpty)
                        }
                        .padding(.horizontal, Spacing.md)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer().frame(height: Spacing.xxl)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.momentum.gray)
                }
            }
            .confetti(isShowing: $showConfetti, intensity: 150)
        }
    }

    private func createGoal() {
        guard let category = selectedCategory else { return }

        let goal = Goal(
            title: title,
            affirmation: affirmation,
            category: category,
            targetDate: hasTargetDate ? targetDate : nil
        )

        modelContext.insert(goal)
        try? modelContext.save()

        showConfetti = true

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        GoalVisionBoard()
    }
}
