import Cocoa
import Carbon

class KeyboardShortcutManager: NSObject {
    // Dictionary to store registered shortcuts and their handlers
    private var shortcuts: [UInt32: () -> Void] = [:]
    
    // Register all keyboard shortcuts
    func registerShortcuts() {
        // Register Ctrl+Q for keyboard layout fixing
        registerShortcut(keyCode: kVK_ANSI_Q, modifiers: [.control], action: fixLayout)
        
        // Register Ctrl+W for clipboard translation
        registerShortcut(keyCode: kVK_ANSI_W, modifiers: [.control], action: translateText)
        
        // Register Ctrl+A for AI language correction
        registerShortcut(keyCode: kVK_ANSI_A, modifiers: [.control], action: aiCorrect)
        
        // Register Ctrl+S for Hebrew nikud/vowelization
        registerShortcut(keyCode: kVK_ANSI_S, modifiers: [.control], action: addNikud)
        
        // Register Ctrl+Cmd+A for clipboard to notepad
        registerShortcut(keyCode: kVK_ANSI_A, modifiers: [.control, .command], action: sendToNotepad)
    }
    
    // Register a single keyboard shortcut
    private func registerShortcut(keyCode: Int, modifiers: NSEvent.ModifierFlags, action: @escaping () -> Void) {
        let shortcutID = UInt32(keyCode) | (UInt32(modifiers.rawValue) << 16)
        shortcuts[shortcutID] = action
        
        // Set up event tap to capture keyboard events
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if type == .keyDown {
                    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                    let modifiers = NSEvent.ModifierFlags(rawValue: UInt(event.getIntegerValueField(.keyboardEventFlags)))
                    
                    let shortcutID = UInt32(keyCode) | (UInt32(modifiers.rawValue) << 16)
                    
                    if let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(refcon!).takeUnretainedValue(),
                       let action = manager.shortcuts[shortcutID] {
                        action()
                        return nil // Consume the event
                    }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Failed to create event tap")
            return
        }
        
        // Create a run loop source and add it to the current run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    // Action functions for each feature
    private func fixLayout() {
        runPythonScript("layout_fixer.py")
    }
    
    private func translateText() {
        runPythonScript("clipboard_translator.py")
    }
    
    private func aiCorrect() {
        runPythonScript("language_corrector.py")
    }
    
    private func addNikud() {
        runPythonScript("hebrew_nikud.py")
    }
    
    private func sendToNotepad() {
        runPythonScript("clipboard_to_notepad.py")
    }
    
    // Helper function to run Python scripts
    private func runPythonScript(_ scriptName: String) {
        let scriptPath = Bundle.main.path(forResource: scriptName, ofType: nil, inDirectory: "Scripts")
        
        guard let scriptPath = scriptPath else {
            print("Script not found: \(scriptName)")
            return
        }
        
        let task = Process()
        task.launchPath = "/usr/bin/python3"
        task.arguments = [scriptPath]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
        } catch {
            print("Error running script: \(error)")
        }
    }
}
