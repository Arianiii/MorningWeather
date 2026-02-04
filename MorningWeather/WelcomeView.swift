
import SwiftUI

struct WelcomeView: View {
    @Binding var isCompleted: Bool

    // 1. State variables to control the animation
    @State private var currentIconIndex = 0
    // An array of SF Symbols representing different weather conditions
    private let weatherIcons = ["sun.max.fill", "cloud.fill", "cloud.rain.fill", "snow"]
    // An array of colors corresponding to each weather icon
    private let weatherColors: [Color] = [.yellow, .gray.opacity(0.8), .blue.opacity(0.7), .white]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()
                
                // 2. The animated Image view
                Image(systemName: weatherIcons[currentIconIndex])
                    .font(.system(size: 100))
                    // The color of the icon will also animate
                    .foregroundColor(weatherColors[currentIconIndex])
                    .padding()
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 10)
                    // 3. Define a smooth transition for when the icon changes
                    .transition(.opacity.combined(with: .scale))
                    // Using .id() helps SwiftUI understand that the view has changed, ensuring a smooth transition
                    .id(currentIconIndex)

                Text("Welcome to MorningWeather")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(radius: 5)
                
                Text("Get a fresh start to your day with a simple weather forecast right when you wake up.")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: { isCompleted = true }) {
                    Text("Get Started")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .foregroundColor(.primary)
                        .cornerRadius(15)
                }
                .padding()
            }
        }
        // 4. Start the animation when the view appears
        .onAppear(perform: startIconAnimation)
    }

    // A function to handle the animation logic
    private func startIconAnimation() {
        // We use a Task for modern, safe background work in SwiftUI
        Task {
            // This loop will run as long as the view is visible
            while !Task.isCancelled {
                // Wait for 2 seconds before changing the icon
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                
                // Animate the change
                withAnimation(.easeInOut(duration: 1.0)) {
                    // Move to the next icon in the array, looping back to the start if needed
                    currentIconIndex = (currentIconIndex + 1) % weatherIcons.count
                }
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(isCompleted: .constant(false))
    }
}
