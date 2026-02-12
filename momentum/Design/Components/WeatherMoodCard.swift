import SwiftUI

// MARK: - Weather Mood Card
struct WeatherSuggestionsCard: View {
    let weather: WeatherCondition
    var addedSuggestions: Set<String> = []
    let onAddAction: (ActionTemplate) -> Void
    let onAddChallenge: (ActionTemplate) -> Void
    var onChangeWeather: ((WeatherCondition) -> Void)? = nil

    @State private var isExpanded = false
    @State private var showVibePicker = false

    private var moodData: WeatherMood {
        WeatherMood.personalizedMood(for: weather) // Uses user's focus areas
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with weather mood
            Button {
                withAnimation(.spring(response: 0.4)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    // Weather icon - tappable to change vibe
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        showVibePicker = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: moodData.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)

                            Image(systemName: weather.icon)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(moodData.greeting)
                            .font(.titleSmall)
                            .foregroundColor(Color.momentum.charcoal)

                        Text(moodData.vibeCheck)
                            .font(.caption)
                            .foregroundColor(Color.momentum.gray)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)
                }
            }

            // Motivational quote
            Text(moodData.quote)
                .font(.bodySmall)
                .foregroundColor(Color.momentum.plum)
                .italic()
                .padding(.vertical, Spacing.xs)

            // Expanded suggestions
            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Perfect for today:")
                        .font(.caption)
                        .foregroundColor(Color.momentum.gray)

                    let available = moodData.suggestedActivities.filter { !addedSuggestions.contains($0.title) }
                    if available.isEmpty {
                        Text("You've added all suggestions! Nice.")
                            .font(.bodySmall)
                            .foregroundColor(Color.momentum.sage)
                            .padding(.vertical, Spacing.xs)
                    } else {
                        ForEach(available.prefix(4), id: \.title) { activity in
                            WeatherActivityChip(
                                activity: activity,
                                isAdded: false,
                                onAddAsAction: {
                                    onAddAction(activity)
                                    withAnimation {
                                        isExpanded = false
                                    }
                                },
                                onAddAsChallenge: {
                                    onAddChallenge(activity)
                                    withAnimation {
                                        isExpanded = false
                                    }
                                }
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.md)
        .background(
            LinearGradient(
                colors: [
                    moodData.gradientColors[0].opacity(0.1),
                    Color.momentum.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(moodData.gradientColors[0].opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showVibePicker) {
            WeatherVibePicker(currentWeather: weather) { newWeather in
                onChangeWeather?(newWeather)
            }
            .presentationDetents([.height(320)])
        }
    }
}

// MARK: - Weather Vibe Picker
struct WeatherVibePicker: View {
    let currentWeather: WeatherCondition
    let onSelect: (WeatherCondition) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Set Your Vibe")
                .font(.displaySmall)
                .foregroundColor(Color.momentum.charcoal)
                .padding(.top, Spacing.lg)

            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(WeatherCondition.allCases, id: \.self) { condition in
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        onSelect(condition)
                        dismiss()
                    } label: {
                        let mood = WeatherMood.mood(for: condition)
                        VStack(spacing: Spacing.xs) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: mood.gradientColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 52, height: 52)

                                Image(systemName: condition.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            }
                            .overlay(
                                Circle()
                                    .strokeBorder(currentWeather == condition ? Color.momentum.coral : Color.clear, lineWidth: 3)
                                    .frame(width: 56, height: 56)
                            )

                            Text(condition.displayName)
                                .font(.caption)
                                .foregroundColor(Color.momentum.charcoal)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()
        }
        .background(Color.momentum.cream.ignoresSafeArea())
    }
}

// MARK: - Weather Activity Chip
struct WeatherActivityChip: View {
    let activity: ActionTemplate
    var isAdded: Bool = false
    let onAddAsAction: () -> Void
    let onAddAsChallenge: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: activity.type.icon)
                .font(.system(size: 12))
                .foregroundColor(isAdded ? Color.momentum.gray : activity.type.color)

            Text(activity.title)
                .font(.bodySmall)
                .foregroundColor(isAdded ? Color.momentum.gray : Color.momentum.charcoal)
                .lineLimit(1)

            Spacer()

            if isAdded {
                // Show checkmark for already-added items
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.momentum.sage)
            } else {
                // Add as quick action
                Button(action: onAddAsAction) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.momentum.sage)
                }

                // Add as challenge
                Button(action: onAddAsChallenge) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.momentum.coral)
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(isAdded ? Color.momentum.cream : Color.momentum.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
        .momentumShadow(radius: isAdded ? 0 : 2)
        .opacity(isAdded ? 0.7 : 1.0)
    }
}

