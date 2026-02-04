
import Foundation

// A simple, Codable struct to hold our location data.
// Identifiable is needed to use it in SwiftUI's ForEach loops.
// Codable is needed to easily save and load it from UserDefaults.
struct SavedLocation: Identifiable, Codable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
}
