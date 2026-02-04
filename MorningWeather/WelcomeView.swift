
import SwiftUI
import SceneKit // 1. Import SceneKit, Apple's native 3D framework

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
                
                // 2. Use the native SceneView to display a 3D model
                // We are loading a "stylized_cloud.usdz" model that is now part of our project.
                SceneView(
                    // "scene:" expects a SceneKit scene object. We create one from our file.
                    scene: SCNScene(named: "stylized_cloud.usdz"),
                    // "options:" allows us to configure the view
                    options: [
                        .autoenablesDefaultLighting, // Adds a simple light so the model isn't dark
                        .allowsCameraControl // Lets the user rotate and zoom the model!
                    ]
                )
                .frame(height: 300)

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
