#!/usr/bin/env python3
"""
language_corrector.py - Fixes spelling and grammar issues in Hebrew or English text
"""

import subprocess
import re

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
    """Detect if text is primarily Hebrew or English"""
    hebrew_chars = sum(1 for c in text if '\u0590' <= c <= '\u05FF')
    english_chars = sum(1 for c in text if 'a' <= c.lower() <= 'z')
    
    if hebrew_chars > english_chars:
        return "hebrew"
    else:
        return "english"

def correct_text(text, language):
    """
    Correct spelling and grammar in the given text
    In a real implementation, this would use a language model API
    """
    # In a real implementation, this would be an API call to a language model
    # For demonstration purposes, we'll use a simple mock correction
    
    if language == "english":
        # Simple English corrections (for demonstration only)
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
            "alot": "a lot"
        }
        
        # Apply corrections
        words = re.findall(r'\b\w+\b', text.lower())
        for word in words:
            if word in corrections:
                text = re.sub(r'\b' + word + r'\b', corrections[word], text, flags=re.IGNORECASE)
    
    elif language == "hebrew":
        # Simple Hebrew corrections (for demonstration only)
        corrections = {
            "אני הולך לשם": "אני הולך לשם",  # Example correction
            "אני רוצה לאכול": "אני רוצה לאכול"  # Example correction
        }
        
        # Apply corrections
        for incorrect, correct in corrections.items():
            text = text.replace(incorrect, correct)
    
    return text

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
