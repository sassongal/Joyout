#!/bin/bash

# JoyaaS MenuBar DMG Installer Creator
# This script builds the app and creates a professional DMG installer

set -e

echo "🚀 Creating JoyaaS MenuBar Installer..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="JoyaaSMenuBar"
INSTALLER_NAME="JoyaaS MenuBar Installer"
DMG_NAME="JoyaaS-MenuBar-v1.0"
BACKGROUND_NAME="dmg-background.png"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
DMG_DIR="$SCRIPT_DIR/dmg"
TEMP_DMG="$SCRIPT_DIR/temp.dmg"
FINAL_DMG="$SCRIPT_DIR/$DMG_NAME.dmg"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR" "$DMG_DIR" "$TEMP_DMG" "$FINAL_DMG" 2>/dev/null || true

# Create directories
mkdir -p "$BUILD_DIR" "$DMG_DIR"

# Check if Swift is installed
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Error: Swift is not installed or not in PATH${NC}"
    exit 1
fi

# Build the application with Swift Package Manager
echo -e "${YELLOW}🔨 Building $APP_NAME with Swift Package Manager...${NC}"
swift build -c release

# Create app bundle structure
echo -e "${YELLOW}📦 Creating app bundle...${NC}"
APP_DIR="$BUILD_DIR/JoyaaS MenuBar.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy the executable
cp .build/release/JoyaaSMenuBar "$MACOS_DIR/JoyaaS MenuBar"

# Copy resources
if [ -f "JoyaaSMenuBar/menubar-icon.png" ]; then
    cp "JoyaaSMenuBar/menubar-icon.png" "$RESOURCES_DIR/"
fi

if [ -f "installer-logo-512.png" ]; then
    cp "installer-logo-512.png" "$RESOURCES_DIR/"
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>JoyaaS MenuBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.galsasson.joyaas-menubar</string>
    <key>CFBundleName</key>
    <string>JoyaaS MenuBar</string>
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
PLIST_EOF

BUILT_APP="$APP_DIR"
echo -e "${GREEN}✅ Build completed: $BUILT_APP${NC}"

# Copy app to DMG directory
echo -e "${YELLOW}📦 Preparing DMG contents...${NC}"
cp -R "$BUILT_APP" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create installer script
cat > "$DMG_DIR/Install JoyaaS.command" << 'EOF'
#!/bin/bash

# JoyaaS MenuBar Auto-Installer
# This script automatically installs JoyaaS MenuBar and sets up permissions

set -e

echo "🦚 Installing JoyaaS MenuBar..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="$SCRIPT_DIR/JoyaaSMenuBar.app"
INSTALL_PATH="/Applications/JoyaaSMenuBar.app"

# Check if app exists in DMG
if [ ! -d "$APP_PATH" ]; then
    echo "❌ JoyaaSMenuBar.app not found in installer"
    exit 1
fi

# Copy app to Applications
echo -e "${YELLOW}📁 Installing to Applications folder...${NC}"
if [ -d "$INSTALL_PATH" ]; then
    echo "Removing existing installation..."
    rm -rf "$INSTALL_PATH"
fi

cp -R "$APP_PATH" "/Applications/"
echo -e "${GREEN}✅ App installed to Applications${NC}"

# Set permissions
chmod -R 755 "$INSTALL_PATH"

# Launch the app
echo -e "${YELLOW}🚀 Launching JoyaaS MenuBar...${NC}"
open "$INSTALL_PATH"

# Wait a moment for the app to start
sleep 2

# Show completion message
echo -e "${GREEN}🎉 JoyaaS MenuBar has been installed successfully!${NC}"
echo -e "${BLUE}Look for the peacock icon in your menu bar.${NC}"
echo ""
echo "The app will:"
echo "• Request accessibility permissions for advanced features"
echo "• Show a welcome guide on first launch"
echo "• Appear in your menu bar automatically"
echo ""
echo "Right-click the menu bar icon to enable Auto Layout Fix!"

# Keep terminal open briefly
echo ""
echo "Press any key to close this installer..."
read -n 1 -s

