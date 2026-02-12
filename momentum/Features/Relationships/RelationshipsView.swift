import SwiftUI
import SwiftData

struct RelationshipsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Relationship.name) private var relationships: [Relationship]

    @State private var showAddRelationship = false
    @State private var selectedRelationship: Relationship?
    @State private var pendingInteractionType: InteractionType?

    @EnvironmentObject private var purchaseService: PurchaseService

    private let maxFreeRelationships = 5

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Neglected banner
                    if !neglectedRelationships.isEmpty {
                        NeglectedBanner(count: neglectedRelationships.count) {
                            // Could scroll to neglected or show filter
                        }
                    }

                    if relationships.isEmpty {
                        EmptyRelationshipsView(onAdd: { showAddRelationship = true })
                    } else {
                        // Relationships Grid
                        LazyVGrid(columns: columns, spacing: Spacing.md) {
                            ForEach(relationships) { relationship in
                                RelationshipCard(
                                    relationship: relationship,
                                    onTap: {
                                        pendingInteractionType = nil
                                        selectedRelationship = relationship
                                    },
                                    onQuickLog: { type in
                                        pendingInteractionType = type
                                        selectedRelationship = relationship
                                    }
                                )
                            }

                            // Add button
                            AddRelationshipCard {
                                checkAndShowAddRelationship()
                            }
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationTitle("People")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: checkAndShowAddRelationship) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.momentum.coral)
                    }
                }
            }
            .sheet(isPresented: $showAddRelationship) {
                AddRelationshipSheet()
            }
            .sheet(item: $selectedRelationship) { relationship in
                RelationshipDetailView(
                    relationship: relationship,
                    initialInteractionType: pendingInteractionType
                )
            }
        }
    }

    private var neglectedRelationships: [Relationship] {
        relationships.filter { $0.healthStatus == .neglected }
    }

    private func checkAndShowAddRelationship() {
        if !purchaseService.isPlus && relationships.count >= maxFreeRelationships {
            purchaseService.showPaywall = true
        } else {
            showAddRelationship = true
        }
    }
}

// MARK: - Empty State
struct EmptyRelationshipsView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.momentum.sage.opacity(0.5))

            VStack(spacing: Spacing.sm) {
                Text("Your circle awaits")
                    .font(.displaySmall)
                    .foregroundColor(Color.momentum.charcoal)

                Text("Add the people who matter to you. We'll help you nurture those relationships.")
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.center)
            }

            MomentumButton("Add Someone", icon: "person.badge.plus") {
                onAdd()
            }
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Add Relationship Card
struct AddRelationshipCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Circle()
                    .strokeBorder(Color.momentum.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 24))
                            .foregroundColor(Color.momentum.gray)
                    )

                Text("Add Person")
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

