import Foundation
import Combine

// MARK: - Suggested Action Templates by Goal Category
struct ActionTemplate {
    let title: String
    let type: ActionType

    /// Convert this ActionTemplate to a Challenge
    func toChallenge(difficulty: ChallengeDifficulty = .easy, duration: ChallengeDuration = .daily) -> Challenge {
        // Map ActionType to ChallengeCategory
        let category: ChallengeCategory = {
            switch type {
            case .reflect: return .mindset
            case .research: return .growth
            case .connect: return .social
            case .create: return .creativity
            case .doIt: return .adventure
            }
        }()

        let xpReward = Int(Double(duration.baseXP) * difficulty.xpMultiplier)

        return Challenge(
            title: title,
            description: "Weather-inspired challenge: \(title)",
            category: category,
            difficulty: difficulty,
            duration: duration,
            xpReward: xpReward
        )
    }
}

struct ActionTemplates {

    /// Get suggested micro-actions based on goal category
    static func suggestions(for category: GoalCategory) -> [ActionTemplate] {
        switch category {
        case .adventure:
            return adventureActions
        case .career:
            return careerActions
        case .wealth:
            return wealthActions
        case .relationships:
            return relationshipActions
        case .growth:
            return growthActions
        case .wellness:
            return wellnessActions
        case .wildcard:
            return wildcardSuggestions() // Dynamic cross-category suggestions
        }
    }

    /// Smart wildcard: pulls random suggestions from ALL categories
    private static func wildcardSuggestions() -> [ActionTemplate] {
        let allCategories: [GoalCategory] = [.adventure, .career, .wealth, .relationships, .growth, .wellness]

        var suggestions: [ActionTemplate] = []

        // Pull 1 random suggestion from each category
        for category in allCategories.shuffled() {
            let categoryActions: [ActionTemplate]
            switch category {
            case .adventure: categoryActions = adventureActions
            case .career: categoryActions = careerActions
            case .wealth: categoryActions = wealthActions
            case .relationships: categoryActions = relationshipActions
            case .growth: categoryActions = growthActions
            case .wellness: categoryActions = wellnessActions
            case .wildcard: continue // Skip wildcard in the loop
            }
            if let randomPick = categoryActions.randomElement() {
                suggestions.append(randomPick)
            }
        }

        // Add surprise wildcard-only actions
        let surpriseActions = [
            ActionTemplate(title: "Do something you've been avoiding", type: .doIt),
            ActionTemplate(title: "Random act of kindness", type: .connect),
            ActionTemplate(title: "Learn one fascinating fact", type: .research),
            ActionTemplate(title: "Try the opposite of your usual", type: .doIt),
            ActionTemplate(title: "Say yes to something unexpected", type: .doIt),
            ActionTemplate(title: "Text someone you haven't talked to in a while", type: .connect)
        ]
        suggestions.append(contentsOf: surpriseActions.shuffled().prefix(2))

        return suggestions.shuffled()
    }

    // MARK: - Adventure Actions
    private static let adventureActions: [ActionTemplate] = [
        ActionTemplate(title: "Research destinations and costs", type: .research),
        ActionTemplate(title: "Set up a dedicated savings account", type: .doIt),
        ActionTemplate(title: "Talk to someone who's done this", type: .connect),
        ActionTemplate(title: "Create a vision board or Pinterest board", type: .create),
        ActionTemplate(title: "Book the first step (flight, accommodation, etc.)", type: .doIt),
        ActionTemplate(title: "List what you need to prepare or pack", type: .reflect),
        ActionTemplate(title: "Find travel groups or communities", type: .research),
        ActionTemplate(title: "Set a target date and mark your calendar", type: .doIt),
    ]

    // MARK: - Career Actions
    private static let careerActions: [ActionTemplate] = [
        ActionTemplate(title: "Update your resume/CV", type: .doIt),
        ActionTemplate(title: "Research companies you'd love to work for", type: .research),
        ActionTemplate(title: "Reach out to someone in your dream role", type: .connect),
        ActionTemplate(title: "Take an online course or certification", type: .doIt),
        ActionTemplate(title: "Practice for interviews", type: .doIt),
        ActionTemplate(title: "Reflect on your unique strengths", type: .reflect),
        ActionTemplate(title: "Update your LinkedIn profile", type: .doIt),
        ActionTemplate(title: "Create a portfolio or case study", type: .create),
        ActionTemplate(title: "Ask for feedback from a mentor", type: .connect),
        ActionTemplate(title: "Set up informational interviews", type: .connect),
    ]

