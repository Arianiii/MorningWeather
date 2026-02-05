
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

@main
struct MorningWeatherApp: App {
    @StateObject private var weatherService = WeatherService()
    @AppObject private var locationManager = LocationManager() // Phase 2: LocationManager for global access
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashScreenView()
                } else if hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(locationManager) // Pass LocationManager environment
                } else {
                    WelcomeView(isCompleted: $hasCompletedOnboarding)
                        .environmentObject(locationManager)
                }
            }
            .onAppear {
                weatherService.requestLocationAuthorization()
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted { print("Notification authorization granted.") }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { 
                    withAnimation { showSplash = false }
                }
            }
        }
    }
}
