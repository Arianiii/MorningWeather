
import SwiftUI
import Lottie // 1. Import the Lottie library

// A helper view to easily use Lottie animations
struct LottieView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode

    // Creates the LottieAnimationView
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.play()
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }

    // This function is required but we don't need to update the view from here
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}


struct WelcomeView: View {
    @Binding var isCompleted: Bool

    @State private var currentAnimationIndex = 0
    // An array of our Lottie animation file names (without the .json extension)
    private let weatherAnimations = ["sunny", "cloudy", "rainy", "snowy"]

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
                
                // 2. The animated Lottie view
                LottieView(name: weatherAnimations[currentAnimationIndex], loopMode: .loop)
                    .frame(width: 200, height: 200) // Give the animation a nice size
                    .id(currentAnimationIndex) // Helps SwiftUI with the transition
                    .transition(.opacity.combined(with: .scale))


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
        .onAppear(perform: startAnimation)
    }

    private func startAnimation() {
        Task {
            while !Task.isCancelled {
                // Wait for 3 seconds this time to allow the animation to play
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                
                withAnimation(.easeInOut(duration: 0.8)) {
                    currentAnimationIndex = (currentAnimationIndex + 1) % weatherAnimations.count
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
