#!/bin/bash

# Joyout SaaS Installation Script
# This script sets up the Joyout SaaS platform for development and production

set -e

echo "🚀 Installing Joyout SaaS Platform..."
echo "======================================="

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed. Please install Python 3.8 or higher."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo "✓ Python $PYTHON_VERSION found"

# Create virtual environment if it doesn't exist
if [ ! -d "venv_saas" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv_saas
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv_saas/bin/activate

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo "📚 Installing Python dependencies..."
pip install -r requirements_saas.txt

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "⚙️  Creating environment configuration..."
    cat > .env << EOL
# Flask Configuration
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
FLASK_ENV=development
FLASK_DEBUG=True

# Database Configuration
DATABASE_URL=sqlite:///joyout_saas.db

# Google AI Configuration
GOOGLE_AI_API_KEY=

# Optional: Production configurations
# DATABASE_URL=postgresql://user:password@localhost:5432/joyout_saas
# REDIS_URL=redis://localhost:6379/0
# MAIL_SERVER=smtp.gmail.com
# MAIL_PORT=587
# MAIL_USERNAME=
# MAIL_PASSWORD=
EOL
    echo "✓ Created .env file - please add your Google AI API key"
fi

# Initialize database
echo "🗄️  Initializing database..."
python3 -c "
from saas_app import app, db
with app.app_context():
    db.create_all()
    print('Database initialized successfully')
"

# Create example data (optional)
echo "📝 Would you like to create a demo user account? (y/n)"
read -r CREATE_DEMO
if [ "$CREATE_DEMO" = "y" ] || [ "$CREATE_DEMO" = "Y" ]; then
    python3 -c "
from saas_app import app, db, User
with app.app_context():
    # Check if demo user already exists
    demo_user = User.query.filter_by(username='demo').first()
    if not demo_user:
        demo_user = User(
            email='demo@joyout.com',
            username='demo'
        )
        demo_user.set_password('demo123')
        demo_user.generate_api_key()
        demo_user.subscription_tier = 'pro'  # Give demo user pro features
        db.session.add(demo_user)
        db.session.commit()
        print('✓ Demo user created: username=demo, password=demo123')
    else:
        print('✓ Demo user already exists: username=demo, password=demo123')
"
fi

# Set up directory structure
echo "📁 Setting up directory structure..."
mkdir -p logs
mkdir -p uploads
mkdir -p backups

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x saas_app.py
chmod +x install_saas.sh

echo ""
echo "🎉 Installation Complete!"
echo "=========================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. 🔑 Add your Google AI API key to the .env file:"
echo "   Edit .env and set GOOGLE_AI_API_KEY=your-api-key"
echo ""
echo "2. 🚀 Start the development server:"
echo "   python3 saas_app.py"
echo ""
echo "3. 🌐 Open your browser and visit:"
echo "   http://localhost:5000"
echo ""
if [ "$CREATE_DEMO" = "y" ] || [ "$CREATE_DEMO" = "Y" ]; then
echo "4. 👤 Login with demo account:"
echo "   Username: demo"
echo "   Password: demo123"
echo ""
fi
echo "📚 Additional Commands:"
echo ""
echo "🛠️  Production deployment:"
echo "   gunicorn -w 4 -b 0.0.0.0:5000 saas_app:app"
echo ""
echo "🧪 Run tests:"
echo "   pytest"
echo ""
echo "📊 Database management:"
echo "   python3 -c \"from saas_app import app, db; app.app_context().push(); db.create_all()\""
echo ""
echo "📈 Usage Analytics:"
echo "   Check the dashboard for user statistics and usage patterns"
echo ""
echo "🔌 API Documentation:"
echo "   Visit /api/docs (when implemented) for API documentation"
echo ""
echo "💡 Get your Google AI API key for free at:"
echo "   https://aistudio.google.com/app/apikey"
echo ""
echo "Happy processing! 🎯"
