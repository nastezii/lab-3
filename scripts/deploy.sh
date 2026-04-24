#!/bin/bash

set -e

IMAGE=$1
TAG=$2
TARGET_HOST=${TARGET_HOST:-"target-node"}
TARGET_USER=${TARGET_USER:-"ubuntu"}
SERVICE_NAME="webapp"

if [ -z "$IMAGE" ] || [ -z "$TAG" ]; then
    echo "Usage: $0 <image> <tag>"
    exit 1
fi

echo "Deploying $IMAGE with tag $TAG to $TARGET_HOST"

# Create systemd service file for container management
cat > /tmp/${SERVICE_NAME}.service << EOF
[Unit]
Description=Web Application Container
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker run -d --name ${SERVICE_NAME} -p 80:8000 --restart unless-stopped $IMAGE
ExecStop=/usr/bin/docker stop ${SERVICE_NAME}
ExecStopPost=/usr/bin/docker rm ${SERVICE_NAME}
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Copy and deploy to target node
scp -o StrictHostKeyChecking=no /tmp/${SERVICE_NAME}.service ${TARGET_USER}@${TARGET_HOST}:/tmp/
ssh -o StrictHostKeyChecking=no ${TARGET_USER}@${TARGET_HOST} << 'EOF'
    # Update system packages
    sudo apt update && sudo apt upgrade -y
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
    fi
    
    # Install and configure nginx
    if ! command -v nginx &> /dev/null; then
        sudo apt install -y nginx
    fi
    
    # Configure nginx as reverse proxy
    sudo tee /etc/nginx/sites-available/${SERVICE_NAME} > /dev/null << 'NGINX'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINX
    
    # Enable nginx site
    sudo ln -sf /etc/nginx/sites-available/${SERVICE_NAME} /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo nginx -t && sudo systemctl reload nginx
    
    # Setup systemd service
    sudo mv /tmp/${SERVICE_NAME}.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable ${SERVICE_NAME}
    
    # Pull and start the new container
    sudo docker pull $IMAGE
    sudo systemctl restart ${SERVICE_NAME}
    
    echo "Deployment completed successfully"
EOF

echo "Deployment finished"
