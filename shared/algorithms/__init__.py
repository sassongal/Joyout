"""
JoyaaS Shared Algorithms Package
================================

This package contains the unified algorithms used across all JoyaaS components.

Available modules:
- layout_fixer: Hebrew/English layout fixing algorithm
- language_detector: Advanced language detection with confidence scoring
- smart_cache: Intelligent caching system for performance optimization
- security: Input sanitization, rate limiting, and security protection

Author: JoyaaS Development Team
Version: 3.0.0
"""

# Core layout fixing algorithm
from .layout_fixer import LayoutFixer, fix_layout

# Advanced language detection
from .language_detector import (
    AdvancedLanguageDetector,
    detect_language_simple,
    detect_language_with_confidence
)

# Smart caching system
from .smart_cache import (
    SmartCache, 
    cached_operation, 
    get_cache,
    cache_layout_fix,
    cache_text_clean, 
    cache_language_detect,
    cache_ai_operation
)

# Security module - input sanitization and protection
from .security import (
    InputSanitizer,
    RateLimiter,
    SecurityValidator,
    secure_endpoint,
    get_security_validator
)

__version__ = "3.0.0"
__author__ = "JoyaaS Development Team"

__all__ = [
    # Layout fixing
    "LayoutFixer", "fix_layout",
    
    # Language detection
    "AdvancedLanguageDetector", "detect_language_simple", "detect_language_with_confidence",
    
    # Smart caching
    "SmartCache", "cached_operation", "get_cache",
    "cache_layout_fix", "cache_text_clean", "cache_language_detect", "cache_ai_operation",
    
    # Security
    "InputSanitizer", "RateLimiter", "SecurityValidator", 
    "secure_endpoint", "get_security_validator"
]
