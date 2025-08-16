/*
 * JoyaaS Shared Layout Fixing Algorithm - Swift Implementation
 * ===========================================================
 *
 * This module provides the unified layout fixing algorithm used across all JoyaaS components.
 * It handles Hebrew/English keyboard layout mistakes with high accuracy.
 *
 * Author: JoyaaS Development Team
 * Version: 2.0.0
 * Last Updated: 2025-08-16
 */

import Foundation

/**
 * Unified layout fixing algorithm for Hebrew/English keyboard layout mistakes.
 *
 * This class implements the corrected algorithm that properly handles:
 * - Hebrew text typed in English keyboard layout
 * - English text typed in Hebrew keyboard layout
 * - Mixed content detection and handling
 * - Validation of conversion results
 */
public class LayoutFixer {
    
    // MARK: - Private Properties
    
    /// Accurate Hebrew-to-English mapping based on Israeli keyboard standard
    private let hebrewToEnglish: [Character: Character] = [
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
    
    /// English-to-Hebrew mapping (reverse of above)
    private let englishToHebrew: [Character: Character]
    
    /// Common English words for validation
    private let commonEnglishWords: Set<String> = [
        "hello", "world", "the", "and", "you", "are", "have", "that", "for", "not",
        "with", "will", "can", "said", "what", "about", "out", "time", "there",
        "year", "work", "first", "way", "even", "new", "want", "because", "any",
        "these", "give", "day", "most", "us", "over", "think", "also", "your",
        "after", "use", "man", "now", "old", "see", "him", "two", "how",
        "its", "who", "did", "yes", "his", "has", "had", "let", "put", "say",
        "she", "may", "her", "one", "our", "get"
    ]
    
    /// Common Hebrew words for validation
    private let commonHebrewWords: Set<String> = [
        "שלום", "שלומות", "היי", "כן", "לא", "את", "אני", "הוא", "היא",
        "אנחנו", "אתם", "הם", "מה", "איך", "למה", "איפה", "מתי", "כמה",
        "בוא", "בואי", "לך", "לכי", "לכו", "תודה", "תודות", "סליחה",
        "בסדר", "טוב", "רע", "יפה", "גדול", "קטן", "חדש", "ישן",
        "בית", "בתים", "דלת", "חלון", "שולחן", "כיסא", "מיטה",
        "אוכל", "לחם", "מים", "חלב", "ביצה", "בשר", "דג", "פרי",
        "יום", "לילה", "בוקר", "ערב", "שבת", "חג", "דודו", "דעדע"
    ]
    
    // MARK: - Initialization
    
    public init() {
        // Create reverse mapping: English to Hebrew
        englishToHebrew = Dictionary(uniqueKeysWithValues: hebrewToEnglish.map { ($0.value, $0.key) })
    }
    
    // MARK: - Public Methods
    
    /**
     * Fix text typed in wrong keyboard layout (Hebrew/English).
     *
     * - Parameter text: Input text that may have layout issues
     * - Returns: Corrected text or original text if no correction is needed
     *
     * Examples:
     * ```swift
     * let fixer = LayoutFixer()
     * fixer.fixLayout("susu")  // Hebrew typed in English layout → "דודו"
     * fixer.fixLayout("hello") // Correct English → "hello"
     * ```
     */
    public func fixLayout(_ text: String) -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return text
        }
        
        // Detect script content
        let hebrewChars = text.unicodeScalars.filter { $0.value >= 0x0590 && $0.value <= 0x05FF }.count
        let englishChars = text.filter { $0.isASCII && $0.isLetter }.count
        
        // Rule 1: Mixed content (both Hebrew and English) - never convert
        if hebrewChars > 0 && englishChars > 0 {
            return text
        }
        
