#!/bin/bash
# ============================================================================
# Script: update-all-passwords.sh
# Purpose: Convenience script to update all database passwords at once
# Project: myTraderGEO
# Author: DBA Agent
# Created: 2025-01-10
# ============================================================================
#
# This script updates passwords for:
#   - postgres (superuser) - OPTIONAL
#   - mytrader_app (application user)
#   - mytrader_readonly (read-only user)
#
# Usage:
#   1. From .env file:          ./update-all-passwords.sh /path/to/.env.staging
#   2. From environment:        DB_PASSWORD=xxx DB_APP_PASSWORD=yyy ./update-all-passwords.sh
#   3. Interactive prompt:      ./update-all-passwords.sh
#
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Functions
# ============================================================================

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Database Password Update Script${NC}"
    echo -e "${BLUE}  Project: myTraderGEO${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# Load environment variables from file
# ============================================================================

load_env_file() {
    local env_file="$1"

    if [ ! -f "$env_file" ]; then
        print_error "Environment file not found: $env_file"
        exit 1
    fi

    print_info "Loading passwords from: $env_file"

    # Export variables from .env file
    export $(grep -v '^#' "$env_file" | grep -E '(DB_PASSWORD|DB_APP_PASSWORD|DB_READONLY_PASSWORD)=' | xargs)

    if [ -z "$DB_APP_PASSWORD" ] || [ -z "$DB_READONLY_PASSWORD" ]; then
        print_error "Required passwords not found in $env_file"
        print_error "Make sure DB_APP_PASSWORD and DB_READONLY_PASSWORD are set"
        exit 1
    fi

    print_success "Passwords loaded from file"
}

# ============================================================================
# Interactive password prompt
# ============================================================================

prompt_passwords() {
    print_info "Interactive password entry mode"
    echo ""

    # Postgres password (optional)
    read -p "Update postgres superuser password? (y/N): " update_postgres
    if [[ "$update_postgres" =~ ^[Yy]$ ]]; then
        read -s -p "Enter new postgres password: " DB_PASSWORD
        echo ""
        read -s -p "Confirm postgres password: " DB_PASSWORD_CONFIRM
        echo ""

        if [ "$DB_PASSWORD" != "$DB_PASSWORD_CONFIRM" ]; then
            print_error "Postgres passwords do not match!"
            exit 1
        fi

        UPDATE_POSTGRES=true
    else
        UPDATE_POSTGRES=false
    fi

    # Application user password
    read -s -p "Enter new mytrader_app password: " DB_APP_PASSWORD
    echo ""
    read -s -p "Confirm mytrader_app password: " DB_APP_PASSWORD_CONFIRM
    echo ""

    if [ "$DB_APP_PASSWORD" != "$DB_APP_PASSWORD_CONFIRM" ]; then
        print_error "Application passwords do not match!"
        exit 1
    fi

    # Read-only user password
    read -s -p "Enter new mytrader_readonly password: " DB_READONLY_PASSWORD
    echo ""
    read -s -p "Confirm mytrader_readonly password: " DB_READONLY_PASSWORD_CONFIRM
    echo ""

    if [ "$DB_READONLY_PASSWORD" != "$DB_READONLY_PASSWORD_CONFIRM" ]; then
        print_error "Read-only passwords do not match!"
        exit 1
    fi

    print_success "Passwords entered successfully"
    echo ""
}

# ============================================================================
# Validate password complexity
# ============================================================================

