# JoyaaS - Complete Guide & Documentation

## Overview

JoyaaS (Joyout as a Service) is a comprehensive Hebrew/English text processing platform that provides intelligent layout fixing, text cleaning, and AI-powered language services. The platform consists of multiple components working together with a shared algorithm library for consistent results.

## Architecture

### Components

1. **Web SaaS Platform** (`joyaas_app.py`) - Flask-based web application with user management and API
2. **MenuBar App** (`JoyaaS-MenuBar/`) - macOS native MenuBar application 
3. **Native Desktop App** (`JoyaaS-Native/`) - Cross-platform desktop application
4. **Shared Algorithm Library** (`shared/algorithms/`) - Common layout fixing logic

### Shared Algorithm Library

The core of JoyaaS is a unified layout fixing algorithm that ensures consistent results across all components:

- **Python**: `shared/algorithms/layout_fixer.py` 
- **Swift**: `shared/algorithms/LayoutFixer.swift`
- **Documentation**: `shared/algorithms/README.md`

#### Key Features
- ✅ Fixes text typed in wrong Hebrew/English keyboard layout
- ✅ Validates conversion results using linguistic heuristics  
- ✅ Handles edge cases (mixed content, short text, non-alphabetic)
- ✅ Identical behavior across Python and Swift implementations

## Installation & Setup

### Web Platform

1. **Install Dependencies**:
   ```bash
   pip install -r requirements_saas.txt
   ```

2. **Configure Environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

3. **Run the Application**:
   ```bash
   python3 joyaas_app.py
   ```

### MenuBar App (macOS)

1. **Open in Xcode**:
   ```bash
   open JoyaaS-MenuBar/JoyaaSMenuBar.xcodeproj
   ```

2. **Build and Run** from Xcode or:
   ```bash
   cd JoyaaS-MenuBar
   xcodebuild -scheme JoyaaSMenuBar -configuration Release
   ```

### Native Desktop App

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the App**:
   ```bash
   python3 app.py
   ```

## Usage

### Text Processing Operations

#### Layout Fixing
Automatically detects and fixes text typed in the wrong keyboard layout:

```python
from shared.algorithms import LayoutFixer

fixer = LayoutFixer()
result = fixer.fix_layout("susu")  # Returns: "דודו"
```

**Examples**:
- `susu` → `דודו` (English typed in Hebrew layout)
- `akuo` → `שלום` (English typed in Hebrew layout)  
- `hello` → `hello` (correct English stays unchanged)
- `שלום` → `שלום` (correct Hebrew stays unchanged)

#### Text Cleaning
Removes formatting artifacts and normalizes text:

```python
processor = TextProcessor()
clean_text = processor.clean_text("hello    world___")  # Returns: "hello world"
```

#### AI-Powered Features
- Hebrew nikud (vowelization) addition
- Grammar and spelling correction
- Hebrew/English translation

### API Usage

#### Web API Endpoints

**Process Text**:
```bash
curl -X POST http://localhost:5432/api/process \
  -H "Content-Type: application/json" \
  -d '{"text": "susu", "operation": "fix_layout"}'
```

**Batch Processing**:
```bash
curl -X POST http://localhost:5432/api/batch_process \
  -H "Content-Type: application/json" \
  -d '{"texts": ["susu", "hello"], "operation": "fix_layout"}'
```

## Development

### Testing

Run the comprehensive test suite:

```bash
# Test shared algorithm integration
python3 tests/test_shared_algorithm_integration.py

# Test overall functionality  
python3 tests/test_joyaas.py

# Test Swift implementation
swift tests/test_swift_menubar_integration.swift
```

### Adding New Components

1. **Import Shared Algorithm**:
   ```python
   from shared.algorithms import LayoutFixer
   fixer = LayoutFixer()
   result = fixer.fix_layout(text)
   ```

2. **Follow Integration Tests**: Use `tests/test_shared_algorithm_integration.py` as a template

3. **Maintain Consistency**: All components must produce identical results for the same inputs

### Extending the Algorithm

To modify the layout fixing algorithm:

1. Update both `shared/algorithms/layout_fixer.py` and `shared/algorithms/LayoutFixer.swift`
2. Ensure both implementations remain identical
3. Run integration tests to verify consistency
4. Update version numbers in both files

## Configuration

### Environment Variables

**Required**:
- `SECRET_KEY` - Flask application secret key
- `DATABASE_URL` - Database connection string (optional, defaults to SQLite)

**Optional**:
- `GOOGLE_AI_API_KEY` - For AI-powered features
- `GOOGLE_TRANSLATE_API_KEY` - For translation services
- `FLASK_DEBUG` - Enable debug mode (development only)

### Database Setup

The web platform automatically creates necessary database tables on first run. For production, use PostgreSQL:

```bash
export DATABASE_URL="postgresql://user:pass@localhost/joyaas"
```

## Deployment

### Web Platform Deployment

1. **Production Setup**:
   ```bash
   pip install gunicorn
   gunicorn -w 4 -b 0.0.0.0:8000 joyaas_app:app
   ```

2. **Docker Deployment**:
   ```dockerfile
   FROM python:3.9-slim
   COPY requirements_saas.txt .
   RUN pip install -r requirements_saas.txt
   COPY . .
   CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "joyaas_app:app"]
   ```

### MenuBar App Distribution

1. **Archive for Distribution**:
   ```bash
   cd JoyaaS-MenuBar
   xcodebuild -scheme JoyaaSMenuBar -configuration Release archive -archivePath JoyaaS.xcarchive
   ```

2. **Export for Distribution** via Xcode Organizer

## Troubleshooting

### Common Issues

**Import Errors**:
```bash
# Ensure you're in the project root directory
cd /path/to/joyout
python3 -c "from shared.algorithms import LayoutFixer; print('Import successful')"
```

**Layout Fixing Not Working**:
```bash
# Test the algorithm directly
python3 -c "from shared.algorithms import LayoutFixer; print(LayoutFixer().fix_layout('susu'))"
# Should output: דודו
```

**Database Issues**:
```bash
# Reset database (development only)
rm -f joyaas.db
python3 joyaas_app.py
```

### Debug Mode

Enable debug logging:
```bash
export FLASK_DEBUG=true
python3 joyaas_app.py
```

## Contributing

### Development Workflow

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/new-feature
   ```

2. **Make Changes**: Ensure all tests pass

3. **Run Tests**:
   ```bash
   python3 tests/test_shared_algorithm_integration.py
   ```

4. **Submit Pull Request** with test results

### Code Standards

- **Python**: Follow PEP 8
- **Swift**: Follow Swift API Design Guidelines  
- **Documentation**: Update relevant documentation for all changes
- **Testing**: Add tests for new functionality

## Support

### Getting Help

1. **Check Documentation**: Start with this comprehensive guide
2. **Run Tests**: Use test scripts to verify functionality
3. **Check Issues**: Review existing GitHub issues
4. **Create Issue**: Provide test results and error logs

### Performance Optimization

**For High-Volume Usage**:
- Use Redis for caching
- Implement request rate limiting
- Consider API key authentication
- Monitor resource usage

## Version History

- **2.0.0** - Unified shared algorithm library across all components
- **1.5.0** - Added MenuBar app with corrected algorithm
- **1.0.0** - Initial web platform release

---

**Last Updated**: 2025-08-16  
**Version**: 2.0.0 (Unified Algorithm)
