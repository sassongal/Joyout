#!/usr/bin/env python3
"""
hotkeys.py - Global hotkey system for Joyout Text Processing Tools
"""

from pynput import keyboard
import subprocess
import requests
import threading
import time
import sys
from pathlib import Path

# Add the Scripts directory to the Python path
scripts_dir = Path(__file__).parent
sys.path.insert(0, str(scripts_dir))

class HotkeyManager:
    def __init__(self):
        self.hotkeys = {
            # Global hotkeys (Shift+Cmd+Number)
            frozenset([keyboard.Key.shift, keyboard.Key.cmd, keyboard.KeyCode.from_char('1')]): 'hebrew_nikud',
            frozenset([keyboard.Key.shift, keyboard.Key.cmd, keyboard.KeyCode.from_char('2')]): 'language_corrector',
            frozenset([keyboard.Key.shift, keyboard.Key.cmd, keyboard.KeyCode.from_char('3')]): 'clipboard_translator',
            frozenset([keyboard.Key.shift, keyboard.Key.cmd, keyboard.KeyCode.from_char('4')]): 'layout_fixer',
            frozenset([keyboard.Key.shift, keyboard.Key.cmd, keyboard.KeyCode.from_char('5')]): 'underline_remover',
            frozenset([keyboard.Key.shift, keyboard.Key.cmd, keyboard.KeyCode.from_char('6')]): 'clipboard_to_notepad',
            frozenset([keyboard.Key.shift, keyboard.Key.cmd, keyboard.KeyCode.from_char('d')]): 'open_dashboard',
        }
        
        self.current_keys = set()
        self.dashboard_url = "http://localhost:5000"
        
    def on_press(self, key):
        """Handle key press events"""
        self.current_keys.add(key)
        
        # Check if current combination matches any hotkey
        for hotkey_combo, action in self.hotkeys.items():
            if hotkey_combo == self.current_keys:
                threading.Thread(target=self.execute_action, args=(action,), daemon=True).start()
                
    def on_release(self, key):
        """Handle key release events"""
        try:
            self.current_keys.remove(key)
        except KeyError:
            pass  # Key wasn't in set
            
    def execute_action(self, action):
        """Execute the action for a hotkey"""
        try:
            if action == 'open_dashboard':
                subprocess.run(['open', self.dashboard_url])
                self.show_notification("Dashboard opened")
            else:
                # Call the API endpoint
                response = requests.get(f"{self.dashboard_url}/api/execute/{action}", timeout=10)
                if response.status_code == 200:
                    result = response.json()
                    if result['success']:
                        self.show_notification(f"✅ {result['message']}")
                    else:
                        self.show_notification(f"❌ {result['message']}")
                else:
                    self.show_notification("❌ Dashboard not running")
        except requests.exceptions.RequestException:
            self.show_notification("❌ Dashboard not accessible")
        except Exception as e:
            self.show_notification(f"❌ Error: {str(e)}")
            
    def show_notification(self, message):
        """Show macOS notification"""
        try:
            subprocess.run([
                'osascript', '-e', 
                f'display notification "{message}" with title "Joyout"'
            ], check=False, timeout=5)
        except:
            pass  # Ignore notification errors
            
    def start_listening(self):
        """Start the global hotkey listener"""
        print("🎯 Joyout Global Hotkeys Active")
        print("================================")
        print("Shift+Cmd+1: Hebrew Nikud")
        print("Shift+Cmd+2: Language Corrector") 
        print("Shift+Cmd+3: Translator")
        print("Shift+Cmd+4: Layout Fixer")
        print("Shift+Cmd+5: Text Cleaner")
        print("Shift+Cmd+6: To TextEdit")
        print("Shift+Cmd+D: Open Dashboard")
        print("Press Ctrl+C to stop")
        print()
        
        with keyboard.Listener(
            on_press=self.on_press,
            on_release=self.on_release
        ) as listener:
            try:
                listener.join()
            except KeyboardInterrupt:
                print("\\nHotkey listener stopped")

def main():
    hotkey_manager = HotkeyManager()
    hotkey_manager.start_listening()

if __name__ == '__main__':
    main()
