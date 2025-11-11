#!/bin/bash
# Password Rotation Wrapper for myTraderGEO
# Reads credentials from .env file and executes password update SQL
# Usage: ./rotate-passwords.sh [path/to/.env]
#
# Security: Passwords are passed via psql -v variables, not exposed in process list

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${1:-.env}"
SQL_FILE="$SCRIPT_DIR/../migrations/000_update_passwords.sql"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function: Print colored message
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validation: Check if .env file exists
if [[ ! -f "$ENV_FILE" ]]; then
    log_error ".env file not found: $ENV_FILE"
    echo ""
    echo "Usage: $0 [path/to/.env]"
    echo "Example: $0 .env.staging"
    exit 1
fi

# Validation: Check if SQL file exists
if [[ ! -f "$SQL_FILE" ]]; then
    log_error "SQL file not found: $SQL_FILE"
    exit 1
fi

# Parse .env file (ignore comments, empty lines, and export statements)
log_info "Parsing $ENV_FILE..."
export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | sed 's/export //g' | xargs)

# Validation: Check required variables
if [[ -z "${DB_APP_PASSWORD:-}" ]]; then
    log_error "DB_APP_PASSWORD not found in $ENV_FILE"
    exit 1
fi

if [[ -z "${DB_READONLY_PASSWORD:-}" ]]; then
    log_error "DB_READONLY_PASSWORD not found in $ENV_FILE"
    exit 1
fi

if [[ -z "${DB_NAME:-}" ]]; then
    log_warn "DB_NAME not found in $ENV_FILE, using default: mytrader_dev"
    DB_NAME="mytrader_dev"
fi

# Confirmation prompt
log_info "Configuration:"
echo "  Database: $DB_NAME"
echo "  SQL File: $SQL_FILE"
echo "  App Password: ${DB_APP_PASSWORD:0:4}... (hidden)"
echo "  Readonly Password: ${DB_READONLY_PASSWORD:0:4}... (hidden)"
echo ""
read -p "Proceed with password rotation? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warn "Operation cancelled by user"
    exit 0
fi

# Execute password rotation
log_info "Executing password rotation..."

# Use psql with -v to pass passwords securely (not visible in process list)
if psql -U postgres -d "$DB_NAME" \
    -v app_password="$DB_APP_PASSWORD" \
    -v readonly_password="$DB_READONLY_PASSWORD" \
    -f "$SQL_FILE" 2>&1 | tee /tmp/rotate-passwords.log; then

    log_info "✓ Password rotation completed successfully!"
    echo ""
    log_warn "Next steps:"
    echo "  1. Update $ENV_FILE with new passwords (if changed)"
    echo "  2. Restart API container: docker compose restart api"
    echo "  3. Verify: docker compose logs api | grep 'Database connection'"
    echo "  4. Document rotation: echo \"\$(date) - Passwords rotated\" >> password-rotation.log"
else
    log_error "✗ Password rotation failed! Check /tmp/rotate-passwords.log for details"
    exit 1
fi