// MARK: - Add Relationship Sheet
struct AddRelationshipSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: RelationshipCategory = .personal
    @State private var contactGoal: ContactGoal = .monthly
    @State private var notes = ""
    @State private var showContactPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Import from Contacts button
                    Button {
                        showContactPicker = true
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 24))
                                .foregroundColor(Color.momentum.coral)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import from Contacts")
                                    .font(.titleSmall)
                                    .foregroundColor(Color.momentum.charcoal)
                                Text("Quick add from your phone")
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }
                        .padding(Spacing.md)
                        .background(Color.momentum.coral.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                    }

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.momentum.gray.opacity(0.2))
                            .frame(height: 1)
                        Text("or add manually")
                            .font(.caption)
                            .foregroundColor(Color.momentum.gray)
                        Rectangle()
                            .fill(Color.momentum.gray.opacity(0.2))
                            .frame(height: 1)
                    }

                    // Manual entry form
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Name
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Name")
                                .font(.titleSmall)
                                .foregroundColor(Color.momentum.charcoal)

                            TextField("Who do you want to nurture?", text: $name)
                                .font(.bodyMedium)
                                .padding(Spacing.md)
                                .background(Color.momentum.cream)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                        }

                        // Category
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("How do they support your goals?")
                                .font(.titleSmall)
                                .foregroundColor(Color.momentum.charcoal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                                ForEach(RelationshipCategory.allCases) { cat in
                                    CategoryChip(
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

                        // Contact Goal
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("How often do you want to connect?")
                                .font(.titleSmall)
                                .foregroundColor(Color.momentum.charcoal)

                            HStack(spacing: Spacing.xs) {
                                ForEach(ContactGoal.allCases) { goal in
                                    Button {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        contactGoal = goal
                                    } label: {
                                        Text(goal == .biweekly ? "2 wks" : goal.displayName)
                                            .font(.caption)
                                            .foregroundColor(contactGoal == goal ? .white : Color.momentum.charcoal)
                                            .padding(.horizontal, Spacing.sm)
                                            .padding(.vertical, Spacing.xs)
                                            .background(contactGoal == goal ? Color.momentum.sage : Color.momentum.cream)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Notes (optional)")
                                .font(.titleSmall)
                                .foregroundColor(Color.momentum.charcoal)

                            TextField("How you met, shared goals, conversation topics...", text: $notes, axis: .vertical)
                                .font(.bodyMedium)
                                .lineLimit(3...5)
                                .padding(Spacing.md)
                                .background(Color.momentum.cream)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                        }
                    }

                    // Add button
                    MomentumButton("Add to Circle", icon: "person.badge.plus") {
                        addRelationship()
                    }
                    .disabled(name.isEmpty)
                    .padding(.top, Spacing.md)
                }
                .padding(Spacing.lg)
            }
            .background(Color.momentum.white.ignoresSafeArea())
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView { contact in
                    name = contact.fullName
                    category = contact.suggestedCategory
                    if !contact.organization.isEmpty {
                        notes = "Works at \(contact.organization)"
                        if !contact.jobTitle.isEmpty {
                            notes += " as \(contact.jobTitle)"
                        }
                    }
                }
            }
        }
    }

    private func addRelationship() {
        let relationship = Relationship(
            name: name,
            category: category,
            contactGoal: contactGoal,
            notes: notes
        )

        modelContext.insert(relationship)
        try? modelContext.save()

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        dismiss()
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: RelationshipCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.displayName)
                    .font(.bodySmall)
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(isSelected ? category.color : category.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        }
    }
}

// MARK: - Quick Log Interaction Sheet
struct QuickLogInteractionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allRelationships: [Relationship]

    let relationship: Relationship
    let initialType: InteractionType

    @State private var interactionType: InteractionType
    @State private var initiatedBy: Initiator = .me
    @State private var notes = ""

    init(relationship: Relationship, initialType: InteractionType) {
        self.relationship = relationship
        self.initialType = initialType
        _interactionType = State(initialValue: initialType)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Who
                    HStack(spacing: Spacing.md) {
                        Circle()
                            .fill(relationship.category.color.opacity(0.15))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(relationship.initials)
                                    .font(.titleSmall)
                                    .foregroundColor(relationship.category.color)
                            )

                        VStack(alignment: .leading) {
                            Text(relationship.name)
                                .font(.titleMedium)
                                .foregroundColor(Color.momentum.charcoal)
                            Text(relationship.category.displayName)
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }

                        Spacer()
                    }
                    .padding(Spacing.md)
                    .background(Color.momentum.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                    // Type
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("What type of interaction?")
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)

                        InteractionTypePicker(selectedType: $interactionType)
                    }

                    // Who initiated
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Who reached out?")
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)

                        HStack(spacing: Spacing.sm) {
                            ForEach(Initiator.allCases) { initiator in
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    initiatedBy = initiator
                                }) {
                                    Text(initiator.displayName)
                                        .font(.bodySmall)
                                        .foregroundColor(initiatedBy == initiator ? .white : Color.momentum.charcoal)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(initiatedBy == initiator ? Color.momentum.coral : Color.momentum.cream)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Notes (optional)")
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)

                        TextField("What did you talk about?", text: $notes, axis: .vertical)
                            .lineLimit(3...5)
                            .padding(Spacing.md)
                            .background(Color.momentum.cream)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.momentum.white.ignoresSafeArea())
            .navigationTitle("Log Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { logInteraction() }
                }
            }
        }
    }

    private func logInteraction() {
        let interaction = Interaction(
            type: interactionType,
            initiatedBy: initiatedBy,
            notes: notes,
            relationship: relationship
        )

        relationship.interactions.append(interaction)

        // Check for relationship achievements and award XP
        GamificationManager.shared.recordInteraction(
            interaction: interaction,
            relationship: relationship,
            allRelationships: allRelationships,
            context: modelContext
        )

        try? modelContext.save()

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        dismiss()
    }
}

