
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

struct ContentView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    
    @StateObject private var weatherService = WeatherService()
    @StateObject private var savedLocationManager = LocationManager() // Phase 2: Location Manager
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
            // Load last viewed location on startup
            if let lastLocation = savedLocationManager.getLastViewedLocation() {
                let coordinate = CLLocationCoordinate2D(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
                let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
                self.selectedLocation = placemark
                Task { await weatherService.fetchWeather(for: placemark.location!) }
            } else {
                // Initial check for current location if no last location is saved
                 weatherService.fetchCurrentLocationWeather()
            }
        }
        .onChange(of: searchText, perform: searchLocations)
    }
    
    // ... (searchSection, weatherDisplay, searchLocations, selectLocation functions remain mostly the same, but integrate LocationManager) ...
    
    // ... (Existing implementation of searchSection, weatherDisplay, searchLocations, selectLocation moved here) ...
}

// ... (DynamicBackgroundView and other helper views and extensions remain the same) ...

// NEW: Location List View for Phase 2
struct LocationListView: View {
    @ObservedObject var locationManager: LocationManager
    // Add logic here to display the list of saved locations
    var body: some View {
        Text("Saved Locations List View (Under Development)")
    }
}
