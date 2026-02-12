import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var goals: [Goal]
    @Query private var allActions: [MicroAction]
    @Query private var wins: [Win]
    @Query private var challenges: [Challenge]
    @Query private var relationships: [Relationship]

    @State private var currentAffirmation = AffirmationContent.randomMorningPrompt()
    @State private var refreshCount = 0
    @State private var showCelebration = false
    @State private var celebrationMessage = ""
    @State private var celebrationSize: WinSize = .small
    @State private var showLogWinSheet = false
    @State private var completedAction: MicroAction?
    @State private var addedSuggestionsThisSession: Set<String> = []
    @State private var showShareSheet = false
    @State private var showShareAfterCelebration = false

    @EnvironmentObject private var purchaseService: PurchaseService
    @EnvironmentObject private var weatherService: WeatherService
    @StateObject private var gamification = GamificationManager.shared

    private let maxFreeRefreshes = 3

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Affirmation Card
                    AffirmationCard(
                        affirmation: currentAffirmation,
                        onRefresh: refreshAffirmation
                    )

                    // Stats Row
                    HStack(spacing: Spacing.sm) {
                        // Streak
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(Color.momentum.coral.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "flame.fill")
                                    .foregroundColor(Color.momentum.coral)
                            }
                            Text("\(gamification.currentStreak) days")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.momentum.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))

                        // Today's actions
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(Color.momentum.sage.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Text("\(todaysCompletedActions.count)/5")
                                    .font(.titleSmall)
                                    .foregroundColor(Color.momentum.sage)
                            }
                            Text("Actions")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.momentum.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))

                        // Wins
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(Color.momentum.gold.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(Color.momentum.gold)
                            }
                            Text("\(wins.count) wins")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.momentum.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                    }

                    // Activity Overview
                    ActivitySummaryCard(
                        activeChallengesCount: activeChallengesCount,
                        neglectedRelationshipsCount: neglectedRelationshipsCount
                    )

                    // Weather-Based Suggestions
                    if let weather = weatherService.currentWeather {
                        WeatherSuggestionsCard(
                            weather: weather,
                            addedSuggestions: addedSuggestionsThisSession,
                            onAddAction: { template in
                                addQuickAction(from: template)
                                addedSuggestionsThisSession.insert(template.title)
                                ToastManager.shared.show("Added to Today's Moves!")
                            },
                            onAddChallenge: { template in
                                addQuickChallenge(from: template)
                                addedSuggestionsThisSession.insert(template.title)
                                ToastManager.shared.show("Challenge activated!", icon: "flag.fill")
                            },
                            onChangeWeather: { newWeather in
                                let profile = UserProfileManager.shared
                                profile.profile.weatherMode = .manual
                                profile.profile.manualWeather = newWeather
                                profile.save()
                                weatherService.currentWeather = newWeather
                                ToastManager.shared.show("Vibe set to \(newWeather.displayName)!", icon: newWeather.icon)
                            }
                        )
                    }

                    // Today's Moves Section
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Today's Moves")
                                .font(.titleMedium)
                                .foregroundColor(Color.momentum.charcoal)

                            Spacer()

                            NavigationLink(destination: AddActionView()) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.momentum.coral)
                            }
                        }

                        if todaysActions.isEmpty {
                            EmptyActionsView()
                        } else {
                            ForEach(todaysActions) { action in
                                ActionCard(
                                    action: action,
                                    onComplete: {
                                        completeAction(action)
                                    },
                                    onTap: {
                                        // Could navigate to action detail
                                    },
                                    onReschedule: {
                                        rescheduleAction(action)
                                    },
                                    onSkip: {
                                        skipAction(action)
                                    }
                                )
                            }
                        }

                        // Completed today
                        if !todaysCompletedActions.isEmpty {
                            DisclosureGroup {
                                ForEach(todaysCompletedActions) { action in
                                    CompletedActionCard(action: action)
                                }
                            } label: {
                                Text("Completed (\(todaysCompletedActions.count))")
                                    .font(.bodySmall)
                                    .foregroundColor(Color.momentum.gray)
                            }
                        }
                    }

                    // Quick Win Button
                    MomentumButton("Log a Win", icon: "trophy.fill", style: .secondary) {
                        showLogWinSheet = true
                    }
                    .padding(.top, Spacing.md)

                    // Community Pulse - collapsed at bottom
                    CommunityPulseCard()
                }
                .padding(Spacing.md)
            }
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationTitle(AppName.full)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Spacing.md) {
                        // Share button
                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color.momentum.coral)
                        }

                        // Settings button
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(Color.momentum.charcoal)
                        }
                    }
                }
            }
            .sheet(isPresented: $showLogWinSheet) {
                LogWinSheet(preselectedAction: completedAction)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareCustomizationSheet(
                    cardType: .dailySummary(
                        actions: todaysCompletedActions.count,
                        wins: wins.count,
                        streak: gamification.currentStreak
                    )
                )
            }
            .overlay {
                if showCelebration {
                    CelebrationView(
                        message: celebrationMessage,
                        winSize: celebrationSize,
                        isShowing: $showCelebration,
                        onShare: {
                            showShareAfterCelebration = true
                        }
                    )
                }
            }
            .sheet(isPresented: $showShareAfterCelebration) {
                ShareCustomizationSheet(
                    cardType: .dailySummary(
                        actions: todaysCompletedActions.count,
                        wins: wins.count,
                        streak: gamification.currentStreak
                    )
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var todaysActions: [MicroAction] {
        allActions
            .filter { action in
                !action.isCompleted &&
                (action.scheduledDate == nil || Calendar.current.isDateInToday(action.scheduledDate!))
            }
            .sorted { ($0.scheduledDate ?? Date.distantFuture) < ($1.scheduledDate ?? Date.distantFuture) }
    }

    private var todaysCompletedActions: [MicroAction] {
        allActions
            .filter { action in
                action.isCompleted &&
                action.completedAt != nil &&
                Calendar.current.isDateInToday(action.completedAt!)
            }
    }

    private var activeChallengesCount: Int {
        challenges.filter { $0.isActive && !$0.isCompleted }.count
    }

    private var neglectedRelationshipsCount: Int {
        relationships.filter { $0.healthStatus == .neglected }.count
    }

    // MARK: - Methods

    private func refreshAffirmation() {
        if !purchaseService.isPlus && refreshCount >= maxFreeRefreshes {
            // Show paywall
            purchaseService.showPaywall = true
            return
        }

        refreshCount += 1
        withAnimation {
            currentAffirmation = AffirmationContent.randomMorningPrompt()
        }
    }

    private func completeAction(_ action: MicroAction) {
        action.complete()

        // Award XP for completing action
        gamification.addXP(25) // Base XP for action
        gamification.updateStreak()
        gamification.checkTimeBadges()

        // Check action badges
        let totalCompleted = allActions.filter { $0.isCompleted }.count
        gamification.checkActionBadges(totalActions: totalCompleted)

        celebrationMessage = AffirmationContent.randomCompletionMessage()
        celebrationSize = .small
        completedAction = action

        withAnimation {
            showCelebration = true
        }

        // Prompt to log win after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showLogWinSheet = true
        }

        try? modelContext.save()
    }

    private func rescheduleAction(_ action: MicroAction) {
        // Move to tomorrow
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        action.scheduledDate = tomorrow

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        try? modelContext.save()
    }

    private func skipAction(_ action: MicroAction) {
        // Remove the scheduled date (action stays in goal but won't show on dashboard)
        action.scheduledDate = nil

        try? modelContext.save()
    }

    private func addQuickAction(from template: ActionTemplate) {
        let action = MicroAction(
            title: template.title,
            actionType: template.type,
            scheduledDate: Date(),
            goal: goals.first // Link to first active goal or nil
        )

        if let goal = goals.first {
            goal.actions.append(action)
        }

        modelContext.insert(action)
        try? modelContext.save()

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func addQuickChallenge(from template: ActionTemplate) {
        let challenge = template.toChallenge(difficulty: .easy, duration: .daily)
        challenge.isActive = true
        challenge.startedAt = Date()
        challenge.expiresAt = Calendar.current.date(byAdding: .day, value: 1, to: Date())

        modelContext.insert(challenge)
        try? modelContext.save()

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func calculateStreak() -> Int {
        // Simplified streak calculation
        var streak = 0
        var checkDate = Date()

        for _ in 0..<365 {
            let dayActions = allActions
                .filter { action in
                    action.isCompleted &&
                    action.completedAt != nil &&
                    Calendar.current.isDate(action.completedAt!, inSameDayAs: checkDate)
                }

            if dayActions.isEmpty {
                break
            }

            streak += 1
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        return streak
    }
}

// MARK: - Empty State
struct EmptyActionsView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(Color.momentum.sage.opacity(0.5))

            Text("No actions scheduled for today")
                .font(.bodyMedium)
                .foregroundColor(Color.momentum.gray)

            Text("Add actions to your goals or create a new goal to get started.")
                .font(.bodySmall)
                .foregroundColor(Color.momentum.gray)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.momentum.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

// MARK: - Add Action View (Quick Add)
struct AddActionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var goals: [Goal]

    @State private var title = ""
    @State private var actionType: ActionType = .doIt
    @State private var selectedGoal: Goal?
    @State private var scheduledDate = Date()

    var body: some View {
        Form {
            Section("What's the action?") {
                TextField("e.g., Research competitor pricing", text: $title)
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

            Section("Link to Goal") {
                Picker("Goal", selection: $selectedGoal) {
                    Text("None").tag(nil as Goal?)
                    ForEach(goals) { goal in
                        Text(goal.title).tag(goal as Goal?)
                    }
                }
            }

            Section("Schedule") {
                DatePicker("Date", selection: $scheduledDate, displayedComponents: .date)
            }
        }
        .navigationTitle("Add Action")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    addAction()
                }
                .disabled(title.isEmpty)
            }
        }
    }

    private func addAction() {
        let action = MicroAction(
            title: title,
            actionType: actionType,
            scheduledDate: scheduledDate,
            goal: selectedGoal
        )

        if let goal = selectedGoal {
            goal.actions.append(action)
        }

        modelContext.insert(action)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Log Win Sheet
struct LogWinSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseService: PurchaseService
    @Query(filter: #Predicate<Goal> { !$0.isArchived }) private var goals: [Goal]

    var preselectedAction: MicroAction?

    @State private var description = ""
    @State private var winSize: WinSize = .small
    @State private var emotion: Int = 3
    @State private var selectedGoal: Goal?
    @State private var selectedCategory: GoalCategory?
    @State private var showConfetti = false

    // Community sharing
    @State private var shareWithCommunity = false
    @State private var shareAnonymously = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Description
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("What did you accomplish?")
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)

                        TextField("Describe your win...", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.bodyMedium)
                            .foregroundColor(Color.momentum.charcoal)
                            .padding(Spacing.md)
                            .background(Color.momentum.cream)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                    }

                    // Win Size
                    WinSizeSelector(selectedSize: $winSize)

                    // Emotion
                    EmotionSelector(selectedEmotion: $emotion)

                    // Goal Link
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Related to which goal?")
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)

                        Picker("Goal", selection: $selectedGoal) {
                            Text("None")
                                .foregroundColor(Color.momentum.charcoal)
                                .tag(nil as Goal?)
                            ForEach(goals) { goal in
                                HStack {
                                    Image(systemName: goal.category.icon)
                                    Text(goal.title)
                                }
                                .foregroundColor(Color.momentum.charcoal)
                                .tag(goal as Goal?)
                            }
                        }
                        .tint(Color.momentum.charcoal)
                        .pickerStyle(.menu)
                        .padding(Spacing.sm)
                        .background(Color.momentum.cream)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                    }

                    // Category (optional - overrides goal's category)
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Category (optional)")
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)

                        Picker("Category", selection: $selectedCategory) {
                            Text("Auto (from goal)")
                                .foregroundColor(Color.momentum.charcoal)
                                .tag(nil as GoalCategory?)
                            ForEach(GoalCategory.userFacing, id: \.self) { cat in
                                Label(cat.displayName, systemImage: cat.icon)
                                    .foregroundColor(Color.momentum.charcoal)
                                    .tag(cat as GoalCategory?)
                            }
                        }
                        .tint(Color.momentum.charcoal)
                        .pickerStyle(.menu)
                        .padding(Spacing.sm)
                        .background(Color.momentum.cream)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                    }

                    // Community Sharing (Plus feature)
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Share with Community")
                                .font(.titleSmall)
                                .foregroundColor(Color.momentum.charcoal)

                            if !purchaseService.isPlus {
                                HStack(spacing: 2) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 10))
                                    Text("Plus")
                                        .font(.caption)
                                }
                                .foregroundColor(Color.momentum.gold)
                            }
                        }

                        if purchaseService.isPlus {
                            VStack(spacing: Spacing.sm) {
                                Toggle(isOn: $shareWithCommunity) {
                                    HStack(spacing: Spacing.sm) {
                                        Image(systemName: "person.3.fill")
                                            .foregroundColor(Color.momentum.sage)
                                        Text("Inspire others with this win")
                                            .font(.bodySmall)
                                            .foregroundColor(Color.momentum.charcoal)
                                    }
                                }
                                .tint(Color.momentum.sage)

                                if shareWithCommunity {
                                    Toggle(isOn: $shareAnonymously) {
                                        HStack(spacing: Spacing.sm) {
                                            Image(systemName: shareAnonymously ? "person.fill.questionmark" : "person.fill")
                                                .foregroundColor(Color.momentum.plum)
                                            Text(shareAnonymously ? "Share anonymously" : "Share with my name")
                                                .font(.bodySmall)
                                                .foregroundColor(Color.momentum.charcoal)
                                        }
                                    }
                                    .tint(Color.momentum.plum)
                                }
                            }
                            .padding(Spacing.md)
                            .background(Color.momentum.cream)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                        } else {
                            Button {
                                purchaseService.showPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Upgrade to share wins and inspire the community")
                                        .font(.bodySmall)
                                }
                                .foregroundColor(Color.momentum.coral)
                                .padding(Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background(Color.momentum.coral.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.momentum.white.ignoresSafeArea())
            .navigationTitle("Log a Win")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        logWin()
                    }
                    .disabled(description.isEmpty)
                }
            }
            .confetti(isShowing: $showConfetti, intensity: winSize.confettiIntensity)
        }
        .onAppear {
            if let action = preselectedAction {
                description = "Completed: \(action.title)"
                selectedGoal = action.goal
            }
        }
    }

    private func logWin() {
        let win = Win(
            description: description,
            size: winSize,
            emotion: emotion,
            category: selectedCategory,
            goal: selectedGoal,
            action: preselectedAction
        )

        if let goal = selectedGoal {
            goal.wins.append(win)
        }

        modelContext.insert(win)
        try? modelContext.save()

        // Share to community if enabled
        if shareWithCommunity && purchaseService.isPlus {
            let userName = UserProfileManager.shared.profile.name
            let displayName = shareAnonymously ? nil : userName.components(separatedBy: " ").first

            Task {
                try? await CloudKitManager.shared.shareWin(
                    description: description,
                    size: winSize,
                    emotion: emotion,
                    displayName: displayName,
                    isAnonymous: shareAnonymously
                )
            }
        }

        showConfetti = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Activity Summary Card
struct ActivitySummaryCard: View {
    let activeChallengesCount: Int
    let neglectedRelationshipsCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Activity Overview")
                .font(.titleSmall)
                .foregroundColor(Color.momentum.charcoal)

            HStack(spacing: Spacing.md) {
                NavigationLink(destination: ChallengesView()) {
                    SummaryMiniCard(
                        icon: "flag.fill",
                        value: "\(activeChallengesCount)",
                        label: "Challenges",
                        color: Color.momentum.coral
                    )
                }

                NavigationLink(destination: RelationshipsView()) {
                    SummaryMiniCard(
                        icon: "person.2.fill",
                        value: "\(neglectedRelationshipsCount)",
                        label: "Need Love",
                        color: neglectedRelationshipsCount > 0 ? Color.momentum.gold : Color.momentum.sage
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow()
    }
}

struct SummaryMiniCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.titleMedium)
                .foregroundColor(Color.momentum.charcoal)
            Text(label)
                .font(.caption)
                .foregroundColor(Color.momentum.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.sm)
        .background(Color.momentum.cream)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

#Preview {
    DashboardView()
        .environmentObject(PurchaseService())
}
