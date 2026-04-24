# Lab #3 - CI/CD Pipeline

This project implements a complete CI/CD pipeline for a Flask web application as part of Lab #3.

## Project Structure

```
.
|-- .github/
|   `-- workflows/
|       |-- ci.yml          # Code analysis and testing
|       |-- build.yml       # Docker image building
|       `-- deploy.yml      # Deployment to target node
|-- scripts/
|   |-- deploy.sh           # Deployment script
|   |-- verify.sh           # Verification script
|   `-- setup-runner.sh     # Self-hosted runner setup
|-- app.py                  # Flask application
|-- test_app.py            # Test suite
|-- requirements.txt       # Python dependencies
|-- Dockerfile            # Container definition
`-- README.md             # This file
```

## CI/CD Pipeline

### 1. Code Analysis & Testing (`.github/workflows/ci.yml`)

**Triggers:**
- Push to main/master branch
- Pull requests to main/master branch

**Tasks:**
- Python code linting with `flake8`
- Type checking with `mypy`
- Unit testing with `pytest`
- Coverage reporting (minimum 40% required)
- Dockerfile linting with `hadolint`

### 2. Docker Image Building (`.github/workflows/build.yml`)

**Triggers:**
- Push to main/master branch
- Annotated tags

**Tasks:**
- Build and push Docker images to GitHub Container Registry
- Tag images as `latest`, `sha-<commit-hash>`, `stable`, and `<tag>`

### 3. Deployment (`.github/workflows/deploy.yml`)

**Triggers:**
- Annotated tags only

**Tasks:**
- Deploy to target node using self-hosted runner
- Run verification tests
- Notify on failure

## Setup Instructions

### 1. Target Node Setup

On your Ubuntu 24.04 target node:

```bash
# Set up environment variables
export TARGET_HOST="target-node-ip"
export TARGET_USER="ubuntu"

# The deployment script will automatically:
# - Install Docker and nginx
# - Configure nginx as reverse proxy
# - Set up systemd service for container management
# - Deploy and start the application
```

### 2. Self-Hosted Runner Setup

1. Create Ubuntu 24.04 VM for the runner
2. Run the setup script:

```bash
chmod +x scripts/setup-runner.sh
./scripts/setup-runner.sh
```

3. Configure the runner manually (for security):
```bash
cd /opt/actions-runner
sudo -u runner ./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN
sudo systemctl start actions-runner
```

4. Set up SSH access to target node:
```bash
# Copy SSH key to target node
ssh-copy-id ubuntu@target-node-ip
```

### 3. GitHub Secrets

Set these secrets in your GitHub repository:

- `TARGET_HOST`: IP address of target node
- `TARGET_USER`: Username for target node (default: ubuntu)

## Application Endpoints

- `/` - Main application endpoint
- `/health` - Health check endpoint
- `/api/info` - Application information

## Testing

Run tests locally:

```bash
# Install dependencies
pip install -r requirements.txt

# Run tests with coverage
pytest --cov=. --cov-report=html

# Run linting
flake8 .
mypy .
```

## Deployment Process

1. **Code Analysis**: Linting and type checking
2. **Testing**: Unit tests with 40%+ coverage requirement
3. **Build**: Create Docker image
4. **Deploy**: Deploy to target node on tagged releases
5. **Verify**: Health checks and service validation

## Verification

The verification script checks:
- Docker container status
- Nginx configuration and status
- Systemd service status
- Network connectivity
- Resource usage
- Service availability from external access

## Security Notes

- No sensitive tokens stored in scripts
- Manual runner configuration required
- SSH key-based authentication for deployment
- Non-root Docker user in containers

## Demonstration Requirements

The repository demonstrates:
- Successful PR merge after all checks pass
- Blocked PR merge due to failed tests/analysis
- Successful deployment and verification logs
- Coverage reports as artifacts

## Cleanup

After completing the lab:
```bash
# Stop and remove runner VM
# Clean up any temporary resources
# Remove sensitive data from logs
```
