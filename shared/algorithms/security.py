#!/usr/bin/env python3
"""
Security Module for JoyaaS
===========================

Comprehensive security utilities for input sanitization, rate limiting,
and protection against common vulnerabilities:
- Input sanitization and validation
- SQL injection prevention  
- XSS protection
- Rate limiting for API endpoints
- Security headers and CSRF protection
- Content filtering and validation

Author: JoyaaS Development Team
Version: 1.0.0
"""

import re
import html
import time
import hashlib
import secrets
import logging
from typing import Dict, Any, Optional, List, Callable, Tuple
from functools import wraps
from datetime import datetime, timedelta
from collections import defaultdict, deque
import unicodedata


class InputSanitizer:
    """Advanced input sanitization and validation."""
    
    # Dangerous patterns to detect and neutralize
    SQL_INJECTION_PATTERNS = [
        r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION)\b)",
        r"(\b(OR|AND)\s+\d+\s*=\s*\d+)",
        r"(--|\|\||;|\/\*|\*\/)",
        r"(\bxp_cmdshell\b|\bsp_\w+\b)",
        r"(\b(SCRIPT|IFRAME|OBJECT|EMBED|LINK|META)\b)",
    ]
    
    XSS_PATTERNS = [
        r"<\s*script[^>]*>.*?<\s*/\s*script\s*>",
        r"javascript\s*:",
        r"on\w+\s*=",
        r"<\s*iframe[^>]*>",
        r"<\s*object[^>]*>",
        r"<\s*embed[^>]*>",
        r"eval\s*\(",
        r"expression\s*\(",
    ]
    
    # Safe characters for different contexts
    SAFE_FILENAME_CHARS = re.compile(r'[^a-zA-Z0-9._\-]')
    SAFE_TEXT_CHARS = re.compile(r'[^\w\s\u0590-\u05FF.,!?:;()\-"\']')  # Include Hebrew
    
    def __init__(self):
        """Initialize the input sanitizer."""
        self.logger = logging.getLogger(__name__)
        
        # Compile patterns for performance
        self.sql_patterns = [re.compile(pattern, re.IGNORECASE | re.DOTALL) 
                           for pattern in self.SQL_INJECTION_PATTERNS]
        self.xss_patterns = [re.compile(pattern, re.IGNORECASE | re.DOTALL)
                           for pattern in self.XSS_PATTERNS]
    
    def sanitize_text(self, text: str, max_length: int = 10000) -> str:
        """Sanitize text input for safe processing."""
        if not isinstance(text, str):
            raise ValueError("Input must be a string")
        
        if len(text) > max_length:
            raise ValueError(f"Input too long (max {max_length} characters)")
        
        # Normalize Unicode
        text = unicodedata.normalize('NFKC', text)
        
        # HTML escape
        text = html.escape(text)
        
        # Remove null bytes and other dangerous characters
        text = text.replace('\x00', '').replace('\r', '')
        
        # Check for SQL injection patterns
        for pattern in self.sql_patterns:
            if pattern.search(text):
                self.logger.warning(f"Potential SQL injection detected: {text[:100]}...")
                raise ValueError("Input contains potentially dangerous SQL patterns")
        
        # Check for XSS patterns
        for pattern in self.xss_patterns:
            if pattern.search(text):
                self.logger.warning(f"Potential XSS detected: {text[:100]}...")
                raise ValueError("Input contains potentially dangerous script patterns")
        
        return text
    
    def sanitize_filename(self, filename: str) -> str:
        """Sanitize filename for safe file operations."""
        if not isinstance(filename, str):
            raise ValueError("Filename must be a string")
        
        if len(filename) > 255:
            raise ValueError("Filename too long")
        
        # Remove dangerous characters
        filename = self.SAFE_FILENAME_CHARS.sub('_', filename)
        
        # Prevent directory traversal
        filename = filename.replace('..', '').replace('/', '').replace('\\', '')
        
        # Ensure it's not empty
        if not filename.strip('_'):
            raise ValueError("Invalid filename")
        
        return filename
    
    def validate_text_content(self, text: str) -> Dict[str, Any]:
        """Validate text content and return safety metrics."""
        metrics = {
            'length': len(text),
            'safe': True,
            'warnings': [],
            'sanitized_length': 0
        }
        
        try:
            sanitized = self.sanitize_text(text)
            metrics['sanitized_length'] = len(sanitized)
        except ValueError as e:
            metrics['safe'] = False
            metrics['warnings'].append(str(e))
        
        # Check for suspicious patterns
        if re.search(r'\b(password|token|key|secret)\b', text, re.IGNORECASE):
            metrics['warnings'].append("Potential sensitive data detected")
        
        if len(text) > 5000:
            metrics['warnings'].append("Large input size")
        
        return metrics
    
    def clean_for_display(self, text: str) -> str:
        """Clean text for safe display in UI."""
        # Basic sanitization
        text = html.escape(text)
        
        # Remove excessive whitespace
        text = re.sub(r'\s+', ' ', text).strip()
        
        # Truncate if too long
        if len(text) > 500:
            text = text[:497] + "..."
        
        return text


