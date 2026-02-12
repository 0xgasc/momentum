import Foundation
import CloudKit
import SwiftUI
import Combine

/// Manages all CloudKit operations for community features
@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()

    // CloudKit container and database - lazy to avoid crash when entitlement is missing
    private lazy var container: CKContainer? = {
        // Only initialize if CloudKit is available
        guard isCloudKitAvailable else { return nil }
        return CKContainer(identifier: "iCloud.io.momentum.goaltracker")
    }()

    private var publicDatabase: CKDatabase? { container?.publicCloudDatabase }

    // Check if CloudKit entitlement exists
    private var isCloudKitAvailable: Bool {
        // Check if we can access the default container without crashing
        let fileManager = FileManager.default
        return fileManager.url(forUbiquityContainerIdentifier: nil) != nil
    }

    // Published community stats - start with mock data for immediate display
    @Published var activeUsersCount: Int = 247
    @Published var winsToday: Int = 52
    @Published var streakUsersCount: Int = 34
    @Published var recentCommunityWins: [CommunityWin] = CommunityWin.mockWins
    @Published var isLoading = false
    @Published var hasError = false

    // Device ID for unique user tracking
    private var deviceID: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    private init() {
        // Don't auto-fetch on init - let views trigger refresh via onAppear
        // This prevents blocking during app launch
    }

    // MARK: - Public Methods

    /// Share a win to the community
    func shareWin(
        description: String,
        size: WinSize,
        emotion: Int,
        displayName: String?,
        isAnonymous: Bool
    ) async throws {
        guard let database = publicDatabase else {
            // CloudKit not available - just update local stats for demo
            winsToday += 1
            return
        }

        let record = CKRecord(recordType: "CommunityWin")
        record["winDescription"] = description
        record["size"] = size.rawValue
        record["emotion"] = emotion
        record["displayName"] = isAnonymous ? nil : displayName
        record["isAnonymous"] = isAnonymous
        record["createdAt"] = Date()
        record["deviceID"] = deviceID

        try await database.save(record)

        // Update local stats
        winsToday += 1

        // Refresh wins list
        await fetchRecentWins()
    }

    /// Share a goal milestone to the community
    func shareMilestone(
        goalTitle: String,
        milestone: Double,
        message: String?,
        displayName: String?,
        isAnonymous: Bool
    ) async throws {
        guard let database = publicDatabase else {
            // CloudKit not available - just update local stats for demo
            winsToday += 1
            return
        }

        let record = CKRecord(recordType: "CommunityMilestone")
        record["goalTitle"] = goalTitle
        record["milestone"] = Int(milestone * 100)
        record["message"] = message
        record["displayName"] = isAnonymous ? nil : displayName
        record["isAnonymous"] = isAnonymous
        record["createdAt"] = Date()
        record["deviceID"] = deviceID

        try await database.save(record)
    }

    /// Share a streak achievement to the community
    func shareStreak(
        days: Int,
        message: String?,
        displayName: String?,
        isAnonymous: Bool
    ) async throws {
        guard let database = publicDatabase else {
            // CloudKit not available - silently succeed
            return
        }

        let record = CKRecord(recordType: "CommunityStreak")
        record["days"] = days
        record["message"] = message
        record["displayName"] = isAnonymous ? nil : displayName
        record["isAnonymous"] = isAnonymous
        record["createdAt"] = Date()
        record["deviceID"] = deviceID

        try await database.save(record)
    }

    /// Share a daily summary to the community
    func shareDailySummary(
        actions: Int,
        wins: Int,
        streak: Int,
        message: String?,
        displayName: String?,
        isAnonymous: Bool
    ) async throws {
        guard let database = publicDatabase else {
            // CloudKit not available - silently succeed
            return
        }

        let record = CKRecord(recordType: "CommunitySummary")
        record["actions"] = actions
        record["wins"] = wins
        record["streak"] = streak
        record["message"] = message
        record["displayName"] = isAnonymous ? nil : displayName
        record["isAnonymous"] = isAnonymous
        record["createdAt"] = Date()
        record["deviceID"] = deviceID

        try await database.save(record)
    }

    /// Celebrate someone's win
    func celebrateWin(winId: String) async {
        guard let database = publicDatabase else {
            // CloudKit not available - silently skip
            return
        }

        let record = CKRecord(recordType: "Celebration")
        record["winId"] = winId
        record["deviceID"] = deviceID
        record["createdAt"] = Date()

        do {
            try await database.save(record)
        } catch {
            print("Failed to save celebration: \(error)")
        }
    }

    /// Register this device as active (call on app launch)
    func registerActiveUser(hasStreak: Bool) async {
        guard let database = publicDatabase else {
            // CloudKit not available - silently skip
            return
        }

        let record = CKRecord(recordType: "ActiveUser")
        record["deviceID"] = deviceID
        record["lastActive"] = Date()
        record["hasStreak"] = hasStreak

        do {
            try await database.save(record)
        } catch {
            // Silently fail - not critical
            print("Failed to register active user: \(error)")
        }
    }

    /// Refresh community statistics
    func refreshCommunityStats() async {
        guard let database = publicDatabase else {
            // CloudKit not available - keep mock data
            isLoading = false
            return
        }

        isLoading = true
        hasError = false

        do {
            // Count wins today
            let todayStart = Calendar.current.startOfDay(for: Date())
            let winsPredicate = NSPredicate(format: "createdAt >= %@", todayStart as NSDate)
            let winsQuery = CKQuery(recordType: "CommunityWin", predicate: winsPredicate)

            let winsResults = try await database.records(matching: winsQuery)
            winsToday = winsResults.matchResults.count

            // Count active users (active in last 24 hours)
            let yesterday = Date().addingTimeInterval(-86400)
            let activePredicate = NSPredicate(format: "lastActive >= %@", yesterday as NSDate)
            let activeQuery = CKQuery(recordType: "ActiveUser", predicate: activePredicate)

            let activeResults = try await database.records(matching: activeQuery)
            activeUsersCount = activeResults.matchResults.count

            // Count streak users
            let streakPredicate = NSPredicate(format: "hasStreak == YES AND lastActive >= %@", yesterday as NSDate)
            let streakQuery = CKQuery(recordType: "ActiveUser", predicate: streakPredicate)

            let streakResults = try await database.records(matching: streakQuery)
            streakUsersCount = streakResults.matchResults.count

        } catch {
            hasError = true
            print("Failed to fetch community stats: \(error)")

            // Use fallback mock data for demo
            activeUsersCount = 247
            winsToday = 52
            streakUsersCount = 34
        }

        isLoading = false
    }

    /// Fetch recent community wins for the feed
    func fetchRecentWins(limit: Int = 50) async {
        guard let database = publicDatabase else {
            // CloudKit not available - keep mock data
            return
        }

        do {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: "CommunityWin", predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            let results = try await database.records(matching: query, resultsLimit: limit)

            var wins: [CommunityWin] = []
            for (_, result) in results.matchResults {
                if let record = try? result.get() {
                    let win = CommunityWin(record: record)
                    wins.append(win)
                }
            }

            recentCommunityWins = wins

        } catch {
            print("Failed to fetch community wins: \(error)")

            // Use mock data for demo
            recentCommunityWins = CommunityWin.mockWins
        }
    }
}

