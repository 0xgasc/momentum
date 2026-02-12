import SwiftUI
import SwiftData
import Combine

// MARK: - Challenge Model
@Model
final class Challenge {
    var id: UUID
    var title: String
    var challengeDescription: String
    var categoryRaw: String
    var difficultyRaw: String
    var durationRaw: String
    var xpReward: Int
    var isCompleted: Bool
    var isActive: Bool
    var startedAt: Date?
    var completedAt: Date?
    var expiresAt: Date?

    // Completion reflection fields (journal-like)
    var completionNotes: String?
    var completionEmotion: Int?
    var completionPhotoData: Data?
    var voiceMemoPath: String?

    var category: ChallengeCategory {
        get { ChallengeCategory(rawValue: categoryRaw) ?? .mindset }
        set { categoryRaw = newValue.rawValue }
    }

    var difficulty: ChallengeDifficulty {
        get { ChallengeDifficulty(rawValue: difficultyRaw) ?? .easy }
        set { difficultyRaw = newValue.rawValue }
    }

    var duration: ChallengeDuration {
        get { ChallengeDuration(rawValue: durationRaw) ?? .daily }
        set { durationRaw = newValue.rawValue }
    }

    /// Map challenge difficulty to appropriate win size
    var correspondingWinSize: WinSize {
        switch difficulty {
        case .easy: return .small
        case .medium: return .medium
        case .hard: return .big
        case .epic: return .massive
        }
    }

    init(
        title: String,
        description: String,
        category: ChallengeCategory,
        difficulty: ChallengeDifficulty,
        duration: ChallengeDuration,
        xpReward: Int
    ) {
        self.id = UUID()
        self.title = title
        self.challengeDescription = description
        self.categoryRaw = category.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.durationRaw = duration.rawValue
        self.xpReward = xpReward
        self.isCompleted = false
        self.isActive = false
    }
}

enum ChallengeCategory: String, Codable, CaseIterable, Identifiable {
    case mindset = "Mindset"
    case fitness = "Fitness"
    case social = "Social"
    case growth = "Growth"
    case adventure = "Adventure"
    case creativity = "Creativity"
    case wellness = "Wellness"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .mindset: return "brain.head.profile"
        case .fitness: return "figure.run"
        case .social: return "person.2.fill"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .adventure: return "map.fill"
        case .creativity: return "paintbrush.fill"
        case .wellness: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .mindset: return Color.momentum.plum
        case .fitness: return Color.momentum.coral
        case .social: return Color.momentum.sage
        case .growth: return Color.momentum.gold
        case .adventure: return Color(red: 0.4, green: 0.6, blue: 0.9)
        case .creativity: return Color(red: 0.9, green: 0.5, blue: 0.7)
        case .wellness: return Color(red: 0.6, green: 0.8, blue: 0.7)
        }
    }
}

enum ChallengeDifficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case epic = "Epic"

    var xpMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        case .epic: return 3.0
        }
    }

    var color: Color {
        switch self {
        case .easy: return Color.momentum.sage
        case .medium: return Color.momentum.gold
        case .hard: return Color.momentum.coral
        case .epic: return Color.momentum.plum
        }
    }
}

enum ChallengeDuration: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var baseXP: Int {
        switch self {
        case .daily: return 50
        case .weekly: return 200
        case .monthly: return 500
        }
    }
}

// MARK: - Challenge Templates
struct ChallengeTemplates {

