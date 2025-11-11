-- =====================================================
-- Migration: 002_update_production_passwords.sql
-- Description: Atualiza senhas dos usuários da aplicação em staging/production
-- Security: Multi-Environment Password Strategy
-- Project: myTraderGEO
-- Author: DBA Agent
-- Date: 2025-01-28
-- Updated: 2025-01-10 - Added postgres superuser option
-- =====================================================
--
-- IMPORTANTE: Este script deve ser executado MANUALMENTE em staging e production
-- NUNCA commitar senhas reais no Git!
--
-- EXECUÇÃO:
-- Este script usa variáveis do psql para receber senhas via CLI.
-- As senhas são passadas como parâmetros e NUNCA ficam no histórico de comandos
-- se usar variáveis de ambiente.
--
-- COMO EXECUTAR:
--
-- Opção 1: Via variáveis de ambiente - Application Users Only (RECOMENDADO - mais seguro)
-- ----------------------------------------------------------------------------------------
-- export DB_APP_PASSWORD="sua_senha_forte_aqui"
-- export DB_READONLY_PASSWORD="sua_senha_readonly_aqui"
--
-- psql -U postgres -d mytrader_staging -f 002_update_production_passwords.sql \
--   -v app_password="$DB_APP_PASSWORD" \
--   -v readonly_password="$DB_READONLY_PASSWORD"
--
-- Opção 1b: Incluindo Postgres Superuser (OPCIONAL)
-- --------------------------------------------------
-- export DB_PASSWORD="sua_senha_postgres_super_forte"
-- export DB_APP_PASSWORD="sua_senha_forte_aqui"
-- export DB_READONLY_PASSWORD="sua_senha_readonly_aqui"
--
-- psql -U postgres -d mytrader_staging -f 002_update_production_passwords.sql \
--   -v postgres_password="$DB_PASSWORD" \
--   -v app_password="$DB_APP_PASSWORD" \
--   -v readonly_password="$DB_READONLY_PASSWORD"
--
-- NOTE: Uncomment the postgres password update section below if needed
--
-- Opção 2: Via prompt interativo (senhas não aparecem no histórico)
-- -----------------------------------------------------------------
-- psql -U postgres -d mytrader_staging
-- \set app_password `read -s -p "App Password: " pwd; echo $pwd`
-- \set readonly_password `read -s -p "Readonly Password: " pwd; echo $pwd`
-- \i 002_update_production_passwords.sql
--
-- Opção 3: Via linha de comando (CUIDADO - fica no histórico bash!)
-- -----------------------------------------------------------------
-- psql -U postgres -d mytrader_staging -f 002_update_production_passwords.sql \
--   -v app_password='SuaSenhaForte123!' \
--   -v readonly_password='SuaSenhaReadonly456!'
--
-- =====================================================
-- SEGURANÇA:
-- - Use senhas FORTES (16+ caracteres, maiúsculas, minúsculas, números, símbolos)
-- - DIFERENTES entre staging e production
-- - Armazene senhas em gerenciador de senhas (1Password, Bitwarden, etc)
-- - Configure rotação de senhas (trimestral recomendado)
-- - NUNCA commite senhas reais no Git
-- =====================================================

\echo '================================================='
\echo 'Updating production passwords for myTraderGEO'
\echo '================================================='
\echo ''

-- Verificar se variáveis foram passadas
DO $$
BEGIN
    IF :'app_password' = ':app_password' THEN
        RAISE EXCEPTION 'Variable app_password not set. See script header for usage instructions.';
    END IF;

    IF :'readonly_password' = ':readonly_password' THEN
        RAISE EXCEPTION 'Variable readonly_password not set. See script header for usage instructions.';
    END IF;
END $$;

\echo 'Variables validated ✓'
\echo ''

-- =====================================================
-- OPTIONAL: UPDATE PASSWORD: postgres (Superuser)
-- =====================================================
-- Uncomment the lines below if you want to update the postgres superuser password
-- Make sure you passed -v postgres_password="..." when executing this script
--
-- \echo 'Updating password for user: postgres (SUPERUSER)'
-- ALTER USER postgres WITH PASSWORD :'postgres_password';
-- \echo '✓ Password updated for postgres (SUPERUSER)'
-- \echo ''
-- \echo '⚠️  WARNING: After updating postgres password, you must:'
-- \echo '  1. Update POSTGRES_PASSWORD in .env file (on server)'
-- \echo '  2. Restart database container: docker compose restart database'
-- \echo '  3. Update any backup scripts that use postgres user'
-- \echo ''

-- =====================================================
-- UPDATE PASSWORD: mytrader_app
-- =====================================================

\echo 'Updating password for user: mytrader_app'

-- Usar prepared statement para evitar SQL injection
-- e garantir que senha é tratada corretamente
ALTER USER mytrader_app WITH PASSWORD :'app_password';

\echo '✓ Password updated for mytrader_app'
\echo ''

-- =====================================================
-- UPDATE PASSWORD: mytrader_readonly
-- =====================================================

\echo 'Updating password for user: mytrader_readonly'

ALTER USER mytrader_readonly WITH PASSWORD :'readonly_password';

\echo '✓ Password updated for mytrader_readonly'
\echo ''

-- =====================================================
-- VERIFICATION
-- =====================================================

\echo '================================================='
\echo 'Password Update Summary'
\echo '================================================='
\echo ''
\echo 'Users updated:'
\echo '  - mytrader_app: Password changed ✓'
\echo '  - mytrader_readonly: Password changed ✓'
\echo ''
\echo 'Next steps:'
\echo '  1. Update .env.staging or .env.production with new passwords'
\echo '  2. Update connection strings in Docker Compose'
\echo '  3. Restart application containers'
\echo '  4. Test database connectivity'
\echo '  5. Document password change in password manager'
\echo ''
\echo '================================================='
\echo 'Migration completed successfully!'
\echo '================================================='

-- Listar informações dos usuários (sem mostrar senhas)
\echo ''
\echo 'Current user information:'
SELECT
    usename AS username,
    CASE
        WHEN usesuper THEN 'Yes'
        ELSE 'No'
    END AS is_superuser,
    CASE
        WHEN usecreatedb THEN 'Yes'
        ELSE 'No'
    END AS can_create_db,
    valuntil AS password_expiration
FROM pg_user
WHERE usename IN ('mytrader_app', 'mytrader_readonly')
ORDER BY usename;
