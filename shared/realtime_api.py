"""
FastAPI WebSocket Integration for JoyaaS Real-time Processing
Provides WebSocket endpoints and REST API integration with the real-time processor.
"""

import asyncio
import json
import uuid
import logging
from typing import Dict, List, Optional, Any
from datetime import datetime
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Depends, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import uvicorn

from .realtime_processor import RealTimeProcessor, ProcessingRequest, ProcessingResult

logger = logging.getLogger(__name__)

# Pydantic models for API requests/responses
class TextProcessingRequest(BaseModel):
    text: str = Field(..., description="Text to process")
    operations: List[str] = Field(default=["fix_layout"], description="List of operations to perform")
    user_id: Optional[str] = Field(None, description="User ID for tracking")
    priority: int = Field(1, description="Processing priority (1=high, 2=normal, 3=low)")
    use_debounce: bool = Field(True, description="Whether to use debounced processing")

class TextProcessingResponse(BaseModel):
    request_id: str
    original_text: str
    processed_text: str
    operations_applied: List[str]
    processing_time_ms: float
    confidence_score: float
    suggestions: List[str]
    timestamp: float

class StreamChunkRequest(BaseModel):
    stream_id: str = Field(..., description="Stream identifier")
    text_chunk: str = Field(..., description="Text chunk to add to stream")
    metadata: Optional[Dict] = Field(None, description="Additional metadata")

class ConnectionInfo(BaseModel):
    connection_id: str
    user_id: Optional[str]
    created_at: float
    last_activity: float
    subscriptions: List[str]

class ProcessingMetrics(BaseModel):
    total_requests: int
    successful_requests: int
    failed_requests: int
    average_processing_time: float
    active_connections: int
    total_connections: int
    uptime_seconds: float

class WebSocketMessage(BaseModel):
    type: str
    data: Optional[Dict] = None
    message: Optional[str] = None
    request_id: Optional[str] = None
    timestamp: float

