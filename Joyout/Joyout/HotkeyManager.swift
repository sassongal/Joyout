import Foundation
import HotKey

class GlobalShortcuts {
    static let shared = GlobalShortcuts()

    let underlineHotKey = HotKey(key: .q, modifiers: [.control])
    let translateHotKey = HotKey(key: .w, modifiers: [.control])
    let correctHotKey = HotKey(key: .a, modifiers: [.control])
    let nikudHotKey = HotKey(key: .s, modifiers: [.control])
    let sendHotKey = HotKey(key: .a, modifiers: [.control, .command])

    private init() {
        underlineHotKey.keyDownHandler = {
            ScriptRunner.run(scriptName: "underline_remover.py", userMessage: "Underlines removed")
        }

        translateHotKey.keyDownHandler = {
            ScriptRunner.run(scriptName: "clipboard_translator.py", userMessage: "Text translated")
        }

        correctHotKey.keyDownHandler = {
            ScriptRunner.run(scriptName: "language_corrector.py", userMessage: "AI correction done")
        }

        nikudHotKey.keyDownHandler = {
            ScriptRunner.run(scriptName: "hebrew_nikud.py", userMessage: "Nikud added")
        }

        sendHotKey.keyDownHandler = {
            ScriptRunner.run(scriptName: "clipboard_to_notepad.py", userMessage: "Sent to Notepad")
        }
    }
}
