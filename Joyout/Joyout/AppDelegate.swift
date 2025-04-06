import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController!
    var shortcutManager: KeyboardShortcutManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()
        shortcutManager = KeyboardShortcutManager()
        shortcutManager.registerShortcuts()
        setupAutoLaunch()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources
    }

    private func setupAutoLaunch() {
        // Future implementation
    }
}