class RealTimeAPI:
    """FastAPI application with real-time processing capabilities"""
    
    def __init__(self, text_processor=None):
        self.app = FastAPI(
            title="JoyaaS Real-time Processing API",
            description="Real-time text processing with WebSocket support",
            version="1.0.0"
        )
        
        self.processor = RealTimeProcessor(text_processor)
        self.startup_time = datetime.now().timestamp()
        
        # Set up routes
        self._setup_routes()
        
    def _setup_routes(self):
        """Set up FastAPI routes"""
        
        @self.app.on_event("startup")
        async def startup_event():
            await self.processor.start()
            logger.info("Real-time processor started with FastAPI")
            
        @self.app.on_event("shutdown")
        async def shutdown_event():
            await self.processor.stop()
            logger.info("Real-time processor stopped")
            
        # WebSocket endpoint for real-time processing
        @self.app.websocket("/ws/{user_id}")
        async def websocket_endpoint(websocket: WebSocket, user_id: str):
            await self.handle_websocket_connection(websocket, user_id)
            
        # REST API endpoints
        @self.app.post("/api/process", response_model=TextProcessingResponse)
        async def process_text(request: TextProcessingRequest):
            return await self.handle_text_processing(request)
            
        @self.app.post("/api/process/batch")
        async def batch_process_text(requests: List[TextProcessingRequest]):
            return await self.handle_batch_processing(requests)
            
        @self.app.get("/api/metrics", response_model=ProcessingMetrics)
        async def get_metrics():
            return await self.handle_get_metrics()
            
        @self.app.get("/api/connections")
        async def get_connections():
            return await self.handle_get_connections()
            
        @self.app.get("/api/health")
        async def health_check():
            return {"status": "healthy", "timestamp": datetime.now().timestamp()}
            
    async def handle_websocket_connection(self, websocket: WebSocket, user_id: str):
        """Handle WebSocket connections for real-time processing"""
        await websocket.accept()
        
        connection_id = str(uuid.uuid4())
        await self.processor.add_connection(connection_id, websocket, user_id)
        
        try:
            while True:
                # Receive message from client
                data = await websocket.receive_text()
                message = json.loads(data)
                
                await self.handle_websocket_message(connection_id, message)
                
        except WebSocketDisconnect:
            await self.processor.remove_connection(connection_id)
            logger.info(f"WebSocket disconnected: {connection_id}")
        except Exception as e:
            logger.error(f"WebSocket error: {e}")
            await self.processor.remove_connection(connection_id)
            
    async def handle_websocket_message(self, connection_id: str, message: Dict):
        """Handle incoming WebSocket messages"""
        message_type = message.get("type")
        
        if message_type == "process_text":
            # Handle text processing request
            data = message.get("data", {})
            request = ProcessingRequest(
                request_id=str(uuid.uuid4()),
                text=data.get("text", ""),
                operations=data.get("operations", ["fix_layout"]),
                user_id=data.get("user_id"),
                priority=data.get("priority", 1)
            )
            
            use_debounce = data.get("use_debounce", True)
            await self.processor.process_text_request(connection_id, request, use_debounce)
            
        elif message_type == "stream_text":
            # Handle stream processing
            data = message.get("data", {})
            await self.processor.add_stream_text(
                connection_id,
                data.get("stream_id", "default"),
                data.get("text_chunk", ""),
                data.get("metadata")
            )
            
        elif message_type == "get_metrics":
            # Send current metrics
            metrics = self.processor.get_metrics()
            metrics["uptime_seconds"] = datetime.now().timestamp() - self.startup_time
            
            connection = self.processor.connections.get(connection_id)
            if connection:
                await connection.send_message({
                    "type": "metrics",
                    "data": metrics,
                    "timestamp": datetime.now().timestamp()
                })
                
        elif message_type == "subscribe":
            # Handle subscription to specific events
            data = message.get("data", {})
            topics = data.get("topics", [])
            
            connection = self.processor.connections.get(connection_id)
            if connection:
                connection.subscriptions.update(topics)
                await connection.send_message({
                    "type": "subscription_confirmed",
                    "data": {"topics": topics},
                    "timestamp": datetime.now().timestamp()
                })
                
        else:
            # Unknown message type
            connection = self.processor.connections.get(connection_id)
            if connection:
                await connection.send_error(f"Unknown message type: {message_type}")
                
    async def handle_text_processing(self, request: TextProcessingRequest) -> TextProcessingResponse:
        """Handle REST API text processing request"""
        # Create a mock connection for REST API processing
        class MockWebSocket:
            async def send_text(self, text):
                pass  # REST API doesn't need to send back via WebSocket
                
        mock_connection_id = str(uuid.uuid4())
        mock_websocket = MockWebSocket()
        
        await self.processor.add_connection(mock_connection_id, mock_websocket, request.user_id)
        
        try:
            processing_request = ProcessingRequest(
                request_id=str(uuid.uuid4()),
                text=request.text,
                operations=request.operations,
                user_id=request.user_id,
                priority=request.priority
            )
            
            result = await self.processor.process_text_request(
                mock_connection_id, 
                processing_request, 
                request.use_debounce
            )
            
            if result:
                return TextProcessingResponse(
                    request_id=result.request_id,
                    original_text=result.original_text,
                    processed_text=result.processed_text,
                    operations_applied=result.operations_applied,
                    processing_time_ms=result.processing_time_ms,
                    confidence_score=result.confidence_score,
                    suggestions=result.suggestions,
                    timestamp=result.timestamp
                )
            else:
                raise HTTPException(status_code=500, detail="Processing failed")
                
        finally:
            await self.processor.remove_connection(mock_connection_id)
            
    async def handle_batch_processing(self, requests: List[TextProcessingRequest]) -> List[TextProcessingResponse]:
        """Handle batch processing of multiple text requests"""
        if len(requests) > 100:  # Limit batch size
            raise HTTPException(status_code=400, detail="Batch size too large (max 100)")
            
        results = []
        
        # Process all requests concurrently
        async def process_single_request(req):
            try:
                return await self.handle_text_processing(req)
            except Exception as e:
                logger.error(f"Batch processing error: {e}")
                return None
                
        tasks = [process_single_request(req) for req in requests]
        completed_results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Filter out failed results and exceptions
        for result in completed_results:
            if isinstance(result, TextProcessingResponse):
                results.append(result)
                
        return results
        
    async def handle_get_metrics(self) -> ProcessingMetrics:
        """Get current processing metrics"""
        metrics = self.processor.get_metrics()
        metrics["uptime_seconds"] = datetime.now().timestamp() - self.startup_time
        
        return ProcessingMetrics(**metrics)
        
    async def handle_get_connections(self) -> Dict:
        """Get information about active connections"""
        connection_info = self.processor.get_connection_info()
        
        return {
            "active_connections": connection_info["active_connections"],
            "connections": [
                ConnectionInfo(
                    connection_id=conn["id"],
                    user_id=conn["user_id"],
                    created_at=conn["created_at"],
                    last_activity=conn["last_activity"],
                    subscriptions=conn["subscriptions"]
                ).dict()
                for conn in connection_info["connections"]
            ],
            "timestamp": datetime.now().timestamp()
        }
        
    def run(self, host: str = "0.0.0.0", port: int = 8000, debug: bool = False):
        """Run the FastAPI application"""
        uvicorn.run(
            self.app,
            host=host,
            port=port,
            log_level="debug" if debug else "info",
            reload=debug
        )

