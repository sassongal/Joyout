# 🚀 JoyaaS - Professional Hebrew/English Text Processing SaaS

**JoyaaS (Joyout as a Service)** is a complete transformation from a simple macOS clipboard tool to a professional, cloud-based SaaS platform for Hebrew and English text processing.

## ✨ What Changed?

### Before: Local macOS Tool
- ❌ macOS only
- ❌ Clipboard dependent
- ❌ Single user
- ❌ No web interface
- ❌ No user management
- ❌ No analytics

### After: Global SaaS Platform
- ✅ **Cross-platform** - Works on ANY device with a browser
- ✅ **Web-based** - No clipboard limitations
- ✅ **Multi-user** - User accounts and authentication
- ✅ **Professional UI** - Modern, responsive dashboard
- ✅ **Usage analytics** - Track processing patterns
- ✅ **API access** - RESTful API for developers
- ✅ **Batch processing** - Handle multiple texts at once
- ✅ **Subscription tiers** - Monetization ready

## 🚀 Quick Start

### Launch JoyaaS Platform
```bash
cd Resources/Scripts
chmod +x install_joyaas.sh
./install_joyaas.sh
python3 joyaas_app.py
```

### Visit Your Platform
Open http://localhost:5000 in any browser

## 🎯 Core Features

### Text Processing Tools
- **Hebrew Nikud Addition** - Add vowelization to Hebrew text
- **Language Correction** - Fix spelling and grammar (Hebrew/English)
- **Smart Translation** - Hebrew ↔ English with context awareness
- **Layout Fixer** - Fix text typed in wrong keyboard layout
- **Text Cleaner** - Remove formatting artifacts
- **Batch Processing** - Process multiple texts simultaneously

### SaaS Platform Features
- **User Registration & Login** - Secure authentication system
- **Usage Analytics** - Track processing patterns and statistics
- **API Access** - Full RESTful API with documentation
- **Subscription Management** - Free/Pro/Enterprise tiers
- **Processing History** - Review past operations
- **Modern Dashboard** - Professional web interface

## 📊 Subscription Plans

| Plan | Monthly Limit | Price | Features |
|------|---------------|-------|----------|
| **Free** | 100 processes | $0 | All tools + Basic API |
| **Pro** | 5,000 processes | $19 | Priority support + Analytics |
| **Enterprise** | 50,000 processes | $99 | Custom integrations + Webhooks |

## 🔌 API Usage

```bash
# Process single text
curl -X POST http://localhost:5000/api/process \
  -H "Content-Type: application/json" \
  -d '{"text": "שלום עולם", "operation": "hebrew_nikud"}'

# Batch processing
curl -X POST http://localhost:5000/api/batch_process \
  -H "Content-Type: application/json" \
  -d '{"texts": ["שלום", "עולם"], "operation": "translate"}'
```

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
