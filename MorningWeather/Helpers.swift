
import SwiftUI
import MapKit
import Lottie
import CoreLocation
import Foundation
import UserNotifications

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    private let notificationTimeKey = "dailyNotificationTime"
    
    // Gets the saved time or defaults to 8:00 AM
    func getDailyNotificationTime() -> Date {
        if let data = UserDefaults.standard.data(forKey: notificationTimeKey),
           let time = try? JSONDecoder().decode(Date.self, from: data) {
            return time
        }
        // Default to 8:00 AM
        return Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    }
    
    // Saves the user-selected time
    func setDailyNotificationTime(time: Date) {
        if let encoded = try? JSONEncoder().encode(time) {
            UserDefaults.standard.set(encoded, forKey: notificationTimeKey)
            // Reschedule immediately after saving
            if let lastLocation = LocationManager().getLastViewedLocation(), 
               let weatherData = WeatherService().weatherData {
                scheduleDailyWeatherNotification(for: CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude), weatherData: weatherData)
            }
        }
    }
    
    func requestNotificationAuthorization() {
        // ... (remains the same)
    }
    
    func scheduleDailyWeatherNotification(for location: CLLocation, weatherData: OpenWeatherResponse) {
        clearPendingNotifications()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Good Morning! ☀️"
            
            let bodyMessage: String; let mainCondition = weatherData.weather.first?.main.lowercased() ?? "clear"
            let temp = Int(weatherData.main.temp); let locationName = weatherData.name
            
            let hour = Calendar.current.component(.hour, from: Date())
            
            if hour < 12 { bodyMessage = "It's \(temp)°C in \(locationName). Expect \(mainCondition). Have a great morning!" }
            else if hour < 18 { bodyMessage = "Current weather in \(locationName): \(temp)°C and \(mainCondition). Enjoy your afternoon!" }
            else if hour < 20 { bodyMessage = "Current weather in \(locationName): \(temp)°C and \(mainCondition). Enjoy your evening!" }
            else { bodyMessage = "\(locationName) is \(temp)°C with \(mainCondition). Wishing you a good night!" }
            
            content.body = bodyMessage; content.sound = .default
            
            // --- UPDATED LOGIC: Use Saved Time ---
            let notificationTime = self.getDailyNotificationTime()
            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
            // --- END UPDATED LOGIC ---
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(identifier: "DailyWeatherNotification", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }
    
    func scheduleWeatherAlarm(at time: Date, for condition: String, location: SavedLocation) {
        // ... (remains the same)
    }
    
    func clearPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// ... (LocationManager, WeatherService, Data Models, Alarm Structure, and all Helper Views remain the same) ...

// MARK: - Settings View (NEW)
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTime: Date = NotificationManager().getDailyNotificationTime()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("DAILY WEATHER NOTIFICATION")) {
                    DatePicker("Notification Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .onChange(of: selectedTime) { newTime in
                            notificationManager.setDailyNotificationTime(time: newTime)
                        }
                    
                    Text("The weather forecast will be sent to you daily at this time for the last viewed location.")
                        .font(.caption)
                        .opacity(0.7)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// ... (All other existing structs/classes/extensions from Helpers.swift are appended here) ...
