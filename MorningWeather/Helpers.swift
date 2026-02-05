
import SwiftUI
import MapKit
import Lottie
import CoreLocation
import Foundation
import UserNotifications

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    // Request notification authorization
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification authorization granted.")
            } else if let error = error {
                print("Notification authorization denied: \(error.localizedDescription)")
            }
        }
    }
    
    // Schedule a daily morning weather notification
    func scheduleDailyWeatherNotification(for location: CLLocation, weatherData: OpenWeatherResponse) {
        // Check if authorization is granted before scheduling
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Good Morning! ☀️"
            
            // Customize message based on weather and time of day
            var bodyMessage: String
            let mainCondition = weatherData.weather.first?.main.lowercased() ?? "clear"
            let temp = Int(weatherData.main.temp)
            let locationName = weatherData.name
            
            let hour = Calendar.current.component(.hour, from: Date())
            
            if hour < 12 { // Morning
                bodyMessage = "It's \(temp)°C in \(locationName). Expect \(mainCondition). Have a great morning!"
            } else if hour < 18 { // Afternoon
                bodyMessage = "Current weather in \(locationName): \(temp)°C and \(mainCondition). Enjoy your afternoon!"
            }
            else if hour < 20 { // Evening
                bodyMessage = "Current weather in \(locationName): \(temp)°C and \(mainCondition). Enjoy your evening!"
            } else { // Night
                bodyMessage = "\(locationName) is \(temp)°C with \(mainCondition). Wishing you a good night!"
            }
            
            content.body = bodyMessage
            content.sound = .default
            
            // Schedule for tomorrow morning at 8 AM
            var dateComponents = DateComponents()
            dateComponents.hour = 8
            dateComponents.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("Daily weather notification scheduled.")
                }
            }
        }
    }
    
    // Clear pending notifications (e.g., if user changes location)
    func clearPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All pending notifications cleared.")
    }
}

// MARK: - Weather Service (using OpenWeatherMap)
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var weatherData: OpenWeatherResponse?
    @Published var errorMessage: String?
    @Published var isLoadingLocation = false

    private let apiKey = "dca771ea4f512ddfece257fb57686565"
    let locationManager = CLLocationManager() // Made internal to be accessible from MorningWeatherApp
    
    override init() {
        super.init()
        self.locationManager.delegate = self
    }

    // NEW PUBLIC FUNCTION TO REQUEST AUTHORIZATION
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func fetchCurrentLocationWeather() {
        isLoadingLocation = true
        self.errorMessage = nil // Clear previous errors
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
            // If not determined, request authorization explicitly (will trigger didChangeAuthorization)
            requestLocationAuthorization()
        case .denied, .restricted:
            self.errorMessage = "Location access denied. Please enable in Settings for current weather."
            isLoadingLocation = false
        @unknown default:
            self.errorMessage = "Unknown location authorization status."
            isLoadingLocation = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
            self.errorMessage = nil
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
        isLoadingLocation = false // Ensure loading state is reset here
        guard let location = locations.first else {
            self.errorMessage = "Could not determine current location."
            return
        }
        Task { await fetchWeather(for: location) }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoadingLocation = false // Ensure loading state is reset here
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
// FIX 1: Simplify Main struct to include all necessary data and remove MainDetails/CodingKeys
struct OpenWeatherResponse: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
    let sys: Sys
    let wind: Wind 
    let visibility: Int? 

    struct Main: Codable {
        let temp: Double
        let feels_like: Double
        let temp_min: Double
        let temp_max: Double
        let pressure: Int // ADDED
        let humidity: Int // ADDED
    }

    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct Wind: Codable {
        let speed: Double
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

// --- NEW: Weather Card View with Detail Grid ---
struct WeatherCardView: View {
    let weather: OpenWeatherResponse
    let locationName: String

    var body: some View {
        VStack(spacing: 15) {
            Text(locationName)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .shadow(radius: 5)
            
            // Weather Animation
            if let condition = weather.weather.first?.main {
                WeatherAnimationView(openWeatherConditionMain: condition)
                    .frame(height: 180)
            }
            
            // Current Temperature
            Text("\(Int(weather.main.temp))°C")
                .font(.system(size: 90, weight: .thin))
                .foregroundColor(.white)
                .shadow(radius: 5)
            
            // Description
            Text(weather.weather.first?.description.capitalized ?? "")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, 20)

            // Detail Grid (New Design)
            VStack(spacing: 10) {
                HStack {
                    DetailItem(icon: "humidity.fill", label: "Humidity", value: "\(weather.main.humidity)%") // FIX 2: Accessing data correctly
                    DetailItem(icon: "gauge", label: "Pressure", value: "\(weather.main.pressure) hPa") // FIX 2: Accessing data correctly
                }
                HStack {
                    DetailItem(icon: "wind", label: "Wind Speed", value: "\(Int(weather.wind.speed * 3.6)) km/h") // Convert m/s to km/h
                    DetailItem(icon: "eye.fill", label: "Visibility", value: "\(weather.visibility.map { "\($0 / 1000) km" } ?? "N/A")")
                }
            }
            .padding(10)
            .background(.ultraThinMaterial) // The glassy effect for the details
            .cornerRadius(15)
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.horizontal)
    }
}

// Helper for the detail grid
struct DetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title3)
            Text(label)
                .font(.caption)
                .opacity(0.8)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(.white)
    }
}


// --- NEW: Custom Splash Screen View ---
struct SplashScreenView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "4a7b9d"), Color(hex: "2a4d69")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Floating icons for visual appeal during splash
            GeometryReader { geo in
                FloatingIcon(iconName: "sun.max.fill", size: 80, duration: 25, startX: geo.size.width * 0.1, startY: geo.size.height * 0.2, endX: geo.size.width * 0.2, endY: geo.size.height * 0.15)
                FloatingIcon(iconName: "cloud.fill", size: 60, duration: 30, startX: geo.size.width * 0.8, startY: geo.size.height * 0.3, endX: geo.size.width * 0.7, endY: geo.size.height * 0.35)
                FloatingIcon(iconName: "cloud.drizzle.fill", size: 40, duration: 20, startX: geo.size.width * 0.2, startY: geo.size.height * 0.8, endX: geo.size.width * 0.3, endY: geo.size.height * 0.85)
            }
            
            VStack {
                Spacer()
                Image(systemName: "cloud.sun.fill") // A central icon for the splash screen
                    .font(.system(size: 150))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                Text("MorningWeather")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
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
