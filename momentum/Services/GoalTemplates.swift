import Foundation

struct GoalTemplate: Identifiable {
    let id = UUID()
    let title: String
    let affirmation: String
    let emoji: String
}

struct GoalTemplates {
    static func templates(for category: GoalCategory) -> [GoalTemplate] {
        switch category {
        case .adventure:
            return [
                GoalTemplate(title: "Travel to a new country", affirmation: "I am an adventurous explorer", emoji: "✈️"),
                GoalTemplate(title: "Try 10 new experiences this year", affirmation: "I embrace the unknown fearlessly", emoji: "🎯"),
                GoalTemplate(title: "Learn an extreme sport", affirmation: "I push my limits and grow", emoji: "🏄"),
            ]
        case .career:
            return [
                GoalTemplate(title: "Get promoted this year", affirmation: "I am a leader in my field", emoji: "🚀"),
                GoalTemplate(title: "Launch my side business", affirmation: "I am a successful entrepreneur", emoji: "💼"),
                GoalTemplate(title: "Switch to my dream career", affirmation: "I deserve work that fulfills me", emoji: "✨"),
                GoalTemplate(title: "Build my personal brand", affirmation: "I am known for my expertise", emoji: "📣"),
            ]
        case .wealth:
            return [
                GoalTemplate(title: "Save a $10K emergency fund", affirmation: "I am financially secure and free", emoji: "🏦"),
                GoalTemplate(title: "Pay off all my debt", affirmation: "I am debt-free and thriving", emoji: "💳"),
                GoalTemplate(title: "Start investing consistently", affirmation: "I build wealth with confidence", emoji: "📈"),
            ]
        case .relationships:
            return [
                GoalTemplate(title: "Strengthen my inner circle", affirmation: "I nurture meaningful connections", emoji: "💛"),
                GoalTemplate(title: "Find my community", affirmation: "I attract people who elevate me", emoji: "👥"),
                GoalTemplate(title: "Be more present with loved ones", affirmation: "I give my full attention to those I love", emoji: "🤝"),
            ]
        case .growth:
            return [
                GoalTemplate(title: "Read 24 books this year", affirmation: "I am a lifelong learner", emoji: "📚"),
                GoalTemplate(title: "Learn a new language", affirmation: "I am capable of learning anything", emoji: "🌍"),
                GoalTemplate(title: "Get certified in my field", affirmation: "I invest in my growth daily", emoji: "🎓"),
                GoalTemplate(title: "Start journaling daily", affirmation: "I understand myself deeply", emoji: "📝"),
            ]
        case .wellness:
            return [
                GoalTemplate(title: "Run a 5K", affirmation: "My body is strong and capable", emoji: "🏃"),
                GoalTemplate(title: "Meditate every day", affirmation: "I am calm, centered, and present", emoji: "🧘"),
                GoalTemplate(title: "Build a morning routine", affirmation: "I start each day with intention", emoji: "🌅"),
                GoalTemplate(title: "Cook healthy meals weekly", affirmation: "I nourish my body with love", emoji: "🥗"),
            ]
        case .wildcard:
            return []
        }
    }
}
