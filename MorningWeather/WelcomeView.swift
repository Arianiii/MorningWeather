
import SwiftUI
import SplineRuntime // 1. Import the Spline library

struct WelcomeView: View {
    @Binding var isCompleted: Bool

    var body: some View {
        ZStack {
            // A slightly darker gradient to make the 3D scene pop
            LinearGradient(
                colors: [Color(hex: "3d4a6c"), Color(hex: "1a2033")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()
                
                // 2. The new 3D Spline View
                // We load the 3D scene directly from its URL.
                // Note: This requires an internet connection the first time it loads.
                if let url = URL(string: "https://prod.spline.design/O7-d-Aqz-i45WH-Y/scene.splinecode") {
                    try? SplineView(sceneURL: url)
                        .frame(height: 300) // Give it a larger frame
                        .ignoresSafeArea(.all)
                } else {
                    // Fallback in case the URL is invalid
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 150))
                }


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
    }
}

// Helper to allow using Hex color codes
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
