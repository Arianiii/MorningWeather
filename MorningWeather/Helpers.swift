
import SwiftUI
import MapKit
import Lottie
import CoreLocation
import Foundation

// MARK: - Weather Service (using OpenWeatherMap)
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var weatherData: OpenWeatherResponse?
    @Published var errorMessage: String?
    @Published var isLoadingLocation = false

    private let apiKey = "dca771ea4f512ddfece257fb57686565"
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func fetchCurrentLocationWeather() {
        isLoadingLocation = true
        // Request location only if authorized. Otherwise, authorization status will change and trigger requestLocation
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
        // If not authorized, locationManagerDidChangeAuthorization will handle it after a status change
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // --- FIXED: Request location immediately once authorized ---
            manager.requestLocation()
            self.errorMessage = nil // Clear any previous location denial error
        case .denied, .restricted:
            self.errorMessage = "Location access denied. Please enable in Settings for current weather."
            isLoadingLocation = false
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            self.errorMessage = "Unknown location authorization status."
            isLoadingLocation = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLoadingLocation = false
        guard let location = locations.first else {
            self.errorMessage = "Could not determine current location."
            return
        }
        Task { await fetchWeather(for: location) }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoadingLocation = false
        print("Location Manager Error: \(error.localizedDescription)")
        self.errorMessage = "Failed to get current location: \(error.localizedDescription)"
    }

    func fetchWeather(for location: CLLocation) async {
        self.weatherData = nil
        self.errorMessage = nil
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid API URL."
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("OpenWeatherMap Error: HTTP Status \(status)")
                self.errorMessage = "Failed to fetch weather. Check API key or network connection. Status: \(status)"
                return
            }
            
            let decodedResponse = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
            self.weatherData = decodedResponse
            
        } catch {
            print("OpenWeatherMap Decoding/Network Error: \(error.localizedDescription)")
            self.errorMessage = "Failed to decode weather data or network error. Details: \(error.localizedDescription)"
        }
    }
}

// MARK: - OpenWeatherMap Data Models
struct OpenWeatherResponse: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
    let sys: Sys

    struct Main: Codable {
        let temp: Double
        let feels_like: Double
        let temp_min: Double
        let temp_max: Double
    }

    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct Sys: Codable {
        let sunrise: Date
        let sunset: Date
    }
    
    var isDaytime: Bool {
        let now = Date()
        return now >= sys.sunrise && now < sys.sunset
    }
}

// MARK: - Data Models (Existing)
struct SearchResult: Identifiable {
    let id = UUID()
    let placemark: MKPlacemark
}

// MARK: - Helper Views (Existing)
struct LottieView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFill
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

// A view that shows a Lottie animation based on the weather condition
struct WeatherAnimationView: View {
    let openWeatherConditionMain: String

    var body: some View {
        LottieView(name: animationName, loopMode: .loop)
    }
    
    private var animationName: String {
        switch openWeatherConditionMain.lowercased() {
        case "clear", "sunny": return "Weather-sunny"
        case "clouds", "cloudy", "fog": return "Weather-windy"
        case "rain", "drizzle", "thunderstorm": return "Weather-night"
        case "snow": return "Weather-night"
        default: return "Weather-windy"
        }
    }
}

struct FloatingIcon: View {
    @State private var isAnimating = false
    let iconName: String, size: CGFloat, duration: Double, startX: CGFloat, startY: CGFloat, endX: CGFloat, endY: CGFloat

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size))
            .foregroundColor(.white.opacity(0.8))
            .shadow(radius: 5)
            .position(x: isAnimating ? endX : startX, y: isAnimating ? endY : startY)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(duration * Double.random(in: 0...1))) {
                    isAnimating = true
                }
            }
    }
}


// MARK: - Extensions (Existing)
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(red: Double((rgb >> 16) & 0xFF) / 255.0, green: Double((rgb >> 8) & 0xFF) / 255.0, blue: Double(rgb & 0xFF) / 255.0)
    }
}

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
