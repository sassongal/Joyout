#!/bin/bash

# JoyaaS Application Launcher
echo "🚀 JoyaaS - Professional Hebrew/English Text Processing"
echo "======================================================"
echo ""
echo "Choose your preferred version:"
echo ""
echo "1. 🌐 Web Application (Recommended for full features)"
echo "2. 🍎 Native macOS App (SwiftUI + Perfect Layout Fixer)"
echo "3. 🔧 Build Native App (if changes were made)"
echo "4. 📊 Test Layout Fixer Performance"
echo "5. ❌ Exit"
echo ""

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo ""
        echo "🌐 Starting JoyaaS Web Application..."
        echo "📱 Features: Perfect Layout Fixer, Text Cleaner, AI Tools, Dashboard"
        echo "🔗 Will open in browser automatically"
        echo ""
        python3 joyaas_app_fixed.py
        ;;
    2)
        echo ""
        echo "🍎 Starting JoyaaS Native macOS App..."
        echo "📱 Features: SwiftUI Interface, Perfect Layout Fixer, Text Processing"
        echo ""
        if [ -d "JoyaaS-Native-Build/JoyaaS.app" ]; then
            open JoyaaS-Native-Build/JoyaaS.app
            echo "✅ Native app launched successfully!"
        else
            echo "❌ Native app not found. Please build it first (option 3)."
        fi
        ;;
    3)
        echo ""
        echo "🔧 Building JoyaaS Native macOS App..."
        echo "📦 This will create a fresh native app bundle"
        echo ""
        ./build_native_app.sh
        if [ $? -eq 0 ]; then
            echo ""
            echo "✅ Build successful! You can now use option 2 to launch the native app."
        else
            echo "❌ Build failed. Please check the error messages above."
        fi
        ;;
    4)
        echo ""
        echo "🧪 Testing Perfect Layout Fixer..."
        echo "📊 Running comprehensive performance tests"
        echo ""
        python3 test_functionality.py
        ;;
    5)
        echo ""
        echo "👋 Thanks for using JoyaaS!"
        echo "🌟 Star us on GitHub: https://github.com/sassongal/Joyout"
        exit 0
        ;;
    *)
        echo ""
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "🎉 JoyaaS Session Complete!"
echo "💡 Run this script again anytime to launch JoyaaS"
