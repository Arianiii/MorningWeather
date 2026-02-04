
import SwiftUI

struct ContentView: View {
    // Create an instance of our weather service
    @StateObject private var weatherService = WeatherService()
    
    var body: some View {
        VStack(spacing: 20) {
            if let weather = weatherService.weather {
                // Display the fetched weather data
                Text("Current Weather")
                    .font(.largeTitle)
                
                Text(weather.currentWeather.condition.description)
                    .font(.title)
                
                Text("\(weather.currentWeather.temperature.formatted())")
                    .font(.system(size: 60, weight: .bold))
                
                Text("Feels like: \(weather.currentWeather.apparentTemperature.formatted())")
                
            } else {
                // Show a loading or prompt view
                ProgressView()
                Text("Fetching weather data...")
                    .padding()
            }
            
            Button("Refresh Weather") {
                weatherService.fetchWeatherForCurrentLocation()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .onAppear {
            // Fetch weather when the view first appears
            weatherService.fetchWeatherForCurrentLocation()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
