#!/usr/bin/env python3
"""
hebrew_nikud.py - Applies vowelization (nikud) to Hebrew text
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

def is_hebrew(text):
    """Check if text contains Hebrew characters"""
    hebrew_chars = sum(1 for c in text if '\u0590' <= c <= '\u05FF')
    return hebrew_chars > 0

def add_nikud_with_api(text):
    """
    Add nikud using Google AI (Gemini) API
    """
    config = JoyoutConfig()
    api_key = config.get_api_key('google_ai')
    
    if not api_key:
        print("Warning: No Google AI API key found. Using fallback method.")
        print("Run 'python3 config.py' to set up API keys.")
        return add_nikud_with_fallback(text)
    
    model = config.get_setting('google_ai_model', 'gemini-1.5-flash')
    prompt = f"Add Hebrew vowelization (nikud) to this Hebrew text. Only return the text with nikud points added, no explanations or additional text:\n\n{text}"
    
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
            "maxOutputTokens": len(text) * 2 + 100
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
            nikud_text = result['candidates'][0]['content']['parts'][0]['text'].strip()
            
            # Remove any quotes that might have been added
            if nikud_text.startswith('"') and nikud_text.endswith('"'):
                nikud_text = nikud_text[1:-1]
            
            return nikud_text
        else:
            print("Google AI API: No candidates in response")
            return add_nikud_with_fallback(text)
        
    except requests.RequestException as e:
        print(f"Google AI API error: {e}")
        return add_nikud_with_fallback(text)
    except (KeyError, IndexError) as e:
        print(f"Google AI API response error: {e}")
        return add_nikud_with_fallback(text)

def add_nikud_with_fallback(text):
    """
    Fallback nikud addition using dictionary
    """
    # Extended dictionary of common Hebrew words with nikud
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
        "אוכל": "אֹכֶל",
        "איך": "אֵיךְ",
        "מה": "מָה",
        "איפה": "אֵיפֹה",
        "מתי": "מָתַי",
        "למה": "לָמָה",
        "כמה": "כַּמָּה",
        "טוב": "טוֹב",
        "רע": "רַע",
        "יפה": "יָפֶה",
        "גדול": "גָּדוֹל",
        "קטן": "קָטָן",
        "חדש": "חָדָשׁ",
        "ישן": "יָשָׁן",
        "צעיר": "צָעִיר",
        "זקן": "זָקֵן",
        "חום": "חוּם",
        "קר": "קַר",
        "חם": "חַם",
        "אהבה": "אַהֲבָה",
        "שנאה": "שִׂנְאָה",
        "שמחה": "שִׂמְחָה",
        "עצבות": "עַצְבוּת",
        "אמת": "אֱמֶת",
        "שקר": "שֶׁקֶר",
        "חיים": "חַיִּים",
        "מות": "מָוֶת",
        "עולם": "עוֹלָם",
        "שמיים": "שָׁמַיִם",
        "ארץ": "אֶרֶץ",
        "ים": "יָם",
        "הר": "הַר",
        "עיר": "עִיר",
        "כפר": "כְּפָר"
    }
    
    # Split text into Hebrew words (preserving punctuation and spaces)
    words = re.findall(r'[\u0590-\u05FF]+|[^\u0590-\u05FF]+', text)
    
    result = []
    for word in words:
        # Only process Hebrew words
        if re.match(r'[\u0590-\u05FF]+', word):
            if word in nikud_dict:
                result.append(nikud_dict[word])
            else:
                result.append(word)
        else:
            result.append(word)
    
    return ''.join(result)

def add_nikud(text):
    """
    Main nikud function that tries API first, then fallback
    """
    return add_nikud_with_api(text)

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
