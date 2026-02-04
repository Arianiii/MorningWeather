
import SwiftUI
import MapKit
import Lottie
import WeatherKit // <-- THE MISSING IMPORT

// --- HELPER VIEWS ---

// A simple struct to hold the results of our location search
struct SearchResult: Identifiable {
    let id = UUID()
    let placemark: MKPlacemark
}

// A helper view to easily use Lottie animations
struct LottieView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode

    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.play()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        return view
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
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
            return "weather_cloudy"
        }
    }
}


// --- MAIN VIEW ---

struct ContentView: View {
    // State for the search text and search results
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    
    // State to hold the currently selected location's weather
    @StateObject private var weatherService = WeatherService()
    @State private var selectedLocationName: String?
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "3d4a6c"), Color(hex: "1a2033")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if selectedLocationName == nil {
                    searchSection
                } else {
                    weatherDisplay
                }
            }
        }
        .onChange(of: searchText) { newValue in
            searchLocations(query: newValue)
        }
    }
    
    // --- SUBVIEWS ---
    
    private var searchSection: some View {
        VStack {
            Spacer()
            TextField("Search for a city...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()

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
        .transition(.opacity)
    }
    
    private var weatherDisplay: some View {
        VStack(spacing: 10) {
            if let weather = weatherService.weather, let locationName = selectedLocationName {
                Text(locationName)
                    .font(.largeTitle)
                    .padding(.top)
                
                WeatherAnimationView(condition: weather.currentWeather.condition)
                    .frame(height: 200)
                
                Text("\(weather.currentWeather.temperature.formatted())")
                    .font(.system(size: 60, weight: .bold))
                
                Text(weather.currentWeather.condition.description)
                    .font(.headline)
                
                Spacer()
                
                Button("Change Location") {
                    withAnimation {
                        selectedLocationName = nil
                        weatherService.weather = nil
                        searchText = ""
                    }
                }
                .padding()

            } else {
                Spacer()
                ProgressView()
                    .tint(.white)
                Text("Fetching weather...")
                Spacer()
            }
        }
        .foregroundColor(.white)
        .transition(.opacity)
    }
    
    // --- LOGIC ---
    
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
    
    private func selectLocation(_ placemark: MKPlacemark) {
        guard let location = placemark.location else { return }
        
        withAnimation {
            self.selectedLocationName = placemark.title
            self.searchResults = []
            self.searchText = ""
            
            Task {
                await weatherService.fetchWeather(for: location)
            }
        }
    }
}

// --- EXTENSIONS ---

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
