
import SwiftUI
import MapKit
import Lottie
import CoreLocation
import Foundation
import UserNotifications

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted { print("Notification authorization granted.") }
        }
    }
    
    func scheduleDailyWeatherNotification(for location: CLLocation, weatherData: OpenWeatherResponse) {
        clearPendingNotifications()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "Good Morning! ☀️"
            
            let bodyMessage: String; let mainCondition = weatherData.weather.first?.main.lowercased() ?? "clear"
            let temp = Int(weatherData.main.temp); let locationName = weatherData.name
            let hour = Calendar.current.component(.hour, from: Date())
            
            if hour < 12 { bodyMessage = "It's \(temp)°C in \(locationName). Expect \(mainCondition). Have a great morning!" }
            else if hour < 18 { bodyMessage = "Current weather in \(locationName): \(temp)°C and \(mainCondition). Enjoy your afternoon!" }
            else if hour < 20 { bodyMessage = "Current weather in \(locationName): \(temp)°C and \(mainCondition). Enjoy your evening!" }
            else { bodyMessage = "\(locationName) is \(temp)°C with \(mainCondition). Wishing you a good night!" }
            
            content.body = bodyMessage; content.sound = .default
            
            var dateComponents = DateComponents(); dateComponents.hour = 8; dateComponents.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }
    
    func scheduleWeatherAlarm(at time: Date, for condition: String, location: SavedLocation) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["WEATHER_ALARM_\(location.name)"])
        
        let content = UNMutableNotificationContent()
        content.title = "Weather Alarm! 🚨"
        content.body = "The alarm for \(location.name) is set to check for \(condition) tomorrow morning."
        content.sound = .default
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        dateComponents.weekday = Calendar.current.component(.weekday, from: time.addingTimeInterval(24 * 3600)) // Schedule for the next day
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "WEATHER_ALARM_\(location.name)",
            content: content, 
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { _ in }
    }
    
    func clearPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Location Management
struct SavedLocation: Identifiable, Codable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
}

struct SearchResult: Identifiable {
    let id = UUID()
    let placemark: MKPlacemark
}

class LocationManager: ObservableObject {
    @Published var savedLocations: [SavedLocation] = []
    
    private let userDefaultsKey = "savedWeatherLocations"
    private let lastLocationKey = "lastViewedLocation"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
                savedLocations = decoded
                return
            }
        }
        savedLocations = []
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func addLocation(name: String, coordinate: CLLocationCoordinate2D) {
        let newLocation = SavedLocation(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        if !savedLocations.contains(where: { $0.name == name }) {
            savedLocations.append(newLocation)
            save()
        }
    }
    
    func removeLocation(at offsets: IndexSet) {
        savedLocations.remove(atOffsets: offsets)
        save()
    }
    
    func setLastViewedLocation(name: String, coordinate: CLLocationCoordinate2D) {
        let lastLocation = SavedLocation(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let encoded = try? JSONEncoder().encode(lastLocation) {
            UserDefaults.standard.set(encoded, forKey: lastLocationKey)
        }
    }
    
    func getLastViewedLocation() -> SavedLocation? {
        if let data = UserDefaults.standard.data(forKey: lastLocationKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970 
            return try? decoder.decode(SavedLocation.self, from: data)
        }
        return nil
    }
}


// MARK: - Weather Service (using OpenWeatherMap)
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var weatherData: CurrentWeatherResponse?
    @Published var forecastData: ForecastResponse? 
    @Published var errorMessage: String?
    @Published var isLoadingLocation = false
    @Published var currentCityName: String?

    private let apiKey = "dca771ea4f512ddfece257fb57686565"
    let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        self.locationManager.delegate = self
    }

    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func fetchCurrentLocationWeather() {
        isLoadingLocation = true
        self.errorMessage = nil
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
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
        @unknown default: break
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
        self.errorMessage = "Failed to get current location: \(error.localizedDescription)"
    }

    func fetchWeather(for location: CLLocation) async {
        self.weatherData = nil; self.forecastData = nil; self.errorMessage = nil
        let lat = location.coordinate.latitude; let lon = location.coordinate.longitude
        
        let currentUrlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        let forecastUrlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"

        // 1. Fetch Current Weather
        do {
            guard let url = URL(string: currentUrlString) else { throw URLError(.badURL) }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            
            let decodedResponse = try JSONDecoder().decode(CurrentWeatherResponse.self, from: data)
            self.weatherData = decodedResponse
            NotificationManager().scheduleDailyWeatherNotification(for: location, weatherData: decodedResponse)
            
            LocationManager().setLastViewedLocation(name: decodedResponse.name, coordinate: location.coordinate)
            LocationManager().addLocation(name: decodedResponse.name, coordinate: location.coordinate)

        } catch {
            self.errorMessage = "Failed to fetch current weather. Details: \(error.localizedDescription)"
            return
        }
        
        // 2. Fetch Forecast
        do {
            guard let url = URL(string: forecastUrlString) else { throw URLError(.badURL) }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            
            let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .secondsSince1970 
            let decodedResponse = try decoder.decode(ForecastResponse.self, from: data)
            self.forecastData = decodedResponse
        } catch {
            if self.errorMessage == nil { self.errorMessage = "Failed to fetch forecast data. Details: \(error.localizedDescription)" }
        }
    }
}

