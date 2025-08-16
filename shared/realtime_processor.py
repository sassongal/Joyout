"""
Real-time Processing Pipeline for JoyaaS
Provides WebSocket support, debounced processing, and stream processing capabilities.
"""

import asyncio
import json
import time
import logging
from collections import defaultdict, deque
from dataclasses import dataclass, asdict
from typing import Dict, List, Optional, Callable, Any, Set
from datetime import datetime, timedelta
import weakref
import threading
from functools import wraps

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class ProcessingRequest:
    """Represents a text processing request"""
    request_id: str
    text: str
    operations: List[str]
    user_id: Optional[str] = None
    timestamp: float = None
    priority: int = 1  # 1=high, 2=normal, 3=low
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = time.time()

@dataclass
class ProcessingResult:
    """Represents a processing result"""
    request_id: str
    original_text: str
    processed_text: str
    operations_applied: List[str]
    processing_time_ms: float
    confidence_score: float
    suggestions: List[str] = None
    timestamp: float = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = time.time()
        if self.suggestions is None:
            self.suggestions = []

class DebounceManager:
    """Manages debounced processing to avoid excessive API calls"""
    
    def __init__(self, default_delay: float = 0.5):
        self.default_delay = default_delay
        self.pending_requests: Dict[str, asyncio.Task] = {}
        self.last_request_time: Dict[str, float] = {}
        
    async def debounced_process(self, 
                              key: str, 
                              processor_func: Callable,
                              request: ProcessingRequest,
                              delay: Optional[float] = None) -> ProcessingResult:
        """
        Debounce processing requests to avoid rapid successive calls
        """
        if delay is None:
            delay = self.default_delay
            
        # Cancel any existing pending request for this key
        if key in self.pending_requests:
            self.pending_requests[key].cancel()
            
        # Create new delayed processing task
        async def delayed_process():
            await asyncio.sleep(delay)
            return await processor_func(request)
            
        task = asyncio.create_task(delayed_process())
        self.pending_requests[key] = task
        self.last_request_time[key] = time.time()
        
        try:
            result = await task
            return result
        finally:
            # Clean up completed task
            if key in self.pending_requests:
                del self.pending_requests[key]

class StreamProcessor:
    """Handles stream processing for continuous text analysis"""
    
    def __init__(self, max_buffer_size: int = 1000):
        self.max_buffer_size = max_buffer_size
        self.text_streams: Dict[str, deque] = defaultdict(lambda: deque(maxlen=max_buffer_size))
        self.stream_metadata: Dict[str, Dict] = defaultdict(dict)
        self.processing_callbacks: List[Callable] = []
        
    def add_text_chunk(self, stream_id: str, text_chunk: str, metadata: Dict = None):
        """Add a text chunk to the stream buffer"""
        timestamp = time.time()
        
        # Add to stream buffer
        self.text_streams[stream_id].append({
            'text': text_chunk,
            'timestamp': timestamp,
            'metadata': metadata or {}
        })
        
        # Update stream metadata
        self.stream_metadata[stream_id].update({
            'last_update': timestamp,
            'chunk_count': len(self.text_streams[stream_id]),
            'total_length': sum(len(chunk['text']) for chunk in self.text_streams[stream_id])
        })
        
        # Trigger processing callbacks
        self._trigger_callbacks(stream_id, text_chunk)
        
    def get_stream_content(self, stream_id: str, last_n_chunks: Optional[int] = None) -> str:
        """Get concatenated content from stream"""
        if stream_id not in self.text_streams:
            return ""
            
        chunks = list(self.text_streams[stream_id])
        if last_n_chunks:
            chunks = chunks[-last_n_chunks:]
            
        return ''.join(chunk['text'] for chunk in chunks)
        
    def add_processing_callback(self, callback: Callable):
        """Add callback function for stream processing events"""
        self.processing_callbacks.append(callback)
        
    def _trigger_callbacks(self, stream_id: str, text_chunk: str):
        """Trigger all registered callbacks"""
        for callback in self.processing_callbacks:
            try:
                callback(stream_id, text_chunk, self.stream_metadata[stream_id])
            except Exception as e:
                logger.error(f"Error in stream processing callback: {e}")

class WebSocketConnection:
    """Manages individual WebSocket connections"""
    
    def __init__(self, connection_id: str, websocket, user_id: Optional[str] = None):
        self.connection_id = connection_id
        self.websocket = websocket
        self.user_id = user_id
        self.created_at = time.time()
        self.last_activity = time.time()
        self.is_active = True
        self.subscriptions: Set[str] = set()
        
    async def send_message(self, message: Dict):
        """Send message to WebSocket client"""
        try:
            if self.is_active:
                await self.websocket.send_text(json.dumps(message))
                self.last_activity = time.time()
        except Exception as e:
            logger.error(f"Error sending WebSocket message: {e}")
            self.is_active = False
            
    async def send_processing_result(self, result: ProcessingResult):
        """Send processing result to client"""
        message = {
            'type': 'processing_result',
            'data': asdict(result),
            'timestamp': time.time()
        }
        await self.send_message(message)
        
    async def send_error(self, error_message: str, request_id: Optional[str] = None):
        """Send error message to client"""
        message = {
            'type': 'error',
            'message': error_message,
            'request_id': request_id,
            'timestamp': time.time()
        }
        await self.send_message(message)

