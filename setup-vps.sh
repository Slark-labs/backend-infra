#!/bin/bash

# 🚀 Automated VPS Setup Script for Backend Infrastructure
# This script sets up everything automatically - just run it!

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
   log_warning "⚠️  WARNING: You're running as root!"
   log_info "While possible, it's NOT recommended to run this script as root."
   log_info ""
   log_info "🔍 WHY NOT ROOT:"
   log_info "• Security risk - scripts running as root can damage your system"
   log_info "• Principle of least privilege - use regular user when possible"
   log_info "• Docker will be configured for your user account"
   log_info ""
   log_info "✅ RECOMMENDED: Run as regular user with sudo when needed"
   log_info "Example: ssh youruser@your-vps, then run the script"
   log_info ""
   read -p "Do you want to continue anyway? (y/N): " -r
   if [[ ! $REPLY =~ ^[Yy]$ ]]; then
       log_info "Exiting... Please run as regular user."
       exit 1
   fi
   log_warning "Continuing as root... Use at your own risk!"
fi

# Check if we're running via curl pipe (common issue)
if [[ -z "$0" || "$0" == "bash" ]] && [[ -n "$BASH_SOURCE" ]]; then
    log_info "Detected script running via curl pipe - this is fine!"
    log_info "Continuing with setup..."
fi

echo ""
echo "🚀 Starting AUTOMATED VPS setup for backend infrastructure..."
echo "═══════════════════════════════════════════════════════════════"

# Function to generate secure password
generate_password() {
    openssl rand -base64 32
}

# Function to generate JWT secret
generate_jwt_secret() {
    openssl rand -hex 32
}

# Step 1: Update system
log_info "Step 1: Updating system packages..."
sudo apt update && sudo apt upgrade -y
log_success "System packages updated"

# Step 2: Install Docker with conflict resolution
log_info "Step 2: Installing Docker (handling conflicts)..."

# Remove any conflicting packages
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Clean up
sudo apt autoremove -y 2>/dev/null || true
sudo apt autoclean

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update

# Install Docker Engine and plugins
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install additional packages
sudo apt install -y curl wget git jq

log_success "Docker installed successfully"

# Step 3: Start and configure Docker
log_info "Step 3: Configuring Docker..."

sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER

log_success "Docker configured and started"

# Step 4: Create directories
log_info "Step 4: Creating required directories..."

sudo mkdir -p /opt/backend-infra
sudo mkdir -p /opt/infra/env

sudo chown -R $USER:$USER /opt/backend-infra
sudo chown -R $USER:$USER /opt/infra/env
sudo chmod 700 /opt/infra/env

log_success "Directories created with proper permissions"

# Step 5: Generate secure passwords
log_info "Step 5: Generating secure passwords..."

DB_PASSWORD=$(generate_password)
JWT_SECRET=$(generate_jwt_secret)

log_success "Secure passwords generated"

# Step 6: Create environment files
log_info "Step 6: Creating environment files..."

# Database environment
cat > /opt/infra/env/database.env << EOF
POSTGRES_PASSWORD=$DB_PASSWORD
EOF

# Application template
cat > /opt/infra/env/your-app-backend.env << EOF
PORT=3000
NODE_ENV=production
DATABASE_URL=postgres://postgres:$DB_PASSWORD@postgres:5432/app_database
REDIS_URL=redis://redis:6379
JWT_SECRET=$JWT_SECRET
EOF

# Set proper permissions
sudo chmod 600 /opt/infra/env/*.env

log_success "Environment files created"

# Step 7: Clone repository (if URL provided)
if [ -n "$1" ]; then
    log_info "Step 7: Cloning repository from $1..."
    git clone "$1" /opt/backend-infra
    log_success "Repository cloned"
else
    log_warning "Step 7: No repository URL provided"
    log_info "To clone your repository manually:"
    log_info "  git clone https://github.com/yourusername/backend-infra.git /opt/backend-infra"
    echo ""
fi

# Step 8: Final setup verification
log_info "Step 8: Verifying setup..."

# Test Docker
if docker --version > /dev/null 2>&1; then
    log_success "Docker is working"
else
    log_error "Docker is not working properly"
fi

# Test Docker Compose
if docker compose version > /dev/null 2>&1; then
    log_success "Docker Compose is working"
else
    log_error "Docker Compose is not working properly"
fi

# Check directories exist
if [ -d "/opt/infra/env" ] && [ -d "/opt/backend-infra" ]; then
    log_success "Directories exist"
else
    log_error "Directories were not created properly"
fi

# Check env files exist
if [ -f "/opt/infra/env/database.env" ] && [ -f "/opt/infra/env/your-app-backend.env" ]; then
    log_success "Environment files exist"
else
    log_error "Environment files were not created properly"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
log_success "🎉 VPS SETUP COMPLETED SUCCESSFULLY!"
echo ""
echo "📋 IMPORTANT INFORMATION:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔑 GENERATED CREDENTIALS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PostgreSQL Password: $DB_PASSWORD"
echo "JWT Secret:          $JWT_SECRET"
echo ""
echo "💾 SAVE THESE CREDENTIALS SECURELY!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "• Store them in a password manager"
echo "• You'll need them for GitHub Actions secrets"
echo "• Keep them safe - they secure your production data"
echo ""

if [ -z "$1" ]; then
    echo "📥 NEXT STEPS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Clone your backend-infra repository:"
    echo "   git clone https://github.com/yourusername/backend-infra.git /opt/backend-infra"
    echo ""
fi

echo "2. Start the infrastructure:"
echo "   cd /opt/backend-infra && docker compose up -d"
echo ""

echo "3. Add GitHub Secrets (to ALL repositories):"
echo "   DOCKER_USERNAME=your_dockerhub_username"
echo "   DOCKER_PASSWORD=your_dockerhub_password"
echo "   VPS_IP=your_vps_ip_address"
echo "   VPS_USERNAME=root"
echo "   VPS_SSH_KEY=your_private_ssh_key"
echo ""

echo "4. Test deployment:"
echo "   Push any change to main branch → Watch automatic deployment!"
echo ""

echo "🔧 USEFUL COMMANDS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "docker compose logs              # View all logs"
echo "docker compose ps               # View service status"
echo "docker compose restart <service> # Restart a service"
echo "docker system prune -a          # Clean up unused images"
echo ""

echo "📚 DOCUMENTATION:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Full setup guide: /opt/backend-infra/README.md"
echo ""

echo "═══════════════════════════════════════════════════════════════"
log_success "Setup complete! Your VPS is ready for automated deployments 🚀"
echo ""

# Reminder about new group membership
log_warning "NOTE: Run 'newgrp docker' or logout/login to use Docker without sudo"
echo ""
