import SwiftUI

struct RelationshipCard: View {
    let relationship: Relationship
    let onTap: () -> Void
    let onQuickLog: (InteractionType) -> Void

    @State private var showQuickActions = false

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Card content area - tappable to open detail
            Button(action: onTap) {
                VStack(spacing: Spacing.sm) {
                    // Avatar with health indicator
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(relationship.category.color.opacity(0.15))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Text(relationship.initials)
                                    .font(.titleMedium)
                                    .foregroundColor(relationship.category.color)
                            )

                        Circle()
                            .fill(relationship.healthStatus.color)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.momentum.white, lineWidth: 2)
                            )
                    }

                    Text(relationship.name)
                        .font(.bodySmall)
                        .foregroundColor(Color.momentum.charcoal)
                        .lineLimit(1)

                    // Last contact
                    if let days = relationship.daysSinceLastContact {
                        Text(days == 0 ? "Today" : "\(days)d ago")
                            .font(.caption)
                            .foregroundColor(relationship.healthStatus.color)
                    } else {
                        Text("Never")
                            .font(.caption)
                            .foregroundColor(Color.momentum.gray)
                    }
                }
            }
            .buttonStyle(.plain)

            // Quick action buttons — OUTSIDE the card button, no nesting
            HStack(spacing: Spacing.xxs) {
                QuickActionButton(icon: "phone.fill", color: Color.momentum.coral) {
                    onQuickLog(.call)
                }
                QuickActionButton(icon: "message.fill", color: Color.momentum.plum) {
                    onQuickLog(.message)
                }
                QuickActionButton(icon: "person.2.fill", color: Color.momentum.sage) {
                    onQuickLog(.inPerson)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow(radius: 4)
    }
}

struct QuickActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

// MARK: - Neglected Relationships Banner
struct NeglectedBanner: View {
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color.momentum.coral)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) relationship\(count == 1 ? "" : "s") need\(count == 1 ? "s" : "") attention")
                        .font(.bodySmall)
                        .foregroundColor(Color.momentum.charcoal)
                    Text("Tap to see who to reach out to")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.momentum.gray)
            }
            .padding(Spacing.md)
            .background(Color.momentum.coral.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }
}

// MARK: - Interaction Type Picker
struct InteractionTypePicker: View {
    @Binding var selectedType: InteractionType

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.sm) {
            ForEach(InteractionType.allCases) { type in
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    selectedType = type
                }) {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: type.icon)
                            .font(.system(size: 24))
                        Text(type.displayName)
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(selectedType == type ? type.color : Color.momentum.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(
                        selectedType == type
                            ? type.color.opacity(0.15)
                            : Color.momentum.cream
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                }
            }
        }
    }
}

#Preview {
    let relationship = Relationship(
        name: "Sarah Chen",
        category: .mentor,
        contactGoal: .biweekly
    )

    VStack(spacing: 20) {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            RelationshipCard(
                relationship: relationship,
                onTap: {},
                onQuickLog: { _ in }
            )
            RelationshipCard(
                relationship: relationship,
                onTap: {},
                onQuickLog: { _ in }
            )
        }

        NeglectedBanner(count: 3, onTap: {})

        InteractionTypePicker(selectedType: .constant(.call))
    }
    .padding()
    .background(Color.momentum.cream)
}
