
import SwiftUI

struct WelcomeView: View {
    @Binding var isCompleted: Bool

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "sun.max.fill")
                .font(.system(size: 100))
                .foregroundColor(.yellow)
                .padding()
                .shadow(radius: 10)

            Text("Welcome to MorningWeather")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Get a fresh start to your day with a simple weather forecast right when you wake up.")
                .font(.headline)
                .foregroundColor(.secondary)
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
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(isCompleted: .constant(false))
    }
}
