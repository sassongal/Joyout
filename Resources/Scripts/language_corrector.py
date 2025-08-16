#!/usr/bin/env python3
"""
language_corrector.py - Fixes spelling and grammar issues in Hebrew or English text
"""

import subprocess
import re
import requests
import json
import os
import sys
from pathlib import Path

# Add the Scripts directory to the Python path
scripts_dir = Path(__file__).parent
sys.path.insert(0, str(scripts_dir))

from config import JoyoutConfig

def get_clipboard_content():
    """Get the current clipboard content"""
    p = subprocess.Popen(['pbpaste'], stdout=subprocess.PIPE)
    content = p.stdout.read().decode('utf-8')
    return content

def set_clipboard_content(content):
    """Set the clipboard content"""
    p = subprocess.Popen(['pbcopy'], stdin=subprocess.PIPE)
    p.communicate(input=content.encode('utf-8'))

def detect_language(text):
    """Enhanced language detection for Hebrew vs English"""
    # Count Hebrew characters (including punctuation)
    hebrew_chars = sum(1 for c in text if '\u0590' <= c <= '\u05FF')
    # Count English letters only
    english_chars = sum(1 for c in text if 'a' <= c.lower() <= 'z')
    
    # More sophisticated detection
    total_meaningful = hebrew_chars + english_chars
    if total_meaningful == 0:
        return "english"  # Default to English for neutral text
    
    hebrew_ratio = hebrew_chars / total_meaningful
    
    # If more than 30% Hebrew, consider it Hebrew text
    if hebrew_ratio > 0.3:
        return "hebrew"
    else:
        return "english"

def correct_with_google_ai(text, language):
    """
    Correct text using Google AI (Gemini) API
    """
    config = JoyoutConfig()
    api_key = config.get_api_key('google_ai')
    
    if not api_key:
        print("Warning: No Google AI API key found. Using fallback method.")
        print("Run 'python3 config.py' to set up API keys.")
        return correct_with_fallback(text, language)
    
    model = config.get_setting('google_ai_model', 'gemini-1.5-flash')
    lang_prompt = "Hebrew" if language == "hebrew" else "English"
    
    prompt = f"Please correct the spelling and grammar in this {lang_prompt} text. Only return the corrected text without any explanations or additional formatting:\n\n{text}"
    
    headers = {
        "Content-Type": "application/json"
    }
    
    data = {
        "contents": [{
            "parts": [{
                "text": prompt
            }]
        }],
        "generationConfig": {
            "temperature": 0.1,
            "maxOutputTokens": len(text.split()) * 3 + 100
        }
    }
    
    try:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
        response = requests.post(
            url,
            headers=headers,
            json=data,
            timeout=30
        )
        response.raise_for_status()
        
        result = response.json()
        if 'candidates' in result and len(result['candidates']) > 0:
            corrected_text = result['candidates'][0]['content']['parts'][0]['text'].strip()
            
            # Remove any quotes that might have been added
            if corrected_text.startswith('"') and corrected_text.endswith('"'):
                corrected_text = corrected_text[1:-1]
            
            return corrected_text
        else:
            print("Google AI API: No candidates in response")
            return correct_with_fallback(text, language)
        
    except requests.RequestException as e:
        print(f"Google AI API error: {e}")
        return correct_with_fallback(text, language)
    except (KeyError, IndexError) as e:
        print(f"Google AI API response error: {e}")
        return correct_with_fallback(text, language)

def correct_with_fallback(text, language):
    """
    Fallback correction using basic rules
    """
    if language == "english":
        corrections = {
            "teh": "the",
            "dont": "don't",
            "cant": "can't", 
            "wont": "won't",
            "im": "I'm",
            "ive": "I've",
            "youre": "you're",
            "theyre": "they're",
            "thier": "their",
            "recieve": "receive",
            "definately": "definitely",
            "seperate": "separate",
            "occured": "occurred",
            "alot": "a lot",
            "loose": "lose",
            "its": "it's",
            "your": "you're",
            "then": "than"
        }
        
        # Apply corrections word by word
        words = text.split()
        corrected_words = []
        
        for word in words:
            # Remove punctuation for matching
            clean_word = re.sub(r'[^\w]', '', word.lower())
            if clean_word in corrections:
                # Replace but preserve punctuation
                punct = re.sub(r'\w', '', word)
                corrected_word = corrections[clean_word] + punct
                # Preserve original capitalization pattern
                if word[0].isupper():
                    corrected_word = corrected_word.capitalize()
                corrected_words.append(corrected_word)
            else:
                corrected_words.append(word)
        
        return ' '.join(corrected_words)
    
    elif language == "hebrew":
        # Basic Hebrew corrections
        corrections = {
            "לכול": "לכל",
            "שכול": "שכל",
            "כול": "כל",
            "אני הולכ": "אני הולך",
            "את": "אתה",  # context dependent
            "שלומ": "שלום"
        }
        
        for incorrect, correct in corrections.items():
            text = text.replace(incorrect, correct)
    
    return text

def correct_text(text, language):
    """
    Main correction function that tries Google AI first, then fallback
    """
    return correct_with_google_ai(text, language)

def main():
    # Get text from clipboard
    text = get_clipboard_content()
    
    if not text:
        print("No text in clipboard")
        return
    
    # Detect language
    language = detect_language(text)
    
    # Correct the text
    corrected_text = correct_text(text, language)
    
    # Set the corrected text back to clipboard
    set_clipboard_content(corrected_text)
    
    # Notify user (in a real app, this would use macOS notification)
    print(f"Text corrected ({language}) and copied to clipboard")

if __name__ == "__main__":
    main()
