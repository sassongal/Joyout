#!/usr/bin/env python3
"""
hebrew_nikud.py - Applies vowelization (nikud) to Hebrew text
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

def is_hebrew(text):
    """Check if text contains Hebrew characters"""
    hebrew_chars = sum(1 for c in text if '\u0590' <= c <= '\u05FF')
    return hebrew_chars > 0

def add_nikud(text):
    """
    Add nikud (vowelization) to Hebrew text
    In a real implementation, this would use a Hebrew NLP model or API
    """
    # In a real implementation, this would be an API call to a Hebrew NLP service
    # For demonstration purposes, we'll use a simple mock nikud addition
    
    # Dictionary of common Hebrew words with nikud (for demonstration only)
    nikud_dict = {
        "שלום": "שָׁלוֹם",
        "תודה": "תּוֹדָה",
        "בבקשה": "בְּבַקָּשָׁה",
        "אני": "אֲנִי",
        "אתה": "אַתָּה",
        "את": "אַתְּ",
        "הוא": "הוּא",
        "היא": "הִיא",
        "אנחנו": "אֲנַחְנוּ",
        "אתם": "אַתֶּם",
        "אתן": "אַתֶּן",
        "הם": "הֵם",
        "הן": "הֵן",
        "ילד": "יֶלֶד",
        "ילדה": "יַלְדָּה",
        "בית": "בַּיִת",
        "ספר": "סֵפֶר",
        "לחם": "לֶחֶם",
        "מים": "מַיִם",
        "אוכל": "אֹכֶל"
    }
    
    # Split text into words
    words = re.findall(r'[\u0590-\u05FF]+', text)
    
    # Replace words with nikud versions if available
    for word in words:
        if word in nikud_dict:
            text = text.replace(word, nikud_dict[word])
    
    return text

def main():
    # Get text from clipboard
    text = get_clipboard_content()
    
    if not text:
        print("No text in clipboard")
        return
    
    # Check if text contains Hebrew
    if not is_hebrew(text):
        print("No Hebrew text detected")
        return
    
    # Add nikud to the text
    nikud_text = add_nikud(text)
    
    # Set the text with nikud back to clipboard
    set_clipboard_content(nikud_text)
    
    # Notify user (in a real app, this would use macOS notification)
    print("Nikud added and copied to clipboard")

if __name__ == "__main__":
    main()