    static func dailyChallenges(for focusAreas: Set<GoalCategory>) -> [ChallengeTemplate] {
        var challenges: [ChallengeTemplate] = []

        // Mindset challenges (always included)
        challenges += [
            ChallengeTemplate(
                title: "Morning Manifestation",
                description: "Write down 3 things you're grateful for before 9am",
                category: .mindset, difficulty: .easy, duration: .daily
            ),
            ChallengeTemplate(
                title: "Affirmation Power",
                description: "Say your affirmation out loud 5 times",
                category: .mindset, difficulty: .easy, duration: .daily
            ),
            ChallengeTemplate(
                title: "Digital Detox Hour",
                description: "No phone for 1 hour (not including sleep)",
                category: .wellness, difficulty: .medium, duration: .daily
            )
        ]

        // Fitness challenges
        if focusAreas.contains(.wellness) || focusAreas.contains(.adventure) {
            challenges += [
                ChallengeTemplate(
                    title: "Power Walk",
                    description: "Take a 30-minute walk outdoors",
                    category: .fitness, difficulty: .easy, duration: .daily
                ),
                ChallengeTemplate(
                    title: "Morning Movement",
                    description: "10 minutes of stretching or yoga before noon",
                    category: .fitness, difficulty: .easy, duration: .daily
                ),
                ChallengeTemplate(
                    title: "Stairway to Goals",
                    description: "Take the stairs instead of elevators all day",
                    category: .fitness, difficulty: .medium, duration: .daily
                )
            ]
        }

        // Social challenges
        if focusAreas.contains(.relationships) {
            challenges += [
                ChallengeTemplate(
                    title: "Reach Out",
                    description: "Text or call someone you haven't talked to in 2+ weeks",
                    category: .social, difficulty: .easy, duration: .daily
                ),
                ChallengeTemplate(
                    title: "Genuine Compliment",
                    description: "Give 3 genuine compliments to different people",
                    category: .social, difficulty: .easy, duration: .daily
                ),
                ChallengeTemplate(
                    title: "Voice Note Love",
                    description: "Send a voice message to a friend instead of texting",
                    category: .social, difficulty: .easy, duration: .daily
                )
            ]
        }

        // Career/Growth challenges
        if focusAreas.contains(.career) || focusAreas.contains(.growth) {
            challenges += [
                ChallengeTemplate(
                    title: "Learn Something New",
                    description: "Watch a 15+ minute educational video",
                    category: .growth, difficulty: .easy, duration: .daily
                ),
                ChallengeTemplate(
                    title: "Network Nudge",
                    description: "Connect with 1 new person on LinkedIn",
                    category: .growth, difficulty: .medium, duration: .daily
                ),
                ChallengeTemplate(
                    title: "Skill Stack",
                    description: "Spend 30 minutes learning a new skill",
                    category: .growth, difficulty: .medium, duration: .daily
                )
            ]
        }

        // Adventure challenges
        if focusAreas.contains(.adventure) {
            challenges += [
                ChallengeTemplate(
                    title: "New Route",
                    description: "Take a different route somewhere today",
                    category: .adventure, difficulty: .easy, duration: .daily
                ),
                ChallengeTemplate(
                    title: "Say Yes",
                    description: "Say yes to something you'd normally say no to",
                    category: .adventure, difficulty: .medium, duration: .daily
                ),
                ChallengeTemplate(
                    title: "Solo Adventure",
                    description: "Do one activity alone that you'd usually do with others",
                    category: .adventure, difficulty: .medium, duration: .daily
                )
            ]
        }

        // Creative challenges
        challenges += [
            ChallengeTemplate(
                title: "Creative 15",
                description: "Spend 15 minutes on a creative activity",
                category: .creativity, difficulty: .easy, duration: .daily
            ),
            ChallengeTemplate(
                title: "Photo Moment",
                description: "Take a photo of something beautiful you notice",
                category: .creativity, difficulty: .easy, duration: .daily
            )
        ]

        return challenges
    }

