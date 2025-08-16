#!/usr/bin/env python3
"""
start_joyout.py - Complete SaaS startup script for Joyout Text Processing Tools
"""

import subprocess
import threading
import time
import sys
import os
import signal
from pathlib import Path

# Add the Scripts directory to the Python path
scripts_dir = Path(__file__).parent
sys.path.insert(0, str(scripts_dir))

class JoyoutSaaS:
    def __init__(self):
        self.dashboard_process = None
        self.hotkeys_process = None
        self.running = True
        
    def check_dependencies(self):
        """Check if all dependencies are installed"""
        try:
            import flask
            import pynput
            import requests
            return True
        except ImportError as e:
            print(f"❌ Missing dependency: {e}")
            print("Please run: pip3 install -r requirements.txt")
            return False
            
    def start_dashboard(self):
        """Start the web dashboard"""
        try:
            print("🚀 Starting Dashboard Server...")
            self.dashboard_process = subprocess.Popen(
                [sys.executable, str(scripts_dir / 'dashboard.py')],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            time.sleep(2)  # Give dashboard time to start
            return True
        except Exception as e:
            print(f"❌ Failed to start dashboard: {e}")
            return False
            
    def start_hotkeys(self):
        """Start the global hotkey system"""
        try:
            print("⌨️  Starting Global Hotkeys...")
            self.hotkeys_process = subprocess.Popen(
                [sys.executable, str(scripts_dir / 'hotkeys.py')],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            return True
        except Exception as e:
            print(f"❌ Failed to start hotkeys: {e}")
            return False
            
    def show_welcome_message(self):
        """Show welcome message and instructions"""
        print()
        print("🎉 JOYOUT SAAS IS RUNNING!")
        print("=" * 50)
        print("📊 Dashboard: http://localhost:5000")
        print()
        print("🌟 GLOBAL HOTKEYS (System-wide):")
        print("   Shift+Cmd+1: Hebrew Nikud")
        print("   Shift+Cmd+2: Language Corrector")
        print("   Shift+Cmd+3: Translator")
        print("   Shift+Cmd+4: Layout Fixer")
        print("   Shift+Cmd+5: Text Cleaner")
        print("   Shift+Cmd+6: To TextEdit")
        print("   Shift+Cmd+D: Open Dashboard")
        print()
        print("💡 Usage:")
        print("   1. Copy any text to clipboard")
        print("   2. Use hotkeys to process instantly")
        print("   3. Processed text replaces clipboard")
        print()
        print("🔧 Dashboard Features:")
        print("   • Real-time statistics")
        print("   • Clipboard preview")
        print("   • One-click processing")
        print("   • API status monitoring")
        print()
        print("Press Ctrl+C to stop all services")
        print("=" * 50)
        
    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        print("\\n🛑 Shutting down Joyout SaaS...")
        self.running = False
        
        if self.dashboard_process:
            self.dashboard_process.terminate()
            
        if self.hotkeys_process:
            self.hotkeys_process.terminate()
            
        print("✅ All services stopped")
        sys.exit(0)
        
    def run(self):
        """Main run method"""
        # Set up signal handlers
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
        
        print("🎯 JOYOUT SAAS - PROFESSIONAL TEXT PROCESSING")
        print("=" * 50)
        
        # Check dependencies
        if not self.check_dependencies():
            return False
            
        # Start services
        if not self.start_dashboard():
            return False
            
        if not self.start_hotkeys():
            return False
            
        # Show welcome message
        self.show_welcome_message()
        
        # Keep the main process running
        try:
            while self.running:
                time.sleep(1)
                
                # Check if processes are still running
                if self.dashboard_process and self.dashboard_process.poll() is not None:
                    print("⚠️  Dashboard process stopped")
                    
                if self.hotkeys_process and self.hotkeys_process.poll() is not None:
                    print("⚠️  Hotkeys process stopped")
                    
        except KeyboardInterrupt:
            self.signal_handler(None, None)
            
        return True

def main():
    saas = JoyoutSaaS()
    saas.run()

if __name__ == '__main__':
    main()
