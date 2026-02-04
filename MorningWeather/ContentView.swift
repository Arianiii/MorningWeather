
import SwiftUI
import MapKit
import Lottie
import WeatherKit

// --- DATA MODELS & HELPERS ---

struct SearchResult: Identifiable {
    let id = UUID()
    let placemark: MKPlacemark
}

// --- SERVICE CLASS (Now self-contained) ---

@MainActor
class WeatherService: ObservableObject {
    @Published var weather: Weather?
    @Published var errorMessage: String? // To hold error messages

    private let service = WeatherKit.WeatherService.shared

    func fetchWeather(for location: CLLocation) async {
        // Reset state before a new request
        self.weather = nil
        self.errorMessage = nil
        
        do {
            let result = try await service.weather(for: location)
            self.weather = result
        } catch {
            // If an error occurs, save the message
            print("WeatherKit Error: \(error.localizedDescription)")
            self.errorMessage = "Failed to fetch weather data. Please ensure WeatherKit is enabled in your project's capabilities and try again."
        }
    }
}

// --- VIEWS ---

struct LottieView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.play()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct WeatherAnimationView: View {
    let condition: WeatherCondition

    var body: some View {
        LottieView(name: animationName, loopMode: .loop)
    }
    
    private var animationName: String {
        switch condition {
        case .clear, .mostlyClear, .hot: return "weather_sunny"
        case .cloudy, .mostlyCloudy, .foggy, .partlyCloudy: return "weather_cloudy"
        case .rain, .heavyRain, .strongStorms, .isolatedThunderstorms: return "weather_rainy"
        case .snow, .heavySnow, .blizzard, .flurries: return "weather_snowy"
        default: return "weather_cloudy"
        }
    }
}

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
        // This view remains largely the same
        VStack {
            Spacer()
            Text("Find Your Weather")
                .font(.largeTitle).bold()
                .foregroundColor(.white)
            
            TextField("Search for a city...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

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
            // ** NEW LOGIC: Check for error first, then weather, then show loading **
            if let errorMessage = weatherService.errorMessage {
                // Display the error message
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                Text("Error")
                    .font(.largeTitle)
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Try Again") {
                    if let location = selectedLocation?.location {
                        Task { await weatherService.fetchWeather(for: location) }
                    }
                }
                .buttonStyle(.borderedProminent)
                
            } else if let weather = weatherService.weather, let locationName = selectedLocation?.title {
                // Display the weather (as before)
                Text(locationName).font(.largeTitle).padding(.top)
                WeatherAnimationView(condition: weather.currentWeather.condition).frame(height: 200)
                Text(weather.currentWeather.temperature.formatted()).font(.system(size: 60, weight: .bold))
                Text(weather.currentWeather.condition.description).font(.headline)
                
            } else {
                // Display the loading indicator
                ProgressView().tint(.white)
                Text("Fetching weather...")
            }
            
            Spacer()
            Button("Change Location") {
                withAnimation { selectedLocation = nil; searchText = "" }
            }
            .padding()
        }
        .foregroundColor(.white)
    }
    
    private func searchLocations(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
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


// --- EXTENSIONS ---

extension MKPlacemark {
    var title: String? {
        let name = self.name ?? ""
        let locality = self.locality ?? ""
        let country = self.countryCode ?? ""
        if !name.isEmpty { return "\(name), \(country)" }
        if !locality.isEmpty { return "\(locality), \(country)" }
        return country
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double((rgb >> 0) & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
