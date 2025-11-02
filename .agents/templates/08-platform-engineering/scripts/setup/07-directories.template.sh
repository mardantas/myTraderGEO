#!/bin/bash
#
# Step 7: Directory Structure Creation
# Part of [PROJECT_NAME] Server Setup
#
# This script creates the project directory structure.
#

set -e

PROJECT_USER="${1:-}"
PROJECT_NAME="${2:-app}"

if [[ -z "$PROJECT_USER" ]]; then
    echo "Error: Project user not provided"
    echo "Usage: bash 07-directories.sh <project_user> <project_name>"
    exit 1
fi

echo "Creating project directory structure..."

USER_HOME=$(eval echo ~"$PROJECT_USER")
PROJECT_ROOT="$USER_HOME/${PROJECT_NAME}"

# Create directory structure
echo "Creating directories under: $PROJECT_ROOT"

sudo -u "$PROJECT_USER" mkdir -p "$PROJECT_ROOT"
sudo -u "$PROJECT_USER" mkdir -p "$PROJECT_ROOT/configs"
sudo -u "$PROJECT_USER" mkdir -p "$PROJECT_ROOT/backups/postgres"
sudo -u "$PROJECT_USER" mkdir -p "$PROJECT_ROOT/scripts"
sudo -u "$PROJECT_USER" mkdir -p "$PROJECT_ROOT/logs"

# Verify directory creation
echo ""
echo "Directory structure:"
tree -L 2 "$PROJECT_ROOT" 2>/dev/null || ls -la "$PROJECT_ROOT"

echo ""
echo "✅ Directory structure created successfully"
echo "   Root: $PROJECT_ROOT"
echo "   - configs/           (configuration files)"
echo "   - backups/postgres/  (database backups)"
echo "   - scripts/           (maintenance scripts)"
echo "   - logs/              (application logs)"
