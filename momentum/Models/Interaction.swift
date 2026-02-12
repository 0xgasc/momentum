import Foundation
import SwiftData
import SwiftUI

enum InteractionType: String, Codable, CaseIterable, Identifiable {
    case call
    case message
    case inPerson
    case sentGift
    case helpedThem
    case theyHelpedMe

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .call: return "Call"
        case .message: return "Message"
        case .inPerson: return "In Person"
        case .sentGift: return "Sent Gift"
        case .helpedThem: return "Helped Them"
        case .theyHelpedMe: return "They Helped Me"
        }
    }

    var icon: String {
        switch self {
        case .call: return "phone.fill"
        case .message: return "message.fill"
        case .inPerson: return "person.2.fill"
        case .sentGift: return "gift.fill"
        case .helpedThem: return "hand.raised.fill"
        case .theyHelpedMe: return "hands.clap.fill"
        }
    }

    var color: Color {
        switch self {
        case .call: return Color.momentum.coral
        case .message: return Color.momentum.plum
        case .inPerson: return Color.momentum.sage
        case .sentGift: return Color.momentum.gold
        case .helpedThem: return Color.momentum.coral
        case .theyHelpedMe: return Color.momentum.sage
        }
    }
}

enum Initiator: String, Codable, CaseIterable, Identifiable {
    case me
    case them

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .me: return "I initiated"
        case .them: return "They reached out"
        }
    }
}

@Model
final class Interaction {
    var id: UUID
    var interactionType: InteractionType
    var initiatedBy: Initiator
    var notes: String
    var createdAt: Date

    var relationship: Relationship?

    init(
        id: UUID = UUID(),
        type: InteractionType,
        initiatedBy: Initiator = .me,
        notes: String = "",
        createdAt: Date = Date(),
        relationship: Relationship? = nil
    ) {
        self.id = id
        self.interactionType = type
        self.initiatedBy = initiatedBy
        self.notes = notes
        self.createdAt = createdAt
        self.relationship = relationship
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
