import SwiftUI

struct AffirmationCard: View {
    let affirmation: String
    let onRefresh: () -> Void
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Today's Mindset")
                    .font(.caption)
                    .foregroundColor(Color.momentum.plum)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isAnimating = true
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onRefresh()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            isAnimating = false
                        }
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.momentum.plum)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
            }

            Text(affirmation)
                .font(.displayMedium)
                .foregroundColor(Color.momentum.charcoal)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.momentum.plum.opacity(0.08),
                    Color.momentum.plum.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .momentumShadow()
    }
}

// MARK: - Affirmation Content
struct AffirmationContent {
    // MARK: - Gentle Style (Self-compassion focused)
    static let gentleMorningPrompts = [
        "You're exactly where you need to be right now.",
        "Progress isn't always visible, but it's always happening.",
        "Be gentle with yourself today. Growth takes time.",
        "You don't have to be perfect to be amazing.",
        "Every small step forward is still a step forward.",
        "Your worth isn't measured by your productivity.",
        "Take a breath. You've got this, at your own pace.",
        "It's okay to rest. Rest is part of the journey.",
        "You're doing better than you think you are.",
        "Today is a fresh start. No pressure, just possibilities."
    ]

    static let gentleCompletionMessages = [
        "Look at you, taking care of business.",
        "That's a win worth celebrating.",
        "You should be proud of yourself.",
        "Every step counts. This one counted.",
        "Well done. You're making progress.",
        "That's self-care in action.",
        "You're building something beautiful.",
        "Another piece of the puzzle in place.",
        "You're showing up for yourself.",
        "That's growth."
    ]

    // MARK: - Balanced Style (Mix of support and accountability)
    static let balancedMorningPrompts = [
        "What would you do today if you knew you couldn't fail?",
        "Your future self is watching. Make them proud.",
        "Today's actions write tomorrow's story.",
        "Someone with your exact circumstances achieved your exact goal.",
        "You're not behind. You're on your own timeline.",
        "Every expert was once a beginner who refused to quit.",
        "Your potential is not defined by your past.",
        "Small steps still move you forward.",
        "The best time to start was yesterday. The second best time is now.",
        "You have the same 24 hours as everyone else. Use them wisely."
    ]

    static let balancedCompletionMessages = [
        "That's how it's done.",
        "Look at you, making moves.",
        "Your future self just high-fived you.",
        "Plot: advancing.",
        "Momentum: building.",
        "Another one. Keep going.",
        "You're on fire today.",
        "This is what winning looks like.",
        "Tiny action, mighty impact.",
        "Level up."
    ]

    // MARK: - Intense Style (Main character energy, no excuses)
    static let intenseMorningPrompts = [
        "Main character energy only. Let's get it.",
        "The audacity to try is the only audacity you need.",
        "You're not here to be average. Act like it.",
        "No excuses. No limits. Just results.",
        "Winners don't wait for perfect conditions.",
        "Your dreams don't have a snooze button.",
        "Be the energy you want to attract.",
        "While they sleep, you work. That's the difference.",
        "Soft life? Earn it first.",
        "Today's discomfort is tomorrow's flex."
    ]

    static let intenseCompletionMessages = [
        "That's the energy. Keep matching it.",
        "Period. No notes.",
        "Ate and left no crumbs.",
        "This is giving main character.",
        "The version of you who wins? That's you right now.",
        "Your future self is literally cheering.",
        "Obsessed with this growth.",
        "Unbothered. Focused. Winning.",
        "Another W for the collection.",
        "That's literally iconic."
    ]

    static func randomMorningPrompt(style: UserProfile.MotivationStyle = .balanced) -> String {
        let prompts: [String]
        switch style {
        case .gentle: prompts = gentleMorningPrompts
        case .balanced: prompts = balancedMorningPrompts
        case .intense: prompts = intenseMorningPrompts
        }
        return prompts.randomElement() ?? prompts[0]
    }

    static func randomCompletionMessage(style: UserProfile.MotivationStyle = .balanced) -> String {
        let messages: [String]
        switch style {
        case .gentle: messages = gentleCompletionMessages
        case .balanced: messages = balancedCompletionMessages
        case .intense: messages = intenseCompletionMessages
        }
        return messages.randomElement() ?? messages[0]
    }

    // Convenience methods that use the user's saved preference
    static func randomMorningPrompt() -> String {
        let style = UserProfileManager.shared.profile.motivationStyle
        return randomMorningPrompt(style: style)
    }

    static func randomCompletionMessage() -> String {
        let style = UserProfileManager.shared.profile.motivationStyle
        return randomCompletionMessage(style: style)
    }
}

#Preview {
    AffirmationCard(
        affirmation: "What would you do today if you knew you couldn't fail?",
        onRefresh: {}
    )
    .padding()
    .background(Color.momentum.cream)
}
