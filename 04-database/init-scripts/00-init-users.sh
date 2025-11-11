#!/bin/bash
# =====================================================
# Init Script: 00-init-users.sh
# Description: Cria usuÃ¡rios dedicados para a aplicaÃ§Ã£o com senhas do ambiente
# Security: PrincÃ­pio do Menor PrivilÃ©gio (Least Privilege)
# Project: myTraderGEO
# Author: DBA Agent
# Date: Generated from template
# =====================================================
#
# Este script Ã© executado automaticamente pelo PostgreSQL
# na inicializaÃ§Ã£o do container (via /docker-entrypoint-initdb.d/)
#
# IMPORTANTE:
# - Apenas executado na PRIMEIRA inicializaÃ§Ã£o (quando o volume estÃ¡ vazio)
# - Senhas vÃªm das variÃ¡veis de ambiente Docker:
#   * DB_APP_PASSWORD
#   * DB_READONLY_PASSWORD
#
# SECURITY NOTE:
# - NUNCA usar o usuÃ¡rio 'postgres' (superuser) na aplicaÃ§Ã£o
# - Usar 'mytrader_app' para a aplicaÃ§Ã£o
# - Usar 'mytrader_readonly' para analytics/backups
# - Senhas NUNCA hardcoded - sempre via environment variables
# =====================================================

set -e  # Exit on error

# Validate environment variables
if [ -z "$DB_APP_PASSWORD" ]; then
    echo "ERROR: DB_APP_PASSWORD environment variable is not set!"
    exit 1
fi

if [ -z "$DB_READONLY_PASSWORD" ]; then
    echo "ERROR: DB_READONLY_PASSWORD environment variable is not set!"
    exit 1
fi

echo "================================================="
echo "Creating application users for myTraderGEO"
echo "Using passwords from environment variables"
echo "================================================="

# Execute SQL with environment variables
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "mytrader_dev" <<-EOSQL
    -- =====================================================
    -- USER 1: mytrader_app (Application User)
    -- Purpose: Main application database user
    -- Permissions: CRUD + CREATE TABLE (for migrations)
    -- =====================================================

    DO
    \$\$
    BEGIN
        -- Criar usuÃ¡rio para aplicaÃ§Ã£o
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'mytrader_app') THEN
            CREATE USER mytrader_app WITH
                PASSWORD '$DB_APP_PASSWORD'
                NOCREATEDB
                NOCREATEROLE
                NOSUPERUSER;
            RAISE NOTICE 'âœ“ User mytrader_app created successfully';
        ELSE
            RAISE NOTICE '! User mytrader_app already exists';
        END IF;
    END
    \$\$;

    -- =====================================================
    -- USER 2: mytrader_readonly (Read-Only User)
    -- Purpose: Analytics, Reports, Backups
    -- Permissions: SELECT only
    -- =====================================================

    DO
    \$\$
    BEGIN
        -- Criar usuÃ¡rio read-only
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'mytrader_readonly') THEN
            CREATE USER mytrader_readonly WITH
                PASSWORD '$DB_READONLY_PASSWORD'
                NOCREATEDB
                NOCREATEROLE
                NOSUPERUSER;
            RAISE NOTICE 'âœ“ User mytrader_readonly created successfully';
        ELSE
            RAISE NOTICE '! User mytrader_readonly already exists';
        END IF;
    END
    \$\$;

    -- =====================================================
    -- SECURITY: Revogar CONNECT do role public (GLOBAL)
    -- =====================================================
    -- PostgreSQL concede CONNECT ao role 'public' por padrÃ£o.
    -- Todos os usuÃ¡rios herdam de 'public' automaticamente.
    -- Devemos revogar de 'public' PRIMEIRO para bloquear heranÃ§a.

    REVOKE CONNECT ON DATABASE template0 FROM public;
    REVOKE CONNECT ON DATABASE template1 FROM public;
    REVOKE CONNECT ON DATABASE postgres FROM public;

    -- =====================================================
    -- SECURITY: Revogar acesso a databases do sistema
    -- =====================================================
    -- Por padrÃ£o, PostgreSQL permite conexÃ£o a qualquer database.
    -- Devemos revogar explicitamente para aplicar Least Privilege.

    -- mytrader_app revocations
    REVOKE CONNECT ON DATABASE template0 FROM mytrader_app;
    REVOKE CONNECT ON DATABASE template1 FROM mytrader_app;
    REVOKE CONNECT ON DATABASE postgres FROM mytrader_app;

    -- mytrader_readonly revocations
    REVOKE CONNECT ON DATABASE template0 FROM mytrader_readonly;
    REVOKE CONNECT ON DATABASE template1 FROM mytrader_readonly;
    REVOKE CONNECT ON DATABASE postgres FROM mytrader_readonly;

    -- =====================================================
    -- PERMISSIONS: mytrader_app (Application User)
    -- =====================================================

    -- Grant permissÃµes APENAS no database da aplicaÃ§Ã£o
    GRANT CONNECT ON DATABASE mytrader_dev TO mytrader_app;
    GRANT USAGE ON SCHEMA public TO mytrader_app;

    -- PermissÃµes em tabelas existentes (CRUD)
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO mytrader_app;

    -- PermissÃµes em sequÃªncias (para SERIAL/IDENTITY/auto-increment)
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO mytrader_app;

    -- PermissÃµes futuras (para tabelas criadas depois - importante para migrations)
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO mytrader_app;

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT USAGE, SELECT ON SEQUENCES TO mytrader_app;

    -- Permitir criaÃ§Ã£o de tabelas (necessÃ¡rio para migrations)
    GRANT CREATE ON SCHEMA public TO mytrader_app;

    -- =====================================================
    -- PERMISSIONS: mytrader_readonly (Read-Only User)
    -- =====================================================

    -- Grant permissÃµes apenas de leitura APENAS no database da aplicaÃ§Ã£o
    GRANT CONNECT ON DATABASE mytrader_dev TO mytrader_readonly;
    GRANT USAGE ON SCHEMA public TO mytrader_readonly;

    -- Apenas SELECT em todas as tabelas
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO mytrader_readonly;

    -- PermissÃµes futuras
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT ON TABLES TO mytrader_readonly;

EOSQL

echo ""
echo "================================================="
echo "SECURITY SUMMARY - PostgreSQL Users"
echo "================================================="
echo ""
echo "USER: postgres (SUPERUSER)"
echo "  Purpose: Database administration ONLY"
echo "  Usage: Manual DBA tasks, troubleshooting"
echo "  âš ï¸  NEVER use in application connection string"
echo ""
echo "USER: mytrader_app (APPLICATION)"
echo "  Purpose: Main application"
echo "  Permissions: CRUD + CREATE TABLE"
echo "  âœ“ Can: SELECT, INSERT, UPDATE, DELETE, CREATE TABLE"
echo "  âœ— Cannot: DROP DATABASE, CREATE ROLE, ALTER SYSTEM"
echo "  âœ— Cannot: Connect to template0, template1, postgres"
echo ""
echo "USER: mytrader_readonly (READ-ONLY)"
echo "  Purpose: Analytics, Reports, Backups"
echo "  Permissions: SELECT only"
echo "  âœ“ Can: SELECT"
echo "  âœ— Cannot: INSERT, UPDATE, DELETE, CREATE"
echo "  âœ— Cannot: Connect to template0, template1, postgres"
echo ""
echo "================================================="
echo "Setup completed successfully!"
echo "================================================="
echo ""

# List created users (for verification)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "mytrader_dev" -c "\du"
