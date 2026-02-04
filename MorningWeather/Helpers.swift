
import SwiftUI
import MapKit
import WeatherKit
import Lottie

// MARK: - Weather Service
@MainActor
class WeatherService: ObservableObject {
    @Published var weather: Weather?
    @Published var errorMessage: String?

    private let service = WeatherKit.WeatherService.shared

    func fetchWeather(for location: CLLocation) async {
        self.weather = nil
        self.errorMessage = nil
        do {
            self.weather = try await service.weather(for: location)
        } catch {
            self.errorMessage = "Failed to fetch weather. Please ensure WeatherKit is enabled in Capabilities."
        }
    }
}

// MARK: - Data Models
struct SearchResult: Identifiable {
    let id = UUID()
    let placemark: MKPlacemark
}

// MARK: - Helper Views
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
    var body: some View { LottieView(name: animationName, loopMode: .loop) }
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


// MARK: - Extensions
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
