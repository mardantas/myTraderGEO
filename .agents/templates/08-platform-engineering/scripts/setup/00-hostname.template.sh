#!/bin/bash
#
# Step 0: Configure Hostname
# Part of [PROJECT_NAME] Server Setup
#
# This script configures the server hostname based on the environment.
#

set -e

TARGET_HOSTNAME="${1:-}"

if [[ -z "$TARGET_HOSTNAME" ]]; then
    echo "Error: Hostname not provided"
    echo "Usage: bash 00-hostname.sh <hostname>"
    exit 1
fi

echo "Configuring hostname: $TARGET_HOSTNAME"

# Set hostname
sudo hostnamectl set-hostname "$TARGET_HOSTNAME"

# Update /etc/hosts
if ! grep -q "127.0.1.1.*$TARGET_HOSTNAME" /etc/hosts; then
    echo "127.0.1.1 $TARGET_HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
fi

# Verify
CURRENT_HOSTNAME=$(hostname)
if [[ "$CURRENT_HOSTNAME" == "$TARGET_HOSTNAME" ]]; then
    echo "✅ Hostname configured successfully: $TARGET_HOSTNAME"
else
    echo "⚠️  Warning: Hostname mismatch. Expected: $TARGET_HOSTNAME, Got: $CURRENT_HOSTNAME"
    exit 1
fi
