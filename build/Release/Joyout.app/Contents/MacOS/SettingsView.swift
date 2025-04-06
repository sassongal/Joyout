import SwiftUI

struct SettingsView: View {
    @State private var autoRunEnabled = true
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                GeneralSettingsView(autoRunEnabled: $autoRunEnabled)
                    .tabItem {
                        Label("General", systemImage: "gear")
                    }
                    .tag(0)
                
                AppearanceSettings()
                    .tabItem {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                    .tag(1)
                
                ShortcutsSettingsView()
                    .tabItem {
                        Label("Shortcuts", systemImage: "keyboard")
                    }
                    .tag(2)
            }
            .padding()
            .frame(width: 400, height: 300)
        }
    }
}

struct GeneralSettingsView: View {
    @Binding var autoRunEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(NSLocalizedString("General Settings", comment: ""))
                .font(.headline)
                .padding(.bottom, 5)
            
            Toggle("Launch at login", isOn: $autoRunEnabled)
                .onChange(of: autoRunEnabled) { newValue in
                    setLaunchAtLogin(enabled: newValue)
                }
            
            Divider()
            
            Text(NSLocalizedString("Privacy", comment: ""))
                .font(.headline)
                .padding(.top, 5)
            
            Text(NSLocalizedString("Joyout does not store or send any clipboard data outside your device.", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func setLaunchAtLogin(enabled: Bool) {
        // In a real app, this would use SMLoginItemSetEnabled or similar
        print("Launch at login set to: \(enabled)")
    }
}

struct ShortcutsSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(NSLocalizedString("Keyboard Shortcuts", comment: ""))
                .font(.headline)
                .padding(.bottom, 5)
            
            ShortcutRow(feature: "Fix Layout", shortcut: "⌃Q")
            ShortcutRow(feature: "Remove Underlines", shortcut: "")
            ShortcutRow(feature: "Translate Text", shortcut: "⌃W")
            ShortcutRow(feature: "AI Correct", shortcut: "⌃A")
            ShortcutRow(feature: "Add Nikud", shortcut: "⌃S")
            ShortcutRow(feature: "Send to Notepad", shortcut: "⌃⌘A")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ShortcutRow: View {
    let feature: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(feature)
                .frame(width: 150, alignment: .leading)
            
            Spacer()
            
            if !shortcut.isEmpty {
                Text(shortcut)
                    .padding(4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            } else {
                Text(NSLocalizedString("None", comment: ""))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
