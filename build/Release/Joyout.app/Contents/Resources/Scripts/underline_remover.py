#!/usr/bin/env python3
"""
underline_remover.py - Removes red underlines and formatting artifacts from text
For example, cleaning text copied from OneNote with formatting issues
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

def clean_text(text):
    """
    Clean text by removing formatting artifacts
    - Removes HTML-like tags
    - Removes special characters used for formatting
    - Normalizes whitespace
    """
    # Remove HTML-like tags
    text = re.sub(r'<[^>]+>', '', text)
    
    # Remove special characters often used in formatting
    text = re.sub(r'[\u200B-\u200F\u202A-\u202E]', '', text)  # Remove bidirectional control chars
    
    # Remove zero-width spaces and joiners
    text = re.sub(r'[\u200B\u200C\u200D\uFEFF]', '', text)
    
    # Normalize whitespace (replace multiple spaces with single space)
    text = re.sub(r'\s+', ' ', text)
    
    # Remove leading/trailing whitespace from each line
    lines = text.split('\n')
    lines = [line.strip() for line in lines]
    text = '\n'.join(lines)
    
    return text

def main():
    # Get text from clipboard
    text = get_clipboard_content()
    
    if not text:
        print("No text in clipboard")
        return
    
    # Clean the text
    cleaned_text = clean_text(text)
    
    # Set the cleaned text back to clipboard
    set_clipboard_content(cleaned_text)
    
    # Notify user (in a real app, this would use macOS notification)
    print("Text cleaned and copied to clipboard")

if __name__ == "__main__":
    main()
