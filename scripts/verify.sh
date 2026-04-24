#!/bin/bash

set -e

TARGET_HOST=${TARGET_HOST:-"target-node"}
TARGET_USER=${TARGET_USER:-"ubuntu"}
SERVICE_NAME="webapp"
MAX_RETRIES=30
RETRY_INTERVAL=10

echo "Starting verification of deployment on $TARGET_HOST"

# Function to check if service is responding
check_service() {
    local url=$1
    local max_retries=$2
    local interval=$3
    
    for ((i=1; i<=max_retries; i++)); do
        if curl -f -s "$url" > /dev/null; then
            echo "Service is responding at $url (attempt $i)"
            return 0
        fi
        echo "Waiting for service... (attempt $i/$max_retries)"
        sleep $interval
    done
    
    echo "Service failed to respond after $max_retries attempts"
    return 1
}

# Verify deployment on target node
ssh -o StrictHostKeyChecking=no ${TARGET_USER}@${TARGET_HOST} << 'EOF'
    echo "=== Verifying Docker container ==="
    
    # Check if container is running
    if docker ps | grep -q webapp; then
        echo "Docker container is running"
        docker ps | grep webapp
    else
        echo "Docker container is not running"
        exit 1
    fi
    
    # Check container logs for errors
    echo "=== Container logs (last 20 lines) ==="
    docker logs --tail 20 webapp
    
    echo "=== Verifying nginx configuration ==="
    
    # Check nginx status
    if systemctl is-active --quiet nginx; then
        echo "Nginx is running"
    else
        echo "Nginx is not running"
        systemctl status nginx
        exit 1
    fi
    
    # Test nginx configuration
    if nginx -t; then
        echo "Nginx configuration is valid"
    else
        echo "Nginx configuration has errors"
        exit 1
    fi
    
    echo "=== Checking systemd service ==="
    
    # Check systemd service status
    if systemctl is-active --quiet webapp; then
        echo "Systemd service is active"
        systemctl status webapp --no-pager
    else
        echo "Systemd service is not active"
        systemctl status webapp --no-pager
        exit 1
    fi
    
    echo "=== Network connectivity tests ==="
    
    # Test local connectivity
    if curl -f -s http://localhost/health > /dev/null; then
        echo "Health endpoint is accessible locally"
    else
        echo "Health endpoint is not accessible locally"
        exit 1
    fi
    
    # Test external connectivity
    if curl -f -s http://localhost/ > /dev/null; then
        echo "Main service is accessible locally"
    else
        echo "Main service is not accessible locally"
        exit 1
    fi
    
    echo "=== Resource usage ==="
    
    # Check resource usage
    echo "Container resource usage:"
    docker stats --no-stream webapp
    
    echo "System resource usage:"
    free -h
    df -h
    
    echo "=== Port availability ==="
    
    # Check if ports are listening
    if netstat -tlnp | grep -q ":80 "; then
        echo "Port 80 is listening"
    else
        echo "Port 80 is not listening"
        exit 1
    fi
    
    if netstat -tlnp | grep -q ":8000 "; then
        echo "Port 8000 is listening"
    else
        echo "Port 8000 is not listening"
        exit 1
    fi
EOF

# Additional verification from runner
echo "=== External connectivity tests from runner ==="

# Test connectivity to target host
if ping -c 3 "$TARGET_HOST" > /dev/null 2>&1; then
    echo "Target host $TARGET_HOST is reachable"
else
    echo "Target host $TARGET_HOST is not reachable"
    exit 1
fi

# Test service availability
if check_service "http://$TARGET_HOST/health" $MAX_RETRIES $RETRY_INTERVAL; then
    echo "Health endpoint is accessible from runner"
else
    echo "Health endpoint is not accessible from runner"
    exit 1
fi

if check_service "http://$TARGET_HOST/" $MAX_RETRIES $RETRY_INTERVAL; then
    echo "Main service is accessible from runner"
else
    echo "Main service is not accessible from runner"
    exit 1
fi

echo "=== Verification completed successfully ==="

# Optional: Additional custom checks can be added here
echo "All verifications passed!"
