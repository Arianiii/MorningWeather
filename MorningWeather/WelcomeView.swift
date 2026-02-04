
import SwiftUI
import AVKit // 1. Import Apple's Audio/Video Kit

// A helper view to play the video on a loop
struct LoopingPlayerView: View {
    // We need an AVPlayer instance
    @State private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            // Use .onAppear to set up and start the video
            .onAppear {
                // Find the video file in our project
                guard let fileURL = Bundle.main.url(forResource: "background_video", withExtension: "mp4") else {
                    print("Video file not found.")
                    return
                }
                
                // Create a player item
                let playerItem = AVPlayerItem(url: fileURL)
                
                // Set up the player
                player.replaceCurrentItem(with: playerItem)
                player.isMuted = true // Mute the video
                player.play() // Start playing
                
                // Set up an observer to loop the video when it ends
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                    player.seek(to: .zero) // Go back to the start
                    player.play() // Play again
                }
            }
            // Use .onDisappear to clean up the observer
            .onDisappear {
                NotificationCenter.default.removeObserver(self)
            }
    }
}


struct WelcomeView: View {
    @Binding var isCompleted: Bool

    var body: some View {
        // Use a ZStack to layer the content on top of the video
        ZStack {
            // 2. The looping video player as the background
            LoopingPlayerView()
                .ignoresSafeArea() // Make it fill the whole screen
                .blur(radius: 3) // Add a slight blur for a softer look
                .scaleEffect(1.2) // Zoom in a bit to avoid black edges

            // A semi-transparent overlay to make the text more readable
            Color.black.opacity(0.3).ignoresSafeArea()

            // 3. The rest of our UI content, unchanged
            VStack(spacing: 30) {
                Spacer()

                Text("Welcome to MorningWeather")
                    .font(.system(size: 44, weight: .bold))
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

// Preview Provider remains unchanged, but the video won't play in the canvas.
// You must run the app in the Simulator to see the video.
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(isCompleted: .constant(false))
    }
}
