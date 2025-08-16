import Foundation

class TextProcessor: ObservableObject {
    static let shared = TextProcessor()
    
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    // AI API Configuration
    private var googleAPIKey: String? {
        return UserDefaults.standard.string(forKey: "google_api_key")
    }
    
    // Processing statistics
    @Published var totalProcessedCount = 0
    @Published var recentOperations: [ProcessingOperation] = []
    
    struct ProcessingOperation: Identifiable, Codable {
        let id = UUID()
        let operation: String
        let inputLength: Int
        let outputLength: Int
        let duration: TimeInterval
        let timestamp: Date
        let success: Bool
    }
    
    init() {
        loadStatistics()
    }
    
    // NOTE: Keyboard mappings removed - using shared LayoutFixer for consistency
    
    // Common English words to help with detection
    private let commonEnglishWords: Set<String> = [
        "the", "and", "you", "that", "was", "for", "are", "with", "his", "they",
        "have", "this", "will", "can", "had", "her", "what", "said", "each",
        "which", "she", "how", "their", "if", "up", "out", "many", "then", "them",
        "these", "so", "some", "would", "make", "like", "into", "him", "has", "two",
        "more", "very", "what", "know", "just", "first", "get", "over", "think", "also"
    ]
    
    // Common Hebrew words to help with detection  
    private let commonHebrewWords: Set<String> = [
        "של", "את", "על", "לא", "זה", "או", "אם", "כל", "גם", "הוא", "היא", "אני", "רק", "עם", "יש",
        "היה", "כי", "אין", "לכל", "היום", "הזה", "אבל", "שלא", "מה", "כמו", "אחד", "פה", "שם", "יכול",
        "צריך", "יותר", "טוב", "נראה", "חושב", "רוצה", "דבר", "פעם", "שנים", "חיים", "עולם", "בית"
    ]
    
    // Initialize shared layout fixer
    private let sharedLayoutFixer = LayoutFixer()
    
    func fixLayout(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        
        // Use the shared layout fixer algorithm for consistency
        let correctedText = sharedLayoutFixer.fixLayout(text)
        
        recordOperation(operation: "Layout Fixer", inputLength: text.count, outputLength: correctedText.count, duration: 0.1, success: true)
        return correctedText
    }
    
    // NOTE: Removed redundant fixLayoutSimple method - using shared LayoutFixer
    
    private func isReasonableEnglish(_ text: String) -> Bool {
        // Check if text looks like reasonable English
        let cleanText = text.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Very common English words - if it matches, it's probably English
        let commonWords: Set<String> = [
            "hello", "world", "the", "and", "you", "are", "have", "that", "for", "not",
            "with", "will", "can", "said", "what", "about", "out", "time", "there",
            "year", "work", "first", "way", "even", "new", "want", "because", "any",
            "these", "give", "day", "most", "us", "over", "think", "also", "your",
            "after", "use", "man", "now", "old", "see", "him", "two", "how",
            "its", "who", "did", "yes", "his", "has", "had", "let", "put", "say",
            "she", "may", "her", "one", "our", "get"
        ]
        
        // Check exact match first
        if commonWords.contains(cleanText) {
            return true
        }
        
        // For longer words, check vowel/consonant ratio
        if cleanText.count >= 3 {
            let vowels = cleanText.filter { "aeiou".contains($0) }.count
            let consonants = cleanText.filter { $0.isLetter && !"aeiou".contains($0) }.count
            
            guard vowels + consonants > 0 else { return false }
            
            let vowelRatio = Double(vowels) / Double(vowels + consonants)
            
            // English typically has 15-65% vowels
            if vowelRatio >= 0.15 && vowelRatio <= 0.65 {
                // Additional check: no more than 3 consecutive consonants
                var consecutiveConsonants = 0
                var maxConsecutive = 0
                
                for char in cleanText {
                    if char.isLetter && !"aeiou".contains(char) {
                        consecutiveConsonants += 1
                        maxConsecutive = max(maxConsecutive, consecutiveConsonants)
                    } else {
                        consecutiveConsonants = 0
                    }
                }
                
                return maxConsecutive <= 3
            }
        }
        
        // For short words, be more restrictive
        return false
    }
    
    private func isReasonableHebrew(_ text: String) -> Bool {
        // Check if text looks like reasonable Hebrew
        // Remove spaces for analysis
        let clean = text.replacingOccurrences(of: " ", with: "")
        
        // Check if all characters are Hebrew
        let hebrewChars = clean.unicodeScalars.filter { 
            CharacterSet(charactersIn: "\u{0590}"..."\u{05FF}").contains($0) 
        }.count
        
        if hebrewChars != clean.count || clean.count == 0 {
            return false
        }
        
        // Common Hebrew words
        let commonHebrew: Set<String> = [
            "שלום", "שלומות", "היי", "כן", "לא", "את", "אני", "הוא", "היא", 
            "אנחנו", "אתם", "הם", "מה", "איך", "למה", "איפה", "מתי", "כמה",
            "בוא", "בואי", "לך", "לכי", "לכו", "תודה", "תודות", "סליחה",
            "בסדר", "טוב", "רע", "יפה", "גדול", "קטן", "חדש", "ישן",
            "בית", "בתים", "דלת", "חלון", "שולחן", "כיסא", "מיטה",
            "אוכל", "לחם", "מים", "חלב", "ביצה", "בשר", "דג", "פרי",
            "יום", "לילה", "בוקר", "ערב", "שבת", "חג", "דודו", "דעדע"
        ]
        
        // Check if it's a known Hebrew word
        if commonHebrew.contains(clean) {
            return true
        }
        
        // For unknown words, use letter frequency heuristics
        // Hebrew has certain common letters
        if clean.count >= 2 {
            let commonHebrewLetters = Set("אבגדהוזחטיכלמנסעפצקרשת")
            let hebrewLetterCount = clean.filter { commonHebrewLetters.contains($0) }.count
            
            // Most of the letters should be common Hebrew letters
            return hebrewLetterCount >= Int(Double(clean.count) * 0.8)
        }
        
        return true // Default to true for very short text
    }
    
