import Cocoa
import Carbon

class KeyboardShortcutManager: NSObject {
    private var shortcuts: [UInt32: () -> Void] = [:]
    
    func registerShortcuts() {
        registerShortcut(keyCode: kVK_ANSI_Q, modifiers: [.control], action: fixLayout)
        registerShortcut(keyCode: kVK_ANSI_W, modifiers: [.control], action: translateText)
        registerShortcut(keyCode: kVK_ANSI_A, modifiers: [.control], action: aiCorrect)
        registerShortcut(keyCode: kVK_ANSI_S, modifiers: [.control], action: addNikud)
        registerShortcut(keyCode: kVK_ANSI_A, modifiers: [.control, .command], action: sendToNotepad)
    }
    
    private func registerShortcut(keyCode: Int, modifiers: NSEvent.ModifierFlags, action: @escaping () -> Void) {
        let shortcutID = UInt32(keyCode) | (UInt32(modifiers.rawValue) << 16)
        shortcuts[shortcutID] = action
        
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if type == .keyDown {
                    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                    let flags = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))
                    
                    let shortcutID = UInt32(keyCode) | (UInt32(flags.rawValue) << 16)
                    
                    let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(refcon!).takeUnretainedValue()
                    if let action = manager.shortcuts[shortcutID] {
                        action()
                        return nil
                    }

                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Failed to create event tap")
            return
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
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

    private func runPythonScript(_ scriptName: String) {
        guard let scriptPath = Bundle.main.path(forResource: scriptName, ofType: nil, inDirectory: "Scripts") else {
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