exit 0
EOF

chmod +x "$DMG_DIR/Install JoyaaS.command"

# Create README file
cat > "$DMG_DIR/README.txt" << EOF
JoyaaS MenuBar v1.0

INSTALLATION:
1. Double-click "Install JoyaaS.command" for automatic installation
2. Or manually drag JoyaaSMenuBar.app to Applications folder

FEATURES:
• Auto Layout Fix - Automatically corrects Hebrew/English typing mistakes
• Global Hotkey - Press Ctrl+Cmd+F to fix selected text anywhere
• Menu Bar Integration - Quick access from your menu bar
• Clipboard Operations - Fix text directly from clipboard
• Smart Detection - Only fixes text when absolutely certain

FIRST RUN:
The app will request accessibility permissions for advanced features.
This is required for:
- System-wide text monitoring
- Auto layout correction
- Global keyboard shortcuts

Your privacy is protected - all text processing happens locally.

SUPPORT:
For help or questions, contact Gal Sasson

© 2024 Gal Sasson. All rights reserved.
EOF

# Create background image with your peacock logo
echo -e "${YELLOW}🎨 Creating DMG background with JoyaaS logo...${NC}"
python3 << 'PYTHON_SCRIPT'
from PIL import Image, ImageDraw, ImageFont
import os

# Create a professional gradient background
width, height = 600, 400
image = Image.new('RGB', (width, height), '#f8f9fa')
draw = ImageDraw.Draw(image)

# Draw a subtle gradient from light gray to white
for i in range(height):
    gray_value = int(248 + (i * 7 / height))  # 248 to 255
    color = (gray_value, gray_value, min(gray_value + 2, 255))
    draw.line([(0, i), (width, i)], fill=color)

# Use your ACTUAL logo directly
def use_actual_logo(draw, x, y, size):
    # Try to load and use your actual logo file
    try:
        from PIL import Image
        logo_path = '/Users/galsasson/Downloads/Joyout/logoflatupdated.png'
        if os.path.exists(logo_path):
            logo = Image.open(logo_path)
            # Resize to fit
            logo_resized = logo.resize((size, size), Image.Resampling.LANCZOS)
            # Convert to RGB if needed (for blending)
            if logo_resized.mode == 'RGBA':
                # Composite onto white background
                white_bg = Image.new('RGB', (size, size), 'white')
                white_bg.paste(logo_resized, (0, 0), logo_resized)
                logo_resized = white_bg
            return logo_resized
    except:
        pass
    return None