    static func weeklyChallenges(for focusAreas: Set<GoalCategory>) -> [ChallengeTemplate] {
        var challenges: [ChallengeTemplate] = []

        challenges += [
            ChallengeTemplate(
                title: "Consistency Champ",
                description: "Complete your morning routine 5 days this week",
                category: .mindset, difficulty: .medium, duration: .weekly
            ),
            ChallengeTemplate(
                title: "Reflection Sunday",
                description: "Write a full journal entry reviewing your week",
                category: .mindset, difficulty: .easy, duration: .weekly
            ),
            ChallengeTemplate(
                title: "Action Streak",
                description: "Complete at least 3 micro-actions every day for 7 days",
                category: .growth, difficulty: .hard, duration: .weekly
            )
        ]

        if focusAreas.contains(.wellness) || focusAreas.contains(.adventure) {
            challenges += [
                ChallengeTemplate(
                    title: "Move Your Body",
                    description: "Exercise 4 times this week",
                    category: .fitness, difficulty: .medium, duration: .weekly
                ),
                ChallengeTemplate(
                    title: "Hydration Station",
                    description: "Drink 8 glasses of water every day for 7 days",
                    category: .wellness, difficulty: .medium, duration: .weekly
                ),
                ChallengeTemplate(
                    title: "Early Bird",
                    description: "Wake up before 7am 5 days this week",
                    category: .wellness, difficulty: .hard, duration: .weekly
                )
            ]
        }

        if focusAreas.contains(.relationships) {
            challenges += [
                ChallengeTemplate(
                    title: "Connection Week",
                    description: "Have a meaningful conversation with 5 different people",
                    category: .social, difficulty: .medium, duration: .weekly
                ),
                ChallengeTemplate(
                    title: "Quality Time",
                    description: "Spend 2+ hours of uninterrupted time with someone you love",
                    category: .social, difficulty: .easy, duration: .weekly
                )
            ]
        }

        if focusAreas.contains(.adventure) {
            challenges += [
                ChallengeTemplate(
                    title: "Explorer Mode",
                    description: "Visit a place in your city you've never been to",
                    category: .adventure, difficulty: .medium, duration: .weekly
                ),
                ChallengeTemplate(
                    title: "Try Something New",
                    description: "Try a new restaurant, activity, or hobby",
                    category: .adventure, difficulty: .easy, duration: .weekly
                )
            ]
        }

        return challenges
    }

    static func monthlyChallenges(for focusAreas: Set<GoalCategory>) -> [ChallengeTemplate] {
        var challenges: [ChallengeTemplate] = [
            ChallengeTemplate(
                title: "30-Day Journal Streak",
                description: "Write in your journal every single day",
                category: .mindset, difficulty: .epic, duration: .monthly
            ),
            ChallengeTemplate(
                title: "Goal Crusher",
                description: "Complete 50 micro-actions this month",
                category: .growth, difficulty: .hard, duration: .monthly
            ),
            ChallengeTemplate(
                title: "Digital Minimalist",
                description: "Reduce screen time by 1 hour daily average",
                category: .wellness, difficulty: .hard, duration: .monthly
            )
        ]

        if focusAreas.contains(.wellness) {
            challenges += [
                ChallengeTemplate(
                    title: "Fitness February",
                    description: "Work out 20 times this month",
                    category: .fitness, difficulty: .epic, duration: .monthly
                ),
                ChallengeTemplate(
                    title: "Sleep Routine",
                    description: "Go to bed before 11pm for 20 days",
                    category: .wellness, difficulty: .hard, duration: .monthly
                )
            ]
        }

        if focusAreas.contains(.career) {
            challenges += [
                ChallengeTemplate(
                    title: "Skill Master",
                    description: "Complete an online course or certification",
                    category: .growth, difficulty: .epic, duration: .monthly
                ),
                ChallengeTemplate(
                    title: "Network Builder",
                    description: "Have 10 career-related conversations",
                    category: .social, difficulty: .hard, duration: .monthly
                )
            ]
        }

        return challenges
    }
}

struct ChallengeTemplate {
    let title: String
    let description: String
    let category: ChallengeCategory
    let difficulty: ChallengeDifficulty
    let duration: ChallengeDuration

    var xpReward: Int {
        Int(Double(duration.baseXP) * difficulty.xpMultiplier)
    }

    func toChallenge() -> Challenge {
        Challenge(
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            duration: duration,
            xpReward: xpReward
        )
    }
}

// MARK: - Badge System
enum Badge: String, CaseIterable, Identifiable, Codable {
    // Streak badges
    case firstStep = "First Step"
    case weekWarrior = "Week Warrior"
    case monthlyMaster = "Monthly Master"
    case hundredDayHero = "100 Day Hero"

    // Action badges
    case actionTaker = "Action Taker"
    case doer = "Doer"
    case achiever = "Achiever"
    case unstoppable = "Unstoppable"

    // Win badges
    case firstWin = "First Win"
    case winStreak = "Win Streak"
    case bigWinner = "Big Winner"
    case victoryLap = "Victory Lap"