// MARK: - Relationship Detail View
struct RelationshipDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var relationship: Relationship
    var initialInteractionType: InteractionType? = nil

    @State private var showEditSheet = false
    @State private var showLogInteraction = false
    @State private var logInteractionType: InteractionType = .message
    @State private var logInitiatedBy: Initiator = .me
    @State private var logNotes = ""
    @Query private var allRelationships: [Relationship]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    VStack(spacing: Spacing.md) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(relationship.category.color.opacity(0.15))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(relationship.initials)
                                        .font(.displayMedium)
                                        .foregroundColor(relationship.category.color)
                                )

                            Circle()
                                .fill(relationship.healthStatus.color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.momentum.white, lineWidth: 3)
                                )
                        }

                        Text(relationship.name)
                            .font(.displayMedium)
                            .foregroundColor(Color.momentum.charcoal)

                        HStack(spacing: Spacing.sm) {
                            Label(relationship.category.displayName, systemImage: relationship.category.icon)
                            Text("•")
                            Text(relationship.contactGoal.displayName)
                        }
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                    }
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(Color.momentum.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                    // Quick Actions
                    HStack(spacing: Spacing.sm) {
                        ForEach([InteractionType.call, .message, .inPerson], id: \.self) { type in
                            QuickActionLargeButton(type: type) {
                                logInteractionType = type
                                withAnimation(.spring(response: 0.3)) {
                                    showLogInteraction = true
                                }
                            }
                        }
                    }

                    // Inline Log Interaction Form
                    if showLogInteraction {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Log \(logInteractionType.displayName)")
                                .font(.titleSmall)
                                .foregroundColor(Color.momentum.charcoal)

                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Who reached out?")
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)

                                HStack(spacing: Spacing.sm) {
                                    ForEach(Initiator.allCases) { initiator in
                                        Button {
                                            let impact = UIImpactFeedbackGenerator(style: .light)
                                            impact.impactOccurred()
                                            logInitiatedBy = initiator
                                        } label: {
                                            Text(initiator.displayName)
                                                .font(.bodySmall)
                                                .foregroundColor(logInitiatedBy == initiator ? .white : Color.momentum.charcoal)
                                                .padding(.horizontal, Spacing.md)
                                                .padding(.vertical, Spacing.sm)
                                                .background(logInitiatedBy == initiator ? Color.momentum.coral : Color.momentum.cream)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }

                            TextField("What did you talk about? (optional)", text: $logNotes, axis: .vertical)
                                .font(.bodySmall)
                                .lineLimit(2...4)
                                .padding(Spacing.sm)
                                .background(Color.momentum.cream)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))

                            HStack(spacing: Spacing.md) {
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        showLogInteraction = false
                                    }
                                    logNotes = ""
                                } label: {
                                    Text("Cancel")
                                        .font(.bodySmall)
                                        .foregroundColor(Color.momentum.gray)
                                }

                                Spacer()

                                Button {
                                    saveInteraction()
                                } label: {
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Save")
                                    }
                                    .font(.bodySmall)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.vertical, Spacing.sm)
                                    .background(Color.momentum.coral)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(Spacing.md)
                        .background(Color.momentum.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        .momentumShadow(radius: 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Notes
                    if !relationship.notes.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Notes")
                                .font(.titleSmall)
                                .foregroundColor(Color.momentum.charcoal)

                            Text(relationship.notes)
                                .font(.bodyMedium)
                                .foregroundColor(Color.momentum.gray)
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.momentum.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                    }

                    // Interaction History
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("History")
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)

                        if relationship.interactions.isEmpty {
                            Text("No interactions logged yet")
                                .font(.bodySmall)
                                .foregroundColor(Color.momentum.gray)
                                .padding(Spacing.md)
                        } else {
                            ForEach(relationship.interactions.sorted { $0.createdAt > $1.createdAt }) { interaction in
                                InteractionRow(interaction: interaction)
                            }
                        }
                    }

                    // Delete
                    Button(action: deleteRelationship) {
                        Text("Remove Person")
                            .font(.bodySmall)
                            .foregroundColor(Color.momentum.coral)
                    }
                    .padding(.top, Spacing.lg)
                }
                .padding(Spacing.md)
            }
            .background(Color.momentum.cream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showEditSheet = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(Color.momentum.charcoal)
                    }
                }
            }
            .fullScreenCover(isPresented: $showEditSheet) {
                EditRelationshipSheet(relationship: relationship)
            }
            .onAppear {
                if let type = initialInteractionType {
                    logInteractionType = type
                    withAnimation(.spring(response: 0.3)) {
                        showLogInteraction = true
                    }
                }
            }
        }
    }

    private func saveInteraction() {
        let interaction = Interaction(
            type: logInteractionType,
            initiatedBy: logInitiatedBy,
            notes: logNotes,
            relationship: relationship
        )

        relationship.interactions.append(interaction)

        // Auto-log as a Win so it appears in the Wins tab
        let winDescription = logNotes.isEmpty
            ? "\(logInteractionType.displayName) with \(relationship.name)"
            : logNotes
        let win = Win(
            description: winDescription,
            size: .small,
            emotion: 4,
            category: .relationships
        )
        modelContext.insert(win)

        GamificationManager.shared.recordInteraction(
            interaction: interaction,
            relationship: relationship,
            allRelationships: allRelationships,
            context: modelContext
        )

        try? modelContext.save()

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        withAnimation(.spring(response: 0.3)) {
            showLogInteraction = false
        }
        logNotes = ""
        logInitiatedBy = .me
    }

    private func deleteRelationship() {
        modelContext.delete(relationship)
        try? modelContext.save()
        dismiss()
    }
}

struct QuickActionLargeButton: View {
    let type: InteractionType
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                Text(type.displayName)
                    .font(.caption)
            }
            .foregroundColor(type.color)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(type.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }
}

struct InteractionRow: View {
    let interaction: Interaction

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(interaction.interactionType.color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: interaction.interactionType.icon)
                        .font(.system(size: 14))
                        .foregroundColor(interaction.interactionType.color)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(interaction.interactionType.displayName)
                    .font(.bodySmall)
                    .foregroundColor(Color.momentum.charcoal)

                Text("\(interaction.initiatedBy.displayName) • \(interaction.formattedDate)")
                    .font(.caption)
                    .foregroundColor(Color.momentum.gray)
            }

            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

// MARK: - Edit Relationship Sheet
struct EditRelationshipSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var relationship: Relationship

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $relationship.name)
                }

                Section("Category") {
                    Picker("Relationship type", selection: $relationship.category) {
                        ForEach(RelationshipCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }

                Section("Contact Goal") {
                    Picker("How often", selection: $relationship.contactGoal) {
                        ForEach(ContactGoal.allCases) { goal in
                            Text(goal.displayName).tag(goal)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $relationship.notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Edit Person")
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
    RelationshipsView()
        .environmentObject(PurchaseService())
}
