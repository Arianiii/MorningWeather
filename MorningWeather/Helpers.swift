
import SwiftUI
import MapKit
import Lottie
import CoreLocation
import Foundation
import UserNotifications

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    // ... (Existing functions) ...

    // --- NEW: Alarm Scheduling ---
    func scheduleWeatherAlarm(at time: Date, for condition: String, location: SavedLocation) {
        // 1. Clear any existing weather alarms to prevent duplicates
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["WEATHER_ALARM_\(location.name)"])
        
        // 2. Schedule the alarm (simplified logic for the sake of the demo)
        let content = UNMutableNotificationContent()
        content.title = "Weather Alarm! 🚨"
        content.body = "The alarm for \(location.name) is set to check for \(condition) tomorrow morning."
        content.sound = .default
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        dateComponents.weekday = Calendar.current.component(.weekday, from: time.addingTimeInterval(24 * 3600)) // Schedule for the next day
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false) // Set once
        
        let request = UNNotificationRequest(
            identifier: "WEATHER_ALARM_\(location.name)",
            content: content, 
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling alarm: \(error.localizedDescription)")
            } else {
                print("Weather alarm scheduled for \(location.name) at \(dateComponents.hour!):\(dateComponents.minute!)")
            }
        }
    }
}


// MARK: - Location Management
struct SavedLocation: Identifiable, Codable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
}

class LocationManager: ObservableObject {
    @Published var savedLocations: [SavedLocation] = []
    
    // ... (Existing LocationManager functions) ...
}

// MARK: - Weather Service
// ... (WeatherService, OpenWeatherResponse, ForecastResponse, ForecastItem structs remain unchanged) ...


// MARK: - Alarm Structure (NEW)
struct WeatherAlarm: Codable, Identifiable {
    let id = UUID()
    let time: Date
    let city: SavedLocation
    let condition: String // e.g., "Rain", "Snow", "Heavy Wind"
}
