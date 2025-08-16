"""
JoyaaS Shared Algorithms Package
===============================

This package contains shared algorithms used across all JoyaaS components:
- Web App (Python Flask)
- MenuBar App (Swift/Python bridge)
- Native App (Swift)

The shared algorithms ensure consistency and maintainability across platforms.
"""

# Import all shared algorithms for easy access
from .algorithms.layout_fixer import LayoutFixer, fix_layout
from .algorithms.language_detector import AdvancedLanguageDetector, detect_language_simple, detect_language_with_confidence
from .algorithms.smart_cache import SmartCache, get_cache, cached_operation, cache_layout_fix, cache_text_clean, cache_language_detect, cache_ai_operation

# Import real-time processing capabilities
from .realtime_processor import (
    RealTimeProcessor, 
    ProcessingRequest, 
    ProcessingResult,
    DebounceManager,
    StreamProcessor,
    WebSocketConnection,
    debounced_processing,
    realtime_endpoint
)

from .realtime_api import (
    RealTimeAPI,
    TextProcessingRequest,
    TextProcessingResponse,
    RealTimeClient,
    create_realtime_api,
    run_realtime_server
)

__version__ = "2.0.0"
__all__ = [
    "LayoutFixer", "fix_layout", 
    "AdvancedLanguageDetector", "detect_language_simple", "detect_language_with_confidence",
    "SmartCache", "get_cache", "cached_operation", 
    "cache_layout_fix", "cache_text_clean", "cache_language_detect", "cache_ai_operation",
    "RealTimeProcessor", "ProcessingRequest", "ProcessingResult",
    "DebounceManager", "StreamProcessor", "WebSocketConnection",
    "debounced_processing", "realtime_endpoint",
    "RealTimeAPI", "TextProcessingRequest", "TextProcessingResponse",
    "RealTimeClient", "create_realtime_api", "run_realtime_server"
]
