#!/usr/bin/env python3
"""
Advanced Language Detection System
==================================

A sophisticated language detection algorithm that provides:
- Confidence scoring for detection accuracy
- Mixed-language handling with segment detection
- Context awareness using patterns and N-grams
- Support for Hebrew, English, and mixed content

Author: JoyaaS Development Team
Version: 2.0.0
"""

from typing import Dict, List, Tuple, Optional, Set
import re
import math
from collections import Counter, defaultdict


class AdvancedLanguageDetector:
    """
    Advanced language detector with confidence scoring and context awareness.
    
    Features:
    - Character-based analysis with Unicode ranges
    - N-gram frequency analysis for better accuracy
    - Common word pattern recognition
    - Mixed content segmentation
    - Confidence scoring based on multiple factors
    """
    
    def __init__(self):
        """Initialize the language detector with patterns and models."""
        self._initialize_patterns()
        self._initialize_ngrams()
        self._initialize_stopwords()
    
    def _initialize_patterns(self):
        """Initialize character patterns and ranges for different languages."""
        
        # Hebrew Unicode ranges
        self.hebrew_range = (0x0590, 0x05FF)
        self.hebrew_letters = set('אבגדהוזחטיכלמנסעפצקרשתםןץףך')
        
        # English patterns
        self.english_letters = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
        
        # Common Hebrew patterns that strongly indicate Hebrew
        self.hebrew_patterns = [
            r'[אבגדהוזחטיכלמנסעפצקרשתםןץףך]{2,}',  # Hebrew letter sequences
            r'ה[אבגדהוזחטיכלמנסעפצקרשתםןץףך]+',        # Definite article
            r'[בלכמש][אבגדהוזחטיכלמנסעפצקרשתםןץףך]+',    # Prepositions
            r'ו[אבגדהוזחטיכלמנסעפצקרשתםןץףך]+',        # Conjunction
        ]
        
        # Common English patterns
        self.english_patterns = [
            r'\b(the|and|you|that|was|for|are|with|his|they)\b',
            r'\b\w+ing\b',      # -ing endings
            r'\b\w+tion\b',     # -tion endings
            r'\b\w+ed\b',       # -ed endings
            r'\b\w+ly\b',       # -ly endings
        ]
    
    def _initialize_ngrams(self):
        """Initialize N-gram models for languages."""
        
        # Hebrew character N-grams (based on Hebrew text patterns)
        self.hebrew_bigrams = {
            'של': 0.15, 'את': 0.12, 'על': 0.10, 'לא': 0.09, 'זה': 0.08,
            'או': 0.07, 'אם': 0.06, 'כל': 0.06, 'גם': 0.05, 'הו': 0.05,
            'היא': 0.04, 'אני': 0.04, 'רק': 0.04, 'עם': 0.04, 'יש': 0.04,
            'היה': 0.03, 'כי': 0.03, 'אין': 0.03, 'מה': 0.03, 'כמו': 0.03
        }
        
        # English character N-grams
        self.english_bigrams = {
            'th': 0.15, 'he': 0.12, 'in': 0.10, 'er': 0.09, 'an': 0.08,
            'ed': 0.07, 're': 0.06, 'nd': 0.06, 'on': 0.05, 'en': 0.05,
            'at': 0.04, 'ou': 0.04, 'it': 0.04, 'is': 0.04, 'or': 0.04,
            'ti': 0.03, 'hi': 0.03, 'as': 0.03, 'to': 0.03, 'le': 0.03
        }
    
    def _initialize_stopwords(self):
        """Initialize common words (stopwords) for each language."""
        
        self.hebrew_stopwords = {
            'של', 'את', 'על', 'לא', 'זה', 'או', 'אם', 'כל', 'גם', 'הוא', 'היא', 'אני',
            'רק', 'עם', 'יש', 'היה', 'כי', 'אין', 'לכל', 'היום', 'הזה', 'אבל', 'שלא',
            'מה', 'כמו', 'אחד', 'פה', 'שם', 'יכול', 'צריך', 'יותר', 'טוב', 'נראה',
            'חושב', 'רוצה', 'דבר', 'פעם', 'שנים', 'חיים', 'עולם', 'בית'
        }
        
        self.english_stopwords = {
            'the', 'and', 'you', 'that', 'was', 'for', 'are', 'with', 'his', 'they',
            'have', 'this', 'will', 'can', 'had', 'her', 'what', 'said', 'each',
            'which', 'she', 'how', 'their', 'if', 'up', 'out', 'many', 'then', 'them',
            'these', 'so', 'some', 'would', 'make', 'like', 'into', 'him', 'has', 'two',
            'more', 'very', 'know', 'just', 'first', 'get', 'over', 'think', 'also'
        }
    
    def detect_language(self, text: str) -> Tuple[str, float, Dict[str, float]]:
        """
        Detect the primary language of text with confidence scoring.
        
        Args:
            text: Input text to analyze
            
        Returns:
            Tuple of (language, confidence, detailed_scores)
            - language: 'hebrew', 'english', 'mixed', or 'unknown'
            - confidence: Float between 0.0 and 1.0
            - detailed_scores: Dict with breakdown of scoring factors
        """
        
        if not text or not text.strip():
            return 'unknown', 0.0, {}
        
        # Analyze different aspects of the text
        char_analysis = self._analyze_characters(text)
        pattern_analysis = self._analyze_patterns(text)
        ngram_analysis = self._analyze_ngrams(text)
        word_analysis = self._analyze_words(text)
        
        # Combine scores with weighted importance
        scores = self._calculate_weighted_scores(
            char_analysis, pattern_analysis, ngram_analysis, word_analysis
        )
        
        # Determine final language and confidence
        language, confidence = self._determine_final_language(scores)
        
        # Detailed scoring breakdown for debugging/analysis
        detailed_scores = {
            'character_scores': char_analysis,
            'pattern_scores': pattern_analysis,
            'ngram_scores': ngram_analysis,
            'word_scores': word_analysis,
            'final_scores': scores
        }
        
        return language, confidence, detailed_scores
    
    def detect_mixed_segments(self, text: str) -> List[Tuple[str, str, float]]:
        """
        Detect language segments in mixed-language text.
        
        Args:
            text: Input text to analyze
            
        Returns:
            List of tuples (segment_text, language, confidence)
        """
        
        if not text or not text.strip():
            return []
        
        # Split text into potential segments
        segments = self._segment_text(text)
        
        results = []
        for segment in segments:
            if segment.strip():
                lang, conf, _ = self.detect_language(segment)
                results.append((segment, lang, conf))
        
        return results
    
    def _analyze_characters(self, text: str) -> Dict[str, float]:
        """Analyze character distribution in text."""
        
        hebrew_chars = 0
        english_chars = 0
        other_chars = 0
        
        for char in text:
            if self.hebrew_range[0] <= ord(char) <= self.hebrew_range[1]:
                hebrew_chars += 1
            elif char.isascii() and char.isalpha():
                english_chars += 1
            elif char.isalpha():
                other_chars += 1
        
        total_alpha = hebrew_chars + english_chars + other_chars
        
        if total_alpha == 0:
            return {'hebrew': 0.0, 'english': 0.0, 'other': 0.0}
        
        return {
            'hebrew': hebrew_chars / total_alpha,
            'english': english_chars / total_alpha,
            'other': other_chars / total_alpha
        }
    
    def _analyze_patterns(self, text: str) -> Dict[str, float]:
        """Analyze language-specific patterns in text."""
        
        hebrew_pattern_score = 0
        english_pattern_score = 0
        
        # Hebrew patterns
        for pattern in self.hebrew_patterns:
            matches = len(re.findall(pattern, text))
            hebrew_pattern_score += matches
        
        # English patterns
        for pattern in self.english_patterns:
            matches = len(re.findall(pattern, text, re.IGNORECASE))
            english_pattern_score += matches
        
        # Normalize by text length
        text_length = max(len(text.split()), 1)
        
        return {
            'hebrew': min(hebrew_pattern_score / text_length, 1.0),
            'english': min(english_pattern_score / text_length, 1.0)
        }
    
    def _analyze_ngrams(self, text: str) -> Dict[str, float]:
        """Analyze N-gram frequency matching."""
        
        # Generate bigrams from text
        bigrams = []
        clean_text = text.lower()
        for i in range(len(clean_text) - 1):
            bigram = clean_text[i:i+2]
            if bigram.isalpha() or any(c in self.hebrew_letters for c in bigram):
                bigrams.append(bigram)
        
        if not bigrams:
            return {'hebrew': 0.0, 'english': 0.0}
        
        bigram_counter = Counter(bigrams)
        total_bigrams = sum(bigram_counter.values())
        
        # Calculate Hebrew score
        hebrew_score = 0
        for bigram, count in bigram_counter.items():
            if bigram in self.hebrew_bigrams:
                hebrew_score += (count / total_bigrams) * self.hebrew_bigrams[bigram]
        
        # Calculate English score
        english_score = 0
        for bigram, count in bigram_counter.items():
            if bigram in self.english_bigrams:
                english_score += (count / total_bigrams) * self.english_bigrams[bigram]
        
        return {
            'hebrew': min(hebrew_score * 10, 1.0),  # Scale factor
            'english': min(english_score * 10, 1.0)
        }
    
    def _analyze_words(self, text: str) -> Dict[str, float]:
        """Analyze common word frequency."""
        
        # Extract words
        words = re.findall(r'\b\w+\b', text.lower())
        
        if not words:
            return {'hebrew': 0.0, 'english': 0.0}
        
        hebrew_word_count = sum(1 for word in words if word in self.hebrew_stopwords)
        english_word_count = sum(1 for word in words if word in self.english_stopwords)
        
        total_words = len(words)
        
        return {
            'hebrew': hebrew_word_count / total_words,
            'english': english_word_count / total_words
        }
    
    def _calculate_weighted_scores(
        self, 
        char_scores: Dict[str, float],
        pattern_scores: Dict[str, float], 
        ngram_scores: Dict[str, float],
        word_scores: Dict[str, float]
    ) -> Dict[str, float]:
        """Calculate weighted final scores for each language."""
        
        # Weights for different analysis types
        weights = {
            'character': 0.3,    # Character distribution
            'pattern': 0.25,     # Language patterns
            'ngram': 0.25,       # N-gram analysis
            'word': 0.2          # Common words
        }
        
        hebrew_score = (
            char_scores.get('hebrew', 0) * weights['character'] +
            pattern_scores.get('hebrew', 0) * weights['pattern'] +
            ngram_scores.get('hebrew', 0) * weights['ngram'] +
            word_scores.get('hebrew', 0) * weights['word']
        )
        
        english_score = (
            char_scores.get('english', 0) * weights['character'] +
            pattern_scores.get('english', 0) * weights['pattern'] +
            ngram_scores.get('english', 0) * weights['ngram'] +
            word_scores.get('english', 0) * weights['word']
        )
        
        return {
            'hebrew': hebrew_score,
            'english': english_score
        }
    
    def _determine_final_language(self, scores: Dict[str, float]) -> Tuple[str, float]:
        """Determine final language and confidence from scores."""
        
        hebrew_score = scores.get('hebrew', 0)
        english_score = scores.get('english', 0)
        
        total_score = hebrew_score + english_score
        
        # Handle edge cases
        if total_score < 0.1:
            return 'unknown', 0.0
        
        # Calculate confidence as the difference between top scores
        if hebrew_score > english_score:
            if hebrew_score > 0.7:
                confidence = min(hebrew_score / total_score, 1.0)
                return 'hebrew', confidence
            elif english_score > 0.3:
                # Mixed content likely
                confidence = 1.0 - abs(hebrew_score - english_score) / total_score
                return 'mixed', confidence
            else:
                confidence = hebrew_score / total_score if total_score > 0 else 0.0
                return 'hebrew', confidence
        
        elif english_score > hebrew_score:
            if english_score > 0.7:
                confidence = min(english_score / total_score, 1.0)
                return 'english', confidence
            elif hebrew_score > 0.3:
                # Mixed content likely
                confidence = 1.0 - abs(hebrew_score - english_score) / total_score
                return 'mixed', confidence
            else:
                confidence = english_score / total_score if total_score > 0 else 0.0
                return 'english', confidence
        
        else:
            # Very close scores - likely mixed
            confidence = max(0.5, 1.0 - abs(hebrew_score - english_score))
            return 'mixed', confidence
    
    def _segment_text(self, text: str) -> List[str]:
        """Segment text into potential language segments."""
        
        # Split on punctuation and whitespace while preserving segments
        segments = []
        current_segment = ""
        current_lang_chars = None
        
        for char in text:
            if char.isspace() or char in '.,!?;:':
                if current_segment.strip():
                    segments.append(current_segment)
                    current_segment = ""
                    current_lang_chars = None
                if not char.isspace():
                    segments.append(char)
            else:
                # Determine character language tendency
                if self.hebrew_range[0] <= ord(char) <= self.hebrew_range[1]:
                    char_lang = 'hebrew'
                elif char.isascii() and char.isalpha():
                    char_lang = 'english'
                else:
                    char_lang = 'other'
                
                # Check for language switch
                if current_lang_chars and current_lang_chars != char_lang and char_lang != 'other':
                    if current_segment.strip():
                        segments.append(current_segment)
                    current_segment = char
                    current_lang_chars = char_lang
                else:
                    current_segment += char
                    if char_lang != 'other':
                        current_lang_chars = char_lang
        
        if current_segment.strip():
            segments.append(current_segment)
        
        return segments
    
    def get_detection_stats(self, text: str) -> Dict[str, any]:
        """Get detailed detection statistics for analysis."""
        
        language, confidence, detailed_scores = self.detect_language(text)
        segments = self.detect_mixed_segments(text)
        
        return {
            'primary_language': language,
            'confidence': confidence,
            'detailed_scores': detailed_scores,
            'segments': segments,
            'text_length': len(text),
            'word_count': len(text.split()),
            'character_distribution': self._analyze_characters(text)
        }