    // NOTE: Removed redundant LayoutAnalyzer class - using shared LayoutFixer
    
    private func convertText(_ text: String, using mapping: [Character: Character]) -> String {
        return String(text.map { char in
            let lowerChar = char.lowercased().first ?? char
            return mapping[lowerChar] ?? char
        })
    }
    
    private func shouldConvert(original: String, converted: String, targetLanguage: String) -> Bool {
        // Don't convert if the result is the same
        guard original != converted else { return false }
        
        // Don't convert if original has good words in its current language
        if targetLanguage == "english" && hasCommonHebrewWords(original) {
            return false
        }
        if targetLanguage == "hebrew" && hasCommonEnglishWords(original) {
            return false
        }
        
        // Check if the converted text has characteristics of the target language
        if targetLanguage == "english" {
            return looksLikeEnglish(converted)
        } else {
            return looksLikeHebrew(converted)
        }
    }
    
    private func hasCommonEnglishWords(_ text: String) -> Bool {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
        
        let commonWordsFound = words.filter { commonEnglishWords.contains($0) }.count
        return commonWordsFound >= min(2, max(1, words.count / 3))
    }
    
    private func hasCommonHebrewWords(_ text: String) -> Bool {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
        
        let commonWordsFound = words.filter { commonHebrewWords.contains($0) }.count
        return commonWordsFound >= min(2, max(1, words.count / 3))
    }
    
    private func looksLikeEnglish(_ text: String) -> Bool {
        // Check for common English patterns and words
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        guard !words.isEmpty else { return false }
        
        // Check for common English words
        let commonWordsFound = words.filter { commonEnglishWords.contains($0) }.count
        if Double(commonWordsFound) / Double(words.count) >= 0.2 {
            return true
        }
        
        // Check for common English patterns
        let hasCommonEnglishPatterns = words.contains { word in
            // Common endings
            word.hasSuffix("ing") || word.hasSuffix("ed") || word.hasSuffix("er") || 
            word.hasSuffix("est") || word.hasSuffix("ly") || word.hasSuffix("tion") ||
            // Common beginnings  
            word.hasPrefix("un") || word.hasPrefix("re") || word.hasPrefix("pre")
        }
        
        return hasCommonEnglishPatterns
    }
    
    private func looksLikeHebrew(_ text: String) -> Bool {
        // Check for Hebrew characteristics
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        guard !words.isEmpty else { return false }
        
        // Check for common Hebrew words
        let commonWordsFound = words.filter { commonHebrewWords.contains($0) }.count
        if Double(commonWordsFound) / Double(words.count) >= 0.2 {
            return true
        }
        
        // Check if most characters are Hebrew
        let hebrewChars = text.filter { char in
            let scalar = char.unicodeScalars.first
            return scalar != nil && CharacterSet.init(charactersIn: "א"..."ת").contains(scalar!)
        }
        
        let totalLetters = text.filter { $0.isLetter }
        if !totalLetters.isEmpty {
            return Double(hebrewChars.count) / Double(totalLetters.count) >= 0.7
        }
        
        return false
    }
    
    func cleanText(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        
        let cleaner = AdvancedTextCleaner()
        let cleanedText = cleaner.cleanText(text)
        
        recordOperation(operation: "Text Cleaner", inputLength: text.count, outputLength: cleanedText.count, duration: 0.1, success: true)
        return cleanedText
    }
    
    private class AdvancedTextCleaner {
        func cleanText(_ text: String) -> String {
            var result = text
            
            // 1. Normalize whitespace
            result = normalizeWhitespace(result)
            
            // 2. Fix punctuation spacing
            result = fixPunctuationSpacing(result)
            
            // 3. Normalize quotation marks and apostrophes
            result = normalizeQuotes(result)
            
            // 4. Remove excessive punctuation
            result = normalizeExcessivePunctuation(result)
            
            // 5. Fix line breaks and paragraphs
            result = normalizeLineBreaks(result)
            
            // 6. Remove unwanted Unicode characters
            result = removeUnwantedCharacters(result)
            
            // 7. Fix common formatting issues
            result = fixCommonFormatting(result)
            
            // 8. Trim and finalize
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return result
        }
        
        private func normalizeWhitespace(_ text: String) -> String {
            // Replace multiple spaces with single space
            var result = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            
            // Replace tabs with spaces
            result = result.replacingOccurrences(of: "\t", with: " ")
            
            // Remove trailing spaces from lines
            let lines = result.components(separatedBy: .newlines)
            result = lines.map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
            
            return result
        }
        
        private func fixPunctuationSpacing(_ text: String) -> String {
            var result = text
            
            // Fix spacing around punctuation - Hebrew and English
            let punctuationRules: [(pattern: String, replacement: String)] = [
                // Remove space before punctuation
                (" \\.", "."),
                (" \\,", ","),
                (" \\!", "!"),
                (" \\?", "?"),
                (" \\:", ":"),
                (" \\;", ";"),
                
                // Ensure space after punctuation (but not at end of line)
                ("\\.(\\S)", ". $1"),
                ("\\,(\\S)", ", $1"),
                ("\\!(\\S)", "! $1"),
                ("\\?(\\S)", "? $1"),
                ("\\:(\\S)", ": $1"),
                ("\\;(\\S)", "; $1"),
                
                // Fix parentheses spacing
                ("\\s*\\(\\s*", " ("),
                ("\\s*\\)\\s*", ") "),
                ("\\(\\s+", "("),
                ("\\s+\\)", ")"),
                
                // Fix brackets spacing
                ("\\s*\\[\\s*", " ["),
                ("\\s*\\]\\s*", "] "),
                ("\\[\\s+", "["),
                ("\\s+\\]", "]"),
            ]
            
            for rule in punctuationRules {
                result = result.replacingOccurrences(of: rule.pattern, with: rule.replacement, options: .regularExpression)
            }
            
            return result
        }
        
