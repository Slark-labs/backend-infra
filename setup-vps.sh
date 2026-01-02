#!/bin/bash

# VPS Initial Setup Script for Backend Infrastructure
# Run this script on your VPS to set up the infrastructure for the first time

set -e

echo "🚀 Starting VPS setup for backend infrastructure..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "📦 Installing required packages..."
sudo apt install -y curl wget git docker.io docker-compose-plugin

# Start and enable Docker
echo "🐳 Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group (optional, for convenience)
sudo usermod -aG docker $USER

# Create infrastructure directory
echo "📁 Creating infrastructure directory..."
sudo mkdir -p /opt/backend-infra
sudo chown -R $USER:$USER /opt/backend-infra

# Create env directory with proper permissions
echo "🔒 Creating environment variables directory..."
sudo mkdir -p /opt/infra/env
sudo chown -R $USER:$USER /opt/infra/env
sudo chmod 700 /opt/infra/env

# Clone the infrastructure repository (replace with your actual repo URL)
echo "📥 Cloning infrastructure repository..."
# Replace this with your actual repository URL
# git clone https://github.com/yourusername/backend-infra.git /opt/backend-infra

echo "⚠️  Please manually clone your backend-infra repository to /opt/backend-infra"
echo "   Example: git clone https://github.com/yourusername/backend-infra.git /opt/backend-infra"

# Create basic environment files
echo "📝 Creating basic environment files..."

# Database environment (for docker-compose)
cat > /opt/infra/env/database.env << EOF
POSTGRES_PASSWORD=your_secure_postgres_password_here
EOF

# Example app environment template
# Copy and customize this for each of your applications
cat > /opt/infra/env/your-app-backend.env << EOF
PORT=3000
NODE_ENV=production
DATABASE_URL=postgres://postgres:your_secure_postgres_password_here@postgres:5432/app_database
REDIS_URL=redis://redis:6379
JWT_SECRET=your_jwt_secret_here
EOF

echo "📝 Created template environment file: /opt/infra/env/your-app-backend.env"
echo "   Copy this file for each of your applications:"
echo "   cp /opt/infra/env/your-app-backend.env /opt/infra/env/your-first-app-backend.env"
echo "   cp /opt/infra/env/your-app-backend.env /opt/infra/env/your-second-app-backend.env"

echo "⚠️  IMPORTANT: Update the environment variables in /opt/infra/env/ with your actual values!"
echo "   - database.env: Set a strong POSTGRES_PASSWORD"
echo "   - your-app-backend.env: Copy this template for each of your applications"
echo "   - Update DATABASE_URL with the same password from database.env"
echo "   - JWT_SECRET: Use a unique, strong secret for each app"
echo "   - Customize other variables as needed for your applications"

# Set proper permissions on env files
sudo chmod 600 /opt/infra/env/*.env

echo "✅ VPS setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Update environment variables in /opt/infra/env/"
echo "2. Clone your backend-infra repo to /opt/backend-infra/"
echo "3. Run: cd /opt/backend-infra && docker compose up -d"
echo "4. Test your deployments with the GitHub Actions workflows"
echo ""
echo "🔧 Useful commands:"
echo "   docker compose logs              # View all logs"
echo "   docker compose ps               # View service status"
echo "   docker compose restart <service> # Restart a specific service"
echo "   docker system prune -a          # Clean up unused images"
