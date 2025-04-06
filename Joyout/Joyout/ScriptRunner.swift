import Foundation
import Cocoa

class ScriptRunner {
    static func run(scriptName: String, userMessage: String) {
        guard let selected = SelectedTextManager.getSelectedText() else {
            showNotification(text: "❌ לא נבחר טקסט")
            return
        }

        let process = Process()
        process.launchPath = "/usr/bin/python3"
        process.arguments = ["/Users/galsasson/Downloads/Joyout-project/scripts/\(scriptName)", selected.text]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        process.launch()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        switch selected.source {
        case .editable:
            if scriptName == "language_corrector.py" {
                // AI correction: נשמור ל־Clipboard, המשתמש יחליט מתי להדביק
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(output, forType: .string)
                showNotification(text: "✅ \(userMessage) – הועתק ללוח")
            } else if scriptName == "clipboard_to_notepad.py" {
                // שליחה לנוטפד
                openNotepad(with: selected.text)
            } else {
                // פעולות כמו ניקוד, תרגום, תיקון פריסה – החלפה במקום
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(output, forType: .string)

                let script = """
                tell application "System Events"
                    keystroke "a" using command down
                    delay 0.1
                    keystroke "v" using command down
                end tell
                """
                let appleScript = NSAppleScript(source: script)
                appleScript?.executeAndReturnError(nil)

                showNotification(text: "✅ \(userMessage) – הטקסט הוחלף")
            }

        case .selectedOnly:
            // טקסט ממקור חיצוני – נדביק לתוך TextEdit
            openNotepad(with: output)
            showNotification(text: "✅ \(userMessage) הודבק לנוטפד")

        case .none:
            showNotification(text: "⚠️ לא נמצא טקסט תקף")
        }
    }

    static func openNotepad(with text: String) {
        let tempPath = "/tmp/joyout_text.txt"
        try? text.write(toFile: tempPath, atomically: true, encoding: .utf8)
        let script = "open -a TextEdit \(tempPath)"
        _ = try? shell(script)
    }

    static func showNotification(text: String) {
        let notification = NSUserNotification()
        notification.title = "Joyout"
        notification.informativeText = text
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }

    static func shell(_ command: String) throws -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