        private func normalizeQuotes(_ text: String) -> String {
            var result = text
            
            // Normalize different types of quotes to standard ones
            let quoteNormalization: [(from: String, to: String)] = [
                // Curly quotes to straight quotes
                ("“", "\""),  // Left double quotation mark
                ("”", "\""),  // Right double quotation mark
                ("‘", "'"),   // Left single quotation mark
                ("’", "'"),   // Right single quotation mark
                ("‚", "'"),   // Single low-9 quotation mark
                ("„", "\""), // Double low-9 quotation mark
                ("«", "\""), // Left-pointing double angle quotation mark
                ("»", "\""), // Right-pointing double angle quotation mark
                
                // Different apostrophes
                ("’", "'"),   // Right single quotation mark (apostrophe)
                ("ʼ", "'"),   // Modifier letter apostrophe
            ]
            
            for (from, to) in quoteNormalization {
                result = result.replacingOccurrences(of: from, with: to)
            }
            
            return result
        }
        
        private func normalizeExcessivePunctuation(_ text: String) -> String {
            var result = text
            
            // Fix excessive punctuation
            let punctuationNormalization: [(pattern: String, replacement: String)] = [
                ("\\.\\.\\.\\.+", "..."),  // Multiple periods to ellipsis
                ("!{2,}", "!"),            // Multiple exclamations to single
                ("\\?{2,}", "?"),         // Multiple questions to single
                (":{2,}", ":"),            // Multiple colons to single
                (";{2,}", ";"),            // Multiple semicolons to single
                (",{2,}", ","),            // Multiple commas to single
                
                // Fix mixed excessive punctuation
                ("[!?]{3,}", "?!"),        // Mixed excessive to ?!
                ("\\?!+", "?!"),           // ?!!! to ?!
                ("!\\?+", "!?"),           // !??? to !?
            ]
            
            for (pattern, replacement) in punctuationNormalization {
                result = result.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
            }
            
            return result
        }
        
        private func normalizeLineBreaks(_ text: String) -> String {
            var result = text
            
            // Normalize different line break types
            result = result.replacingOccurrences(of: "\r\n", with: "\n")  // Windows CRLF to LF
            result = result.replacingOccurrences(of: "\r", with: "\n")     // Old Mac CR to LF
            
            // Remove excessive line breaks (more than 2 consecutive)
            result = result.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            
            // Remove line breaks that are just whitespace
            result = result.replacingOccurrences(of: "\n\\s+\n", with: "\n\n", options: .regularExpression)
            
            return result
        }
        
        private func removeUnwantedCharacters(_ text: String) -> String {
            var result = text
            
            // Remove or replace problematic Unicode characters
            let unwantedCharReplacements: [(from: String, to: String)] = [
                (" ", " "),           // Non-breaking space to regular space
                ("​", ""),             // Zero width space
                ("‌", ""),             // Zero width non-joiner
                ("‍", ""),             // Zero width joiner
                ("﻿", ""),             // Zero width no-break space (BOM)
                ("⁠", ""),             // Word joiner
                ("­", ""),             // Soft hyphen
                ("‪", ""),             // Left-to-right embedding
                ("‫", ""),             // Right-to-left embedding
                ("‬", ""),             // Pop directional formatting
                ("‭", ""),             // Left-to-right override
                ("‮", ""),             // Right-to-left override
            ]
            
            for (from, to) in unwantedCharReplacements {
                result = result.replacingOccurrences(of: from, with: to)
            }
            
            // Remove control characters except tab, newline, and carriage return
            result = result.filter { char in
                let scalar = char.unicodeScalars.first!
                // Check if it's a control character using character categories
                let category = scalar.properties.generalCategory
                let isControl = category == .control || category == .format || category == .surrogate || category == .privateUse
                return !isControl || scalar == UnicodeScalar(9) || scalar == UnicodeScalar(10) || scalar == UnicodeScalar(13)
            }
            
            return String(result)
        }
        
        private func fixCommonFormatting(_ text: String) -> String {
            var result = text
            
            // Fix common formatting issues
            let formattingFixes: [(pattern: String, replacement: String)] = [
                // Fix spacing around hyphens and dashes
                ("\\s+-\\s+", " - "),                    // Normalize dash spacing
                ("(\\w)-\\s+(\\w)", "$1-$2"),          // Remove space in hyphenated words
                
                // Fix number formatting
                ("(\\d)\\s*,\\s*(\\d{3})", "$1,$2"),   // Fix number comma spacing
                ("(\\d)\\s*\\.\\s*(\\d)", "$1.$2"),    // Fix decimal point spacing
                
                // Fix URL and email spacing (preserve them)
                ("(https?://)\\s+", "$1"),               // Remove space after protocol
                ("@\\s+(\\w)", "@$1"),                   // Remove space after @ in emails
                
                // Fix common Hebrew/English text issues
                ("([א-ת])\\s+([א-ת]{1,2})\\s+([א-ת])", "$1 $2 $3"), // Hebrew word spacing
                ("([a-zA-Z])\\s+([a-zA-Z]{1,2})\\s+([a-zA-Z])", "$1 $2 $3"),           // English word spacing
            ]
            
            for (pattern, replacement) in formattingFixes {
                result = result.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
            }
            
            return result
        }
    }
    
    func addHebrewNikud(_ text: String) -> String {
        return processWithAI(text: text, operation: "hebrew_nikud")
    }
    
    func correctLanguage(_ text: String) -> String {
        return processWithAI(text: text, operation: "grammar_correction")
    }
    
    func translateText(_ text: String) -> String {
        return processWithAI(text: text, operation: "translation")
    }
    
    // MARK: - AI Integration
    
    private func processWithAI(text: String, operation: String) -> String {
        guard let apiKey = googleAPIKey, !apiKey.isEmpty else {
            // Fallback to basic processing if no API key
            return fallbackProcessing(text: text, operation: operation)
        }
        
        let startTime = Date()
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 1.0
            
            let duration = Date().timeIntervalSince(startTime)
            recordOperation(operation: operation, inputLength: text.count, outputLength: text.count, duration: duration, success: true)
        }
        
