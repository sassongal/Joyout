import Foundation
import AppKit

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var history: [ClipboardItem] = []
    @Published var isMonitoring = false
    
    private var lastChangeCount: Int = 0
    private var monitoringTimer: Timer?
    private let maxHistoryItems = 50
    private let textProcessor = TextProcessor()
    
    struct ClipboardItem: Identifiable, Codable {
        let id = UUID()
        let text: String
        let timestamp: Date
        let source: String
        var processedVersions: [String: String] = [:]
        var suggestedOperation: String?
        
        enum CodingKeys: String, CodingKey {
            case text, timestamp, source, processedVersions, suggestedOperation
        }
    }
    
    private init() {
        loadHistory()
        lastChangeCount = NSPasteboard.general.changeCount
    }
    
    func startMonitoring() {
        isMonitoring = true
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.checkForClipboardChanges()
        }
        print("📋 Started clipboard monitoring")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        print("📋 Stopped clipboard monitoring")
    }
    
    private func checkForClipboardChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount
        
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            if let text = NSPasteboard.general.string(forType: .string), !text.isEmpty {
                addToHistory(text: text, source: "System")
                
                // Smart analysis for automatic suggestions
                DispatchQueue.global(qos: .background).async {
                    let suggestedOperation = SmartTextAnalyzer.shared.suggestBestOperation(for: text)
                    
                    DispatchQueue.main.async {
                        if !self.history.isEmpty {
                            self.history[0].suggestedOperation = suggestedOperation
                            
                            // Show notification if there's a strong suggestion
                            let confidence = SmartTextAnalyzer.shared.getConfidence(for: text, operation: suggestedOperation)
                            if confidence > 0.8 {
                                NotificationManager.shared.showClipboardSuggestion(operation: suggestedOperation, preview: String(text.prefix(30)))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func addToHistory(text: String, source: String) {
        // Don't add duplicates or very short text
        guard text.count > 2, history.first?.text != text else { return }
        
        let item = ClipboardItem(text: text, timestamp: Date(), source: source)
        history.insert(item, at: 0)
        
        // Limit history size
        if history.count > maxHistoryItems {
            history = Array(history.prefix(maxHistoryItems))
        }
        
        saveHistory()
    }
    
    func getCurrentText() -> String {
        return NSPasteboard.general.string(forType: .string) ?? ""
    }
    
    func setText(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        addToHistory(text: text, source: "JoyaaS")
    }
    
    func processClipboardItem(_ item: ClipboardItem, operation: String, completion: @escaping (String) -> Void) {
        // Check if we already have this processed version
        if let cached = item.processedVersions[operation] {
            completion(cached)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.processText(item.text, operation: operation)
            
            DispatchQueue.main.async {
                // Update the item with the processed version
                if let index = self.history.firstIndex(where: { $0.id == item.id }) {
                    self.history[index].processedVersions[operation] = result
                    self.saveHistory()
                }
                completion(result)
            }
        }
    }
    
    func applyProcessedText(_ text: String) {
        setText(text)
        NotificationManager.shared.showText("📋 Applied to clipboard", subtitle: String(text.prefix(50)))
    }
    
    private func processText(_ text: String, operation: String) -> String {
        switch operation {
        case "Layout Fixer":
            return textProcessor.fixLayout(text)
        case "Text Cleaner":
            return textProcessor.cleanText(text)
        case "Hebrew Nikud":
            return textProcessor.addHebrewNikud(text)
        case "Language Corrector":
            return textProcessor.correctLanguage(text)
        case "Translator":
            return textProcessor.translateText(text)
        default:
            return text
        }
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    func removeItem(_ item: ClipboardItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    // MARK: - Persistence
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "clipboardHistory")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "clipboardHistory"),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            history = decoded
        }
    }
    
    // MARK: - Quick Actions
    
    func quickFixClipboard() {
        let text = getCurrentText()
        guard !text.isEmpty else { return }
        
        let fixed = textProcessor.fixLayout(text)
        if fixed != text {
            setText(fixed)
            NotificationManager.shared.showText("🔧 Quick Fix Applied", subtitle: String(fixed.prefix(50)))
        }
    }
    
    func smartProcessClipboard() {
        let text = getCurrentText()
        guard !text.isEmpty else { return }
        
        let suggestedOperation = SmartTextAnalyzer.shared.suggestBestOperation(for: text)
        let processed = processText(text, operation: suggestedOperation)
        
        if processed != text {
            setText(processed)
            NotificationManager.shared.showText("🧠 Smart Process: \(suggestedOperation)", subtitle: String(processed.prefix(50)))
        }
    }
}