# Convenience functions for backward compatibility
def detect_language_simple(text: str) -> str:
    """Simple language detection returning just the language."""
    detector = AdvancedLanguageDetector()
    language, _, _ = detector.detect_language(text)
    return language


def detect_language_with_confidence(text: str) -> Tuple[str, float]:
    """Language detection with confidence score."""
    detector = AdvancedLanguageDetector()
    language, confidence, _ = detector.detect_language(text)
    return language, confidence


# Example usage and testing
if __name__ == "__main__":
    detector = AdvancedLanguageDetector()
    
    test_cases = [
        "Hello world, how are you today?",
        "שלום עולם, מה שלומך היום?",
        "Hello שלום mixed content",
        "susu should be דודו",
        "akuo should be שלום",
        "This is a longer English text with multiple sentences. It should be detected as English.",
        "זה טקסט ארוך בעברית עם כמה משפטים. זה צריך להיות מזוהה כעברית.",
        "Mixed English and עברית in the same text",
        "",
        "123 numbers only",
        "a",
        "ש"
    ]
    
    print("Advanced Language Detection Test Results")
    print("=" * 60)
    
    for i, test_text in enumerate(test_cases, 1):
        language, confidence, _ = detector.detect_language(test_text)
        print(f"Test {i:2d}: '{test_text[:30]}{'...' if len(test_text) > 30 else ''}'")
        print(f"         Language: {language:<8} Confidence: {confidence:.2f}")
        
        if language == 'mixed':
            segments = detector.detect_mixed_segments(test_text)
            print(f"         Segments: {[(seg[:10], lang, f'{conf:.2f}') for seg, lang, conf in segments]}")
        print()
    
    # Detailed analysis example
    sample_text = "Hello שלום this is mixed content עם עברית"
    stats = detector.get_detection_stats(sample_text)
    print(f"Detailed analysis for: '{sample_text}'")
    print(f"Primary language: {stats['primary_language']}")
    print(f"Confidence: {stats['confidence']:.2f}")
    print(f"Character distribution: {stats['character_distribution']}")
