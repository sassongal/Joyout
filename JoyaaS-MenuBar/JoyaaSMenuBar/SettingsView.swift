import SwiftUI
import AppKit

struct SettingsView: View {
    @StateObject private var textProcessor = TextProcessor.shared
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("General")
                }
                .tag(0)
            
            FontSettingsView()
                .tabItem {
                    Image(systemName: "textformat")
                    Text("Fonts")
                }
                .tag(1)
            
            HotkeysSettingsView()
                .tabItem {
                    Image(systemName: "keyboard")
                    Text("Hotkeys")
                }
                .tag(2)
            
            AISettingsView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI & Processing")
                }
                .tag(3)
            
            NotificationsSettingsView()
                .tabItem {
                    Image(systemName: "bell")
                    Text("Notifications")
                }
                .tag(4)
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Statistics")
                }
                .tag(5)
        }
        .frame(width: 600, height: 500)
    }
}

struct GeneralSettingsView: View {
    @State private var enableClipboardMonitoring = true
    @State private var enableSmartSuggestions = true
    @State private var showMenuBarIcon = true
    @State private var preferredTheme = "Auto"
    
    private let themes = ["Auto", "Light", "Dark"]
    
    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $preferredTheme) {
                    ForEach(themes, id: \.self) { theme in
                        Text(theme).tag(theme)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Toggle("Show menu bar icon", isOn: $showMenuBarIcon)
            }
            
            Section("Smart Features") {
                Toggle("Enable clipboard monitoring", isOn: $enableClipboardMonitoring)
                    .onChange(of: enableClipboardMonitoring) { enabled in
                        if enabled {
                            ClipboardManager.shared.startMonitoring()
                        } else {
                            ClipboardManager.shared.stopMonitoring()
                        }
                    }
                
                Toggle("Enable smart suggestions", isOn: $enableSmartSuggestions)
            }
            
            Section("Reset") {
                Button("Reset All Settings") {
                    resetAllSettings()
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(GroupedFormStyle())
        .onAppear {
            enableClipboardMonitoring = ClipboardManager.shared.isMonitoring
        }
    }
    
    private func resetAllSettings() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "google_api_key")
        defaults.removeObject(forKey: "notifications_enabled")
        defaults.removeObject(forKey: "processing_history")
        defaults.removeObject(forKey: "clipboardHistory")
        
        NotificationManager.shared.showText("Settings Reset", subtitle: "All preferences have been reset to defaults")
    }
}

struct HotkeysSettingsView: View {
    @State private var hotkeys = [
        ("Quick Layout Fix", "Cmd+Shift+J", true),
        ("Smart Translation", "Cmd+Shift+T", true),
        ("Process Clipboard", "Cmd+Shift+C", true),
        ("Hebrew Nikud", "Cmd+Shift+H", true),
        ("Smart Detection", "Cmd+Shift+B", true)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Global Keyboard Shortcuts")
                .font(.headline)
            
            Text("These shortcuts work system-wide in any application.")
                .foregroundColor(.secondary)
            
            List {
                ForEach(hotkeys.indices, id: \.self) { index in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(hotkeys[index].0)
                                .font(.system(.body, design: .default))
                            Text(hotkeys[index].1)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: .constant(hotkeys[index].2))
                            .toggleStyle(SwitchToggleStyle())
                    }
                    .padding(.vertical, 4)
                }
            }
            .frame(height: 250)
            
            HStack {
                Text("⚠️ Note: Some shortcuts may require accessibility permissions")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Button("Open System Preferences") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .font(.caption)
            }
        }
        .padding()
    }
}

struct AISettingsView: View {
    @StateObject private var textProcessor = TextProcessor.shared
    @State private var apiKey = ""
    @State private var showingAPIKeyField = false
    @State private var apiKeyStatus = "Not Configured"
    @State private var enableAIFeatures = false
    
    var body: some View {
        Form {
            Section("Google AI Integration") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("API Status")
                            .font(.headline)
                        Text(apiKeyStatus)
                            .foregroundColor(textProcessor.hasValidAPIKey() ? .green : .red)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Button(textProcessor.hasValidAPIKey() ? "Update Key" : "Set API Key") {
                        showingAPIKeyField.toggle()
                    }
                }
                
                if showingAPIKeyField {
                    SecureField("Enter Google AI API Key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Button("Save") {
                            textProcessor.setGoogleAPIKey(apiKey)
                            updateAPIKeyStatus()
                            showingAPIKeyField = false
                            apiKey = ""
                        }
                        .disabled(apiKey.isEmpty)
                        
                        Button("Cancel") {
                            showingAPIKeyField = false
                            apiKey = ""
                        }
                        
                        Spacer()
                        
                        Link("Get API Key", destination: URL(string: "https://makersuite.google.com/app/apikey")!)
                            .font(.caption)
                    }
                }
            }
            
            Section("AI Configuration") {
                Toggle("Enable AI-powered features", isOn: $enableAIFeatures)
                    .help("Use Google AI for advanced Hebrew Nikud, grammar correction, and translation")
            }
        }
        .formStyle(GroupedFormStyle())
        .onAppear {
            updateAPIKeyStatus()
        }
    }
    
    private func updateAPIKeyStatus() {
        if textProcessor.hasValidAPIKey() {
            apiKeyStatus = "✅ Configured"
            enableAIFeatures = true
        } else {
            apiKeyStatus = "❌ Not Configured"
            enableAIFeatures = false
        }
    }
}