# Draw your peacock logo in the center-left
def draw_peacock_logo(draw, x, y, size):
    # Your ACTUAL logo colors from analysis
    blue_color = (5, 71, 179)  # #0547B3 - Your actual logo blue
    black_color = (10, 16, 20)  # #0A1014 - Your actual logo dark
    
    # Main peacock body (blue ellipse)
    body_w, body_h = int(size * 0.7), int(size * 0.8)
    draw.ellipse([x - body_w//2, y - body_h//2, x + body_w//2, y + body_h//2], fill=blue_color)
    
    # Eye/head area (black curved section)
    eye_w, eye_h = int(size * 0.25), int(size * 0.4)
    eye_x = x - size//4
    draw.ellipse([eye_x - eye_w//2, y - eye_h//2, eye_x + eye_w//2, y + eye_h//2], fill=black_color)
    
    # Beak triangle
    beak_points = [
        (x - size//2, y - size//20),
        (x - size//2 - size//8, y),
        (x - size//2, y + size//20)
    ]
    draw.polygon(beak_points, fill=black_color)
    
    # Crown feathers (three circles with stems)
    feather_positions = [-size//6, 0, size//6]
    for i, fx_offset in enumerate(feather_positions):
        fx = x + fx_offset
        fy = y - size//2 - (size//8 if i == 1 else size//10)
        
        # Stem
        draw.line([(x, y - size//3), (fx, fy + size//20)], fill=black_color, width=3)
        
        # Feather tip
        feather_radius = size//20
        draw.ellipse([fx - feather_radius, fy - feather_radius, 
                     fx + feather_radius, fy + feather_radius], fill=black_color)
    
    # Eye highlight
    highlight_size = size//25
    draw.ellipse([eye_x - size//15, y - size//20, 
                 eye_x - size//15 + highlight_size, y - size//20 + highlight_size], fill='white')

# Try to use actual logo first, fallback to drawn version
actual_logo = use_actual_logo(None, 150, 200, 120)
if actual_logo:
    # Paste the actual logo
    image.paste(actual_logo, (150 - 60, 200 - 60))
else:
    # Draw the JoyaaS peacock logo as fallback
    draw_peacock_logo(draw, 150, 200, 120)

# Add elegant text
try:
    # Try to use a system font
    title_font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 36)
    subtitle_font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 18)
except:
    # Fallback to default font
    title_font = ImageFont.load_default()
    subtitle_font = ImageFont.load_default()

# JoyaaS title with your ACTUAL logo blue
title_color = (5, 71, 179)  # Your actual blue #0547B3
draw.text((280, 150), 'JoyaaS', fill=title_color, font=title_font)
draw.text((280, 190), 'MenuBar', fill=(100, 100, 100), font=subtitle_font)

# Subtitle
draw.text((280, 220), 'Advanced Hebrew-English Layout Fixer', fill=(120, 120, 120), font=subtitle_font)

# Instructions
instruction_color = (80, 80, 80)
draw.text((50, 320), '1. Run "Install JoyaaS.command" for automatic installation', fill=instruction_color)
draw.text((50, 340), '2. Or drag JoyaaSMenuBar.app to Applications folder', fill=instruction_color)
draw.text((50, 360), '3. Look for the peacock icon in your menu bar!', fill=instruction_color)

# Save the background
bg_path = os.path.join(os.environ['DMG_DIR'], 'dmg-background.png')
image.save(bg_path, 'PNG', optimize=True)
print(f"Beautiful JoyaaS DMG background saved to {bg_path}")
PYTHON_SCRIPT

# Calculate DMG size
DMG_SIZE=$(du -sm "$DMG_DIR" | cut -f1)
DMG_SIZE=$((DMG_SIZE + 50)) # Add some padding

# Create DMG
echo -e "${YELLOW}💿 Creating DMG installer...${NC}"
hdiutil create -srcfolder "$DMG_DIR" -volname "$INSTALLER_NAME" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDZO -size ${DMG_SIZE}m "$FINAL_DMG"

# Configure DMG appearance
if command -v osascript &> /dev/null; then
    echo -e "${YELLOW}🎨 Configuring DMG appearance...${NC}"
    
    # Mount the DMG
    MOUNT_DIR=$(hdiutil attach "$FINAL_DMG" | grep '/Volumes/' | awk '{print $3}')
    
    # Configure with AppleScript
    osascript << EOF
tell application "Finder"
    tell disk "$INSTALLER_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1000, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set background picture of viewOptions to file "dmg-background.png"
        
        -- Position items
        set position of item "JoyaaSMenuBar.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        set position of item "Install JoyaaS.command" of container window to {300, 300}
        set position of item "README.txt" of container window to {300, 100}
        
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

    # Unmount
    hdiutil detach "$MOUNT_DIR"
fi

# Clean up temporary files
rm -rf "$BUILD_DIR" "$DMG_DIR"

# Final message
echo ""
echo -e "${GREEN}🎉 DMG Installer created successfully!${NC}"
echo -e "${GREEN}📍 Location: $FINAL_DMG${NC}"
echo ""
echo -e "${BLUE}The installer includes:${NC}"
echo "• JoyaaSMenuBar.app - The main application"
echo "• Install JoyaaS.command - Automatic installer script"
echo "• Applications symlink - For drag-and-drop installation"
echo "• README.txt - Installation and usage instructions"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test the DMG installer"
echo "2. Distribute to users"
echo "3. Users double-click 'Install JoyaaS.command' for automatic installation"

exit 0
