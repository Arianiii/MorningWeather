
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
        // ... (Notification logic remains the same)
    }
    
    func clearPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Location Management (UPDATED FOR PHASE 2)
struct SavedLocation: Identifiable, Codable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
}

class LocationManager: ObservableObject {
    @Published var savedLocations: [SavedLocation] = []
    
    private let userDefaultsKey = "savedWeatherLocations"
    private let lastLocationKey = "lastViewedLocation"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
                savedLocations = decoded
                return
            }
        }
        savedLocations = []
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func addLocation(name: String, coordinate: CLLocationCoordinate2D) {
        let newLocation = SavedLocation(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        if !savedLocations.contains(where: { $0.name == name }) {
            savedLocations.append(newLocation)
            save()
        }
    }
    
    func removeLocation(at offsets: IndexSet) {
        savedLocations.remove(atOffsets: offsets)
        save()
    }
    
    func setLastViewedLocation(name: String, coordinate: CLLocationCoordinate2D) {
        let lastLocation = SavedLocation(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let encoded = try? JSONEncoder().encode(lastLocation) {
            UserDefaults.standard.set(encoded, forKey: lastLocationKey)
        }
    }
    
    func getLastViewedLocation() -> SavedLocation? {
        if let data = UserDefaults.standard.data(forKey: lastLocationKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970 
            return try? decoder.decode(SavedLocation.self, from: data)
        }
        return nil
    }
}


// MARK: - Weather Service (using OpenWeatherMap)
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
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
            
            // Set last viewed location upon successful fetch
            LocationManager().setLastViewedLocation(name: decodedResponse.name, coordinate: location.coordinate)
            LocationManager().addLocation(name: decodedResponse.name, coordinate: location.coordinate) // Add to saved locations

        } catch {
            self.errorMessage = "Failed to fetch current weather. Details: \(error.localizedDescription)"
            return
        }
        
        // 2. Fetch Forecast
        do {
            guard let url = URL(string: forecastUrlString) else { throw URLError(.badURL) }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970 
            
            let decodedResponse = try decoder.decode(ForecastResponse.self, from: data)
            self.forecastData = decodedResponse
        } catch {
            if self.errorMessage == nil {
                 self.errorMessage = "Failed to fetch forecast data. Details: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - OpenWeatherMap Data Models (UPDATED to CurrentWeatherResponse)
// ... (CurrentWeatherResponse, ForecastResponse, ForecastItem structs remain unchanged) ...

// MARK: - Helper Views (Existing)
// ... (All existing View structs remain unchanged) ...

// MARK: - Extensions
// ... (Color, MKPlacemark extensions remain unchanged) ...
