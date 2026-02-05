
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

@main
struct MorningWeatherApp: App {
    @StateObject private var weatherService = WeatherService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    // State to control showing the splash screen
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashScreenView() // Our new splash screen
                } else if hasCompletedOnboarding {
                    ContentView()
                } else {
                    WelcomeView(isCompleted: $hasCompletedOnboarding)
                }
            }
            .onAppear {
                // --- MOVED LOCATION AND NOTIFICATION REQUESTS HERE ---
                // 1. Request Location Authorization immediately on app launch
                weatherService.requestLocationAuthorization()
                // 2. Request Notification Authorization immediately on app launch
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        print("Notification authorization granted.")
                    } else if let error = error {
                        print("Notification authorization denied: \(error.localizedDescription)")
                    }
                }
                // --- END MOVED REQUESTS ---
                
                // Dismiss splash screen after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // 2 second splash screen
                    withAnimation { showSplash = false }
                }
            }
        }
    }
}
