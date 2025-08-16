import SwiftUI
import Combine
import UserNotifications

@main
struct JoyaaS_NativeApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            AppMenuCommands()
        }
        
        // Menu bar extra for quick access
        MenuBarExtra("JoyaaS", systemImage: "text.bubble.fill") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - App State Management
class AppState: ObservableObject {
    @Published var inputText: String = ""
    @Published var outputText: String = ""
    @Published var selectedOperation: TextOperation = .layoutFixer
    @Published var isProcessing: Bool = false
    @Published var processingHistory: [ProcessingRecord] = []
    @Published var showingSettings: Bool = false
    @Published var showingHistory: Bool = false
    
    // Settings
    @Published var enabledOperations: Set<TextOperation> = Set(TextOperation.allCases)
    @Published var autoProcessClipboard: Bool = false
    @Published var showNotifications: Bool = true
    @Published var googleAIKey: String = ""
    
    private var textProcessor = TextProcessor()
    private var clipboardMonitor: ClipboardMonitor?
    
    init() {
        loadSettings()
        setupClipboardMonitoring()
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func processText() {
        guard !inputText.isEmpty else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let startTime = Date()
            let result = self.textProcessor.process(
                text: self.inputText,
                operation: self.selectedOperation,
                apiKey: self.googleAIKey
            )
            let processingTime = Date().timeIntervalSince(startTime)
            
            DispatchQueue.main.async {
                self.outputText = result
                self.isProcessing = false
                
                // Add to history
                let record = ProcessingRecord(
                    id: UUID(),
                    input: self.inputText,
                    output: result,
                    operation: self.selectedOperation,
                    timestamp: Date(),
                    processingTime: processingTime
                )
                self.processingHistory.insert(record, at: 0)
                
                // Show notification if enabled
                if self.showNotifications {
                    self.showProcessingNotification()
                }
            }
        }
    }
    
    private func setupClipboardMonitoring() {
        if autoProcessClipboard {
            clipboardMonitor = ClipboardMonitor { [weak self] text in
                DispatchQueue.main.async {
                    self?.inputText = text
                    self?.processText()
                }
            }
        }
    }
    
    private func showProcessingNotification() {
        let content = UNMutableNotificationContent()
        content.title = "JoyaaS"
        content.body = "Text processed successfully!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
    
    private func loadSettings() {
        // Load from UserDefaults
        let defaults = UserDefaults.standard
        autoProcessClipboard = defaults.bool(forKey: "autoProcessClipboard")
        showNotifications = defaults.bool(forKey: "showNotifications")
        googleAIKey = defaults.string(forKey: "googleAIKey") ?? ""
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(autoProcessClipboard, forKey: "autoProcessClipboard")
        defaults.set(showNotifications, forKey: "showNotifications")
        defaults.set(googleAIKey, forKey: "googleAIKey")
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .processText,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.processText()
        }
        
        NotificationCenter.default.addObserver(
            forName: .clearInput,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.inputText = ""
            self?.outputText = ""
        }
        
        NotificationCenter.default.addObserver(
            forName: .processClipboard,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if let clipboardString = NSPasteboard.general.string(forType: .string) {
                self?.inputText = clipboardString
                self?.processText()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .showHistory,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showingHistory = true
        }
        
        NotificationCenter.default.addObserver(
            forName: .showSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.showingSettings = true
        }
        
        NotificationCenter.default.addObserver(
            forName: .selectOperation,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let operation = notification.object as? TextOperation {
                self?.selectedOperation = operation
            }
        }
    }
}

// MARK: - Data Models
enum TextOperation: String, CaseIterable, Identifiable {
    case layoutFixer = "Layout Fixer"
    case textCleaner = "Text Cleaner"
    case hebrewNikud = "Hebrew Nikud"
    case languageCorrector = "Language Corrector"
    case translator = "Translator"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .layoutFixer: return "keyboard"
        case .textCleaner: return "paintbrush.fill"
        case .hebrewNikud: return "textformat.abc.dottedunderline"
        case .languageCorrector: return "checkmark.circle.fill"
        case .translator: return "globe"
        }
    }
    
    var description: String {
        switch self {
        case .layoutFixer: return "Fix text typed in wrong keyboard layout"
        case .textCleaner: return "Remove formatting artifacts and clean text"
        case .hebrewNikud: return "Add vowelization to Hebrew text"
        case .languageCorrector: return "Fix spelling and grammar"
        case .translator: return "Translate between Hebrew and English"
        }
    }
    
    var requiresAPIKey: Bool {
        switch self {
        case .layoutFixer, .textCleaner: return false
        case .hebrewNikud, .languageCorrector, .translator: return true
        }
    }
}

struct ProcessingRecord: Identifiable, Hashable {
    let id: UUID
    let input: String
    let output: String
    let operation: TextOperation
    let timestamp: Date
    let processingTime: TimeInterval
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ProcessingRecord, rhs: ProcessingRecord) -> Bool {
        return lhs.id == rhs.id
    }
}
