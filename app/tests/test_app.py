import pytest
import json
from unittest.mock import patch, MagicMock
from src.app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_page(client):
    """Test the home page endpoint"""
    with patch('src.app.redis_client') as mock_redis:
        mock_redis.incr.return_value = 42
        response = client.get('/')
        assert response.status_code == 200
        assert b'Total Visitors' in response.data
        assert b'42' in response.data

def test_health_endpoint(client):
    """Test the health check endpoint"""
    with patch('src.app.redis_client') as mock_redis:
        mock_redis.ping.return_value = True
        response = client.get('/health')
        data = json.loads(response.data)
        assert response.status_code == 200
        assert data['status'] == 'healthy'
        assert data['redis'] == 'connected'

def test_health_endpoint_redis_down(client):
    """Test health endpoint when Redis is down"""
    with patch('src.app.redis_client') as mock_redis:
        mock_redis.ping.return_value = False
        response = client.get('/health')
        data = json.loads(response.data)
        assert response.status_code == 503
        assert data['status'] == 'healthy'
        assert data['redis'] == 'disconnected'

def test_metrics_endpoint(client):
    """Test the metrics endpoint"""
    response = client.get('/metrics')
    assert response.status_code == 200
    assert 'http_requests_total' in response.data.decode()

def test_api_visitors(client):
    """Test the API visitors endpoint"""
    with patch('src.app.redis_client') as mock_redis:
        mock_redis.get.return_value = '100'
        response = client.get('/api/visitors')
        data = json.loads(response.data)
        assert response.status_code == 200
        assert data['visitor_count'] == 100

def test_api_reset(client):
    """Test the API reset endpoint"""
    with patch('src.app.redis_client') as mock_redis:
        response = client.post('/api/reset')
        data = json.loads(response.data)
        assert response.status_code == 200
        assert 'reset successfully' in data['message']
        mock_redis.set.assert_called_once_with('visitor_count', 0)

def test_404_error(client):
    """Test 404 error handling"""
    response = client.get('/nonexistent')
    data = json.loads(response.data)
    assert response.status_code == 404
    assert data['error'] == 'Not found'

def test_redis_connection_error(client):
    """Test behavior when Redis connection fails"""
    with patch('src.app.redis_client') as mock_redis:
        mock_redis.incr.side_effect = Exception("Connection failed")
        response = client.get('/')
        assert response.status_code == 500

if __name__ == '__main__':
    pytest.main([__file__]) 