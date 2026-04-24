#!/bin/bash

set -e

echo "Setting up self-hosted GitHub Actions runner on Ubuntu 24.04"

# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git docker.io jq

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create runner user (optional, for security)
if ! id "runner" &>/dev/null; then
    sudo useradd -m -s /bin/bash runner
    sudo usermod -aG docker runner
fi

# Download and install GitHub Actions runner
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/v//')
RUNNER_ARCH="linux-x64"

echo "Downloading runner version $RUNNER_VERSION"

cd /tmp
wget https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-$RUNNER_ARCH-$RUNNER_VERSION.tar.gz

# Extract and install
sudo mkdir -p /opt/actions-runner
sudo tar -xzf actions-runner-$RUNNER_ARCH-$RUNNER_VERSION.tar.gz -C /opt/actions-runner
sudo chown -R runner:runner /opt/actions-runner

# Install dependencies
cd /opt/actions-runner
sudo ./bin/installdependencies.sh

# Create systemd service for runner
sudo tee /etc/systemd/system/actions-runner.service > /dev/null << EOF
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
Type=simple
User=runner
WorkingDirectory=/opt/actions-runner
ExecStart=/opt/actions-runner/run.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable actions-runner.service

# Setup SSH key for deployment (if needed)
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
    echo "SSH key generated. Add the following public key to your target node's authorized_keys:"
    cat ~/.ssh/id_rsa.pub
fi

# Install additional tools for verification
sudo apt install -y net-tools curl

echo "Runner setup completed!"
echo ""
echo "Next steps:"
echo "1. Configure the runner manually by running:"
echo "   cd /opt/actions-runner"
echo "   sudo -u runner ./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN"
echo "2. Start the runner:"
echo "   sudo systemctl start actions-runner"
echo "3. Check status:"
echo "   sudo systemctl status actions-runner"
echo ""
echo "IMPORTANT: Do not add tokens to this script. Configure manually for security."
echo ""
echo "For deployment, set these environment variables:"
echo "export TARGET_HOST='your-target-node-ip'"
echo "export TARGET_USER='ubuntu'"