validate_password() {
    local password="$1"
    local user_type="$2"
    local min_length="${3:-16}"

    if [ ${#password} -lt $min_length ]; then
        print_error "$user_type password must be at least $min_length characters"
        return 1
    fi

    # Check for complexity (at least one uppercase, lowercase, number, special char)
    if ! echo "$password" | grep -q '[A-Z]'; then
        print_warning "$user_type password should contain uppercase letters"
    fi

    if ! echo "$password" | grep -q '[a-z]'; then
        print_warning "$user_type password should contain lowercase letters"
    fi

    if ! echo "$password" | grep -q '[0-9]'; then
        print_warning "$user_type password should contain numbers"
    fi

    if ! echo "$password" | grep -q '[^a-zA-Z0-9]'; then
        print_warning "$user_type password should contain special characters"
    fi

    return 0
}

# ============================================================================
# Update passwords in database
# ============================================================================

update_passwords() {
    print_info "Updating database passwords..."
    echo ""

    # Detect database host (default to localhost if not in container)
    DB_HOST="${DB_HOST:-localhost}"
    DB_NAME="${DB_NAME:-mytrader_dev}"
    DB_USER="${DB_USER:-postgres}"

    print_info "Database: $DB_HOST / $DB_NAME"
    print_info "Connecting as: $DB_USER"
    echo ""

    # Build SQL commands
    local SQL_COMMANDS=""

    if [ "$UPDATE_POSTGRES" = true ] && [ -n "$DB_PASSWORD" ]; then
        print_info "Will update: postgres (superuser)"
        SQL_COMMANDS="ALTER USER postgres WITH PASSWORD '$DB_PASSWORD';"
    fi

    SQL_COMMANDS="$SQL_COMMANDS
    ALTER USER mytrader_app WITH PASSWORD '$DB_APP_PASSWORD';
    ALTER USER mytrader_readonly WITH PASSWORD '$DB_READONLY_PASSWORD';"

    print_info "Will update: mytrader_app"
    print_info "Will update: mytrader_readonly"
    echo ""

    # Execute password updates
    if docker exec mytraderdev-database psql -U "$DB_USER" -d "$DB_NAME" -c "$SQL_COMMANDS" 2>/dev/null; then
        print_success "Passwords updated in database!"
    elif psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "$SQL_COMMANDS"; then
        print_success "Passwords updated in database!"
    else
        print_error "Failed to connect to database"
        print_info "Make sure database is running and credentials are correct"
        exit 1
    fi

    echo ""
}

# ============================================================================
# Next steps reminder
# ============================================================================

print_next_steps() {
    echo ""
    print_header
    print_success "Database passwords updated successfully!"
    echo ""
    print_warning "IMPORTANT: Next steps to complete the update:"
    echo ""
    echo "1. Update .env file on server with new passwords"
    echo "2. Restart API container:      docker compose restart api"

    if [ "$UPDATE_POSTGRES" = true ]; then
        echo "3. Restart database container: docker compose restart database"
        echo "4. Verify API connection:      docker compose logs api"
    else
        echo "3. Verify API connection:      docker compose logs api"
    fi

    echo ""
    echo "5. Document the rotation:"
    echo "   echo \"\$(date) - Password rotated by \$(whoami)\" >> password-rotation.log"
    echo ""
}

# ============================================================================
# Main script
# ============================================================================

main() {
    print_header

    # Check if .env file path provided
    if [ $# -eq 1 ]; then
        load_env_file "$1"
        UPDATE_POSTGRES=false  # Don't update postgres by default from file

        # Check if DB_PASSWORD is set in env file
        if [ -n "$DB_PASSWORD" ]; then
            read -p "Update postgres password too? (y/N): " update_pg
            if [[ "$update_pg" =~ ^[Yy]$ ]]; then
                UPDATE_POSTGRES=true
            fi
        fi
    else
        # Check if environment variables are already set
        if [ -n "$DB_APP_PASSWORD" ] && [ -n "$DB_READONLY_PASSWORD" ]; then
            print_info "Using passwords from environment variables"
            UPDATE_POSTGRES=false

            if [ -n "$DB_PASSWORD" ]; then
                UPDATE_POSTGRES=true
                print_info "Will also update postgres password"
            fi
        else
            # Interactive mode
            prompt_passwords
        fi
    fi

    # Validate passwords
    echo ""
    print_info "Validating password complexity..."

    if [ "$UPDATE_POSTGRES" = true ]; then
        validate_password "$DB_PASSWORD" "postgres" 20
    fi

    validate_password "$DB_APP_PASSWORD" "mytrader_app" 16
    validate_password "$DB_READONLY_PASSWORD" "mytrader_readonly" 16

    echo ""

    # Confirm before proceeding
    print_warning "This will update database passwords!"
    read -p "Continue? (y/N): " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_error "Operation cancelled by user"
        exit 0
    fi

    # Update passwords
    update_passwords

    # Print next steps
    print_next_steps
}

# Run main function
main "$@"
