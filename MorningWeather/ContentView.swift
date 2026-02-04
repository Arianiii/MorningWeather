
import SwiftUI
import MapKit // We need MapKit for location search
import Lottie // We will use Lottie for the weather animations

// A simple struct to hold the results of our location search
struct SearchResult: Identifiable {
    let id = UUID()
    let placemark: MKPlacemark
}

// A view that shows a Lottie animation based on the weather condition
struct WeatherAnimationView: View {
    let condition: WeatherCondition

    var body: some View {
        LottieView(name: animationName, loopMode: .loop)
    }
    
    // A helper to map WeatherKit conditions to our Lottie file names
    private var animationName: String {
        switch condition {
        case .clear, .mostlyClear, .hot:
            return "weather_sunny"
        case .cloudy, .mostlyCloudy, .foggy, .partlyCloudy:
            return "weather_cloudy"
        case .rain, .heavyRain, .strongStorms, .isolatedThunderstorms:
            return "weather_rainy"
        case .snow, .heavySnow, .blizzard, .flurries:
            return "weather_snowy"
        default:
            // A sensible default
            return "weather_cloudy"
        }
    }
}


struct ContentView: View {
    // State for the search text and search results
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    
    // State to hold the currently selected location's weather
    @StateObject private var weatherService = WeatherService()
    @State private var selectedLocationName: String?
    
    var body: some View {
        ZStack {
            // A dynamic gradient that could change with the weather later
            LinearGradient(
                colors: [Color(hex: "3d4a6c"), Color(hex: "1a2033")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // --- MAIN UI LOGIC ---
            VStack(spacing: 20) {
                // If no location is selected, show the search UI
                if selectedLocationName == nil {
                    searchSection
                } else {
                    // Otherwise, show the weather display
                    weatherDisplay
                }
            }
        }
        // When searchText changes, perform a search
        .onChange(of: searchText) { newValue in
            searchLocations(query: newValue)
        }
    }
    
    // --- SUBVIEWS ---
    
    // The UI for searching for a location
    private var searchSection: some View {
        VStack {
            Spacer()
            TextField("Search for a city...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()

            // Display search results
            if !searchResults.isEmpty {
                List(searchResults) { result in
                    Button(action: {
                        selectLocation(result.placemark)
                    }) {
                        Text(result.placemark.title ?? "Unknown Location")
                    }
                }
                .listStyle(.plain)
            }
            Spacer()
        }
        .transition(.opacity) // Animate the appearance/disappearance
    }
    
    // The UI for displaying the weather
    private var weatherDisplay: some View {
        VStack {
            // A button to go back to search
            Button("Change Location") {
                withAnimation {
                    selectedLocationName = nil
                    weatherService.weather = nil // Clear old weather data
                    searchText = ""
                }
            }
            .padding()

            if let weather = weatherService.weather, let locationName = selectedLocationName {
                Text(locationName)
                    .font(.largeTitle)
                
                WeatherAnimationView(condition: weather.currentWeather.condition)
                    .frame(height: 200)
                
                Text("\(weather.currentWeather.temperature.formatted())")
                    .font(.system(size: 60, weight: .bold))
                
                Text(weather.currentWeather.condition.description)
            } else {
                ProgressView() // Show while loading weather
            }
            Spacer()
        }
        .foregroundColor(.white)
        .transition(.opacity) // Animate the appearance/disappearance
    }
    
    // --- LOGIC ---
    
    // Performs a location search using MapKit
    private func searchLocations(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                self.searchResults = []
                return
            }
            self.searchResults = response.mapItems.map { SearchResult(placemark: $0.placemark) }
        }
    }
    
    // Handles selecting a location from the search results
    private func selectLocation(_ placemark: MKPlacemark) {
        guard let location = placemark.location else { return }
        
        withAnimation {
            self.selectedLocationName = placemark.title
            self.searchResults = []
            self.searchText = ""
            
            // Fetch weather for the selected location
            Task {
                await weatherService.fetchWeather(for: location)
            }
        }
    }
}

// We need this for the placemark's title property
extension MKPlacemark {
    var title: String? {
        let name = self.name ?? ""
        let locality = self.locality ?? ""
        let country = self.countryCode ?? ""
        
        if !name.isEmpty {
            return "\(name), \(country)"
        }
        if !locality.isEmpty {
            return "\(locality), \(country)"
        }
        return country
    }
}
