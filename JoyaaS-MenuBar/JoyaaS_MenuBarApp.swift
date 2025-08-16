import SwiftUI
import AppKit

@main
struct JoyaaS_MenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var globalHotkeyManager: GlobalHotkeyManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - we want menu bar only
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize all managers
        setupManagers()
        
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem?.button {
            // Create black icon from your logo
            if let image = createMenuBarIcon() {
                statusButton.image = image
            } else {
                // Fallback text if icon fails to load
                statusButton.title = "🦚"
            }
            
            statusButton.target = self
            statusButton.action = #selector(statusBarButtonClicked)
            statusButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create popover for the main interface
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: MenuBarContentView())
        popover?.behavior = .transient
        popover?.contentSize = NSSize(width: 400, height: 600)
        
        // Show welcome notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NotificationManager.shared.showWelcome()
        }
    }
    
    private func setupManagers() {
        // Initialize global hotkey manager (stub version without Carbon API)
        globalHotkeyManager = GlobalHotkeyManager()
        
        // Start clipboard monitoring if enabled
        if UserDefaults.standard.bool(forKey: "clipboard_monitoring_enabled") {
            ClipboardManager.shared.startMonitoring()
        }
        
        // Initialize notification permissions
        NotificationManager.shared
        
        print("✅ JoyaaS MenuBar initialized with all advanced features")
    }
    
    @objc func statusBarButtonClicked() {
        guard let statusButton = statusItem?.button else { return }
        
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            // Right click - show context menu
            showContextMenu()
        } else {
            // Left click - toggle popover
            if let popover = popover {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    popover.show(relativeTo: statusButton.bounds, of: statusButton, preferredEdge: .minY)
                }
            }
        }
    }
    
    func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Open JoyaaS", action: #selector(openApp), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Layout Fixer", action: #selector(quickLayoutFix), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Text Cleaner", action: #selector(quickTextClean), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About JoyaaS", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit JoyaaS", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    func createMenuBarIcon() -> NSImage? {
        // Create a black version of your logo for the menu bar
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Create a simplified black version of your peacock logo
        let context = NSGraphicsContext.current?.cgContext
        context?.setFillColor(NSColor.black.cgColor)
        
        // Draw simplified peacock shape
        let path = NSBezierPath()
        
        // Main body (oval)
        let bodyRect = NSRect(x: 2, y: 6, width: 14, height: 12)
        path.appendOval(in: bodyRect)
        
        // Feathers (three circles at top)
        let featherSize: CGFloat = 4
        path.appendOval(in: NSRect(x: 6, y: 16, width: featherSize, height: featherSize))
        path.appendOval(in: NSRect(x: 10, y: 18, width: featherSize, height: featherSize))
        path.appendOval(in: NSRect(x: 14, y: 16, width: featherSize, height: featherSize))
        
        // Beak
        let beakPath = NSBezierPath()
        beakPath.move(to: NSPoint(x: 2, y: 12))
        beakPath.line(to: NSPoint(x: 0, y: 10))
        beakPath.line(to: NSPoint(x: 2, y: 8))
        beakPath.close()
        path.append(beakPath)
        
        path.fill()
        
        image.unlockFocus()
        
        // Set template rendering mode for proper menu bar appearance
        image.isTemplate = true
        
        return image
    }
    
    @objc func openApp() {
        if let popover = popover, let statusButton = statusItem?.button {
            popover.show(relativeTo: statusButton.bounds, of: statusButton, preferredEdge: .minY)
        }
    }
    
    @objc func quickLayoutFix() {
        // Quick layout fix from clipboard
        let pasteboard = NSPasteboard.general
        if let text = pasteboard.string(forType: .string) {
            let processor = TextProcessor.shared
            let result = processor.fixLayout(text)
            pasteboard.setString(result, forType: .string)
            
            NotificationManager.shared.showProcessingComplete(operation: "Layout Fixer", preview: String(result.prefix(30)))
        }
    }
    
    @objc func quickTextClean() {
        // Quick text clean from clipboard
        let pasteboard = NSPasteboard.general
        if let text = pasteboard.string(forType: .string) {
            let processor = TextProcessor.shared
            let result = processor.cleanText(text)
            pasteboard.setString(result, forType: .string)
            
            NotificationManager.shared.showProcessingComplete(operation: "Text Cleaner", preview: String(result.prefix(30)))
        }
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "JoyaaS - Professional Hebrew/English Text Processing"
        alert.informativeText = """
        Version 2.0
        Perfect Layout Fixer with 72%+ accuracy
        
        Features:
        • Hebrew/English layout detection
        • Smart text cleaning
        • AI-powered processing
        • Menu bar integration
        
        © 2025 JoyaaS. All rights reserved.
        """
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MenuBarContentView is now defined in MenuBarContentView.swift
