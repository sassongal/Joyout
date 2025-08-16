import Foundation
import AppKit
import Cocoa

class GlobalHotkeyManager: ObservableObject {
    private let textProcessor = TextProcessor.shared
    private let clipboardManager = ClipboardManager.shared
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var accessibilityCheckTimer: Timer?
    private var hasAccessibilityPermission = false
    
    // Hotkey definitions
    private struct Hotkey {
        let keyCode: UInt16
        let modifiers: NSEvent.ModifierFlags
        let action: () -> Void
        let description: String
    }
    
    private lazy var hotkeys: [Hotkey] = [
        Hotkey(keyCode: 38, modifiers: [.command, .shift], action: performQuickFix, description: "Quick Fix (Cmd+Shift+J)"),
        Hotkey(keyCode: 17, modifiers: [.command, .shift], action: performTranslate, description: "Translate (Cmd+Shift+T)"),
        Hotkey(keyCode: 8, modifiers: [.command, .shift], action: performClipboardProcess, description: "Smart Process (Cmd+Shift+C)"),
        Hotkey(keyCode: 4, modifiers: [.command, .shift], action: performHebrewNikud, description: "Hebrew Nikud (Cmd+Shift+H)"),
        Hotkey(keyCode: 11, modifiers: [.command, .shift], action: performSmartDetect, description: "Smart Detect (Cmd+Shift+B)")
    ]
    
    init() {
        setupGlobalHotkeys()
    }
    
    deinit {
        cleanup()
    }
    