        // Simulate AI processing with progress updates
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 1...5 {
                DispatchQueue.main.async {
                    self.processingProgress = Double(i) / 5.0
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        
        // For now, return fallback processing until actual API integration
        return fallbackProcessing(text: text, operation: operation)
    }
    
    private func fallbackProcessing(text: String, operation: String) -> String {
        switch operation {
        case "hebrew_nikud":
            return addBasicNikud(text)
        case "grammar_correction":
            return correctGrammar(text)
        case "translation":
            return translateTextFallback(text)
        default:
            return text
        }
    }
    
    private func correctGrammar(_ text: String) -> String {
        let corrector = AdvancedLanguageCorrectorProcessor()
        return corrector.correctLanguage(text)
    }
    
    private func translateTextFallback(_ text: String) -> String {
        let translator = AdvancedTranslationProcessor()
        return translator.translateText(text)
    }
    
    private class AdvancedLanguageCorrectorProcessor {
        // Hebrew grammar corrections
        private let hebrewGrammarCorrections: [String: String] = [
            // Common spelling mistakes
            "אשתו": "אשתו",
            "אשתה": "אישתה",
            "צירך": "צריך",
            "לאט": "לאת",
            "מלא": "מלא",
            "בעיה": "בעיה",
            "נוסיף": "נוסיף",
            "נוסיע": "נסיעה",
            "דרושה": "דרושה",
            "דרושים": "דרושים",
            "הורידה": "הורידה",
            "אוריד": "אוריד",
            "להביא": "להביא",
            "להבין": "להבין",
            "מבין": "מבין",
            "מביא": "מביא",
            "כוללים": "כוללים",
            "כולל": "כולל",
            "נכלל": "נכלל",
            "עדכן": "עדכן",
            "מעדכן": "מעדכן",
            "מתעדכן": "מתעדכן",
            
            // Gender agreement corrections
            "זה טוב": "זה טוב",
            "זאת טוב": "זאת טובה",
            "הוא טובה": "הוא טוב",
            "היא טוב": "היא טובה",
            "בחור יפה": "בחור יפה",
            "בחורה יפה": "בחורה יפה",
            "איש חכם": "איש חכם",
            "אישה חכם": "אישה חכמה",
            
            // Tense corrections
            "אני הולכ": "אני הולך",
            "אני רוצ": "אני רוצה",
            "הוא רוצ": "הוא רוצה",
            "היא רוצ": "היא רוצה",
            "אתה רוצ": "אתה רוצה",
            "את רוצ": "את רוצה",
            
            // Preposition corrections
            "ב בית": "בבית",
            "ל לכת": "ללכת",
            "מ מקום": "ממקום",
            "כ כמו": "כמו",
            "של של": "של",
            
            // Definite article corrections
            "ה ה": "ה",
            "ה בית": "הבית",
            "ב ה": "בה",
            "ל ה": "לה",
            "מ ה": "מה",
        ]
        
        // English grammar corrections
        private let englishGrammarCorrections: [String: String] = [
            // Common spelling mistakes
            "recieve": "receive",
            "seperate": "separate",
            "definately": "definitely",
            "occured": "occurred",
            "accomodate": "accommodate",
            "acheive": "achieve",
            "beleive": "believe",
            "existance": "existence",
            "independant": "independent",
            "maintainance": "maintenance",
            "neccessary": "necessary",
            "occassion": "occasion",
            "priviledge": "privilege",
            "recomend": "recommend",
            "rythm": "rhythm",
            "sucessful": "successful",
            "tommorow": "tomorrow",
            "untill": "until",
            "wierd": "weird",
            "youre": "you're",
            "its": "it's",
            "there": "their",
            "your": "you're",
            
            // Grammar corrections
            "should of": "should have",
            "could of": "could have",
            "would of": "would have",
            "might of": "might have",
            "must of": "must have",
            "alot": "a lot",
            "everyday": "every day",
            "anyways": "anyway",
            "irregardless": "regardless",
            "supposably": "supposedly",
            
            // Apostrophe corrections
            "dont": "don't",
            "cant": "can't",
            "wont": "won't",
            "shouldnt": "shouldn't",
            "couldnt": "couldn't",
            "wouldnt": "wouldn't",
            "isnt": "isn't",
            "arent": "aren't",
            "wasnt": "wasn't",
            "werent": "weren't",
            "hasnt": "hasn't",
            "havent": "haven't",
            "hadnt": "hadn't",
            "didnt": "didn't",
            "doesnt": "doesn't",
            
            // Capitalization fixes
            "i ": "I ",
            " i ": " I ",
            "i'm": "I'm",
            "i'll": "I'll",
            "i've": "I've",
            "i'd": "I'd",
        ]
        
        // Contextual grammar patterns
        private let contextualCorrections: [(pattern: String, replacement: String)] = [
            // Hebrew contextual corrections
            ("\\bא(\\w+) ו(\\w+)", "א$1 ו$2"),
            ("\\bב(\\w+) ב(\\w+)", "ב$1 ב$2"),
            ("\\bל(\\w+) ל(\\w+)", "ל$1 ל$2"),
            ("\\bמ(\\w+) מ(\\w+)", "מ$1 מ$2"),
            ("\\bש(\\w+) ש(\\w+)", "ש$1 ש$2"),
            
            // English contextual corrections
            ("\\ba (aeiou)", "an $1"),
            ("\\ban ([bcdfghjklmnpqrstvwxyz])", "a $1"),
            ("([.!?])\\s*([a-z])", "$1 \\u$2"),  // Capitalize after sentence end
            ("^([a-z])", "\\u$1"),  // Capitalize first letter
            
            // Double word removal
            ("\\b(\\w+)\\s+\\1\\b", "$1"),
            
            // Multiple spaces to single space (handled in text cleaner but double-check)
            ("\\s{2,}", " "),
            
            // Fix sentence spacing
            ("([.!?])([A-Z])", "$1 $2"),
        ]
        
        // Language-specific patterns
        private let hebrewPatterns = Set("אבגדהוזחטיכלמנסעפצקרשתםןץףך")
        private let englishPatterns = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
        func correctLanguage(_ text: String) -> String {
            guard !text.isEmpty else { return text }
            
            var result = text
            
            // Step 1: Determine primary language
            let primaryLanguage = detectPrimaryLanguage(result)
            
            // Step 2: Apply language-specific corrections
            result = applyLanguageSpecificCorrections(result, language: primaryLanguage)
            
            // Step 3: Apply contextual corrections
            result = applyContextualCorrections(result)
            
            // Step 4: Fix capitalization and punctuation
            result = fixCapitalizationAndPunctuation(result)
            
            // Step 5: Remove redundant spaces and normalize
            result = normalizeSpacing(result)
            
            return result
        }
        
        private func detectPrimaryLanguage(_ text: String) -> String {
            let hebrewCount = text.filter { hebrewPatterns.contains($0) }.count
            let englishCount = text.filter { englishPatterns.contains($0) }.count
            
            let totalLetters = hebrewCount + englishCount
            guard totalLetters > 0 else { return "unknown" }
            
            let hebrewRatio = Double(hebrewCount) / Double(totalLetters)
            
            if hebrewRatio > 0.6 {
                return "hebrew"
            } else if hebrewRatio < 0.4 {
                return "english"
            } else {
                return "mixed"
            }
        }
        
        private func applyLanguageSpecificCorrections(_ text: String, language: String) -> String {
            var result = text
            
            switch language {
            case "hebrew":
                result = applyHebrewCorrections(result)
            case "english":
                result = applyEnglishCorrections(result)
            case "mixed":
                result = applyHebrewCorrections(result)
                result = applyEnglishCorrections(result)
            default:
                break
            }
            
            return result
        }
        
        private func applyHebrewCorrections(_ text: String) -> String {
            var result = text
            
            // Apply Hebrew-specific corrections
            for (error, correction) in hebrewGrammarCorrections {
                result = result.replacingOccurrences(of: error, with: correction)
            }
            
            // Fix Hebrew-specific patterns
            result = fixHebrewSpecificPatterns(result)
            
            return result
        }
        
        private func applyEnglishCorrections(_ text: String) -> String {
            var result = text.lowercased()
            
            // Apply English-specific corrections
            for (error, correction) in englishGrammarCorrections {
                result = result.replacingOccurrences(of: error, with: correction, options: .caseInsensitive)
            }
            
            return result
        }
        
        private func fixHebrewSpecificPatterns(_ text: String) -> String {
            var result = text
            
            // Fix common Hebrew prefix/suffix issues
            let hebrewPatternFixes: [(pattern: String, replacement: String)] = [
                // Fix definite article spacing
                ("ה ([אבגדהוזחטיכלמנסעפצקרשתםןץףך])", "ה$1"),
                
                // Fix preposition spacing
                ("ב ([אבגדהוזחטיכלמנסעפצקרשתםןץףך])", "ב$1"),
                ("ל ([אבגדהוזחטיכלמנסעפצקרשתםןץףך])", "ל$1"),
                ("מ ([אבגדהוזחטיכלמנסעפצקרשתםןץףך])", "מ$1"),
                ("כ ([אבגדהוזחטיכלמנסעפצקרשתםןץףך])", "כ$1"),
                ("ש ([אבגדהוזחטיכלמנסעפצקרשתםןץףך])", "ש$1"),
                
                // Fix conjunctions
                ("ו ([אבגדהוזחטיכלמנסעפצקרשתםןץףך])", "ו$1"),
                
                // Common gender agreement fixes
                ("\\b(\\w*[אבגדהוזחטיכלמנסעפצקרשתםןץףך]+) טוב\\b", "$1 טוב"),
                ("\\b(\\w*[אבגדהוזחטיכלמנסעפצקרשתםןץףך]*ה) טוב\\b", "$1 טובה"),
            ]
            
            for (pattern, replacement) in hebrewPatternFixes {
                result = result.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
            }
            
            return result
        }
        
        private func applyContextualCorrections(_ text: String) -> String {
            var result = text
            
            for (pattern, replacement) in contextualCorrections {
                result = result.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
            }
            
            return result
        }
        
        private func fixCapitalizationAndPunctuation(_ text: String) -> String {
            var result = text
            
            // Fix sentence capitalization
            let sentences = result.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            let correctedSentences = sentences.map { sentence -> String in
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return sentence }
                
                // Capitalize first letter of sentence if it's English
                let firstChar = String(trimmed.prefix(1))
                if englishPatterns.contains(Character(firstChar.lowercased())) {
                    return firstChar.uppercased() + String(trimmed.dropFirst())
                }
                
                return trimmed
            }
            
            // Rejoin with proper punctuation
            result = correctedSentences.joined(separator: ". ")
            
            // Fix common punctuation issues
            result = result.replacingOccurrences(of: " ,", with: ",")
            result = result.replacingOccurrences(of: " .", with: ".")
            result = result.replacingOccurrences(of: " !", with: "!")
            result = result.replacingOccurrences(of: " ?", with: "?")
            result = result.replacingOccurrences(of: " :", with: ":")
            result = result.replacingOccurrences(of: " ;", with: ";")
            
            return result
        }
        
        private func normalizeSpacing(_ text: String) -> String {
            var result = text
            
            // Remove multiple consecutive spaces
            result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            
            // Trim whitespace
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return result
        }
    }
    
