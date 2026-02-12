import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var purchaseService: PurchaseService
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var gamification = GamificationManager.shared

    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("morningReminderEnabled") private var morningReminderEnabled = true
    @AppStorage("eveningReflectionEnabled") private var eveningReflectionEnabled = false
    @AppStorage("relationshipRemindersEnabled") private var relationshipRemindersEnabled = true

    // Secret admin mode - tap version 7 times to unlock
    @State private var versionTapCount = 0
    @State private var showAdminMode = false
    @AppStorage("debug_plus_status") private var debugPlusStatus = false

    var body: some View {
        List {
            // Profile Section
            Section {
                HStack(spacing: Spacing.md) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.momentum.coral.opacity(0.15))
                            .frame(width: 60, height: 60)

                        Text(profileManager.profile.name.prefix(1).uppercased())
                            .font(.displaySmall)
                            .foregroundColor(Color.momentum.coral)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profileManager.profile.name.isEmpty ? "Set up your profile" : profileManager.profile.name)
                            .font(.titleMedium)
                            .foregroundColor(Color.momentum.charcoal)

                        HStack(spacing: Spacing.sm) {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                Text("L\(gamification.currentLevel)")
                            }
                            .foregroundColor(Color.momentum.plum)

                            Text("•")
                                .foregroundColor(Color.momentum.gray)

                            Text("\(gamification.totalXP) XP")
                                .foregroundColor(Color.momentum.gold)

                            Text("•")
                                .foregroundColor(Color.momentum.gray)

                            Text("\(gamification.earnedBadges.count) badges")
                                .foregroundColor(Color.momentum.sage)
                        }
                        .font(.caption)
                    }
                }
                .padding(.vertical, Spacing.xs)

                NavigationLink(destination: BadgesView()) {
                    HStack {
                        Image(systemName: "medal.fill")
                            .foregroundColor(Color.momentum.gold)
                        Text("View All Badges")
                    }
                }

                NavigationLink(destination: ProfileEditView()) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(Color.momentum.plum)
                        Text("Edit Profile")
                    }
                }
            } header: {
                Text("Profile")
            }

            // Subscription Section
            Section {
                if purchaseService.isPlus {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(Color.momentum.gold)
                                Text("momentum Plus")
                                    .font(.titleSmall)
                                    .foregroundColor(Color.momentum.charcoal)
                            }
                            Text("You have full access to all features")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical, Spacing.xs)
                } else {
                    Button(action: {
                        purchaseService.showPaywall = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text("Upgrade to Plus")
                                    .font(.titleSmall)
                                    .foregroundColor(Color.momentum.charcoal)
                                Text("Unlock unlimited goals, relationships & more")
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.momentum.coral)
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }
            } header: {
                Text("Subscription")
            }

            // Notifications Section
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Enable Notifications", systemImage: "bell.fill")
                }
                .tint(Color.momentum.coral)

                if notificationsEnabled {
                    Toggle(isOn: $morningReminderEnabled) {
                        VStack(alignment: .leading) {
                            Text("Morning Motivation")
                            Text("Daily affirmation at 8 AM")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }
                    }
                    .tint(Color.momentum.coral)

                    Toggle(isOn: $eveningReflectionEnabled) {
                        VStack(alignment: .leading) {
                            Text("Evening Reflection")
                            Text("Log your wins at 8 PM")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }
                    }
                    .tint(Color.momentum.coral)

                    Toggle(isOn: $relationshipRemindersEnabled) {
                        VStack(alignment: .leading) {
                            Text("Relationship Nudges")
                            Text("Remind you to reach out")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }
                    }
                    .tint(Color.momentum.coral)
                }
            } header: {
                Text("Notifications")
            }

            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(Color.momentum.gray)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    versionTapCount += 1
                    if versionTapCount >= 7 {
                        showAdminMode = true
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()
                    }
                }

                Link(destination: URL(string: "https://momentum.app/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color.momentum.gray)
                    }
                }
                .foregroundColor(Color.momentum.charcoal)

                Link(destination: URL(string: "https://momentum.app/terms")!) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color.momentum.gray)
                    }
                }
                .foregroundColor(Color.momentum.charcoal)

                Button(action: {
                    purchaseService.restorePurchases()
                }) {
                    Text("Restore Purchases")
                }

            } header: {
                Text("About")
            }

            // Secret Admin Section (only visible after tapping version 7 times)
            if showAdminMode {
                Section {
                    Toggle(isOn: $debugPlusStatus) {
                        HStack {
                            Image(systemName: "hammer.fill")
                                .foregroundColor(Color.momentum.plum)
                            VStack(alignment: .leading) {
                                Text("Debug Plus Status")
                                Text("Override subscription for testing")
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)
                            }
                        }
                    }
                    .tint(Color.momentum.coral)
                    .onChange(of: debugPlusStatus) { _, newValue in
                        purchaseService.debugOverridePlus = newValue
                    }

                    Button(role: .destructive) {
                        showAdminMode = false
                        versionTapCount = 0
                    } label: {
                        HStack {
                            Image(systemName: "eye.slash.fill")
                            Text("Hide Admin Mode")
                        }
                    }
                } header: {
                    Text("🔧 Admin")
                } footer: {
                    Text("These settings are for development and demo purposes only.")
                }
            }

            // Footer
            Section {
                VStack(spacing: Spacing.sm) {
                    Text(AppName.full)
                        .font(.displaySmall)
                        .foregroundColor(Color.momentum.charcoal)

                    Text("Built with love for ambitious dreamers")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $purchaseService.showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Paywall View
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseService: PurchaseService

    @State private var selectedPlan: PurchasePlan = .yearly
    @State private var isPurchasing = false

    enum PurchasePlan {
        case monthly
        case yearly
        case lifetime
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.momentum.gold)

                        Text("Unlock Your Full Potential")
                            .font(.displayMedium)
                            .foregroundColor(Color.momentum.charcoal)
                            .multilineTextAlignment(.center)

                        Text("Get unlimited access to all features")
                            .font(.bodyMedium)
                            .foregroundColor(Color.momentum.gray)
                    }
                    .padding(.top, Spacing.xl)

                    // Features
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        FeatureRow(icon: "target", title: "Unlimited Goals", description: "Track as many dreams as you have")
                        FeatureRow(icon: "person.2.fill", title: "Unlimited Relationships", description: "Nurture your entire network")
                        FeatureRow(icon: "arrow.clockwise", title: "Unlimited Affirmation Refreshes", description: "Fresh inspiration whenever you need it")
                        FeatureRow(icon: "sparkles", title: "Premium Celebrations", description: "Extra special confetti for big wins")
                    }
                    .padding(Spacing.lg)
                    .background(Color.momentum.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                    .momentumShadow()

                    // Plan Selection
                    VStack(spacing: Spacing.md) {
                        PlanCard(
                            title: "Lifetime",
                            price: "$149.99",
                            subtitle: "Pay once, own forever",
                            isSelected: selectedPlan == .lifetime,
                            isBestValue: true
                        ) {
                            selectedPlan = .lifetime
                        }

                        PlanCard(
                            title: "Yearly",
                            price: "$59.99/year",
                            subtitle: "Save 37%",
                            isSelected: selectedPlan == .yearly,
                            isBestValue: false
                        ) {
                            selectedPlan = .yearly
                        }

                        PlanCard(
                            title: "Monthly",
                            price: "$7.99/month",
                            subtitle: "Cancel anytime",
                            isSelected: selectedPlan == .monthly,
                            isBestValue: false
                        ) {
                            selectedPlan = .monthly
                        }
                    }

                    // Purchase Button
                    VStack(spacing: Spacing.sm) {
                        MomentumButton(selectedPlan == .lifetime ? "Buy Lifetime Access" : "Start Free Trial", icon: "sparkles") {
                            purchase()
                        }
                        .disabled(isPurchasing)

                        if selectedPlan == .lifetime {
                            Text("One-time purchase — no subscription")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        } else {
                            Text("7-day free trial, then \(selectedPlan == .yearly ? "$59.99/year" : "$7.99/month")")
                                .font(.caption)
                                .foregroundColor(Color.momentum.gray)
                        }
                    }

                    // Legal
                    VStack(spacing: Spacing.xs) {
                        Text(selectedPlan == .lifetime ? "One-time purchase. No recurring charges." : "Cancel anytime. Subscriptions auto-renew.")
                            .font(.caption)
                            .foregroundColor(Color.momentum.gray)

                        HStack(spacing: Spacing.md) {
                            Link("Privacy", destination: URL(string: "https://momentum.app/privacy")!)
                            Text("•")
                            Link("Terms", destination: URL(string: "https://momentum.app/terms")!)
                            Text("•")
                            Button("Restore") {
                                purchaseService.restorePurchases()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                    }
                    .padding(.bottom, Spacing.xl)
                }
                .padding(.horizontal, Spacing.lg)
            }
            .background(Color.momentum.cream.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color.momentum.gray.opacity(0.5))
                    }
                }
            }
        }
    }

    private func purchase() {
        isPurchasing = true
        Task {
            let plan: PurchaseService.PurchasePlan
            switch selectedPlan {
            case .lifetime: plan = .lifetime
            case .yearly: plan = .yearly
            case .monthly: plan = .monthly
            }
            await purchaseService.purchase(plan: plan)
            isPurchasing = false
            if purchaseService.isPlus {
                dismiss()
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.momentum.coral)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.titleSmall)
                    .foregroundColor(Color.momentum.charcoal)
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.momentum.gray)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.momentum.sage)
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let title: String
    let price: String
    let subtitle: String
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xs) {
                        Text(title)
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)

                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.momentum.coral)
                                .clipShape(Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                }

                Spacer()

                Text(price)
                    .font(.titleSmall)
                    .foregroundColor(Color.momentum.charcoal)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.momentum.coral : Color.momentum.gray)
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.momentum.coral.opacity(0.1) : Color.momentum.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(isSelected ? Color.momentum.coral : Color.momentum.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(PurchaseService())
    }
}