    func setupGlobalHotkeys() {
        checkAccessibilityPermission()
        
        // Start with a timer to periodically check accessibility permission
        accessibilityCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.checkAccessibilityPermission()
        }
    }
    
    private func checkAccessibilityPermission() {
        let wasEnabled = hasAccessibilityPermission
        hasAccessibilityPermission = AXIsProcessTrusted()
        
        if hasAccessibilityPermission && !wasEnabled {
            // Permission granted, setup hotkeys
            setupEventMonitors()
            print("✅ Accessibility permission granted - Global hotkeys enabled")
            
            // Stop the periodic check
            accessibilityCheckTimer?.invalidate()
            accessibilityCheckTimer = nil
            
            // Show success notification
            NotificationManager.shared.showText("🎯 Global Hotkeys Enabled", subtitle: "All keyboard shortcuts are now active")
        } else if !hasAccessibilityPermission && wasEnabled {
            // Permission revoked
            cleanup()
            print("⚠️ Accessibility permission revoked - Global hotkeys disabled")
        } else if !hasAccessibilityPermission {
            // Still no permission - show how to enable it
            showAccessibilityInstructions()
        }
    }
    
    private func showAccessibilityInstructions() {
        print("⚠️ Global hotkeys require accessibility permissions")
        print("💡 Go to System Preferences > Security & Privacy > Privacy > Accessibility")
        print("💡 Add JoyaaS to the list and enable it")
        
        // Show notification with instructions
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NotificationManager.shared.showText(
                "🔐 Enable Global Hotkeys", 
                subtitle: "Grant accessibility permission in System Preferences"
            )
        }
    }
    
    private func setupEventMonitors() {
        cleanup() // Remove existing monitors
        
        // Global monitor (works when app is not in focus)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            self.handleKeyEvent(event)
        }
        
        // Local monitor (works when app is in focus)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return self.handleKeyEvent(event) ? nil : event
        }
        
        print("🎯 Global hotkey monitoring started")
        print("📝 Available hotkeys:")
        for hotkey in hotkeys {
            print("   • \(hotkey.description)")
        }
    }
    
    private func cleanup() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        for hotkey in hotkeys {
            if event.keyCode == hotkey.keyCode && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == hotkey.modifiers {
                DispatchQueue.main.async {
                    hotkey.action()
                }
                return true // Event handled
            }
        }
        return false // Event not handled
    }
    
    // MARK: - Hotkey Actions
    
    func performQuickFix() {
        print("🔧 Executing Quick Fix hotkey")
        processSelectedTextOrClipboard(operation: "Layout Fixer")
    }
    
    func performTranslate() {
        print("🌐 Executing Translation hotkey")
        processSelectedTextOrClipboard(operation: "Translator")
    }
    
    func performClipboardProcess() {
        print("📋 Executing Smart Clipboard Process hotkey")
        ClipboardManager.shared.smartProcessClipboard()
    }
    
    func performHebrewNikud() {
        print("🔤 Executing Hebrew Nikud hotkey")
        processSelectedTextOrClipboard(operation: "Hebrew Nikud")
    }
    
    func performSmartDetect() {
        print("🧠 Executing Smart Detect hotkey")
        
        // Try selected text first, then clipboard
        if let selectedText = getSelectedText(), !selectedText.isEmpty {
            let suggestedOperation = SmartTextAnalyzer.shared.suggestBestOperation(for: selectedText)
            processText(selectedText, operation: suggestedOperation) { result in
                self.replaceSelectedText(with: result)
                NotificationManager.shared.showProcessingComplete(operation: "Smart: \(suggestedOperation)", preview: String(result.prefix(50)))
            }
        } else {
            // Fallback to clipboard
            guard let clipboardText = NSPasteboard.general.string(forType: .string), 
                  !clipboardText.isEmpty else { return }
            
            let suggestedOperation = SmartTextAnalyzer.shared.suggestBestOperation(for: clipboardText)
            processClipboard(operation: suggestedOperation)
        }
    }
    
    private func processSelectedTextOrClipboard(operation: String) {
        // Try to get selected text first
        if let selectedText = getSelectedText(), !selectedText.isEmpty {
            processText(selectedText, operation: operation) { result in
                self.replaceSelectedText(with: result)
                NotificationManager.shared.showProcessingComplete(operation: operation, preview: String(result.prefix(50)))
            }
        } else {
            // Fall back to clipboard
            processClipboard(operation: operation)
        }
    }
    
    private func processClipboard(operation: String) {
        guard let clipboardText = NSPasteboard.general.string(forType: .string),
              !clipboardText.isEmpty else { 
            NotificationManager.shared.showError("No Content", message: "No text found in clipboard")
            return 
        }
        
        processText(clipboardText, operation: operation) { result in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result, forType: .string)
            NotificationManager.shared.showProcessingComplete(operation: operation, preview: String(result.prefix(50)))
        }
    }
    
    private func processText(_ text: String, operation: String, completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result: String
            
            switch operation {
            case "Layout Fixer":
                result = self.textProcessor.fixLayout(text)
            case "Text Cleaner":
                result = self.textProcessor.cleanText(text)
            case "Hebrew Nikud":
                result = self.textProcessor.addHebrewNikud(text)
            case "Language Corrector":
                result = self.textProcessor.correctLanguage(text)
            case "Translator":
                result = self.textProcessor.translateText(text)
            default:
                result = text
            }
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    private func getSelectedText() -> String? {
        // Save current clipboard
        let originalClipboard = NSPasteboard.general.string(forType: .string)
        
        // Copy selected text using accessibility
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Create Cmd+C event
        guard let cmdCDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true),
              let cmdCUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false) else {
            return nil
        }
        
        cmdCDown.flags = .maskCommand
        cmdCUp.flags = .maskCommand
        
        cmdCDown.post(tap: .cghidEventTap)
        cmdCUp.post(tap: .cghidEventTap)
        
        // Small delay to ensure copy completes
        Thread.sleep(forTimeInterval: 0.1)
        
        // Get copied text
        let selectedText = NSPasteboard.general.string(forType: .string)
        
        // Restore original clipboard if it changed
        if let original = originalClipboard, selectedText != original {
            // We'll restore this after processing
        }
        
        return selectedText != originalClipboard ? selectedText : nil
    }
    
    private func replaceSelectedText(with text: String) {
        // Copy new text to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        // Create Cmd+V event
        let source = CGEventSource(stateID: .hidSystemState)
        
        guard let cmdVDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let cmdVUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else {
            return
        }
        
        cmdVDown.flags = .maskCommand
        cmdVUp.flags = .maskCommand
        
        cmdVDown.post(tap: .cghidEventTap)
        cmdVUp.post(tap: .cghidEventTap)
    }
    
    // MARK: - Public Status
    
    func getStatus() -> String {
        if hasAccessibilityPermission {
            return "✅ Global hotkeys enabled"
        } else {
            return "⚠️ Accessibility permission required"
        }
    }
    
    func getHotkeyDescriptions() -> [String] {
        return hotkeys.map { $0.description }
    }
    
    func requestAccessibilityPermission() {
        // This will prompt the user for permission
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
