#!/bin/bash
#
# Step 3: UFW Firewall Setup
# Part of myTraderGEO Server Setup
#
# This script configures UFW firewall to allow only necessary ports.
#

set -e

echo "Configuring UFW Firewall..."

# Install UFW if not already installed
if ! command -v ufw &> /dev/null; then
    echo "Installing UFW..."
    sudo apt-get install -y ufw
fi

# Set default policies
echo "Setting default firewall policies..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (port 22) - CRITICAL: Must be enabled before activating UFW
echo "Allowing SSH (port 22)..."
sudo ufw allow 22/tcp comment 'SSH'

# Allow HTTP (port 80)
echo "Allowing HTTP (port 80)..."
sudo ufw allow 80/tcp comment 'HTTP'

# Allow HTTPS (port 443)
echo "Allowing HTTPS (port 443)..."
sudo ufw allow 443/tcp comment 'HTTPS'

# Enable UFW
echo "Enabling UFW firewall..."
echo "y" | sudo ufw enable

# Show status
echo ""
echo "Current firewall status:"
sudo ufw status verbose

echo ""
echo "✅ UFW Firewall configured successfully"
echo "   Allowed ports: 22 (SSH), 80 (HTTP), 443 (HTTPS)"