    private class AdvancedTranslationProcessor {
        // Hebrew to English common word translations
        private let hebrewToEnglishDict: [String: String] = [
            "שלום": "hello",
            "בוקר טוב": "good morning",
            "ערב טוב": "good evening",
            "לילה טוב": "good night",
            "תודה": "thank you",
            "בבקשה": "please",
            "סליחה": "excuse me",
            "כן": "yes",
            "לא": "no",
            "מה שלומך": "how are you",
            "איך קוראים לך": "what is your name",
            "כמה זה עולה": "how much does it cost",
            "איפה": "where",
            "מה": "what",
            "מי": "who",
            "מתי": "when",
            "למה": "why",
            "איך": "how",
            "בית": "house",
            "מים": "water",
            "אוכל": "food",
            "זמן": "time",
            "כסף": "money",
            "עבודה": "work",
            "משפחה": "family",
            "חברים": "friends",
            "אהבה": "love",
            "שמחה": "happiness",
            "בריאות": "health",
            "חיים": "life",
        ]
        
        // English to Hebrew common word translations
        private let englishToHebrewDict: [String: String] = [
            "hello": "שלום",
            "good morning": "בוקר טוב",
            "good evening": "ערב טוב",
            "good night": "לילה טוב",
            "thank you": "תודה",
            "please": "בבקשה",
            "excuse me": "סליחה",
            "yes": "כן",
            "no": "לא",
            "how are you": "מה שלומך",
            "what is your name": "איך קוראים לך",
            "how much": "כמה",
            "where": "איפה",
            "what": "מה",
            "who": "מי",
            "when": "מתי",
            "why": "למה",
            "how": "איך",
            "house": "בית",
            "water": "מים",
            "food": "אוכל",
            "time": "זמן",
            "money": "כסף",
            "work": "עבודה",
            "family": "משפחה",
            "friends": "חברים",
            "love": "אהבה",
            "happiness": "שמחה",
            "health": "בריאות",
            "life": "חיים",
        ]
        