    // Challenge badges
    case challengeAccepted = "Challenge Accepted"
    case challengeChamp = "Challenge Champ"
    case epicConqueror = "Epic Conqueror"

    // Category badges
    case mindsetMaster = "Mindset Master"
    case fitnessFreak = "Fitness Freak"
    case socialButterfly = "Social Butterfly"
    case growthGuru = "Growth Guru"
    case adventurer = "Adventurer"
    case creator = "Creator"

    // Special badges
    case earlyBird = "Early Bird"
    case nightOwl = "Night Owl"
    case weekendWarrior = "Weekend Warrior"
    case consistencyChamp = "Consistency Champ"

    // Relationship badges
    case firstReachOut = "First Reach Out"
    case mentorConnection = "Mentor Connection"
    case innerCircle = "Inner Circle"
    case consistentConnector = "Consistent Connector"
    case relationshipBuilder = "Relationship Builder"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .firstStep: return "shoe.fill"
        case .weekWarrior: return "7.circle.fill"
        case .monthlyMaster: return "calendar.circle.fill"
        case .hundredDayHero: return "100.circle.fill"
        case .actionTaker: return "bolt.fill"
        case .doer: return "checkmark.circle.fill"
        case .achiever: return "star.fill"
        case .unstoppable: return "flame.fill"
        case .firstWin: return "trophy.fill"
        case .winStreak: return "trophy.circle.fill"
        case .bigWinner: return "crown.fill"
        case .victoryLap: return "medal.fill"
        case .challengeAccepted: return "flag.fill"
        case .challengeChamp: return "flag.checkered"
        case .epicConqueror: return "mountain.2.fill"
        case .mindsetMaster: return "brain.head.profile"
        case .fitnessFreak: return "figure.run"
        case .socialButterfly: return "person.2.fill"
        case .growthGuru: return "chart.line.uptrend.xyaxis"
        case .adventurer: return "map.fill"
        case .creator: return "paintbrush.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .weekendWarrior: return "sun.max.fill"
        case .consistencyChamp: return "crown.fill"
        case .firstReachOut: return "hand.wave.fill"
        case .mentorConnection: return "graduationcap.fill"
        case .innerCircle: return "circle.hexagongrid.fill"
        case .consistentConnector: return "link.circle.fill"
        case .relationshipBuilder: return "person.3.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstStep, .actionTaker, .firstWin, .challengeAccepted:
            return Color.momentum.sage
        case .weekWarrior, .doer, .winStreak, .challengeChamp:
            return Color.momentum.gold
        case .monthlyMaster, .achiever, .bigWinner, .epicConqueror:
            return Color.momentum.coral
        case .hundredDayHero, .unstoppable, .victoryLap, .consistencyChamp:
            return Color.momentum.plum
        default:
            return Color.momentum.coral
        }
    }

    var description: String {
        switch self {
        case .firstStep: return "Complete your first action"
        case .weekWarrior: return "7-day streak"
        case .monthlyMaster: return "30-day streak"
        case .hundredDayHero: return "100-day streak"
        case .actionTaker: return "Complete 10 actions"
        case .doer: return "Complete 50 actions"
        case .achiever: return "Complete 100 actions"
        case .unstoppable: return "Complete 500 actions"
        case .firstWin: return "Log your first win"
        case .winStreak: return "Log 10 wins"
        case .bigWinner: return "Log a Big win"
        case .victoryLap: return "Log 50 wins"
        case .challengeAccepted: return "Complete first challenge"
        case .challengeChamp: return "Complete 10 challenges"
        case .epicConqueror: return "Complete an Epic challenge"
        case .mindsetMaster: return "Complete 20 mindset actions"
        case .fitnessFreak: return "Complete 20 fitness challenges"
        case .socialButterfly: return "Log 20 relationship interactions"
        case .growthGuru: return "Complete 20 growth actions"
        case .adventurer: return "Complete 10 adventure challenges"
        case .creator: return "Complete 20 creative actions"
        case .earlyBird: return "Complete an action before 7am"
        case .nightOwl: return "Complete an action after 10pm"
        case .weekendWarrior: return "Complete 5 actions on a weekend"
        case .consistencyChamp: return "Complete actions 30 days in a row"
        case .firstReachOut: return "Make your first outreach"
        case .mentorConnection: return "Log 5 interactions with mentors"
        case .innerCircle: return "Maintain 5 healthy relationships"
        case .consistentConnector: return "Weekly contact with someone for 1 month"
        case .relationshipBuilder: return "Log 50 total interactions"
        }
    }

    var xpReward: Int {
        switch self {
        case .firstStep, .firstWin, .challengeAccepted, .earlyBird, .nightOwl, .firstReachOut:
            return 100
        case .weekWarrior, .actionTaker, .winStreak:
            return 250
        case .monthlyMaster, .doer, .bigWinner, .challengeChamp, .weekendWarrior, .mentorConnection, .innerCircle:
            return 500
        case .hundredDayHero, .achiever, .victoryLap, .epicConqueror, .consistencyChamp, .consistentConnector, .relationshipBuilder:
            return 1000
        case .unstoppable:
            return 2000
        default:
            return 300
        }
    }
}

