# JoyaaS MenuBar - Complete User Manual

## 🦚 Introduction

JoyaaS MenuBar is an advanced native macOS application that brings powerful Hebrew-English text processing capabilities directly to your menu bar. With intelligent auto-correction, global hotkeys, and system-wide text monitoring, it's designed to seamlessly fix layout mistakes as you type.

## ⚡ Quick Start

### Installation
1. **Download** the `JoyaaS-MenuBar-v1.0.dmg` file
2. **Mount** the DMG by double-clicking it
3. **Run** `Install JoyaaS.command` for automatic installation
4. **Alternative**: Manually drag `JoyaaSMenuBar.app` to the `Applications` folder

The app will automatically launch and appear as a black peacock icon in your menu bar.

### First Launch Setup
1. **Welcome Dialog**: On first launch, you'll see a welcome message explaining the app's features
2. **Permissions Request**: The app will ask for accessibility permissions (required for advanced features)
3. **Menu Bar Icon**: Look for the black peacock icon in your menu bar

## 🎯 Core Features

### 1. Perfect Layout Fixer
The heart of JoyaaS - automatically detects and fixes text typed in the wrong keyboard layout.

**How it works:**
- Detects Hebrew text typed in English layout and vice versa
- Uses smart heuristics to avoid false positives
- Preserves mixed-language text
- Only converts when absolutely certain

**Examples:**
- `רובק שםובךא` → `hello world` (Hebrew layout → English)
- `ahkf vkrc` → `שלום עולם` (English layout → Hebrew)

### 2. Auto Layout Fix (Advanced)
Real-time text monitoring and correction across all applications.

**Requirements:**
- Accessibility permissions
- Manual activation via menu

**How it works:**
- Monitors typing in real-time across all apps
- Automatically fixes obvious layout mistakes
- Shows subtle notifications when corrections are made
- More conservative than manual fixing to avoid unwanted changes

### 3. Global Hotkey System
**Default Hotkey:** `Ctrl+Cmd+F`

**Functionality:**
- Works in any application
- Copies selected text, fixes layout, and pastes back
- Shows notifications for successful fixes

### 4. Menu Bar Interface
**Left-click:** Opens the main processing interface
**Right-click:** Shows quick actions menu

### 5. Text Processing Operations
- **Layout Fixer**: Hebrew ↔ English layout correction
- **Text Cleaner**: Removes extra spaces and normalizes formatting
- **Hebrew Nikud**: (Placeholder) Add vowel marks to Hebrew text
- **Language Corrector**: Basic text correction
- **Translator**: (Placeholder) Text translation

## 🖥️ User Interface Guide

### Main Interface (Left-click menu bar icon)
- **Header**: App title with link to main Python app
- **Operation Selector**: Choose processing type
- **Input Area**: Type or paste text to process
- **Process Button**: Apply selected operation
- **Output Area**: View processed results
- **Auto Layout Fix Toggle**: Enable/disable real-time monitoring
- **Quick Actions**: Direct clipboard processing

### Context Menu (Right-click menu bar icon)
- **Open JoyaaS**: Launch main Python application
- **Auto Layout Fix**: Toggle real-time monitoring
- **Fix Layout from Clipboard**: Process clipboard text
- **Clean Text from Clipboard**: Clean clipboard formatting
- **Fix Selected Text**: Use global hotkey function
- **Settings**: Configure app behavior
- **About**: Version and developer information
- **Quit**: Close the application

## 🔧 Settings & Configuration

### Launch at Login
- **Enable**: App starts automatically when you log in
- **Disable**: Manual launch required

### Auto Layout Fix Settings
- **Minimum Text Length**: Default 3 characters (prevents false positives)
- **Buffer Delay**: 500ms after typing stops before processing
- **Max Buffer Size**: 500 characters maximum

### Global Hotkey
- **Default**: Ctrl+Cmd+F
- **Custom**: Feature planned for future update

## 🔐 Privacy & Permissions

### Required Permissions

#### Accessibility Permissions
**Purpose**: Enable advanced features
**Required for:**
- System-wide text monitoring
- Auto layout correction
- Global keyboard shortcuts
- Selected text replacement

#### How to Grant Permissions
1. **Automatic**: App will prompt during setup
2. **Manual**: System Preferences → Security & Privacy → Privacy → Accessibility → Add JoyaaSMenuBar

### Privacy Protection
- **Local Processing**: All text processing happens on your device
- **No Data Collection**: No text or usage data is transmitted
- **No Analytics**: No tracking or analytics
- **Open Source Logic**: Text processing algorithms are transparent

## 🚀 Advanced Usage

### Auto Layout Fix Best Practices
1. **Start Conservative**: Enable for trial period to test accuracy
2. **Monitor Notifications**: Watch for auto-corrections to ensure they're correct
3. **Disable if Needed**: Turn off in applications where precision is critical
4. **Use Manual Mode**: For important documents, use manual processing

