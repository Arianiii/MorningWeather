
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

@main
struct MorningWeatherApp: App {
    // FIX: WeatherService is declared as StateObject/ObservedObject because it's the root of data flow
    @StateObject private var weatherService = WeatherService() 
    // FIX: LocationManager is declared as StateObject because it manages global app state (Saved Locations)
    @StateObject private var locationManager = LocationManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashScreenView()
                } else if hasCompletedOnboarding {
                    ContentView()
                        // FIX: Pass LocationManager as EnvironmentObject
                        .environmentObject(locationManager) 
                } else {
                    WelcomeView(isCompleted: $hasCompletedOnboarding)
                         // FIX: Pass LocationManager as EnvironmentObject
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
