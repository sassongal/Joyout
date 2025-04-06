import SwiftUI

struct ContentView: View {
    @State private var autoRunEnabled = true
    
    var body: some View {
        VStack(spacing: 12) {
            Text(NSLocalizedString("Joyout", comment: ""))
                .font(.headline)
                .padding(.top, 8)
            
            Divider()
            
            // Feature buttons
            FeatureButton(title: "Fix Layout", shortcut: "⌃Q", action: fixLayout)
            FeatureButton(title: "Remove Underlines", shortcut: "", action: removeUnderlines)
            FeatureButton(title: "Translate Text", shortcut: "⌃W", action: translateText)
            FeatureButton(title: "AI Correct", shortcut: "⌃A", action: aiCorrect)
            FeatureButton(title: "Add Nikud", shortcut: "⌃S", action: addNikud)
            FeatureButton(title: "Send to Notepad", shortcut: "⌃⌘A", action: sendToNotepad)
            
            Divider()
            
            // Auto-run toggle
            Toggle("Auto-run on startup", isOn: $autoRunEnabled)
                .padding(.horizontal)
                .onChange(of: autoRunEnabled) { oldValue, newValue in
                    toggleAutoRun(enabled: newValue)
                }

            
            Spacer()
        }
        .frame(width: 280)
        .padding(.bottom, 12)
    }
    
    // Action functions for each feature
    func fixLayout() {
        runPythonScript("layout_fixer.py")
    }
    
    func removeUnderlines() {
        runPythonScript("underline_remover.py")
    }
    
    func translateText() {
        runPythonScript("clipboard_translator.py")
    }
    
    func aiCorrect() {
        runPythonScript("language_corrector.py")
    }
    
    func addNikud() {
        runPythonScript("hebrew_nikud.py")
    }
    
    func sendToNotepad() {
        runPythonScript("clipboard_to_notepad.py")
    }
    
    func toggleAutoRun(enabled: Bool) {
        // Logic to enable/disable auto-run on startup
    }
    
    func runPythonScript(_ scriptName: String) {
        // Logic to run Python script from Resources/Scripts directory
    }
}

// Custom button style for feature buttons
struct FeatureButton: View {
    let title: String
    let shortcut: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if !shortcut.isEmpty {
                    Text(shortcut)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .buttonStyle(FeatureButtonStyle())
        .frame(maxWidth: .infinity)
        .frame(height: 36)
    }
}

struct FeatureButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? Color.gray.opacity(0.2) : Color.clear)
            )
            .contentShape(Rectangle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
