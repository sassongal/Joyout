#!/usr/bin/env python3
"""
dashboard.py - SaaS-style web dashboard for Joyout Text Processing Tools
"""

from flask import Flask, render_template, request, jsonify
import subprocess
import threading
import time
import json
import os
from datetime import datetime
from pathlib import Path
import sys

# Add the Scripts directory to the Python path
scripts_dir = Path(__file__).parent
sys.path.insert(0, str(scripts_dir))

from config import JoyoutConfig

app = Flask(__name__)

# Global statistics
stats = {
    'total_processed': 0,
    'nikud_count': 0,
    'corrections_count': 0,
    'translations_count': 0,
    'layout_fixes_count': 0,
    'text_cleanings_count': 0,
    'last_used': None,
    'api_status': 'unknown'
}

def get_clipboard_content():
    """Get the current clipboard content"""
    try:
        p = subprocess.Popen(['pbpaste'], stdout=subprocess.PIPE)
        content = p.stdout.read().decode('utf-8')
        return content
    except:
        return ""

def set_clipboard_content(content):
    """Set the clipboard content"""
    try:
        p = subprocess.Popen(['pbcopy'], stdin=subprocess.PIPE)
        p.communicate(input=content.encode('utf-8'))
        return True
    except:
        return False

def run_script_function(script_name, function_name):
    """Run a specific function from a script"""
    try:
        if script_name == 'hebrew_nikud':
            from hebrew_nikud import add_nikud, get_clipboard_content, set_clipboard_content, is_hebrew
            text = get_clipboard_content()
            if not text or not is_hebrew(text):
                return False, "No Hebrew text in clipboard"
            result = add_nikud(text)
            set_clipboard_content(result)
            stats['nikud_count'] += 1
            return True, "Hebrew nikud added successfully"
            
        elif script_name == 'language_corrector':
            from language_corrector import correct_text, detect_language, get_clipboard_content, set_clipboard_content
            text = get_clipboard_content()
            if not text:
                return False, "No text in clipboard"
            language = detect_language(text)
            result = correct_text(text, language)
            set_clipboard_content(result)
            stats['corrections_count'] += 1
            return True, f"Text corrected ({language})"
            
        elif script_name == 'clipboard_translator':
            from clipboard_translator import translate_text, get_clipboard_content, set_clipboard_content
            text = get_clipboard_content()
            if not text:
                return False, "No text in clipboard"
            result = translate_text(text)
            set_clipboard_content(result)
            stats['translations_count'] += 1
            return True, "Text translated successfully"
            
        elif script_name == 'layout_fixer':
            from layout_fixer import fix_layout, get_clipboard_content, set_clipboard_content
            text = get_clipboard_content()
            if not text:
                return False, "No text in clipboard"
            result = fix_layout(text)
            set_clipboard_content(result)
            stats['layout_fixes_count'] += 1
            return True, "Layout fixed successfully"
            
        elif script_name == 'underline_remover':
            from underline_remover import clean_text, get_clipboard_content, set_clipboard_content
            text = get_clipboard_content()
            if not text:
                return False, "No text in clipboard"
            result = clean_text(text)
            set_clipboard_content(result)
            stats['text_cleanings_count'] += 1
            return True, "Text cleaned successfully"
            
        elif script_name == 'clipboard_to_notepad':
            from clipboard_to_notepad import main as notepad_main
            notepad_main()
            return True, "Text sent to TextEdit"
            
        return False, "Unknown script"
    except Exception as e:
        return False, f"Error: {str(e)}"

def check_api_status():
    """Check Google AI API status"""
    try:
        config = JoyoutConfig()
        api_key = config.get_api_key('google_ai')
        if api_key:
            stats['api_status'] = 'connected'
        else:
            stats['api_status'] = 'no_key'
    except:
        stats['api_status'] = 'error'

@app.route('/')
def dashboard():
    """Main dashboard page"""
    check_api_status()
    return render_template('dashboard.html', stats=stats)

@app.route('/api/execute/<script_name>')
def execute_function(script_name):
    """Execute a text processing function"""
    success, message = run_script_function(script_name, 'main')
    
    if success:
        stats['total_processed'] += 1
        stats['last_used'] = datetime.now().strftime('%H:%M:%S')
    
    return jsonify({
        'success': success,
        'message': message,
        'stats': stats
    })

@app.route('/api/stats')
def get_stats():
    """Get current statistics"""
    check_api_status()
    return jsonify(stats)

@app.route('/api/clipboard')
def get_clipboard():
    """Get current clipboard content"""
    content = get_clipboard_content()
    return jsonify({
        'content': content,
        'length': len(content),
        'has_content': bool(content.strip())
    })

@app.route('/api/config')
def get_config():
    """Get configuration status"""
    try:
        config = JoyoutConfig()
        return jsonify({
            'google_ai_key': bool(config.get_api_key('google_ai')),
            'google_translate_key': bool(config.get_api_key('google_translate')),
            'model': config.get_setting('google_ai_model', 'gemini-1.5-flash')
        })
    except:
        return jsonify({'error': 'Configuration error'})

def open_browser():
    """Open browser to dashboard after short delay"""
    time.sleep(1)
    subprocess.run(['open', 'http://localhost:5000'])

if __name__ == '__main__':
    print("🚀 Starting Joyout SaaS Dashboard...")
    print("📊 Dashboard will open at: http://localhost:5000")
    
    # Open browser in background
    threading.Thread(target=open_browser, daemon=True).start()
    
    # Run Flask app
    app.run(host='127.0.0.1', port=5000, debug=False, use_reloader=False)
