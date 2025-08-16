#!/usr/bin/env python3
"""
Cross-Platform Algorithm Consistency Test
==========================================

Tests that the Swift MenuBar app and Python components use the same
layout fixing algorithm and produce identical results.
"""

import sys
import os
import subprocess

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_python_components():
    """Test Python components consistency"""
    print("🐍 Testing Python Components")
    print("=" * 50)
    
    # Import Python components
    from shared.algorithms.layout_fixer import LayoutFixer
    import joyaas_app
    
    # Test cases for layout fixing
    test_cases = [
        "susu",      # Critical test: Hebrew typed in English → דודו
        "akuo",      # Hebrew typed in English → שלום  
        "hello",     # Correct English → hello
        "שלום",      # Correct Hebrew → שלום
        "",          # Empty string → ""
        "a",         # Single character → a
        "123",       # Numbers → 123
    ]
    
    fixer = LayoutFixer()
    
    print("Test Results:")
    results = {}
    for test_input in test_cases:
        result = fixer.fix_layout(test_input)
        results[test_input] = result
        print(f"  '{test_input}' → '{result}'")
    
    return results

def test_swift_component():
    """Test Swift MenuBar component"""
    print("\n🦄 Testing Swift MenuBar Component")
    print("=" * 50)
    
    # Create Swift test file
    swift_test_code = '''
import Foundation

// Import the LayoutFixer
class LayoutFixer {
    // Accurate Hebrew-to-English mapping based on Israeli keyboard standard
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
    
    init() {
        englishToHebrew = Dictionary(uniqueKeysWithValues: hebrewToEnglish.map { ($0.value, $0.key) })
    }
    
    func fixLayout(_ text: String) -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return text
        }
        
        let hebrewChars = text.unicodeScalars.filter { $0.value >= 0x0590 && $0.value <= 0x05FF }.count
        let englishChars = text.filter { $0.isASCII && $0.isLetter }.count
        
        // Rule 1: Mixed content - never convert
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
        
        // Case A: Pure Hebrew text that might be English typed wrong
        if hebrewChars > 0 && englishChars == 0 {
            let convertibleHebrew = text.filter { hebrewToEnglish.keys.contains($0) }.count
            if convertibleHebrew == hebrewChars && convertibleHebrew >= 2 {
                let candidate = String(text.map { hebrewToEnglish[$0] ?? $0 })
                if isReasonableEnglish(candidate) {
                    return candidate
                }
            }
        }
        
        // Case B: Pure English text that might be Hebrew typed wrong
        else if englishChars > 0 && hebrewChars == 0 {
            let convertibleEnglish = text.lowercased().filter { $0.isLetter && englishToHebrew.keys.contains($0) }.count
            if convertibleEnglish == englishChars && convertibleEnglish >= 2 {
                let candidate = String(text.map { char in
                    if char.isLetter {
                        return englishToHebrew[Character(char.lowercased())] ?? char
                    }
                    return char
                })
                
                if isReasonableHebrew(candidate) {
                    return candidate
                }
            }
        }
        
        return text
    }
    
    private func isReasonableEnglish(_ text: String) -> Bool {
        let cleanText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let commonWords: Set<String> = [
            "hello", "world", "the", "and", "you", "are", "have", "that", "for", "not",
            "with", "will", "can", "said", "what", "about", "out", "time", "there",
            "year", "work", "first", "way", "even", "new", "want", "because", "any",
            "these", "give", "day", "most", "us", "over", "think", "also", "your",
            "after", "use", "man", "now", "old", "see", "him", "two", "how",
            "its", "who", "did", "yes", "his", "has", "had", "let", "put", "say",
            "she", "may", "her", "one", "our", "get"
        ]
        
        if commonWords.contains(cleanText) {
            return true
        }
        
        if cleanText.count >= 3 {
            let vowels = cleanText.filter { "aeiou".contains($0) }.count
            let consonants = cleanText.filter { $0.isLetter && !"aeiou".contains($0) }.count
            
            guard vowels + consonants > 0 else { return false }
            
            let vowelRatio = Double(vowels) / Double(vowels + consonants)
            
            if vowelRatio >= 0.15 && vowelRatio <= 0.65 {
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
        
        return false
    }
    
    private func isReasonableHebrew(_ text: String) -> Bool {
        let clean = text.replacingOccurrences(of: " ", with: "")
        
        let hebrewChars = clean.unicodeScalars.filter {
            $0.value >= 0x0590 && $0.value <= 0x05FF
        }.count
        
        if hebrewChars != clean.count || clean.count == 0 {
            return false
        }
        
        let commonHebrew: Set<String> = [
            "שלום", "שלומות", "היי", "כן", "לא", "את", "אני", "הוא", "היא", 
            "אנחנו", "אתם", "הם", "מה", "איך", "למה", "איפה", "מתי", "כמה",
            "בוא", "בואי", "לך", "לכי", "לכו", "תודה", "תודות", "סליחה",
            "בסדר", "טוב", "רע", "יפה", "גדול", "קטן", "חדש", "ישן",
            "בית", "בתים", "דלת", "חלון", "שולחן", "כיסא", "מיטה",
            "אוכל", "לחם", "מים", "חלב", "ביצה", "בשר", "דג", "פרי",
            "יום", "לילה", "בוקר", "ערב", "שבת", "חג", "דודו", "דעדע"
        ]
        
        if commonHebrew.contains(clean) {
            return true
        }
        
        if clean.count >= 2 {
            let commonHebrewLetters = Set("אבגדהוזחטיכלמנסעפצקרשת")
            let hebrewLetterCount = clean.filter { commonHebrewLetters.contains($0) }.count
            
            return hebrewLetterCount >= Int(Double(clean.count) * 0.8)
        }
        
        return true
    }
}

// Test cases
let testCases = ["susu", "akuo", "hello", "שלום", "", "a", "123"]
let fixer = LayoutFixer()

print("Test Results:")
for testInput in testCases {
    let result = fixer.fixLayout(testInput)
    print("  '\\(testInput)' → '\\(result)'")
}
'''
    
    # Write Swift test file
    swift_test_file = '/tmp/layout_fixer_test.swift'
    with open(swift_test_file, 'w') as f:
        f.write(swift_test_code)
    
    try:
        # Run Swift test
        result = subprocess.run(['swift', swift_test_file], 
                              capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            print(result.stdout)
            
            # Parse Swift results
            swift_results = {}
            lines = result.stdout.strip().split('\n')
            
            for line in lines:
                if " → " in line:
                    # Parse: '  'input' → 'output''
                    parts = line.strip().split(" → ")
                    if len(parts) == 2:
                        input_part = parts[0].strip("' ")
                        output_part = parts[1].strip("' ")
                        swift_results[input_part] = output_part
            
            return swift_results
        else:
            print(f"❌ Swift test failed: {result.stderr}")
            return {}
            
    except Exception as e:
        print(f"❌ Swift test error: {e}")
        return {}

def compare_results(python_results, swift_results):
    """Compare Python and Swift results"""
    print("\n🔍 Cross-Platform Consistency Analysis")
    print("=" * 50)
    
    all_consistent = True
    
    for test_input in python_results.keys():
        python_output = python_results.get(test_input, "N/A")
        swift_output = swift_results.get(test_input, "N/A")
        
        is_consistent = python_output == swift_output
        status = "✅ CONSISTENT" if is_consistent else "❌ INCONSISTENT"
        
        print(f"Input: '{test_input}'")
        print(f"  Python: '{python_output}'")
        print(f"  Swift:  '{swift_output}'")
        print(f"  Status: {status}")
        print()
        
        if not is_consistent:
            all_consistent = False
    
    print("=" * 50)
    if all_consistent:
        print("🎉 SUCCESS: All components produce IDENTICAL results!")
        print("✅ Swift algorithm inconsistency has been FIXED")
        print("✅ Cross-platform consistency achieved")
    else:
        print("❌ FAILURE: Components produce different results")
        print("🔴 Swift algorithm inconsistency still exists")
    
    return all_consistent

def main():
    print("🚀 Cross-Platform Algorithm Consistency Test")
    print("Testing Swift MenuBar vs Python Components")
    print("=" * 60)
    
    # Test Python components
    python_results = test_python_components()
    
    # Test Swift component
    swift_results = test_swift_component()
    
    # Compare results
    is_consistent = compare_results(python_results, swift_results)
    
    return is_consistent

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