// MARK: - CommunityWin Model

struct CommunityWin: Identifiable {
    let id: String
    let winDescription: String
    let size: WinSize
    let emotion: Int
    let displayName: String?
    let isAnonymous: Bool
    let createdAt: Date

    init(record: CKRecord) {
        self.id = record.recordID.recordName
        self.winDescription = record["winDescription"] as? String ?? ""
        self.size = WinSize(rawValue: record["size"] as? String ?? "small") ?? .small
        self.emotion = record["emotion"] as? Int ?? 3
        self.displayName = record["displayName"] as? String
        self.isAnonymous = record["isAnonymous"] as? Bool ?? true
        self.createdAt = record["createdAt"] as? Date ?? Date()
    }

    // Mock initializer for demo
    init(id: String, description: String, size: WinSize, emotion: Int, displayName: String?, isAnonymous: Bool, createdAt: Date) {
        self.id = id
        self.winDescription = description
        self.size = size
        self.emotion = emotion
        self.displayName = displayName
        self.isAnonymous = isAnonymous
        self.createdAt = createdAt
    }

    var displayNameOrAnonymous: String {
        if isAnonymous || displayName == nil {
            return "Someone"
        }
        return displayName!
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    var sizeEmoji: String {
        switch size {
        case .tiny: return "✨"
        case .small: return "🌟"
        case .medium: return "⭐️"
        case .big: return "🏆"
        case .massive: return "👑"
        }
    }

    // Mock data for demo/fallback
    static var mockWins: [CommunityWin] {
        [
            CommunityWin(id: "1", description: "Finished my first prototype!", size: .big, emotion: 5, displayName: "Sarah", isAnonymous: false, createdAt: Date().addingTimeInterval(-300)),
            CommunityWin(id: "2", description: "Meditated for 10 minutes", size: .small, emotion: 4, displayName: nil, isAnonymous: true, createdAt: Date().addingTimeInterval(-1800)),
            CommunityWin(id: "3", description: "Had a great workout", size: .medium, emotion: 5, displayName: "Maya", isAnonymous: false, createdAt: Date().addingTimeInterval(-3600)),
            CommunityWin(id: "4", description: "Completed my reading goal", size: .small, emotion: 4, displayName: nil, isAnonymous: true, createdAt: Date().addingTimeInterval(-7200)),
            CommunityWin(id: "5", description: "Got the job offer!", size: .massive, emotion: 5, displayName: "Jade", isAnonymous: false, createdAt: Date().addingTimeInterval(-14400)),
            CommunityWin(id: "6", description: "Reached out to my mentor", size: .small, emotion: 3, displayName: nil, isAnonymous: true, createdAt: Date().addingTimeInterval(-21600)),
            CommunityWin(id: "7", description: "Launched my side project", size: .big, emotion: 5, displayName: "Tasha", isAnonymous: false, createdAt: Date().addingTimeInterval(-43200)),
        ]
    }
}
