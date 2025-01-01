import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @Environment(\.colorScheme) var colorScheme
    @State private var showPrivacyPolicy = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $settings.isDarkMode)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                }
                
                Section(header: Text("Sound")) {
                    HStack {
                        Image(systemName: "speaker.fill")
                        Slider(value: $settings.volume, in: 0...1, step: 0.1)
                        Image(systemName: "speaker.wave.3.fill")
                    }
                    .accentColor(.purple)
                    Text("Volume: \(Int(settings.volume * 100))%")
                        .font(.caption)
                }
                
                Section(header: Text("Haptics")) {
                    Picker("Vibration Strength", selection: $settings.vibrationStrength) {
                        Text("Off").tag(0)
                        Text("Light").tag(1)
                        Text("Medium").tag(2)
                        Text("Strong").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                }
                
                Section(header: Text("Gameplay")) {
                    Toggle("Show Tutorials", isOn: $settings.showTutorials)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                    
                    Picker("Difficulty Level", selection: $settings.difficultyLevel) {
                        ForEach(DifficultyLevel.allCases) { level in
                            Text(level.description).tag(level)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                            .foregroundColor(.gray)
                    }
                    
                    Button("Privacy Policy") {
                        showPrivacyPolicy = true
                    }
                }
                
                Section {
                    Button("Reset to Default Settings") {
                        settings.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .font(.system(.body, design: .rounded))
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(Settings())
    }
}
