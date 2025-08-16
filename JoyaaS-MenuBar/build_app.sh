#!/bin/bash

# JoyaaS MenuBar App Build Script
# Builds a release version of the app with your beautiful peacock logo

set -e

echo "🦚 Building JoyaaS MenuBar with your beautiful peacock logo..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf .build

# Build for release
echo "🚀 Building release version..."
swift build -c release

# Create app bundle structure
echo "📦 Creating app bundle..."
APP_NAME="JoyaaS MenuBar"
APP_DIR="build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf build
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy the executable
cp .build/release/JoyaaSMenuBar "$MACOS_DIR/$APP_NAME"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.galsasson.joyaas-menubar</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>JoyaaS MenuBar</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Copy resources if they exist
if [ -f "JoyaaSMenuBar/menubar-icon.png" ]; then
    cp "JoyaaSMenuBar/menubar-icon.png" "$RESOURCES_DIR/"
    echo "✅ Copied your beautiful peacock logo to app bundle"
fi

echo "🎉 Build complete!"
echo "📁 App bundle created at: $APP_DIR"
echo ""
echo "Your beautiful peacock logo is now integrated throughout the app:"
echo "• Menu bar icon shows your logo"
echo "• SwiftUI interface displays your logo in the header"
echo "• Logo appears in buttons and status indicators"
echo ""
echo "To run the app:"
echo "  open \"$APP_DIR\""
echo ""
echo "To create a DMG installer, run the create_dmg.sh script!"
