
import SwiftUI
import MapKit
import Lottie
import CoreLocation
import Foundation
import UserNotifications

// MARK: - Notification Manager (No Change)
class NotificationManager: ObservableObject {
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted { print("Notification authorization granted.") }
        }
    }
    
    func scheduleDailyWeatherNotification(for location: CLLocation, weatherData: OpenWeatherResponse) {
        clearPendingNotifications()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "Good Morning! ☀️"
            
            var bodyMessage: String
            let mainCondition = weatherData.weather.first?.main.lowercased() ?? "clear"
            let temp = Int(weatherData.main.temp)
            let locationName = weatherData.name
            let hour = Calendar.current.component(.hour, from: Date())
            
            if hour < 12 { bodyMessage = "It's \(temp)°C in \(locationName). Expect \(mainCondition). Have a great morning!" }
            else if hour < 18 { bodyMessage = "Current weather in \(locationName): \(temp)°C and \(mainCondition). Enjoy your afternoon!" }
            else if hour < 20 { bodyMessage = "Current weather in \(locationName): \(temp)°C and \(mainCondition). Enjoy your evening!" }
            else { bodyMessage = "\(locationName) is \(temp)°C with \(mainCondition). Wishing you a good night!" }
            
            content.body = bodyMessage; content.sound = .default
            
            var dateComponents = DateComponents(); dateComponents.hour = 8; dateComponents.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }
    
    func clearPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Weather Service (using OpenWeatherMap)
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    // UPDATED: Now includes Forecast Response and handles two API calls (current and forecast)
    @Published var weatherData: CurrentWeatherResponse?
    @Published var forecastData: ForecastResponse? 
    @Published var errorMessage: String?
    @Published var isLoadingLocation = false

    private let apiKey = "dca771ea4f512ddfece257fb57686565"
    let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        self.locationManager.delegate = self
    }

    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func fetchCurrentLocationWeather() {
        isLoadingLocation = true
        self.errorMessage = nil
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
            requestLocationAuthorization()
        case .denied, .restricted:
            self.errorMessage = "Location access denied. Please enable in Settings for current weather."
            isLoadingLocation = false
        @unknown default:
            self.errorMessage = "Unknown location authorization status."
            isLoadingLocation = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
            self.errorMessage = nil
        case .denied, .restricted:
            self.errorMessage = "Location access denied. Please enable in Settings for current weather."
            isLoadingLocation = false
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default: break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLoadingLocation = false
        guard let location = locations.first else {
            self.errorMessage = "Could not determine current location."
            return
        }
        Task { await fetchWeather(for: location) }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoadingLocation = false
        self.errorMessage = "Failed to get current location: \(error.localizedDescription)"
    }

    // UPDATED: Fetches BOTH current weather and 5-day forecast
    func fetchWeather(for location: CLLocation) async {
        self.weatherData = nil
        self.forecastData = nil
        self.errorMessage = nil
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        let currentUrlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        let forecastUrlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"

        // 1. Fetch Current Weather
        do {
            guard let url = URL(string: currentUrlString) else { throw URLError(.badURL) }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let decodedResponse = try JSONDecoder().decode(CurrentWeatherResponse.self, from: data)
            self.weatherData = decodedResponse
            NotificationManager().scheduleDailyWeatherNotification(for: location, weatherData: decodedResponse)
        } catch {
            self.errorMessage = "Failed to fetch current weather. Details: \(error.localizedDescription)"
            return
        }
        
        // 2. Fetch Forecast
        do {
            guard let url = URL(string: forecastUrlString) else { throw URLError(.badURL) }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            
            // Set the date decoding strategy for Unix timestamps
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970 
            
            let decodedResponse = try decoder.decode(ForecastResponse.self, from: data)
            self.forecastData = decodedResponse
        } catch {
            // Note: Forecast failure is secondary, don't overwrite primary weather error
            if self.errorMessage == nil {
                 self.errorMessage = "Failed to fetch forecast data. Details: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - OpenWeatherMap Data Models (UPDATED to CurrentWeatherResponse)
typealias OpenWeatherResponse = CurrentWeatherResponse // Alias for existing code compatibility

struct CurrentWeatherResponse: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
    let sys: Sys
    let wind: Wind 
    let visibility: Int? 

    struct Main: Codable {
        let temp: Double
        let feels_like: Double
        let temp_min: Double
        let temp_max: Double
        let pressure: Int
        let humidity: Int
    }

    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct Wind: Codable {
        let speed: Double
    }
    
    struct Sys: Codable {
        let sunrise: Date
        let sunset: Date
    }
    
    var isDaytime: Bool {
        let now = Date()
        return now >= sys.sunrise && now < sys.sunset
    }
}

// NEW: Model for 5-day / 3-hour forecast
struct ForecastResponse: Codable {
    let list: [ForecastItem]
}

struct ForecastItem: Codable, Identifiable {
    let dt: Date
    let main: CurrentWeatherResponse.Main
    let weather: [CurrentWeatherResponse.Weather]
    
    var id: Date { dt }
    
    var hour: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: dt)
    }
    
    var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: dt)
    }
}


// MARK: - Helper Views (Existing)
// (LottieView, WeatherAnimationView, FloatingIcon, SplashScreenView, WeatherCardView, DetailItem, Extensions)
// ... (The rest of the Helpers.swift file with all other helper structs and classes)
// ... (Including the existing LottieView, WeatherAnimationView, etc.) ...
// [The rest of the file content for Helpers.swift is assumed to be appended here] ...
