import SwiftUI
import Cocoa
import Combine

// MARK: - Clipboard Monitor
class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var onClipboardChange: (String) -> Void
    
    init(onClipboardChange: @escaping (String) -> Void) {
        self.onClipboardChange = onClipboardChange
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let currentChangeCount = NSPasteboard.general.changeCount
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            if let clipboardString = NSPasteboard.general.string(forType: .string),
               !clipboardString.isEmpty {
                onClipboardChange(clipboardString)
            }
        }
    }
}

// MARK: - App Menu Commands
struct AppMenuCommands: Commands {
    var body: some Commands {
        // File menu commands
        CommandGroup(after: .newItem) {
            Button("Process Text") {
                // This would trigger processing via a notification or shared state
                NotificationCenter.default.post(name: .processText, object: nil)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            
            Button("Clear Input") {
                NotificationCenter.default.post(name: .clearInput, object: nil)
            }
            .keyboardShortcut("k", modifiers: [.command])
        }
        
        // Edit menu enhancements
        CommandGroup(after: .pasteboard) {
            Button("Process Clipboard") {
                NotificationCenter.default.post(name: .processClipboard, object: nil)
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])
        }
        
        // View menu commands
        CommandGroup(after: .toolbar) {
            Button("Show History") {
                NotificationCenter.default.post(name: .showHistory, object: nil)
            }
            .keyboardShortcut("h", modifiers: [.command])
            
            Button("Show Settings") {
                NotificationCenter.default.post(name: .showSettings, object: nil)
            }
            .keyboardShortcut(",", modifiers: [.command])
        }
        
        // Text Operations menu
        CommandMenu("Text Operations") {
            Button("Layout Fixer") {
                NotificationCenter.default.post(name: .selectOperation, object: TextOperation.layoutFixer)
            }
            .keyboardShortcut("1", modifiers: [.command])
            
            Button("Text Cleaner") {
                NotificationCenter.default.post(name: .selectOperation, object: TextOperation.textCleaner)
            }
            .keyboardShortcut("2", modifiers: [.command])
            
            Button("Hebrew Nikud") {
                NotificationCenter.default.post(name: .selectOperation, object: TextOperation.hebrewNikud)
            }
            .keyboardShortcut("3", modifiers: [.command])
            
            Button("Language Corrector") {
                NotificationCenter.default.post(name: .selectOperation, object: TextOperation.languageCorrector)
            }
            .keyboardShortcut("4", modifiers: [.command])
            
            Button("Translator") {
                NotificationCenter.default.post(name: .selectOperation, object: TextOperation.translator)
            }
            .keyboardShortcut("5", modifiers: [.command])
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let processText = Notification.Name("processText")
    static let clearInput = Notification.Name("clearInput")
    static let processClipboard = Notification.Name("processClipboard")
    static let showHistory = Notification.Name("showHistory")
    static let showSettings = Notification.Name("showSettings")
    static let selectOperation = Notification.Name("selectOperation")
}
