#!/bin/bash

# ==================================
# myTraderGEO - Deployment Script
# ==================================
# Usage: ./deploy.sh [environment] [version]
# Example: ./deploy.sh production v1.0.0
#          ./deploy.sh staging latest

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INFRA_DIR="$PROJECT_ROOT/05-infra"

# ==================================
# Functions
# ==================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $0 [environment] [version]

Arguments:
    environment    Target environment (development|staging|production)
    version        Docker image version tag (default: latest)

Examples:
    $0 development
    $0 staging latest
    $0 production v1.0.0

EOF
    exit 1
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi

    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi

    log_info "All prerequisites met"
}

load_env_file() {
    local env_file="$INFRA_DIR/configs/.env"

    if [ ! -f "$env_file" ]; then
        log_error ".env file not found at $env_file"
        log_info "Copy .env.example to .env and configure it:"
        log_info "  cp $INFRA_DIR/configs/.env.example $env_file"
        exit 1
    fi

    log_info "Loading environment variables from $env_file"
    set -a
    source "$env_file"
    set +a
}

backup_database() {
    local env=$1

    log_warn "Database backup not implemented yet"
    log_info "Skipping database backup for $env environment"
    # TODO: Implement backup using backup-database.sh script
}

pull_images() {
    local env=$1
    local compose_file="$INFRA_DIR/docker/docker-compose.$env.yml"

    log_info "Pulling Docker images for $env environment..."
    docker compose -f "$compose_file" pull
}

deploy_services() {
    local env=$1
    local compose_file="$INFRA_DIR/docker/docker-compose.$env.yml"

    log_info "Deploying services for $env environment..."
    docker compose -f "$compose_file" up -d --remove-orphans

    log_info "Waiting for services to be healthy..."
    sleep 10

    docker compose -f "$compose_file" ps
}

run_migrations() {
    local env=$1

    log_info "Running database migrations..."
    # TODO: Implement migration execution
    # docker compose -f "$compose_file" exec api dotnet ef database update
}

health_check() {
    local env=$1

    log_info "Running health checks..."

    local api_url="http://localhost:5000/health"
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$api_url" > /dev/null 2>&1; then
            log_info "API health check passed"
            return 0
        fi

        log_warn "API not ready yet (attempt $attempt/$max_attempts)..."
        sleep 2
        ((attempt++))
    done

    log_error "API health check failed after $max_attempts attempts"
    return 1
}

show_logs() {
    local env=$1
    local compose_file="$INFRA_DIR/docker/docker-compose.$env.yml"

    log_info "Showing recent logs..."
    docker compose -f "$compose_file" logs --tail=50
}

# ==================================
# Main Deployment Flow
# ==================================

main() {
    local environment=${1:-}
    local version=${2:-latest}

    # Validate arguments
    if [ -z "$environment" ]; then
        log_error "Environment argument is required"
        show_usage
    fi

    # Validate environment
    case "$environment" in
        development)
            log_warn "Deploying to DEVELOPMENT environment"
            ;;
        staging)
            log_info "Deploying to STAGING environment"
            ;;
        production)
            log_warn "Deploying to PRODUCTION environment"
            read -p "Are you sure you want to deploy to production? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                log_info "Deployment cancelled"
                exit 0
            fi
            ;;
        *)
            log_error "Invalid environment: $environment"
            log_info "Valid environments: development, staging, production"
            show_usage
            ;;
    esac

    # Export version for docker-compose
    export VERSION="$version"

    log_info "========================================="
    log_info "myTraderGEO Deployment"
    log_info "========================================="
    log_info "Environment: $environment"
    log_info "Version: $version"
    log_info "========================================="

    # Execute deployment steps
    check_prerequisites
    load_env_file

    if [ "$environment" != "development" ]; then
        backup_database "$environment"
        pull_images "$environment"
    fi

    deploy_services "$environment"

    if [ "$environment" != "development" ]; then
        run_migrations "$environment"
    fi

    health_check "$environment"

    log_info "========================================="
    log_info "Deployment completed successfully!"
    log_info "========================================="
    log_info "API: http://localhost:5000"
    log_info "Frontend: http://localhost:3000"
    log_info "========================================="

    # Ask if user wants to see logs
    read -p "Show logs? (y/n): " show_logs_confirm
    if [ "$show_logs_confirm" = "y" ]; then
        show_logs "$environment"
    fi
}

# Run main function
main "$@"
