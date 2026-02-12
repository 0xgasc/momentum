import Foundation
import SwiftData

enum GoalCategory: String, Codable, CaseIterable, Identifiable {
    case adventure
    case career
    case wealth
    case relationships
    case growth
    case wellness
    case wildcard

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    /// Categories shown to users (excludes wildcard which is internal-only)
    static var userFacing: [GoalCategory] {
        allCases.filter { $0 != .wildcard }
    }
}

@Model
final class Goal {
    var id: UUID
    var title: String
    var affirmation: String // Present-tense version "I am..."
    var category: GoalCategory
    var targetDate: Date?
    var isArchived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MicroAction.goal)
    var actions: [MicroAction]

    @Relationship(deleteRule: .cascade, inverse: \Win.goal)
    var wins: [Win]

    init(
        id: UUID = UUID(),
        title: String,
        affirmation: String,
        category: GoalCategory,
        targetDate: Date? = nil,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.affirmation = affirmation
        self.category = category
        self.targetDate = targetDate
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.actions = []
        self.wins = []
    }

    var activeActions: [MicroAction] {
        actions.filter { !$0.isCompleted }
    }

    var completedActions: [MicroAction] {
        actions.filter { $0.isCompleted }
    }

    var progressPercentage: Double {
        guard !actions.isEmpty else { return 0 }
        return Double(completedActions.count) / Double(actions.count)
    }
}