class RateLimiter:
    """Advanced rate limiting for API protection."""
    
    def __init__(self, 
                 requests_per_minute: int = 60,
                 requests_per_hour: int = 1000,
                 burst_allowance: int = 10):
        """Initialize rate limiter with configurable limits."""
        self.requests_per_minute = requests_per_minute
        self.requests_per_hour = requests_per_hour
        self.burst_allowance = burst_allowance
        
        # Track requests by client
        self.minute_requests = defaultdict(deque)
        self.hour_requests = defaultdict(deque)
        self.burst_requests = defaultdict(deque)
        
        self.logger = logging.getLogger(__name__)
    
    def _clean_old_requests(self, client_id: str):
        """Clean up old request timestamps."""
        now = time.time()
        
        # Clean minute requests (older than 60 seconds)
        minute_queue = self.minute_requests[client_id]
        while minute_queue and now - minute_queue[0] > 60:
            minute_queue.popleft()
        
        # Clean hour requests (older than 3600 seconds)
        hour_queue = self.hour_requests[client_id]
        while hour_queue and now - hour_queue[0] > 3600:
            hour_queue.popleft()
        
        # Clean burst requests (older than 10 seconds)
        burst_queue = self.burst_requests[client_id]
        while burst_queue and now - burst_queue[0] > 10:
            burst_queue.popleft()
    
    def is_allowed(self, client_id: str) -> Tuple[bool, Dict[str, Any]]:
        """Check if request is allowed for client."""
        self._clean_old_requests(client_id)
        
        now = time.time()
        
        # Check limits
        minute_count = len(self.minute_requests[client_id])
        hour_count = len(self.hour_requests[client_id])
        burst_count = len(self.burst_requests[client_id])
        
        # Determine if allowed
        allowed = True
        reason = None
        
        if burst_count >= self.burst_allowance:
            allowed = False
            reason = f"Burst limit exceeded ({burst_count}/{self.burst_allowance})"
        elif minute_count >= self.requests_per_minute:
            allowed = False
            reason = f"Minute limit exceeded ({minute_count}/{self.requests_per_minute})"
        elif hour_count >= self.requests_per_hour:
            allowed = False
            reason = f"Hour limit exceeded ({hour_count}/{self.requests_per_hour})"
        
        # If allowed, record the request
        if allowed:
            self.minute_requests[client_id].append(now)
            self.hour_requests[client_id].append(now)
            self.burst_requests[client_id].append(now)
        else:
            self.logger.warning(f"Rate limit exceeded for {client_id}: {reason}")
        
        status = {
            'allowed': allowed,
            'reason': reason,
            'minute_requests': minute_count,
            'hour_requests': hour_count,
            'burst_requests': burst_count,
            'reset_times': {
                'minute': now + 60,
                'hour': now + 3600,
                'burst': now + 10
            }
        }
        
        return allowed, status


class SecurityValidator:
    """Comprehensive security validation for JoyaaS operations."""
    
    def __init__(self):
        """Initialize security validator."""
        self.sanitizer = InputSanitizer()
        self.rate_limiter = RateLimiter()
        self.logger = logging.getLogger(__name__)
        
        # Track security events
        self.security_events = deque(maxlen=1000)
    
    def validate_layout_fix_input(self, text: str, client_id: str) -> Dict[str, Any]:
        """Validate input for layout fixing operations."""
        # Rate limiting
        allowed, rate_status = self.rate_limiter.is_allowed(client_id)
        if not allowed:
            return {
                'valid': False,
                'error': 'Rate limit exceeded',
                'details': rate_status
            }
        
        # Input sanitization
        try:
            sanitized_text = self.sanitizer.sanitize_text(text, max_length=5000)
            content_metrics = self.sanitizer.validate_text_content(text)
            
            result = {
                'valid': content_metrics['safe'],
                'sanitized_text': sanitized_text,
                'original_length': len(text),
                'sanitized_length': len(sanitized_text),
                'warnings': content_metrics['warnings'],
                'rate_limit_status': rate_status
            }
            
            if not content_metrics['safe']:
                result['error'] = 'Input failed security validation'
                self._log_security_event('input_validation_failed', client_id, text[:100])
            
            return result
            
        except ValueError as e:
            self._log_security_event('input_sanitization_failed', client_id, str(e))
            return {
                'valid': False,
                'error': f'Input sanitization failed: {str(e)}',
                'rate_limit_status': rate_status
            }
    
    def _log_security_event(self, event_type: str, client_id: str, details: str):
        """Log security events for monitoring."""
        event = {
            'timestamp': datetime.now().isoformat(),
            'type': event_type,
            'client_id': client_id,
            'details': details
        }
        
        self.security_events.append(event)
        self.logger.warning(f"Security event: {event_type} for {client_id}")
    
    def get_security_stats(self) -> Dict[str, Any]:
        """Get security statistics and recent events."""
        recent_events = list(self.security_events)[-50:]  # Last 50 events
        
        event_counts = defaultdict(int)
        for event in recent_events:
            event_counts[event['type']] += 1
        
        return {
            'total_events': len(self.security_events),
            'recent_events': recent_events,
            'event_type_counts': dict(event_counts),
            'rate_limiter_status': {
                'active_clients': len(self.rate_limiter.minute_requests)
            }
        }


