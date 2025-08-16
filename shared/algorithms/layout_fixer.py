#!/usr/bin/env python3
"""
JoyaaS Shared Layout Fixing Algorithm
=====================================

This module provides the unified layout fixing algorithm used across all JoyaaS components.
It handles Hebrew/English keyboard layout mistakes with high accuracy.

Author: JoyaaS Development Team
Version: 2.0.0
Last Updated: 2025-08-16
"""

from typing import Dict, Set, Tuple, Optional


class LayoutFixer:
    """
    Unified layout fixing algorithm for Hebrew/English keyboard layout mistakes.
    
    This class implements the corrected algorithm that properly handles:
    - Hebrew text typed in English keyboard layout
    - English text typed in Hebrew keyboard layout
    - Mixed content detection and handling
    - Validation of conversion results
    """
    
    def __init__(self):
        """Initialize the LayoutFixer with keyboard mappings and validation data."""
        # Accurate Hebrew-to-English mapping based on Israeli keyboard standard
        self._hebrew_to_english: Dict[str, str] = {
            # Top row (QWERTY)
            'ק': 'e', 'ר': 'r', 'א': 't', 'ט': 'y', 'ו': 'u',
            'ן': 'i', 'ם': 'o', 'פ': 'p',
            
            # Middle row (ASDF)
            'ש': 'a', 'ד': 's', 'ג': 'd', 'כ': 'f', 'ע': 'g',
            'י': 'h', 'ח': 'j', 'ל': 'k', 'ך': 'l',
            
            # Bottom row (ZXCV)
            'ז': 'z', 'ס': 'x', 'ב': 'c', 'ה': 'v', 'נ': 'b',
            'מ': 'n', 'צ': 'm', 'ת': ',', 'ץ': '.'
        }
        
        # Create reverse mapping: English to Hebrew
        self._english_to_hebrew: Dict[str, str] = {v: k for k, v in self._hebrew_to_english.items()}
        
        # Common English words for validation
        self._common_english_words: Set[str] = {
            'hello', 'world', 'the', 'and', 'you', 'are', 'have', 'that', 'for', 'not',
            'with', 'will', 'can', 'said', 'what', 'about', 'out', 'time', 'there',
            'year', 'work', 'first', 'way', 'even', 'new', 'want', 'because', 'any',
            'these', 'give', 'day', 'most', 'us', 'over', 'think', 'also', 'your',
            'after', 'use', 'man', 'now', 'old', 'see', 'him', 'two', 'how',
            'its', 'who', 'did', 'yes', 'his', 'has', 'had', 'let', 'put', 'say',
            'she', 'may', 'her', 'one', 'our', 'get'
        }
        
        # Common Hebrew words for validation
        self._common_hebrew_words: Set[str] = {
            'שלום', 'שלומות', 'היי', 'כן', 'לא', 'את', 'אני', 'הוא', 'היא', 
            'אנחנו', 'אתם', 'הם', 'מה', 'איך', 'למה', 'איפה', 'מתי', 'כמה',
            'בוא', 'בואי', 'לך', 'לכי', 'לכו', 'תודה', 'תודות', 'סליחה',
            'בסדר', 'טוב', 'רע', 'יפה', 'גדול', 'קטן', 'חדש', 'ישן',
            'בית', 'בתים', 'דלת', 'חלון', 'שולחן', 'כיסא', 'מיטה',
            'אוכל', 'לחם', 'מים', 'חלב', 'ביצה', 'בשר', 'דג', 'פרי',
            'יום', 'לילה', 'בוקר', 'ערב', 'שבת', 'חג', 'דודו', 'דעדע'
        }
    
    def fix_layout(self, text: str) -> str:
        """
        Fix text typed in wrong keyboard layout (Hebrew/English).
        
        Args:
            text: Input text that may have layout issues
            
        Returns:
            Corrected text or original text if no correction is needed
            
        Examples:
            >>> fixer = LayoutFixer()
            >>> fixer.fix_layout("susu")  # Hebrew typed in English layout
            "דודו"
            >>> fixer.fix_layout("hello")  # Correct English
            "hello"
        """
        if not text or not text.strip():
            return text
        
        # Detect script content
        hebrew_chars = sum(1 for c in text if '\u0590' <= c <= '\u05ff')
        english_chars = sum(1 for c in text if c.isascii() and c.isalpha())
        
        # Rule 1: Mixed content (both Hebrew and English) - never convert
        if hebrew_chars > 0 and english_chars > 0:
            return text
            
        # Rule 2: Too short - never convert single characters
        if len(text.strip()) < 2:
            return text
        
        # Rule 3: No alphabetic content - never convert
        if hebrew_chars == 0 and english_chars == 0:
            return text
        
        # Rule 4: Check if this might be a typing mistake
        
        # Case A: Pure Hebrew text that might be English typed wrong
        if hebrew_chars > 0 and english_chars == 0:
            # Check if ALL Hebrew chars can be mapped to English
            convertible_hebrew = sum(1 for c in text if c in self._hebrew_to_english)
            
            # Only convert if ALL Hebrew characters can be converted
            if convertible_hebrew == hebrew_chars and convertible_hebrew >= 2:
                candidate = ''.join(self._hebrew_to_english.get(c, c) for c in text)
                
                # Additional validation: check if result is reasonable English
                if self._is_reasonable_english(candidate):
                    return candidate
        
        # Case B: Pure English text that might be Hebrew typed wrong  
        elif english_chars > 0 and hebrew_chars == 0:
            # Check if ALL English chars can be mapped to Hebrew
            convertible_english = sum(1 for c in text.lower() if c.isalpha() and c in self._english_to_hebrew)
            
            # Only convert if ALL English characters can be converted
            if convertible_english == english_chars and convertible_english >= 2:
                candidate = ''.join(self._english_to_hebrew.get(c.lower(), c) if c.isalpha() else c for c in text)
                
                # Additional validation: check if result is reasonable Hebrew
                if self._is_reasonable_hebrew(candidate):
                    return candidate
        
        # Default: no conversion
        return text
    
    def _is_reasonable_english(self, text: str) -> bool:
        """Check if text looks like reasonable English."""
        text = text.lower().strip()
        
        # Check exact match first
        if text in self._common_english_words:
            return True
        
        # For longer words, check vowel/consonant ratio
        if len(text) >= 3:
            vowels = sum(1 for c in text if c in 'aeiou')
            consonants = sum(1 for c in text if c.isalpha() and c not in 'aeiou')
            
            if vowels + consonants == 0:
                return False
                
            vowel_ratio = vowels / (vowels + consonants)
            
            # English typically has 15-65% vowels
            if 0.15 <= vowel_ratio <= 0.65:
                # Additional check: no more than 3 consecutive consonants
                consecutive_consonants = 0
                max_consecutive = 0
                
                for c in text:
                    if c.isalpha() and c not in 'aeiou':
                        consecutive_consonants += 1
                        max_consecutive = max(max_consecutive, consecutive_consonants)
                    else:
                        consecutive_consonants = 0
                        
                return max_consecutive <= 3
        
        # For short words, be more restrictive
        return False
    
    def _is_reasonable_hebrew(self, text: str) -> bool:
        """Check if text looks like reasonable Hebrew."""
        # Remove spaces for analysis
        clean = text.replace(' ', '')
        
        # Check if all characters are Hebrew
        hebrew_chars = sum(1 for c in clean if '\u0590' <= c <= '\u05ff')
        
        if hebrew_chars != len(clean) or len(clean) == 0:
            return False
        
        # Check if it's a known Hebrew word
        if clean in self._common_hebrew_words:
            return True
        
        # For unknown words, use letter frequency heuristics
        # Hebrew has certain common letters
        if len(clean) >= 2:
            common_hebrew_letters = set('אבגדהוזחטיכלמנסעפצקרשת')
            hebrew_letter_count = sum(1 for c in clean if c in common_hebrew_letters)
            
            # Most of the letters should be common Hebrew letters
            return hebrew_letter_count >= len(clean) * 0.8
        
        return True  # Default to true for very short text
    
    def get_keyboard_mapping(self) -> Tuple[Dict[str, str], Dict[str, str]]:
        """
        Get the keyboard mappings used by this algorithm.
        
        Returns:
            Tuple of (hebrew_to_english, english_to_hebrew) mappings
        """
        return self._hebrew_to_english.copy(), self._english_to_hebrew.copy()
    
    def get_algorithm_info(self) -> Dict[str, str]:
        """
        Get information about this algorithm implementation.
        
        Returns:
            Dictionary with algorithm metadata
        """
        return {
            'name': 'JoyaaS Layout Fixer',
            'version': '2.0.0',
            'description': 'Unified Hebrew/English layout fixing algorithm',
            'author': 'JoyaaS Development Team',
            'last_updated': '2025-08-16',
            'supported_languages': 'Hebrew, English',
            'keyboard_layout': 'Israeli Standard QWERTY'
        }


