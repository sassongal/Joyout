#!/usr/bin/env python3
"""
joyout.py - Quick launcher for all Joyout text processing tools
"""

import sys
import subprocess
from pathlib import Path

def show_menu():
    print("\n🎯 Joyout Text Processing Tools")
    print("================================")
    print("1. Hebrew Nikud (Add vowels to Hebrew text)")
    print("2. Language Corrector (Fix spelling/grammar)")
    print("3. Translator (Hebrew ↔ English)")
    print("4. Layout Fixer (Fix wrong keyboard layout)")
    print("5. Text Cleaner (Remove formatting)")
    print("6. Copy to TextEdit")
    print("7. Setup API Keys")
    print("0. Exit")
    print("\nSelect an option (0-7): ", end="")

def run_script(script_name):
    script_path = Path(__file__).parent / script_name
    try:
        subprocess.run(['python3', str(script_path)], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running {script_name}: {e}")
    except FileNotFoundError:
        print(f"Script {script_name} not found!")

def main():
    scripts = {
        '1': 'hebrew_nikud.py',
        '2': 'language_corrector.py', 
        '3': 'clipboard_translator.py',
        '4': 'layout_fixer.py',
        '5': 'underline_remover.py',
        '6': 'clipboard_to_notepad.py',
        '7': 'config.py'
    }
    
    while True:
        show_menu()
        choice = input().strip()
        
        if choice == '0':
            print("Goodbye! 👋")
            break
        elif choice in scripts:
            print(f"\nRunning {scripts[choice]}...")
            run_script(scripts[choice])
            print("\nPress Enter to continue...")
            input()
        else:
            print("\n❌ Invalid choice. Please select 0-7.")
            print("Press Enter to continue...")
            input()

if __name__ == "__main__":
    main()
