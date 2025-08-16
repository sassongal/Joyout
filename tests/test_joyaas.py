#!/usr/bin/env python3
"""
test_joyaas.py - Quick test script for JoyaaS functionality
Run this to verify that the installation and basic features work
"""

import os
import sys
import subprocess
from pathlib import Path

def test_imports():
    """Test that all required imports work"""
    print("🧪 Testing imports...")
    try:
        import flask
        import flask_sqlalchemy
        import flask_login
        import werkzeug
        import requests
        import dotenv
        print("✅ All required packages imported successfully")
        return True
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False

def test_app_creation():
    """Test that the Flask app can be created"""
    print("🧪 Testing JoyaaS app creation...")
    try:
        # Add current directory to Python path
        sys.path.insert(0, str(Path(__file__).parent))
        from joyaas_app import app, db, User, TextProcessor
        
        # Test app creation
        if not app:
            raise Exception("App not created")
        
        # Test database models
        with app.app_context():
            # This will create tables in memory for testing
            app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
            db.create_all()
            
            # Test creating a user
            test_user = User(email='test@example.com', username='testuser')
            test_user.set_password('testpass')
            test_user.generate_api_key()
            
            db.session.add(test_user)
            db.session.commit()
            
            # Test user methods
            assert test_user.check_password('testpass')
            assert test_user.api_key is not None
            assert test_user.can_process() == True
            
        print("✅ JoyaaS app creation and database models working")
        return True
    except Exception as e:
        print(f"❌ App creation error: {e}")
        return False

def test_text_processor():
    """Test text processing functions"""
    print("🧪 Testing text processing functions...")
    try:
        sys.path.insert(0, str(Path(__file__).parent))
        from joyaas_app import TextProcessor
        
        processor = TextProcessor()
        
        # Test language detection
        hebrew_text = "שלום עולם"
        english_text = "hello world"
        
        assert processor.detect_language(hebrew_text) == "hebrew"
        assert processor.detect_language(english_text) == "english"
        
        # Test layout fixing
        fixed = processor.fix_layout("susu")  # "דודו" typed on English keyboard
        assert fixed == "דודו"  # Should convert correctly
        
        # Test text cleaning
        messy_text = "hello    world___"
        cleaned = processor.clean_text(messy_text)
        assert "hello world" in cleaned
        
        print("✅ Text processing functions working")
        return True
    except Exception as e:
        print(f"❌ Text processor error: {e}")
        return False

def test_configuration():
    """Test configuration loading"""
    print("🧪 Testing configuration...")
    try:
        # Check if .env file exists
        env_file = Path('.env')
        if env_file.exists():
            print("✅ .env file found")
        else:
            print("⚠️  .env file not found - create one using install_joyaas.sh")
        
        # Test environment variables
        google_api_key = os.environ.get('GOOGLE_AI_API_KEY')
        if google_api_key:
            print("✅ Google AI API key configured")
        else:
            print("⚠️  Google AI API key not set - add it to .env file")
            
        return True
    except Exception as e:
        print(f"❌ Configuration error: {e}")
        return False

def test_file_structure():
    """Test that all required files exist"""
    print("🧪 Testing file structure...")
    required_files = [
        'joyaas_app.py',
        'requirements_saas.txt',
        'install_joyaas.sh',
        'templates/landing.html',
        'templates/login.html',
        'templates/register.html',
        'templates/saas_dashboard.html'
    ]
    
    all_exist = True
    for file in required_files:
        if Path(file).exists():
            print(f"✅ {file} exists")
        else:
            print(f"❌ {file} missing")
            all_exist = False
    
    return all_exist

def main():
    """Run all tests"""
    print("🚀 JoyaaS Test Suite")
    print("===================")
    
    tests = [
        test_file_structure,
        test_imports,
        test_configuration,
        test_text_processor,
        test_app_creation
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"❌ Test failed: {e}")
        print("")
    
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! JoyaaS is ready to use.")
        print("\n🚀 To start JoyaaS:")
        print("   python3 joyaas_app.py")
    else:
        print("⚠️  Some tests failed. Please check the errors above.")
        if passed >= 3:
            print("   Basic functionality should still work.")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
