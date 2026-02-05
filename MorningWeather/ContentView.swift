
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

// NOTE: All structs and classes for WeatherService, LocationManager, etc., are now in Helpers.swift

// Defensive addition: Re-introduce SearchResult struct locally to fix scope issues
struct SearchResult: Identifiable {
    let id = UUID()
    let placemark: MKPlacemark
}

struct ContentView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    
    @StateObject private var weatherService = WeatherService()
    @EnvironmentObject private var savedLocationManager: LocationManager
    @State private var selectedLocation: MKPlacemark? = nil
    
    @State private var isAnimating = false
    @State private var showSavedLocations = false
    @State private var showAlarmSettings = false

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
            if let lastLocation = savedLocationManager.getLastViewedLocation() {
                let coordinate = CLLocationCoordinate2D(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
                let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
                self.selectedLocation = placemark
                Task { await weatherService.fetchWeather(for: placemark.location!) }
            } else {
                 weatherService.fetchCurrentLocationWeather()
            }
        }
        .onChange(of: searchText, perform: searchLocations)
        .sheet(isPresented: $showSavedLocations) {
            ManageLocationsView()
                .environmentObject(savedLocationManager)
        }
        .sheet(isPresented: $showAlarmSettings) {
            AlarmSettingsView()
                .environmentObject(savedLocationManager)
        }
    }
    
    private var searchSection: some View {
        VStack {
            Spacer()
            Text("Find Your Weather").font(.largeTitle).bold().foregroundColor(.white).shadow(radius: 5)
            
            if weatherService.isLoadingLocation && weatherService.errorMessage == nil {
                ProgressView().tint(.white).scaleEffect(1.5)
                Text("Getting your current location...").foregroundColor(.white.opacity(0.8))
            } else {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.6))
                    TextField("Search for a city...", text: $searchText).foregroundColor(.white).accentColor(.white)
                }
                .padding().background(.ultraThinMaterial).cornerRadius(15).padding(.horizontal)
                
                if !searchResults.isEmpty {
                    List(searchResults) { result in
                        Button(action: { selectLocation(result.placemark) }) {
                            Text(result.placemark.title ?? "Unknown").foregroundColor(.primary)
                        }
                    }
                    .listStyle(.plain).background(.ultraThinMaterial).cornerRadius(10).padding(.horizontal).frame(maxHeight: 300)
                }
                
                Button(action: { withAnimation { weatherService.fetchCurrentLocationWeather() } }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Use Current Location")
                    }
                    .fontWeight(.semibold).frame(maxWidth: .infinity).padding().background(Color.white.opacity(0.2)).foregroundColor(.white).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.5), lineWidth: 1))
                }
                .padding(.top, 10).padding(.horizontal)
            }
            Spacer()
        }
    }
    
    private var weatherDisplay: some View {
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
                    
                    // --- NEW: Header with Alarm and Location Buttons ---
                    HStack {
                        Button(action: { showSavedLocations = true }) {
                            Image(systemName: "list.bullet").font(.title2).foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text(locationName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                        
                        Button(action: { showAlarmSettings = true }) {
                            Image(systemName: "alarm.fill").font(.title2).foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 40) // Push down from safe area

                    // --- END NEW HEADER ---

                    WeatherCardView(weather: weather, locationName: locationName)
                        .transition(.scale.combined(with: .opacity))
                        .scaleEffect(isAnimating ? 1.01 : 1.0)
                        .rotationEffect(.degrees(isAnimating ? 0.5 : -0.5))
                        .onAppear { withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) { isAnimating = true } }
                    
                    if let forecast = weatherService.forecastData {
                        HourlyForecastView(forecastList: forecast.list)
                        DailyForecastView(forecastList: forecast.list)
                    }
                    
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
