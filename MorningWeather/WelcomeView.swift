
import SwiftUI
import Lottie

// We keep the LottieView helper from before
struct LottieView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode

    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFill // Use scaleAspectFill for backgrounds
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

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}


struct WelcomeView: View {
    @Binding var isCompleted: Bool

    var body: some View {
        ZStack {
            // 1. Use the LottieView as our new animated background
            LottieView(name: "sky_background", loopMode: .loop)
                .ignoresSafeArea()

            // A subtle gradient overlay to enhance readability
            LinearGradient(
                colors: [.black.opacity(0.3), .clear, .black.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 2. The rest of the UI, on top of the animation
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
