#!/bin/bash
#
# Step 9: Verification and Validation
# Part of myTraderGEO Server Setup
#
# This script validates all setup steps and provides a checklist.
#

set -e

PROJECT_USER="${1:-}"

if [[ -z "$PROJECT_USER" ]]; then
    echo "Error: Project user not provided"
    echo "Usage: bash 09-verify.sh <project_user>"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Server Setup Verification Checklist"
echo "========================================="
echo ""

PASS_COUNT=0
FAIL_COUNT=0

check_pass() {
    echo -e "[${GREEN}✓${NC}] $1"
    ((PASS_COUNT++))
}

check_fail() {
    echo -e "[${RED}✗${NC}] $1"
    ((FAIL_COUNT++))
}

check_warn() {
    echo -e "[${YELLOW}!${NC}] $1"
}

# Hostname
echo "Checking hostname..."
HOSTNAME=$(hostname)
if [[ -n "$HOSTNAME" ]]; then
    check_pass "Hostname: $HOSTNAME"
else
    check_fail "Hostname not set"
fi
echo ""

# System Updates
echo "Checking system packages..."
if command -v apt-get &> /dev/null; then
    check_pass "apt-get available"
else
    check_fail "apt-get not found"
fi
echo ""

# Docker
echo "Checking Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    check_pass "Docker: $DOCKER_VERSION"

    if command -v docker compose &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version)
        check_pass "Docker Compose: $COMPOSE_VERSION"
    else
        check_fail "Docker Compose not found"
    fi

    # Check Docker service
    if systemctl is-active --quiet docker; then
        check_pass "Docker service: Active"
    else
        check_fail "Docker service: Inactive"
    fi
else
    check_fail "Docker not installed"
fi
echo ""

# Firewall
echo "Checking UFW firewall..."
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status | head -1)
    if [[ "$UFW_STATUS" == *"active"* ]]; then
        check_pass "UFW: Active"
        echo "   Open ports:"
        sudo ufw status numbered | grep "ALLOW" | sed 's/^/   /'
    else
        check_fail "UFW: Inactive"
    fi
else
    check_fail "UFW not installed"
fi
echo ""

# Security Tools
echo "Checking security tools..."

# fail2ban
if systemctl is-active --quiet fail2ban; then
    check_pass "fail2ban: Active"
else
    check_fail "fail2ban: Not active"
fi

# chrony
if systemctl is-active --quiet chrony; then
    check_pass "chrony (NTP): Active"
    TIMEZONE=$(timedatectl show -p Timezone --value)
    echo "   Timezone: $TIMEZONE"
else
    check_fail "chrony: Not active"
fi

# htpasswd
if command -v htpasswd &> /dev/null; then
    check_pass "htpasswd: Available"
else
    check_fail "htpasswd not found"
fi
echo ""

# User and Group
echo "Checking project user: $PROJECT_USER..."
if id "$PROJECT_USER" &> /dev/null; then
    check_pass "User exists: $PROJECT_USER"

    # Check groups
    USER_GROUPS=$(groups "$PROJECT_USER")
    echo "   Groups: $USER_GROUPS"

    if echo "$USER_GROUPS" | grep -q "docker"; then
        check_pass "User in docker group"
    else
        check_fail "User NOT in docker group"
    fi
else
    check_fail "User does not exist: $PROJECT_USER"
fi
echo ""

# SSH Configuration
echo "Checking SSH configuration..."
USER_HOME=$(eval echo ~"$PROJECT_USER")
SSH_DIR="$USER_HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

if [[ -d "$SSH_DIR" ]]; then
    check_pass "SSH directory exists: $SSH_DIR"

    SSH_DIR_PERMS=$(stat -c "%a" "$SSH_DIR")
    if [[ "$SSH_DIR_PERMS" == "700" ]]; then
        check_pass "SSH directory permissions: 700"
    else
        check_fail "SSH directory permissions: $SSH_DIR_PERMS (should be 700)"
    fi
else
    check_fail "SSH directory missing: $SSH_DIR"
fi

if [[ -f "$AUTHORIZED_KEYS" ]]; then
    check_pass "Authorized keys file exists"

    KEYS_PERMS=$(stat -c "%a" "$AUTHORIZED_KEYS")
    if [[ "$KEYS_PERMS" == "600" ]]; then
        check_pass "Authorized keys permissions: 600"
    else
        check_fail "Authorized keys permissions: $KEYS_PERMS (should be 600)"
    fi

    KEY_COUNT=$(wc -l < "$AUTHORIZED_KEYS")
    if [[ $KEY_COUNT -gt 0 ]]; then
        check_pass "SSH keys configured: $KEY_COUNT key(s)"
    else
        check_warn "No SSH keys configured yet"
    fi
else
    check_fail "Authorized keys file missing"
fi
echo ""

# Directory Structure
echo "Checking project directory structure..."
PROJECT_ROOT="$USER_HOME/myTraderGEO"

if [[ -d "$PROJECT_ROOT" ]]; then
    check_pass "Project root exists: $PROJECT_ROOT"

    for dir in configs backups/postgres scripts logs; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            check_pass "Directory exists: $dir"
        else
            check_fail "Directory missing: $dir"
        fi
    done
else
    check_fail "Project root missing: $PROJECT_ROOT"
fi
echo ""

# Environment File
echo "Checking environment files..."
for env in staging production; do
    ENV_FILE="$PROJECT_ROOT/.env.$env"
    if [[ -f "$ENV_FILE" ]]; then
        check_pass "Environment file exists: .env.$env"

        ENV_PERMS=$(stat -c "%a" "$ENV_FILE")
        if [[ "$ENV_PERMS" == "600" ]]; then
            check_pass "Environment file permissions: 600"
        else
            check_fail "Environment file permissions: $ENV_PERMS (should be 600)"
        fi

        # Check for placeholder values
        if grep -q "CHANGE_ME" "$ENV_FILE"; then
            check_warn ".env.$env contains CHANGE_ME placeholders - needs customization"
        else
            check_pass ".env.$env appears customized"
        fi
    else
        check_warn "Environment file not found: .env.$env (will be created during deployment)"
    fi
done
echo ""

# Summary
echo "========================================="
echo "Verification Summary"
echo "========================================="
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"
echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
    echo -e "${GREEN}✅ All checks passed! Server is ready for deployment.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some checks failed. Please review and fix issues before deploying.${NC}"
    exit 1
fi
