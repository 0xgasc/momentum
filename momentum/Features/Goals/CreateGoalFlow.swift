import SwiftUI
import SwiftData

struct CreateGoalFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var goalTitle = ""
    @State private var category: GoalCategory = .growth
    @State private var affirmation = ""
    @State private var targetDate = Date().addingTimeInterval(86400 * 30) // 30 days default
    @State private var hasDeadline = false
    @State private var initialActions: [String] = ["", "", ""]
    @State private var showConfetti = false

    private let totalSteps = 4

    /// Auto-fill affirmation from template if title matches
    private func prefillAffirmationIfNeeded() {
        guard affirmation.isEmpty else { return }
        let templates = GoalTemplates.templates(for: category)
        if let match = templates.first(where: { $0.title == goalTitle }) {
            affirmation = match.affirmation
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressBar(progress: Double(currentStep + 1) / Double(totalSteps))
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                // Step content
                TabView(selection: $currentStep) {
                    DreamItStep(
                        goalTitle: $goalTitle,
                        category: $category
                    )
                    .tag(0)

                    BelieveItStep(
                        goalTitle: goalTitle,
                        affirmation: $affirmation
                    )
                    .tag(1)

                    BreakItDownStep(
                        actions: $initialActions,
                        category: category
                    )
                    .tag(2)

                    SetStakesStep(
                        hasDeadline: $hasDeadline,
                        targetDate: $targetDate
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // Navigation buttons
                HStack(spacing: Spacing.md) {
                    if currentStep > 0 {
                        MomentumButton("Back", style: .ghost) {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    }

                    Spacer()

                    if currentStep < totalSteps - 1 {
                        MomentumButton("Continue", icon: "arrow.right") {
                            // Auto-fill affirmation from template when moving to Step 2
                            if currentStep == 0 {
                                prefillAffirmationIfNeeded()
                            }
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .disabled(!canContinue)
                    } else {
                        MomentumButton("Create Goal", icon: "sparkles") {
                            createGoal()
                        }
                        .disabled(!canCreate)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.momentum.cream.ignoresSafeArea())
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

    private var canContinue: Bool {
        switch currentStep {
        case 0: return !goalTitle.isEmpty
        case 1: return !affirmation.isEmpty
        case 2: return initialActions.contains { !$0.isEmpty }
        default: return true
        }
    }

    private var canCreate: Bool {
        !goalTitle.isEmpty && !affirmation.isEmpty
    }

    private func createGoal() {
        let goal = Goal(
            title: goalTitle,
            affirmation: affirmation,
            category: category,
            targetDate: hasDeadline ? targetDate : nil
        )

        // Add initial actions
        for actionTitle in initialActions where !actionTitle.isEmpty {
            let action = MicroAction(
                title: actionTitle,
                actionType: .doIt,
                scheduledDate: Date(),
                goal: goal
            )
            goal.actions.append(action)
        }

        modelContext.insert(goal)
        try? modelContext.save()

        showConfetti = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.momentum.coral.opacity(0.2))
                    .frame(height: 4)

                Rectangle()
                    .fill(Color.momentum.coral)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.spring(response: 0.4), value: progress)
            }
            .clipShape(Capsule())
        }
        .frame(height: 4)
    }
}

// MARK: - Step 1: Dream It
struct DreamItStep: View {
    @Binding var goalTitle: String
    @Binding var category: GoalCategory

    private var templates: [GoalTemplate] {
        GoalTemplates.templates(for: category)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Dream It")
                        .font(.displayLarge)
                        .foregroundColor(Color.momentum.charcoal)

                    Text("What's something you want to achieve? Think big.")
                        .font(.bodyMedium)
                        .foregroundColor(Color.momentum.gray)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Category")
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.charcoal)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.sm) {
                        ForEach(GoalCategory.userFacing, id: \.self) { cat in
                            CategoryButton(
                                category: cat,
                                isSelected: category == cat
                            ) {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                category = cat
                            }
                        }
                    }
                }

                // Template suggestions for selected category
                if !templates.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Get inspired:")
                            .font(.caption)
                            .foregroundColor(Color.momentum.gray)

                        ForEach(templates) { template in
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    goalTitle = template.title
                                }
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    Text(template.emoji)
                                        .font(.body)

                                    Text(template.title)
                                        .font(.bodySmall)
                                        .foregroundColor(goalTitle == template.title ? .white : Color.momentum.charcoal)
                                        .lineLimit(1)

                                    Spacer()

                                    if goalTitle == template.title {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(goalTitle == template.title ? category.color : Color.momentum.white)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                                .momentumShadow(radius: goalTitle == template.title ? 0 : 2)
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .background(category.color.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Your Goal")
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.charcoal)

                    TextField("e.g., Launch my side business", text: $goalTitle)
                        .font(.bodyLarge)
                        .padding(Spacing.md)
                        .background(Color.momentum.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        .momentumShadow(radius: 4)
                }

                Spacer()
            }
            .padding(Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct CategoryButton: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Circle()
                    .fill(isSelected ? category.color : category.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? .white : category.color)
                    )

                Text(category.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? category.color : Color.momentum.gray)
            }
        }
    }
}

// MARK: - Step 2: Believe It
struct BelieveItStep: View {
    let goalTitle: String
    @Binding var affirmation: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Believe It")
                        .font(.displayLarge)
                        .foregroundColor(Color.momentum.charcoal)

