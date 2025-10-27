-- =====================================================
-- Init Script: 01-create-app-user.sql
-- Description: Cria usuários dedicados para a aplicação
-- Security: Princípio do Menor Privilégio (Least Privilege)
-- Project: myTraderGEO
-- Author: DBA Agent
-- Date: 2025-10-26
-- =====================================================
--
-- Este script é executado automaticamente pelo PostgreSQL
-- na inicialização do container (via /docker-entrypoint-initdb.d/)
--
-- IMPORTANTE: Apenas executado na PRIMEIRA inicialização
-- (quando o volume do PostgreSQL está vazio)
--
-- SECURITY NOTE:
-- - NUNCA usar o usuário 'postgres' (superuser) na aplicação
-- - Usar 'mytrader_app' para a aplicação .NET
-- - Usar 'mytrader_readonly' para analytics/backups
-- =====================================================

-- Conectar ao database da aplicação
\c mytrader_dev;

\echo '================================================='
\echo 'Creating application users for myTraderGEO'
\echo '================================================='

-- =====================================================
-- USER 1: mytrader_app (Application User)
-- Purpose: Main application database user
-- Permissions: CRUD + CREATE TABLE (for EF Core migrations)
-- =====================================================

DO
$$
BEGIN
    -- Criar usuário para aplicação (development)
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'mytrader_app') THEN
        CREATE USER mytrader_app WITH
            PASSWORD 'app_dev_password_123'
            NOCREATEDB
            NOCREATEROLE
            NOSUPERUSER;
        RAISE NOTICE '✓ User mytrader_app created successfully';
    ELSE
        RAISE NOTICE '! User mytrader_app already exists';
    END IF;
END
$$;

-- Grant permissões no database
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

-- Permitir criação de tabelas (necessário para EF Core migrations)
GRANT CREATE ON SCHEMA public TO mytrader_app;

\echo '✓ Permissions granted to mytrader_app:'
\echo '  - CONNECT on database'
\echo '  - SELECT, INSERT, UPDATE, DELETE on tables'
\echo '  - USAGE, SELECT on sequences'
\echo '  - CREATE TABLE (for migrations)'

-- =====================================================
-- USER 2: mytrader_readonly (Read-Only User)
-- Purpose: Analytics, Reports, Backups
-- Permissions: SELECT only
-- =====================================================

DO
$$
BEGIN
    -- Criar usuário read-only
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'mytrader_readonly') THEN
        CREATE USER mytrader_readonly WITH
            PASSWORD 'readonly_dev_password_123'
            NOCREATEDB
            NOCREATEROLE
            NOSUPERUSER;
        RAISE NOTICE '✓ User mytrader_readonly created successfully';
    ELSE
        RAISE NOTICE '! User mytrader_readonly already exists';
    END IF;
END
$$;

-- Grant permissões apenas de leitura
GRANT CONNECT ON DATABASE mytrader_dev TO mytrader_readonly;
GRANT USAGE ON SCHEMA public TO mytrader_readonly;

-- Apenas SELECT em todas as tabelas
GRANT SELECT ON ALL TABLES IN SCHEMA public TO mytrader_readonly;

-- Permissões futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO mytrader_readonly;

\echo '✓ Read-only permissions granted to mytrader_readonly:'
\echo '  - CONNECT on database'
\echo '  - SELECT on tables (read-only)'

-- =====================================================
-- SECURITY SUMMARY
-- =====================================================

\echo ''
\echo '================================================='
\echo 'SECURITY SUMMARY - PostgreSQL Users'
\echo '================================================='
\echo ''
\echo 'USER: postgres (SUPERUSER)'
\echo '  Purpose: Database administration ONLY'
\echo '  Usage: Manual DBA tasks, troubleshooting'
\echo '  ⚠️  NEVER use in application connection string'
\echo ''
\echo 'USER: mytrader_app (APPLICATION)'
\echo '  Purpose: Main .NET application'
\echo '  Permissions: CRUD + CREATE TABLE'
\echo '  ✓ Can: SELECT, INSERT, UPDATE, DELETE, CREATE TABLE'
\echo '  ✗ Cannot: DROP DATABASE, CREATE ROLE, ALTER SYSTEM'
\echo ''
\echo 'USER: mytrader_readonly (READ-ONLY)'
\echo '  Purpose: Analytics, Reports, Backups'
\echo '  Permissions: SELECT only'
\echo '  ✓ Can: SELECT'
\echo '  ✗ Cannot: INSERT, UPDATE, DELETE, CREATE'
\echo ''
\echo '================================================='
\echo 'Setup completed successfully!'
\echo '================================================='
\echo ''

-- Listar usuários criados (para verificação)
\du
