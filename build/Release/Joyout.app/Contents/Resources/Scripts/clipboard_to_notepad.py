#!/usr/bin/env python3
"""
clipboard_to_notepad.py - Copies selected text and pastes it into TextEdit
"""

import subprocess
import time
import os

def get_clipboard_content():
    """Get the current clipboard content"""
    p = subprocess.Popen(['pbpaste'], stdout=subprocess.PIPE)
    content = p.stdout.read().decode('utf-8')
    return content

def set_clipboard_content(content):
    """Set the clipboard content"""
    p = subprocess.Popen(['pbcopy'], stdin=subprocess.PIPE)
    p.communicate(input=content.encode('utf-8'))

def open_textedit():
    """Open TextEdit application"""
    subprocess.run(['open', '-a', 'TextEdit'])
    # Give TextEdit time to open
    time.sleep(1)

def paste_to_textedit():
    """Paste clipboard content to TextEdit"""
    # Simulate Command+V keystroke to paste
    # In a real implementation, this would use AppleScript or macOS Automation
    applescript = '''
    tell application "TextEdit"
        activate
        tell application "System Events"
            keystroke "v" using command down
        end tell
    end tell
    '''
    subprocess.run(['osascript', '-e', applescript])

def main():
    # Get text from clipboard (it should already be there from the selection)
    text = get_clipboard_content()
    
    if not text:
        print("No text in clipboard")
        return
    
    # Open TextEdit
    open_textedit()
    
    # Paste the text
    paste_to_textedit()
    
    # Notify user (in a real app, this would use macOS notification)
    print("Text sent to TextEdit")

if __name__ == "__main__":
    main()