// MARK: - OpenWeatherMap Data Models
typealias OpenWeatherResponse = CurrentWeatherResponse
struct CurrentWeatherResponse: Codable {
    let name: String; let main: Main; let weather: [Weather]; let sys: Sys; let wind: Wind; let visibility: Int? 
    struct Main: Codable { let temp: Double; let feels_like: Double; let temp_min: Double; let temp_max: Double; let pressure: Int; let humidity: Int }
    struct Weather: Codable { let id: Int; let main: String; let description: String; let icon: String }
    struct Wind: Codable { let speed: Double }
    struct Sys: Codable { let sunrise: Date; let sunset: Date }
    var isDaytime: Bool { let now = Date(); return now >= sys.sunrise && now < sys.sunset }
}

struct ForecastResponse: Codable { let list: [ForecastItem] }

struct ForecastItem: Codable, Identifiable {
    let dt: Date; let main: CurrentWeatherResponse.Main; let weather: [CurrentWeatherResponse.Weather]
    var id: Date { dt }
    var hour: String { let formatter = DateFormatter(); formatter.dateFormat = "h a"; return formatter.string(from: dt) }
    var day: String { let formatter = DateFormatter(); formatter.dateFormat = "EEE"; return formatter.string(from: dt) }
}

// MARK: - Alarm Structure
struct WeatherAlarm: Codable, Identifiable {
    let id = UUID(); let time: Date; let city: SavedLocation; let condition: String
}

// MARK: - Helper Views

// Dynamic Background View - Provides the glassy gradient and floating icons
struct DynamicBackgroundView: View {
    let condition: String
    let isDaytime: Bool
    
    var gradientColors: [Color] {
        if isDaytime {
            switch condition.lowercased() {
            case "clear", "sunny": return [Color(hex: "4a7b9d"), Color(hex: "2a4d69")] // Light Blue/Dark Blue
            case "clouds", "windy": return [Color(hex: "6c7a89"), Color(hex: "475b6d")] // Gray/Slate
            case "rain", "drizzle", "thunderstorm": return [Color(hex: "485461"), Color(hex: "2c3e50")] // Dark Blue/Gray
            default: return [Color(hex: "4a7b9d"), Color(hex: "2a4d69")]
            }
        } else {
            return [Color(hex: "1a2033"), Color(hex: "0a0f18")] // Very Dark Blue/Black
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            GeometryReader { geo in
                FloatingIcon(iconName: "sun.max.fill", size: 80, duration: 25, startX: geo.size.width * 0.1, startY: geo.size.height * 0.2, endX: geo.size.width * 0.2, endY: geo.size.height * 0.15)
                FloatingIcon(iconName: "cloud.fill", size: 60, duration: 30, startX: geo.size.width * 0.8, startY: geo.size.height * 0.3, endX: geo.size.width * 0.7, endY: geo.size.height * 0.35)
                FloatingIcon(iconName: "cloud.drizzle.fill", size: 40, duration: 20, startX: geo.size.width * 0.2, startY: geo.size.height * 0.8, endX: geo.size.width * 0.3, endY: geo.size.height * 0.85)
            }
        }
    }
}

