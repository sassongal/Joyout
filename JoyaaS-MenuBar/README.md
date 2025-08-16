# JoyaaS MenuBar

A native macOS menu bar application that provides quick access to JoyaaS text processing features directly from your menu bar.

## Features

- **Menu Bar Integration**: Your beautiful blue peacock logo appears in your macOS menu bar
- **Quick Access**: Click the icon to open a compact processing interface
- **Multiple Operations**: Layout fixer, text cleaner, Hebrew Nikud, language corrector, and translator
- **Clipboard Integration**: Paste and copy functionality with one click
- **Context Menu**: Right-click for quick actions without opening the main interface
- **Perfect Layout Fixer**: Uses the same advanced Hebrew-English layout detection as the main app

## Installation

### Building from Source

1. **Requirements**:
   - macOS 13.0 or later
   - Xcode 15.0 or later
   - Swift 5.0

2. **Build Steps**:
   ```bash
   cd /Users/galsasson/Downloads/Joyout/JoyaaS-MenuBar
   open JoyaaSMenuBar.xcodeproj
   ```
   
3. **In Xcode**:
   - Select "JoyaaSMenuBar" scheme
   - Build and run (⌘R)
   - The app will appear in your menu bar with your stunning peacock logo

### Usage

#### Main Interface
- **Left-click** the menu bar icon to open the processing interface
- Enter or paste text in the input area
- Select the desired operation
- Click "Process" to transform your text
- Copy the result or use it directly

#### Quick Actions (Right-click menu)
- **Open JoyaaS**: Launch the main Python application
- **Fix Layout from Clipboard**: Instantly fix layout issues in clipboard text
- **Clean Text from Clipboard**: Clean up formatting in clipboard text
- **About JoyaaS**: Show information about the application
- **Quit**: Close the menu bar app

#### Keyboard Shortcuts
- **Paste**: ⌘V in the input field
- **Copy**: Click the "Copy" button next to output text
- **Clear**: Reset input and output fields

## Text Processing Features

### Layout Fixer
The advanced layout fixer automatically detects when text was typed in the wrong keyboard layout and converts it intelligently:

- **Hebrew ↔ English**: Bidirectional conversion support
- **Smart Detection**: Only converts when absolutely certain
- **Mixed Language Protection**: Preserves text with multiple languages
- **Word Recognition**: Uses common word patterns for validation
- **Punctuation Preservation**: Maintains all original formatting

### Text Cleaner
- Removes extra whitespaces
- Normalizes line breaks
- Trims unnecessary characters
- Preserves intentional formatting

### Other Features
- **Hebrew Nikud**: Add vowel marks to Hebrew text (placeholder)
- **Language Corrector**: Basic text correction (placeholder)
- **Translator**: Text translation (placeholder)

## Technical Details

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **AppKit**: Menu bar and system integration
- **Cocoa**: Native macOS functionality
- **TextProcessor**: Swift implementation of Python text processing logic

### Files Structure
```
JoyaaSMenuBar/
├── App.swift              # Main application and menu bar logic
├── ContentView.swift      # SwiftUI interface
├── TextProcessor.swift    # Text processing algorithms
└── JoyaaSMenuBar.entitlements  # App permissions
```

### Integration with Main App
- The menu bar app can launch the main Python JoyaaS application
- Both apps share the same layout fixing algorithm
- Clipboard integration allows seamless workflow between apps

## Development

### Customization
To modify the text processing behavior, edit the `TextProcessor.swift` file. The keyboard mappings and word lists can be customized to support different layouts or languages.

### Beautiful Peacock Logo
Your stunning blue and black peacock logo is now fully integrated throughout the app:
- Menu bar icon uses a simplified version for maximum visibility
- App icons in all required sizes (16x16 to 1024x1024) for macOS
- SwiftUI component `PeacockLogoView` for consistent branding throughout the interface
- Professional DMG installer background featuring your logo
- All generated automatically from your original design

### Adding New Features
1. Add new methods to `TextProcessor.swift`
2. Update the operations list in `ContentView.swift`
3. Implement the UI logic in the `performOperation` method

## Troubleshooting

### Common Issues

**App doesn't appear in menu bar**:
- Make sure the app built successfully
- Check that macOS allows the app to run (System Preferences > Security & Privacy)

**Layout fixing not working**:
- Ensure the text has enough alphabetic characters (minimum 3)
- Check that the text isn't already in mixed languages
- Verify the keyboard mapping matches your layout

**Python app won't launch**:
- Update the path in `App.swift` if your Python script is in a different location
- Ensure Python 3 is installed and accessible at `/usr/bin/python3`

### Performance
The menu bar app is optimized for quick operations:
- Processing happens on background threads
- UI remains responsive during text processing
- Memory usage is minimal when idle

## License

This project is part of the JoyaaS suite by Gal Sasson.
