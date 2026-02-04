
import SwiftUI

// This view is now very clean and only contains UI code.
// It uses the FloatingIcon helper from Helpers.swift.
struct WelcomeView: View {
    @Binding var isCompleted: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(hex: "4a7b9d"), Color(hex: "2a4d69")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                FloatingIcon(iconName: "sun.max.fill", size: 80, duration: 25, startX: geo.size.width * 0.1, startY: geo.size.height * 0.2, endX: geo.size.width * 0.2, endY: geo.size.height * 0.15)
                FloatingIcon(iconName: "cloud.fill", size: 60, duration: 30, startX: geo.size.width * 0.8, startY: geo.size.height * 0.3, endX: geo.size.width * 0.7, endY: geo.size.height * 0.35)
                FloatingIcon(iconName: "cloud.drizzle.fill", size: 40, duration: 20, startX: geo.size.width * 0.2, startY: geo.size.height * 0.8, endX: geo.size.width * 0.3, endY: geo.size.height * 0.85)

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
                            .font(.title3).fontWeight(.semibold)
                            .frame(maxWidth: .infinity).padding()
                            .background(.white.opacity(0.9)).foregroundColor(.primary)
                            .cornerRadius(15).shadow(radius: 5)
                    }
                    .padding()
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
