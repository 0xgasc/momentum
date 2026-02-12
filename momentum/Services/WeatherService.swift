import Foundation
import SwiftUI
import WeatherKit
import CoreLocation
import Combine

// MARK: - Weather Service
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentWeather: WeatherCondition?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let weatherKitService = WeatherKit.WeatherService.shared
    private let locationManager = CLLocationManager()
    private var locationCompletion: ((CLLocation?) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Fetch Weather
    @MainActor
    func fetchWeather() async {
        let profile = UserProfileManager.shared.profile

        // Respect user's weather preference
        switch profile.weatherMode {
        case .off:
            currentWeather = nil // Dashboard hides weather card
            isLoading = false
            return
        case .manual:
            currentWeather = profile.manualWeather ?? .clear
            isLoading = false
            return
        case .auto:
            break // Continue with location-based fetch below
        }

        isLoading = true
        errorMessage = nil

        // Request location permission if needed
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            isLoading = false
            currentWeather = .clear
            return
        }

        // Get current location
        let location = await withCheckedContinuation { continuation in
            locationCompletion = { location in
                continuation.resume(returning: location)
            }
            locationManager.requestLocation()

            // Timeout after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if self?.locationCompletion != nil {
                    self?.locationCompletion?(nil)
                    self?.locationCompletion = nil
                }
            }
        }

        guard let location else {
            isLoading = false
            currentWeather = .clear
            return
        }

        do {
            let weather = try await weatherKitService.weather(for: location)
            let condition = weather.currentWeather.condition
            currentWeather = mapCondition(condition)
        } catch {
            print("Weather fetch error: \(error)")
            currentWeather = .clear
        }

        isLoading = false
    }

    private func mapCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
        case .clear, .mostlyClear:
            return .clear
        case .partlyCloudy, .mostlyCloudy, .cloudy:
            return .cloudy
        case .rain, .drizzle, .heavyRain:
            return .rainy
        case .snow, .sleet, .heavySnow:
            return .snowy
        case .windy, .breezy:
            return .windy
        case .hot:
            return .hot
        case .frigid:
            return .cold
        default:
            return .clear
        }
    }

    // MARK: - Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationCompletion?(locations.first)
        locationCompletion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationCompletion?(nil)
        locationCompletion = nil
    }
}

// MARK: - Weather Condition Enum
enum WeatherCondition: String, CaseIterable, Codable {
    case clear
    case cloudy
    case rainy
    case snowy
    case windy
    case hot
    case cold

    var displayName: String {
        switch self {
        case .clear: return "Clear"
        case .cloudy: return "Cloudy"
        case .rainy: return "Rainy"
        case .snowy: return "Snowy"
        case .windy: return "Windy"
        case .hot: return "Hot"
        case .cold: return "Cold"
        }
    }

    var icon: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "snow"
        case .windy: return "wind"
        case .hot: return "thermometer.sun.fill"
        case .cold: return "thermometer.snowflake"
        }
    }

    var activityRecommendation: String {
        switch self {
        case .clear:
            return "Perfect weather for outdoor activities!"
        case .cloudy:
            return "Great day for a walk or outdoor tasks."
        case .rainy:
            return "Indoor day - perfect for research or creative work."
        case .snowy:
            return "Cozy inside day - ideal for reflection and planning."
        case .windy:
            return "Breezy day - good for quick outdoor errands."
        case .hot:
            return "Stay cool - morning or evening outdoor activities."
        case .cold:
            return "Bundle up for outdoor activities or stay in."
        }
    }
}

// MARK: - Weather-Based Action Suggestions
struct WeatherBasedSuggestions {
    static func suggestedActionTypes(for weather: WeatherCondition, category: GoalCategory) -> [ActionType] {
        switch weather {
        case .clear, .cloudy:
            return [.doIt, .connect, .create, .research, .reflect]
        case .rainy, .snowy:
            return [.research, .reflect, .create, .doIt]
        case .windy:
            return [.doIt, .research, .connect]
        case .hot, .cold:
            return [.research, .reflect, .create, .connect]
        }
    }

    static func suggestions(for weather: WeatherCondition, category: GoalCategory) -> [ActionTemplate] {
        let baseActions = ActionTemplates.suggestions(for: category)
        let preferredTypes = suggestedActionTypes(for: weather, category: category)

        return baseActions.sorted { action1, action2 in
            let index1 = preferredTypes.firstIndex(of: action1.type) ?? preferredTypes.count
            let index2 = preferredTypes.firstIndex(of: action2.type) ?? preferredTypes.count
            return index1 < index2
        }
    }

    static func weatherSpecificActions(for weather: WeatherCondition) -> [ActionTemplate] {
        switch weather {
        case .clear:
            return [
                ActionTemplate(title: "Go for a walk while brainstorming", type: .reflect),
                ActionTemplate(title: "Have an outdoor meeting or call", type: .connect),
                ActionTemplate(title: "Take progress photos outside", type: .create),
                ActionTemplate(title: "Exercise or stretch outdoors", type: .doIt)
            ]
        case .cloudy:
            return [
                ActionTemplate(title: "Take a reflective walk", type: .reflect),
                ActionTemplate(title: "Work from a cafe with outdoor seating", type: .doIt),
                ActionTemplate(title: "Meet a friend for coffee", type: .connect)
            ]
        case .rainy:
            return [
                ActionTemplate(title: "Deep work session - no distractions", type: .research),
                ActionTemplate(title: "Journal about your progress", type: .reflect),
                ActionTemplate(title: "Organize your workspace", type: .doIt),
                ActionTemplate(title: "Video call with your network", type: .connect),
                ActionTemplate(title: "Create content for your goals", type: .create)
            ]
        case .snowy:
            return [
                ActionTemplate(title: "Plan your week ahead", type: .reflect),
                ActionTemplate(title: "Read industry articles or books", type: .research),
                ActionTemplate(title: "Cozy creative session", type: .create),
                ActionTemplate(title: "Catch up with someone you miss", type: .connect)
            ]
        case .windy:
            return [
                ActionTemplate(title: "Quick outdoor task or errand", type: .doIt),
                ActionTemplate(title: "Short walking phone call", type: .connect),
                ActionTemplate(title: "Indoor focus session", type: .research)
            ]
        case .hot:
            return [
                ActionTemplate(title: "Early morning outdoor activity", type: .doIt),
                ActionTemplate(title: "Air-conditioned work session", type: .research),
                ActionTemplate(title: "Indoor creative work", type: .create),
                ActionTemplate(title: "Evening walk meeting", type: .connect)
            ]
        case .cold:
            return [
                ActionTemplate(title: "Warm drink + planning session", type: .reflect),
                ActionTemplate(title: "Cozy research session", type: .research),
                ActionTemplate(title: "Indoor workout or yoga", type: .doIt),
                ActionTemplate(title: "Phone call catch-up", type: .connect)
            ]
        }
    }
}