class RealTimeProcessor:
    """Main real-time processing pipeline coordinator"""
    
    def __init__(self, text_processor=None):
        self.text_processor = text_processor
        self.connections: Dict[str, WebSocketConnection] = {}
        self.debounce_manager = DebounceManager()
        self.stream_processor = StreamProcessor()
        self.processing_queue = asyncio.Queue()
        self.metrics = {
            'total_requests': 0,
            'successful_requests': 0,
            'failed_requests': 0,
            'average_processing_time': 0.0,
            'active_connections': 0,
            'total_connections': 0
        }
        self.is_running = False
        self._worker_task = None
        
        # Set up stream processing callback
        self.stream_processor.add_processing_callback(self._handle_stream_update)
        
    async def start(self):
        """Start the real-time processor"""
        if not self.is_running:
            self.is_running = True
            self._worker_task = asyncio.create_task(self._process_queue_worker())
            logger.info("Real-time processor started")
            
    async def stop(self):
        """Stop the real-time processor"""
        self.is_running = False
        if self._worker_task:
            self._worker_task.cancel()
            try:
                await self._worker_task
            except asyncio.CancelledError:
                pass
        logger.info("Real-time processor stopped")
        
    async def add_connection(self, connection_id: str, websocket, user_id: Optional[str] = None):
        """Add new WebSocket connection"""
        connection = WebSocketConnection(connection_id, websocket, user_id)
        self.connections[connection_id] = connection
        self.metrics['active_connections'] = len(self.connections)
        self.metrics['total_connections'] += 1
        
        logger.info(f"New WebSocket connection added: {connection_id}")
        
        # Send welcome message
        await connection.send_message({
            'type': 'welcome',
            'connection_id': connection_id,
            'timestamp': time.time()
        })
        
    async def remove_connection(self, connection_id: str):
        """Remove WebSocket connection"""
        if connection_id in self.connections:
            connection = self.connections[connection_id]
            connection.is_active = False
            del self.connections[connection_id]
            self.metrics['active_connections'] = len(self.connections)
            logger.info(f"WebSocket connection removed: {connection_id}")
            
    async def process_text_request(self, 
                                 connection_id: str, 
                                 request: ProcessingRequest,
                                 use_debounce: bool = True) -> Optional[ProcessingResult]:
        """Process text with optional debouncing"""
        if connection_id not in self.connections:
            logger.error(f"Connection not found: {connection_id}")
            return None
            
        connection = self.connections[connection_id]
        
        try:
            # Add to processing queue
            await self.processing_queue.put((connection, request, use_debounce))
            
            if use_debounce:
                # Use debounced processing for rapid requests
                debounce_key = f"{connection_id}:{request.user_id or 'anonymous'}"
                result = await self.debounce_manager.debounced_process(
                    debounce_key,
                    self._process_single_request,
                    request
                )
            else:
                # Process immediately
                result = await self._process_single_request(request)
                
            # Send result to client
            await connection.send_processing_result(result)
            
            # Update metrics
            self.metrics['successful_requests'] += 1
            self._update_average_processing_time(result.processing_time_ms)
            
            return result
            
        except Exception as e:
            logger.error(f"Error processing request: {e}")
            await connection.send_error(str(e), request.request_id)
            self.metrics['failed_requests'] += 1
            return None
            
    async def add_stream_text(self, 
                            connection_id: str, 
                            stream_id: str, 
                            text_chunk: str, 
                            metadata: Dict = None):
        """Add text chunk to stream processing"""
        if connection_id not in self.connections:
            return
            
        # Add to stream processor
        self.stream_processor.add_text_chunk(stream_id, text_chunk, metadata)
        
        # Notify connection about stream update
        connection = self.connections[connection_id]
        await connection.send_message({
            'type': 'stream_update',
            'stream_id': stream_id,
            'chunk_length': len(text_chunk),
            'total_length': self.stream_processor.stream_metadata[stream_id].get('total_length', 0),
            'timestamp': time.time()
        })
        
    async def _process_single_request(self, request: ProcessingRequest) -> ProcessingResult:
        """Process a single text processing request"""
        start_time = time.time()
        
        # Default processor if none provided
        if self.text_processor is None:
            # Simple fallback processing
            processed_text = request.text.strip()
            operations_applied = ['basic_cleanup']
            confidence_score = 0.8
        else:
            # Use provided text processor
            try:
                # This would integrate with the shared layout_fixer and other algorithms
                from .layout_fixer import LayoutFixer
                from .advanced_language_detector import AdvancedLanguageDetector
                
                layout_fixer = LayoutFixer()
                language_detector = AdvancedLanguageDetector()
                
                processed_text = request.text
                operations_applied = []
                
                # Apply requested operations
                for operation in request.operations:
                    if operation == 'fix_layout':
                        processed_text = layout_fixer.fix_layout(processed_text)
                        operations_applied.append('fix_layout')
                    elif operation == 'detect_language':
                        lang_info = language_detector.detect_language(processed_text)
                        # Store language info in metadata
                        operations_applied.append('detect_language')
                
                confidence_score = 0.9  # High confidence for our algorithms
                
            except ImportError as e:
                logger.warning(f"Could not import shared algorithms: {e}")
                processed_text = request.text.strip()
                operations_applied = ['basic_cleanup']
                confidence_score = 0.6
                
        processing_time_ms = (time.time() - start_time) * 1000
        
        result = ProcessingResult(
            request_id=request.request_id,
            original_text=request.text,
            processed_text=processed_text,
            operations_applied=operations_applied,
            processing_time_ms=processing_time_ms,
            confidence_score=confidence_score,
            suggestions=[]
        )
        
        self.metrics['total_requests'] += 1
        
        return result
        
    async def _process_queue_worker(self):
        """Background worker to process queued requests"""
        while self.is_running:
            try:
                # Get next item from queue with timeout
                connection, request, use_debounce = await asyncio.wait_for(
                    self.processing_queue.get(), timeout=1.0
                )
                
                # Process the request (already handled in process_text_request)
                self.processing_queue.task_done()
                
            except asyncio.TimeoutError:
                continue  # Continue checking if still running
            except Exception as e:
                logger.error(f"Error in queue worker: {e}")
                
    def _handle_stream_update(self, stream_id: str, text_chunk: str, metadata: Dict):
        """Handle stream processing updates"""
        # This could trigger additional processing based on stream patterns
        logger.debug(f"Stream update for {stream_id}: {len(text_chunk)} chars")
        
    def _update_average_processing_time(self, processing_time_ms: float):
        """Update running average of processing times"""
        current_avg = self.metrics['average_processing_time']
        total_requests = self.metrics['total_requests']
        
        if total_requests == 1:
            self.metrics['average_processing_time'] = processing_time_ms
        else:
            # Calculate running average
            self.metrics['average_processing_time'] = (
                (current_avg * (total_requests - 1) + processing_time_ms) / total_requests
            )
            
    def get_metrics(self) -> Dict:
        """Get current processing metrics"""
        return self.metrics.copy()
        
    def get_connection_info(self) -> Dict:
        """Get information about active connections"""
        return {
            'active_connections': len(self.connections),
            'connections': [
                {
                    'id': conn_id,
                    'user_id': conn.user_id,
                    'created_at': conn.created_at,
                    'last_activity': conn.last_activity,
                    'subscriptions': list(conn.subscriptions)
                }
                for conn_id, conn in self.connections.items()
                if conn.is_active
            ]
        }