// Splash Screen View
struct SplashScreenView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "4a7b9d"), Color(hex: "2a4d69")], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            GeometryReader { geo in
                FloatingIcon(iconName: "sun.max.fill", size: 80, duration: 25, startX: geo.size.width * 0.1, startY: geo.size.height * 0.2, endX: geo.size.width * 0.2, endY: geo.size.height * 0.15)
                FloatingIcon(iconName: "cloud.fill", size: 60, duration: 30, startX: geo.size.width * 0.8, startY: geo.size.height * 0.3, endX: geo.size.width * 0.7, endY: geo.size.height * 0.35)
                FloatingIcon(iconName: "cloud.drizzle.fill", size: 40, duration: 20, startX: geo.size.width * 0.2, startY: geo.size.height * 0.8, endX: geo.size.width * 0.3, endY: geo.size.height * 0.85)
            }
            VStack {
                Spacer()
                Image(systemName: "cloud.sun.fill").font(.system(size: 150)).foregroundColor(.white).padding(.bottom, 20)
                Text("MorningWeather").font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                Spacer()
            }
        }
    }
}

// Lottie Animation View
struct LottieView: UIViewRepresentable {
    let name: String; let loopMode: LottieLoopMode

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

// Weather Animation Helper
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

// Floating Icon Helper
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

// Weather Card View
struct WeatherCardView: View {
    let weather: OpenWeatherResponse
    let locationName: String

    var body: some View {
        VStack(spacing: 15) {
            Text(weather.weather.first?.description.capitalized ?? "")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, 20)

            VStack(spacing: 10) {
                HStack {
                    DetailItem(icon: "humidity.fill", label: "Humidity", value: "\(weather.main.humidity)%")
                    DetailItem(icon: "gauge", label: "Pressure", value: "\(weather.main.pressure) hPa")
                }
                HStack {
                    DetailItem(icon: "wind", label: "Wind Speed", value: "\(Int(weather.wind.speed * 3.6)) km/h")
                    DetailItem(icon: "eye.fill", label: "Visibility", value: "\(weather.visibility.map { "\($0 / 1000) km" } ?? "N/A")")
                }
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .cornerRadius(15)
        }
        .padding(25)
        .background(.ultraThinMaterial)
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.horizontal)
    }
}

// Detail Item Helper
struct DetailItem: View {
    let icon: String; let label: String; let value: String
    
    var body: some View {
        VStack {
            Image(systemName: icon).font(.title3)
            Text(label).font(.caption).opacity(0.8)
            Text(value).font(.headline).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(.white)
    }
}

// Hourly Forecast View
struct HourlyForecastView: View {
    let forecastList: [ForecastItem]
    
    var hourlyForecast: [ForecastItem] { return Array(forecastList.prefix(8)) }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("HOURLY FORECAST").font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.8)).padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(hourlyForecast) { item in
                        VStack(spacing: 8) {
                            Text(item.hour).font(.subheadline).fontWeight(.medium)
                            Image(systemName: item.weather.first?.icon.toSFSymbol() ?? "questionmark.circle").font(.title3).frame(height: 30)
                            Text("\(Int(item.main.temp))°C").fontWeight(.semibold)
                        }
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial).cornerRadius(15).padding(.horizontal)
        }
        .padding(.top)
    }
}

// Daily Forecast View
struct DailyForecastView: View {
    let forecastList: [ForecastItem]
    
