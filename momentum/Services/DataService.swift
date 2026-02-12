import Foundation
import SwiftData

// MARK: - Data Service
@MainActor
class DataService {
    static let shared = DataService()

    private init() {}

    // MARK: - Sample Data for Testing
    static func createSampleData(in context: ModelContext) {
        // Sample Goals
        let goals = [
            Goal(
                title: "Launch my side project",
                affirmation: "I am a successful entrepreneur with a thriving business",
                category: .career,
                targetDate: Date().addingTimeInterval(86400 * 60)
            ),
            Goal(
                title: "Run a marathon",
                affirmation: "I am strong, disciplined, and capable of running 26.2 miles",
                category: .wellness,
                targetDate: Date().addingTimeInterval(86400 * 120)
            ),
            Goal(
                title: "Learn Spanish",
                affirmation: "I am fluent in Spanish and connect with people from around the world",
                category: .growth,
                targetDate: nil
            )
        ]

        for goal in goals {
            context.insert(goal)
        }

        // Sample Actions for first goal
        let actions = [
            MicroAction(title: "Research competitor pricing", actionType: .research, scheduledDate: Date(), goal: goals[0]),
            MicroAction(title: "Draft landing page copy", actionType: .create, scheduledDate: Date(), goal: goals[0]),
            MicroAction(title: "Reach out to potential beta testers", actionType: .connect, scheduledDate: Date().addingTimeInterval(86400), goal: goals[0])
        ]

        for action in actions {
            goals[0].actions.append(action)
        }

        // Sample Wins
        let wins = [
            Win(description: "Finished the first prototype!", size: .medium, emotion: 4, goal: goals[0]),
            Win(description: "Ran 5 miles without stopping", size: .small, emotion: 3, goal: goals[1]),
            Win(description: "Had a 10-minute conversation in Spanish", size: .small, emotion: 4, goal: goals[2])
        ]

        for win in wins {
            context.insert(win)
        }

        // Sample Relationships
        let relationships = [
            Relationship(name: "Sarah Chen", category: .mentor, contactGoal: .biweekly, notes: "Former manager, great for career advice"),
            Relationship(name: "Marcus Johnson", category: .peer, contactGoal: .weekly, notes: "Co-founder of similar startup"),
            Relationship(name: "Alex Rivera", category: .supporter, contactGoal: .monthly, notes: "Old college friend, always encouraging")
        ]

        for relationship in relationships {
            context.insert(relationship)

            // Add sample interaction
            let interaction = Interaction(
                type: .message,
                initiatedBy: .me,
                notes: "Caught up about recent progress",
                createdAt: Date().addingTimeInterval(-86400 * Double.random(in: 1...10)),
                relationship: relationship
            )
            relationship.interactions.append(interaction)
        }

        try? context.save()
    }

    // MARK: - Statistics
    static func calculateStats(goals: [Goal], wins: [Win]) -> DashboardStats {
        let totalWins = wins.count
        let todaysWins = wins.filter { Calendar.current.isDateInToday($0.createdAt) }.count

        let allActions = goals.flatMap { $0.actions }
        let completedToday = allActions.filter {
            $0.isCompleted && $0.completedAt != nil && Calendar.current.isDateInToday($0.completedAt!)
        }.count

        // Calculate streak
        var streak = 0
        var checkDate = Date()

        for _ in 0..<365 {
            let dayActions = allActions.filter {
                $0.isCompleted && $0.completedAt != nil &&
                Calendar.current.isDate($0.completedAt!, inSameDayAs: checkDate)
            }

            if dayActions.isEmpty && !Calendar.current.isDateInToday(checkDate) {
                break
            }

            if !dayActions.isEmpty {
                streak += 1
            }

            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        return DashboardStats(
            totalWins: totalWins,
            todaysWins: todaysWins,
            actionsCompletedToday: completedToday,
            currentStreak: streak
        )
    }
}

// MARK: - Dashboard Stats
struct DashboardStats {
    let totalWins: Int
    let todaysWins: Int
    let actionsCompletedToday: Int
    let currentStreak: Int
}

// MARK: - Date Helpers
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: self, to: date).day ?? 0
    }
}
