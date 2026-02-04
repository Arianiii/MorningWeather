
import SwiftUI

struct ContentView: View {
    // We create a single instance of our LocationManager to be used by the app.
    @StateObject private var locationManager = LocationManager()
    
    // State to control showing the "Add Location" sheet.
    @State private var isAddingLocation = false

    var body: some View {
        // Use a NavigationView to get a title bar and navigation capabilities.
        NavigationView {
            ZStack {
                // Same background as the welcome screen for consistency.
                LinearGradient(
                    colors: [Color(hex: "3d4a6c"), Color(hex: "1a2033")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // If there are no saved locations, show a helpful message.
                if locationManager.savedLocations.isEmpty {
                    Text("No locations added yet.\nTap the '+' button to add a city.")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                // The list of saved locations.
                List {
                    // Loop through each saved location.
                    ForEach(locationManager.savedLocations) { location in
                        // For now, we just show the name.
                        // Later, we will turn this into a beautiful weather summary row.
                        Text(location.name)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical)
                    }
                    // Enable the "swipe to delete" functionality.
                    .onDelete(perform: locationManager.removeLocation)
                    .listRowBackground(Color.white.opacity(0.1))
                }
                .listStyle(.plain) // Use a plain style for a modern look.
            }
            .navigationTitle("Your Locations")
            .navigationBarTitleDisplayMode(.inline)
            // Add a '+' button to the top-right corner.
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingLocation = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            // When the '+' button is tapped, this sheet will appear.
            .sheet(isPresented: $isAddingLocation) {
                // We will create this AddLocationView in the next step.
                // For now, it's just a placeholder.
                Text("Search for a new location")
            }
        }
        // Style the navigation bar for our dark theme.
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
