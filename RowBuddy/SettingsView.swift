import SwiftUI

// MARK: - App Settings Model
class AppSettings: ObservableObject {
    // Display Settings
    @AppStorage("colorScheme") var colorScheme: String = "system" // system, light, dark
    @AppStorage("keepScreenAwake") var keepScreenAwake: Bool = true
    @AppStorage("showNextSegment") var showNextSegment: Bool = true
    @AppStorage("timerColorScheme") var timerColorScheme: String = "blue" // blue, green, purple
    
    // Audio Settings
    @AppStorage("soundEffects") var soundEffects: Bool = true
    @AppStorage("countdownBeeps") var countdownBeeps: Bool = true
    @AppStorage("segmentTransitionSound") var segmentTransitionSound: Bool = true
    @AppStorage("voiceAnnouncements") var voiceAnnouncements: Bool = false
    @AppStorage("hapticFeedback") var hapticFeedback: Bool = true
    @AppStorage("continueMusic") var continueMusic: Bool = true
    
    // Workout Defaults
    @AppStorage("defaultSPM") var defaultSPM: Int = 24
    @AppStorage("defaultGoalSplit") var defaultGoalSplit: String = "2:00/500m"
    @AppStorage("confirmSkip") var confirmSkip: Bool = true
    @AppStorage("autoPauseOnLock") var autoPauseOnLock: Bool = false
    
    static let shared = AppSettings()
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settings = AppSettings.shared
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    
    var onSignOut: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Display Settings
                Section(header: Text("Display")) {
                    Picker("Appearance", selection: $settings.colorScheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    
                    Picker("Timer Color", selection: $settings.timerColorScheme) {
                        HStack {
                            Circle().fill(Color.blue).frame(width: 20, height: 20)
                            Text("Blue")
                        }.tag("blue")
                        HStack {
                            Circle().fill(Color.green).frame(width: 20, height: 20)
                            Text("Green")
                        }.tag("green")
                        HStack {
                            Circle().fill(Color.purple).frame(width: 20, height: 20)
                            Text("Purple")
                        }.tag("purple")
                    }
                    
                    Toggle("Keep Screen Awake", isOn: $settings.keepScreenAwake)
                        .tint(.blue)
                    
                    Toggle("Show Next Segment Preview", isOn: $settings.showNextSegment)
                        .tint(.blue)
                }
                
                // MARK: - Audio Settings
                Section(header: Text("Audio & Haptics")) {
                    Toggle("Sound Effects", isOn: $settings.soundEffects)
                        .tint(.blue)
                    
                    if settings.soundEffects {
                        Toggle("Countdown Beeps", isOn: $settings.countdownBeeps)
                            .tint(.blue)
                            .padding(.leading, 20)
                        
                        Toggle("Segment Transition Sound", isOn: $settings.segmentTransitionSound)
                            .tint(.blue)
                            .padding(.leading, 20)
                    }
                    
                    Toggle("Voice Announcements", isOn: $settings.voiceAnnouncements)
                        .tint(.blue)
                    
                    Toggle("Haptic Feedback", isOn: $settings.hapticFeedback)
                        .tint(.blue)
                    
                    Toggle("Continue Playing Music", isOn: $settings.continueMusic)
                        .tint(.blue)
                }
                .font(.subheadline)
                
                // MARK: - Workout Defaults
                Section(header: Text("Workout Defaults")) {
                    Stepper("Default SPM: \(settings.defaultSPM)", value: $settings.defaultSPM, in: 10...40)
                    
                    HStack {
                        Text("Default Goal Split")
                        Spacer()
                        TextField("2:00/500m", text: $settings.defaultGoalSplit)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Confirm Before Skipping", isOn: $settings.confirmSkip)
                        .tint(.blue)
                    
                    Toggle("Auto-Pause on Screen Lock", isOn: $settings.autoPauseOnLock)
                        .tint(.blue)
                }
                
                // MARK: - Account
                Section(header: Text("Account")) {
                    Button(action: {
                        showSignOutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        showDeleteAccountConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Account")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // MARK: - About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/support")!) {
                        HStack {
                            Text("Support & Feedback")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Sign Out?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    onSignOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .confirmationDialog("Delete Account?", isPresented: $showDeleteAccountConfirmation, titleVisibility: .visible) {
                Button("Delete Account", role: .destructive) {
                    // TODO: Implement account deletion
                    print("Delete account")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all your workouts. This action cannot be undone.")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(onSignOut: {})
    }
}
