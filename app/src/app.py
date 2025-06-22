#!/usr/bin/env python3
"""
Kubernetes Sample Python Application
A Flask application with visitor counter and Prometheus metrics
"""

import os
import time
import redis
from flask import Flask, render_template, jsonify, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Application version information
APP_VERSION = os.getenv('APP_VERSION', 'v1.0.0-dev')
BUILD_DATE = os.getenv('BUILD_DATE', 'unknown')
VCS_REF = os.getenv('VCS_REF', 'unknown')
GITHUB_ACTIONS_RUN_ID = os.getenv('GITHUB_RUN_ID', 'unknown')

app = Flask(__name__)

# Redis configuration
REDIS_HOST = os.getenv('REDIS_HOST', 'redis')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
REDIS_DB = int(os.getenv('REDIS_DB', 0))

# Initialize Redis connection
try:
    redis_client = redis.Redis(
        host=REDIS_HOST,
        port=REDIS_PORT,
        db=REDIS_DB,
        decode_responses=True,
        socket_connect_timeout=5,
        socket_timeout=5
    )
    # Test connection
    redis_client.ping()
    logger.info(f"Connected to Redis at {REDIS_HOST}:{REDIS_PORT}")
except Exception as e:
    logger.error(f"Failed to connect to Redis: {e}")
    redis_client = None

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency')
VISITOR_COUNT = Counter('visitor_count_total', 'Total number of visitors')

@app.route('/')
def home():
    """Home page with visitor counter"""
    start_time = time.time()
    
    try:
        # Increment visitor count
        if redis_client:
            visitor_count = redis_client.incr('visitor_count')
            VISITOR_COUNT.inc()
        else:
            visitor_count = "Redis not available"
        
        # Record metrics
        REQUEST_COUNT.labels(method='GET', endpoint='/', status=200).inc()
        REQUEST_LATENCY.observe(time.time() - start_time)
        
        return render_template('index.html', visitor_count=visitor_count)
    
    except Exception as e:
        logger.error(f"Error in home route: {e}")
        REQUEST_COUNT.labels(method='GET', endpoint='/', status=500).inc()
        return render_template('index.html', visitor_count="Error"), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    start_time = time.time()
    
    health_status = {
        'status': 'healthy',
        'timestamp': time.time(),
        'redis': 'connected' if redis_client and redis_client.ping() else 'disconnected',
        'version': APP_VERSION,
        'build_date': BUILD_DATE,
        'vcs_ref': VCS_REF,
        'github_run_id': GITHUB_ACTIONS_RUN_ID
    }
    
    status_code = 200 if health_status['redis'] == 'connected' else 503
    
    REQUEST_COUNT.labels(method='GET', endpoint='/health', status=status_code).inc()
    REQUEST_LATENCY.observe(time.time() - start_time)
    
    return jsonify(health_status), status_code

@app.route('/version')
def version():
    """Version information endpoint for ArgoCD testing"""
    start_time = time.time()
    
    version_info = {
        'version': APP_VERSION,
        'build_date': BUILD_DATE,
        'vcs_ref': VCS_REF,
        'github_run_id': GITHUB_ACTIONS_RUN_ID,
        'timestamp': time.time(),
        'environment': os.getenv('FLASK_ENV', 'production')
    }
    
    REQUEST_COUNT.labels(method='GET', endpoint='/version', status=200).inc()
    REQUEST_LATENCY.observe(time.time() - start_time)
    
    return jsonify(version_info), 200

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/api/visitors')
def api_visitors():
    """API endpoint to get visitor count"""
    start_time = time.time()
    
    try:
        if redis_client:
            visitor_count = redis_client.get('visitor_count') or 0
        else:
            visitor_count = 0
        
        response = {'visitor_count': int(visitor_count)}
        
        REQUEST_COUNT.labels(method='GET', endpoint='/api/visitors', status=200).inc()
        REQUEST_LATENCY.observe(time.time() - start_time)
        
        return jsonify(response)
    
    except Exception as e:
        logger.error(f"Error in API visitors route: {e}")
        REQUEST_COUNT.labels(method='GET', endpoint='/api/visitors', status=500).inc()
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/reset', methods=['POST'])
def reset_counter():
    """API endpoint to reset visitor counter (for testing)"""
    start_time = time.time()
    
    try:
        if redis_client:
            redis_client.set('visitor_count', 0)
            message = "Visitor counter reset successfully"
        else:
            message = "Redis not available"
        
        REQUEST_COUNT.labels(method='POST', endpoint='/api/reset', status=200).inc()
        REQUEST_LATENCY.observe(time.time() - start_time)
        
        return jsonify({'message': message})
    
    except Exception as e:
        logger.error(f"Error in reset counter route: {e}")
        REQUEST_COUNT.labels(method='POST', endpoint='/api/reset', status=500).inc()
        return jsonify({'error': 'Internal server error'}), 500

@app.errorhandler(404)
def not_found(error):
    """404 error handler"""
    REQUEST_COUNT.labels(method=request.method, endpoint=request.path, status=404).inc()
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    """500 error handler"""
    REQUEST_COUNT.labels(method=request.method, endpoint=request.path, status=500).inc()
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'
    
    logger.info(f"Starting Flask application on port {port}")
    logger.info(f"Application version: {APP_VERSION}")
    logger.info(f"Build date: {BUILD_DATE}")
    logger.info(f"VCS ref: {VCS_REF}")
    logger.info(f"GitHub Run ID: {GITHUB_ACTIONS_RUN_ID}")
    
    app.run(host='0.0.0.0', port=port, debug=debug) 