import SwiftUI
import Combine

// MARK: - User Profile
struct UserProfile: Codable {
    var name: String = ""
    var identity: Identity = .preferNotToSay
    var motivationStyle: MotivationStyle = .balanced
    var focusAreas: Set<GoalCategory> = []
    var weatherMode: WeatherMode = .manual // Default to private
    var manualWeather: WeatherCondition? = nil
    var hasCompletedOnboarding: Bool = false

    enum WeatherMode: String, Codable, CaseIterable, Identifiable {
        case auto = "Auto (Location)"
        case manual = "Set My Vibe"
        case off = "Off"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .auto: return "location.fill"
            case .manual: return "sun.max.fill"
            case .off: return "eye.slash.fill"
            }
        }

        var description: String {
            switch self {
            case .auto: return "Uses your location for real-time weather suggestions"
            case .manual: return "Pick your weather vibe - no location needed"
            case .off: return "Hide weather suggestions entirely"
            }
        }
    }

    enum Identity: String, Codable, CaseIterable, Identifiable {
        case woman = "Woman"
        case man = "Man"
        case nonBinary = "Non-binary"
        case genderfluid = "Genderfluid"
        case other = "Other"
        case preferNotToSay = "Prefer not to say"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .woman: return "figure.stand.dress"
            case .man: return "figure.stand"
            case .nonBinary: return "figure.wave"
            case .genderfluid: return "sparkles"
            case .other: return "star.fill"
            case .preferNotToSay: return "person.fill"
            }
        }
    }

    enum MotivationStyle: String, Codable, CaseIterable, Identifiable {
        case gentle = "Gentle & Supportive"
        case balanced = "Balanced"
        case intense = "Bold & Direct"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .gentle: return "Soft encouragement, self-compassion focused"
            case .balanced: return "Mix of support and accountability"
            case .intense: return "Main character energy, no excuses vibes"
            }
        }

        var icon: String {
            switch self {
            case .gentle: return "heart.fill"
            case .balanced: return "scale.3d"
            case .intense: return "flame.fill"
            }
        }
    }
}

// MARK: - User Profile Manager
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()

    @Published var profile: UserProfile {
        didSet { save() }
    }

    private let key = "userProfile"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = profile
        } else {
            self.profile = UserProfile()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    var needsOnboarding: Bool {
        !profile.hasCompletedOnboarding
    }

    func completeOnboarding() {
        profile.hasCompletedOnboarding = true
    }
}

// MARK: - Onboarding Flow
struct OnboardingFlow: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var currentStep = 0
    @State private var name = ""
    @State private var identity: UserProfile.Identity = .preferNotToSay
    @State private var motivationStyle: UserProfile.MotivationStyle = .balanced
    @State private var focusAreas: Set<GoalCategory> = []
    @State private var weatherMode: UserProfile.WeatherMode = .manual
    @State private var manualWeather: WeatherCondition? = .clear

    let onComplete: () -> Void

    private let totalSteps = 5

    var body: some View {
        ZStack {
            Color.momentum.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: Spacing.xs) {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        Capsule()
                            .fill(step <= currentStep ? Color.momentum.coral : Color.momentum.gray.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)

                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep(name: $name)
                        .tag(0)

                    IdentityStep(identity: $identity)
                        .tag(1)

                    MotivationStep(style: $motivationStyle)
                        .tag(2)

                    FocusAreasStep(focusAreas: $focusAreas)
                        .tag(3)

                    WeatherVibeStep(weatherMode: $weatherMode, manualWeather: $manualWeather)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // Navigation
                HStack {
                    if currentStep > 0 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.bodyMedium)
                            .foregroundColor(Color.momentum.gray)
                        }
                    }

                    Spacer()

                    Button {
                        if currentStep < totalSteps - 1 {
                            withAnimation { currentStep += 1 }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Text(currentStep == totalSteps - 1 ? "Let's Go!" : "Continue")
                            Image(systemName: currentStep == totalSteps - 1 ? "sparkles" : "chevron.right")
                        }
                        .font(.titleSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(canContinue ? Color.momentum.coral : Color.momentum.gray)
                        .clipShape(Capsule())
                    }
                    .disabled(!canContinue)
                }
                .padding(Spacing.xl)
            }
        }
    }

    private var canContinue: Bool {
        switch currentStep {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return true // Identity is optional
        case 2: return true // Motivation style has default
        case 3: return !focusAreas.isEmpty
        case 4: return true // Weather has defaults
        default: return true
        }
    }

    private func completeOnboarding() {
        profileManager.profile.name = name
        profileManager.profile.identity = identity
        profileManager.profile.motivationStyle = motivationStyle
        profileManager.profile.focusAreas = focusAreas
        profileManager.profile.weatherMode = weatherMode
        profileManager.profile.manualWeather = manualWeather
        profileManager.completeOnboarding()

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        onComplete()
    }
}

// MARK: - Step 1: Welcome
struct WelcomeStep: View {
    @Binding var name: String

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Text("Welcome to")
                    .font(.titleLarge)
                    .foregroundColor(Color.momentum.gray)

                Text("momentum")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Color.momentum.coral)

                Text("Your journey to becoming who you're meant to be starts here.")
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("What should we call you?")
                    .font(.titleSmall)
                    .foregroundColor(Color.momentum.charcoal)

                TextField("Your name", text: $name)
                    .font(.titleMedium)
                    .foregroundColor(Color.momentum.charcoal)
                    .padding(Spacing.md)
                    .background(Color.momentum.white)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                    .momentumShadow(radius: 4)
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
    }
}