// MARK: - Weather Mood Data
struct WeatherMood {
    let greeting: String
    let vibeCheck: String
    let quote: String
    let gradientColors: [Color]
    let suggestedActivities: [ActionTemplate]

    static func mood(for weather: WeatherCondition) -> WeatherMood {
        let userName = UserProfileManager.shared.profile.name
        let firstName = userName.components(separatedBy: " ").first ?? userName

        switch weather {
        case .clear:
            return WeatherMood(
                greeting: firstName.isEmpty ? "Main character energy today" : "\(firstName)'s main character moment",
                vibeCheck: "Sunny vibes - the world is your runway",
                quote: "They believed they could, so they did.",
                gradientColors: [Color.momentum.gold, Color.momentum.coral],
                suggestedActivities: [
                    ActionTemplate(title: "Manifest walk in the sun", type: .reflect),
                    ActionTemplate(title: "Outdoor journaling sesh", type: .create),
                    ActionTemplate(title: "Coffee date with your vision board", type: .reflect),
                    ActionTemplate(title: "Take aesthetic progress pics", type: .doIt),
                    ActionTemplate(title: "Network at a sunny patio", type: .connect)
                ]
            )

        case .cloudy:
            return WeatherMood(
                greeting: "Soft era vibes",
                vibeCheck: "Cozy but productive - find your flow",
                quote: "Growth happens in the in-between moments.",
                gradientColors: [Color.momentum.sage, Color.momentum.gray],
                suggestedActivities: [
                    ActionTemplate(title: "Cute cafe work session", type: .research),
                    ActionTemplate(title: "Romanticize your routine", type: .reflect),
                    ActionTemplate(title: "FaceTime your mentor", type: .connect),
                    ActionTemplate(title: "Brain dump in your planner", type: .create)
                ]
            )

        case .rainy:
            return WeatherMood(
                greeting: "Stay cozy, stay focused",
                vibeCheck: "Rain check on outside - glow up inside",
                quote: "Rainy days are for building empires from your couch.",
                gradientColors: [Color.momentum.plum, Color.momentum.sage],
                suggestedActivities: [
                    ActionTemplate(title: "Deep dive research mode", type: .research),
                    ActionTemplate(title: "Cozy content creation", type: .create),
                    ActionTemplate(title: "Audio message your bestie goals", type: .connect),
                    ActionTemplate(title: "Plan next week like a CEO", type: .reflect),
                    ActionTemplate(title: "Online course binge", type: .research),
                    ActionTemplate(title: "Organize your digital life", type: .doIt)
                ]
            )

        case .snowy:
            return WeatherMood(
                greeting: "Winter arc activated",
                vibeCheck: "It's giving main character hibernation",
                quote: "Even royalty needs rest days to conquer kingdoms.",
                gradientColors: [Color.momentum.white, Color.momentum.plum],
                suggestedActivities: [
                    ActionTemplate(title: "Hot cocoa + goal review", type: .reflect),
                    ActionTemplate(title: "Cozy reading session", type: .research),
                    ActionTemplate(title: "Blanket burrito planning", type: .create),
                    ActionTemplate(title: "Voice note check-in with friends", type: .connect),
                    ActionTemplate(title: "Self-care Sunday activities", type: .doIt)
                ]
            )

        case .windy:
            return WeatherMood(
                greeting: "Change is in the air",
                vibeCheck: "Quick moves, big energy",
                quote: "Let the wind carry your doubts away.",
                gradientColors: [Color.momentum.coral, Color.momentum.gold],
                suggestedActivities: [
                    ActionTemplate(title: "Power walk + podcast", type: .doIt),
                    ActionTemplate(title: "Quick errand run aesthetic", type: .doIt),
                    ActionTemplate(title: "Speed networking on LinkedIn", type: .connect),
                    ActionTemplate(title: "5-minute journal prompts", type: .reflect)
                ]
            )

        case .hot:
            return WeatherMood(
                greeting: "It's giving summer mode",
                vibeCheck: "Stay cool, stay focused, stay hydrated",
                quote: "Your glow-up doesn't take breaks for the heat.",
                gradientColors: [Color.momentum.coral, Color.momentum.gold],
                suggestedActivities: [
                    ActionTemplate(title: "Sunrise goal-setting", type: .reflect),
                    ActionTemplate(title: "Iced matcha + work session", type: .research),
                    ActionTemplate(title: "Pool-side reading", type: .research),
                    ActionTemplate(title: "Evening walk with affirmations", type: .reflect),
                    ActionTemplate(title: "AC'd work sprint", type: .create)
                ]
            )

        case .cold:
            return WeatherMood(
                greeting: "Cozy villain era",
                vibeCheck: "Cold outside, fire inside",
                quote: "Too busy building an empire to notice the cold.",
                gradientColors: [Color.momentum.plum, Color.momentum.charcoal],
                suggestedActivities: [
                    ActionTemplate(title: "Warm drink + brain work", type: .research),
                    ActionTemplate(title: "Indoor workout session", type: .doIt),
                    ActionTemplate(title: "Cozy catch-up calls", type: .connect),
                    ActionTemplate(title: "Pinterest your next chapter", type: .create),
                    ActionTemplate(title: "Budget review & goals", type: .reflect)
                ]
            )
        }
    }

