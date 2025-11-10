#!/bin/bash
# =====================================================
# Init Script: 00-init-users.sh
# Description: Cria usuários dedicados para a aplicação com senhas do ambiente
# Security: Princípio do Menor Privilégio (Least Privilege)
# Project: myTraderGEO
# Author: DBA Agent
# Date: Generated from template
# =====================================================
#
# Este script é executado automaticamente pelo PostgreSQL
# na inicialização do container (via /docker-entrypoint-initdb.d/)
#
# IMPORTANTE:
# - Apenas executado na PRIMEIRA inicialização (quando o volume está vazio)
# - Senhas vêm das variáveis de ambiente Docker:
#   * DB_APP_PASSWORD
#   * DB_READONLY_PASSWORD
#
# SECURITY NOTE:
# - NUNCA usar o usuário 'postgres' (superuser) na aplicação
# - Usar 'mytrader_app' para a aplicação
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
        -- Criar usuário para aplicação
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'mytrader_app') THEN
            CREATE USER mytrader_app WITH
                PASSWORD '$DB_APP_PASSWORD'
                NOCREATEDB
                NOCREATEROLE
                NOSUPERUSER;
            RAISE NOTICE '✓ User mytrader_app created successfully';
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
        -- Criar usuário read-only
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'mytrader_readonly') THEN
            CREATE USER mytrader_readonly WITH
                PASSWORD '$DB_READONLY_PASSWORD'
                NOCREATEDB
                NOCREATEROLE
                NOSUPERUSER;
            RAISE NOTICE '✓ User mytrader_readonly created successfully';
        ELSE
            RAISE NOTICE '! User mytrader_readonly already exists';
        END IF;
    END
    \$\$;

    -- =====================================================
    -- SECURITY: Revogar CONNECT do role public (GLOBAL)
    -- =====================================================
    -- PostgreSQL concede CONNECT ao role 'public' por padrão.
    -- Todos os usuários herdam de 'public' automaticamente.
    -- Devemos revogar de 'public' PRIMEIRO para bloquear herança.

    REVOKE CONNECT ON DATABASE template0 FROM public;
    REVOKE CONNECT ON DATABASE template1 FROM public;
    REVOKE CONNECT ON DATABASE postgres FROM public;

    -- =====================================================
    -- SECURITY: Revogar acesso a databases do sistema
    -- =====================================================
    -- Por padrão, PostgreSQL permite conexão a qualquer database.
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

    -- Grant permissões APENAS no database da aplicação
    GRANT CONNECT ON DATABASE mytrader_dev TO mytrader_app;
    GRANT USAGE ON SCHEMA public TO mytrader_app;

    -- Permissões em tabelas existentes (CRUD)
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO mytrader_app;

    -- Permissões em sequências (para SERIAL/IDENTITY/auto-increment)
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO mytrader_app;

    -- Permissões futuras (para tabelas criadas depois - importante para migrations)
    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO mytrader_app;

    ALTER DEFAULT PRIVILEGES IN SCHEMA public
        GRANT USAGE, SELECT ON SEQUENCES TO mytrader_app;

    -- Permitir criação de tabelas (necessário para migrations)
    GRANT CREATE ON SCHEMA public TO mytrader_app;

    -- =====================================================
    -- PERMISSIONS: mytrader_readonly (Read-Only User)
    -- =====================================================

    -- Grant permissões apenas de leitura APENAS no database da aplicação
    GRANT CONNECT ON DATABASE mytrader_dev TO mytrader_readonly;
    GRANT USAGE ON SCHEMA public TO mytrader_readonly;

    -- Apenas SELECT em todas as tabelas
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO mytrader_readonly;

    -- Permissões futuras
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
echo "  ⚠️  NEVER use in application connection string"
echo ""
echo "USER: mytrader_app (APPLICATION)"
echo "  Purpose: Main application"
echo "  Permissions: CRUD + CREATE TABLE"
echo "  ✓ Can: SELECT, INSERT, UPDATE, DELETE, CREATE TABLE"
echo "  ✗ Cannot: DROP DATABASE, CREATE ROLE, ALTER SYSTEM"
echo "  ✗ Cannot: Connect to template0, template1, postgres"
echo ""
echo "USER: mytrader_readonly (READ-ONLY)"
echo "  Purpose: Analytics, Reports, Backups"
echo "  Permissions: SELECT only"
echo "  ✓ Can: SELECT"
echo "  ✗ Cannot: INSERT, UPDATE, DELETE, CREATE"
echo "  ✗ Cannot: Connect to template0, template1, postgres"
echo ""
echo "================================================="
echo "Setup completed successfully!"
echo "================================================="
echo ""

# List created users (for verification)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "mytrader_dev" -c "\du"
