import Foundation
import Cocoa
import ApplicationServices

enum TextSourceType {
    case editable
    case selectedOnly
    case none
}

struct SelectedTextResult {
    let text: String
    let source: TextSourceType
}

class SelectedTextManager {
    static func getSelectedText() -> SelectedTextResult? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = frontApp.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)

        var focusedElement: CFTypeRef?
        let resultFocused = AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard resultFocused == .success,
              let focusedElement = focusedElement else {
            print("❌ No focused UI element")
            return nil
        }

        let focused = unsafeBitCast(focusedElement, to: AXUIElement.self)


        var selectedTextValue: CFTypeRef?
        let resultText = AXUIElementCopyAttributeValue(focused, kAXSelectedTextAttribute as CFString, &selectedTextValue)

        guard resultText == .success,
              let selectedText = selectedTextValue as? String,
              !selectedText.isEmpty else {
            print("❌ No selected text")
            return nil
        }

        var isEditable: DarwinBoolean = false
        let resultEditable = AXUIElementIsAttributeSettable(focused, kAXValueAttribute as CFString, &isEditable)

        let source: TextSourceType = (resultEditable == .success && isEditable.boolValue) ? .editable : .selectedOnly

        return SelectedTextResult(text: selectedText, source: source)
    }
    
}
