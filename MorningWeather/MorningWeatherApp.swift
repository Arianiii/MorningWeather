
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

@main
struct MorningWeatherApp: App {
    // We will initialize WeatherService here to make sure it's ready for location requests
    @StateObject private var weatherService = WeatherService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    WelcomeView(isCompleted: $hasCompletedOnboarding)
                }
            }
            .onAppear {
                // --- MOVED LOCATION AND NOTIFICATION REQUESTS HERE ---
                // 1. Request Location Authorization immediately on app launch
                weatherService.requestLocationAuthorization() // Call the new public function
                // 2. Request Notification Authorization immediately on app launch
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        print("Notification authorization granted.")
                    } else if let error = error {
                        print("Notification authorization denied: \(error.localizedDescription)")
                    }
                }
                // --- END MOVED REQUESTS ---
            }
        }
    }
}