// MARK: - Gamification Manager
class GamificationManager: ObservableObject {
    static let shared = GamificationManager()

    @Published var totalXP: Int {
        didSet { UserDefaults.standard.set(totalXP, forKey: "totalXP") }
    }

    @Published var earnedBadges: Set<Badge> {
        didSet {
            let badgeStrings = earnedBadges.map { $0.rawValue }
            UserDefaults.standard.set(badgeStrings, forKey: "earnedBadges")
        }
    }

    @Published var currentStreak: Int {
        didSet { UserDefaults.standard.set(currentStreak, forKey: "currentStreak") }
    }

    @Published var lastActiveDate: Date? {
        didSet {
            if let date = lastActiveDate {
                UserDefaults.standard.set(date, forKey: "lastActiveDate")
            }
        }
    }

    @Published var showBadgeUnlock = false
    @Published var unlockedBadge: Badge?

    init() {
        self.totalXP = UserDefaults.standard.integer(forKey: "totalXP")
        self.currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        self.lastActiveDate = UserDefaults.standard.object(forKey: "lastActiveDate") as? Date

        if let badgeStrings = UserDefaults.standard.stringArray(forKey: "earnedBadges") {
            self.earnedBadges = Set(badgeStrings.compactMap { Badge(rawValue: $0) })
        } else {
            self.earnedBadges = []
        }
    }

    var currentLevel: Int {
        // Level up every 500 XP
        return (totalXP / 500) + 1
    }

    var xpToNextLevel: Int {
        let nextLevelXP = currentLevel * 500
        return nextLevelXP - totalXP
    }

    var levelProgress: Double {
        let currentLevelStart = (currentLevel - 1) * 500
        let progressInLevel = totalXP - currentLevelStart
        return Double(progressInLevel) / 500.0
    }

    var levelTitle: String {
        switch currentLevel {
        case 1...5: return "Dreamer"
        case 6...10: return "Starter"
        case 11...20: return "Mover"
        case 21...35: return "Achiever"
        case 36...50: return "Champion"
        case 51...75: return "Legend"
        default: return "Icon"
        }
    }

    func addXP(_ amount: Int) {
        let oldLevel = currentLevel
        totalXP += amount

        if currentLevel > oldLevel {
            // Level up celebration
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        }
    }

