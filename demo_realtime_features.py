#!/usr/bin/env python3
"""
Real-time Processing Pipeline Demo
Showcases WebSocket functionality, debounced processing, and streaming capabilities
"""

import sys
import os
import asyncio
import json
import time
import threading
from pathlib import Path
from typing import List, Dict
import websockets
import requests

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from shared.realtime_processor import RealTimeProcessor, ProcessingRequest
from shared.realtime_api import RealTimeAPI, run_realtime_server, RealTimeClient

class RealTimeDemo:
    """Comprehensive demo of real-time processing features"""
    
    def __init__(self):
        self.server_thread = None
        self.server_running = False
        
    def start_demo_server(self, port=8002):
        """Start the real-time server for demo"""
        def run_server():
            print(f"🚀 Starting real-time demo server on port {port}...")
            try:
                run_realtime_server(
                    text_processor=None,  # Use default processor
                    host="localhost",
                    port=port,
                    debug=False
                )
            except Exception as e:
                print(f"❌ Server error: {e}")
        
        self.server_thread = threading.Thread(target=run_server, daemon=True)
        self.server_thread.start()
        self.server_running = True
        
        # Wait for server to start
        print("⏳ Waiting for server to start...")
        time.sleep(3)
        print("✅ Server started!")
        
    async def demo_basic_processing(self):
        """Demo basic real-time text processing"""
        print("\n" + "="*60)
        print("DEMO 1: Basic Real-time Text Processing")
        print("="*60)
        
        processor = RealTimeProcessor()
        await processor.start()
        
        try:
            # Create mock WebSocket connection
            class MockWebSocket:
                def __init__(self):
                    self.sent_messages = []
                    
                async def send_text(self, text):
                    data = json.loads(text)
                    self.sent_messages.append(data)
                    print(f"📤 WebSocket sent: {data['type']}")
                    
            mock_ws = MockWebSocket()
            await processor.add_connection("demo_conn", mock_ws, "demo_user")
            
            # Test different text processing operations
            test_cases = [
                ("susu", ["fix_layout"], "Hebrew layout mistake"),
                ("Hello    world!!!", ["clean_text"], "Text cleaning"),
                ("test text", ["fix_layout", "clean_text"], "Multiple operations")
            ]
            
            for text, operations, description in test_cases:
                print(f"\n🧪 Testing: {description}")
                print(f"   Input: '{text}'")
                print(f"   Operations: {operations}")
                
                request = ProcessingRequest(
                    request_id=f"demo_{int(time.time())}",
                    text=text,
                    operations=operations,
                    user_id="demo_user"
                )
                
                result = await processor.process_text_request("demo_conn", request, use_debounce=False)
                
                if result:
                    print(f"   ✅ Output: '{result.processed_text}'")
                    print(f"   ⏱️  Time: {result.processing_time_ms:.2f}ms")
                    print(f"   🎯 Confidence: {result.confidence_score:.1%}")
                else:
                    print("   ❌ Processing failed")
                    
        finally:
            await processor.stop()
            
    async def demo_debounced_processing(self):
        """Demo debounced processing to prevent API spam"""
        print("\n" + "="*60)
        print("DEMO 2: Debounced Processing (Anti-Spam)")
        print("="*60)
        
        processor = RealTimeProcessor()
        await processor.start()
        
        try:
            class MockWebSocket:
                async def send_text(self, text): pass
                    
            mock_ws = MockWebSocket()
            await processor.add_connection("debounce_conn", mock_ws, "debounce_user")
            
            # Simulate rapid typing by sending multiple requests quickly
            print("🎮 Simulating rapid typing (like auto-complete)...")
            print("   This would normally cause many API calls, but debouncing prevents spam")
            
            rapid_inputs = ["s", "su", "sus", "susu"]
            
            start_time = time.time()
            tasks = []
            
            for i, text in enumerate(rapid_inputs):
                print(f"   {i+1}. Typing: '{text}'")
                
                request = ProcessingRequest(
                    request_id=f"rapid_{i}",
                    text=text,
                    operations=["fix_layout"],
                    user_id="debounce_user"
                )
                
                # Send with debouncing enabled
                task = processor.process_text_request("debounce_conn", request, use_debounce=True)
                tasks.append(task)
                
                # Small delay to simulate typing
                await asyncio.sleep(0.1)
                
            # Wait for all debounced requests to complete
            results = await asyncio.gather(*tasks, return_exceptions=True)
            end_time = time.time()
            
            successful_results = [r for r in results if not isinstance(r, Exception) and r is not None]
            
            print(f"\n📊 Debouncing Results:")
            print(f"   • Requests sent: {len(rapid_inputs)}")
            print(f"   • Actual processing: {len(successful_results)}")
            print(f"   • Time taken: {(end_time - start_time)*1000:.1f}ms")
            print(f"   • API calls saved: {len(rapid_inputs) - len(successful_results)}")
            print(f"   ✅ Final result: '{successful_results[-1].processed_text if successful_results else 'None'}'")
            
        finally:
            await processor.stop()
            
    async def demo_stream_processing(self):
        """Demo continuous stream processing"""
        print("\n" + "="*60)
        print("DEMO 3: Stream Processing (Continuous Text)")
        print("="*60)
        
        processor = RealTimeProcessor()
        await processor.start()
        
        try:
            class MockWebSocket:
                def __init__(self):
                    self.messages = []
                    
                async def send_text(self, text):
                    data = json.loads(text)
                    if data.get('type') == 'stream_update':
                        self.messages.append(data)
                    
            mock_ws = MockWebSocket()
            await processor.add_connection("stream_conn", mock_ws, "stream_user")
            
            # Simulate continuous text input (like live typing or dictation)
            text_chunks = ["Hello ", "world! ", "This is ", "a stream ", "of continuous ", "text input."]
            
            print("📝 Simulating continuous text input...")
            
            for i, chunk in enumerate(text_chunks):
                print(f"   {i+1}. Adding chunk: '{chunk}'")
                
                await processor.add_stream_text(
                    "stream_conn",
                    "demo_stream",
                    chunk,
                    {"chunk_number": i+1, "timestamp": time.time()}
                )
                
                await asyncio.sleep(0.2)  # Simulate typing speed
                
            # Get the complete stream content
            stream_content = processor.stream_processor.get_stream_content("demo_stream")
            last_3_chunks = processor.stream_processor.get_stream_content("demo_stream", last_n_chunks=3)
            
            print(f"\n📄 Stream Results:")
            print(f"   • Total chunks: {len(text_chunks)}")
            print(f"   • Stream updates sent: {len(mock_ws.messages)}")
            print(f"   • Complete content: '{stream_content}'")
            print(f"   • Last 3 chunks: '{last_3_chunks}'")
            
        finally:
            await processor.stop()
            
    async def demo_websocket_client(self):
        """Demo WebSocket client integration"""
        print("\n" + "="*60)
        print("DEMO 4: WebSocket Client Integration")
        print("="*60)
        
        if not self.server_running:
            print("❌ Demo server not running. Starting it now...")
            self.start_demo_server(8002)
            
        try:
            print("🔌 Connecting to WebSocket server...")
            
            async with websockets.connect("ws://localhost:8002/ws/demo_user") as websocket:
                print("✅ Connected to WebSocket server")
                
                # Send welcome acknowledgment
                welcome_msg = await websocket.recv()
                welcome_data = json.loads(welcome_msg)
                print(f"📨 Received: {welcome_data.get('type', 'unknown')}")
                
                # Test text processing via WebSocket
                test_message = {
                    "type": "process_text",
                    "data": {
                        "text": "susu",
                        "operations": ["fix_layout"],
                        "user_id": "demo_user",
                        "use_debounce": False
                    }
                }
                
                print(f"📤 Sending processing request...")
                await websocket.send(json.dumps(test_message))
                
                # Receive processing result
                result_msg = await websocket.recv()
                result_data = json.loads(result_msg)
                
                if result_data.get('type') == 'processing_result':
                    result = result_data['data']
                    print(f"✅ Processing completed!")
                    print(f"   Original: '{result['original_text']}'")
                    print(f"   Processed: '{result['processed_text']}'")
                    print(f"   Time: {result['processing_time_ms']:.2f}ms")
                else:
                    print(f"❌ Unexpected response: {result_data}")
                    
                # Test metrics request
                metrics_message = {"type": "get_metrics"}
                await websocket.send(json.dumps(metrics_message))
                
                metrics_msg = await websocket.recv()
                metrics_data = json.loads(metrics_msg)
                
                if metrics_data.get('type') == 'metrics':
                    metrics = metrics_data['data']
                    print(f"\n📈 Server Metrics:")
                    print(f"   • Total requests: {metrics.get('total_requests', 0)}")
                    print(f"   • Active connections: {metrics.get('active_connections', 0)}")
                    print(f"   • Average processing time: {metrics.get('average_processing_time', 0):.2f}ms")
                    
        except Exception as e:
            print(f"❌ WebSocket demo failed: {e}")
            print("   Make sure the demo server is running on port 8002")
            
    async def demo_batch_processing(self):
        """Demo high-performance batch processing"""
        print("\n" + "="*60)
        print("DEMO 5: High-Performance Batch Processing")
        print("="*60)
        
        processor = RealTimeProcessor()
        await processor.start()
        
        try:
            class MockWebSocket:
                async def send_text(self, text): pass
                    
            mock_ws = MockWebSocket()
            await processor.add_connection("batch_conn", mock_ws, "batch_user")
            
            # Create a batch of test texts
            test_texts = [
                "susu",  # Hebrew layout
                "Hello   world!!!",  # Needs cleaning
                "shalom",  # English layout for Hebrew
                "test    text   here",  # Multiple spaces
                "another sample text",
            ]
            
            print(f"🚀 Processing {len(test_texts)} texts in parallel...")
            
            start_time = time.time()
            
            # Create all requests
            requests = []
            for i, text in enumerate(test_texts):
                request = ProcessingRequest(
                    request_id=f"batch_{i}",
                    text=text,
                    operations=["fix_layout", "clean_text"],
                    user_id="batch_user"
                )
                requests.append(request)
                
            # Process all concurrently
            tasks = [
                processor.process_text_request("batch_conn", req, use_debounce=False)
                for req in requests
            ]
            
            results = await asyncio.gather(*tasks)
            end_time = time.time()
            
            # Display results
            successful = [r for r in results if r is not None]
            total_time = (end_time - start_time) * 1000
            
            print(f"\n📊 Batch Processing Results:")
            print(f"   • Texts processed: {len(successful)}/{len(test_texts)}")
            print(f"   • Total time: {total_time:.2f}ms")
            print(f"   • Average per text: {total_time/len(successful):.2f}ms")
            print(f"   • Throughput: {len(successful)/(total_time/1000):.1f} texts/second")
            
            print(f"\n📝 Individual Results:")
            for i, (original, result) in enumerate(zip(test_texts, successful)):
                if result:
                    print(f"   {i+1}. '{original}' → '{result.processed_text}'")
                    
        finally:
            await processor.stop()
            
    def demo_performance_comparison(self):
        """Demo performance comparison: sync vs async processing"""
        print("\n" + "="*60)
        print("DEMO 6: Performance Comparison (Sync vs Async)")
        print("="*60)
        
        # This would typically compare with a synchronous processor
        # For demo purposes, we'll show the metrics
        
        async def run_comparison():
            processor = RealTimeProcessor()
            await processor.start()
            
            try:
                class MockWebSocket:
                    async def send_text(self, text): pass
                        
                mock_ws = MockWebSocket()
                await processor.add_connection("perf_conn", mock_ws, "perf_user")
                
                # Sequential processing simulation
                print("🐌 Simulating sequential processing...")
                sequential_start = time.time()
                
                for i in range(10):
                    request = ProcessingRequest(
                        request_id=f"seq_{i}",
                        text="test text",
                        operations=["fix_layout"],
                        user_id="perf_user"
                    )
                    await processor.process_text_request("perf_conn", request, use_debounce=False)
                    
                sequential_time = (time.time() - sequential_start) * 1000
                
                # Concurrent processing simulation
                print("🚀 Simulating concurrent processing...")
                concurrent_start = time.time()
                
                tasks = []
                for i in range(10):
                    request = ProcessingRequest(
                        request_id=f"conc_{i}",
                        text="test text",
                        operations=["fix_layout"],
                        user_id="perf_user"
                    )
                    task = processor.process_text_request("perf_conn", request, use_debounce=False)
                    tasks.append(task)
                    
                await asyncio.gather(*tasks)
                concurrent_time = (time.time() - concurrent_start) * 1000
                
                # Show comparison
                print(f"\n⚡ Performance Comparison:")
                print(f"   • Sequential: {sequential_time:.2f}ms for 10 requests")
                print(f"   • Concurrent: {concurrent_time:.2f}ms for 10 requests")
                print(f"   • Speedup: {sequential_time/concurrent_time:.1f}x faster")
                print(f"   • Throughput: {10000/concurrent_time:.1f} requests/second")
                
            finally:
                await processor.stop()
                
        asyncio.run(run_comparison())
        
    def show_feature_summary(self):
        """Show summary of implemented features"""
        print("\n" + "="*60)
        print("🎉 REAL-TIME PROCESSING PIPELINE FEATURES")
        print("="*60)
        
        features = [
            ("✅ WebSocket Real-time Communication", "Bidirectional real-time text processing"),
            ("✅ Debounced Processing", "Prevents API spam during rapid typing"),
            ("✅ Stream Processing", "Handles continuous text input streams"),
            ("✅ Connection Management", "Multi-user connection handling with metrics"),
            ("✅ Async Processing Pipeline", "High-performance concurrent processing"),
            ("✅ FastAPI Integration", "Modern async web framework with WebSocket support"),
            ("✅ REST + WebSocket APIs", "Flexible API access methods"),
            ("✅ Auto-reconnection", "Robust client-server connection handling"),
            ("✅ Error Handling", "Comprehensive error handling and recovery"),
            ("✅ Performance Metrics", "Real-time processing statistics"),
            ("✅ Batch Processing", "Efficient bulk text processing"),
            ("✅ Hebrew/English Layout Fixing", "Core text processing functionality"),
            ("✅ Text Cleaning", "Advanced text normalization"),
            ("✅ Caching & Security", "Smart caching and input sanitization")
        ]
        
        for feature, description in features:
            print(f"  {feature}")
            print(f"    {description}")
            
        print(f"\n🚀 Ready for Production Deployment!")
        print(f"📊 Competitive Advantages:")
        print(f"  • Real-time processing with sub-second latency")
        print(f"  • Scalable WebSocket architecture")
        print(f"  • Smart debouncing prevents API abuse")
        print(f"  • High-performance async pipeline")
        print(f"  • Multi-platform compatibility")
        
    async def run_all_demos(self):
        """Run all demo scenarios"""
        print("🎬 JoyaaS Real-time Processing Pipeline - Complete Demo")
        print("=" * 60)
        
        try:
            # Start demo server for WebSocket tests
            self.start_demo_server(8002)
            
            # Run all demos
            await self.demo_basic_processing()
            await self.demo_debounced_processing()
            await self.demo_stream_processing()
            await self.demo_websocket_client()
            await self.demo_batch_processing()
            self.demo_performance_comparison()
            
            # Show feature summary
            self.show_feature_summary()
            
        except KeyboardInterrupt:
            print("\n🛑 Demo interrupted by user")
        except Exception as e:
            print(f"\n❌ Demo error: {e}")
        finally:
            print("\n👋 Demo completed!")

def main():
    """Main entry point for the demo"""
    demo = RealTimeDemo()
    
    try:
        asyncio.run(demo.run_all_demos())
    except KeyboardInterrupt:
        print("\n🛑 Demo interrupted")
    except Exception as e:
        print(f"❌ Demo failed: {e}")

if __name__ == "__main__":
    main()