// MARK: - Step 2: Identity
struct IdentityStep: View {
    @Binding var identity: UserProfile.Identity

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(Color.momentum.plum)

                Text("How do you identify?")
                    .font(.displaySmall)
                    .foregroundColor(Color.momentum.charcoal)

                Text("This helps us personalize your experience. You can skip this if you prefer.")
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(UserProfile.Identity.allCases) { option in
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        identity = option
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: option.icon)
                                .font(.system(size: 20))
                            Text(option.rawValue)
                                .font(.bodyMedium)
                        }
                        .foregroundColor(identity == option ? .white : Color.momentum.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md)
                        .background(identity == option ? Color.momentum.plum : Color.momentum.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        .momentumShadow(radius: identity == option ? 0 : 4)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
    }
}

// MARK: - Step 3: Motivation Style
struct MotivationStep: View {
    @Binding var style: UserProfile.MotivationStyle

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(Color.momentum.gold)

                Text("What's your vibe?")
                    .font(.displaySmall)
                    .foregroundColor(Color.momentum.charcoal)

                Text("How do you like to be motivated?")
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
            }

            Spacer()

            VStack(spacing: Spacing.md) {
                ForEach(UserProfile.MotivationStyle.allCases) { option in
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        style = option
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: option.icon)
                                .font(.system(size: 24))
                                .foregroundColor(style == option ? .white : Color.momentum.coral)
                                .frame(width: 44, height: 44)
                                .background(style == option ? Color.momentum.coral : Color.momentum.coral.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.rawValue)
                                    .font(.titleSmall)
                                    .foregroundColor(Color.momentum.charcoal)
                                Text(option.description)
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)
                            }

                            Spacer()

                            if style == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.momentum.coral)
                            }
                        }
                        .padding(Spacing.md)
                        .background(Color.momentum.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .stroke(style == option ? Color.momentum.coral : Color.clear, lineWidth: 2)
                        )
                        .momentumShadow(radius: 4)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
    }
}

// MARK: - Step 4: Focus Areas
struct FocusAreasStep: View {
    @Binding var focusAreas: Set<GoalCategory>

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundColor(Color.momentum.sage)

                Text("What are you focused on?")
                    .font(.displaySmall)
                    .foregroundColor(Color.momentum.charcoal)

                Text("Select all that apply. You can always change this later.")
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                ForEach(GoalCategory.userFacing, id: \.self) { category in
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        if focusAreas.contains(category) {
                            focusAreas.remove(category)
                        } else {
                            focusAreas.insert(category)
                        }
                    } label: {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: category.icon)
                                .font(.system(size: 28))
                            Text(category.displayName)
                                .font(.bodySmall)
                        }
                        .foregroundColor(focusAreas.contains(category) ? .white : category.color)
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md)
                        .background(focusAreas.contains(category) ? category.color : category.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .stroke(focusAreas.contains(category) ? Color.clear : category.color.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)

            if !focusAreas.isEmpty {
                Text("\(focusAreas.count) area\(focusAreas.count == 1 ? "" : "s") selected")
                    .font(.caption)
                    .foregroundColor(Color.momentum.sage)
            }

            Spacer()
        }
    }
}

// MARK: - Step 5: Weather Vibe
struct WeatherVibeStep: View {
    @Binding var weatherMode: UserProfile.WeatherMode
    @Binding var manualWeather: WeatherCondition?

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.momentum.gold, Color.momentum.coral],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("What's your weather vibe?")
                    .font(.displaySmall)
                    .foregroundColor(Color.momentum.charcoal)

                Text("Control your experience. No location tracking required.")
                    .font(.bodyMedium)
                    .foregroundColor(Color.momentum.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()

            // Weather mode selection
            VStack(spacing: Spacing.md) {
                ForEach(UserProfile.WeatherMode.allCases) { mode in
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        weatherMode = mode
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 24))
                                .foregroundColor(weatherMode == mode ? .white : Color.momentum.coral)
                                .frame(width: 44, height: 44)
                                .background(weatherMode == mode ? Color.momentum.coral : Color.momentum.coral.opacity(0.1))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.rawValue)
                                    .font(.titleSmall)
                                    .foregroundColor(Color.momentum.charcoal)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)
                            }

                            Spacer()

                            if weatherMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.momentum.coral)
                            }
                        }
                        .padding(Spacing.md)
                        .background(Color.momentum.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .stroke(weatherMode == mode ? Color.momentum.coral : Color.clear, lineWidth: 2)
                        )
                        .momentumShadow(radius: 4)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)

            // Manual weather picker (only when "Set My Vibe" is selected)
            if weatherMode == .manual {
                VStack(spacing: Spacing.sm) {
                    Text("Pick your vibe:")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Spacing.sm) {
                        ForEach(WeatherCondition.allCases, id: \.self) { condition in
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                manualWeather = condition
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: condition.icon)
                                        .font(.system(size: 22))
                                    Text(condition.displayName)
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(manualWeather == condition ? .white : Color.momentum.charcoal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background(manualWeather == condition ? Color.momentum.coral : Color.momentum.white)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.small)
                                        .stroke(manualWeather == condition ? Color.clear : Color.momentum.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Context note
            if weatherMode == .auto {
                Text("We'll ask for location permission on your first day")
                    .font(.caption)
                    .foregroundColor(Color.momentum.sage)
                    .transition(.opacity)
            } else if weatherMode == .off {
                Text("You can always turn this on later in Settings")
                    .font(.caption)
                    .foregroundColor(Color.momentum.gray)
                    .transition(.opacity)
            }

            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: weatherMode)
    }
}

#Preview {
    OnboardingFlow(onComplete: {})
}