    func unlockBadge(_ badge: Badge) {
        guard !earnedBadges.contains(badge) else { return }

        earnedBadges.insert(badge)
        addXP(badge.xpReward)

        // Show badge unlock
        unlockedBadge = badge
        showBadgeUnlock = true

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }

    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastActiveDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day
                currentStreak += 1
                checkStreakBadges()
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = 1
            }
            // Same day = no change
        } else {
            currentStreak = 1
        }

        lastActiveDate = today
    }

    private func checkStreakBadges() {
        if currentStreak >= 7 { unlockBadge(.weekWarrior) }
        if currentStreak >= 30 { unlockBadge(.monthlyMaster) }
        if currentStreak >= 100 { unlockBadge(.hundredDayHero) }
        if currentStreak >= 30 { unlockBadge(.consistencyChamp) }
    }

    func checkActionBadges(totalActions: Int) {
        if totalActions >= 1 { unlockBadge(.firstStep) }
        if totalActions >= 10 { unlockBadge(.actionTaker) }
        if totalActions >= 50 { unlockBadge(.doer) }
        if totalActions >= 100 { unlockBadge(.achiever) }
        if totalActions >= 500 { unlockBadge(.unstoppable) }
    }

    func checkWinBadges(totalWins: Int, hasBigWin: Bool) {
        if totalWins >= 1 { unlockBadge(.firstWin) }
        if totalWins >= 10 { unlockBadge(.winStreak) }
        if totalWins >= 50 { unlockBadge(.victoryLap) }
        if hasBigWin { unlockBadge(.bigWinner) }
    }

    func checkTimeBadges() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 7 { unlockBadge(.earlyBird) }
        if hour >= 22 { unlockBadge(.nightOwl) }
    }

    // MARK: - Challenge Pattern Tracking

    /// Record a challenge completion and check for pattern-based badges
    func recordChallengeCompletion(challenge: Challenge, context: ModelContext) {
        // Check for category streak badges
        checkChallengeCategoryBadge(category: challenge.category)

        // Check for milestone achievements and auto-log wins
        checkChallengeMilestones(challenge: challenge, context: context)
    }

    /// Check if completing challenges in a category should unlock a badge
    private func checkChallengeCategoryBadge(category: ChallengeCategory) {
        switch category {
        case .mindset: unlockBadge(.mindsetMaster)
        case .fitness: unlockBadge(.fitnessFreak)
        case .social: unlockBadge(.socialButterfly)
        case .growth: unlockBadge(.growthGuru)
        case .adventure: unlockBadge(.adventurer)
        case .creativity: unlockBadge(.creator)
        case .wellness: break
        }
    }

    /// Check for milestone achievements and auto-log wins
    private func checkChallengeMilestones(challenge: Challenge, context: ModelContext) {
        // First epic challenge - auto-log as a big win
        if challenge.difficulty == .epic && !earnedBadges.contains(.epicConqueror) {
            autoLogWin(
                description: "Conquered my first Epic challenge: \(challenge.title)",
                size: .big,
                context: context
            )
        }
    }

    /// Auto-log a Win for milestone achievements
    private func autoLogWin(description: String, size: WinSize, context: ModelContext) {
        let win = Win(
            description: description,
            size: size,
            emotion: 5
        )
        context.insert(win)
        try? context.save()

        // Check win badges
        let allWins = (try? context.fetch(FetchDescriptor<Win>())) ?? []
        let hasBigWin = allWins.contains { $0.size == .big || $0.size == .massive }
        checkWinBadges(totalWins: allWins.count, hasBigWin: hasBigWin)
    }

    // MARK: - Relationship Achievement Tracking

    /// Called when an interaction is logged
    func recordInteraction(
        interaction: Interaction,
        relationship: Relationship,
        allRelationships: [Relationship],
        context: ModelContext
    ) {
        let totalInteractions = allRelationships.flatMap { $0.interactions }.count

        // First reach out badge
        if totalInteractions == 1 && interaction.initiatedBy == .me {
            unlockBadge(.firstReachOut)
            autoLogWin(
                description: "First reach-out to \(relationship.name)!",
                size: .small,
                context: context
            )
        }

        // Social Butterfly: 20 interactions (FIX: this was never triggered before!)
        if totalInteractions >= 20 {
            unlockBadge(.socialButterfly)
        }

        // Relationship Builder: 50 interactions
        if totalInteractions >= 50 {
            unlockBadge(.relationshipBuilder)
        }

        // Mentor Connection: 5 interactions with mentors
        let mentorInteractions = allRelationships
            .filter { $0.category == .mentor }
            .flatMap { $0.interactions }
            .count
        if mentorInteractions >= 5 {
            unlockBadge(.mentorConnection)
        }

        // Inner Circle: 5 healthy relationships
        let healthyRelationships = allRelationships.filter { $0.healthStatus == .healthy }
        if healthyRelationships.count >= 5 {
            unlockBadge(.innerCircle)
        }

        // Award XP for interaction
        addXP(15)
    }
}
