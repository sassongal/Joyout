# JoyaaS Shared Algorithm Library

This directory contains the unified layout fixing algorithm used across all JoyaaS components to ensure consistent behavior and results.

## Overview

The JoyaaS Layout Fixer is a sophisticated algorithm that automatically detects and corrects Hebrew/English keyboard layout mistakes. It provides consistent results across Python and Swift implementations.

## Features

- ✅ **Unified Algorithm**: Same logic across all platforms (Python, Swift)
- ✅ **High Accuracy**: Intelligent validation prevents false conversions
- ✅ **Mixed Content Safe**: Never converts text with both Hebrew and English
- ✅ **Performance Optimized**: Efficient character mapping and validation
- ✅ **Well Tested**: Comprehensive test suite with edge cases

## Files

| File | Description |
|------|-------------|
| `layout_fixer.py` | Python implementation of the layout fixing algorithm |
| `LayoutFixer.swift` | Swift implementation of the layout fixing algorithm |
| `__init__.py` | Python package initialization |
| `README.md` | This documentation file |

## Algorithm Logic

The layout fixer uses a rule-based approach:

1. **Mixed Content Detection**: Skip conversion if both Hebrew and English are present
2. **Length Validation**: Skip very short text (< 2 characters)  
3. **Character Mapping**: Check if ALL characters can be converted
4. **Language Validation**: Verify the result looks reasonable in the target language

### Keyboard Mapping

Based on the Israeli Standard QWERTY layout:

```
Hebrew Layout:  / ק ר א ט ו ן ם פ
English Layout: q w e r t y u i o p

Hebrew Layout:  ש ד ג כ ע י ח ל ך ף
English Layout: a s d f g h j k l ;

Hebrew Layout:  ז ס ב ה ן מ צ ת ץ
English Layout: z x c v b n m , .
```

## Python Usage

### Basic Usage

```python
from shared.algorithms import fix_layout

# Fix Hebrew typed in English layout
result = fix_layout("susu")  # → "דודו"

# English remains unchanged
result = fix_layout("hello")  # → "hello" 

# Mixed content is preserved
result = fix_layout("hello שלום")  # → "hello שלום"
```

### Advanced Usage

```python
from shared.algorithms import LayoutFixer

fixer = LayoutFixer()

# Fix layout
corrected = fixer.fix_layout("ahbh")  # → "שיני"

# Get algorithm info
info = fixer.get_algorithm_info()
print(info['version'])  # → "2.0.0"

# Get keyboard mappings
hebrew_to_eng, eng_to_hebrew = fixer.get_keyboard_mapping()
```

## Swift Usage

### Basic Usage

```swift
import Foundation

// Fix Hebrew typed in English layout  
let result = fixLayout("susu")  // → "דודו"

// English remains unchanged
let result = fixLayout("hello")  // → "hello"
```

### Advanced Usage

```swift
let fixer = LayoutFixer()

// Fix layout
let corrected = fixer.fixLayout("ahbh")  // → "שיני"

// Get algorithm info
let info = fixer.getAlgorithmInfo()
print(info["version"]!)  // → "2.0.0"

// Get keyboard mappings
let (hebrewToEng, engToHebrew) = fixer.getKeyboardMapping()
```

## Integration Examples

### Flask Web App Integration

```python
# In your Flask app
from shared.algorithms import fix_layout

@app.route('/api/fix-layout', methods=['POST'])
def api_fix_layout():
    data = request.get_json()
    text = data.get('text', '')
    
    corrected = fix_layout(text)
    
    return jsonify({
        'original': text,
        'corrected': corrected,
        'changed': text != corrected
    })
```

### Swift iOS App Integration

```swift
// In your Swift app
import shared.algorithms  // Import the shared library

class TextProcessor {
    private let layoutFixer = LayoutFixer()
    
    func processText(_ text: String) -> String {
        return layoutFixer.fixLayout(text)
    }
}
```

## Testing

### Python Tests

Run the Python test suite:

```bash
cd /path/to/joyaas
python3 shared/algorithms/layout_fixer.py
```

Expected output:
```
✅ Test 1: 'susu' → 'דודו' PASS
✅ Test 2: 'ahbh' → 'שיני' PASS
✅ Test 3: 'hello' → 'hello' PASS
✅ Test 4: 'שלום' → 'שלום' PASS
✅ Test 5: 'hello שלום' → 'hello שלום' PASS
✅ Test 6: 'a' → 'a' PASS
✅ Test 7: '123' → '123' PASS
```

### Swift Tests

Test the Swift implementation:

```swift
#if DEBUG
let fixer = LayoutFixer()
fixer.runTests()
#endif
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0.0 | 2025-08-16 | Unified algorithm across Python and Swift |
| 1.0.0 | Previous | Initial individual implementations |

## Contributing

When updating the algorithm:

1. **Modify both implementations** (Python and Swift) to maintain consistency
2. **Update version numbers** in both files and documentation
3. **Run all tests** to ensure nothing breaks
4. **Update integration examples** if the API changes

## Support

For questions about the shared algorithm library:
- Check the test cases for expected behavior
- Review the algorithm logic documentation above
- Ensure both Python and Swift versions produce identical results
