
import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

struct ContentView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    
    @StateObject private var weatherService = WeatherService()
    @EnvironmentObject private var savedLocationManager: LocationManager
    @State private var selectedLocation: MKPlacemark? = nil
    
    @State private var isAnimating = false
    @State private var showSavedLocations = false
    @State private var showAlarmSettings = false // State for showing alarm settings

    var body: some View {
        ZStack {
            // ... (Background remains the same) ...
            
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
            // ... (OnAppear logic remains the same) ...
        }
        .onChange(of: searchText, perform: searchLocations)
        .sheet(isPresented: $showSavedLocations) {
            ManageLocationsView()
                .environmentObject(savedLocationManager)
        }
        .sheet(isPresented: $showAlarmSettings) { // Attach new alarm sheet
            AlarmSettingsView()
                .environmentObject(savedLocationManager)
        }
    }
    
    private var searchSection: some View {
        // ... (Implementation remains the same) ...
    }
    
    private var weatherDisplay: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ... (Error or Weather Data Display) ...
                
                if let weather = weatherService.weatherData, let locationName = selectedLocation?.title ?? Optional(weather.name) {
                    
                    // --- NEW: Header with Alarm and Location Buttons ---
                    HStack {
                        // Button to manage saved locations
                        Button(action: { showSavedLocations = true }) {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Location Name
                        Text(locationName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                        
                        // Button to set weather alarm
                        Button(action: { showAlarmSettings = true }) {
                            Image(systemName: "alarm.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 40) // Push down from safe area

                    // --- END NEW HEADER ---

                    WeatherCardView(weather: weather, locationName: locationName)
                        // ... (Animation modifiers) ...
                    
                    if let forecast = weatherService.forecastData {
                        HourlyForecastView(forecastList: forecast.list)
                        DailyForecastView(forecastList: forecast.list)
                    }
                }
                
                // ... (Search button at the bottom) ...
                
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
    
    // ... (searchLocations and selectLocation functions remain the same) ...
}

// NOTE: All helper views like ManageLocationsView, AlarmSettingsView, DynamicBackgroundView, etc., are in Helpers.swift, but AlarmSettingsView is complex enough to merit its own file, which I'll keep here for the final push.
