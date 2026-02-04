
import Foundation
import WeatherKit
import CoreLocation

// A simple service class to fetch weather data using WeatherKit.
@MainActor
class WeatherService: ObservableObject {
    @Published var weather: Weather?
    
    private let service = WeatherKit.WeatherService.shared
    private let locationManager = CLLocationManager()
    
    init() {
        // Request authorization when the service is created.
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchWeather(for location: CLLocation) async {
        do {
            let result = try await service.weather(for: location)
            self.weather = result
            print("Weather data fetched successfully.")
        } catch {
            print("Failed to fetch weather data: \(error.localizedDescription)")
        }
    }
    
    // A helper function to get the user's current location and then fetch weather.
    func fetchWeatherForCurrentLocation() {
        // Make sure to add "Privacy - Location When In Use Usage Description" to your Info.plist
        guard let location = locationManager.location else {
            print("User location is not available.")
            return
        }
        
        Task {
            await fetchWeather(for: location)
        }
    }
}
