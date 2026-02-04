
import Foundation
import CoreLocation

// A class to manage adding, removing, and saving locations.
// It will be an ObservableObject so our views can react to changes.
@MainActor
class LocationManager: ObservableObject {
    @Published private(set) var savedLocations: [SavedLocation] = []
    
    private let userDefaultsKey = "weatherLocations"
    
    init() {
        // Load saved locations when the app starts
        loadLocations()
    }
    
    // --- Data Persistence ---
    
    private func loadLocations() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
                savedLocations = decoded
                return
            }
        }
        // If loading fails, start with an empty array
        savedLocations = []
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // --- Public Functions ---
    
    func addLocation(name: String, coordinate: CLLocationCoordinate2D) {
        let newLocation = SavedLocation(
            id: UUID(),
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        savedLocations.append(newLocation)
        save()
    }
    
    func removeLocation(at offsets: IndexSet) {
        savedLocations.remove(atOffsets: offsets)
        save()
    }
}
