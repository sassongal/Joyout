#!/bin/bash
# JoyaaS Standalone Installer for macOS
# This creates a self-contained application that users can download and run

set -e  # Exit on any error

echo "🚀 Creating JoyaaS Standalone Application for macOS"
echo "=================================================="

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required. Please install Python 3 from https://python.org"
    echo "   Or install via Homebrew: brew install python"
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Create the app bundle
echo "🔨 Creating application bundle..."
python3 create_macos_app.py

# Create a DMG installer (optional)
if command -v hdiutil &> /dev/null; then
    echo "📦 Creating DMG installer..."
    
    # Remove existing DMG
    [ -f "JoyaaS-1.0.dmg" ] && rm "JoyaaS-1.0.dmg"
    
    # Create temporary directory for DMG contents
    mkdir -p dmg_tmp
    cp -R JoyaaS.app dmg_tmp/
    
    # Create alias to Applications folder
    ln -s /Applications dmg_tmp/Applications
    
    # Create DMG
    hdiutil create -volname "JoyaaS" -srcfolder dmg_tmp -ov -format UDZO JoyaaS-1.0.dmg
    
    # Clean up
    rm -rf dmg_tmp
    
    echo "✅ DMG created: JoyaaS-1.0.dmg"
fi

echo ""
echo "🎉 JoyaaS Standalone Application Created!"
echo "========================================"
echo ""
echo "📁 Files created:"
echo "   • JoyaaS.app - The standalone application"
if [ -f "JoyaaS-1.0.dmg" ]; then
    echo "   • JoyaaS-1.0.dmg - Installer package"
fi
echo ""
echo "📋 Distribution Instructions:"
echo "   1. Users can download and drag JoyaaS.app to their Applications folder"
echo "   2. Double-click JoyaaS.app to launch"
echo "   3. First run will automatically install dependencies"
echo "   4. The app will open in their default web browser"
echo ""
echo "🔧 Requirements for end users:"
echo "   • macOS 10.15 or later"
echo "   • Python 3.x (most Macs have this pre-installed)"
echo ""
echo "✨ Features:"
echo "   • No complex installation process"
echo "   • Automatic dependency management"
echo "   • Opens in web browser automatically"
echo "   • Can be distributed via download or USB"
echo ""
