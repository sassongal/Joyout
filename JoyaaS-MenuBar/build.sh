#!/bin/bash

# JoyaaS MenuBar Build Script
# This script builds the macOS menu bar application

set -e

echo "🔨 Building JoyaaS MenuBar..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Error: Xcode is not installed or xcodebuild is not in PATH${NC}"
    exit 1
fi

# Navigate to project directory
cd "$(dirname "$0")"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
xcodebuild clean -project JoyaaSMenuBar.xcodeproj -scheme JoyaaSMenuBar

# Build the application
echo -e "${YELLOW}🔨 Building application...${NC}"
xcodebuild build -project JoyaaSMenuBar.xcodeproj -scheme JoyaaSMenuBar -configuration Release

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build succeeded!${NC}"
    echo -e "${GREEN}📍 The app should now be available in the build directory.${NC}"
    echo -e "${GREEN}🚀 To run: Open Xcode and press ⌘R, or run the built app directly.${NC}"
    echo ""
    echo -e "${YELLOW}💡 Next steps:${NC}"
    echo "   1. Open JoyaaSMenuBar.xcodeproj in Xcode"
    echo "   2. Press ⌘R to run the app"
    echo "   3. Look for the peacock icon in your menu bar"
else
    echo -e "${RED}❌ Build failed. Please check the error messages above.${NC}"
    exit 1
fi
