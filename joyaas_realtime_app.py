#!/usr/bin/env python3
"""
joyaas_realtime_app.py - Enhanced JoyaaS with Real-time Processing
Cross-platform Hebrew/English text processing SaaS with WebSocket support
"""

import asyncio
import os
import sys
import logging
import threading
from pathlib import Path
from datetime import datetime
from flask import Flask, render_template, request, jsonify, session, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from werkzeug.security import generate_password_hash, check_password_hash
import uvicorn
from concurrent.futures import ThreadPoolExecutor

# Add the Scripts directory to the Python path
scripts_dir = Path(__file__).parent
sys.path.insert(0, str(scripts_dir))

# Import shared algorithms and real-time processing
from shared import (
    LayoutFixer,
    RealTimeAPI,
    TextProcessingRequest,
    run_realtime_server,
    create_realtime_api
)

# Import original app components
from joyaas_app import (
    User, ProcessingHistory, TextProcessor,
    app as flask_app, db, login_manager, text_processor
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(name)s %(message)s',
    handlers=[
        logging.FileHandler('joyaas_realtime.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class EnhancedTextProcessor(TextProcessor):
    """Enhanced text processor with real-time capabilities"""
    
    def __init__(self):
        super().__init__()
        self.layout_fixer = LayoutFixer()
        
    async def async_process_text(self, text: str, operations: list, user_id: str = None):
        """Process text asynchronously for real-time processing"""
        results = {}
        
        for operation in operations:
            try:
                if operation == 'fix_layout':
                    results[operation] = self.fix_layout(text)
                elif operation == 'clean_text':
                    results[operation] = self.clean_text(text)
                elif operation == 'hebrew_nikud':
                    results[operation] = await self.async_add_hebrew_nikud(text)
                elif operation == 'correct_text':
                    results[operation] = await self.async_correct_text(text)
                elif operation == 'translate':
                    results[operation] = await self.async_translate_text(text)
                else:
                    results[operation] = text
                    
            except Exception as e:
                logger.error(f"Error in {operation}: {e}")
                results[operation] = text
                
        return results
        
    async def async_add_hebrew_nikud(self, text):
        """Async version of Hebrew nikud addition"""
        # Run the sync version in a thread pool
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            return await loop.run_in_executor(executor, self.add_hebrew_nikud, text)
            
    async def async_correct_text(self, text):
        """Async version of text correction"""
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            return await loop.run_in_executor(executor, self.correct_text, text)
            
    async def async_translate_text(self, text):
        """Async version of text translation"""
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            return await loop.run_in_executor(executor, self.translate_text, text)

class JoyaaSRealTimeApp:
    """Main application class combining Flask and real-time processing"""
    
    def __init__(self):
        self.flask_app = flask_app
        self.enhanced_processor = EnhancedTextProcessor()
        self.realtime_api = None
        self.realtime_server_thread = None
        
    async def initialize_realtime_api(self):
        """Initialize the real-time API with enhanced processor"""
        self.realtime_api = await create_realtime_api(self.enhanced_processor)
        
    def setup_enhanced_routes(self):
        """Add enhanced routes with real-time support"""
        
        @self.flask_app.route('/realtime')
        @login_required
        def realtime_dashboard():
            """Real-time processing dashboard"""
            return render_template('realtime_dashboard.html', 
                                 user_id=current_user.id,
                                 api_key=current_user.api_key)
        
        @self.flask_app.route('/api/realtime/status')
        @login_required
        def realtime_status():
            """Get real-time processing status"""
            if self.realtime_api:
                metrics = self.realtime_api.processor.get_metrics()
                connections = self.realtime_api.processor.get_connection_info()
                
                return jsonify({
                    'status': 'active',
                    'metrics': metrics,
                    'connections': connections['active_connections'],
                    'websocket_url': f'ws://localhost:8001/ws/{current_user.id}'
                })
            else:
                return jsonify({'status': 'inactive'})
                
        @self.flask_app.route('/api/process/async', methods=['POST'])
        @login_required
        async def async_process():
            """Async processing endpoint"""
            if not current_user.can_process():
                return jsonify({
                    'error': 'Usage limit exceeded',
                    'usage_limit': current_user.USAGE_LIMITS.get(current_user.subscription_tier, 100)
                }), 429
            
            data = request.get_json()
            text = data.get('text', '')
            operations = data.get('operations', ['fix_layout'])
            
            if not text:
                return jsonify({'error': 'Missing text'}), 400
            
            try:
                start_time = datetime.utcnow()
                
                # Process with enhanced async processor
                results = await self.enhanced_processor.async_process_text(
                    text, operations, current_user.id
                )
                
                processing_time = (datetime.utcnow() - start_time).total_seconds()
                
                # Save to history for the primary operation
                primary_operation = operations[0] if operations else 'fix_layout'
                primary_result = results.get(primary_operation, text)
                
                history = ProcessingHistory(
                    user_id=current_user.id,
                    operation_type=primary_operation,
                    input_text=text[:1000],
                    output_text=primary_result[:1000],
                    language_detected=self.enhanced_processor.detect_language(text),
                    processing_time=processing_time
                )
                db.session.add(history)
                
                # Update user usage
                current_user.increment_usage()
                
                return jsonify({
                    'success': True,
                    'results': results,
                    'processing_time': processing_time,
                    'language_detected': self.enhanced_processor.detect_language(text),
                    'remaining_usage': current_user.USAGE_LIMITS.get(current_user.subscription_tier, 100) - current_user.monthly_usage
                })
                
            except Exception as e:
                logger.error(f"Async processing error: {e}")
                return jsonify({'error': str(e)}), 500
        
        @self.flask_app.route('/api/stream/start', methods=['POST'])
        @login_required
        def start_stream():
            """Start a text processing stream"""
            data = request.get_json()
            stream_id = data.get('stream_id', f'stream_{current_user.id}_{datetime.utcnow().timestamp()}')
            
            return jsonify({
                'success': True,
                'stream_id': stream_id,
                'websocket_url': f'ws://localhost:8001/ws/{current_user.id}',
                'message': 'Connect to WebSocket and send stream_text messages'
            })
        
    def run_realtime_server_background(self):
        """Run the real-time server in background"""
        def run_server():
            try:
                logger.info("Starting real-time WebSocket server on port 8001...")
                run_realtime_server(
                    text_processor=self.enhanced_processor,
                    host="0.0.0.0",
                    port=8001,
                    debug=False
                )
            except Exception as e:
                logger.error(f"Real-time server error: {e}")
        
        self.realtime_server_thread = threading.Thread(target=run_server, daemon=True)
        self.realtime_server_thread.start()
        
    def run(self, host='0.0.0.0', port=5000, debug=False):
        """Run the complete application"""
        logger.info("Initializing JoyaaS Real-time Application...")
        
        # Set up enhanced routes
        self.setup_enhanced_routes()
        
        # Start real-time server in background
        self.run_realtime_server_background()
        
        # Initialize database
        with self.flask_app.app_context():
            db.create_all()
            logger.info("Database initialized")
        
        logger.info(f"Starting Flask app on {host}:{port}")
        logger.info(f"Real-time WebSocket server running on port 8001")
        logger.info("Application ready for requests!")
        
        # Run Flask app
        self.flask_app.run(host=host, port=port, debug=debug, threaded=True)

# Create real-time dashboard template
REALTIME_DASHBOARD_TEMPLATE = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JoyaaS Real-time Processing</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .message-log {
            height: 300px;
            overflow-y: auto;
            background-color: #f8f9fa;
            border: 1px solid #dee2e6;
            padding: 10px;
            font-family: monospace;
            font-size: 0.9em;
        }
        .status-indicator {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 8px;
        }
        .status-connected { background-color: #28a745; }
        .status-disconnected { background-color: #dc3545; }
        .status-connecting { background-color: #ffc107; }
    </style>
</head>
<body>
    <div class="container mt-4">
        <div class="row">
            <div class="col-md-12">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h2>JoyaaS Real-time Processing</h2>
                    <div>
                        <span class="status-indicator" id="status-indicator"></span>
                        <span id="connection-status">Connecting...</span>
                    </div>
                </div>
                
                <div class="row">
                    <div class="col-md-8">
                        <div class="card mb-4">
                            <div class="card-header">
                                <h5>Text Processing</h5>
                            </div>
                            <div class="card-body">
                                <div class="mb-3">
                                    <label for="text-input" class="form-label">Text to Process:</label>
                                    <textarea class="form-control" id="text-input" rows="4" 
                                            placeholder="Type or paste text here for real-time processing..."></textarea>
                                </div>
                                
                                <div class="mb-3">
                                    <label class="form-label">Operations:</label>
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" id="fix-layout" checked>
                                        <label class="form-check-label" for="fix-layout">Fix Keyboard Layout</label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" id="clean-text">
                                        <label class="form-check-label" for="clean-text">Clean Text</label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" id="hebrew-nikud">
                                        <label class="form-check-label" for="hebrew-nikud">Add Hebrew Nikud</label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" id="correct-text">
                                        <label class="form-check-label" for="correct-text">Correct Grammar</label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" id="translate">
                                        <label class="form-check-label" for="translate">Translate</label>
                                    </div>
                                </div>
                                
                                <div class="d-flex gap-2">
                                    <button class="btn btn-primary" onclick="processText()">Process Now</button>
                                    <button class="btn btn-secondary" onclick="toggleAutoProcess()" id="auto-process-btn">
                                        Enable Auto-Process
                                    </button>
                                </div>
                            </div>
                        </div>
                        
                        <div class="card">
                            <div class="card-header">
                                <h5>Results</h5>
                            </div>
                            <div class="card-body">
                                <div id="results-container">
                                    <p class="text-muted">Results will appear here...</p>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-4">
                        <div class="card mb-4">
                            <div class="card-header">
                                <h6>Connection Info</h6>
                            </div>
                            <div class="card-body">
                                <p><strong>User ID:</strong> {{ user_id }}</p>
                                <p><strong>WebSocket:</strong> <span id="ws-url">Not connected</span></p>
                                <p><strong>Requests:</strong> <span id="request-count">0</span></p>
                            </div>
                        </div>
                        
                        <div class="card">
                            <div class="card-header">
                                <h6>Message Log</h6>
                                <button class="btn btn-sm btn-outline-secondary float-end" onclick="clearLog()">Clear</button>
                            </div>
                            <div class="card-body p-0">
                                <div class="message-log" id="message-log"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        let ws = null;
        let autoProcess = false;
        let requestCount = 0;
        let autoProcessTimeout = null;
        
        const userId = '{{ user_id }}';
        const wsUrl = `ws://localhost:8001/ws/${userId}`;
        
        function log(message) {
            const logDiv = document.getElementById('message-log');
            const timestamp = new Date().toLocaleTimeString();
            logDiv.innerHTML += `<div>[${timestamp}] ${message}</div>`;
            logDiv.scrollTop = logDiv.scrollHeight;
        }
        
        function updateStatus(status) {
            const indicator = document.getElementById('status-indicator');
            const statusText = document.getElementById('connection-status');
            
            indicator.className = 'status-indicator';
            
            switch(status) {
                case 'connected':
                    indicator.classList.add('status-connected');
                    statusText.textContent = 'Connected';
                    break;
                case 'connecting':
                    indicator.classList.add('status-connecting');
                    statusText.textContent = 'Connecting...';
                    break;
                case 'disconnected':
                    indicator.classList.add('status-disconnected');
                    statusText.textContent = 'Disconnected';
                    break;
            }
        }
        
        function connectWebSocket() {
            updateStatus('connecting');
            log('Connecting to WebSocket...');
            
            ws = new WebSocket(wsUrl);
            
            ws.onopen = function() {
                updateStatus('connected');
                log('Connected to real-time processing server');
                document.getElementById('ws-url').textContent = wsUrl;
            };
            
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                log(`Received: ${data.type}`);
                
                if (data.type === 'processing_result') {
                    displayResults(data.data);
                } else if (data.type === 'welcome') {
                    log('Welcome message received');
                } else if (data.type === 'error') {
                    log(`Error: ${data.message}`);
                }
            };
            
            ws.onclose = function() {
                updateStatus('disconnected');
                log('WebSocket connection closed');
                
                // Attempt to reconnect after 3 seconds
                setTimeout(connectWebSocket, 3000);
            };
            
            ws.onerror = function(error) {
                log(`WebSocket error: ${error}`);
            };
        }
        
        function getSelectedOperations() {
            const operations = [];
            if (document.getElementById('fix-layout').checked) operations.push('fix_layout');
            if (document.getElementById('clean-text').checked) operations.push('clean_text');
            if (document.getElementById('hebrew-nikud').checked) operations.push('hebrew_nikud');
            if (document.getElementById('correct-text').checked) operations.push('correct_text');
            if (document.getElementById('translate').checked) operations.push('translate');
            return operations;
        }
        
        function processText() {
            const text = document.getElementById('text-input').value;
            const operations = getSelectedOperations();
            
            if (!text.trim()) {
                alert('Please enter some text to process');
                return;
            }
            
            if (!ws || ws.readyState !== WebSocket.OPEN) {
                alert('WebSocket not connected. Please wait for connection.');
                return;
            }
            
            const message = {
                type: 'process_text',
                data: {
                    text: text,
                    operations: operations,
                    user_id: userId,
                    use_debounce: autoProcess
                }
            };
            
            ws.send(JSON.stringify(message));
            requestCount++;
            document.getElementById('request-count').textContent = requestCount;
            
            log(`Processing text: "${text.substring(0, 50)}${text.length > 50 ? '...' : ''}"`);
        }
        
        function displayResults(result) {
            const container = document.getElementById('results-container');
            const timestamp = new Date().toLocaleTimeString();
            
            let html = `<div class="border rounded p-3 mb-3">`;
            html += `<div class="d-flex justify-content-between mb-2">`;
            html += `<strong>Processing Result</strong>`;
            html += `<small class="text-muted">${timestamp}</small>`;
            html += `</div>`;
            
            html += `<div class="mb-2"><strong>Original:</strong> ${result.original_text}</div>`;
            html += `<div class="mb-2"><strong>Processed:</strong> ${result.processed_text}</div>`;
            html += `<div class="mb-2"><strong>Operations:</strong> ${result.operations_applied.join(', ')}</div>`;
            html += `<div class="small text-muted">`;
            html += `Processing time: ${result.processing_time_ms.toFixed(2)}ms | `;
            html += `Confidence: ${(result.confidence_score * 100).toFixed(1)}%`;
            html += `</div>`;
            html += `</div>`;
            
            container.innerHTML = html + container.innerHTML;
        }
        
        function toggleAutoProcess() {
            autoProcess = !autoProcess;
            const btn = document.getElementById('auto-process-btn');
            
            if (autoProcess) {
                btn.textContent = 'Disable Auto-Process';
                btn.className = 'btn btn-warning';
                setupAutoProcess();
                log('Auto-processing enabled');
            } else {
                btn.textContent = 'Enable Auto-Process';
                btn.className = 'btn btn-secondary';
                if (autoProcessTimeout) {
                    clearTimeout(autoProcessTimeout);
                }
                log('Auto-processing disabled');
            }
        }
        
        function setupAutoProcess() {
            const textInput = document.getElementById('text-input');
            
            textInput.addEventListener('input', function() {
                if (!autoProcess) return;
                
                if (autoProcessTimeout) {
                    clearTimeout(autoProcessTimeout);
                }
                
                autoProcessTimeout = setTimeout(processText, 1000); // 1 second debounce
            });
        }
        
        function clearLog() {
            document.getElementById('message-log').innerHTML = '';
        }
        
        // Initialize connection on page load
        document.addEventListener('DOMContentLoaded', function() {
            connectWebSocket();
        });
    </script>
</body>
</html>
'''

def create_realtime_dashboard_template():
    """Create the real-time dashboard template file"""
    template_dir = Path(__file__).parent / 'templates'
    template_dir.mkdir(exist_ok=True)
    
    template_path = template_dir / 'realtime_dashboard.html'
    with open(template_path, 'w', encoding='utf-8') as f:
        f.write(REALTIME_DASHBOARD_TEMPLATE)
    
    logger.info(f"Created real-time dashboard template: {template_path}")

def main():
    """Main entry point"""
    # Create template files
    create_realtime_dashboard_template()
    
    # Initialize and run the app
    app = JoyaaSRealTimeApp()
    
    # Get configuration from environment
    host = os.environ.get('HOST', '0.0.0.0')
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('DEBUG', 'False').lower() == 'true'
    
    logger.info("="*60)
    logger.info("JoyaaS Real-time Processing Server")
    logger.info("="*60)
    logger.info(f"🚀 Starting application...")
    logger.info(f"📍 Flask server: http://{host}:{port}")
    logger.info(f"🔌 WebSocket server: ws://{host}:8001")
    logger.info(f"🎯 Real-time dashboard: http://{host}:{port}/realtime")
    logger.info("="*60)
    
    app.run(host=host, port=port, debug=debug)

if __name__ == "__main__":
    main()