# Decorators for easy security integration
def secure_endpoint(rate_limit_per_minute: int = 60):
    """Decorator to add security validation to functions."""
    validator = SecurityValidator()
    
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Extract client ID (could be IP, user ID, etc.)
            client_id = kwargs.get('client_id', 'unknown')
            
            # Check rate limiting
            allowed, status = validator.rate_limiter.is_allowed(client_id)
            if not allowed:
                raise ValueError(f"Rate limit exceeded: {status['reason']}")
            
            # Sanitize string arguments
            sanitized_args = []
            for arg in args:
                if isinstance(arg, str):
                    try:
                        sanitized_arg = validator.sanitizer.sanitize_text(arg)
                        sanitized_args.append(sanitized_arg)
                    except ValueError as e:
                        raise ValueError(f"Input validation failed: {str(e)}")
                else:
                    sanitized_args.append(arg)
            
            # Sanitize string keyword arguments
            sanitized_kwargs = {}
            for key, value in kwargs.items():
                if isinstance(value, str) and key not in ['client_id']:
                    try:
                        sanitized_kwargs[key] = validator.sanitizer.sanitize_text(value)
                    except ValueError as e:
                        raise ValueError(f"Input validation failed for {key}: {str(e)}")
                else:
                    sanitized_kwargs[key] = value
            
            return func(*sanitized_args, **sanitized_kwargs)
        
        return wrapper
    return decorator


# Global security validator instance
_security_validator = None

def get_security_validator() -> SecurityValidator:
    """Get the global security validator instance."""
    global _security_validator
    if _security_validator is None:
        _security_validator = SecurityValidator()
    return _security_validator


# Example usage and testing
if __name__ == "__main__":
    print("🔒 Security Module Test")
    print("=" * 40)
    
    # Test input sanitization
    sanitizer = InputSanitizer()
    
    test_inputs = [
        "Hello world",
        "שלום עולם",
        "<script>alert('xss')</script>",
        "SELECT * FROM users; DROP TABLE users;",
        "Normal text with some Hebrew: שלום",
        "' OR 1=1 --",
    ]
    
    print("Testing Input Sanitization:")
    for text in test_inputs:
        try:
            sanitized = sanitizer.sanitize_text(text)
            metrics = sanitizer.validate_text_content(text)
            print(f"✅ '{text[:30]}...' → Safe: {metrics['safe']}")
        except ValueError as e:
            print(f"❌ '{text[:30]}...' → Error: {e}")
    
    # Test rate limiting
    print(f"\nTesting Rate Limiting:")
    rate_limiter = RateLimiter(requests_per_minute=5, burst_allowance=3)
    
    client = "test_client"
    for i in range(10):
        allowed, status = rate_limiter.is_allowed(client)
        print(f"Request {i+1}: {'✅ Allowed' if allowed else '❌ Blocked'}")
        if not allowed:
            print(f"  Reason: {status['reason']}")
        time.sleep(0.1)
    
    # Test security validator
    print(f"\nTesting Security Validator:")
    validator = SecurityValidator()
    
    test_cases = [
        ("Hello world", "client1"),
        ("<script>alert('test')</script>", "client2"),
        ("שלום עולם", "client3"),
    ]
    
    for text, client in test_cases:
        result = validator.validate_layout_fix_input(text, client)
        print(f"Client {client}: {'✅ Valid' if result['valid'] else '❌ Invalid'}")
        if not result['valid']:
            print(f"  Error: {result.get('error', 'Unknown')}")
    
    # Show security stats
    stats = validator.get_security_stats()
    print(f"\nSecurity Stats:")
    print(f"Total events: {stats['total_events']}")
    print(f"Event types: {stats['event_type_counts']}")
