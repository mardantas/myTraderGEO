#!/bin/bash
#
# Step 4: Security Hardening
# Part of [PROJECT_NAME] Server Setup
#
# This script installs and configures security tools:
# - fail2ban (brute-force protection)
# - chrony (NTP time synchronization)
# - apache2-utils (htpasswd for Traefik dashboard)
#

set -e

TIMEZONE="${1:-UTC}"

echo "Installing security tools..."

# Install fail2ban (brute-force protection)
echo "Installing fail2ban..."
sudo apt-get install -y fail2ban

# Start and enable fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Verify fail2ban status
echo "fail2ban status:"
sudo systemctl status fail2ban --no-pager | head -5

echo ""

# Install chrony (NTP time synchronization)
echo "Installing chrony (NTP)..."
sudo apt-get install -y chrony

# Set timezone
echo "Setting timezone to: $TIMEZONE"
sudo timedatectl set-timezone "$TIMEZONE"

# Start and enable chrony
sudo systemctl start chrony
sudo systemctl enable chrony

# Verify chrony status
echo "chrony status:"
sudo systemctl status chrony --no-pager | head -5

echo ""

# Verify time synchronization
echo "Current system time:"
timedatectl

echo ""

# Install apache2-utils (for htpasswd - Traefik dashboard authentication)
echo "Installing apache2-utils (htpasswd)..."
sudo apt-get install -y apache2-utils

# Verify htpasswd installation
if command -v htpasswd &> /dev/null; then
    echo "✅ htpasswd installed successfully"
else
    echo "⚠️  Warning: htpasswd not found"
fi

echo ""
echo "✅ Security hardening completed"
echo "   - fail2ban: Brute-force protection enabled"
echo "   - chrony: NTP time synchronization enabled"
echo "   - htpasswd: Available for Traefik dashboard authentication"
echo "   - Timezone: $TIMEZONE"
