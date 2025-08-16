# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Joyout Text Processing Tools is a collection of macOS utilities for Hebrew and English text processing. The tools work with the system clipboard and use Google AI (Gemini) for intelligent text operations like adding Hebrew nikud, grammar correction, and translation.

## Architecture

### Core Components

- **Configuration Management (`config.py`)**: Centralized API key and settings management with fallback systems
- **Clipboard Integration**: All scripts use standardized clipboard operations via `pbpaste`/`pbcopy`
- **AI Integration**: Google AI (Gemini) API integration with offline fallbacks
- **Language Detection**: Automatic Hebrew/English detection using Unicode ranges
- **Fallback Systems**: Each AI feature has dictionary-based offline alternatives

### Script Responsibilities

- `hebrew_nikud.py`: Hebrew vowelization using AI + dictionary fallback
- `language_corrector.py`: Grammar/spelling correction for Hebrew/English
- `clipboard_translator.py`: Translation with auto-detection + web fallback
- `layout_fixer.py`: Keyboard layout mistake correction (English ↔ Hebrew)
- `underline_remover.py`: Text cleaning and formatting artifact removal
- `clipboard_to_notepad.py`: macOS TextEdit integration via AppleScript

## Common Development Commands

### Setup and Installation
```bash
# Install dependencies
pip3 install -r requirements.txt

# Make scripts executable
chmod +x *.py

# Interactive API key setup
python3 config.py

# Automated installation
./install.sh
```

### Running Scripts
```bash
# Hebrew nikud addition
python3 hebrew_nikud.py

# Language correction
python3 language_corrector.py

# Translation
python3 clipboard_translator.py

# Layout fixing
python3 layout_fixer.py

# Text cleaning
python3 underline_remover.py

# Copy to TextEdit
python3 clipboard_to_notepad.py
```

### Testing and Development
```bash
# Test Google AI API connection
python3 -c "from config import JoyoutConfig; c=JoyoutConfig(); print('API Key:', 'SET' if c.get_api_key('google_ai') else 'NOT SET')"

# Test clipboard functionality
echo "test text" | pbcopy && python3 hebrew_nikud.py

# Check configuration
python3 -c "from config import JoyoutConfig; import json; c=JoyoutConfig(); print(json.dumps(c.config, indent=2))"
```

## Key Implementation Patterns

### Configuration Access
```python
from config import JoyoutConfig
config = JoyoutConfig()
api_key = config.get_api_key('google_ai')
setting = config.get_setting('google_ai_model', 'gemini-1.5-flash')
```

### Clipboard Operations
```python
def get_clipboard_content():
    p = subprocess.Popen(['pbpaste'], stdout=subprocess.PIPE)
    return p.stdout.read().decode('utf-8')

def set_clipboard_content(content):
    p = subprocess.Popen(['pbcopy'], stdin=subprocess.PIPE)
    p.communicate(input=content.encode('utf-8'))
```

### Google AI API Structure
```python
data = {
    "contents": [{"parts": [{"text": prompt}]}],
    "generationConfig": {
        "temperature": 0.1,
        "maxOutputTokens": max_tokens
    }
}
url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
```

### Language Detection
```python
def detect_language(text):
    hebrew_chars = sum(1 for c in text if '\u0590' <= c <= '\u05FF')
    english_chars = sum(1 for c in text if 'a' <= c.lower() <= 'z')
    return "hebrew" if hebrew_chars > english_chars else "english"
```

## API Key Management

The project uses Google AI (Gemini) which is free with generous limits. API keys can be set via:

1. Interactive setup: `python3 config.py`
2. Environment variables: `export GOOGLE_AI_API_KEY="your-key"`
3. Config file: `~/.joyout/config.json`

## Error Handling Patterns

All scripts implement graceful fallbacks:
- Network errors → offline dictionary/rule-based processing
- API errors → fallback translation services
- Missing keys → user-friendly setup instructions

## macOS Integration

- Uses `pbpaste`/`pbcopy` for clipboard access
- AppleScript integration for TextEdit automation
- Designed for keyboard shortcut integration via macOS System Preferences

## Development Notes

- All scripts are standalone and can run independently
- Consistent error handling and user feedback across all tools
- Unicode-aware text processing for Hebrew support
- Fallback mechanisms ensure functionality without internet/API access
