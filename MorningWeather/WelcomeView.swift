
import SwiftUI
import SplineRuntime

struct WelcomeView: View {
    @Binding var isCompleted: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "3d4a6c"), Color(hex: "1a2033")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()
                
                // --- FIXED LINE ---
                // The parameter name has been updated from `sceneURL` to `sceneFileURL`
                // to match the newer version of the Spline library.
                if let url = URL(string: "https://prod.spline.design/O7-d-Aqz-i45WH-Y/scene.splinecode") {
                    try? SplineView(sceneFileURL: url) // Corrected parameter name
                        .frame(height: 300)
                        .ignoresSafeArea(.all)
                } else {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 150))
                }
                // --- END OF FIX ---

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