# Convenience function for direct usage
def fix_layout(text: str) -> str:
    """
    Convenience function to fix layout issues in text.
    
    Args:
        text: Input text that may have layout issues
        
    Returns:
        Corrected text or original text if no correction is needed
    """
    fixer = LayoutFixer()
    return fixer.fix_layout(text)


# Example usage and testing
if __name__ == "__main__":
    # Test the algorithm
    print("JoyaaS Layout Fixer - Algorithm Test")
    print("=" * 40)
    
    fixer = LayoutFixer()
    
    test_cases = [
        ("susu", "דודו"),      # Hebrew typed in English layout
        ("ahbh", "שיני"),      # Hebrew typed in English layout (corrected)
        ("hello", "hello"),     # Correct English
        ("שלום", "שלום"),       # Correct Hebrew
        ("hello שלום", "hello שלום"), # Mixed content - no change expected
        ("a", "a"),             # Too short
        ("123", "123"),         # No alphabetic content
    ]
    
    print("\nRunning test cases:")
    for i, (input_text, expected) in enumerate(test_cases, 1):
        result = fixer.fix_layout(input_text)
        status = "✅ PASS" if (expected is None and result == input_text) or result == expected else "❌ FAIL"
        print(f"Test {i}: '{input_text}' → '{result}' {status}")
        if expected and result != expected:
            print(f"  Expected: '{expected}'")
    
    # Display algorithm info
    info = fixer.get_algorithm_info()
    print(f"\nAlgorithm Info:")
    for key, value in info.items():
        print(f"  {key.replace('_', ' ').title()}: {value}")
