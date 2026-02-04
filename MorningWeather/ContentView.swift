
import SwiftUI
import MapKit

// This view is also very clean and uses helpers from Helpers.swift.
struct ContentView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    
    @StateObject private var weatherService = WeatherService()
    @State private var selectedLocation: MKPlacemark?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "3d4a6c"), Color(hex: "1a2033")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if selectedLocation == nil {
                    searchSection
                } else {
                    weatherDisplay
                }
            }
        }
        .onChange(of: searchText, perform: searchLocations)
    }
    
    private var searchSection: some View {
        VStack {
            Spacer()
            Text("Find Your Weather").font(.largeTitle).bold().foregroundColor(.white)
            TextField("Search for a city...", text: $searchText).textFieldStyle(.roundedBorder).padding(.horizontal)
            if !searchResults.isEmpty {
                List(searchResults) { result in
                    Button(action: { selectLocation(result.placemark) }) {
                        Text(result.placemark.title ?? "Unknown")
                    }
                }
                .listStyle(.plain).cornerRadius(10).padding(.horizontal)
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
                    if let location = selectedLocation?.location {
                        Task { await weatherService.fetchWeather(for: location) }
                    }
                }
                .buttonStyle(.borderedProminent)
            } else if let weather = weatherService.weather, let locationName = selectedLocation?.title {
                Text(locationName).font(.largeTitle).padding(.top)
                WeatherAnimationView(condition: weather.currentWeather.condition).frame(height: 200) // Lottie animation
                Text(weather.currentWeather.temperature.formatted()).font(.system(size: 60, weight: .bold))
                Text(weather.currentWeather.condition.description).font(.headline)
            } else {
                ProgressView().tint(.white)
                Text("Fetching weather...")
            }
            Spacer()
            Button("Change Location") { withAnimation { selectedLocation = nil; searchText = "" } }.padding()
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
