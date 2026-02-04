
import SwiftUI

struct ContentView: View {
    @StateObject private var weatherService = WeatherService()
    
    var body: some View {
        // Use a ZStack to layer the background behind the content
        ZStack {
            // 1. A colorful gradient background, consistent with the welcome screen
            LinearGradient(
                colors: [.blue, .cyan.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 2. Main content VStack
            VStack(spacing: 20) {
                if let weather = weatherService.weather {
                    
                    Text("Cupertino") // Example city name
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    Text(weather.currentWeather.condition.description)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer().frame(height: 30)
                    
                    Text("\(weather.currentWeather.temperature.formatted().dropLast())") // Remove the unit for custom styling
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    + Text("°")
                        .font(.system(size: 80, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .shadow(radius: 10)
                    
                    Text("Feels like: \(weather.currentWeather.apparentTemperature.formatted())")
                        .foregroundColor(.white.opacity(0.9))

                } else {
                    // Loading view
                    ProgressView()
                        .tint(.white)
                    Text("Fetching weather data...")
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .padding()
            // 3. Apply the "glass" material effect as a background to our content
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .padding()

        }
        .onAppear {
            weatherService.fetchWeatherForCurrentLocation()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