    var dailyForecast: [ForecastItem] {
        let now = Date(); var uniqueDays: [String: ForecastItem] = [:]
        for item in forecastList {
            let day = item.day
            if item.dt > now && uniqueDays[day] == nil { uniqueDays[day] = item }
        }
        let sortedDays = uniqueDays.values.sorted(by: { $0.dt < $1.dt }).prefix(5)
        return Array(sortedDays)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("5-DAY FORECAST").font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.8)).padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(dailyForecast) { item in
                    HStack {
                        Text(item.day).fontWeight(.medium).frame(width: 50, alignment: .leading)
                        Image(systemName: item.weather.first?.icon.toSFSymbol() ?? "questionmark.circle").font(.title3)
                        Text(item.weather.first?.description.capitalized ?? "").font(.callout).opacity(0.8)
                        Spacer()
                        Text("\(Int(item.main.temp_max))° / \(Int(item.main.temp_min))°").fontWeight(.semibold)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 20).background(Color.clear)
                }
            }
            .background(.ultraThinMaterial).cornerRadius(15).padding(.horizontal)
        }
        .padding(.top)
    }
}

// Manage Locations View (Used in a sheet)
struct ManageLocationsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(locationManager.savedLocations) { location in
                    VStack(alignment: .leading) {
                        Text(location.name).font(.headline)
                        Text("Lat: \(location.latitude), Lon: \(location.longitude)").font(.caption).foregroundColor(.gray)
                    }
                }
                .onDelete(perform: deleteLocation)
            }
            .navigationTitle("Saved Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { EditButton() }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
    
    private func deleteLocation(offsets: IndexSet) { locationManager.removeLocation(at: offsets) }
}

// Alarm Settings View (Used in a sheet)
struct AlarmSettingsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var alarmTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    @State private var selectedCondition = "Rain"
    
    let conditions = ["Rain", "Snow", "Heavy Wind"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ALARM TIME")) {
                    DatePicker("Time", selection: $alarmTime, displayedComponents: .hourAndMinute)
                }
                Section(header: Text("ALARM CONDITION")) {
                    Picker("Trigger if:", selection: $selectedCondition) {
                        ForEach(conditions, id: \.self) { condition in Text(condition) }
                    }
                    Text("This alarm will notify you if \(selectedCondition) is forecast for tomorrow morning.").font(.caption).opacity(0.7)
                }
                Section(header: Text("CITY")) {
                    if let firstLocation = locationManager.savedLocations.first { Text(firstLocation.name) } 
                    else { Text("No saved location. Please add one first.").foregroundColor(.red) }
                }
                Button("Set Smart Alarm") {
                    if let location = locationManager.savedLocations.first {
                        NotificationManager().scheduleWeatherAlarm(at: alarmTime, for: selectedCondition, location: location)
                    }
                }
                .frame(maxWidth: .infinity).padding().background(Color.blue).foregroundColor(.white).cornerRadius(10)
            }
            .navigationTitle("Set Weather Alarm")
        }
    }
}


// MARK: - Extensions
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex); _ = scanner.scanString("#"); var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb); self.init(red: Double((rgb >> 16) & 0xFF) / 255.0, green: Double((rgb >> 8) & 0xFF) / 255.0, blue: Double(rgb & 0xFF) / 255.0)
    }
}

extension MKPlacemark {
    var title: String? {
        let name = self.name ?? ""; let locality = self.locality ?? ""; let country = self.countryCode ?? ""
        if !name.isEmpty { return "\(name), \(country)" }; if !locality.isEmpty { return "\(locality), \(country)" }; return country
    }
}

extension String {
    func toSFSymbol() -> String {
        switch self {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n", "04d", "04n": return "cloud.fill"
        case "09d", "09n", "10d", "10n": return "cloud.rain.fill"
        case "11d", "11n": return "cloud.bolt.rain.fill"
        case "13d", "13n": return "cloud.snow.fill"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "questionmark.circle"
        }
    }
}
