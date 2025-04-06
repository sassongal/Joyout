#!/usr/bin/env python3
"""
layout_fixer.py - Fixes text typed in the wrong keyboard layout
For example, typing "sus" in English and getting "דוד" in Hebrew
"""

import subprocess
import sys
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

def fix_layout(text):
    """
    Fix text typed in the wrong keyboard layout
    This is a simplified implementation that maps between English and Hebrew layouts
    """
    # English to Hebrew mapping (QWERTY to Hebrew standard layout)
    en_to_he = {
        'q': '/', 'w': "'", 'e': 'ק', 'r': 'ר', 't': 'א', 'y': 'ט', 'u': 'ו', 'i': 'ן', 'o': 'ם', 'p': 'פ',
        'a': 'ש', 's': 'ד', 'd': 'ג', 'f': 'כ', 'g': 'ע', 'h': 'י', 'j': 'ח', 'k': 'ל', 'l': 'ך',
        'z': 'ז', 'x': 'ס', 'c': 'ב', 'v': 'ה', 'b': 'נ', 'n': 'מ', 'm': 'צ',
        ';': 'ף', "'": ',', ',': 'ת', '.': 'ץ', '/': '.'
    }
    
    # Hebrew to English mapping (reverse of the above)
    he_to_en = {v: k for k, v in en_to_he.items()}
    
    # Detect if text is mostly Hebrew or English
    hebrew_chars = sum(1 for c in text if '\u0590' <= c <= '\u05FF')
    
    if hebrew_chars > len(text) / 2:
        # Text is mostly Hebrew, convert to English
        mapping = he_to_en
    else:
        # Text is mostly English, convert to Hebrew
        mapping = en_to_he
    
    # Convert the text
    result = ''
    for char in text:
        lower_char = char.lower()
        if lower_char in mapping:
            # Preserve case if possible
            if char.isupper():
                result += mapping[lower_char].upper()
            else:
                result += mapping[lower_char]
        else:
            result += char
    
    return result

def main():
    # Get text from clipboard
    text = get_clipboard_content()
    
    if not text:
        print("No text in clipboard")
        return
    
    # Fix the layout
    fixed_text = fix_layout(text)
    
    # Set the fixed text back to clipboard
    set_clipboard_content(fixed_text)
    
    # Notify user (in a real app, this would use macOS notification)
    print("Text layout fixed and copied to clipboard")

if __name__ == "__main__":
    main()
