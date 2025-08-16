import SwiftUI
import AppKit

struct MenuBarContentView: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var textProcessor = TextProcessor.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var showingSettings = false
    @State private var showingBatchProcessor = false
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView()
            
            // Tab Selection
            Picker("Tab", selection: $selectedTab) {
                Text("Process").tag(0)
                Text("Clipboard").tag(1)
                Text("Stats").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Content based on selected tab
            switch selectedTab {
            case 0:
                ProcessingView()
            case 1:
                ClipboardHistoryView()
            case 2:
                QuickStatsView()
            default:
                ProcessingView()
            }
            
            Divider()
            
            // Footer with actions
            FooterView()
        }
        .frame(width: 400, height: 600)
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingBatchProcessor) {
            BatchProcessorView()
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            PeacockLogoView(size: 20)
                .foregroundColor(Color(red: 5.0/255.0, green: 71.0/255.0, blue: 179.0/255.0))
            
            Text("JoyaaS")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 5.0/255.0, green: 71.0/255.0, blue: 179.0/255.0))
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: { ClipboardManager.shared.quickFixClipboard() }) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.orange)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Quick fix clipboard content")
                
                Button(action: { ClipboardManager.shared.smartProcessClipboard() }) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Smart process clipboard")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ProcessingView: View {
    @StateObject private var textProcessor = TextProcessor.shared
    @State private var inputText = ""
    @State private var selectedOperation = "Layout Fixer"
    @State private var isProcessing = false
    @State private var processedResults: [String] = []
    
    private let operations = ["Layout Fixer", "Text Cleaner", "Hebrew Nikud", "Language Corrector", "Translator"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Quick paste and process
                GroupBox("Quick Process") {
                    VStack(spacing: 8) {
                        HStack {
                            Button("Paste & Fix Layout") {
                                quickProcess("Layout Fixer")
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Smart Process") {
                                smartProcess()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        HStack {
                            Button("Clean Text") {
                                quickProcess("Text Cleaner")
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Add Nikud") {
                                quickProcess("Hebrew Nikud")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // Input area
                GroupBox("Manual Input") {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Operation", selection: $selectedOperation) {
                            ForEach(operations, id: \.self) { operation in
                                Text(operation).tag(operation)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        TextEditor(text: $inputText)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(height: 80)
                            .scrollContentBackground(.hidden)
                            .background(Color(NSColor.textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.secondary.opacity(0.3))
                            )
                        
                        HStack {
                            Button("Process") {
                                processManualInput()
                            }
                            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            
                            Spacer()
                            
                            Button("Clear") {
                                inputText = ""
                                processedResults.removeAll()
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Processing results
                if !processedResults.isEmpty {
                    GroupBox("Results") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(processedResults.enumerated()), id: \.offset) { index, result in
                                HStack {
                                    Text(result)
                                        .font(.system(size: 11, design: .monospaced))
                                        .lineLimit(2)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(result, forType: .string)
                                        NotificationManager.shared.showText("Copied!", subtitle: String(result.prefix(30)))
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 2)
                                
                                if index < processedResults.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func quickProcess(_ operation: String) {
        guard let clipboardText = NSPasteboard.general.string(forType: .string),
              !clipboardText.isEmpty else {
            NotificationManager.shared.showError("No Content", message: "No text found in clipboard")
            return
        }
        
        let result = processText(clipboardText, operation: operation)
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result, forType: .string)
        
        processedResults.insert(result, at: 0)
        if processedResults.count > 5 {
            processedResults = Array(processedResults.prefix(5))
        }
        
        NotificationManager.shared.showProcessingComplete(operation: operation, preview: String(result.prefix(50)))
    }
    
    private func smartProcess() {
        guard let clipboardText = NSPasteboard.general.string(forType: .string),
              !clipboardText.isEmpty else {
            NotificationManager.shared.showError("No Content", message: "No text found in clipboard")
            return
        }
        
        let suggestedOperation = SmartTextAnalyzer.shared.suggestBestOperation(for: clipboardText)
        quickProcess(suggestedOperation)
    }
    
    private func processManualInput() {
        let result = processText(inputText, operation: selectedOperation)
        processedResults.insert(result, at: 0)
        
        if processedResults.count > 5 {
            processedResults = Array(processedResults.prefix(5))
        }
    }
    
    private func processText(_ text: String, operation: String) -> String {
        switch operation {
        case "Layout Fixer":
            return textProcessor.fixLayout(text)
        case "Text Cleaner":
            return textProcessor.cleanText(text)
        case "Hebrew Nikud":
            return textProcessor.addHebrewNikud(text)
        case "Language Corrector":
            return textProcessor.correctLanguage(text)
        case "Translator":
            return textProcessor.translateText(text)
        default:
            return text
        }
    }
}

struct ClipboardHistoryView: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @State private var searchText = ""
    
    var filteredHistory: [ClipboardManager.ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.history
        } else {
            return clipboardManager.history.filter { item in
                item.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and controls
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search history...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Clipboard monitoring toggle
            HStack {
                Toggle("Monitor clipboard", isOn: .constant(clipboardManager.isMonitoring))
                    .font(.caption)
                    .onChange(of: clipboardManager.isMonitoring) { enabled in
                        if enabled {
                            clipboardManager.startMonitoring()
                        } else {
                            clipboardManager.stopMonitoring()
                        }
                    }
                
                Spacer()
                
                Button("Clear All") {
                    clipboardManager.clearHistory()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
            
            // History list
            ScrollView {
                LazyVStack(spacing: 4) {
                    if filteredHistory.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "clipboard")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            
                            Text(searchText.isEmpty ? "No clipboard history" : "No matching items")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 40)
                    } else {
                        ForEach(filteredHistory) { item in
                            ClipboardItemView(item: item)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ClipboardItemView: View {
    let item: ClipboardManager.ClipboardItem
    @State private var showingProcessOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.text)
                        .font(.system(size: 11, design: .monospaced))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(item.source)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Text(RelativeDateTimeFormatter().localizedString(for: item.timestamp, relativeTo: Date()))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if let suggestion = item.suggestedOperation {
                            Text(suggestion)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Button(action: { copyToClipboard(item.text) }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Copy to clipboard")
                    
                    Button(action: { showingProcessOptions.toggle() }) {
                        Image(systemName: "gear")
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Process options")
                }
            }
            
            if showingProcessOptions {
                ProcessingOptionsView(item: item)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.2))
        )
    }
    
    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        NotificationManager.shared.showText("Copied!", subtitle: String(text.prefix(30)))
    }
}

struct ProcessingOptionsView: View {
    let item: ClipboardManager.ClipboardItem
    private let operations = ["Layout Fixer", "Text Cleaner", "Hebrew Nikud", "Language Corrector", "Translator"]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 4) {
            ForEach(operations, id: \.self) { operation in
                Button(operation) {
                    processAndApply(operation)
                }
                .font(.caption2)
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, 4)
    }
    
    private func processAndApply(_ operation: String) {
        ClipboardManager.shared.processClipboardItem(item, operation: operation) { result in
            ClipboardManager.shared.applyProcessedText(result)
        }
    }
}

struct QuickStatsView: View {
    @StateObject private var textProcessor = TextProcessor.shared
    @StateObject private var clipboardManager = ClipboardManager.shared
    @State private var stats: TextProcessor.ProcessingStats?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Overall stats
                if let stats = stats {
                    GroupBox("Usage Summary") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            StatItem(title: "Total", value: "\(stats.totalOperations)", color: .blue)
                            StatItem(title: "Recent", value: "\(stats.recentOperationsCount)", color: .green)
                            StatItem(title: "Avg Time", value: String(format: "%.1fs", stats.averageDuration), color: .orange)
                            StatItem(title: "Clipboard", value: "\(clipboardManager.history.count)", color: .purple)
                        }
                    }
                }
                
                // Recent operations
                GroupBox("Recent Activity") {
                    if textProcessor.recentOperations.isEmpty {
                        Text("No recent activity")
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 4) {
                            ForEach(Array(textProcessor.recentOperations.prefix(3))) { operation in
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
                
                // Quick actions
                GroupBox("Quick Actions") {
                    VStack(spacing: 6) {
                        HStack {
                            Button("Show Usage Tips") {
                                NotificationManager.shared.showUsageTip()
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Button("Clear All Data") {
                                clearAllData()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                            .buttonStyle(.bordered)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            updateStats()
        }
    }
    
    private func updateStats() {
        stats = textProcessor.getProcessingStats()
    }
    
    private func clearAllData() {
        clipboardManager.clearHistory()
        // Clear other data as needed
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct FooterView: View {
    @State private var showingSettings = false
    
    var body: some View {
        HStack {
            Button(action: { showingSettings = true }) {
                Image(systemName: "gear")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Settings")
            
            Spacer()
            
            Text("Cmd+Shift+J for quick fixes")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: quitApp) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Quit JoyaaS")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

struct BatchProcessorView: View {
    @State private var items: [String] = []
    @State private var results: [String] = []
    @State private var selectedOperation = "Layout Fixer"
    @State private var isProcessing = false
    
    private let operations = ["Layout Fixer", "Text Cleaner", "Hebrew Nikud", "Language Corrector", "Translator"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Batch Processor")
                .font(.headline)
            
            HStack {
                Picker("Operation", selection: $selectedOperation) {
                    ForEach(operations, id: \.self) { operation in
                        Text(operation).tag(operation)
                    }
                }
                
                Spacer()
                
                Button("Process All") {
                    processBatch()
                }
                .disabled(items.isEmpty || isProcessing)
            }
            
            // Items list
            List {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Text(item)
                        .font(.system(size: 11, design: .monospaced))
                        .lineLimit(2)
                }
            }
            .frame(height: 200)
            
            if isProcessing {
                ProgressView("Processing...")
                    .frame(maxWidth: .infinity)
            }
            
            HStack {
                Button("Add from Clipboard") {
                    if let text = NSPasteboard.general.string(forType: .string) {
                        items.append(text)
                    }
                }
                
                Button("Clear") {
                    items.removeAll()
                    results.removeAll()
                }
                .foregroundColor(.red)
                
                Spacer()
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
    
    private func processBatch() {
        guard !items.isEmpty else { return }
        
        isProcessing = true
        
        TextProcessor.shared.processBatch(items, operation: selectedOperation) { processedResults in
            self.results = processedResults
            self.isProcessing = false
        }
    }
}

#Preview {
    MenuBarContentView()
}
