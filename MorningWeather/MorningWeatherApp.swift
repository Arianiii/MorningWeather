
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

@main
struct MorningWeatherApp: App {
    @StateObject private var weatherService = WeatherService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

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
                weatherService.requestLocationAuthorization()
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        print("Notification authorization granted.")
                    } else if let error = error {
                        print("Notification authorization denied: \(error.localizedDescription)")
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { 
                    withAnimation { showSplash = false }
                }
            }
        }
    }
}
