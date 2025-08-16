# Joyout Text Processing Tools

A collection of powerful text processing utilities for macOS that work with your clipboard to provide Hebrew/English language support, translation, and text cleaning capabilities.

## 🌟 Features

- **Hebrew Nikud Addition** - Automatically adds vowelization (nikud) to Hebrew text
- **Language Correction** - Fixes spelling and grammar in Hebrew and English
- **Smart Translation** - Translates between Hebrew and English with auto-detection
- **Layout Fixer** - Fixes text typed in wrong keyboard layout
- **Text Cleaner** - Removes formatting artifacts and unwanted characters
- **Clipboard to TextEdit** - Quick copy to TextEdit for further editing

## 🚀 Quick Start

### Prerequisites

- macOS (tested on macOS 10.15+)
- Python 3.7 or higher
- Google AI API key (free from Google AI Studio)

### Installation

1. Clone or download this repository
2. Install dependencies:
   ```bash
   pip3 install -r requirements.txt
   ```
3. Set up your API keys:
   ```bash
   python3 config.py
   ```

### Getting Your Free Google AI API Key

1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated API key
5. Run `python3 config.py` and paste your API key when prompted

## 📱 Usage

All scripts work with your system clipboard. Simply:

1. Copy/select text you want to process
2. Run the appropriate script
3. The processed text replaces your clipboard content

### Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `hebrew_nikud.py` | Add nikud to Hebrew text | `python3 hebrew_nikud.py` |
| `language_corrector.py` | Fix spelling/grammar | `python3 language_corrector.py` |
| `clipboard_translator.py` | Translate text | `python3 clipboard_translator.py` |
| `layout_fixer.py` | Fix keyboard layout mistakes | `python3 layout_fixer.py` |
| `underline_remover.py` | Clean text formatting | `python3 underline_remover.py` |
| `clipboard_to_notepad.py` | Copy to TextEdit | `python3 clipboard_to_notepad.py` |

### Keyboard Shortcuts (Optional)

You can set up keyboard shortcuts in macOS System Preferences > Keyboard > Shortcuts to run these scripts quickly:

1. Go to System Preferences > Keyboard > Shortcuts > Services
2. Add new shortcuts for each script
3. Use Automator to create Quick Actions that run the Python scripts

## ⚙️ Configuration

### API Keys

The application supports multiple ways to provide API keys:

1. **Interactive setup** (recommended):
   ```bash
   python3 config.py
   ```

2. **Environment variables**:
   ```bash
   export GOOGLE_AI_API_KEY="your-api-key-here"
   export GOOGLE_TRANSLATE_API_KEY="your-translate-key-here"  # optional
   ```

3. **Configuration file**: Keys are stored in `~/.joyout/config.json`

### Settings

You can customize the behavior by modifying settings in the config:

- `google_ai_model`: AI model to use (default: "gemini-1.5-flash")
- `default_translation_target`: Default translation target language
- `enable_notifications`: Enable system notifications
- `debug_mode`: Enable debug output

## 🔧 Development

### Project Structure

```
Scripts/
├── config.py                 # Configuration management
├── hebrew_nikud.py           # Hebrew vowelization
├── language_corrector.py     # Language correction
├── clipboard_translator.py   # Translation functionality
├── layout_fixer.py          # Keyboard layout fixing
├── underline_remover.py     # Text cleaning
├── clipboard_to_notepad.py  # TextEdit integration
├── requirements.txt         # Python dependencies
├── setup.py                # Package setup
├── README.md               # This file
└── .gitignore              # Git ignore rules
```

### Core Architecture

- **Configuration Management**: Centralized API key and settings management
- **Clipboard Integration**: All scripts work seamlessly with macOS clipboard
- **Fallback Systems**: Each AI-powered feature has offline fallback capabilities
- **Language Detection**: Automatic Hebrew/English language detection
- **Error Handling**: Robust error handling with user-friendly messages

### Adding New Features

1. Create a new Python script following the existing pattern
2. Import `JoyoutConfig` for consistent configuration handling
3. Use `get_clipboard_content()` and `set_clipboard_content()` for clipboard operations
4. Implement both AI-powered and fallback functionality
5. Add proper error handling and user feedback

## 💡 Why Google AI?

- **Free**: Generous free tier with Google account
- **Fast**: Optimized for quick responses
- **Multilingual**: Excellent Hebrew and English support
- **Reliable**: Google's robust infrastructure

## 🐛 Troubleshooting

### Common Issues

1. **"No Google AI API key found"**
   - Run `python3 config.py` to set up your API key
   - Ensure you have a valid Google AI API key from AI Studio

2. **"No text in clipboard"**
   - Make sure you have copied text before running the script
   - Try copying text again

3. **Translation not working**
   - Check your internet connection
   - Verify your Google AI API key is valid
   - The script will fall back to basic translation if API fails

4. **Hebrew text not displaying correctly**
   - Ensure your terminal/editor supports Hebrew Unicode
   - Try using a different text editor

### Getting Help

If you encounter issues:

1. Enable debug mode: Set `debug_mode: true` in your config
2. Check the error messages for specific API errors
3. Try the fallback functionality (works offline)
4. Verify your API key is correctly set up

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

---

Made with ❤️ for Hebrew and English text processing
