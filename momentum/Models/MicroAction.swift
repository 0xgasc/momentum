import Foundation
import SwiftData

enum ActionType: String, Codable, CaseIterable, Identifiable {
    case doIt = "do"
    case research
    case connect
    case reflect
    case create

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .doIt: return "Do"
        case .research: return "Research"
        case .connect: return "Connect"
        case .reflect: return "Reflect"
        case .create: return "Create"
        }
    }

    var icon: String {
        switch self {
        case .doIt: return "checkmark.circle.fill"
        case .research: return "magnifyingglass"
        case .connect: return "person.2.fill"
        case .reflect: return "brain.head.profile"
        case .create: return "paintbrush.fill"
        }
    }

    var color: Color {
        switch self {
        case .doIt: return Color.momentum.coral
        case .research: return Color.momentum.plum
        case .connect: return Color.momentum.sage
        case .reflect: return Color.momentum.gold
        case .create: return Color.momentum.coral
        }
    }
}

import SwiftUI

@Model
final class MicroAction {
    var id: UUID
    var title: String
    var actionType: ActionType
    var isCompleted: Bool
    var scheduledDate: Date?
    var completedAt: Date?
    var createdAt: Date

    var goal: Goal?

    @Relationship(deleteRule: .nullify, inverse: \Win.action)
    var win: Win?

    init(
        id: UUID = UUID(),
        title: String,
        actionType: ActionType,
        isCompleted: Bool = false,
        scheduledDate: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        goal: Goal? = nil
    ) {
        self.id = id
        self.title = title
        self.actionType = actionType
        self.isCompleted = isCompleted
        self.scheduledDate = scheduledDate
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.goal = goal
    }

    var isScheduledForToday: Bool {
        guard let scheduledDate else { return false }
        return Calendar.current.isDateInToday(scheduledDate)
    }

    func complete() {
        isCompleted = true
        completedAt = Date()
    }
}