                    Text("Write it as if you've already achieved it. Present tense, first person.")
                        .font(.bodyMedium)
                        .foregroundColor(Color.momentum.gray)
                }

                // Example based on goal
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Your goal:")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)

                    Text(goalTitle)
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.plum)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.momentum.plum.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Your Affirmation")
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.charcoal)

                    TextField("e.g., I am a successful business owner", text: $affirmation, axis: .vertical)
                        .font(.bodyLarge)
                        .lineLimit(3...5)
                        .padding(Spacing.md)
                        .background(Color.momentum.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        .momentumShadow(radius: 4)
                }

                // Tips
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Tips:")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)

                    Text("• Start with \"I am\" or \"I have\"")
                    Text("• Use present tense")
                    Text("• Make it specific and personal")
                }
                .font(.caption)
                .foregroundColor(Color.momentum.gray)

                Spacer()
            }
            .padding(Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Step 3: Break It Down
struct BreakItDownStep: View {
    @Binding var actions: [String]
    let category: GoalCategory

    @State private var showSuggestions = true

    private var suggestions: [ActionTemplate] {
        ActionTemplates.suggestions(for: category)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Break It Down")
                        .font(.displayLarge)
                        .foregroundColor(Color.momentum.charcoal)

                    Text("What's the first few micro-actions you can take? Start small.")
                        .font(.bodyMedium)
                        .foregroundColor(Color.momentum.gray)
                }

                VStack(spacing: Spacing.md) {
                    ForEach(actions.indices, id: \.self) { index in
                        HStack(spacing: Spacing.sm) {
                            Circle()
                                .fill(Color.momentum.coral.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(Color.momentum.coral)
                                )

                            TextField(
                                index == 0 ? "e.g., Research competitors" : "Next action...",
                                text: $actions[index]
                            )
                            .font(.bodyMedium)
                            .padding(Spacing.sm)
                            .background(Color.momentum.white)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                            .momentumShadow(radius: 2)
                        }
                    }

                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        actions.append("")
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add another action")
                        }
                        .font(.bodySmall)
                        .foregroundColor(Color.momentum.sage)
                    }
                }

                // Suggested Actions
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Button {
                        withAnimation {
                            showSuggestions.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(Color.momentum.gold)
                            Text("Suggested actions for \(category.displayName)")
                                .font(.titleSmall)
                                .foregroundColor(Color.momentum.charcoal)
                            Spacer()
                            Image(systemName: showSuggestions ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }
                    }

                    if showSuggestions {
                        let addedTitles = Set(actions.map { $0.lowercased() }.filter { !$0.isEmpty })
                        let available = suggestions.filter { !addedTitles.contains($0.title.lowercased()) }
                        if available.isEmpty {
                            Text("All suggestions added!")
                                .font(.bodySmall)
                                .foregroundColor(Color.momentum.sage)
                        } else {
                            VStack(spacing: Spacing.xs) {
                                ForEach(available.prefix(6), id: \.title) { suggestion in
                                    SuggestionChip(suggestion: suggestion) {
                                        addSuggestion(suggestion.title)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(Spacing.md)
                .background(Color.momentum.gold.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                // Hint
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color.momentum.gold)
                    Text("Tap a suggestion to add it, or write your own!")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                }

                Spacer()
            }
            .padding(Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func addSuggestion(_ title: String) {
        // Find the first empty slot, or add a new one
        if let emptyIndex = actions.firstIndex(where: { $0.isEmpty }) {
            withAnimation {
                actions[emptyIndex] = title
            }
        } else {
            withAnimation {
                actions.append(title)
            }
        }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

// MARK: - Suggestion Chip
struct SuggestionChip: View {
    let suggestion: ActionTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: suggestion.type.icon)
                    .font(.system(size: 12))
                    .foregroundColor(suggestion.type.color)

                Text(suggestion.title)
                    .font(.bodySmall)
                    .foregroundColor(Color.momentum.charcoal)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.momentum.coral)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.momentum.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        }
    }
}

// MARK: - Step 4: Set Stakes
struct SetStakesStep: View {
    @Binding var hasDeadline: Bool
    @Binding var targetDate: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Set Stakes")
                        .font(.displayLarge)
                        .foregroundColor(Color.momentum.charcoal)

                    Text("Goals with deadlines are more likely to be achieved. When do you want to complete this?")
                        .font(.bodyMedium)
                        .foregroundColor(Color.momentum.gray)
                }

                Toggle(isOn: $hasDeadline) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Set a target date")
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)
                        Text("Optional but recommended")
                            .font(.caption)
                            .foregroundColor(Color.momentum.gray)
                    }
                }
                .tint(Color.momentum.coral)
                .padding(Spacing.md)
                .background(Color.momentum.white)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                .momentumShadow(radius: 4)

                if hasDeadline {
                    DatePicker(
                        "Target Date",
                        selection: $targetDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.momentum.coral)
                    .padding(Spacing.md)
                    .background(Color.momentum.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                    .momentumShadow(radius: 4)
                }

                // Motivation
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("You're almost there!")
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.charcoal)

                    Text("\"A goal without a plan is just a wish. A goal with a plan is a mission.\"")
                        .font(.bodySmall)
                        .foregroundColor(Color.momentum.gray)
                        .italic()
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.momentum.sage.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                Spacer()
            }
            .padding(Spacing.lg)
        }
    }
}

#Preview {
    CreateGoalFlow()
}