    /// Personalized mood based on user's focus areas
    static func personalizedMood(for weather: WeatherCondition) -> WeatherMood {
        let baseMood = mood(for: weather)
        let focusAreas = UserProfileManager.shared.profile.focusAreas

        // If no focus areas set, return base mood
        guard !focusAreas.isEmpty else { return baseMood }

        // Get suggestions from user's focus areas, filtered by weather
        var personalizedSuggestions: [ActionTemplate] = []
        for category in focusAreas {
            let categorySuggestions = ActionTemplates.suggestions(for: category)
                .filter { isWeatherAppropriate($0, for: weather) }
            personalizedSuggestions.append(contentsOf: categorySuggestions.prefix(2))
        }

        // If we got personalized suggestions, combine them with base (prioritizing focus areas)
        guard !personalizedSuggestions.isEmpty else { return baseMood }

        // Combine: personalized first, then base suggestions
        let combined = personalizedSuggestions + baseMood.suggestedActivities

        // Remove duplicates while preserving order (using title as key)
        var seen = Set<String>()
        let unique = combined.filter { template in
            if seen.contains(template.title) {
                return false
            }
            seen.insert(template.title)
            return true
        }

        return WeatherMood(
            greeting: baseMood.greeting,
            vibeCheck: baseMood.vibeCheck,
            quote: baseMood.quote,
            gradientColors: baseMood.gradientColors,
            suggestedActivities: Array(unique.prefix(6))
        )
    }

    /// Check if an activity is appropriate for the weather
    private static func isWeatherAppropriate(_ template: ActionTemplate, for weather: WeatherCondition) -> Bool {
        let outdoorKeywords = ["walk", "outdoor", "outside", "patio", "pool", "hike", "sun", "sunrise", "evening walk"]
        let title = template.title.lowercased()
        let isOutdoor = outdoorKeywords.contains { title.contains($0) }

        switch weather {
        case .rainy, .snowy, .cold:
            return !isOutdoor // Filter out outdoor activities in bad weather
        default:
            return true // All activities OK in good weather
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        WeatherSuggestionsCard(
            weather: .clear,
            addedSuggestions: ["Manifest walk in the sun"],
            onAddAction: { _ in },
            onAddChallenge: { _ in }
        )

        WeatherSuggestionsCard(
            weather: .rainy,
            addedSuggestions: [],
            onAddAction: { _ in },
            onAddChallenge: { _ in }
        )
    }
    .padding()
    .background(Color.momentum.cream)
}
