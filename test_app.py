import pytest
import json
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_hello_endpoint(client):
    """Test the main hello endpoint"""
    response = client.get('/')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'message' in data
    assert 'Lab #3 CI/CD' in data['message']
    assert 'status' in data
    assert data['status'] == 'running'

def test_health_endpoint(client):
    """Test the health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'healthy'

def test_info_endpoint(client):
    """Test the info endpoint"""
    response = client.get('/api/info')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'app' in data
    assert 'endpoints' in data
    assert isinstance(data['endpoints'], list)
    assert len(data['endpoints']) >= 3

def test_not_found(client):
    """Test 404 error handling"""
    response = client.get('/nonexistent')
    assert response.status_code == 404

def test_content_type(client):
    """Test that responses are JSON"""
    response = client.get('/')
    assert response.content_type == 'application/json'