### Global Hotkey Tips
1. **Select First**: Highlight text before using the hotkey
2. **Wait for Processing**: Allow time for the correction to complete
3. **Undo Available**: Use Cmd+Z if correction is unwanted
4. **Works Everywhere**: Functions in any text-capable application

### Menu Bar Efficiency
- **Quick Access**: Right-click for fastest common operations
- **Clipboard Workflow**: Copy → Right-click → Fix → Paste
- **Status Monitoring**: Green indicator shows auto-fix is active

## 🔧 Troubleshooting

### Common Issues

#### App Doesn't Appear in Menu Bar
**Causes:**
- App not launching properly
- Menu bar icon area full
- macOS security blocking

**Solutions:**
1. Check Activity Monitor for running process
2. Restart the application
3. Clear menu bar space
4. Check Security & Privacy settings

#### Auto Layout Fix Not Working
**Causes:**
- Missing accessibility permissions
- Text too short (< 3 characters)
- Mixed language text (intentionally preserved)
- Conservative detection logic

**Solutions:**
1. Grant accessibility permissions
2. Try with longer text samples
3. Use manual processing for mixed text
4. Check notification area for auto-fixes

#### Global Hotkey Not Responding
**Causes:**
- Accessibility permissions not granted
- Hotkey conflict with other apps
- Text not selected properly

**Solutions:**
1. Verify accessibility permissions
2. Test in different applications
3. Ensure text is highlighted before pressing hotkey
4. Check for conflicting keyboard shortcuts

#### Layout Fix Seems Incorrect
**Causes:**
- Unusual text patterns
- Technical terminology
- Names or specialized vocabulary

**Solutions:**
1. The algorithm is conservative by design
2. Use manual review for critical text
3. Consider disabling auto-fix for specialized work
4. Report consistent false positives for improvement

### Performance Issues

#### High CPU Usage
- Auto-fix monitoring uses minimal resources normally
- High usage may indicate system conflicts
- Try disabling and re-enabling auto-fix

#### Memory Usage
- Normal usage: < 50MB
- High usage may indicate memory leaks
- Restart app if usage exceeds 200MB

## 📋 Keyboard Shortcuts

### Global Shortcuts
| Shortcut | Action |
|----------|--------|
| `Ctrl+Cmd+F` | Fix selected text layout |

### Interface Shortcuts
| Shortcut | Action |
|----------|--------|
| `Cmd+V` | Paste into input field |
| `Cmd+C` | Copy from output field (when focused) |
| `Cmd+A` | Select all in active field |

## 🔄 Integration with Main JoyaaS App

### Launching Python App
- **From Interface**: Click arrow icon in header
- **From Menu**: Right-click → "Open JoyaaS"
- **Path**: `/Users/galsasson/Downloads/Joyout/joyaas_app_fixed.py`

### Shared Functionality
- **Same Algorithm**: Identical layout fixing logic
- **Consistent Results**: Processing produces same output
- **Complementary Features**: Menu bar for quick fixes, main app for bulk processing

## 🆘 Support & Feedback

### Getting Help
1. **Check This Manual**: Most issues covered here
2. **Test with Simple Text**: Verify basic functionality
3. **Check Permissions**: Ensure accessibility is granted
4. **Restart App**: Often resolves temporary issues

### Reporting Issues
When reporting problems, include:
- macOS version
- App version
- Steps to reproduce
- Expected vs actual behavior
- Console logs if available

### Feature Requests
Future enhancements being considered:
- Custom hotkey configuration
- Advanced text processing options
- Multiple language support
- Cloud sync for settings

## 📚 Technical Information

### System Requirements
- **macOS**: 13.0 (Ventura) or later
- **Architecture**: Apple Silicon and Intel supported
- **Memory**: 50MB typical usage
- **Permissions**: Accessibility access for advanced features

### File Locations
- **Application**: `/Applications/JoyaaSMenuBar.app`
- **Preferences**: `~/Library/Preferences/com.galsasson.JoyaaSMenuBar.plist`
- **Log Files**: Console.app → JoyaaSMenuBar

### Architecture
- **UI Framework**: SwiftUI with AppKit integration
- **Text Processing**: Native Swift implementation
- **System Integration**: Carbon Event Manager for global hotkeys
- **Accessibility**: AXUIElement for text replacement

## 📄 License & Credits

### License
JoyaaS MenuBar is part of the JoyaaS suite developed by Gal Sasson.

### Credits
- **Developer**: Gal Sasson
- **Text Processing Logic**: Derived from perfect Python implementation
- **UI Design**: Native macOS design principles
- **Icon**: Custom peacock-inspired design

### Version History
- **v1.0**: Initial release with auto-fix and global hotkeys

---

**© 2024 Gal Sasson. All rights reserved.**

For the latest updates and information, visit the project repository or contact the developer.
