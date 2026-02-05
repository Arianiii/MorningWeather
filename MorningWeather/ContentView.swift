
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

struct ContentView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    
    @StateObject private var weatherService = WeatherService()
    @State private var selectedLocation: MKPlacemark? = nil

    var body: some View {
        ZStack {
            if let weather = weatherService.weatherData, weather.isDaytime {
                LinearGradient(colors: [Color(hex: "87CEEB"), Color(hex: "B0E0E6")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            } else if let weather = weatherService.weatherData, !weather.isDaytime {
                LinearGradient(colors: [Color(hex: "1A2033"), Color(hex: "3D4A6C")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
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
        }
        .onAppear {
            // 1. Request Notification Authorization when the app appears
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    print("Notification authorization granted.")
                } else if let error = error {
                    print("Notification authorization denied: \(error.localizedDescription)")
                }
            }
            
            // 2. Automatically fetch current location weather when the view appears
            if selectedLocation == nil {
                weatherService.fetchCurrentLocationWeather()
            }
        }
        .onChange(of: searchText, perform: searchLocations)
    }
    
    private var searchSection: some View {
        VStack {
            Spacer()
            Text("Find Your Weather").font(.largeTitle).bold().foregroundColor(.white)
            if weatherService.isLoadingLocation {
                ProgressView().tint(.white)
                Text("Getting your current location...").foregroundColor(.white.opacity(0.8))
            } else {
                TextField("Search for a city...", text: $searchText).textFieldStyle(.roundedBorder).padding(.horizontal)
                if !searchResults.isEmpty {
                    List(searchResults) { result in
                        Button(action: { selectLocation(result.placemark) }) {
                            Text(result.placemark.title ?? "Unknown")
                        }
                    }
                    .listStyle(.plain).cornerRadius(10).padding(.horizontal)
                }
            }
            Spacer()
        }
    }
    
    private var weatherDisplay: some View {
        VStack(spacing: 10) {
            if let errorMessage = weatherService.errorMessage {
                Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundColor(.yellow)
                Text("Error").font(.largeTitle)
                Text(errorMessage).multilineTextAlignment(.center).padding()
                Button("Try Again") {
                    if selectedLocation == nil {
                        weatherService.fetchCurrentLocationWeather()
                    } else if let location = selectedLocation?.location {
                        Task { await weatherService.fetchWeather(for: location) }
                    }
                }
                .buttonStyle(.borderedProminent)
                
            } else if let weather = weatherService.weatherData, let locationName = selectedLocation?.title ?? Optional(weather.name) {
                Text(locationName).font(.largeTitle).padding(.top)
                if let condition = weather.weather.first?.main {
                    WeatherAnimationView(openWeatherConditionMain: condition)
                        .frame(height: 200)
                }
                Text("\(Int(weather.main.temp))°C").font(.system(size: 60, weight: .bold))
                Text(weather.weather.first?.description ?? "").font(.headline)
                Text("Feels like: \(Int(weather.main.feels_like))°C").font(.subheadline).opacity(0.8)
                
            } else if weatherService.isLoadingLocation {
                ProgressView().tint(.white)
                Text("Getting your current location...")
            }
            else {
                ProgressView().tint(.white)
                Text("Fetching weather...")
            }
            
            Spacer()
            Button("Change Location") {
                withAnimation { selectedLocation = nil; searchText = ""; weatherService.errorMessage = nil; weatherService.weatherData = nil }
            }
            .padding()
        }
        .foregroundColor(.white)
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
