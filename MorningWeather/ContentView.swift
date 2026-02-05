
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

struct ContentView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    
    @StateObject private var weatherService = WeatherService()
    @State private var selectedLocation: MKPlacemark? = nil
    
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            if let weather = weatherService.weatherData {
                DynamicBackgroundView(condition: weather.weather.first?.main.lowercased() ?? "clear", isDaytime: weather.isDaytime)
            } else {
                LinearGradient(colors: [Color(hex: "3d4a6c"), Color(hex: "1a2033")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }

            VStack(spacing: 20) {
                if selectedLocation == nil && (!weatherService.isLoadingLocation || weatherService.errorMessage != nil) {
                    searchSection
                } else {
                    weatherDisplay
                }
            }
            .transition(.opacity)
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted { print("Notification authorization granted.") }
            }
        }
        .onChange(of: searchText, perform: searchLocations)
    }
    
    private var searchSection: some View {
        VStack {
            Spacer()
            Text("Find Your Weather").font(.largeTitle).bold().foregroundColor(.white)
                .shadow(radius: 5)
            
            if weatherService.isLoadingLocation && weatherService.errorMessage == nil {
                ProgressView().tint(.white).scaleEffect(1.5)
                Text("Getting your current location...").foregroundColor(.white.opacity(0.8))
            } else {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.6))
                    TextField("Search for a city...", text: $searchText)
                        .foregroundColor(.white)
                        .accentColor(.white)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .padding(.horizontal)
                
                if !searchResults.isEmpty {
                    List(searchResults) { result in
                        Button(action: { selectLocation(result.placemark) }) {
                            Text(result.placemark.title ?? "Unknown").foregroundColor(.primary)
                        }
                    }
                    .listStyle(.plain)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .frame(maxHeight: 300)
                }
                
                Button(action: { 
                    withAnimation { weatherService.fetchCurrentLocationWeather() } 
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Use Current Location")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                }
                .padding(.top, 10)
                .padding(.horizontal)
            }
            Spacer()
        }
    }
    
    private var weatherDisplay: some View {
        // Embed a ScrollView to allow scrolling over the forecast data
        ScrollView {
            VStack(spacing: 20) {
                if let errorMessage = weatherService.errorMessage {
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundColor(.yellow)
                        Text("Error").font(.largeTitle).fontWeight(.bold)
                        Text(errorMessage).multilineTextAlignment(.center).padding(.horizontal)
                        Button("Try Again") {
                            if selectedLocation == nil {
                                weatherService.fetchCurrentLocationWeather()
                            } else if let location = selectedLocation?.location {
                                Task { await weatherService.fetchWeather(for: location) }
                            }
                        }.padding().background(.white.opacity(0.2)).cornerRadius(10)
                    }
                    .foregroundColor(.white).padding().background(.ultraThinMaterial).cornerRadius(20).padding()
                    
                } else if let weather = weatherService.weatherData, let locationName = selectedLocation?.title ?? Optional(weather.name) {
                    
                    WeatherCardView(weather: weather, locationName: locationName)
                        .transition(.scale.combined(with: .opacity))
                        .scaleEffect(isAnimating ? 1.01 : 1.0)
                        .rotationEffect(.degrees(isAnimating ? 0.5 : -0.5))
                        .onAppear { withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) { isAnimating = true } }

                    // --- NEW: Forecast Views ---
                    if let forecast = weatherService.forecastData {
                        HourlyForecastView(forecastList: forecast.list)
                        DailyForecastView(forecastList: forecast.list)
                    }
                    // --- END NEW ---

                } else if weatherService.isLoadingLocation {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Getting your current location...").foregroundColor(.white).padding(.top, 10)
                }
                
                Spacer()
                
                if weatherService.weatherData != nil {
                    Button(action: {
                        withAnimation {
                            selectedLocation = nil; searchText = ""; weatherService.errorMessage = nil; weatherService.weatherData = nil; weatherService.forecastData = nil
                        }
                    }) {
                        Image(systemName: "magnifyingglass.circle.fill").font(.system(size: 50)).foregroundColor(.white.opacity(0.8)).background(Color.black.opacity(0.2)).clipShape(Circle())
                    }
                    .padding(.bottom, 30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack takes all space
        }
    }
    
    private func searchLocations(query: String) {
        let request = MKLocalSearch.Request(); request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            self.searchResults = response?.mapItems.map { SearchResult(placemark: $0.placemark) } ?? []
        }
    }
    
    private func selectLocation(_ placemark: MKPlacemark) {
        guard let location = placemark.location else { return }
        withAnimation {
            self.selectedLocation = placemark
            self.searchResults = []
            Task { await weatherService.fetchWeather(for: location) }
        }
    }
}

// --- NEW: Forecast Views ---

struct HourlyForecastView: View {
    let forecastList: [ForecastItem]
    
    var hourlyForecast: [ForecastItem] {
        return Array(forecastList.prefix(8)) // Show next 8 hourly (24 hours in 3-hour blocks)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("HOURLY FORECAST")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(hourlyForecast) { item in
                        VStack(spacing: 8) {
                            Text(item.hour)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: item.weather.first?.icon.toSFSymbol() ?? "questionmark.circle") // Use icon converter
                                .font(.title3)
                                .frame(height: 30)
                            Text("\(Int(item.main.temp))°C")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            .padding(.horizontal)
        }
        .padding(.top)
    }
}

struct DailyForecastView: View {
    let forecastList: [ForecastItem]
    
    // Group 3-hour forecasts into daily forecasts, showing one item per day
    var dailyForecast: [ForecastItem] {
        let now = Date()
        var uniqueDays: [String: ForecastItem] = [:]
        
        for item in forecastList {
            let day = item.day // E.g., "Mon", "Tue"
            
            // Skip today and only take the first forecast item for each unique day
            if item.dt > now && uniqueDays[day] == nil {
                uniqueDays[day] = item
            }
        }
        // Return sorted list of next 5 days
        let sortedDays = uniqueDays.values.sorted(by: { $0.dt < $1.dt }).prefix(5)
        return Array(sortedDays)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("5-DAY FORECAST")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(dailyForecast) { item in
                    HStack {
                        Text(item.day)
                            .fontWeight(.medium)
                            .frame(width: 50, alignment: .leading)
                        
                        Image(systemName: item.weather.first?.icon.toSFSymbol() ?? "questionmark.circle")
                            .font(.title3)
                        
                        Text(item.weather.first?.description.capitalized ?? "")
                            .font(.callout)
                            .opacity(0.8)
                        
                        Spacer()
                        
                        Text("\(Int(item.main.temp_max))° / \(Int(item.main.temp_min))°")
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.clear)
                }
            }
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            .padding(.horizontal)
        }
        .padding(.top)
    }
}

// Extension to convert OpenWeatherMap icons to SFSymbols (approximate)
extension String {
    func toSFSymbol() -> String {
        switch self {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n", "04d", "04n": return "cloud.fill"
        case "09d", "09n", "10d", "10n": return "cloud.rain.fill"
        case "11d", "11n": return "cloud.bolt.rain.fill"
        case "13d", "13n": return "cloud.snow.fill"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "questionmark.circle"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
