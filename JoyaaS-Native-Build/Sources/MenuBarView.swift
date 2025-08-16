import SwiftUI
import AppKit
import UserNotifications

// MARK: - Menu Bar View
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var quickText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.blue)
                Text("JoyaaS")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    NSApp.sendAction(#selector(AppDelegate.openMainWindow), to: nil, from: nil)
                }) {
                    Image(systemName: "rectangle.expand.vertical")
                }
                .buttonStyle(.borderless)
                .help("Open Main Window")
            }
            
            Divider()
            
            // Quick Process
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Process")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Operation Selector
                Picker("Operation", selection: $appState.selectedOperation) {
                    ForEach(TextOperation.allCases) { operation in
                        Label(operation.rawValue, systemImage: operation.icon)
                            .tag(operation)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                
                // Quick text input
                HStack {
                    TextField("Enter text to process...", text: $quickText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Process") {
                        appState.inputText = quickText
                        appState.processText()
                        
                        // Copy result to clipboard after processing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if !appState.outputText.isEmpty {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(appState.outputText, forType: .string)
                                
                                // Show notification
                                let content = UNMutableNotificationContent()
                                content.title = "JoyaaS"
                                content.body = "Text processed and copied to clipboard!"
                                content.sound = .default
                                
                                let request = UNNotificationRequest(
                                    identifier: UUID().uuidString,
                                    content: content,
                                    trigger: nil
                                )
                                
                                UNUserNotificationCenter.current().add(request)
                            }
                        }
                    }
                    .disabled(quickText.isEmpty || appState.isProcessing)
                }
            }
            
            // Get text from clipboard
            Button("Process Clipboard") {
                if let clipboardText = NSPasteboard.general.string(forType: .string) {
                    appState.inputText = clipboardText
                    appState.processText()
                    
                    // Replace clipboard with result
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if !appState.outputText.isEmpty {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(appState.outputText, forType: .string)
                        }
                    }
                }
            }
            .disabled(appState.isProcessing)
            
            Divider()
            
            // Recent Operations
            if !appState.processingHistory.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(appState.processingHistory.prefix(3)) { record in
                        MenuBarHistoryRow(record: record)
                    }
                }
            }
            
            Divider()
            
            // Quick Actions
            VStack(alignment: .leading, spacing: 4) {
                Button("Settings") {
                    appState.showingSettings = true
                }
                .buttonStyle(.borderless)
                
                Button("View History") {
                    appState.showingHistory = true
                }
                .buttonStyle(.borderless)
                
                Button("Quit JoyaaS") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .frame(width: 280)
    }
}

struct MenuBarHistoryRow: View {
    let record: ProcessingRecord
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: record.operation.icon)
                .foregroundColor(.blue)
                .frame(width: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.operation.rawValue)
                    .font(.caption)
                    .lineLimit(1)
                
                Text(record.output.prefix(40) + (record.output.count > 40 ? "..." : ""))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(record.output, forType: .string)
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Copy to Clipboard")
        }
        .padding(.vertical, 2)
    }
}

// Note: AppMenuCommands and ClipboardMonitor are defined in SupportingComponents.swift

// MARK: - App Delegate (for menu handling)
class AppDelegate: NSObject, NSApplicationDelegate {
    @objc func openMainWindow() {
        // Activate the main window
        for window in NSApplication.shared.windows {
            if window.identifier?.rawValue == "MainWindow" {
                window.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
                return
            }
        }
    }
}
