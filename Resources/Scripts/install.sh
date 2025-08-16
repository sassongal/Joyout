#!/bin/bash

# Joyout Text Tools Installation Script
# This script installs the Joyout text processing tools on macOS

set -e  # Exit on error

echo "🚀 Installing Joyout Text Processing Tools..."
echo "============================================"

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    echo "Please install Python 3 from https://www.python.org/downloads/"
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Check if pip3 is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is required but not installed."
    echo "Please install pip3 or reinstall Python 3"
    exit 1
fi

echo "✅ pip3 found"

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip3 install -r requirements.txt

echo "✅ Dependencies installed successfully"

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x *.py

echo "✅ Scripts are now executable"

# Run initial configuration
echo "⚙️  Running initial configuration..."
echo "You'll be prompted to set up your Google AI API key."
echo "This is free and only takes a minute!"
echo ""
read -p "Press Enter to continue with API key setup (or Ctrl+C to skip)..."

python3 config.py

echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
echo "You can now use the following commands:"
echo "  python3 hebrew_nikud.py       - Add nikud to Hebrew text"
echo "  python3 language_corrector.py - Fix spelling and grammar"
echo "  python3 clipboard_translator.py - Translate text"
echo "  python3 layout_fixer.py       - Fix keyboard layout mistakes"
echo "  python3 underline_remover.py  - Clean text formatting"
echo "  python3 clipboard_to_notepad.py - Copy to TextEdit"
echo ""
echo "💡 Pro tip: Set up keyboard shortcuts in macOS System Preferences"
echo "   to run these scripts quickly!"
echo ""
echo "📖 For detailed usage instructions, see README.md"
echo ""
echo "Happy text processing! 🎯"
