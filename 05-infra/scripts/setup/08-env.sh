#!/bin/bash
#
# Step 8: Environment File (.env) Template
# Part of myTraderGEO Server Setup
#
# This script creates a template .env file for the environment.
#

set -e

PROJECT_USER="${1:-}"
PROJECT_NAME="${2:-app}"
ENVIRONMENT="${3:-staging}"

if [[ -z "$PROJECT_USER" ]]; then
    echo "Error: Project user not provided"
    echo "Usage: bash 08-env.sh <project_user> <project_name> <environment>"
    exit 1
fi

echo "Creating .env template for environment: $ENVIRONMENT"

USER_HOME=$(eval echo ~"$PROJECT_USER")
PROJECT_ROOT="$USER_HOME/${PROJECT_NAME}"
ENV_FILE="$PROJECT_ROOT/.env.${ENVIRONMENT}"

# Determine domain based on environment
if [[ "$ENVIRONMENT" == "production" ]]; then
    DOMAIN="example.com"
else
    DOMAIN="staging.example.com"
fi

# Create .env template
echo "Creating $ENV_FILE..."

sudo -u "$PROJECT_USER" cat > "$ENV_FILE" <<EOF
# myTraderGEO Environment Configuration
# Environment: ${ENVIRONMENT}
# Generated: $(date)
#
# IMPORTANT:
# - Review and update all values below
# - Never commit this file to Git
# - Use strong passwords (16+ characters for staging, 20+ for production)

# Domain Configuration
DOMAIN=${DOMAIN}

# Database Configuration
POSTGRES_DB=myTraderGEO_${ENVIRONMENT}
POSTGRES_USER=postgres
POSTGRES_PASSWORD=CHANGE_ME_STRONG_PASSWORD

# Application Database User (Least Privilege)
DB_APP_USER=mytrader_app
DB_APP_PASSWORD=CHANGE_ME_STRONG_PASSWORD

# JWT Configuration
JWT_SECRET_KEY=CHANGE_ME_STRONG_RANDOM_KEY
JWT_EXPIRATION_MINUTES=15

# Let's Encrypt Configuration
ACME_EMAIL=admin@${DOMAIN}

# Traefik Dashboard (Basic Auth)
# Generate password hash with: htpasswd -nb admin your_password
TRAEFIK_DASHBOARD_AUTH=admin:CHANGE_ME_HTPASSWD_HASH

# Traefik Dashboard IP Whitelist (Production Only)
# Change to YOUR public IP address
YOUR_IP_ADDRESS=203.0.113.0

# Logging
LOG_LEVEL=${ENVIRONMENT == "production" ? "Warning" : "Information"}

# Application Settings
ASPNETCORE_ENVIRONMENT=${ENVIRONMENT^}
EOF

# Set secure permissions
sudo chmod 600 "$ENV_FILE"
sudo chown "$PROJECT_USER:$PROJECT_USER" "$ENV_FILE"

echo ""
echo "✅ Environment file created: $ENV_FILE"
echo ""
echo "   ⚠️  IMPORTANT - Next Steps:"
echo "   1. Edit $ENV_FILE"
echo "   2. Update all CHANGE_ME values"
echo "   3. Generate strong passwords:"
echo "      openssl rand -base64 32"
echo "   4. Generate Traefik dashboard auth:"
echo "      htpasswd -nb admin your_strong_password"
echo "   5. Update YOUR_IP_ADDRESS with your public IP"
echo "   6. Update ACME_EMAIL with your email"
echo ""
echo "   Security Notes:"
echo "   - File permissions: 600 (read/write for $PROJECT_USER only)"
echo "   - Never commit this file to Git"
echo "   - Use different passwords for staging and production"
