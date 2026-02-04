
import SwiftUI

struct WelcomeView: View {
    @Binding var isCompleted: Bool

    var body: some View {
        // Use a ZStack to layer the background behind the content
        ZStack {
            // 1. A colorful gradient background that will be visible through the glass effect
            LinearGradient(
                colors: [.blue, .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 2. The main content
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.yellow)
                    .padding()
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 10)

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
                
                Button(action: {
                    isCompleted = true
                }) {
                    Text("Get Started")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        // 3. Apply the "glass" material effect to the button's background
                        .background(.ultraThinMaterial)
                        .foregroundColor(.primary)
                        .cornerRadius(15)
                }
                .padding()
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(isCompleted: .constant(false))
    }
}
