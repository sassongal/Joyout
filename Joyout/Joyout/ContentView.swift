import SwiftUI

struct ContentView: View {
    @State private var autoRunEnabled = true
    @State private var statusMessage: String? = nil

    var body: some View {
        ZStack {
            Image("JoyoutBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.2)

            VStack(spacing: 12) {
                HStack {
                    Image("AppLogo")
                        .resizable()
                        .frame(width: 24, height: 24)

                    Text("Joyout")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal)

                Divider()

                FeatureButton(title: "Fix Layout", shortcut: "⌃Q", imageAsset: "fix_layout") {
                    runWithMessage("Fixed layout", script: "layout_fixer.py")
                }

                FeatureButton(title: "Remove Underlines", shortcut: "", imageAsset: "remove_underlines") {
                    runWithMessage("Underlines removed", script: "underline_remover.py")
                }

                FeatureButton(title: "Translate Text", shortcut: "⌃W", imageAsset: "translate_text") {
                    runWithMessage("Text translated", script: "clipboard_translator.py")
                }

                FeatureButton(title: "AI Correct", shortcut: "⌃A", imageAsset: "ai_correct") {
                    runWithMessage("AI correction done", script: "language_corrector.py")
                }

                FeatureButton(title: "Add Nikud", shortcut: "⌃S", imageAsset: "add_nikud") {
                    runWithMessage("Nikud added", script: "hebrew_nikud.py")
                }

                FeatureButton(title: "Send to Notepad", shortcut: "⌃⌘A", imageAsset: "send_to_notepad") {
                    runWithMessage("Sent to notepad", script: "clipboard_to_notepad.py")
                }

                Divider()

                Toggle("Auto-run on startup", isOn: $autoRunEnabled)
                    .padding(.horizontal)

                Spacer()

                if let message = statusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }

                Text("Joya Digital Solutions")
                    .font(.system(size: 7))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            .frame(width: 280)
        }
    }

    func runWithMessage(_ message: String, script: String) {
        runPythonScript(script)
        withAnimation {
            statusMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                statusMessage = nil
            }
        }
    }

    func runPythonScript(_ scriptName: String) {
        // Logic to run the script
    }
}
