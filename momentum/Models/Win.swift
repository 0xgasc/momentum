import Foundation
import SwiftData
import SwiftUI

enum WinSize: String, Codable, CaseIterable, Identifiable {
    case tiny
    case small
    case medium
    case big
    case massive

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .tiny: return "sparkle"
        case .small: return "star.fill"
        case .medium: return "star.circle.fill"
        case .big: return "trophy.fill"
        case .massive: return "crown.fill"
        }
    }

    var confettiIntensity: Int {
        switch self {
        case .tiny: return 20
        case .small: return 50
        case .medium: return 100
        case .big: return 200
        case .massive: return 300
        }
    }

    var color: Color {
        switch self {
        case .tiny: return Color.momentum.sage
        case .small: return Color.momentum.sage
        case .medium: return Color.momentum.gold
        case .big: return Color.momentum.coral
        case .massive: return Color.momentum.coral
        }
    }
}

@Model
final class Win {
    var id: UUID
    var winDescription: String
    var size: WinSize
    var emotion: Int // 1-5
    var createdAt: Date
    var category: GoalCategory? // NEW - optional, lightweight migration

    var goal: Goal?
    var action: MicroAction?

    init(
        id: UUID = UUID(),
        description: String,
        size: WinSize,
        emotion: Int = 3,
        createdAt: Date = Date(),
        category: GoalCategory? = nil,
        goal: Goal? = nil,
        action: MicroAction? = nil
    ) {
        self.id = id
        self.winDescription = description
        self.size = size
        self.emotion = min(5, max(1, emotion))
        self.createdAt = createdAt
        self.category = category ?? goal?.category // Smart default from goal
        self.goal = goal
        self.action = action
    }

    /// Resolved category (direct or from goal)
    var resolvedCategory: GoalCategory? {
        category ?? goal?.category
    }

    var emotionEmoji: String {
        switch emotion {
        case 1: return "😊"
        case 2: return "😄"
        case 3: return "🥳"
        case 4: return "🔥"
        case 5: return "🚀"
        default: return "😊"
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
}