        // Rule 2: Too short - never convert single characters
        if text.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            return text
        }
        
        // Rule 3: No alphabetic content - never convert
        if hebrewChars == 0 && englishChars == 0 {
            return text
        }
        
        // Rule 4: Check if this might be a typing mistake
        
        // Case A: Pure Hebrew text that might be English typed wrong
        if hebrewChars > 0 && englishChars == 0 {
            // Check if ALL Hebrew chars can be mapped to English
            let convertibleHebrew = text.filter { hebrewToEnglish.keys.contains($0) }.count
            
            // Only convert if ALL Hebrew characters can be converted
            if convertibleHebrew == hebrewChars && convertibleHebrew >= 2 {
                let candidate = String(text.map { hebrewToEnglish[$0] ?? $0 })
                
                // Additional validation: check if result is reasonable English
                if isReasonableEnglish(candidate) {
                    return candidate
                }
            }
        }
        
        // Case B: Pure English text that might be Hebrew typed wrong
        else if englishChars > 0 && hebrewChars == 0 {
            // Check if ALL English chars can be mapped to Hebrew
            let convertibleEnglish = text.lowercased().filter { $0.isLetter && englishToHebrew.keys.contains($0) }.count
            
            // Only convert if ALL English characters can be converted
            if convertibleEnglish == englishChars && convertibleEnglish >= 2 {
                let candidate = String(text.map { char in
                    if char.isLetter {
                        return englishToHebrew[Character(char.lowercased())] ?? char
                    }
                    return char
                })
                
                // Additional validation: check if result is reasonable Hebrew
                if isReasonableHebrew(candidate) {
                    return candidate
                }
            }
        }
        
        // Default: no conversion
        return text
    }
    
    /**
     * Get the keyboard mappings used by this algorithm.
     *
     * - Returns: Tuple of (hebrewToEnglish, englishToHebrew) mappings
     */
    public func getKeyboardMapping() -> ([Character: Character], [Character: Character]) {
        return (hebrewToEnglish, englishToHebrew)
    }
    
    /**
     * Get information about this algorithm implementation.
     *
     * - Returns: Dictionary with algorithm metadata
     */
    public func getAlgorithmInfo() -> [String: String] {
        return [
            "name": "JoyaaS Layout Fixer",
            "version": "2.0.0",
            "description": "Unified Hebrew/English layout fixing algorithm",
            "author": "JoyaaS Development Team",
            "last_updated": "2025-08-16",
            "supported_languages": "Hebrew, English",
            "keyboard_layout": "Israeli Standard QWERTY"
        ]
    }
    
    // MARK: - Private Methods
    
    /**
     * Check if text looks like reasonable English.
     */
    private func isReasonableEnglish(_ text: String) -> Bool {
        let cleanText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check exact match first
        if commonEnglishWords.contains(cleanText) {
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
    
    /**
     * Check if text looks like reasonable Hebrew.
     */
    private func isReasonableHebrew(_ text: String) -> Bool {
        // Remove spaces for analysis
        let clean = text.replacingOccurrences(of: " ", with: "")
        
        // Check if all characters are Hebrew
        let hebrewChars = clean.unicodeScalars.filter {
            $0.value >= 0x0590 && $0.value <= 0x05FF
        }.count
        
        if hebrewChars != clean.count || clean.count == 0 {
            return false
        }
        
        // Check if it's a known Hebrew word
        if commonHebrewWords.contains(clean) {
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
}

// MARK: - Convenience Functions

/**
 * Convenience function to fix layout issues in text.
 *
 * - Parameter text: Input text that may have layout issues
 * - Returns: Corrected text or original text if no correction is needed
 */
public func fixLayout(_ text: String) -> String {
    let fixer = LayoutFixer()
    return fixer.fixLayout(text)
}

// MARK: - Example Usage and Testing

#if DEBUG
extension LayoutFixer {
    /**
     * Run test cases to verify algorithm functionality.
     * This is only available in debug builds.
     */
    public func runTests() {
        print("JoyaaS Layout Fixer - Swift Algorithm Test")
        print(String(repeating: "=", count: 45))
        
        let testCases: [(String, String)] = [
            ("susu", "דודו"),          // Hebrew typed in English layout
            ("ahbh", "שיני"),          // Hebrew typed in English layout
            ("hello", "hello"),        // Correct English
            ("שלום", "שלום"),          // Correct Hebrew
            ("hello שלום", "hello שלום"), // Mixed content - no change expected
            ("a", "a"),                // Too short
            ("123", "123"),            // No alphabetic content
        ]
        
        print("\nRunning test cases:")
        for (i, (input, expected)) in testCases.enumerated() {
            let result = fixLayout(input)
            let status = result == expected ? "✅ PASS" : "❌ FAIL"
            print("Test \(i + 1): '\(input)' → '\(result)' \(status)")
            if result != expected {
                print("  Expected: '\(expected)'")
            }
        }
        
        // Display algorithm info
        let info = getAlgorithmInfo()
        print("\nAlgorithm Info:")
        for (key, value) in info.sorted(by: { $0.key < $1.key }) {
            let formattedKey = key.replacingOccurrences(of: "_", with: " ").capitalized
            print("  \(formattedKey): \(value)")
        }
    }
}
#endif
