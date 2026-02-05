
import SwiftUI

// --- NEW: Alarm Settings View ---
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
                        ForEach(conditions, id: \.self) { condition in
                            Text(condition)
                        }
                    }
                    Text("This alarm will notify you if \(selectedCondition) is forecast for tomorrow morning.")
                        .font(.caption)
                        .opacity(0.7)
                }
                
                Section(header: Text("CITY")) {
                    // For demo, just use the first saved location
                    if let firstLocation = locationManager.savedLocations.first {
                        Text(firstLocation.name)
                    } else {
                        Text("No saved location. Please add one first.")
                            .foregroundColor(.red)
                    }
                }
                
                Button("Set Smart Alarm") {
                    if let location = locationManager.savedLocations.first {
                        NotificationManager().scheduleWeatherAlarm(
                            at: alarmTime, 
                            for: selectedCondition, 
                            location: location
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .navigationTitle("Set Weather Alarm")
        }
    }
}

// MARK: - ContentView (Updated to include a button to AlarmSettingsView)
struct ContentView: View {
    // ... (Existing state variables) ...
    @State private var showAlarmSettings = false // New state for showing alarm settings

    var body: some View {
        ZStack {
            // ... (Background and main VStacK logic) ...
            
            VStack(spacing: 20) {
                // ... (Search or Display logic remains the same) ...
            }
            .transition(.opacity)
        }
        .onAppear {
            // ... (OnAppear logic remains the same) ...
        }
        .sheet(isPresented: $showAlarmSettings) {
            AlarmSettingsView()
                .environmentObject(savedLocationManager)
        }
        // ... (All other functions remain the same) ...
    }
    
    // ... (rest of ContentView functions) ...
}

// ... (All other helper structs and classes remain in Helpers.swift) ...
