#!/usr/bin/env python3
"""
create_macos_app.py - Create a standalone macOS application for JoyaaS
This script creates a .app bundle that can be distributed to Mac users
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

def create_macos_app():
    """Create a standalone macOS application bundle"""
    
    app_name = "JoyaaS"
    bundle_name = f"{app_name}.app"
    
    # Create app bundle structure
    bundle_dir = Path(bundle_name)
    contents_dir = bundle_dir / "Contents"
    macos_dir = contents_dir / "MacOS"
    resources_dir = contents_dir / "Resources"
    frameworks_dir = contents_dir / "Frameworks"
    
    # Remove existing bundle if it exists
    if bundle_dir.exists():
        shutil.rmtree(bundle_dir)
    
    # Create directory structure
    macos_dir.mkdir(parents=True)
    resources_dir.mkdir(parents=True)
    frameworks_dir.mkdir(parents=True)
    
    print(f"🔨 Creating {bundle_name}...")
    
    # Create Info.plist
    info_plist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>JoyaaS</string>
    <key>CFBundleIdentifier</key>
    <string>com.joyaas.textprocessing</string>
    <key>CFBundleName</key>
    <string>JoyaaS</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>JOYS</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Text Document</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>txt</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
        </dict>
    </array>
</dict>
</plist>'''
    
    with open(contents_dir / "Info.plist", 'w') as f:
        f.write(info_plist)
    
    # Create launcher script
    launcher_script = '''#!/bin/bash
# JoyaaS Launcher Script

# Get the directory where this script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
RESOURCES_DIR="$DIR/../Resources"

# Export Python path
export PYTHONPATH="$RESOURCES_DIR:$PYTHONPATH"

# Change to resources directory
cd "$RESOURCES_DIR"

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_VERSION=$(python -c 'import sys; print(sys.version_info.major)')
    if [ "$PYTHON_VERSION" = "3" ]; then
        PYTHON_CMD="python"
    else
        # Show error dialog
        osascript -e 'display dialog "Python 3 is required to run JoyaaS. Please install Python 3 from python.org" buttons {"OK"} default button "OK" with icon caution'
        exit 1
    fi
else
    # Show error dialog
    osascript -e 'display dialog "Python 3 is required to run JoyaaS. Please install Python 3 from python.org" buttons {"OK"} default button "OK" with icon caution'
    exit 1
fi

# Install dependencies if needed
if [ ! -d "venv_joyaas" ]; then
    echo "Setting up JoyaaS for first run..."
    ./install_joyaas.sh
fi

# Activate virtual environment if it exists
if [ -d "venv_joyaas" ]; then
    source venv_joyaas/bin/activate
fi

# Check if app is already running
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    # Open browser to existing instance
    open "http://localhost:8080"
else
    # Start the application
    echo "Starting JoyaaS..."
    $PYTHON_CMD joyaas_app.py &
    
    # Wait a moment for the server to start
    sleep 3
    
    # Open browser
    open "http://localhost:8080"
fi
'''
    
    with open(macos_dir / "JoyaaS", 'w') as f:
        f.write(launcher_script)
    
    # Make launcher executable
    os.chmod(macos_dir / "JoyaaS", 0o755)
    
    # Copy application files to Resources
    files_to_copy = [
        "joyaas_app.py",
        "config.py",
        "requirements_saas.txt",
        "install_joyaas.sh",
        "test_joyaas.py",
        ".env"
    ]
    
    for file in files_to_copy:
        if Path(file).exists():
            shutil.copy2(file, resources_dir)
            print(f"✅ Copied {file}")
    
    # Copy templates directory
    if Path("templates").exists():
        shutil.copytree("templates", resources_dir / "templates")
        print("✅ Copied templates/")
    
    # Make install script executable
    install_script = resources_dir / "install_joyaas.sh"
    if install_script.exists():
        os.chmod(install_script, 0o755)
    
    # Create a simple icon (you can replace this with a proper .icns file)
    create_app_icon(resources_dir)
    
    print(f"🎉 {bundle_name} created successfully!")
    print(f"📦 You can now distribute the '{bundle_name}' folder to Mac users")
    print(f"👥 Users can drag it to their Applications folder and double-click to run")
    
    return bundle_dir

def create_app_icon(resources_dir):
    """Create a simple app icon"""
    # This creates a basic icon - you can replace with a proper .icns file
    icon_script = '''
tell application "System Events"
    set theIcon to (path to desktop as string) & "JoyaaS_icon.png"
end tell
'''
    
    # For now, we'll just create a placeholder
    # In production, you'd want to create a proper .icns file
    print("📝 Icon placeholder created (replace with proper .icns file)")

if __name__ == "__main__":
    create_macos_app()