        func translateText(_ text: String) -> String {
            guard !text.isEmpty else { return text }
            
            // Determine source language
            let language = detectLanguage(text)
            
            switch language {
            case "hebrew":
                return translateHebrewToEnglish(text)
            case "english":
                return translateEnglishToHebrew(text)
            default:
                // For mixed or unknown content, try layout fix first
                let layoutFixed = TextProcessor.shared.fixLayout(text)
                if layoutFixed != text {
                    return layoutFixed
                }
                return text
            }
        }
        
        private func detectLanguage(_ text: String) -> String {
            let hebrewChars = Set("אבגדהוזחטיכלמנסעפצקרשתםןץףך")
            let englishChars = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
            
            let hebrewCount = text.filter { hebrewChars.contains($0) }.count
            let englishCount = text.filter { englishChars.contains($0) }.count
            
            let totalLetters = hebrewCount + englishCount
            guard totalLetters > 0 else { return "unknown" }
            
            let hebrewRatio = Double(hebrewCount) / Double(totalLetters)
            
            if hebrewRatio > 0.7 {
                return "hebrew"
            } else if hebrewRatio < 0.3 {
                return "english"
            } else {
                return "mixed"
            }
        }
        
        private func translateHebrewToEnglish(_ text: String) -> String {
            var result = text.lowercased()
            
            // First, try phrase-based translation (longest matches first)
            let sortedPhrases = hebrewToEnglishDict.keys.sorted { $0.count > $1.count }
            
            for hebrewPhrase in sortedPhrases {
                if let englishPhrase = hebrewToEnglishDict[hebrewPhrase] {
                    result = result.replacingOccurrences(of: hebrewPhrase, with: englishPhrase)
                }
            }
            
            return result
        }
        
        private func translateEnglishToHebrew(_ text: String) -> String {
            var result = text.lowercased()
            
            // First, try phrase-based translation (longest matches first)
            let sortedPhrases = englishToHebrewDict.keys.sorted { $0.count > $1.count }
            
            for englishPhrase in sortedPhrases {
                if let hebrewPhrase = englishToHebrewDict[englishPhrase] {
                    result = result.replacingOccurrences(of: englishPhrase, with: hebrewPhrase)
                }
            }
            
            return result
        }
    }
    
    private func addBasicNikud(_ text: String) -> String {
        let nikudProcessor = AdvancedHebrewNikudProcessor()
        return nikudProcessor.addNikud(to: text)
    }
    
    private class AdvancedHebrewNikudProcessor {
        // Comprehensive Hebrew nikud dictionary with contextual variations
        private let nikudDictionary: [String: [String]] = [
            // Common function words (multiple forms based on context)
            "של": ["שֶׁל"],
            "את": ["אֶת", "אַת", "אֵת"],
            "על": ["עַל"],
            "לא": ["לֹא"],
            "זה": ["זֶה"],
            "או": ["אוֹ"],
            "אם": ["אִם", "אֵם"],
            "כל": ["כָּל", "כֹּל"],
            "גם": ["גַּם"],
            "הוא": ["הוּא"],
            "היא": ["הִיא"],
            "אני": ["אֲנִי"],
            "רק": ["רַק"],
            "עם": ["עִם"],
            "יש": ["יֵשׁ"],
            "היה": ["הָיָה"],
            "כי": ["כִּי"],
            "אין": ["אֵין"],
            "מה": ["מָה", "מַה"],
            "כמו": ["כְּמוֹ"],
            "לכל": ["לְכָל"],
            "היום": ["הַיּוֹם"],
            "הזה": ["הַזֶּה"],
            "אבל": ["אֲבָל"],
            "שלא": ["שֶׁלֹּא"],
            "אחד": ["אֶחָד"],
            "פה": ["פֹּה"],
            "שם": ["שָׁם"],
            "יכול": ["יָכוֹל"],
            "צריך": ["צָרִיךְ"],
            "יותר": ["יוֹתֵר"],
            "טוב": ["טוֹב"],
            "נראה": ["נִרְאֶה"],
            "חושב": ["חוֹשֵׁב"],
            "רוצה": ["רוֹצֶה"],
            "דבר": ["דָּבָר"],
            "פעם": ["פַּעַם"],
            "שנים": ["שָׁנִים"],
            "חיים": ["חַיִּים"],
            "עולם": ["עוֹלָם"],
            "בית": ["בַּיִת"],
            
            // Verbs with different conjugations
            "אמר": ["אָמַר"],
            "אמרתי": ["אָמַרְתִּי"],
            "אמרת": ["אָמַרְתָּ", "אָמַרְתְּ"],
            "אמרנו": ["אָמַרְנוּ"],
            "אמרתם": ["אֲמַרְתֶּם"],
            "אמרו": ["אָמְרוּ"],
            "בא": ["בָּא"],
            "באה": ["בָּאָה"],
            "באים": ["בָּאִים"],
            "באות": ["בָּאוֹת"],
            "הלך": ["הָלַךְ"],
            "הלכה": ["הָלְכָה"],
            "הלכו": ["הָלְכוּ"],
            "עשה": ["עָשָׂה"],
            "עשתה": ["עָשְׂתָה"],
            "עשו": ["עָשׂוּ"],
            
            // Common nouns
            "איש": ["אִישׁ"],
            "אישה": ["אִשָּׁה"],
            "ילד": ["יֶלֶד"],
            "ילדה": ["יַלְדָּה"],
            "ילדים": ["יְלָדִים"],
            "ילדות": ["יְלָדוֹת"],
            "מים": ["מַיִם"],
            "שמים": ["שָׁמַיִם"],
            "ארץ": ["אֶרֶץ"],
            "שמש": ["שֶׁמֶשׁ"],
            "ירח": ["יָרֵחַ"],
            "לילה": ["לַיְלָה"],
            "יום": ["יוֹם"],
            "בוקר": ["בֹּקֶר"],
            "ערב": ["עֶרֶב"],
            
            // Adjectives
            "גדול": ["גָּדוֹל"],
            "גדולה": ["גְּדוֹלָה"],
            "קטן": ["קָטָן"],
            "קטנה": ["קְטַנָּה"],
            "יפה": ["יָפֶה", "יָפָה"], // both masculine and feminine forms
            "חדש": ["חָדָשׁ"],
            "חדשה": ["חֲדָשָׁה"],
            "ישן": ["יָשָׁן"],
            "ישנה": ["יְשָׁנָה"],
        ]
        
