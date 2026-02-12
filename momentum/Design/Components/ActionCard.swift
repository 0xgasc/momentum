import SwiftUI

struct ActionCard: View {
    let action: MicroAction
    let onComplete: () -> Void
    let onTap: () -> Void
    var onReschedule: (() -> Void)? = nil
    var onSkip: (() -> Void)? = nil

    @State private var offset: CGFloat = 0
    @State private var isCompleting = false
    @State private var showQuickActions = false

    private let swipeThreshold: CGFloat = 80

    var body: some View {
        ZStack(alignment: .leading) {
            // Swipe right background (complete)
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, Spacing.lg)
                Text("Done!")
                    .font(.titleSmall)
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.momentum.sage)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

            // Swipe left background (reschedule)
            HStack {
                Spacer()
                Text("Tomorrow")
                    .font(.titleSmall)
                    .foregroundColor(.white)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.trailing, Spacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.momentum.gold)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

            // Main card
            HStack(spacing: Spacing.sm) {
                // Quick complete button
                Button {
                    completeAction()
                } label: {
                    Circle()
                        .strokeBorder(Color.momentum.sage, lineWidth: 2)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.momentum.sage)
                                .opacity(0.5)
                        )
                }
                .buttonStyle(.plain)

                // Type indicator
                Circle()
                    .fill(action.actionType.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: action.actionType.icon)
                            .font(.system(size: 16))
                            .foregroundColor(action.actionType.color)
                    )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(action.title)
                        .font(.titleSmall)
                        .foregroundColor(Color.momentum.charcoal)
                        .lineLimit(2)

                    if let goal = action.goal {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: goal.category.icon)
                                .font(.system(size: 10))
                            Text(goal.title)
                                .font(.caption)
                        }
                        .foregroundColor(Color.momentum.gray)
                    }
                }

                Spacer()

                // Quick action menu
                Menu {
                    Button {
                        completeAction()
                    } label: {
                        Label("Complete", systemImage: "checkmark.circle.fill")
                    }

                    if let onReschedule {
                        Button {
                            onReschedule()
                        } label: {
                            Label("Move to Tomorrow", systemImage: "calendar.badge.clock")
                        }
                    }

                    if let onSkip {
                        Button(role: .destructive) {
                            onSkip()
                        } label: {
                            Label("Skip", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.momentum.gray.opacity(0.5))
                }
            }
            .padding(Spacing.md)
            .background(Color.momentum.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .momentumShadow(radius: 4)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation.width
                    }
                    .onEnded { value in
                        if value.translation.width > swipeThreshold {
                            completeAction()
                        } else if value.translation.width < -swipeThreshold, let onReschedule {
                            rescheduleAction(onReschedule)
                        } else {
                            withAnimation(.spring(response: 0.3)) {
                                offset = 0
                            }
                        }
                    }
            )
            .onTapGesture {
                onTap()
            }
        }
        .opacity(isCompleting ? 0 : 1)
        .scaleEffect(isCompleting ? 0.8 : 1)
    }

    private func completeAction() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.3)) {
            offset = UIScreen.main.bounds.width
            isCompleting = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }

    private func rescheduleAction(_ action: @escaping () -> Void) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.3)) {
            offset = -UIScreen.main.bounds.width
            isCompleting = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            action()
        }
    }
}

// MARK: - Completed Action Card
struct CompletedActionCard: View {
    let action: MicroAction

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.momentum.sage)

            Text(action.title)
                .font(.bodyMedium)
                .foregroundColor(Color.momentum.gray)
                .strikethrough()

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.momentum.cream.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

#Preview {
    VStack(spacing: 16) {
        ActionCard(
            action: MicroAction(
                title: "Research top 5 companies in target industry",
                actionType: .research
            ),
            onComplete: {},
            onTap: {}
        )

        ActionCard(
            action: MicroAction(
                title: "Send follow-up email to mentor",
                actionType: .connect
            ),
            onComplete: {},
            onTap: {}
        )
    }
    .padding()
    .background(Color.momentum.cream)
}
