import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.blue)
                    .font(.title)
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") {
                    appState.saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.escape)
            }
            .padding(.bottom)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // API Configuration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Configuration")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Google AI API Key")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            SecureField("Enter your Google AI API key", text: $appState.googleAIKey)
                                .textFieldStyle(.roundedBorder)
                            
                            HStack {
                                Text("Required for AI features: Hebrew Nikud, Language Correction, Translation")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Link("Get Free API Key", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    // Behavior Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Behavior")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            Toggle("Auto-process clipboard changes", isOn: $appState.autoProcessClipboard)
                                .help("Automatically process text when clipboard changes")
                            
                            Toggle("Show processing notifications", isOn: $appState.showNotifications)
                                .help("Show system notifications when text processing is complete")
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    // Keyboard Shortcuts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Keyboard Shortcuts")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ShortcutRow(action: "Process Text", shortcut: "⌘ + Return")
                            ShortcutRow(action: "Copy Result", shortcut: "⌘ + C")
                            ShortcutRow(action: "Clear Input", shortcut: "⌘ + K")
                            ShortcutRow(action: "Open Settings", shortcut: "⌘ + ,")
                            ShortcutRow(action: "View History", shortcut: "⌘ + H")
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About JoyaaS")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Version:")
                                    .font(.subheadline)
                                Spacer()
                                Text("2.0.0")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Build:")
                                    .font(.subheadline)
                                Spacer()
                                Text("Native macOS")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Professional Hebrew/English text processing for Mac")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("© 2025 JoyaaS. All rights reserved.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 500, height: 600)
    }
}

struct ShortcutRow: View {
    let action: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(action)
                .font(.subheadline)
            
            Spacer()
            
            Text(shortcut)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
