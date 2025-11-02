#!/bin/bash
#
# Step 6: SSH Keys Configuration
# Part of myTraderGEO Server Setup
#
# This script configures SSH keys for the project user.
#

set -e

PROJECT_USER="${1:-}"

if [[ -z "$PROJECT_USER" ]]; then
    echo "Error: Project user not provided"
    echo "Usage: bash 06-ssh-keys.sh <project_user>"
    exit 1
fi

echo "Configuring SSH keys for user: $PROJECT_USER"

USER_HOME=$(eval echo ~"$PROJECT_USER")
SSH_DIR="$USER_HOME/.ssh"

# Create .ssh directory if it doesn't exist
if [[ ! -d "$SSH_DIR" ]]; then
    echo "Creating .ssh directory..."
    sudo -u "$PROJECT_USER" mkdir -p "$SSH_DIR"
    sudo chmod 700 "$SSH_DIR"
else
    echo ".ssh directory already exists"
fi

# Create authorized_keys file if it doesn't exist
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
if [[ ! -f "$AUTHORIZED_KEYS" ]]; then
    echo "Creating authorized_keys file..."
    sudo -u "$PROJECT_USER" touch "$AUTHORIZED_KEYS"
    sudo chmod 600 "$AUTHORIZED_KEYS"
else
    echo "authorized_keys file already exists"
fi

echo ""
echo "✅ SSH keys configuration completed"
echo "   SSH directory: $SSH_DIR"
echo "   Authorized keys: $AUTHORIZED_KEYS"
echo ""
echo "   Next steps:"
echo "   1. Add your public SSH key to: $AUTHORIZED_KEYS"
echo "   2. Example: echo 'your-public-key' | sudo tee -a $AUTHORIZED_KEYS"
echo "   3. Test SSH connection: ssh $PROJECT_USER@<server-ip>"
