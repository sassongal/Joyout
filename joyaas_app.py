#!/usr/bin/env python3
"""
joyaas_app.py - JoyaaS (Joyout as a Service) Web Application
Cross-platform Hebrew/English text processing SaaS platform
"""

from flask import Flask, render_template, request, jsonify, session, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime, timedelta
import uuid
import os
import json
import requests
from pathlib import Path
import sys
import logging
import re
from functools import wraps
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add the Scripts directory to the Python path
scripts_dir = Path(__file__).parent
sys.path.insert(0, str(scripts_dir))

# Try to import config, create fallback if not available
try:
    from config import JoyoutConfig
except ImportError:
    # Fallback configuration class
    class JoyoutConfig:
        def __init__(self):
            pass
        
        def get_api_key(self, service):
            env_var = f"{service.upper().replace('-', '_')}_API_KEY"
            if service == "google_translate":
                env_var = "GOOGLE_TRANSLATE_API_KEY"
            elif service == "google_ai":
                env_var = "GOOGLE_AI_API_KEY"
            return os.environ.get(env_var, '')
        
        def get_setting(self, key, default=None):
            return os.environ.get(key.upper(), default)

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-key-change-in-production')
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///joyaas.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(name)s %(message)s',
    handlers=[
        logging.FileHandler('joyaas.log'),
        logging.StreamHandler()
    ]
)
app.logger = logging.getLogger(__name__)

# Initialize extensions
db = SQLAlchemy(app)
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# Database Models
class User(UserMixin, db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = db.Column(db.String(120), unique=True, nullable=False)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(120), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    subscription_tier = db.Column(db.String(20), default='free')  # free, pro, enterprise
    api_key = db.Column(db.String(64), unique=True)
    usage_count = db.Column(db.Integer, default=0)
    monthly_usage = db.Column(db.Integer, default=0)
    last_reset = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Usage limits by subscription tier
    USAGE_LIMITS = {
        'free': 100,
        'pro': 5000,
        'enterprise': 50000
    }
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def generate_api_key(self):
        self.api_key = str(uuid.uuid4()).replace('-', '')
    
    def can_process(self):
        # Reset monthly usage if needed
        if datetime.utcnow() - self.last_reset > timedelta(days=30):
            self.monthly_usage = 0
            self.last_reset = datetime.utcnow()
            db.session.commit()
        
        return self.monthly_usage < self.USAGE_LIMITS.get(self.subscription_tier, 100)
    
    def increment_usage(self):
        self.usage_count += 1
        self.monthly_usage += 1
        db.session.commit()

class ProcessingHistory(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), nullable=False)
    operation_type = db.Column(db.String(50), nullable=False)
    input_text = db.Column(db.Text)
    output_text = db.Column(db.Text)
    language_detected = db.Column(db.String(20))
    processing_time = db.Column(db.Float)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    user = db.relationship('User', backref=db.backref('history', lazy=True))

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(user_id)

