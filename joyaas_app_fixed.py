#!/usr/bin/env python3
"""
JoyaaS with automatic port detection to avoid conflicts
"""

import socket
from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime, timedelta
import uuid
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add the Scripts directory to the Python path
scripts_dir = Path(__file__).parent
sys.path.insert(0, str(scripts_dir))

# Import shared algorithm
from shared.algorithms import LayoutFixer

def find_free_port(start_port=8080):
    """Find a free port starting from start_port"""
    for port in range(start_port, start_port + 50):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(('127.0.0.1', port))
                return port
            except OSError:
                continue
    return None

# Configuration
app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-key-change-in-production')
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///joyaas.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize extensions
db = SQLAlchemy(app)
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# Simple User model
class User(UserMixin, db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = db.Column(db.String(120), unique=True, nullable=False)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(120), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    subscription_tier = db.Column(db.String(20), default='free')
    api_key = db.Column(db.String(64), unique=True)
    usage_count = db.Column(db.Integer, default=0)
    monthly_usage = db.Column(db.Integer, default=0)
    last_reset = db.Column(db.DateTime, default=datetime.utcnow)
    
    USAGE_LIMITS = {'free': 100, 'pro': 5000, 'enterprise': 50000}
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def generate_api_key(self):
        self.api_key = str(uuid.uuid4()).replace('-', '')
    
    def can_process(self):
        return self.monthly_usage < self.USAGE_LIMITS.get(self.subscription_tier, 100)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(user_id)

# Initialize shared layout fixer
_layout_fixer = LayoutFixer()

# Simple text processing functions
def fix_layout(text):
    """Fix text typed in wrong keyboard layout (Hebrew/English) - Uses shared algorithm"""
    return _layout_fixer.fix_layout(text)


def clean_text(text):
    """Remove formatting artifacts"""
    import re
    cleaned = re.sub(r'\s+', ' ', text)
    cleaned = re.sub(r'[_]{2,}', '', cleaned)
    cleaned = re.sub(r'[.]{3,}', '...', cleaned)
    return cleaned.strip()

# Routes
@app.route('/')
def index():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>JoyaaS - Hebrew/English Text Processing</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; }
            .container { background: white; border-radius: 20px; padding: 40px; max-width: 600px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); text-align: center; }
            h1 { color: #333; margin-bottom: 20px; font-size: 2.5rem; }
            p { color: #666; margin-bottom: 30px; font-size: 1.1rem; }
            .buttons { display: flex; gap: 15px; justify-content: center; }
            .btn { padding: 15px 30px; border: none; border-radius: 10px; font-size: 1rem; cursor: pointer; text-decoration: none; display: inline-block; transition: transform 0.2s; }
            .btn-primary { background: #667eea; color: white; }
            .btn-secondary { background: #f1f3f4; color: #333; }
            .btn:hover { transform: translateY(-2px); }
            .features { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; margin-top: 30px; text-align: left; }
            .feature { padding: 15px; background: #f8f9fa; border-radius: 10px; }
            .feature h3 { margin: 0 0 10px 0; color: #667eea; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 JoyaaS</h1>
            <p>Professional Hebrew/English Text Processing Platform</p>
            <div class="buttons">
                <a href="/login" class="btn btn-primary">Login</a>
                <a href="/register" class="btn btn-secondary">Register</a>
            </div>
            
            <div class="features">
                <div class="feature">
                    <h3>🔧 Layout Fixer</h3>
                    <p>Fix text typed in wrong keyboard layout</p>
                </div>
                <div class="feature">
                    <h3>🧹 Text Cleaner</h3>
                    <p>Remove formatting artifacts</p>
                </div>
                <div class="feature">
                    <h3>📊 Usage Dashboard</h3>
                    <p>Track your text processing</p>
                </div>
                <div class="feature">
                    <h3>🔌 API Access</h3>
                    <p>Integrate into your apps</p>
                </div>
            </div>
            
            <div style="margin-top: 30px; padding: 20px; background: #e3f2fd; border-radius: 10px;">
                <h3>🎯 Demo Account</h3>
                <p><strong>Username:</strong> demo<br><strong>Password:</strong> demo123</p>
            </div>
        </div>
    </body>
    </html>
    '''

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
    
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Login - JoyaaS</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; margin: 0; }
            .form-container { background: white; padding: 40px; border-radius: 15px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); width: 100%; max-width: 400px; }
            h2 { color: #333; margin-bottom: 30px; text-align: center; }
            .form-group { margin-bottom: 20px; }
            label { display: block; margin-bottom: 5px; font-weight: 600; color: #333; }
            input { width: 100%; padding: 12px; border: 2px solid #e1e5e9; border-radius: 8px; font-size: 16px; box-sizing: border-box; }
            input:focus { outline: none; border-color: #667eea; }
            .btn { width: 100%; padding: 15px; background: #667eea; color: white; border: none; border-radius: 8px; font-size: 16px; cursor: pointer; margin-bottom: 15px; }
            .btn:hover { background: #5a6fd8; }
            .link { text-align: center; }
            .link a { color: #667eea; text-decoration: none; }
        </style>
    </head>
    <body>
        <div class="form-container">
            <h2>Login to JoyaaS</h2>
            <form method="post">
                <div class="form-group">
                    <label>Username:</label>
                    <input type="text" name="username" required>
                </div>
                <div class="form-group">
                    <label>Password:</label>
                    <input type="password" name="password" required>
                </div>
                <button type="submit" class="btn">Login</button>
            </form>
            <div class="link">
                <a href="/register">Don't have an account? Register</a><br>
                <a href="/">← Back to Home</a>
            </div>
        </div>
    </body>
    </html>
    '''

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        email = request.form['email']
        username = request.form['username']
        password = request.form['password']
        
        if User.query.filter_by(email=email).first():
            flash('Email already registered')
            return redirect(url_for('register'))
        
        if User.query.filter_by(username=username).first():
            flash('Username already taken')
            return redirect(url_for('register'))
        
        user = User(email=email, username=username)
        user.set_password(password)
        user.generate_api_key()
        
        db.session.add(user)
        db.session.commit()
        
        login_user(user)
        return redirect(url_for('dashboard'))
    
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Register - JoyaaS</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; margin: 0; }
            .form-container { background: white; padding: 40px; border-radius: 15px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); width: 100%; max-width: 400px; }
            h2 { color: #333; margin-bottom: 30px; text-align: center; }
            .form-group { margin-bottom: 20px; }
            label { display: block; margin-bottom: 5px; font-weight: 600; color: #333; }
            input { width: 100%; padding: 12px; border: 2px solid #e1e5e9; border-radius: 8px; font-size: 16px; box-sizing: border-box; }
            input:focus { outline: none; border-color: #667eea; }
            .btn { width: 100%; padding: 15px; background: #667eea; color: white; border: none; border-radius: 8px; font-size: 16px; cursor: pointer; margin-bottom: 15px; }
            .btn:hover { background: #5a6fd8; }
            .link { text-align: center; }
            .link a { color: #667eea; text-decoration: none; }
        </style>
    </head>
    <body>
        <div class="form-container">
            <h2>Register for JoyaaS</h2>
            <form method="post">
                <div class="form-group">
                    <label>Email:</label>
                    <input type="email" name="email" required>
                </div>
                <div class="form-group">
                    <label>Username:</label>
                    <input type="text" name="username" required>
                </div>
                <div class="form-group">
                    <label>Password:</label>
                    <input type="password" name="password" required>
                </div>
                <button type="submit" class="btn">Register</button>
            </form>
            <div class="link">
                <a href="/login">Already have an account? Login</a><br>
                <a href="/">← Back to Home</a>
            </div>
        </div>
    </body>
    </html>
    '''

@app.route('/dashboard')
@login_required
def dashboard():
    return f'''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Dashboard - JoyaaS</title>
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 0; background: #f5f7fa; }}
            .header {{ background: white; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); display: flex; justify-content: space-between; align-items: center; }}
            .main {{ max-width: 1200px; margin: 40px auto; padding: 0 20px; }}
            .card {{ background: white; padding: 30px; border-radius: 15px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 30px; }}
            .tools {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }}
            .tool {{ padding: 20px; border: 2px solid #e1e5e9; border-radius: 10px; cursor: pointer; transition: all 0.2s; }}
            .tool:hover {{ border-color: #667eea; transform: translateY(-2px); }}
            .btn {{ padding: 12px 24px; background: #667eea; color: white; border: none; border-radius: 8px; cursor: pointer; text-decoration: none; display: inline-block; }}
            .btn:hover {{ background: #5a6fd8; }}
            textarea {{ width: 100%; padding: 15px; border: 2px solid #e1e5e9; border-radius: 8px; font-size: 16px; min-height: 120px; resize: vertical; box-sizing: border-box; }}
            .result {{ background: #f8f9fa; border: 2px solid #e9ecef; border-radius: 8px; padding: 15px; margin-top: 15px; min-height: 60px; }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🚀 JoyaaS Dashboard</h1>
            <div>
                <span>Welcome, {current_user.username}!</span>
                <a href="/logout" class="btn" style="margin-left: 15px;">Logout</a>
            </div>
        </div>
        
        <div class="main">
            <div class="card">
                <h2>📊 Your Stats</h2>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px;">
                    <div style="text-align: center; padding: 20px; background: #e3f2fd; border-radius: 10px;">
                        <h3 style="margin: 0; color: #1976d2;">Monthly Usage</h3>
                        <p style="font-size: 2rem; margin: 10px 0; font-weight: bold;">{current_user.monthly_usage}</p>
                        <p style="margin: 0; color: #666;">/ {current_user.USAGE_LIMITS.get(current_user.subscription_tier, 100)} limit</p>
                    </div>
                    <div style="text-align: center; padding: 20px; background: #f3e5f5; border-radius: 10px;">
                        <h3 style="margin: 0; color: #7b1fa2;">Total Processed</h3>
                        <p style="font-size: 2rem; margin: 10px 0; font-weight: bold;">{current_user.usage_count}</p>
                        <p style="margin: 0; color: #666;">texts processed</p>
                    </div>
                    <div style="text-align: center; padding: 20px; background: #e8f5e8; border-radius: 10px;">
                        <h3 style="margin: 0; color: #388e3c;">Plan</h3>
                        <p style="font-size: 2rem; margin: 10px 0; font-weight: bold;">{current_user.subscription_tier.title()}</p>
                        <p style="margin: 0; color: #666;">subscription</p>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <h2>🔧 Text Processing Tools</h2>
                <div class="tools">
                    <div class="tool" onclick="showTool('layout')">
                        <h3>🔤 Layout Fixer</h3>
                        <p>Fix text typed in wrong Hebrew/English keyboard layout</p>
                    </div>
                    <div class="tool" onclick="showTool('clean')">
                        <h3>🧹 Text Cleaner</h3>
                        <p>Remove formatting artifacts and clean up text</p>
                    </div>
                </div>
            </div>
            
            <div class="card" id="processor" style="display: none;">
                <h2 id="tool-title">Text Processor</h2>
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                    <div>
                        <h3>Input Text</h3>
                        <textarea id="input-text" placeholder="Enter your text here..."></textarea>
                        <button class="btn" onclick="processText()" style="margin-top: 15px;">Process Text</button>
                    </div>
                    <div>
                        <h3>Processed Result</h3>
                        <div id="output" class="result">Processed text will appear here...</div>
                    </div>
                </div>
            </div>
        </div>
        
        <script>
            let currentTool = '';
            
            function showTool(tool) {{
                currentTool = tool;
                const processor = document.getElementById('processor');
                const title = document.getElementById('tool-title');
                
                if (tool === 'layout') {{
                    title.textContent = '🔤 Layout Fixer';
                }} else if (tool === 'clean') {{
                    title.textContent = '🧹 Text Cleaner';
                }}
                
                processor.style.display = 'block';
                processor.scrollIntoView({{ behavior: 'smooth' }});
            }}
            
            function processText() {{
                const input = document.getElementById('input-text').value;
                const output = document.getElementById('output');
                
                if (!input.trim()) {{
                    alert('Please enter some text to process');
                    return;
                }}
                
                // Simple client-side processing
                let result = input;
                
                if (currentTool === 'layout') {{
                    // Hebrew to English mapping (simplified)
                    const heToEn = {{'א':'t','ב':'c','ג':'d','ד':'s','ה':'b','ו':'o','ז':'z','ח':'g','ט':'y','י':'h','כ':'f','ל':'k','מ':'n','נ':'j','ס':'x','ע':'u','פ':'p','צ':'m','ק':'e','ר':'r','ש':'a','ת':','}};
                    const enToHe = {{}};
                    Object.keys(heToEn).forEach(k => enToHe[heToEn[k]] = k);
                    
                    // Try Hebrew to English first
                    if (Object.keys(heToEn).some(c => input.includes(c))) {{
                        result = input.split('').map(c => heToEn[c] || c).join('');
                    }} 
                    // Try English to Hebrew
                    else if (Object.keys(enToHe).some(c => input.toLowerCase().includes(c))) {{
                        result = input.split('').map(c => enToHe[c.toLowerCase()] || c).join('');
                    }}
                }} else if (currentTool === 'clean') {{
                    result = input.replace(/\\s+/g, ' ').replace(/_+/g, '').replace(/\\.{{3,}}/g, '...').trim();
                }}
                
                output.textContent = result;
                output.style.background = '#e8f5e8';
                output.style.borderColor = '#4caf50';
            }}
        </script>
    </body>
    </html>
    '''

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('index'))

if __name__ == '__main__':
    # Find free port
    port = find_free_port(8080)
    if not port:
        print("❌ No free ports available")
        sys.exit(1)
    
    print("🚀 Starting JoyaaS Platform...")
    print(f"📊 Dashboard available at: http://localhost:{port}")
    print("🎯 Hebrew/English AI Text Processing SaaS")
    print(f"🔧 Using port {port} (automatically detected)")
    
    with app.app_context():
        db.create_all()
        
        # Create demo user if doesn't exist
        demo_user = User.query.filter_by(username='demo').first()
        if not demo_user:
            demo_user = User(email='demo@joyaas.com', username='demo')
            demo_user.set_password('demo123')
            demo_user.generate_api_key()
            db.session.add(demo_user)
            db.session.commit()
            print("✅ Demo user created (demo/demo123)")
        
        print("✅ Database initialized")
    
    app.run(host='127.0.0.1', port=port, debug=False)
