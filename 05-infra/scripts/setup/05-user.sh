#!/bin/bash
#
# Step 5: User and Group Creation
# Part of myTraderGEO Server Setup
#
# This script creates the project user and group with Docker access.
#

set -e

PROJECT_USER="${1:-}"
PROJECT_GROUP="${2:-$PROJECT_USER}"

if [[ -z "$PROJECT_USER" ]]; then
    echo "Error: Project user not provided"
    echo "Usage: bash 05-user.sh <project_user> [project_group]"
    exit 1
fi

echo "Creating project user and group..."

# Create group if it doesn't exist
if ! getent group "$PROJECT_GROUP" > /dev/null 2>&1; then
    echo "Creating group: $PROJECT_GROUP"
    sudo groupadd "$PROJECT_GROUP"
else
    echo "Group already exists: $PROJECT_GROUP"
fi

# Create user if it doesn't exist
if ! id "$PROJECT_USER" > /dev/null 2>&1; then
    echo "Creating user: $PROJECT_USER"
    sudo useradd -m -s /bin/bash -g "$PROJECT_GROUP" -G docker "$PROJECT_USER"

    # Set password for user
    echo ""
    echo "Set password for user $PROJECT_USER:"
    sudo passwd "$PROJECT_USER"
else
    echo "User already exists: $PROJECT_USER"

    # Ensure user is in docker group
    if ! groups "$PROJECT_USER" | grep -q "docker"; then
        echo "Adding $PROJECT_USER to docker group..."
        sudo usermod -aG docker "$PROJECT_USER"
    fi
fi

# Verify user creation
echo ""
echo "User information:"
id "$PROJECT_USER"

echo ""
echo "✅ User and group created successfully"
echo "   User: $PROJECT_USER"
echo "   Group: $PROJECT_GROUP"
echo "   Groups: $(groups $PROJECT_USER)"
echo ""
echo "   Note: $PROJECT_USER has been added to the 'docker' group"
echo "   Note: Log out and back in for group changes to take effect"