# Text Processing Functions (platform-independent versions)
class TextProcessor:
    def __init__(self):
        self.config = JoyoutConfig()
    
    def detect_language(self, text):
        """Detect if text is primarily Hebrew or English"""
        hebrew_chars = sum(1 for c in text if '\u0590' <= c <= '\u05FF')
        english_chars = sum(1 for c in text if 'a' <= c.lower() <= 'z')
        return "hebrew" if hebrew_chars > english_chars else "english"
    
    def call_google_ai(self, prompt, max_tokens=1000):
        """Make API call to Google AI"""
        api_key = self.config.get_api_key('google_ai')
        if not api_key:
            raise Exception("Google AI API key not configured")
        
        model = self.config.get_setting('google_ai_model', 'gemini-1.5-flash')
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
        
        data = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.1,
                "maxOutputTokens": max_tokens
            }
        }
        
        response = requests.post(url, json=data, timeout=30)
        response.raise_for_status()
        
        result = response.json()
        if 'candidates' in result and result['candidates']:
            return result['candidates'][0]['content']['parts'][0]['text']
        else:
            raise Exception("No response from Google AI")
    
    def add_hebrew_nikud(self, text):
        """Add nikud to Hebrew text"""
        if not text.strip():
            return text
        
        try:
            prompt = f"""Add Hebrew nikud (vowelization) to the following Hebrew text. Only add nikud where needed for proper pronunciation and understanding. Return only the text with nikud added:

{text}"""
            
            result = self.call_google_ai(prompt)
            return result.strip()
        except Exception as e:
            # Fallback: return original text
            return text
    
    def correct_text(self, text, language=None):
        """Correct spelling and grammar"""
        if not text.strip():
            return text
        
        if language is None:
            language = self.detect_language(text)
        
        try:
            lang_name = "Hebrew" if language == "hebrew" else "English"
            prompt = f"""Fix any spelling and grammar errors in the following {lang_name} text. Preserve the original meaning and style. Return only the corrected text:

{text}"""
            
            result = self.call_google_ai(prompt)
            return result.strip()
        except Exception as e:
            return text
    
    def translate_text(self, text):
        """Translate between Hebrew and English"""
        if not text.strip():
            return text
        
        try:
            language = self.detect_language(text)
            target_lang = "English" if language == "hebrew" else "Hebrew"
            
            prompt = f"""Translate the following text to {target_lang}. Preserve meaning and tone:

{text}"""
            
            result = self.call_google_ai(prompt)
            return result.strip()
        except Exception as e:
            return text
    
    def fix_layout(self, text):
        """Fix text typed in wrong keyboard layout"""
        if not text.strip():
            return text
        
        # Hebrew to English keyboard mapping
        hebrew_to_english = {
            'א': 't', 'ב': 'c', 'ג': 'd', 'ד': 's', 'ה': 'b', 'ו': 'o', 'ז': 'z', 'ח': 'g',
            'ט': 'y', 'י': 'h', 'כ': 'f', 'ל': 'k', 'מ': 'n', 'נ': 'j', 'ס': 'x', 'ע': 'u',
            'פ': 'p', 'צ': 'm', 'ק': 'e', 'ר': 'r', 'ש': 'a', 'ת': ',', 'ן': 'l', 'ם': 'o',
            'ף': ';', 'ץ': '.', 'ך': 'i'
        }
        
        # English to Hebrew keyboard mapping
        english_to_hebrew = {v: k for k, v in hebrew_to_english.items()}
        
        # Try both directions
        fixed_text = text
        
        # Check if text looks like Hebrew typed on English keyboard
        if any(c in english_to_hebrew for c in text.lower()):
            fixed_text = ''.join(english_to_hebrew.get(c.lower(), c) for c in text)
        # Check if text looks like English typed on Hebrew keyboard
        elif any(c in hebrew_to_english for c in text):
            fixed_text = ''.join(hebrew_to_english.get(c, c) for c in text)
        
        return fixed_text
    
    def clean_text(self, text):
        """Remove formatting artifacts and clean text"""
        if not text.strip():
            return text
        
        import re
        
        # Remove multiple spaces
        cleaned = re.sub(r'\s+', ' ', text)
        
        # Remove underlines and formatting characters
        cleaned = re.sub(r'[_]{2,}', '', cleaned)
        
        # Remove excessive punctuation
        cleaned = re.sub(r'[.]{3,}', '...', cleaned)
        cleaned = re.sub(r'[!]{2,}', '!', cleaned)
        cleaned = re.sub(r'[?]{2,}', '?', cleaned)
        
        # Clean up line breaks
        cleaned = re.sub(r'\n\s*\n\s*\n', '\n\n', cleaned)
        
        return cleaned.strip()

# Initialize text processor
text_processor = TextProcessor()

# Routes
@app.route('/')
def index():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    return render_template('landing.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        email = request.form['email']
        username = request.form['username']
        password = request.form['password']
        
        # Check if user exists
        if User.query.filter_by(email=email).first():
            flash('Email already registered')
            return render_template('register.html')
        
        if User.query.filter_by(username=username).first():
            flash('Username already taken')
            return render_template('register.html')
        
        # Create new user
        user = User(email=email, username=username)
        user.set_password(password)
        user.generate_api_key()
        
        db.session.add(user)
        db.session.commit()
        
        login_user(user)
        return redirect(url_for('dashboard'))
    
    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        user = User.query.filter_by(username=username).first()
        
        if user and user.check_password(password):
            login_user(user)
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password')
    
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('index'))

@app.route('/dashboard')
@login_required
def dashboard():
    # Get user statistics
    history_count = ProcessingHistory.query.filter_by(user_id=current_user.id).count()
    recent_activity = ProcessingHistory.query.filter_by(user_id=current_user.id).order_by(
        ProcessingHistory.created_at.desc()
    ).limit(10).all()
    
    stats = {
        'total_processed': current_user.usage_count,
        'monthly_usage': current_user.monthly_usage,
        'usage_limit': current_user.USAGE_LIMITS.get(current_user.subscription_tier, 100),
        'subscription_tier': current_user.subscription_tier.title(),
        'api_key': current_user.api_key,
        'recent_activity': recent_activity
    }
    
    return render_template('saas_dashboard.html', stats=stats)

