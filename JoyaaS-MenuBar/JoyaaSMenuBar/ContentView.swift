import SwiftUI
import AppKit

struct ContentView: View {
    @State private var inputText = ""
    @State private var outputText = ""
    @State private var selectedOperation = "Layout Fixer"
    @State private var statusMessage = ""
    @State private var isProcessing = false
    @State private var isAutoFixEnabled = false
    @State private var showingSettings = false
    @State private var showingClipboardHistory = false
    @State private var showingBatchProcessor = false
    
    @StateObject private var textProcessor = TextProcessor.shared
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var smartAnalyzer = SmartTextAnalyzer.shared
    
    private let operations = ["Layout Fixer", "Text Cleaner", "Hebrew Nikud", "Language Corrector", "Translator"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with Peacock Logo
            HStack {
                // Use your peacock logo or create a colored version
                PeacockLogoView(size: 24)
                    .foregroundColor(.accentColor)
                
                Text("JoyaaS")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 5.0/255.0, green: 71.0/255.0, blue: 179.0/255.0)) // Your actual logo blue #0547B3
                
                Spacer()
                
                Button(action: openMainApp) {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Open main JoyaaS app")
            }
            .padding(.bottom, 4)
            
            // Operation selector
            Picker("Operation", selection: $selectedOperation) {
                ForEach(operations, id: \.self) { operation in
                    Text(operation).tag(operation)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            // Input text area
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Input:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Paste", action: pasteFromClipboard)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
                
                TextEditor(text: $inputText)
                    .font(.system(size: 13, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    .frame(height: 80)
            }
            
            // Process button
            HStack {
                Button(action: processText) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.down")
                        }
                        Text("Process")
                    }
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("Clear", action: clearAll)
                    .foregroundColor(.secondary)
            }
            
            // Output text area
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Output:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !outputText.isEmpty {
                        Button("Copy", action: copyToClipboard)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                
                TextEditor(text: $outputText)
                    .font(.system(size: 13, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    .frame(height: 80)
                    .disabled(true)
            }
            
            // Status message
            if !statusMessage.isEmpty {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Auto-fix toggle
            HStack {
                Toggle("Auto Layout Fix", isOn: $isAutoFixEnabled)
                    .font(.caption)
                    .onChange(of: isAutoFixEnabled) { newValue in
                        toggleAutoFix(enabled: newValue)
                    }
                
                Spacer()
                
                if isAutoFixEnabled {
                    PeacockLogoView(size: 12)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
            
            // Quick actions
            HStack {
                Button(action: { quickAction("Layout Fixer") }) {
                    HStack {
                        PeacockLogoView(size: 10)
                        Text("Fix Layout")
                    }
                }
                .font(.caption)
                .buttonStyle(.borderless)
                
                Button(action: { quickAction("Text Cleaner") }) {
                    Label("Clean Text", systemImage: "sparkles")
                }
                .font(.caption)
                .buttonStyle(.borderless)
                
                Spacer()
            }
            .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(width: 350)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func processText() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isProcessing = true
        statusMessage = ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = performOperation(selectedOperation, on: inputText)
            
            DispatchQueue.main.async {
                outputText = result
                isProcessing = false
                
                if result == inputText {
                    statusMessage = "No changes were needed"
                } else {
                    statusMessage = "Text processed successfully"
                }
                
                // Clear status message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    statusMessage = ""
                }
            }
        }
    }
    
    private func performOperation(_ operation: String, on text: String) -> String {
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
    
    private func quickAction(_ operation: String) {
        guard let clipboardText = NSPasteboard.general.string(forType: .string),
              !clipboardText.isEmpty else {
            statusMessage = "No text found in clipboard"
            return
        }
        
        inputText = clipboardText
        selectedOperation = operation
        processText()
    }
    
    private func pasteFromClipboard() {
        if let clipboardText = NSPasteboard.general.string(forType: .string) {
            inputText = clipboardText
        }
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
        statusMessage = "Copied to clipboard"
        
        // Clear status message after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            statusMessage = ""
        }
    }
    
    private func clearAll() {
        inputText = ""
        outputText = ""
        statusMessage = ""
    }
    
    private func toggleAutoFix(enabled: Bool) {
        isAutoFixEnabled = enabled
        
        if enabled {
            statusMessage = "Auto Layout Fix enabled (feature coming soon)"
        } else {
            statusMessage = "Auto Layout Fix disabled"
        }
        
        // Clear status message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            statusMessage = ""
        }
    }
    
    private func openMainApp() {
        let task = Process()
        task.launchPath = "/usr/bin/python3"
        task.arguments = ["/Users/galsasson/Downloads/Joyout/joyaas_app_fixed.py"]
        
        do {
            try task.run()
        } catch {
            statusMessage = "Failed to open main app"
        }
    }
}

#Preview {
    ContentView()
}