    // MARK: - Wealth Actions
    private static let wealthActions: [ActionTemplate] = [
        ActionTemplate(title: "Track your spending for a week", type: .doIt),
        ActionTemplate(title: "Research investment options", type: .research),
        ActionTemplate(title: "Set up automatic savings transfers", type: .doIt),
        ActionTemplate(title: "Talk to a financially savvy friend", type: .connect),
        ActionTemplate(title: "Create a monthly budget", type: .create),
        ActionTemplate(title: "Reflect on your money mindset", type: .reflect),
        ActionTemplate(title: "Cancel unused subscriptions", type: .doIt),
        ActionTemplate(title: "Research side income opportunities", type: .research),
        ActionTemplate(title: "Open a high-yield savings account", type: .doIt),
        ActionTemplate(title: "Read a book about personal finance", type: .research),
    ]

    // MARK: - Relationship Actions
    private static let relationshipActions: [ActionTemplate] = [
        ActionTemplate(title: "Reach out to someone you've lost touch with", type: .connect),
        ActionTemplate(title: "Plan a meaningful date or hangout", type: .doIt),
        ActionTemplate(title: "Write a heartfelt message to someone", type: .create),
        ActionTemplate(title: "Reflect on what you value in relationships", type: .reflect),
        ActionTemplate(title: "Join a community or group", type: .doIt),
        ActionTemplate(title: "Research conversation starters", type: .research),
        ActionTemplate(title: "Send a surprise gift or card", type: .doIt),
        ActionTemplate(title: "Schedule regular check-ins with loved ones", type: .doIt),
        ActionTemplate(title: "Practice active listening today", type: .doIt),
        ActionTemplate(title: "Ask someone meaningful questions", type: .connect),
    ]

    // MARK: - Growth Actions
    private static let growthActions: [ActionTemplate] = [
        ActionTemplate(title: "Read for 20 minutes", type: .doIt),
        ActionTemplate(title: "Research courses or workshops", type: .research),
        ActionTemplate(title: "Find a mentor or accountability partner", type: .connect),
        ActionTemplate(title: "Journal about your progress", type: .reflect),
        ActionTemplate(title: "Watch a TED talk or documentary", type: .research),
        ActionTemplate(title: "Practice a new skill for 15 minutes", type: .doIt),
        ActionTemplate(title: "Create a learning roadmap", type: .create),
        ActionTemplate(title: "Teach someone what you've learned", type: .connect),
        ActionTemplate(title: "Reflect on lessons from failures", type: .reflect),
        ActionTemplate(title: "Set a 30-day challenge", type: .doIt),
    ]

    // MARK: - Wellness Actions
    private static let wellnessActions: [ActionTemplate] = [
        ActionTemplate(title: "Go for a 20-minute walk", type: .doIt),
        ActionTemplate(title: "Research healthy recipes", type: .research),
        ActionTemplate(title: "Find a workout buddy", type: .connect),
        ActionTemplate(title: "Meditate for 10 minutes", type: .reflect),
        ActionTemplate(title: "Prep healthy meals for the week", type: .doIt),
        ActionTemplate(title: "Create a sleep routine", type: .create),
        ActionTemplate(title: "Schedule a health checkup", type: .doIt),
        ActionTemplate(title: "Try a new type of exercise", type: .doIt),
        ActionTemplate(title: "Journal about how you feel", type: .reflect),
        ActionTemplate(title: "Drink 8 glasses of water today", type: .doIt),
    ]

    // MARK: - Wildcard Actions
    private static let wildcardActions: [ActionTemplate] = [
        ActionTemplate(title: "Brainstorm the first step", type: .reflect),
        ActionTemplate(title: "Research how others did it", type: .research),
        ActionTemplate(title: "Find someone to collaborate with", type: .connect),
        ActionTemplate(title: "Create a mood board or plan", type: .create),
        ActionTemplate(title: "Take one small action today", type: .doIt),
        ActionTemplate(title: "Set a 2-week mini milestone", type: .doIt),
        ActionTemplate(title: "Document your journey", type: .create),
        ActionTemplate(title: "Celebrate what you've done so far", type: .reflect),
    ]

    // MARK: - Quick Actions (for fast logging from Dashboard)
    static let quickActions: [ActionTemplate] = [
        ActionTemplate(title: "Completed a task", type: .doIt),
        ActionTemplate(title: "Did research", type: .research),
        ActionTemplate(title: "Reached out to someone", type: .connect),
        ActionTemplate(title: "Journaled or reflected", type: .reflect),
        ActionTemplate(title: "Created something", type: .create),
    ]
}
