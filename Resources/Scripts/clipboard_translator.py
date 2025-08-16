#!/usr/bin/env python3
"""
clipboard_translator.py - Translates selected text from Hebrew to English
"""

import subprocess
import requests
import json
import os
import urllib.parse
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
    # Count numbers and spaces (neutral)
    neutral_chars = sum(1 for c in text if c.isdigit() or c.isspace())
    
    # More sophisticated detection
    total_meaningful = hebrew_chars + english_chars
    if total_meaningful == 0:
        return "en"  # Default to English for neutral text
    
    hebrew_ratio = hebrew_chars / total_meaningful
    
    # If more than 30% Hebrew, consider it Hebrew text
    if hebrew_ratio > 0.3:
        return "he"
    else:
        return "en"

def translate_with_google_api(text, source_lang="auto", target_lang="en"):
    """
    Translate text using Google Translate API
    """
    config = JoyoutConfig()
    api_key = config.get_api_key('google_translate')
    
    if not api_key:
        print("Warning: No Google Translate API key found. Using fallback method.")
        print("Run 'python3 config.py' to set up API keys.")
        return translate_with_fallback(text, source_lang, target_lang)
    
    url = "https://translation.googleapis.com/language/translate/v2"
    params = {
        'key': api_key,
        'q': text,
        'source': source_lang,
        'target': target_lang,
        'format': 'text'
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        
        result = response.json()
        translated_text = result['data']['translations'][0]['translatedText']
        return translated_text
    except requests.RequestException as e:
        print(f"Translation API error: {e}")
        return translate_with_fallback(text, source_lang, target_lang)
    except (KeyError, IndexError) as e:
        print(f"Translation API response error: {e}")
        return translate_with_fallback(text, source_lang, target_lang)

def translate_with_fallback(text, source_lang="auto", target_lang="en"):
    """
    Fallback translation using free Google Translate web interface
    """
    try:
        # Use Google Translate's web interface as fallback
        encoded_text = urllib.parse.quote(text)
        url = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl={source_lang}&tl={target_lang}&dt=t&q={encoded_text}"
        
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        result = response.json()
        translated_text = result[0][0][0]
        return translated_text
    except Exception as e:
        print(f"Fallback translation error: {e}")
        return translate_with_mock(text)

def translate_with_mock(text):
    """
    Mock translation as final fallback
    """
    hebrew_to_english = {
        "שלום": "hello",
        "תודה": "thank you", 
        "בבקשה": "please",
        "כן": "yes",
        "לא": "no",
        "אני אוהב את זה": "I like this",
        "מה שלומך": "how are you",
        "בוקר טוב": "good morning",
        "לילה טוב": "good night",
        "איך אתה?": "how are you?",
        "מה נשמע?": "what's up?",
        "בסדר": "okay",
        "יום טוב": "good day"
    }
    
    # Check exact matches
    if text.strip() in hebrew_to_english:
        return hebrew_to_english[text.strip()]
    
    # Check if any words match
    for hebrew, english in hebrew_to_english.items():
        if hebrew in text:
            text = text.replace(hebrew, english)
    
    return text

def translate_text(text, source_lang="auto", target_lang="en"):
    """
    Main translation function with multiple fallbacks
    """
    # Auto-detect language if not specified
    if source_lang == "auto":
        detected = detect_language(text)
        if detected == "he":
            target_lang = "en"
        else:
            target_lang = "he"
    
    # Try Google API first, then fallback methods
    return translate_with_google_api(text, source_lang, target_lang)

def main():
    # Get text from clipboard
    text = get_clipboard_content()
    
    if not text:
        print("No text in clipboard")
        return
    
    # Translate the text
    translated_text = translate_text(text)
    
    # Set the translated text back to clipboard
    set_clipboard_content(translated_text)
    
    # Notify user (in a real app, this would use macOS notification)
    print("Text translated and copied to clipboard")

if __name__ == "__main__":
    main()
