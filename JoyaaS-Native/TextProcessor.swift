import Foundation

class TextProcessor {
    
    private let pythonScriptPath: String?
    
    init() {
        // Try to find the Python backend
        let bundle = Bundle.main
        self.pythonScriptPath = bundle.path(forResource: "joyaas_app_fixed", ofType: "py")
    }
    
    func process(text: String, operation: TextOperation, apiKey: String = "") -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "⚠️ Please enter some text to process"
        }
        
        switch operation {
        case .layoutFixer:
            return fixLayout(text: text)
        case .textCleaner:
            return cleanText(text: text)
        case .hebrewNikud:
            return addHebrewNikud(text: text, apiKey: apiKey)
        case .languageCorrector:
            return correctLanguage(text: text, apiKey: apiKey)
        case .translator:
            return translateText(text: text, apiKey: apiKey)
        }
    }
    
    // MARK: - Layout Fixer (No API needed)
    private func fixLayout(text: String) -> String {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        
        // Accurate Hebrew-to-English mapping based on Israeli keyboard standard
        let hebrewToEnglish: [Character: Character] = [
            // Top row (QWERTY)
            "ק": "e", "ר": "r", "א": "t", "ט": "y", "ו": "u",
            "ן": "i", "ם": "o", "פ": "p",
            
            // Middle row (ASDF)
            "ש": "a", "ד": "s", "ג": "d", "כ": "f", "ע": "g",
            "י": "h", "ח": "j", "ל": "k", "ך": "l",
            
            // Bottom row (ZXCV)
            "ז": "z", "ס": "x", "ב": "c", "ה": "v", "נ": "b",
            "מ": "n", "צ": "m", "ת": ",", "ץ": "."
        ]
        
        let englishToHebrew = Dictionary(uniqueKeysWithValues: hebrewToEnglish.map { ($1, $0) })
        
        // Count convertible characters in each direction
        let hebrewChars = text.filter { hebrewToEnglish.keys.contains($0) }.count
        let englishChars = text.filter { char in
            char.isLetter && englishToHebrew.keys.contains(Character(char.lowercased()))
        }.count
        
        // Count total alphabetic characters (including Hebrew)
        let totalAlphaChars = text.filter { char in
            char.isLetter || (char >= "\u{0590}" && char <= "\u{05ff}")
        }.count
        
        if totalAlphaChars == 0 {
            return text
        }
        
        // Convert only if more than 60% of alphabetic characters are convertible
        let englishRatio = Double(englishChars) / Double(totalAlphaChars)
        let hebrewRatio = Double(hebrewChars) / Double(totalAlphaChars)
        
        if englishRatio > 0.6 && englishChars > hebrewChars {
            // Convert English to Hebrew
            return String(text.compactMap { char in
                if char.isLetter {
                    return englishToHebrew[Character(char.lowercased())] ?? char
                }
                return char
            })
        } else if hebrewRatio > 0.6 && hebrewChars > englishChars {
            // Convert Hebrew to English
            return String(text.compactMap { char in
                return hebrewToEnglish[char] ?? char
            })
        }
        
        return text
    }
    
    // MARK: - Text Cleaner (No API needed)
    private func cleanText(text: String) -> String {
        var cleaned = text
        
        // Remove multiple spaces
        cleaned = cleaned.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        // Remove excessive underlines
        cleaned = cleaned.replacingOccurrences(of: #"_{2,}"#, with: "", options: .regularExpression)
        
        // Fix excessive punctuation
        cleaned = cleaned.replacingOccurrences(of: #"\.{3,}"#, with: "...", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"!{2,}"#, with: "!", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"\?{2,}"#, with: "?", options: .regularExpression)
        
        // Clean up line breaks
        cleaned = cleaned.replacingOccurrences(of: #"\n\s*\n\s*\n"#, with: "\n\n", options: .regularExpression)
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - AI-Powered Functions (Require API Key)
    private func addHebrewNikud(text: String, apiKey: String) -> String {
        guard !apiKey.isEmpty else { return "⚠️ Google AI API key required for Hebrew Nikud" }
        
        // Try Swift implementation first
        if let result = callGoogleAI(prompt: createNikudPrompt(text), apiKey: apiKey) {
            return result
        }
        
        // Fallback to Python bridge
        if let pythonResult = PythonBridge.shared.executeTextProcessing(
            operation: "hebrew_nikud", 
            text: text, 
            apiKey: apiKey
        ) {
            return pythonResult
        }
        
        return "❌ Failed to add Hebrew nikud. Please check your API key and internet connection."
    }
    
    private func correctLanguage(text: String, apiKey: String) -> String {
        guard !apiKey.isEmpty else { return "⚠️ Google AI API key required for Language Correction" }
        
        let language = detectLanguage(text: text)
        let langName = language == "hebrew" ? "Hebrew" : "English"
        
        // Try Swift implementation first
        if let result = callGoogleAI(prompt: createCorrectionPrompt(text, language: langName), apiKey: apiKey) {
            return result
        }
        
        // Fallback to Python bridge
        if let pythonResult = PythonBridge.shared.executeTextProcessing(
            operation: "language_corrector", 
            text: text, 
            apiKey: apiKey
        ) {
            return pythonResult
        }
        
        return "❌ Failed to correct text. Please check your API key and internet connection."
    }
    
    private func translateText(text: String, apiKey: String) -> String {
        guard !apiKey.isEmpty else { return "⚠️ Google AI API key required for Translation" }
        
        let language = detectLanguage(text: text)
        let targetLang = language == "hebrew" ? "English" : "Hebrew"
        
        // Try Swift implementation first
        if let result = callGoogleAI(prompt: createTranslationPrompt(text, targetLanguage: targetLang), apiKey: apiKey) {
            return result
        }
        
        // Fallback to Python bridge
        if let pythonResult = PythonBridge.shared.executeTextProcessing(
            operation: "translator", 
            text: text, 
            apiKey: apiKey
        ) {
            return pythonResult
        }
        
        return "❌ Failed to translate text. Please check your API key and internet connection."
    }
    
    // MARK: - Helper Functions
    private func detectLanguage(text: String) -> String {
        let hebrewChars = text.unicodeScalars.filter { $0.value >= 0x0590 && $0.value <= 0x05FF }.count
        let englishChars = text.filter { $0.isLetter && $0.isASCII }.count
        
        return hebrewChars > englishChars ? "hebrew" : "english"
    }
    
    private func callGoogleAI(prompt: String, apiKey: String) -> String? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: String?
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 1000
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return nil
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            guard let data = data, error == nil else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    result = text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } catch {
                print("Error parsing AI response: \(error)")
            }
        }.resume()
        
        semaphore.wait()
        return result
    }
    
    private func createNikudPrompt(_ text: String) -> String {
        return """
        Add Hebrew nikud (vowelization) to the following Hebrew text. Only add nikud where needed for proper pronunciation and understanding. Return only the text with nikud added:
        
        \(text)
        """
    }
    
    private func createCorrectionPrompt(_ text: String, language: String) -> String {
        return """
        Fix any spelling and grammar errors in the following \(language) text. Preserve the original meaning and style. Return only the corrected text:
        
        \(text)
        """
    }
    
    private func createTranslationPrompt(_ text: String, targetLanguage: String) -> String {
        return """
        Translate the following text to \(targetLanguage). Preserve meaning and tone:
        
        \(text)
        """
    }
}
