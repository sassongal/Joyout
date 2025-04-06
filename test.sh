#!/bin/bash
# Test script for Joyout app

echo "Testing Joyout app features..."

# Test keyboard layout fixer
echo "Testing keyboard layout fixer..."
python3 Resources/Scripts/layout_fixer.py
if [ $? -eq 0 ]; then
    echo "✅ Keyboard layout fixer test passed"
else
    echo "❌ Keyboard layout fixer test failed"
fi

# Test underline remover
echo "Testing underline remover..."
python3 Resources/Scripts/underline_remover.py
if [ $? -eq 0 ]; then
    echo "✅ Underline remover test passed"
else
    echo "❌ Underline remover test failed"
fi

# Test clipboard translator
echo "Testing clipboard translator..."
python3 Resources/Scripts/clipboard_translator.py
if [ $? -eq 0 ]; then
    echo "✅ Clipboard translator test passed"
else
    echo "❌ Clipboard translator test failed"
fi

# Test language corrector
echo "Testing language corrector..."
python3 Resources/Scripts/language_corrector.py
if [ $? -eq 0 ]; then
    echo "✅ Language corrector test passed"
else
    echo "❌ Language corrector test failed"
fi

# Test Hebrew nikud
echo "Testing Hebrew nikud..."
python3 Resources/Scripts/hebrew_nikud.py
if [ $? -eq 0 ]; then
    echo "✅ Hebrew nikud test passed"
else
    echo "❌ Hebrew nikud test failed"
fi

# Test clipboard to notepad
echo "Testing clipboard to notepad..."
# This test is skipped in the sandbox environment as it requires TextEdit
echo "⚠️ Clipboard to notepad test skipped (requires TextEdit)"

echo "All tests completed."
