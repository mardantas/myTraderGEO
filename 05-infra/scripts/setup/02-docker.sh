#!/bin/bash
#
# Step 2: Docker Engine Installation
# Part of myTraderGEO Server Setup
#
# This script installs Docker Engine and Docker Compose Plugin on Debian 12.
#

set -e

echo "Installing Docker Engine..."

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo "⚠️  Docker is already installed: $DOCKER_VERSION"
    read -p "Reinstall Docker? [y/N]: " REINSTALL
    if [[ ! "$REINSTALL" =~ ^[Yy]$ ]]; then
        echo "Skipping Docker installation"
        exit 0
    fi
fi

# Remove old Docker installations
echo "Removing old Docker installations (if any)..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null || true
done

# Setup Docker's official GPG key
echo "Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo rm -f /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Setup Docker repository
echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt-get update

# Install Docker Engine, CLI, containerd, and Compose plugin
echo "Installing Docker Engine, CLI, containerd, and Docker Compose Plugin..."
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
echo ""
echo "Verifying Docker installation..."
docker --version
docker compose version

# Test Docker
echo ""
echo "Testing Docker with hello-world image..."
sudo docker run --rm hello-world

echo ""
echo "✅ Docker Engine and Docker Compose Plugin installed successfully"
