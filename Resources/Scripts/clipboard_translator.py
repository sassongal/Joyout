#!/usr/bin/env python3
"""
clipboard_translator.py - Translates selected text from Hebrew to English
"""

import subprocess
import requests
import json
import os

def get_clipboard_content():
    """Get the current clipboard content"""
    p = subprocess.Popen(['pbpaste'], stdout=subprocess.PIPE)
    content = p.stdout.read().decode('utf-8')
    return content

def set_clipboard_content(content):
    """Set the clipboard content"""
    p = subprocess.Popen(['pbcopy'], stdin=subprocess.PIPE)
    p.communicate(input=content.encode('utf-8'))

def translate_text(text, source_lang="he", target_lang="en"):
    """
    Translate text from source language to target language
    Using a mock API call here - in a real app, this would use a translation API
    like Google Translate, DeepL, or Microsoft Translator
    """
    # In a real implementation, this would be an API call
    # For demonstration purposes, we'll use a simple mock translation
    
    # Example API call (commented out as it requires API key)
    # url = "https://translation-api.example.com/translate"
    # payload = {
    #     "text": text,
    #     "source": source_lang,
    #     "target": target_lang
    # }
    # headers = {
    #     "Content-Type": "application/json",
    #     "Authorization": f"Bearer {os.environ.get('TRANSLATION_API_KEY')}"
    # }
    # response = requests.post(url, json=payload, headers=headers)
    # return response.json()["translated_text"]
    
    # Mock translation for demonstration
    hebrew_to_english = {
        "שלום": "hello",
        "תודה": "thank you",
        "בבקשה": "please",
        "כן": "yes",
        "לא": "no",
        "אני אוהב את זה": "I like this",
        "מה שלומך": "how are you",
        "בוקר טוב": "good morning",
        "לילה טוב": "good night"
    }
    
    # Check if the exact text is in our mock dictionary
    if text in hebrew_to_english:
        return hebrew_to_english[text]
    
    # Otherwise return a placeholder message
    return f"[Translated from Hebrew] {text}"

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