        // Hebrew character vowel patterns for pattern-based nikud
        private let vowelPatterns: [(pattern: String, nikud: String)] = [
            // Common patterns in Hebrew
            ("קטל", "קָטַל"),      // pa'al verb pattern
            ("פעל", "פָּעַל"),      // pa'al verb pattern
            ("שמר", "שָׁמַר"),      // pa'al verb pattern
            ("למד", "לָמַד"),      // pa'al verb pattern
            ("כתב", "כָּתַב"),      // pa'al verb pattern
            ("קרא", "קָרָא"),      // pa'al verb pattern
            
            // Pi'el patterns
            ("דבר", "דִּבֵּר"),     // pi'el pattern
            ("חפש", "חִפֵּשׂ"),     // pi'el pattern
            ("בקש", "בִּקֵּשׁ"),     // pi'el pattern
            
            // Hif'il patterns
            ("הגיד", "הִגִּיד"),    // hif'il pattern
            ("הביא", "הֵבִיא"),    // hif'il pattern
            ("הלך", "הוֹלִיךְ"),    // hif'il pattern
        ]
        
        // Context analysis patterns
        private let contextPatterns: [String: String] = [
            // Definite articles
            "ה": "הַ",
            
            // Prepositions
            "ב": "בְּ",
            "ל": "לְ",
            "כ": "כְּ",
            "מ": "מִ",
            
            // Common prefixes
            "ו": "וְ",
            "ש": "שֶׁ",
        ]
        
        func addNikud(to text: String) -> String {
            guard !text.isEmpty else { return text }
            
            // Step 1: Word-by-word processing
            let words = text.components(separatedBy: .whitespacesAndNewlines)
            let processedWords = words.map { processWord($0) }
            let result = processedWords.joined(separator: " ")
            
            // Step 2: Apply contextual rules
            return applyContextualRules(result)
        }
        
        private func processWord(_ word: String) -> String {
            // Remove punctuation for processing but preserve it
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            let punctuation = String(word.dropFirst(cleanWord.count))
            
            guard !cleanWord.isEmpty else { return word }
            
            // Step 1: Check exact dictionary matches
            if let nikudVersions = nikudDictionary[cleanWord.lowercased()] {
                let selectedVersion = selectBestNikudVersion(nikudVersions, for: cleanWord)
                return selectedVersion + punctuation
            }
            
            // Step 2: Handle prefixed words (ה, ב, ל, כ, מ, ו, ש)
            if let processedWithPrefix = handlePrefixedWord(cleanWord) {
                return processedWithPrefix + punctuation
            }
            
            // Step 3: Apply pattern-based nikud
            if let processedWithPattern = applyPatternBasedNikud(cleanWord) {
                return processedWithPattern + punctuation
            }
            
            // Step 4: Apply default vowelization for unknown words
            let defaultNikud = applyDefaultVowelization(cleanWord)
            return defaultNikud + punctuation
        }
        
        private func selectBestNikudVersion(_ versions: [String], for word: String) -> String {
            // For now, return the first (most common) version
            // In a more advanced implementation, this would analyze context
            return versions.first ?? word
        }
        
        private func handlePrefixedWord(_ word: String) -> String? {
            guard word.count > 1 else { return nil }
            
            let firstChar = String(word.prefix(1))
            let remainder = String(word.dropFirst())
            
            // Check if it's a known prefix
            if let prefixNikud = contextPatterns[firstChar] {
                // Recursively process the remainder
                let processedRemainder = processWord(remainder)
                return prefixNikud + processedRemainder
            }
            
            return nil
        }
        
        private func applyPatternBasedNikud(_ word: String) -> String? {
            // Check if word matches any vowel patterns
            for (pattern, nikudPattern) in vowelPatterns {
                if word.count == pattern.count && hasMatchingPattern(word, pattern) {
                    return nikudPattern
                }
            }
            return nil
        }
        
        private func hasMatchingPattern(_ word: String, _ pattern: String) -> Bool {
            // Simple pattern matching - in a real implementation this would be more sophisticated
            let wordChars = Array(word)
            let patternChars = Array(pattern)
            
            guard wordChars.count == patternChars.count else { return false }
            
            // Check if consonants match (ignoring specific letters, focusing on structure)
            for i in 0..<wordChars.count {
                let wordChar = wordChars[i]
                let patternChar = patternChars[i]
                
                // This is a simplified check - real implementation would use Hebrew root analysis
                if isHebrewConsonant(wordChar) && isHebrewConsonant(patternChar) {
                    continue
                } else if wordChar != patternChar {
                    return false
                }
            }
            
            return true
        }
        
        private func isHebrewConsonant(_ char: Character) -> Bool {
            let hebrewConsonants = "אבגדהוזחטיכלמנסעפצקרשתךםןףץ"
            return hebrewConsonants.contains(char)
        }
        
