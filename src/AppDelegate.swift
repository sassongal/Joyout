import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController!
    var shortcutManager: KeyboardShortcutManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the menu bar controller
        menuBarController = MenuBarController()
        
        // Initialize the keyboard shortcut manager
        shortcutManager = KeyboardShortcutManager()
        shortcutManager.registerShortcuts()
        
        // Set up auto-launch at login if enabled
        setupAutoLaunch()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources when app terminates
    }
    
    private func setupAutoLaunch() {
        // Logic to set up auto-launch at login (to be implemented)
    }
}
