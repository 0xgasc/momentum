import SwiftUI

struct ProfileEditView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var identity: UserProfile.Identity = .preferNotToSay
    @State private var motivationStyle: UserProfile.MotivationStyle = .balanced
    @State private var focusAreas: Set<GoalCategory> = []
    @State private var weatherMode: UserProfile.WeatherMode = .manual
    @State private var manualWeather: WeatherCondition? = nil

    var body: some View {
        List {
            // Name
            Section {
                TextField("Your name", text: $name)
                    .font(.bodyMedium)
            } header: {
                Text("Name")
            }

            // Identity
            Section {
                ForEach(UserProfile.Identity.allCases) { option in
                    Button {
                        identity = option
                    } label: {
                        HStack {
                            Image(systemName: option.icon)
                                .foregroundColor(Color.momentum.plum)
                                .frame(width: 28)

                            Text(option.rawValue)
                                .foregroundColor(Color.momentum.charcoal)

                            Spacer()

                            if identity == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.momentum.coral)
                            }
                        }
                    }
                }
            } header: {
                Text("Identity")
            } footer: {
                Text("This helps personalize your experience")
            }

            // Motivation Style
            Section {
                ForEach(UserProfile.MotivationStyle.allCases) { style in
                    Button {
                        motivationStyle = style
                    } label: {
                        HStack {
                            Image(systemName: style.icon)
                                .foregroundColor(Color.momentum.coral)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.rawValue)
                                    .foregroundColor(Color.momentum.charcoal)
                                Text(style.description)
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)
                            }

                            Spacer()

                            if motivationStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.momentum.coral)
                            }
                        }
                    }
                }
            } header: {
                Text("Motivation Style")
            } footer: {
                Text("Changes the tone of affirmations and messages")
            }

            // Focus Areas
            Section {
                ForEach(GoalCategory.userFacing, id: \.self) { category in
                    Button {
                        if focusAreas.contains(category) {
                            focusAreas.remove(category)
                        } else {
                            focusAreas.insert(category)
                        }
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                                .frame(width: 28)

                            Text(category.displayName)
                                .foregroundColor(Color.momentum.charcoal)

                            Spacer()

                            if focusAreas.contains(category) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.momentum.sage)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(Color.momentum.gray.opacity(0.3))
                            }
                        }
                    }
                }
            } header: {
                Text("Focus Areas")
            } footer: {
                Text("Select areas that matter most to you")
            }

            // Weather & Suggestions
            Section {
                ForEach(UserProfile.WeatherMode.allCases) { mode in
                    Button {
                        weatherMode = mode
                    } label: {
                        HStack {
                            Image(systemName: mode.icon)
                                .foregroundColor(Color.momentum.coral)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.rawValue)
                                    .foregroundColor(Color.momentum.charcoal)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(Color.momentum.gray)
                            }

                            Spacer()

                            if weatherMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.momentum.coral)
                            }
                        }
                    }
                }

                if weatherMode == .manual {
                    Picker("Your Weather Vibe", selection: $manualWeather) {
                        ForEach(WeatherCondition.allCases, id: \.self) { condition in
                            Label(condition.displayName, systemImage: condition.icon)
                                .tag(condition as WeatherCondition?)
                        }
                    }
                    .tint(Color.momentum.coral)
                }
            } header: {
                Text("Weather & Suggestions")
            } footer: {
                Text(weatherMode == .auto
                    ? "Location is only used to check weather, never stored"
                    : weatherMode == .manual
                    ? "Change anytime to match your current vibe"
                    : "Weather suggestions will be hidden from your dashboard")
            }

            // Reset Onboarding
            Section {
                Button(role: .destructive) {
                    resetOnboarding()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Restart Onboarding")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.momentum.cream.ignoresSafeArea())
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveProfile()
                }
            }
        }
        .onAppear {
            loadProfile()
        }
    }

    private func loadProfile() {
        name = profileManager.profile.name
        identity = profileManager.profile.identity
        motivationStyle = profileManager.profile.motivationStyle
        focusAreas = profileManager.profile.focusAreas
        weatherMode = profileManager.profile.weatherMode
        manualWeather = profileManager.profile.manualWeather
    }

    private func saveProfile() {
        profileManager.profile.name = name
        profileManager.profile.identity = identity
        profileManager.profile.motivationStyle = motivationStyle
        profileManager.profile.focusAreas = focusAreas
        profileManager.profile.weatherMode = weatherMode
        profileManager.profile.manualWeather = manualWeather
        profileManager.save()

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        ToastManager.shared.show("Profile saved!", icon: "checkmark.circle.fill")

        dismiss()
    }

    private func resetOnboarding() {
        profileManager.profile.hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.warning)
    }
}

#Preview {
    NavigationStack {
        ProfileEditView()
    }
}