struct NotificationsSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        Form {
            Section("Notification Preferences") {
                Toggle("Enable notifications", isOn: $notificationManager.isEnabled)
                    .onChange(of: notificationManager.isEnabled) { _ in
                        notificationManager.savePreferences()
                    }
                
                if notificationManager.isEnabled {
                    Group {
                        Toggle("Processing completion notifications", isOn: $notificationManager.showProcessingNotifications)
                        Toggle("Clipboard notifications", isOn: $notificationManager.showClipboardNotifications)
                        Toggle("Smart suggestions", isOn: $notificationManager.showSmartSuggestions)
                    }
                    .onChange(of: notificationManager.showProcessingNotifications) { _ in
                        notificationManager.savePreferences()
                    }
                    .onChange(of: notificationManager.showClipboardNotifications) { _ in
                        notificationManager.savePreferences()
                    }
                    .onChange(of: notificationManager.showSmartSuggestions) { _ in
                        notificationManager.savePreferences()
                    }
                }
            }
            
            Section("Test Notifications") {
                HStack {
                    Button("Test Welcome") {
                        notificationManager.showWelcome()
                    }
                    
                    Button("Test Processing") {
                        notificationManager.showProcessingComplete(operation: "Layout Fixer", preview: "Hello world!")
                    }
                    
                    Button("Test Tip") {
                        notificationManager.showUsageTip()
                    }
                }
            }
        }
        .formStyle(GroupedFormStyle())
    }
}

struct StatisticsView: View {
    @StateObject private var textProcessor = TextProcessor.shared
    @StateObject private var clipboardManager = ClipboardManager.shared
    @State private var stats: TextProcessor.ProcessingStats?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Usage Statistics") {
                    if let stats = stats {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(title: "Total Operations", value: "\(stats.totalOperations)", color: .blue)
                            StatCard(title: "Recent Operations", value: "\(stats.recentOperationsCount)", color: .green)
                            StatCard(title: "Average Duration", value: String(format: "%.2fs", stats.averageDuration), color: .orange)
                            StatCard(title: "Most Used", value: stats.mostUsedOperation, color: .purple)
                        }
                    } else {
                        Text("Loading statistics...")
                            .foregroundColor(.secondary)
                    }
                }
                
                GroupBox("Recent Activity") {
                    if textProcessor.recentOperations.isEmpty {
                        Text("No recent activity")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 4) {
                            ForEach(Array(textProcessor.recentOperations.prefix(5))) { operation in
                                HStack {
                                    Text(operation.operation)
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text("\(operation.inputLength) chars")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                GroupBox("Clipboard History") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(clipboardManager.history.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Items in history")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Clear History") {
                            clipboardManager.clearHistory()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            stats = textProcessor.getProcessingStats()
        }
    }
}

struct FontSettingsView: View {
    @StateObject private var fontManager = FontManager.shared
    @State private var previewText = "שלום Hello العربية مرحبا 123"
    
    var body: some View {
        Form {
            Section("Font Selection") {
                Picker("Font Family", selection: $fontManager.selectedFontName) {
                    ForEach(fontManager.availableFonts, id: \.name) { font in
                        Text(font.displayName).tag(font.name)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: fontManager.selectedFontName) { newFont in
                    fontManager.setSelectedFont(newFont)
                }
                
                HStack {
                    Text("Font Size:")
                    Slider(value: $fontManager.selectedFontSize, in: 8...32, step: 1) {
                        Text("Font Size")
                    }
                    Text("\(Int(fontManager.selectedFontSize))pt")
                        .frame(width: 35, alignment: .leading)
                        .font(.system(size: 12, design: .monospaced))
                }
                .onChange(of: fontManager.selectedFontSize) { newSize in
                    fontManager.setFontSize(newSize)
                }
            }
            
            Section("Preview") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Font Preview:")
                        .font(.headline)
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(previewText)
                                .font(fontManager.getSwiftUIFont(size: fontManager.selectedFontSize))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                            
                            Divider()
                            
                            HStack {
                                Text("Hebrew: אבגדהוזחטי")
                                    .font(fontManager.getSwiftUIFont(size: fontManager.selectedFontSize * 0.8))
                                Spacer()
                                Text("English: ABCDEFGHIJ")
                                    .font(fontManager.getSwiftUIFont(size: fontManager.selectedFontSize * 0.8))
                            }
                        }
                    }
                    .frame(minHeight: 80)
                    
                    TextField("Custom preview text", text: $previewText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            Section("Recommended Fonts") {
                Text("Fonts optimized for Hebrew and English text:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(fontManager.getRecommendedFonts().prefix(6), id: \.name) { font in
                        Button(action: {
                            fontManager.setSelectedFont(font.name)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(font.displayName)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Text("שלום Hello")
                                    .font(.custom(font.name, size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(font.name == fontManager.selectedFontName ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(font.name == fontManager.selectedFontName ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Section("Font Information") {
                if let selectedFont = fontManager.availableFonts.first(where: { $0.name == fontManager.selectedFontName }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Font Name:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedFont.name)
                                .font(.caption)
                                .font(.system(size: 11, design: .monospaced))
                        }
                        
                        HStack {
                            Text("Family:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedFont.familyName)
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Weight:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedFont.weight)
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Type:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(selectedFont.isSystemFont ? "System Font" : "Custom Font")
                                .font(.caption)
                                .foregroundColor(selectedFont.isSystemFont ? .blue : .orange)
                        }
                    }
                }
            }
        }
        .formStyle(GroupedFormStyle())
        .frame(maxHeight: .infinity)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
