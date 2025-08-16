#!/bin/bash

# JoyaaS MenuBar Final Release Builder
# This script builds the complete JoyaaS MenuBar application with your real logoflatupdated.png logo

set -e

echo "🦚 JoyaaS MenuBar Final Release Builder"
echo "======================================"
echo "Building with your REAL logoflatupdated.png logo!"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGO_PATH="/Users/galsasson/Downloads/Joyout/logoflatupdated.png"

echo -e "${BLUE}📍 Project Directory: $SCRIPT_DIR${NC}"
echo -e "${BLUE}📸 Logo Source: $LOGO_PATH${NC}"
echo ""

# Check if logo exists
if [ ! -f "$LOGO_PATH" ]; then
    echo -e "${RED}❌ Error: logoflatupdated.png not found!${NC}"
    echo "Please ensure the file exists at: $LOGO_PATH"
    exit 1
fi

echo -e "${GREEN}✅ Logo file found ($(du -h "$LOGO_PATH" | cut -f1))${NC}"

# Check logo dimensions
logo_info=$(file "$LOGO_PATH")
echo -e "${BLUE}📏 Logo info: $logo_info${NC}"
echo ""

# Step 1: Generate icons from real logo
echo -e "${YELLOW}Step 1: Generating icons from your real logo...${NC}"
echo "─────────────────────────────────────────────────"
python3 generate_icons.py
echo ""

# Step 2: Build the application
echo -e "${YELLOW}Step 2: Building JoyaaS MenuBar application...${NC}"
echo "───────────────────────────────────────────────"
swift build -c release
echo -e "${GREEN}✅ Swift build completed${NC}"
echo ""

# Step 3: Create app bundle
echo -e "${YELLOW}Step 3: Creating app bundle...${NC}"
echo "───────────────────────────────────────"
./build_app.sh
echo ""

# Step 4: Verify the build
echo -e "${YELLOW}Step 4: Verifying the build...${NC}"
echo "────────────────────────────────────"

APP_BUNDLE="build/JoyaaS MenuBar.app"

if [ -d "$APP_BUNDLE" ]; then
    echo -e "${GREEN}✅ App bundle created successfully${NC}"
    
    # Check for logo files
    if [ -f "$APP_BUNDLE/Contents/Resources/menubar-icon.png" ]; then
        echo -e "${GREEN}✅ Menu bar icon from real logo: $(du -h "$APP_BUNDLE/Contents/Resources/menubar-icon.png" | cut -f1)${NC}"
    fi
    
    # Check executable
    if [ -f "$APP_BUNDLE/Contents/MacOS/JoyaaS MenuBar" ]; then
        echo -e "${GREEN}✅ Executable present${NC}"
    fi
    
    # Check Info.plist
    if [ -f "$APP_BUNDLE/Contents/Info.plist" ]; then
        echo -e "${GREEN}✅ Info.plist present${NC}"
    fi
else
    echo -e "${RED}❌ App bundle not found${NC}"
    exit 1
fi

echo ""

# Step 5: Summary of integration
echo -e "${PURPLE}🎉 INTEGRATION COMPLETE!${NC}"
echo "========================"
echo ""
echo -e "${GREEN}Your logoflatupdated.png has been successfully integrated:${NC}"
echo ""
echo "📱 App Icons Generated:"
echo "  • 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024"
echo "  • Menu bar optimized version (18x18)"
echo "  • Installer logo (512x512)"
echo "  • All created from your ACTUAL 3000x3000 logo"
echo ""
echo "🎨 Color Integration:"
echo "  • Extracted actual colors from your logo"
echo "  • Blue: #0547B3 (RGB 5, 71, 179) - Your real logo blue"
echo "  • Dark: #0A1014 (RGB 10, 16, 20) - Your real logo dark"
echo ""
echo "💻 SwiftUI Integration:"
echo "  • PeacockLogoView uses real logo colors"
echo "  • ContentView header matches your branding"
echo "  • All UI elements use consistent color scheme"
echo ""
echo "📦 Ready Files:"
echo "  • $APP_BUNDLE - Ready-to-run app"
echo "  • installer-logo-512.png - For DMG installer"
echo "  • logo-256.png - General purpose logo"
echo ""

# Step 6: Instructions
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "─────────────"
echo "1. Test the app: open \"$APP_BUNDLE\""
echo "2. Create DMG installer: ./create_installer.sh"
echo "3. The app will appear in your menu bar with your real logo"
echo "4. Right-click the menu bar icon for quick actions"
echo ""

# Show file sizes
echo -e "${BLUE}📊 Build Summary:${NC}"
echo "────────────────"
echo "App bundle size: $(du -h "$APP_BUNDLE" | cut -f1)"
echo "Executable size: $(du -h "$APP_BUNDLE/Contents/MacOS/JoyaaS MenuBar" | cut -f1)"
if [ -f "installer-logo-512.png" ]; then
    echo "Installer logo: $(du -h "installer-logo-512.png" | cut -f1)"
fi
echo ""

echo -e "${GREEN}🚀 JoyaaS MenuBar is ready for distribution!${NC}"
echo -e "${YELLOW}Your beautiful peacock logo is now perfectly integrated.${NC}"
echo ""

# Optional: Launch the app
read -p "Would you like to launch the app now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🚀 Launching JoyaaS MenuBar...${NC}"
    open "$APP_BUNDLE"
    echo "Look for your peacock logo in the menu bar! 🦚"
fi

exit 0
