import Foundation
import SwiftUI
import Combine
import RevenueCat

// MARK: - Purchase Service
@MainActor
class PurchaseService: ObservableObject {
    // MARK: - Published Properties
    @Published var isPlus: Bool = false
    @Published var showPaywall: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - RevenueCat Configuration
    // TODO: Replace with your REAL RevenueCat API key from dashboard (starts with appl_)
    private static let apiKey = "appl_xynOQxQbwmXMjOTcbdMTzahrtuU"
    private static let entitlementID = "plus"

    // Check if RevenueCat is properly configured
    private static var isConfigured: Bool {
        !apiKey.contains("YOUR_REAL_API_KEY") && !apiKey.isEmpty
    }

    // Product IDs - must match App Store Connect exactly
    enum ProductID: String {
        case monthly = "io.momentum.goaltracker.plus.monthly"
        case yearly = "io.momentum.goaltracker.plus.yearly"
        case lifetime = "io.momentum.goaltracker.plus.lifetime"
    }

    // MARK: - Initialization
    init() {
        // Load cached status for immediate UI
        #if DEBUG
        if !Self.isConfigured {
            isPlus = UserDefaults.standard.bool(forKey: "debug_plus_status")
        }
        #endif
    }

    // MARK: - Configure RevenueCat
    static func configure() {
        guard isConfigured else {
            print("⚠️ RevenueCat not configured. Using debug mode.")
            print("   To enable purchases, replace YOUR_REVENUECAT_API_KEY in PurchaseService.swift")
            return
        }

        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        print("✅ RevenueCat configured successfully")
    }

    // MARK: - Check Subscription Status
    func checkSubscriptionStatus() async {
        guard Self.isConfigured else {
            #if DEBUG
            isPlus = UserDefaults.standard.bool(forKey: "debug_plus_status")
            #endif
            return
        }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPlus = customerInfo.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            print("Error fetching customer info: \(error)")
            // Keep existing status on error
        }
    }

    // MARK: - Purchase
    enum PurchasePlan {
        case monthly
        case yearly
        case lifetime

        var productID: ProductID {
            switch self {
            case .monthly: return .monthly
            case .yearly: return .yearly
            case .lifetime: return .lifetime
            }
        }
    }

    func purchase(plan: PurchasePlan) async {
        isLoading = true
        errorMessage = nil

        guard Self.isConfigured else {
            #if DEBUG
            // Simulate purchase in debug mode
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isPlus = true
            UserDefaults.standard.set(true, forKey: "debug_plus_status")
            isLoading = false
            #else
            errorMessage = "Purchases not configured"
            isLoading = false
            #endif
            return
        }

        do {
            let products = await Purchases.shared.products([plan.productID.rawValue])
            guard let product = products.first else {
                errorMessage = "Product not found"
                isLoading = false
                return
            }

            let result = try await Purchases.shared.purchase(product: product)

            if !result.userCancelled {
                isPlus = result.customerInfo.entitlements[Self.entitlementID]?.isActive == true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Restore Purchases
    func restorePurchases() {
        isLoading = true
        errorMessage = nil

        guard Self.isConfigured else {
            #if DEBUG
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                isPlus = UserDefaults.standard.bool(forKey: "debug_plus_status")
                if !isPlus {
                    errorMessage = "No subscription found (debug mode)"
                }
                isLoading = false
            }
            #else
            errorMessage = "Purchases not configured"
            isLoading = false
            #endif
            return
        }

        Task {
            do {
                let customerInfo = try await Purchases.shared.restorePurchases()
                isPlus = customerInfo.entitlements[Self.entitlementID]?.isActive == true

                if !isPlus {
                    errorMessage = "No active subscription found"
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Debug Helpers
    /// Debug override for Plus status - used by secret admin toggle in Settings
    var debugOverridePlus: Bool {
        get {
            UserDefaults.standard.bool(forKey: "debug_plus_status")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "debug_plus_status")
            isPlus = newValue
        }
    }

    #if DEBUG
    func togglePlusForTesting() {
        isPlus.toggle()
        UserDefaults.standard.set(isPlus, forKey: "debug_plus_status")
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
    #endif
}

// MARK: - Free Tier Limits
struct FreeTierLimits {
    static let maxGoals = 3
    static let maxRelationships = 5
    static let maxDailyAffirmationRefreshes = 3
}

// MARK: - Entitlement Check Extension
extension PurchaseService {
    func canAddGoal(currentCount: Int) -> Bool {
        isPlus || currentCount < FreeTierLimits.maxGoals
    }

    func canAddRelationship(currentCount: Int) -> Bool {
        isPlus || currentCount < FreeTierLimits.maxRelationships
    }

    func canRefreshAffirmation(todayCount: Int) -> Bool {
        isPlus || todayCount < FreeTierLimits.maxDailyAffirmationRefreshes
    }
}
