#!/bin/bash
#
# Step 1: System Update and Essential Tools
# Part of [PROJECT_NAME] Server Setup
#
# This script updates the system and installs essential tools.
#

set -e

echo "Updating system packages..."

# Update package lists
sudo apt-get update

# Upgrade installed packages
sudo apt-get upgrade -y

# Install essential tools
echo "Installing essential tools..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    vim \
    git \
    tree \
    htop \
    net-tools \
    unzip \
    software-properties-common

echo "✅ System updated and essential tools installed"
