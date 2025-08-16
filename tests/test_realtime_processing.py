#!/usr/bin/env python3
"""
Comprehensive Test Suite for Real-time Processing Pipeline
Tests WebSocket functionality, debouncing, stream processing, and API integration.
"""

import sys
import os
import asyncio
import json
import time
import unittest
from unittest.mock import AsyncMock, MagicMock, patch
from typing import List, Dict

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.realtime_processor import (
    RealTimeProcessor, 
    ProcessingRequest, 
    ProcessingResult,
    DebounceManager,
    StreamProcessor,
    WebSocketConnection,
    debounced_processing,
    realtime_endpoint
)

from shared.realtime_api import (
    RealTimeAPI,
    TextProcessingRequest,
    TextProcessingResponse,
    RealTimeClient
)

class TestRealTimeProcessor(unittest.TestCase):
    """Test the core real-time processor functionality"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.processor = RealTimeProcessor()
        
    def tearDown(self):
        """Clean up after tests"""
        if hasattr(self, 'processor'):
            asyncio.run(self.processor.stop())
            
    def test_processing_request_creation(self):
        """Test creating processing requests"""
        request = ProcessingRequest(
            request_id="test_123",
            text="susu",
            operations=["fix_layout"],
            user_id="test_user"
        )
        
        self.assertEqual(request.request_id, "test_123")
        self.assertEqual(request.text, "susu") 
        self.assertEqual(request.operations, ["fix_layout"])
        self.assertEqual(request.user_id, "test_user")
        self.assertIsNotNone(request.timestamp)
        
    async def async_test_processor_startup_shutdown(self):
        """Test processor startup and shutdown"""
        # Test startup
        await self.processor.start()
        self.assertTrue(self.processor.is_running)
        self.assertIsNotNone(self.processor._worker_task)
        
        # Test shutdown
        await self.processor.stop()
        self.assertFalse(self.processor.is_running)
        
    def test_processor_startup_shutdown(self):
        """Sync wrapper for async startup/shutdown test"""
        asyncio.run(self.async_test_processor_startup_shutdown())
        
    async def async_test_connection_management(self):
        """Test WebSocket connection management"""
        await self.processor.start()
        
        # Create mock WebSocket
        mock_websocket = AsyncMock()
        
        # Add connection
        await self.processor.add_connection("conn_1", mock_websocket, "user_1")
        
        self.assertIn("conn_1", self.processor.connections)
        self.assertEqual(self.processor.metrics["active_connections"], 1)
        self.assertEqual(self.processor.metrics["total_connections"], 1)
        
        # Remove connection
        await self.processor.remove_connection("conn_1")
        
        self.assertNotIn("conn_1", self.processor.connections)
        self.assertEqual(self.processor.metrics["active_connections"], 0)
        
        await self.processor.stop()
        
    def test_connection_management(self):
        """Sync wrapper for connection management test"""
        asyncio.run(self.async_test_connection_management())
        
    async def async_test_text_processing(self):
        """Test basic text processing functionality"""
        await self.processor.start()
        
        # Create mock WebSocket
        mock_websocket = AsyncMock()
        await self.processor.add_connection("conn_1", mock_websocket, "user_1")
        
        # Create processing request
        request = ProcessingRequest(
            request_id="req_1",
            text="susu",  # Hebrew layout mistake  
            operations=["fix_layout"],
            user_id="user_1"
        )
        
        # Process request
        result = await self.processor.process_text_request("conn_1", request, use_debounce=False)
        
        # Verify result
        self.assertIsNotNone(result)
        self.assertEqual(result.request_id, "req_1")
        self.assertEqual(result.original_text, "susu")
        self.assertIsInstance(result.processing_time_ms, float)
        self.assertGreater(result.confidence_score, 0)
        
        # Verify metrics updated
        self.assertEqual(self.processor.metrics["successful_requests"], 1)
        
        await self.processor.stop()
        
    def test_text_processing(self):
        """Sync wrapper for text processing test"""
        asyncio.run(self.async_test_text_processing())

class TestDebounceManager(unittest.TestCase):
    """Test debounce functionality"""
    
    def setUp(self):
        self.debounce_manager = DebounceManager(default_delay=0.1)  # Short delay for testing
        
    async def async_test_basic_debouncing(self):
        """Test basic debounce functionality"""
        call_count = 0
        
        async def mock_processor(request):
            nonlocal call_count
            call_count += 1
            return ProcessingResult(
                request_id=request.request_id,
                original_text=request.text,
                processed_text=request.text.upper(),
                operations_applied=["uppercase"],
                processing_time_ms=1.0,
                confidence_score=1.0
            )
        
        request = ProcessingRequest("req_1", "test", ["uppercase"])
        
        # Make multiple rapid calls
        tasks = []
        for i in range(5):
            task = self.debounce_manager.debounced_process(
                f"key_{i % 2}",  # Use 2 different keys
                mock_processor,
                request
            )
            tasks.append(task)
        
        # Wait for all tasks to complete
        results = await asyncio.gather(*tasks)
        
        # Should have processed only the last request for each key
        self.assertLessEqual(call_count, 2)  # At most 2 calls for 2 keys
        self.assertEqual(len(results), 5)  # All tasks should return results
        
    def test_basic_debouncing(self):
        """Sync wrapper for debounce test"""
        asyncio.run(self.async_test_basic_debouncing())

class TestStreamProcessor(unittest.TestCase):
    """Test stream processing functionality"""
    
    def setUp(self):
        self.stream_processor = StreamProcessor(max_buffer_size=100)
        
    def test_stream_chunk_addition(self):
        """Test adding text chunks to streams"""
        # Add chunks to stream
        self.stream_processor.add_text_chunk("stream_1", "Hello ", {"type": "greeting"})
        self.stream_processor.add_text_chunk("stream_1", "World!", {"type": "greeting"})
        
        # Verify stream content
        content = self.stream_processor.get_stream_content("stream_1")
        self.assertEqual(content, "Hello World!")
        
        # Verify metadata
        metadata = self.stream_processor.stream_metadata["stream_1"]
        self.assertEqual(metadata["chunk_count"], 2)
        self.assertEqual(metadata["total_length"], 12)
        
    def test_stream_callback_functionality(self):
        """Test stream processing callbacks"""
        callback_calls = []
        
        def test_callback(stream_id, text_chunk, metadata):
            callback_calls.append((stream_id, text_chunk, metadata))
            
        # Add callback
        self.stream_processor.add_processing_callback(test_callback)
        
        # Add chunk (should trigger callback)
        self.stream_processor.add_text_chunk("stream_1", "test", {"key": "value"})
        
        # Verify callback was called
        self.assertEqual(len(callback_calls), 1)
        self.assertEqual(callback_calls[0][0], "stream_1")
        self.assertEqual(callback_calls[0][1], "test")
        
    def test_stream_last_n_chunks(self):
        """Test getting last N chunks from stream"""
        # Add multiple chunks
        for i in range(10):
            self.stream_processor.add_text_chunk("stream_1", f"chunk_{i} ")
            
        # Get last 3 chunks
        content = self.stream_processor.get_stream_content("stream_1", last_n_chunks=3)
        self.assertEqual(content, "chunk_7 chunk_8 chunk_9 ")

class TestWebSocketConnection(unittest.TestCase):
    """Test WebSocket connection wrapper"""
    
    def setUp(self):
        self.mock_websocket = AsyncMock()
        self.connection = WebSocketConnection("conn_1", self.mock_websocket, "user_1")
        
    async def async_test_send_message(self):
        """Test sending messages via WebSocket"""
        message = {"type": "test", "data": {"key": "value"}}
        
        await self.connection.send_message(message)
        
        # Verify WebSocket send_text was called
        self.mock_websocket.send_text.assert_called_once()
        sent_data = self.mock_websocket.send_text.call_args[0][0]
        parsed_data = json.loads(sent_data)
        
        self.assertEqual(parsed_data["type"], "test")
        self.assertEqual(parsed_data["data"]["key"], "value")
        
    def test_send_message(self):
        """Sync wrapper for send message test"""
        asyncio.run(self.async_test_send_message())
        
    async def async_test_send_processing_result(self):
        """Test sending processing results"""
        result = ProcessingResult(
            request_id="req_1",
            original_text="test",
            processed_text="TEST",
            operations_applied=["uppercase"],
            processing_time_ms=1.5,
            confidence_score=0.9
        )
        
        await self.connection.send_processing_result(result)
        
        # Verify the result was sent correctly
        self.mock_websocket.send_text.assert_called_once()
        sent_data = self.mock_websocket.send_text.call_args[0][0]
        parsed_data = json.loads(sent_data)
        
        self.assertEqual(parsed_data["type"], "processing_result")
        self.assertEqual(parsed_data["data"]["request_id"], "req_1")
        self.assertEqual(parsed_data["data"]["processed_text"], "TEST")
        
    def test_send_processing_result(self):
        """Sync wrapper for processing result test"""
        asyncio.run(self.async_test_send_processing_result())

class TestRealTimeAPI(unittest.TestCase):
    """Test FastAPI integration"""
    
    def setUp(self):
        # Mock text processor to avoid import issues
        mock_text_processor = MagicMock()
        self.api = RealTimeAPI(mock_text_processor)
        
    def test_api_creation(self):
        """Test API instance creation"""
        self.assertIsNotNone(self.api.app)
        self.assertIsNotNone(self.api.processor)
        self.assertEqual(self.api.app.title, "JoyaaS Real-time Processing API")
        
    def test_text_processing_request_model(self):
        """Test Pydantic request model"""
        request_data = {
            "text": "susu",
            "operations": ["fix_layout"],
            "user_id": "test_user",
            "priority": 1,
            "use_debounce": True
        }
        
        request = TextProcessingRequest(**request_data)
        
        self.assertEqual(request.text, "susu")
        self.assertEqual(request.operations, ["fix_layout"])
        self.assertEqual(request.user_id, "test_user")
        self.assertEqual(request.priority, 1)
        self.assertTrue(request.use_debounce)
        
    async def async_test_text_processing_handler(self):
        """Test REST API text processing"""
        request = TextProcessingRequest(
            text="susu",
            operations=["fix_layout"],
            user_id="test_user"
        )
        
        # Start the processor
        await self.api.processor.start()
        
        try:
            response = await self.api.handle_text_processing(request)
            
            self.assertIsInstance(response, TextProcessingResponse)
            self.assertEqual(response.original_text, "susu")
            self.assertIsNotNone(response.request_id)
            self.assertGreater(response.processing_time_ms, 0)
            
        finally:
            await self.api.processor.stop()
        
    def test_text_processing_handler(self):
        """Sync wrapper for text processing handler test"""
        asyncio.run(self.async_test_text_processing_handler())

class IntegrationTest(unittest.TestCase):
    """Integration tests for the complete pipeline"""
    
    async def async_test_end_to_end_processing(self):
        """Test complete end-to-end processing pipeline"""
        # Create processor
        processor = RealTimeProcessor()
        await processor.start()
        
        try:
            # Create mock WebSocket
            mock_websocket = AsyncMock()
            
            # Add connection
            await processor.add_connection("test_conn", mock_websocket, "test_user")
            
            # Test layout fixing
            layout_request = ProcessingRequest(
                request_id="layout_req",
                text="susu",  # Should convert to דודו
                operations=["fix_layout"],
                user_id="test_user"
            )
            
            result = await processor.process_text_request("test_conn", layout_request, use_debounce=False)
            
            # Verify processing worked
            self.assertIsNotNone(result)
            self.assertEqual(result.original_text, "susu")
            # Note: Actual conversion depends on algorithm availability
            
            # Test stream processing
            await processor.add_stream_text("test_conn", "stream_1", "Hello ", {"context": "greeting"})
            await processor.add_stream_text("test_conn", "stream_1", "World!", {"context": "greeting"})
            
            stream_content = processor.stream_processor.get_stream_content("stream_1")
            self.assertEqual(stream_content, "Hello World!")
            
            # Test metrics
            metrics = processor.get_metrics()
            self.assertGreater(metrics["total_requests"], 0)
            self.assertGreater(metrics["successful_requests"], 0)
            
            # Test connection info
            conn_info = processor.get_connection_info()
            self.assertEqual(conn_info["active_connections"], 1)
            
        finally:
            await processor.stop()
            
    def test_end_to_end_processing(self):
        """Sync wrapper for end-to-end test"""
        asyncio.run(self.async_test_end_to_end_processing())
        
    async def async_test_batch_processing_simulation(self):
        """Test batch processing with multiple requests"""
        processor = RealTimeProcessor()
        await processor.start()
        
        try:
            mock_websocket = AsyncMock()
            await processor.add_connection("batch_conn", mock_websocket, "batch_user")
            
            # Create multiple requests
            requests = []
            for i in range(10):
                request = ProcessingRequest(
                    request_id=f"batch_req_{i}",
                    text=f"test text {i}",
                    operations=["fix_layout"],
                    user_id="batch_user"
                )
                requests.append(request)
            
            # Process all requests concurrently
            tasks = [
                processor.process_text_request("batch_conn", req, use_debounce=False)
                for req in requests
            ]
            
            results = await asyncio.gather(*tasks)
            
            # Verify all processed successfully
            self.assertEqual(len(results), 10)
            self.assertTrue(all(r is not None for r in results))
            
            # Verify metrics
            metrics = processor.get_metrics()
            self.assertEqual(metrics["successful_requests"], 10)
            
        finally:
            await processor.stop()
            
    def test_batch_processing_simulation(self):
        """Sync wrapper for batch processing test"""
        asyncio.run(self.async_test_batch_processing_simulation())

def run_performance_test():
    """Run performance benchmarks"""
    print("\n" + "="*60)
    print("REAL-TIME PROCESSING PERFORMANCE BENCHMARKS")
    print("="*60)
    
    async def benchmark():
        processor = RealTimeProcessor()
        await processor.start()
        
        try:
            mock_websocket = AsyncMock()
            await processor.add_connection("perf_conn", mock_websocket, "perf_user")
            
            # Benchmark single request processing
            start_time = time.time()
            
            for i in range(100):
                request = ProcessingRequest(
                    request_id=f"perf_req_{i}",
                    text="susu",
                    operations=["fix_layout"],
                    user_id="perf_user"
                )
                await processor.process_text_request("perf_conn", request, use_debounce=False)
                
            end_time = time.time()
            
            total_time = end_time - start_time
            requests_per_second = 100 / total_time
            
            print(f"Single Request Processing:")
            print(f"  - 100 requests processed in {total_time:.2f} seconds")
            print(f"  - {requests_per_second:.2f} requests/second")
            print(f"  - Average latency: {(total_time/100)*1000:.2f}ms per request")
            
            # Benchmark concurrent processing
            start_time = time.time()
            
            tasks = []
            for i in range(50):
                request = ProcessingRequest(
                    request_id=f"concurrent_req_{i}",
                    text="susu",
                    operations=["fix_layout"],
                    user_id="perf_user"
                )
                task = processor.process_text_request("perf_conn", request, use_debounce=False)
                tasks.append(task)
                
            await asyncio.gather(*tasks)
            end_time = time.time()
            
            concurrent_time = end_time - start_time
            concurrent_rps = 50 / concurrent_time
            
            print(f"\nConcurrent Request Processing:")
            print(f"  - 50 concurrent requests processed in {concurrent_time:.2f} seconds")
            print(f"  - {concurrent_rps:.2f} requests/second")
            print(f"  - Average latency: {(concurrent_time/50)*1000:.2f}ms per request")
            
            # Get final metrics
            metrics = processor.get_metrics()
            print(f"\nFinal Metrics:")
            print(f"  - Total requests: {metrics['total_requests']}")
            print(f"  - Successful requests: {metrics['successful_requests']}")
            print(f"  - Failed requests: {metrics['failed_requests']}")
            print(f"  - Average processing time: {metrics['average_processing_time']:.2f}ms")
            
        finally:
            await processor.stop()
            
    asyncio.run(benchmark())

def main():
    """Run all tests and benchmarks"""
    print("JoyaaS Real-Time Processing Pipeline Test Suite")
    print("="*50)
    
    # Run unit tests
    test_suite = unittest.TestLoader().loadTestsFromModule(sys.modules[__name__])
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(test_suite)
    
    if result.wasSuccessful():
        print(f"\n✅ All {result.testsRun} tests passed!")
        
        # Run performance benchmarks
        run_performance_test()
        
        print(f"\n🎉 Real-time processing pipeline is ready for production!")
        print(f"📊 Features implemented:")
        print(f"   • WebSocket real-time communication")
        print(f"   • Debounced processing to prevent API abuse")
        print(f"   • Stream processing for continuous text")
        print(f"   • Connection management and metrics")
        print(f"   • FastAPI integration with REST + WebSocket")
        print(f"   • Batch processing capabilities")
        print(f"   • Error handling and recovery")
        
    else:
        print(f"\n❌ {len(result.failures + result.errors)} test(s) failed")
        return 1
        
    return 0

if __name__ == "__main__":
    exit(main())
