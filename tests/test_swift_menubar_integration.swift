#!/usr/bin/env swift

import Foundation

// Copy the LayoutFixer class from the shared library for testing
class LayoutFixer {
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
    
    private let englishToHebrew: [Character: Character]
    
    private let commonEnglishWords: Set<String> = [
        "hello", "world", "the", "and", "you", "are", "have", "that", "for", "not",
        "with", "will", "can", "said", "what", "about", "out", "time", "there",
        "year", "work", "first", "way", "even", "new", "want", "because", "any",
        "these", "give", "day", "most", "us", "over", "think", "also", "your",
        "after", "use", "man", "now", "old", "see", "him", "two", "how",
        "its", "who", "did", "yes", "his", "has", "had", "let", "put", "say",
        "she", "may", "her", "one", "our", "get"
    ]
    
    private let commonHebrewWords: Set<String> = [
        "שלום", "שלומות", "היי", "כן", "לא", "את", "אני", "הוא", "היא",
        "אנחנו", "אתם", "הם", "מה", "איך", "למה", "איפה", "מתי", "כמה",
        "בוא", "בואי", "לך", "לכי", "לכו", "תודה", "תודות", "סליחה",
        "בסדר", "טוב", "רע", "יפה", "גדול", "קטן", "חדש", "ישן",
        "בית", "בתים", "דלת", "חלון", "שולחן", "כיסא", "מיטה",
        "אוכל", "לחם", "מים", "חלב", "ביצה", "בשר", "דג", "פרי",
        "יום", "לילה", "בוקר", "ערב", "שבת", "חג", "דודו", "דעדע"
    ]
    
    init() {
        englishToHebrew = Dictionary(uniqueKeysWithValues: hebrewToEnglish.map { ($0.value, $0.key) })
    }
    
    func fixLayout(_ text: String) -> String {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return text }
        
        // Detect script content
        let hebrewChars = text.unicodeScalars.filter { CharacterSet(charactersIn: "\u{0590}"..."\u{05FF}").contains($0) }.count
        let englishChars = text.filter { $0.isASCII && $0.isLetter }.count
        
        // Rule 1: Mixed content (both Hebrew and English) - never convert
        if hebrewChars > 0 && englishChars > 0 {
            return text
        }
        
        // Rule 2: Too short - never convert single characters
        if text.trimmingCharacters(in: .whitespaces).count < 2 {
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
    
    private func isReasonableEnglish(_ text: String) -> Bool {
        let cleanText = text.lowercased().trimmingCharacters(in: .whitespaces)
        
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
    
    private func isReasonableHebrew(_ text: String) -> Bool {
        // Remove spaces for analysis
        let clean = text.replacingOccurrences(of: " ", with: "")
        
        // Check if all characters are Hebrew
        let hebrewChars = clean.unicodeScalars.filter {
            CharacterSet(charactersIn: "\u{0590}"..."\u{05FF}").contains($0)
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

// Test the Swift implementation
func runSwiftTests() -> Int {
    print("🚀 Testing Swift MenuBar LayoutFixer Integration")
    print(String(repeating: "=", count: 50))
    
    let fixer = LayoutFixer()
    
    let testCases: [(input: String, expected: String, description: String)] = [
        ("susu", "דודו", "Critical test case: English typed in Hebrew layout"),
        ("hello", "hello", "Pure English should not change"),
        ("שלום", "שלום", "Pure Hebrew should not change"),
        ("akuo", "שלום", "English typed in Hebrew layout"),
        ("hello world", "hello world", "Mixed with space should not change"),
        ("", "", "Empty string should not change"),
        ("a", "a", "Single character should not change"),
        ("123", "123", "Numbers should not change"),
        ("dddd", "גגגג", "Convert if reasonable Hebrew"),
    ]
    
    var passedTests = 0
    let totalTests = testCases.count
    
    for (index, testCase) in testCases.enumerated() {
        let result = fixer.fixLayout(testCase.input)
        let passed = result == testCase.expected
        
        print("\(index + 1). \(testCase.description)")
        print("   Input:    '\(testCase.input)'")
        print("   Expected: '\(testCase.expected)'")
        print("   Actual:   '\(result)'")
        print("   \(passed ? "✅ PASSED" : "❌ FAILED")")
        
        if passed {
            passedTests += 1
        }
        print()
    }
    
    print(String(repeating: "=", count: 50))
    print("📊 Test Results: \(passedTests)/\(totalTests) tests passed")
    
    if passedTests == totalTests {
        print("🎉 All Swift MenuBar tests passed!")
        print("✅ MenuBar app ready for integration with shared algorithm")
    } else {
        print("⚠️  Some Swift tests failed")
    }
    
    return passedTests == totalTests ? 0 : 1
}

// Run the tests
exit(Int32(runSwiftTests()))
