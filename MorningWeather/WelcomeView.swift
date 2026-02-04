
import SwiftUI

// A single, reusable view for the floating icons
struct FloatingIcon: View {
    // Each icon will have its own state for the animation
    @State private var isAnimating = false
    
    // Properties to customize each icon
    let iconName: String
    let size: CGFloat
    let duration: Double
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size))
            .foregroundColor(.white.opacity(0.8))
            .shadow(radius: 5)
            // Position the icon at its start or end point based on the animation state
            .position(x: isAnimating ? endX : startX, y: isAnimating ? endY : startY)
            .onAppear {
                // Start a repeating, auto-reversing animation with a slight delay
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(duration / 2 * Double.random(in: 0...1)) // Random delay to desynchronize animations
                ) {
                    isAnimating = true
                }
            }
    }
}


struct WelcomeView: View {
    @Binding var isCompleted: Bool

    var body: some View {
        // Use a GeometryReader to get the screen dimensions for positioning
        GeometryReader { geo in
            ZStack {
                // 1. The beautiful sky-like gradient background
                LinearGradient(
                    colors: [Color(hex: "4a7b9d"), Color(hex: "2a4d69")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // 2. The floating icons layer
                FloatingIcon(iconName: "sun.max.fill", size: 80, duration: 25, startX: geo.size.width * 0.1, startY: geo.size.height * 0.2, endX: geo.size.width * 0.2, endY: geo.size.height * 0.15)
                FloatingIcon(iconName: "cloud.fill", size: 60, duration: 30, startX: geo.size.width * 0.8, startY: geo.size.height * 0.3, endX: geo.size.width * 0.7, endY: geo.size.height * 0.35)
                FloatingIcon(iconName: "cloud.drizzle.fill", size: 40, duration: 20, startX: geo.size.width * 0.2, startY: geo.size.height * 0.8, endX: geo.size.width * 0.3, endY: geo.size.height * 0.85)
                FloatingIcon(iconName: "snowflake", size: 30, duration: 35, startX: geo.size.width * 0.9, startY: geo.size.height * 0.7, endX: geo.size.width * 0.8, endY: geo.size.height * 0.65)
                FloatingIcon(iconName: "cloud.sun.fill", size: 50, duration: 28, startX: geo.size.width * 0.5, startY: geo.size.height * 0.9, endX: geo.size.width * 0.6, endY: geo.size.height * 0.95)

                // A subtle blur effect for the entire background
                Rectangle()
                    .fill(.clear)
                    .background(.ultraThinMaterial)
                    .opacity(0.1)
                    .ignoresSafeArea()

                // 3. The main UI content on the top layer
                VStack(spacing: 30) {
                    Spacer()

                    Text("Welcome to MorningWeather")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(radius: 10)
                    
                    Text("Get a fresh start to your day with a simple weather forecast right when you wake up.")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: { isCompleted = true }) {
                        Text("Get Started")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white.opacity(0.9))
                            .foregroundColor(.primary)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }
    }
}

// Keep the Hex color helper
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double((rgb >> 0) & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(isCompleted: .constant(false))
    }
}
