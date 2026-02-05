
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

// --- NEW: Dynamic Background View (Moved here from Helpers) ---
struct DynamicBackgroundView: View {
    let condition: String
    let isDaytime: Bool
    
    var body: some View {
        ZStack {
            // 1. Base Gradient
            LinearGradient(colors: getColors(), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            // 2. Atmospheric Animation (Rain/Snow)
            // Using a simple check to determine if the atmospheric animation is needed
            if condition.contains("rain") || condition.contains("drizzle") {
                LottieView(name: "Weather-night", loopMode: .loop) // Using night as rain placeholder
                    .scaleEffect(1.5)
                    .opacity(0.4)
                    .ignoresSafeArea()
            } else if condition.contains("snow") {
                LottieView(name: "Weather-night", loopMode: .loop) // Using night as snow placeholder
                    .scaleEffect(1.5)
                    .opacity(0.4)
                    .ignoresSafeArea()
            }
        }
    }
    
    func getColors() -> [Color] {
        if !isDaytime {
            // Night Colors
            return [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")] 
        }
        
        switch condition {
        case let s where s.contains("rain") || s.contains("drizzle"):
            return [Color(hex: "3a566b"), Color(hex: "2f4353")] // Rainy Grey/Blue
        case let s where s.contains("snow"):
            return [Color(hex: "83a4d4"), Color(hex: "b6fbff")] // Frosty Blue
        case let s where s.contains("cloud"):
            return [Color(hex: "5f7893"), Color(hex: "879bb1")] // Cloudy Blue
        case let s where s.contains("clear") || s.contains("sun"):
            return [Color(hex: "2980B9"), Color(hex: "6DD5FA")] // Bright Sunny Blue
        default:
            return [Color(hex: "87CEEB"), Color(hex: "B0E0E6")] // Default Day
        }
    }
}
// --- END Dynamic Background View ---


struct ContentView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    
    @StateObject private var weatherService = WeatherService()
    @State private var selectedLocation: MKPlacemark? = nil

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
            .transition(.opacity) // Smooth transition between search and display
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    print("Notification authorization granted.")
                } else if let error = error {
                    print("Notification authorization denied: \(error.localizedDescription)")
                }
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
                .background(.ultraThinMaterial) // Glassy Search Bar
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
                    }
                    .padding().background(.white.opacity(0.2)).cornerRadius(10)
                }
                .foregroundColor(.white).padding().background(.ultraThinMaterial).cornerRadius(20).padding()
                
            } else if let weather = weatherService.weatherData, let locationName = selectedLocation?.title ?? Optional(weather.name) {
                // Use the new WeatherCardView here
                WeatherCardView(weather: weather, locationName: locationName)
                    .transition(.scale.combined(with: .opacity))
                
            } else if weatherService.isLoadingLocation {
                ProgressView().tint(.white).scaleEffect(1.5)
                Text("Getting your current location...").foregroundColor(.white).padding(.top, 10)
            }
            else {
                ProgressView().tint(.white).scaleEffect(1.5)
                Text("Fetching weather...").foregroundColor(.white).padding(.top, 10)
            }
            
            Spacer()
            
            if weatherService.weatherData != nil {
                Button(action: {
                    withAnimation {
                        selectedLocation = nil
                        searchText = ""
                        weatherService.errorMessage = nil
                        weatherService.weatherData = nil
                    }
                }) {
                    Image(systemName: "magnifyingglass.circle.fill").font(.system(size: 50)).foregroundColor(.white.opacity(0.8)).background(Color.black.opacity(0.2)).clipShape(Circle())
                }
                .padding(.bottom, 30)
            }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
