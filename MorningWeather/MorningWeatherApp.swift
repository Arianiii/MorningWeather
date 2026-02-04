
import SwiftUI

@main
struct MorningWeatherApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                WelcomeView(isCompleted: $hasCompletedOnboarding)
            }
        }
    }
}