# Convenience functions for easy integration

async def create_realtime_api(text_processor=None) -> RealTimeAPI:
    """Create and initialize a real-time API instance"""
    api = RealTimeAPI(text_processor)
    return api

def run_realtime_server(text_processor=None, host="0.0.0.0", port=8000, debug=False):
    """Run the real-time processing server"""
    api = RealTimeAPI(text_processor)
    api.run(host=host, port=port, debug=debug)

# Example client code for testing WebSocket
class RealTimeClient:
    """Example client for testing WebSocket functionality"""
    
    def __init__(self, url: str = "ws://localhost:8000/ws/test_user"):
        self.url = url
        self.websocket = None
        
    async def connect(self):
        """Connect to WebSocket server"""
        import websockets
        self.websocket = await websockets.connect(self.url)
        
    async def disconnect(self):
        """Disconnect from WebSocket server"""
        if self.websocket:
            await self.websocket.close()
            
    async def send_text_for_processing(self, text: str, operations: List[str] = None):
        """Send text for processing"""
        if operations is None:
            operations = ["fix_layout"]
            
        message = {
            "type": "process_text",
            "data": {
                "text": text,
                "operations": operations,
                "use_debounce": True
            }
        }
        
        await self.websocket.send(json.dumps(message))
        
    async def receive_message(self):
        """Receive message from server"""
        message = await self.websocket.recv()
        return json.loads(message)
        
    async def get_metrics(self):
        """Request current metrics"""
        message = {"type": "get_metrics"}
        await self.websocket.send(json.dumps(message))
        
# Example usage
async def example_client_usage():
    """Example of how to use the WebSocket client"""
    
    client = RealTimeClient()
    
    try:
        await client.connect()
        print("Connected to WebSocket server")
        
        # Send text for processing
        await client.send_text_for_processing("susu", ["fix_layout"])
        
        # Receive results
        while True:
            try:
                message = await client.receive_message()
                print(f"Received: {message}")
                
                if message.get("type") == "processing_result":
                    print(f"Processed text: {message['data']['processed_text']}")
                    break
                    
            except Exception as e:
                print(f"Error receiving message: {e}")
                break
                
        # Request metrics
        await client.get_metrics()
        metrics_message = await client.receive_message()
        print(f"Metrics: {metrics_message}")
        
    finally:
        await client.disconnect()
        print("Disconnected from WebSocket server")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "server":
        # Run server
        print("Starting real-time processing server...")
        run_realtime_server(debug=True)
    elif len(sys.argv) > 1 and sys.argv[1] == "client":
        # Run client example
        print("Running client example...")
        asyncio.run(example_client_usage())
    else:
        print("Usage:")
        print("  python realtime_api.py server  # Run server")
        print("  python realtime_api.py client  # Run client example")
