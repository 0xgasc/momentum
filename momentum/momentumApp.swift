import SwiftUI
import SwiftData

@main
struct MomentumApp: App {
    @StateObject private var purchaseService = PurchaseService()
    @StateObject private var weatherService = WeatherService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Goal.self,
            MicroAction.self,
            Win.self,
            Relationship.self,
            Interaction.self,
            Challenge.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Configure RevenueCat
        PurchaseService.configure()

        // Customize appearance
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(purchaseService)
                        .environmentObject(weatherService)
                        .toastOverlay()
                        .task {
                            await purchaseService.checkSubscriptionStatus()
                            await weatherService.fetchWeather()
                        }
                } else {
                    OnboardingFlow {
                        hasCompletedOnboarding = true
                    }
                    .toastOverlay()
                }
            }
            .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }

    private func configureAppearance() {
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.momentum.cream)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.momentum.charcoal),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.momentum.charcoal),
            .font: UIFont(name: "Georgia", size: 34) ?? UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color.momentum.white)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
