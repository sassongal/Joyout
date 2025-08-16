import Foundation
import UserNotifications
import AppKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isEnabled = true
    @Published var showProcessingNotifications = true
    @Published var showClipboardNotifications = true
    @Published var showSmartSuggestions = true
    
    private init() {
        requestPermission()
        loadPreferences()
    }
    
    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isEnabled = granted
                if granted {
                    print("✅ Notification permissions granted")
                } else {
                    print("❌ Notification permissions denied")
                }
            }
        }
    }
    
    // MARK: - Processing Notifications
    
    func showProcessingComplete(operation: String, preview: String) {
        guard isEnabled && showProcessingNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "✅ \(operation) Complete"
        content.body = preview
        content.sound = .default
        
        // Add action buttons
        let copyAction = UNNotificationAction(identifier: "copy", title: "Copy Result", options: [])
        let undoAction = UNNotificationAction(identifier: "undo", title: "Undo", options: [])
        
        let category = UNNotificationCategory(
            identifier: "processing_complete",
            actions: [copyAction, undoAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "processing_complete"
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show notification: \(error)")
            }
        }
    }
    
    func showClipboardProcessed(operation: String) {
        guard isEnabled && showClipboardNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📋 Clipboard Processed"
        content.body = "Applied \(operation) to clipboard content"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show clipboard notification: \(error)")
            }
        }
    }
    
    func showClipboardSuggestion(operation: String, preview: String) {
        guard isEnabled && showSmartSuggestions else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💡 Smart Suggestion"
        content.body = "Clipboard text might benefit from \(operation): \(preview)"
        content.sound = nil // Silent suggestion
        
        // Add action to apply suggestion
        let applyAction = UNNotificationAction(identifier: "apply_suggestion", title: "Apply \(operation)", options: [])
        let dismissAction = UNNotificationAction(identifier: "dismiss", title: "Dismiss", options: [])
        
        let category = UNNotificationCategory(
            identifier: "smart_suggestion",
            actions: [applyAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "smart_suggestion"
        
        // Show after a delay to avoid spam
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
        let request = UNNotificationRequest(identifier: "suggestion_\(operation)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show suggestion: \(error)")
            }
        }
    }
    
    func showSmartProcessingComplete(operation: String) {
        guard isEnabled && showProcessingNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🧠 Smart Processing Complete"
        content.body = "Applied \(operation) based on intelligent text analysis"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show smart processing notification: \(error)")
            }
        }
    }
    
    // MARK: - System Notifications
    
    func showError(_ title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "❌ \(title)"
        content.body = message
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show error notification: \(error)")
            }
        }
    }
    
    func showText(_ title: String, subtitle: String) {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = subtitle
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show text notification: \(error)")
            }
        }
    }
    
    func showWelcome() {
        let content = UNMutableNotificationContent()
        content.title = "🦚 Welcome to JoyaaS!"
        content.body = "Your smart Hebrew/English text processor is ready. Try Cmd+Shift+J for quick layout fixes!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
        let request = UNNotificationRequest(identifier: "welcome", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show welcome notification: \(error)")
            }
        }
    }
    
    func showUsageTip() {
        guard isEnabled else { return }
        
        let tips = [
            "💡 Tip: Use Cmd+Shift+J to quickly fix layout mistakes in any app",
            "💡 Tip: Cmd+Shift+C processes your clipboard content intelligently",
            "💡 Tip: Enable clipboard monitoring in settings for automatic suggestions",
            "💡 Tip: The smart analyzer can detect what processing your text needs",
            "💡 Tip: Access clipboard history from the menu bar for quick processing"
        ]
        
        let randomTip = tips.randomElement() ?? tips[0]
        
        let content = UNMutableNotificationContent()
        content.title = "JoyaaS Tip"
        content.body = randomTip
        content.sound = nil
        
        let request = UNNotificationRequest(identifier: "usage_tip", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show usage tip: \(error)")
            }
        }
    }
    
    // MARK: - Batch Processing Notifications
    
    func showBatchProcessingStarted(itemCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔄 Batch Processing Started"
        content.body = "Processing \(itemCount) items..."
        content.sound = nil
        
        let request = UNNotificationRequest(identifier: "batch_start", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show batch start notification: \(error)")
            }
        }
    }
    
    func showBatchProcessingComplete(itemCount: Int, duration: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "✅ Batch Processing Complete"
        content.body = "Processed \(itemCount) items in \(String(format: "%.1f", duration)) seconds"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "batch_complete", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to show batch complete notification: \(error)")
            }
        }
    }
    
    // MARK: - Settings
    
    func savePreferences() {
        UserDefaults.standard.set(isEnabled, forKey: "notifications_enabled")
        UserDefaults.standard.set(showProcessingNotifications, forKey: "show_processing_notifications")
        UserDefaults.standard.set(showClipboardNotifications, forKey: "show_clipboard_notifications")
        UserDefaults.standard.set(showSmartSuggestions, forKey: "show_smart_suggestions")
    }
    
    private func loadPreferences() {
        isEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
        showProcessingNotifications = UserDefaults.standard.bool(forKey: "show_processing_notifications")
        showClipboardNotifications = UserDefaults.standard.bool(forKey: "show_clipboard_notifications")
        showSmartSuggestions = UserDefaults.standard.bool(forKey: "show_smart_suggestions")
    }
}