# Convenience decorators for easier integration

def realtime_endpoint(processor: RealTimeProcessor):
    """Decorator to mark endpoints for real-time processing"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Add real-time processing context
            kwargs['realtime_processor'] = processor
            return await func(*args, **kwargs)
        return wrapper
    return decorator

def debounced_processing(delay: float = 0.5):
    """Decorator for debounced processing functions"""
    def decorator(func):
        debounce_manager = DebounceManager(delay)
        
        @wraps(func)
        async def wrapper(key: str, *args, **kwargs):
            async def processor_func(request):
                return await func(request, *args, **kwargs)
            
            # Assume first arg is the request
            request = args[0] if args else kwargs.get('request')
            if request:
                return await debounce_manager.debounced_process(key, processor_func, request)
            else:
                return await func(*args, **kwargs)
                
        return wrapper
    return decorator

# Example usage and testing
async def example_usage():
    """Example of how to use the real-time processor"""
    
    # Create processor
    processor = RealTimeProcessor()
    await processor.start()
    
    # Simulate WebSocket connection (in real implementation, this would be actual WebSocket)
    class MockWebSocket:
        async def send_text(self, text):
            print(f"WebSocket send: {text}")
    
    # Add connection
    mock_ws = MockWebSocket()
    await processor.add_connection("test_conn_1", mock_ws, "user123")
    
    # Create processing request
    request = ProcessingRequest(
        request_id="req_1",
        text="susu",  # Hebrew layout mistake
        operations=["fix_layout"],
        user_id="user123"
    )
    
    # Process request
    result = await processor.process_text_request("test_conn_1", request)
    print(f"Processing result: {result}")
    
    # Test stream processing
    await processor.add_stream_text("test_conn_1", "stream_1", "Hello ", {"context": "greeting"})
    await processor.add_stream_text("test_conn_1", "stream_1", "World!", {"context": "greeting"})
    
    # Get stream content
    content = processor.stream_processor.get_stream_content("stream_1")
    print(f"Stream content: {content}")
    
    # Get metrics
    metrics = processor.get_metrics()
    print(f"Metrics: {metrics}")
    
    # Clean up
    await processor.remove_connection("test_conn_1")
    await processor.stop()

if __name__ == "__main__":
    # Run example
    asyncio.run(example_usage())
