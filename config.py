#!/usr/bin/env python3
"""
config.py - Configuration management for API keys and settings
"""

import os
import json
from pathlib import Path

class JoyoutConfig:
    def __init__(self):
        self.config_dir = Path.home() / ".joyout"
        self.config_file = self.config_dir / "config.json"
        self.config_dir.mkdir(exist_ok=True)
        self.config = self.load_config()
    
    def load_config(self):
        """Load configuration from file"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError):
                print("Warning: Invalid config file, using defaults")
        
        return self.default_config()
    
    def default_config(self):
        """Return default configuration"""
        return {
            "api_keys": {
                "google_ai": "",
                "google_translate": ""
            },
            "settings": {
                "default_translation_target": "en",
                "enable_notifications": True,
                "debug_mode": False,
                "google_ai_model": "gemini-1.5-flash"
            }
        }
    
    def save_config(self):
        """Save configuration to file"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
        except IOError as e:
            print(f"Error saving config: {e}")
    
    def get_api_key(self, service):
        """Get API key for a service"""
        # First try environment variables
        env_var = f"{service.upper().replace('-', '_')}_API_KEY"
        if service == "google_translate":
            env_var = "GOOGLE_TRANSLATE_API_KEY"
        elif service == "google_ai":
            env_var = "GOOGLE_AI_API_KEY"
        
        env_key = os.environ.get(env_var)
        if env_key:
            return env_key
        
        # Then try config file
        return self.config.get("api_keys", {}).get(service, "")
    
    def set_api_key(self, service, key):
        """Set API key for a service"""
        if "api_keys" not in self.config:
            self.config["api_keys"] = {}
        
        self.config["api_keys"][service] = key
        self.save_config()
    
    def get_setting(self, key, default=None):
        """Get a setting value"""
        return self.config.get("settings", {}).get(key, default)
    
    def set_setting(self, key, value):
        """Set a setting value"""
        if "settings" not in self.config:
            self.config["settings"] = {}
        
        self.config["settings"][key] = value
        self.save_config()
    
    def setup_api_keys(self):
        """Interactive setup for API keys"""
        print("Joyout API Key Setup")
        print("==================")
        
        services = {
            "google_ai": {
                "name": "Google AI (Gemini) - for language correction and Hebrew nikud",
                "url": "https://aistudio.google.com/app/apikey",
                "description": "Free with Google account, generous usage limits"
            },
            "google_translate": {
                "name": "Google Translate API",
                "url": "https://cloud.google.com/translate/docs/setup",
                "description": "Optional: for enhanced translation features"
            }
        }
        
        for service, info in services.items():
            current_key = self.get_api_key(service)
            status = "✓ Set" if current_key else "✗ Not set"
            
            print(f"\n{info['name']}")
            print(f"Status: {status}")
            print(f"Description: {info['description']}")
            print(f"Get API key from: {info['url']}")
            
            if input("Update this API key? (y/n): ").lower() == 'y':
                new_key = input("Enter API key: ").strip()
                if new_key:
                    self.set_api_key(service, new_key)
                    print("✓ API key saved")
                else:
                    print("No key entered, skipping")
        
        print("\nSetup complete!")
        print("You can also set API keys using environment variables:")
        print("  export GOOGLE_AI_API_KEY='your-key-here'")
        print("  export GOOGLE_TRANSLATE_API_KEY='your-key-here'")
        print("\nNote: Google AI (Gemini) is free with generous usage limits!")
        print("Get your free API key at: https://aistudio.google.com/app/apikey")

def main():
    config = JoyoutConfig()
    config.setup_api_keys()

if __name__ == "__main__":
    main()
