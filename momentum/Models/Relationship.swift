import Foundation
import SwiftData
import SwiftUI

enum RelationshipCategory: String, Codable, CaseIterable, Identifiable {
    case mentor
    case peer
    case supporter
    case aspirational
    case professional
    case personal

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .mentor: return "graduationcap.fill"
        case .peer: return "person.2.fill"
        case .supporter: return "hands.clap.fill"
        case .aspirational: return "star.fill"
        case .professional: return "briefcase.fill"
        case .personal: return "heart.fill"
        }
    }
}

enum ContactGoal: String, Codable, CaseIterable, Identifiable {
    case weekly
    case biweekly
    case monthly
    case quarterly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        }
    }

    var days: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        }
    }
}

@Model
final class Relationship {
    var id: UUID
    var name: String
    var category: RelationshipCategory
    var contactGoal: ContactGoal
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Interaction.relationship)
    var interactions: [Interaction]

    init(
        id: UUID = UUID(),
        name: String,
        category: RelationshipCategory,
        contactGoal: ContactGoal = .monthly,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.contactGoal = contactGoal
        self.notes = notes
        self.createdAt = createdAt
        self.interactions = []
    }

    var lastInteraction: Interaction? {
        interactions.sorted { $0.createdAt > $1.createdAt }.first
    }

    var daysSinceLastContact: Int? {
        guard let lastInteraction else { return nil }
        return Calendar.current.dateComponents([.day], from: lastInteraction.createdAt, to: Date()).day
    }

    var healthStatus: HealthStatus {
        guard let days = daysSinceLastContact else { return .neutral }
        let goalDays = contactGoal.days

        if days <= goalDays {
            return .healthy
        } else if days <= goalDays * 2 {
            return .warning
        } else {
            return .neglected
        }
    }

    enum HealthStatus {
        case healthy
        case warning
        case neglected
        case neutral

        var color: Color {
            switch self {
            case .healthy: return Color.momentum.sage
            case .warning: return Color.momentum.gold
            case .neglected: return Color.momentum.coral
            case .neutral: return Color.momentum.gray
            }
        }
    }

    var initials: String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
