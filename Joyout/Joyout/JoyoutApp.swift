import SwiftUI

@main
struct JoyoutApp: App {
    init() {
        _ = GlobalShortcuts.shared  // מפעיל את כל הקיצורים בזמן עליית האפליקציה
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