        private func applyDefaultVowelization(_ word: String) -> String {
            // Apply basic vowelization rules for unknown Hebrew words
            var result = word
            
            // Add shva to consonants that typically need it
            let shvaPositions = findShvaPositions(word)
            for position in shvaPositions.reversed() {
                let index = result.index(result.startIndex, offsetBy: position)
                result.insert("ְ", at: result.index(after: index))
            }
            
            // Add basic vowels to common positions
            result = addBasicVowels(result)
            
            return result
        }
        
        private func findShvaPositions(_ word: String) -> [Int] {
            var positions: [Int] = []
            let chars = Array(word)
            
            for i in 0..<chars.count - 1 {
                let currentChar = chars[i]
                let nextChar = chars[i + 1]
                
                // Add shva between consecutive consonants (simplified rule)
                if isHebrewConsonant(currentChar) && isHebrewConsonant(nextChar) {
                    positions.append(i)
                }
            }
            
            return positions
        }
        
        private func addBasicVowels(_ word: String) -> String {
            var result = word
            
            // Very basic vowelization - add kamatz to first consonant if no vowel present
            if let firstConsonantIndex = result.firstIndex(where: { isHebrewConsonant($0) }) {
                let nextIndex = result.index(after: firstConsonantIndex)
                if nextIndex < result.endIndex && isHebrewConsonant(result[nextIndex]) {
                    result.insert("ָ", at: nextIndex) // kamatz
                }
            }
            
            return result
        }
        
        private func applyContextualRules(_ text: String) -> String {
            var result = text
            
            // Apply contextual rules for better nikud accuracy
            let contextualRules: [(pattern: String, replacement: String)] = [
                // Fix definite article combinations
                ("הַה", "הָה"),
                ("בְּב", "בַּב"),
                ("לְל", "לַל"),
                ("כְּכ", "כַּכ"),
                
                // Fix common combinations
                ("אֶלְ", "אֶל"),
                ("עַלְ", "עַל"),
                ("מִן", "מִן"),
                
                // Fix sentence beginnings
                ("וְה", "וְהַ"),
                ("וְב", "וּבְ"),
                ("וְל", "וּלְ"),
            ]
            
            for rule in contextualRules {
                result = result.replacingOccurrences(of: rule.pattern, with: rule.replacement)
            }
            
            return result
        }
    }
    
    // MARK: - Statistics and Analytics
    
    private func recordOperation(operation: String, inputLength: Int, outputLength: Int, duration: TimeInterval, success: Bool) {
        let processingOp = ProcessingOperation(
            operation: operation,
            inputLength: inputLength,
            outputLength: outputLength,
            duration: duration,
            timestamp: Date(),
            success: success
        )
        
        DispatchQueue.main.async {
            self.recentOperations.insert(processingOp, at: 0)
            if self.recentOperations.count > 100 {
                self.recentOperations = Array(self.recentOperations.prefix(100))
            }
            
            if success {
                self.totalProcessedCount += 1
            }
            
            self.saveStatistics()
        }
    }
    
    func getProcessingStats() -> ProcessingStats {
        let operations = recentOperations.prefix(50)
        let averageDuration = operations.isEmpty ? 0 : operations.reduce(0) { $0 + $1.duration } / Double(operations.count)
        
        let operationCounts = Dictionary(grouping: operations, by: { $0.operation })
            .mapValues { $0.count }
        
        let mostUsedOperation = operationCounts.max(by: { $0.value < $1.value })?.key ?? "Layout Fixer"
        
        return ProcessingStats(
            totalOperations: totalProcessedCount,
            recentOperationsCount: operations.count,
            averageDuration: averageDuration,
            mostUsedOperation: mostUsedOperation,
            operationBreakdown: operationCounts
        )
    }
    
    struct ProcessingStats {
        let totalOperations: Int
        let recentOperationsCount: Int
        let averageDuration: TimeInterval
        let mostUsedOperation: String
        let operationBreakdown: [String: Int]
    }
    
    // MARK: - Batch Processing
    
    func processBatch(_ items: [String], operation: String, completion: @escaping ([String]) -> Void) {
        NotificationManager.shared.showBatchProcessingStarted(itemCount: items.count)
        let startTime = Date()
        
        DispatchQueue.global(qos: .userInitiated).async {
            var results: [String] = []
            
            for (index, item) in items.enumerated() {
                let processed = self.processText(item, operation: operation)
                results.append(processed)
                
                DispatchQueue.main.async {
                    self.processingProgress = Double(index + 1) / Double(items.count)
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            DispatchQueue.main.async {
                NotificationManager.shared.showBatchProcessingComplete(itemCount: items.count, duration: duration)
                completion(results)
            }
        }
    }
    
    private func processText(_ text: String, operation: String) -> String {
        switch operation {
        case "Layout Fixer":
            return fixLayout(text)
        case "Text Cleaner":
            return cleanText(text)
        case "Hebrew Nikud":
            return addHebrewNikud(text)
        case "Language Corrector":
            return correctLanguage(text)
        case "Translator":
            return translateText(text)
        default:
            return text
        }
    }
    
    // MARK: - Persistence
    
    private func saveStatistics() {
        if let data = try? JSONEncoder().encode(recentOperations) {
            UserDefaults.standard.set(data, forKey: "processing_history")
        }
        UserDefaults.standard.set(totalProcessedCount, forKey: "total_processed_count")
    }
    
    private func loadStatistics() {
        if let data = UserDefaults.standard.data(forKey: "processing_history"),
           let operations = try? JSONDecoder().decode([ProcessingOperation].self, from: data) {
            recentOperations = operations
        }
        
        totalProcessedCount = UserDefaults.standard.integer(forKey: "total_processed_count")
    }
    
    // MARK: - API Key Management
    
    func setGoogleAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "google_api_key")
    }
    
    func hasValidAPIKey() -> Bool {
        guard let key = googleAPIKey else { return false }
        return !key.isEmpty && key.count > 20
    }
    
    func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: "google_api_key")
    }
}
