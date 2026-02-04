
import SwiftUI
import MapKit
import Lottie
import CoreLocation // Needed for CLLocation

// MARK: - Weather Service (using OpenWeatherMap)
@MainActor
class WeatherService: ObservableObject {
    @Published var weatherData: OpenWeatherResponse? // Holds raw data from OpenWeatherMap
    @Published var errorMessage: String? // To hold error messages

    private let apiKey = "dca771ea4f512ddfece257fb57686565" // Your OpenWeatherMap API Key

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
// Structure to match the OpenWeatherMap API response for current weather
struct OpenWeatherResponse: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
    let sys: Sys // Added for sunrise/sunset times

    struct Main: Codable {
        let temp: Double
        let feels_like: Double
        let temp_min: Double
        let temp_max: Double
    }

    struct Weather: Codable {
        let id: Int
        let main: String // e.g., "Clear", "Clouds", "Rain"
        let description: String // e.g., "clear sky", "few clouds"
        let icon: String // e.g., "01d", "04n"
    }
    
    struct Sys: Codable {
        let sunrise: Date // Unix timestamp
        let sunset: Date // Unix timestamp
    }
    
    // Helper to determine if it's daytime based on sunrise/sunset
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
        animationView.contentMode = .scaleAspectFill // Changed to fill for background animations
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

// A view that shows a Lottie animation based on the weather condition and time of day
struct WeatherAnimationView: View {
    let openWeatherConditionMain: String // e.g., "Clouds", "Rain", "Clear"
    let isDaytime: Bool

    var body: some View {
        LottieView(name: animationName, loopMode: .loop)
    }
    
    // Helper to map OpenWeatherMap conditions to our Lottie file names
    private var animationName: String {
        let baseName: String
        switch openWeatherConditionMain.lowercased() {
        case "clear", "sunny": baseName = "weather_sunny"
        case "clouds", "cloudy", "fog": baseName = "weather_cloudy"
        case "rain", "drizzle", "thunderstorm": baseName = "weather_rainy"
        case "snow": baseName = "weather_snowy"
        default: baseName = "weather_cloudy"
        }
        return "\(baseName)\(isDaytime ? "_day" : "_night")"
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
