import SwiftUI
import Cocoa
import ServiceManagement
import UserNotifications

@main
struct JoyaaSMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - we handle everything through the menu bar
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        setupMenuBar()
        setupEventMonitor()
        showWelcomeMessage()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            // Use your beautiful peacock logo
            button.image = createPeacockIcon()
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func createPeacockIcon() -> NSImage {
        // Try to load the custom menubar icon first
        if let iconPath = Bundle.main.path(forResource: "menubar-icon", ofType: "png"),
           let customIcon = NSImage(contentsOfFile: iconPath) {
            customIcon.size = NSSize(width: 18, height: 18)
            return customIcon
        }
        
        // Fallback: create a beautiful peacock icon based on your logo
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Colors from your beautiful logo
        let blackColor = NSColor.black
        
        // For menu bar, we'll use a simpler black version for better visibility
        blackColor.setFill()
        
        // Draw the peacock body (main shape)
        let bodyPath = NSBezierPath()
        bodyPath.appendOval(in: NSRect(x: 4, y: 5, width: 10, height: 8))
        bodyPath.fill()
        
        // Draw the head/neck area
        let headPath = NSBezierPath()
        headPath.appendOval(in: NSRect(x: 2, y: 8, width: 6, height: 6))
        headPath.fill()
        
        // Draw the crown feathers (three dots)
        let featherPath = NSBezierPath()
        
        // Left feather
        featherPath.appendOval(in: NSRect(x: 6, y: 2, width: 2, height: 2))
        featherPath.move(to: NSPoint(x: 7, y: 4))
        featherPath.line(to: NSPoint(x: 7, y: 8))
        
        // Center feather  
        featherPath.appendOval(in: NSRect(x: 8, y: 1, width: 2, height: 2))
        featherPath.move(to: NSPoint(x: 9, y: 3))
        featherPath.line(to: NSPoint(x: 9, y: 8))
        
        // Right feather
        featherPath.appendOval(in: NSRect(x: 10, y: 2, width: 2, height: 2))
        featherPath.move(to: NSPoint(x: 11, y: 4))
        featherPath.line(to: NSPoint(x: 11, y: 8))
        
        featherPath.lineWidth = 1.0
        featherPath.fill()
        featherPath.stroke()
        
        // Add beak
        let beakPath = NSBezierPath()
        beakPath.move(to: NSPoint(x: 2, y: 10))
        beakPath.line(to: NSPoint(x: 0, y: 11))
        beakPath.line(to: NSPoint(x: 2, y: 12))
        beakPath.close()
        beakPath.fill()
        
        image.unlockFocus()
        
        return image
    }
    
    @objc func togglePopover() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            if let popover = popover, popover.isShown {
                hidePopover()
            } else {
                showPopover()
            }
        }
    }
    
    private func showPopover() {
        if popover == nil {
            popover = NSPopover()
            popover?.contentViewController = NSHostingController(rootView: ContentView())
            popover?.behavior = .transient
        }
        
        if let button = statusItem?.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()
        }
    }
    
    private func hidePopover() {
        popover?.performClose(nil)
        eventMonitor?.stop()
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Open JoyaaS", action: #selector(openJoyaaS), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Fix Layout from Clipboard", action: #selector(fixLayoutFromClipboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Clean Text from Clipboard", action: #selector(cleanTextFromClipboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About JoyaaS", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        menu.items.forEach { $0.target = self }
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc func openJoyaaS() {
        let task = Process()
        task.launchPath = "/usr/bin/python3"
        task.arguments = ["/Users/galsasson/Downloads/Joyout/joyaas_app_fixed.py"]
        
        do {
            try task.run()
        } catch {
            print("Failed to launch JoyaaS: \(error)")
        }
    }
    
    @objc func fixLayoutFromClipboard() {
        guard let clipboardText = NSPasteboard.general.string(forType: .string),
              !clipboardText.isEmpty else {
            showNotification(title: "JoyaaS", message: "No text found in clipboard")
            return
        }
        
        print("Original text: '\(clipboardText)'")
        
        let processor = TextProcessor.shared
        let fixedText = processor.fixLayout(clipboardText)
        
        print("Fixed text: '\(fixedText)'")
        print("Texts are equal: \(fixedText == clipboardText)")
        
        if fixedText != clipboardText {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(fixedText, forType: .string)
            showNotification(title: "JoyaaS", message: "Layout fixed: '\(fixedText)'")
        } else {
            showNotification(title: "JoyaaS", message: "Text layout was already correct: '\(clipboardText)'")
        }
    }
    
    @objc func cleanTextFromClipboard() {
        guard let clipboardText = NSPasteboard.general.string(forType: .string),
              !clipboardText.isEmpty else {
            showNotification(title: "JoyaaS", message: "No text found in clipboard")
            return
        }
        
        let processor = TextProcessor()
        let cleanedText = processor.cleanText(clipboardText)
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cleanedText, forType: .string)
        showNotification(title: "JoyaaS", message: "Text cleaned and copied to clipboard")
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "JoyaaS MenuBar"
        alert.informativeText = "A powerful text processing tool for Hebrew and English.\n\nVersion 1.0\nDeveloped by Gal Sasson"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
    
    private func showWelcomeMessage() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
            
            if !hasLaunchedBefore {
                UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
                
                let alert = NSAlert()
                alert.messageText = "🦚 Welcome to JoyaaS MenuBar!"
                alert.informativeText = "Your beautiful peacock logo is now in your menu bar!\n\n• Click the icon for the main interface\n• Right-click for quick actions\n• Perfect layout fixing with smart detection"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Get Started")
                alert.runModal()
            }
        }
    }
    
    private func showNotification(title: String, message: String) {
        let center = UNUserNotificationCenter.current()
        
        // Request permission first
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            guard granted else {
                print("Notification permission denied")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = UNNotificationSound.default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request) { error in
                if let error = error {
                    print("Notification error: \(error)")
                }
            }
        }
    }
    
    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let popover = self?.popover, popover.isShown {
                self?.hidePopover()
            }
        }
    }
}

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }
    
    func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}