# API Routes
@app.route('/api/process', methods=['POST'])
@login_required
def api_process():
    """Process text through various operations"""
    if not current_user.can_process():
        return jsonify({
            'error': 'Usage limit exceeded',
            'usage_limit': current_user.USAGE_LIMITS.get(current_user.subscription_tier, 100)
        }), 429
    
    data = request.get_json()
    text = data.get('text', '')
    operation = data.get('operation', '')
    
    if not text or not operation:
        return jsonify({'error': 'Missing text or operation'}), 400
    
    start_time = datetime.utcnow()
    
    try:
        # Process text based on operation
        if operation == 'hebrew_nikud':
            result = text_processor.add_hebrew_nikud(text)
        elif operation == 'correct_text':
            result = text_processor.correct_text(text)
        elif operation == 'translate':
            result = text_processor.translate_text(text)
        elif operation == 'fix_layout':
            result = text_processor.fix_layout(text)
        elif operation == 'clean_text':
            result = text_processor.clean_text(text)
        else:
            return jsonify({'error': 'Unknown operation'}), 400
        
        processing_time = (datetime.utcnow() - start_time).total_seconds()
        
        # Save to history
        history = ProcessingHistory(
            user_id=current_user.id,
            operation_type=operation,
            input_text=text[:1000],  # Limit storage
            output_text=result[:1000],
            language_detected=text_processor.detect_language(text),
            processing_time=processing_time
        )
        db.session.add(history)
        
        # Update user usage
        current_user.increment_usage()
        
        return jsonify({
            'success': True,
            'result': result,
            'processing_time': processing_time,
            'language_detected': text_processor.detect_language(text),
            'remaining_usage': current_user.USAGE_LIMITS.get(current_user.subscription_tier, 100) - current_user.monthly_usage
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/batch_process', methods=['POST'])
@login_required
def api_batch_process():
    """Process multiple texts in batch"""
    data = request.get_json()
    texts = data.get('texts', [])
    operation = data.get('operation', '')
    
    if not texts or not operation:
        return jsonify({'error': 'Missing texts or operation'}), 400
    
    # Check usage limits for batch
    if current_user.monthly_usage + len(texts) > current_user.USAGE_LIMITS.get(current_user.subscription_tier, 100):
        return jsonify({
            'error': 'Batch would exceed usage limit',
            'usage_limit': current_user.USAGE_LIMITS.get(current_user.subscription_tier, 100)
        }), 429
    
    results = []
    
    for text in texts:
        try:
            if operation == 'hebrew_nikud':
                result = text_processor.add_hebrew_nikud(text)
            elif operation == 'correct_text':
                result = text_processor.correct_text(text)
            elif operation == 'translate':
                result = text_processor.translate_text(text)
            elif operation == 'fix_layout':
                result = text_processor.fix_layout(text)
            elif operation == 'clean_text':
                result = text_processor.clean_text(text)
            else:
                result = text
            
            results.append({
                'input': text,
                'output': result,
                'success': True
            })
            
            # Update usage for each processed text
            current_user.increment_usage()
            
        except Exception as e:
            results.append({
                'input': text,
                'output': text,
                'success': False,
                'error': str(e)
            })
    
    return jsonify({
        'success': True,
        'results': results,
        'processed_count': len([r for r in results if r['success']]),
        'remaining_usage': current_user.USAGE_LIMITS.get(current_user.subscription_tier, 100) - current_user.monthly_usage
    })

@app.route('/api/usage')
@login_required
def api_usage():
    """Get user usage statistics"""
    return jsonify({
        'monthly_usage': current_user.monthly_usage,
        'total_usage': current_user.usage_count,
        'usage_limit': current_user.USAGE_LIMITS.get(current_user.subscription_tier, 100),
        'subscription_tier': current_user.subscription_tier,
        'can_process': current_user.can_process()
    })

# Initialize database
def create_tables():
    """Create database tables if they don't exist"""
    with app.app_context():
        db.create_all()

if __name__ == '__main__':
    print("🚀 Starting JoyaaS Platform...")
    print("📊 Dashboard available at: http://localhost:5000")
    print("🎯 Hebrew/English AI Text Processing SaaS")
    
    with app.app_context():
        db.create_all()
        print("✅ Database initialized")
    
    app.run(host='127.0.0.1', port=5000, debug=os.environ.get('FLASK_DEBUG', 'True').lower() == 'true')
