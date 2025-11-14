<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)  
- Use blank lines between sections for readability (content)  
- Validate in Markdown preview before committing  
-->

# 04-database - Database Scripts & Migrations

**Projeto:** {PROJECT_NAME}  
**Database:** PostgreSQL 15+  
**Responsible Agent:** DBA Agent  

---

## About This Document

This is a **quick reference guide** for executing database migrations and managing database users. For strategic decisions, database design details, and trade-offs, consult [DBA-01-{EpicName}-Database-Design-Decisions.md](../00-doc-ddd/05-database-design/DBA-01-{EpicName}-Database-Design-Decisions.md).

**Document Separation:**
- **This README:** Commands and checklists (HOW to execute)
- **DBA-01:** Design decisions, justifications, and trade-offs (WHY and WHAT)

**Principle:** README is an INDEX/QUICK-REFERENCE to DBA-01, not a duplicate.

---

## Primary Key Selection Criteria (Quick Reference)

For detailed analysis, see [DBA-01-{EpicName}-Schema-Review.md § Primary Key Strategy](../00-doc-ddd/05-database-design/DBA-01-{EpicName}-Schema-Review.md#-primary-key-strategy).

### Quick Decision Matrix

| Table Type | Use UUID | Use INT/SERIAL |
|------------|----------|----------------|
| **Aggregate root exposed in API** (Users, Orders) | ✅ | ❌ |
| **Lookup table** (<100 rows: SubscriptionPlans, Categories) | ❌ | ✅ |
| **High-volume transactional** (>100k rows: AuditLog) | ✅ | ❌ |
| **High join frequency** (>5 joins/query) | ❌ | ✅ |
| **Security-sensitive** (prevent enumeration attacks) | ✅ | ❌ |
| **Internal-only** (not exposed in API) | ⚠️ | ✅ |

**Examples:**
- **UUID:** Users (API-exposed, security), Orders (high-volume), Transactions (distributed)
- **INT/SERIAL:** SubscriptionPlans (lookup, 3-5 rows), Categories (lookup, <100 rows)

**Trade-offs:**
- UUID: 16 bytes (4x larger storage), slower joins, non-enumerable (security+)
- INT/SERIAL: 4 bytes (compact), faster joins, enumerable (security-)

**See full decision tree, migration paths, and best practices in DBA-01.**

---

## Índice

- [About This Document](#about-this-document)
- [Directory Structure](#directory-structure)
- [PostgreSQL Users (Least Privilege)](#postgresql-users-least-privilege)
- [Multi-Environment Password Strategy](#multi-environment-password-strategy)
- [Security Best Practices](#security-best-practices)
- [How to Execute Migrations](#how-to-execute-migrations)
- [Quick Start for Software Engineers](#quick-start-for-software-engineers-se)
- [Validation and Testing](#validation-and-testing)
- [EF Core Scaffolding Reference](#ef-core-scaffolding-reference-quick)
- [Migration Status](#migration-status)
- [Related Artifacts](#related-artifacts)
- [References](#references)
- [Troubleshooting](#troubleshooting)

---

> **💻 Comandos otimizados para PowerShell (Windows)**

---

## Directory Structure

```
04-database/
├── init-scripts/       # Scripts executed on FIRST container initialization
│   ├── 00-init-users.sh               # Creates users with env-based passwords
│   └── 01-create-app-user.sql.backup  # Legacy (for reference only)
├── migrations/         # Schema migrations (tables, indexes, constraints)
│   ├── 000_*.sql       # Maintenance utilities (password rotation, etc)
│   ├── 001_*.sql       # Schema creation (tables, indexes, constraints)
│   └── 002_*.sql       # Schema updates (subsequent epics)
├── scripts/            # Utility scripts
│   └── rotate-passwords.sh  # Password rotation wrapper (reads .env file)
├── seeds/              # Initial data (plans, config, demo users)
│   └── 001_seed_{epic_name}_defaults.sql
└── README.md           # This file
```

### Directory Description

| Directory | When Executes | Purpose | Idempotent? |
|-----------|---------------|---------|-------------|
| **init-scripts/** | **Only on first initialization** (empty volume) | Create database users, security configurations | ✅ Yes (uses `IF NOT EXISTS`) |
| **migrations/** | Manually by DBA or CI/CD (each schema change) | Create/alter tables, indexes, constraints | ⚠️ Depends (use transactions) |
| **scripts/** | On-demand (maintenance tasks) | Utility wrappers for common operations (password rotation) | ✅ Yes |
| **seeds/** | Manually by DBA after migrations | Populate initial data (plans, config, demos) | ✅ Yes (uses `ON CONFLICT DO NOTHING`) |

---

## PostgreSQL Users (Least Privilege)

### Security Principle

**⚠️ NEVER use the `postgres` (superuser) user in the application!**

The application should use dedicated users with limited permissions, following the **Principle of Least Privilege**.

### Available Users

| User | Purpose | Permissions | Usage |
|------|---------|------------|-------|
| **postgres** | Database administration | **SUPERUSER** (all privileges) | **DBA ONLY** - Administrative tasks, troubleshooting |
| **{project}_app** | .NET Application | - SELECT, INSERT, UPDATE, DELETE (CRUD)<br>- USAGE on sequences<br>- CREATE TABLE (EF Core migrations)<br>- **Limited to database `{project}_dev`** | **Application connection string** |
| **{project}_readonly** | Analytics, Reports, Backups | - SELECT only<br>- **Limited to database `{project}_dev`** | BI tools, backups, read-only analytics |

### Security Benefits

✅ **SQL Injection Mitigated:** Even if attacker gains access via SQL injection:
- ❌ CANNOT drop databases (`DROP DATABASE` blocked)  
- ❌ CANNOT create superusers (`CREATE ROLE` blocked)  
- ❌ CANNOT access system databases (`template0`, `template1`, `postgres`)  
- ❌ CANNOT execute administrative commands (`ALTER SYSTEM`)  

✅ **Defense in Depth:** Bug in application cannot cause catastrophic damage (limited to CRUD operations)

✅ **Audit Trail:** Clear separation between application actions vs administrative actions in logs

✅ **Compliance:** Meets LGPD Art. 46 (technical measures), SOC2/ISO27001 (RBAC)

### Connection Strings

```yaml
# ❌ INSECURE (NEVER DO THIS):
ConnectionStrings__DefaultConnection=Host=database;Port=5432;Database={project}_dev;Username=postgres;Password=xxx

# ✅ SECURE (CORRECT):
ConnectionStrings__DefaultConnection=Host=database;Port=5432;Database={project}_dev;Username={project}_app;Password=xxx

# ✅ READ-ONLY (Analytics, Backups):
ConnectionStrings__ReadOnlyConnection=Host=database;Port=5432;Database={project}_dev;Username={project}_readonly;Password=xxx
```

### How Users Are Created

Users are created automatically by the script:

**File:** [init-scripts/00-init-users.sh](init-scripts/00-init-users.sh)

**Execution:** Automatic on first PostgreSQL container initialization via `/docker-entrypoint-initdb.d/`

**Idempotency:** ✅ Yes (uses `IF NOT EXISTS` - safe to re-execute)

**Passwords:** Read from Docker environment variables (`$DB_APP_PASSWORD`, `$DB_READONLY_PASSWORD`)

> **Note:** This unified script contains both CREATE USER and GRANT statements in a single file for easier maintenance. The passwords come from `.env` files passed via docker-compose environment variables.  

---

## Multi-Environment Password Strategy

### Security Principle

**⚠️ NEVER hardcode passwords in code or commit production passwords to Git!**

All environments use `.env` files for password management. Development uses simple passwords (committed), while staging/production use strong passwords (created on server, NEVER committed).

### Password Requirements by Environment

| Environment | Password Complexity | Rotation Frequency | Git Status | Example |
|-------------|---------------------|-------------------|-----------|---------|
| **Development** | Simple (local_app_123) | ❌ No rotation | ✅ Committed (.env.dev) | `DB_APP_PASSWORD=local_app_123` |
| **Staging** | Strong (16+ chars, mixed case, numbers, symbols) | Semi-annual | ❌ NOT committed (.env.staging) | `DB_APP_PASSWORD=St@g!ng_SecureP@ss2025!#` |
| **Production** | Very Strong (20+ chars, mixed case, numbers, symbols) | Quarterly | ❌ NOT committed (.env.prod) | `DB_APP_PASSWORD=Pr0d_V3ry$trong#P@ssw0rd2025!` |

### Implementation Pattern: Environment-Based Passwords

**Principle:** ALL environments use the same architecture - passwords come from `.env` files via Docker environment variables.

**Flow:**
1. `.env` file defines passwords → Docker Compose loads them → Database init script reads from environment

#### All Environments: Init Script

**File:** [init-scripts/00-init-users.sh](init-scripts/00-init-users.sh)

```bash
#!/bin/bash
# Passwords come from Docker environment variables
# These are set via docker-compose from .env files

psql <<-EOSQL
    CREATE USER {project}_app WITH PASSWORD '$DB_APP_PASSWORD';
    CREATE USER {project}_readonly WITH PASSWORD '$DB_READONLY_PASSWORD';

    -- Grant permissions...
EOSQL
```

**How it works:**
- **Development:** `docker-compose.dev.yml` reads `.env.dev` (committed with simple passwords)
- **Staging:** `docker-compose.staging.yml` reads `.env.staging` (created on server, strong passwords)
- **Production:** `docker-compose.prod.yml` reads `.env.prod` (created on server, very strong passwords)

**Execution:** Automatic on FIRST PostgreSQL container initialization only

---

### Password Rotation (For Running Databases)

For databases that are already initialized and running, you can rotate passwords using two methods:

#### Option A: Shell Wrapper (Recommended - Reads .env)

**File:** [scripts/rotate-passwords.sh](scripts/rotate-passwords.sh)

**Benefits:**
- ✅ **Security:** Passwords not exposed in bash history or process list
- ✅ **Convenience:** Reads credentials directly from .env file
- ✅ **Validation:** Checks for required variables and confirms before execution

```bash
# Local (development)
./scripts/rotate-passwords.sh .env.dev

# Remote (staging/production - after SSH)
./scripts/rotate-passwords.sh .env.staging
```

**Script features:**
- Parses .env file safely (ignores comments, empty lines)
- Validates required variables (DB_APP_PASSWORD, DB_READONLY_PASSWORD)
- Confirmation prompt before execution
- Colored output for better readability
- Logs execution to `/tmp/rotate-passwords.log`

---

#### Option B: SQL Script Directly (Manual)

**File:** [migrations/000_update_passwords.sql](migrations/000_update_passwords.sql)

**Use when:** Shell wrapper not available or you prefer manual control.

```bash
# Export passwords from .env or set manually
export DB_APP_PASSWORD="St@g!ng_SecureP@ss2025!#"
export DB_READONLY_PASSWORD="St@g!ng_ReadOnly2025!#"

# Execute maintenance script
psql -h $DB_HOST -U postgres -d {project}_dev \
  -v app_password="$DB_APP_PASSWORD" \
  -v readonly_password="$DB_READONLY_PASSWORD" \
  -f migrations/000_update_passwords.sql
```

**After password update (both options):**
1. Update `.env` file on server with new passwords (if rotated)
2. Restart API container: `docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev restart api`
3. Verify: `docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev logs api | grep "Database connection"`
4. Document: `echo "$(date) - Password rotated" >> password-rotation.log`

---

### Remote Database Access (Staging/Production)

**Security Principle:** PostgreSQL port 5432 is NOT exposed to the internet in staging/production environments. Access is only possible via SSH + Docker.

#### Recommended Access Method:

```bash
# 1. SSH into the server
ssh {project}@{project}-stage  # or {project}-prod

# 2. Navigate to application directory
cd ~/{project}-app/app

# 3. Access database via docker compose exec
docker compose exec database psql -U postgres -d {project}_staging

# 4. Or rotate passwords using the wrapper
./04-database/scripts/rotate-passwords.sh .env.staging
```

#### Why Port 5432 is Not Exposed:

| Environment | Port 5432 Status | Reasoning |
|-------------|-----------------|-----------|
| **Development** | ✅ Exposed (5432:5432) | Convenience for local development tools (pgAdmin, IDE plugins) |
| **Staging** | ❌ Not exposed | Security - reduces attack surface, only internal containers can access |
| **Production** | ❌ Not exposed | Security - CRITICAL for production, prevents external SQL injection attempts |

**Network Architecture:**
- Database is on internal Docker network only
- API container connects via internal network (`database:5432`)
- External access ONLY via SSH + docker exec (requires server access)

**For emergency access or troubleshooting:**
```bash
# SSH tunnel (if port exposure is temporarily needed for tools like pgAdmin)
ssh -L 5432:localhost:5432 {project}@{project}-stage
# Then connect locally to localhost:5432 with pgAdmin/DBeaver
# IMPORTANT: Close tunnel immediately after use
```

### Password Generation

**Staging/Production (Strong Passwords):**

```bash
# Generate 20-character strong password
openssl rand -base64 20 | tr -d "=+/" | cut -c1-20

# Generate 32-character very strong password (production)
openssl rand -base64 32 | tr -d "=+/" | cut -c1-32

# Or use pwgen (if installed)
pwgen -s 20 1  # Staging
pwgen -s 32 1  # Production
```

**Add to .env.staging or .env.production (on server ONLY):**

```bash
# Database credentials (NEVER commit to Git!)
DB_APP_PASSWORD=[GENERATED_STRONG_PASSWORD]
DB_READONLY_PASSWORD=[GENERATED_STRONG_PASSWORD]
```

### Password Rotation Procedure

**When:** Quarterly (production), Semi-annual (staging)  

**Steps:**

1. **Generate new password:**
   ```bash
   NEW_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
   echo "New password: $NEW_PASSWORD"
   ```

2. **Update .env file on server:**
   ```bash
   # SSH to server
   ssh {project}_app@{project}-prod

   # Edit .env.production
   nano ~/./{project}/.env.production
   # Update: DB_APP_PASSWORD=[NEW_PASSWORD]
   ```

3. **Update database password:**
   ```bash
   export DB_APP_PASSWORD="[NEW_PASSWORD]"
   psql -h localhost -U postgres -d {project}_dev \
     -v app_password="$DB_APP_PASSWORD" \
     -f migrations/000_update_passwords.sql
   ```

4. **Restart application:**
   ```bash
   docker compose -f docker-compose.prod.yml \
     --env-file .env.production restart api
   ```

5. **Verify connection:**
   ```bash
   docker compose -f docker-compose.prod.yml \
     --env-file .env.production logs api | grep "Database connection successful"
   ```

6. **Document rotation in logs:**
   ```bash
   echo "$(date '+%Y-%m-%d %H:%M:%S') - Database password rotated (production)" >> password-rotation.log
   ```

---

## Security Best Practices

### 1. Least Privilege Access

**Principle:** Grant only the minimum permissions necessary for each user.  

**Implementation:**

```sql
-- ✅ GOOD: Application user with limited permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO {project}_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO {project}_app;
GRANT CREATE ON SCHEMA public TO {project}_app;  -- For EF Core migrations

-- ✅ GOOD: Read-only user for analytics
GRANT SELECT ON ALL TABLES IN SCHEMA public TO {project}_readonly;

-- ❌ BAD: Superuser for application (NEVER DO THIS!)
ALTER USER {project}_app WITH SUPERUSER;  -- ❌ DO NOT DO THIS!
```

**Security Benefits:**
- ✅ SQL injection attacks limited to CRUD operations  
- ✅ Cannot DROP DATABASE or CREATE ROLE  
- ✅ Cannot access other databases  
- ✅ Defense in depth (limits damage from application bugs)  

---

### 2. Encryption at Rest

**Principle:** Sensitive data should be encrypted in the database.  

**Implementation:**

**Transparent Data Encryption (PostgreSQL 15+):**

```sql
-- Enable pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypt sensitive columns
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    cpf_encrypted BYTEA,  -- Encrypted CPF
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert with encryption (AES-256)
INSERT INTO users (email, cpf_encrypted)
VALUES (
    'user@example.com',
    pgp_sym_encrypt('123.456.789-00', current_setting('app.encryption_key'))
);

-- Query with decryption
SELECT
    email,
    pgp_sym_decrypt(cpf_encrypted, current_setting('app.encryption_key')) AS cpf
FROM users;
```

**Configuration (in .env):**

```bash
# Encryption key (32 characters minimum, NEVER commit to Git!)
DB_ENCRYPTION_KEY=[GENERATED_STRONG_KEY_32_CHARS]
```

**Security Benefits:**
- ✅ Compliance with LGPD Art. 46 (technical measures for personal data protection)  
- ✅ Protection against database file theft  
- ✅ Audit trail for decryption operations  

---

### 3. Password Rotation

**Policy:**

| Environment | Rotation Frequency | Responsibility | Automated? |
|-------------|-------------------|----------------|------------|
| **Development** | ❌ Never | N/A | N/A |
| **Staging** | Semi-annual (6 months) | DBA / DevOps | ⚠️ Manual |
| **Production** | Quarterly (3 months) | DBA / Security Team | ⚠️ Manual |

**Procedure:** See [Password Rotation Procedure](#password-rotation-procedure) above  

---

### 4. Compliance

**Regulations:**

| Regulation | Requirement | Implementation |
|------------|-------------|----------------|
| **LGPD Art. 46** | Technical measures to protect personal data | ✅ Least privilege, encryption at rest, password rotation |
| **SOC2** | Role-based access control (RBAC) | ✅ Separate users ({project}_app, {project}_readonly) |
| **ISO 27001** | Access control policy | ✅ Documented user permissions, audit logs |

**Evidence for Audits:**

1. **User segregation:** [01-create-app-user.sql](init-scripts/01-create-app-user.sql)
2. **Password rotation logs:** [password-rotation.log](password-rotation.log)
3. **Encryption implementation:** [migrations/003_encrypt_sensitive_columns.sql](migrations/003_encrypt_sensitive_columns.sql)
4. **Security baseline:** [SEC-00-Security-Baseline.md](../00-doc-ddd/09-security/SEC-00-Security-Baseline.md)

---

### 5. Audit Logging

**Principle:** Log all administrative actions for security audits.  

**Implementation (PostgreSQL Audit Extension):**

```sql
-- Enable pgaudit extension
CREATE EXTENSION IF NOT EXISTS pgaudit;

-- Configure audit logging
ALTER SYSTEM SET pgaudit.log = 'write, ddl';
ALTER SYSTEM SET pgaudit.log_catalog = off;
SELECT pg_reload_conf();

-- Verify audit logs
SELECT * FROM pg_stat_statements WHERE query LIKE '%ALTER USER%';
```

**Configuration (postgresql.conf or docker-compose):**

```yaml
# docker-compose.yml
database:
  image: postgres:15-alpine
  command:
    - "postgres"  
    - "-c"  
    - "pgaudit.log=write,ddl"  
  environment:
    - POSTGRES_DB={project}_dev  
```

**Audit Log Location:**

- **Docker:** `docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev logs database | grep AUDIT`
- **Server:** `/var/log/postgresql/postgresql-15-main.log`  

**Compliance Benefits:**
- ✅ SOC2: Audit trail for all database changes  
- ✅ ISO 27001: Monitoring and logging requirement  
- ✅ LGPD: Evidence of technical measures for data protection  

---

### 6. Security Checklist

Use this checklist during Discovery and per-epic security reviews:

#### Discovery Phase (DBA-00)

- [ ] Database users created with least privilege ([00-init-users.sh](init-scripts/00-init-users.sh))
- [ ] Development passwords committed to Git (safe defaults)
- [ ] Staging/production passwords documented (NOT committed)
- [ ] Password rotation utility created ([000_update_passwords.sql](migrations/000_update_passwords.sql))
- [ ] Password rotation procedure documented (this README)  
- [ ] Encryption at rest configured (pgcrypto extension)  
- [ ] Audit logging enabled (pgaudit extension)  

#### Per Epic (DBA-01-{EpicName})

- [ ] Sensitive columns identified (CPF, email, payment data)  
- [ ] Encryption implemented for sensitive data  
- [ ] Migration scripts use transactions (BEGIN/COMMIT/ROLLBACK)  
- [ ] Seed data does NOT contain real personal data  
- [ ] Query performance estimated (<100ms for critical queries)  
- [ ] Indexes created for critical queries (documented in DBA-01)  

#### Staging/Production Deployment

- [ ] ALTER USER migration executed (staging/production ONLY)  
- [ ] Strong passwords set (16+ staging, 20+ production)  
- [ ] Connection string updated in .env (on server)  
- [ ] Application restarted and verified  
- [ ] Password rotation scheduled (calendar reminder)  
- [ ] Audit logs reviewed (no unauthorized access)  

---

## How to Execute Migrations

### Correct Execution Order

**IMPORTANT**: Execute in this order to avoid permission issues:

```powershell
# 1. Start database (init-scripts create users and permissions)
docker compose -f 05-infra/docker/docker-compose.dev.yml `
  --env-file 05-infra/configs/.env.dev up database -d

# 2. Verify users were created
docker compose -f 05-infra/docker/docker-compose.dev.yml `
  --env-file 05-infra/configs/.env.dev `
  logs database | Select-String "Creating application users"

# 3. Execute migrations as {project}_app
docker compose -f 05-infra/docker/docker-compose.dev.yml `
  --env-file 05-infra/configs/.env.dev `
  exec database psql -U {project}_app -d {project}_dev `
  -f /db-scripts/migrations/001_create_{epic_name}_schema.sql

# 4. Execute seeds
docker compose -f 05-infra/docker/docker-compose.dev.yml `
  --env-file 05-infra/configs/.env.dev `
  exec database psql -U {project}_app -d {project}_dev `
  -f /db-scripts/seeds/001_seed_{epic_name}_defaults.sql
```

### Como Funciona: ALTER DEFAULT PRIVILEGES FOR ROLE

**Pergunta:** Como `{project}_readonly` recebe permissões automáticas em tabelas criadas por `{project}_app`?

**Resposta:** O init script configura `ALTER DEFAULT PRIVILEGES FOR ROLE {project}_app`:

```sql
-- No init script (00-init-users.sh):
ALTER DEFAULT PRIVILEGES FOR ROLE {project}_app IN SCHEMA public
    GRANT SELECT ON TABLES TO {project}_readonly;
```

**O que isso faz:**
- Quando `{project}_app` **cria uma tabela**, PostgreSQL **automaticamente** concede SELECT para `{project}_readonly`
- Funciona para migrations executadas como `{project}_app`
- Não precisa mais usar `postgres` para migrations!

**Diferença entre com e sem FOR ROLE:**
- ❌ `ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT...` → Só funciona para tabelas criadas por quem executou o comando (postgres)
- ✅ `ALTER DEFAULT PRIVILEGES FOR ROLE {project}_app IN SCHEMA public GRANT SELECT...` → Funciona para tabelas criadas por `{project}_app`

### Fix Permissions (Apenas se Necessário)

Se você tem tabelas antigas criadas ANTES do init script com `FOR ROLE`, conceda manualmente:

```powershell
# Fix permissions manually for existing tables
docker compose -f 05-infra/docker/docker-compose.dev.yml `
  --env-file 05-infra/configs/.env.dev `
  exec database psql -U postgres -d {project}_dev -c `
  "GRANT SELECT ON ALL TABLES IN SCHEMA public TO {project}_readonly;"
```

### Staging/Production

```powershell
# On server (after SSH)
docker compose exec database psql -U {project}_app -d {project}_staging `
  -f /db-scripts/migrations/001_create_{epic_name}_schema.sql

docker compose exec database psql -U $DB_APP_USER -d {project}_staging `
  -f /db-scripts/seeds/001_seed_{epic_name}_defaults.sql
```

### Rollback Strategy

```sql
-- Rollback migrations (REVERSE order of creation)
-- WARNING: This will DROP ALL data!

-- 1. Drop tables from {Epic_Name} BC
DROP TABLE IF EXISTS {Table1} CASCADE;
DROP TABLE IF EXISTS {Table2} CASCADE;
DROP TABLE IF EXISTS {Table3} CASCADE;
```

---


### 📝 Command Notation

Throughout this document:
- **Full form** used when starting containers or first mention in section
- **Abbreviated form** used when context is clear (container already running)
- **Remote commands** (after SSH) always use abbreviated form

**Local Development:**
```powershell
# Full form (starting containers)
docker compose -f 05-infra/docker/docker-compose.dev.yml `
  --env-file 05-infra/configs/.env.dev up database -d

# Abbreviated form (database already running)
docker compose exec database psql -U {project}_app -d {project}_dev
```

**Remote (After SSH):**
```bash
# Always abbreviated (you're in app directory)
docker compose exec database psql -U postgres -d {project}_staging
```


## Quick Start for Software Engineers (SE)

**⚠️ Database-First Approach:** DBA creates SQL migrations FIRST, then SE scaffolds EF Core models from database.

**Important:** This section covers LOCAL DEVELOPMENT. For CI/CD pipelines and GitHub Actions, see [GM-00 - Database Migrations in CI/CD](../07-github-management/GM-00-GitHub-Setup.md#database-migrations-in-cicd-database-first-approach).

### Prerequisites

- ✅ **Docker Desktop** installed and running
- ✅ **.NET 8 SDK** installed
- ✅ **EF Core CLI tools:** `dotnet tool install --global dotnet-ef`
- ✅ **PostgreSQL client** (psql) - included in Docker image

### Step 1: Start PostgreSQL Container

```powershell
# Start database service only
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# Verify container is running
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev ps database
```

### Step 2: Verify Database Connection

```powershell
# Connect to database as application user
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev `
  exec database psql -U {project}_app -d {project}_dev

# Test connection
\dt  # List tables
SELECT current_user;  # Should show: {project}_app
\q   # Exit
```

### Step 3: Apply SQL Migrations (created by DBA)

**Important:** DBA creates migrations FIRST in `04-database/migrations/`. SE only executes them.

```powershell
# Execute migration (example for EPIC-01)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev `
  exec database psql -U {project}_app -d {project}_dev `
  -f /db-scripts/migrations/001_create_{epic_name}_schema.sql

# Verify tables created
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev `
  exec database psql -U {project}_app -d {project}_dev -c "\dt"
```

### Step 4: Scaffold EF Core Models from Database

**Critical:** EF models are GENERATED from database, not created via Code-First migrations.

```powershell
# Navigate to backend project
cd 02-backend

# Scaffold command (generates C# classes from database schema)
dotnet ef dbcontext scaffold `
  "Host=localhost;Database={project}_dev;Username={project}_app;Password=dev_password_123" `
  Npgsql.EntityFrameworkCore.PostgreSQL `
  --output-dir src/Infrastructure/Data/Models `
  --context-dir src/Infrastructure/Data `
  --context ApplicationDbContext `
  --no-onconfiguring `
  --force
```

**For complete documentation, see SE guides:**

<!--
═══════════════════════════════════════════════════════════════════════════════
TODO-SE: Backend Setup and Testing Documentation
═══════════════════════════════════════════════════════════════════════════════

SE Agent should create comprehensive backend development guides:

1. File: 02-backend/docs/SE-Backend-Setup.md
   - Complete EF Core scaffolding reference
   - Connection string management
   - .NET project structure guide
   - Multi-epic scaffolding workflow

2. File: 02-backend/docs/SE-Testing-Guide.md
   - TestContainers setup for PostgreSQL
   - xUnit test fixtures and patterns
   - Database-First testing approach
   - CI/CD integration

3. File: 02-backend/docs/SE-Scaffolding-Strategy.md
   - Partial classes pattern
   - Domain logic separation
   - FluentAPI configurations
   - Managing auto-generated vs custom code

DBA Note: These sections were removed from DBA README to keep it focused on
database operations. SE is responsible for all C# implementation details.
═══════════════════════════════════════════════════════════════════════════════
-->

### Troubleshooting

#### Problem: "Connection refused" when scaffolding

**Solution:** Check container status and verify connection:
```powershell
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev ps database
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev `
  exec database psql -U {project}_app -d {project}_dev -c "SELECT 1"
```

#### Problem: "Password authentication failed"

**Solution:** Development password is always: `dev_password_123` (from `.env.dev`)

#### Problem: "No tables found" when scaffolding

**Solution:** Apply DBA migrations first (Step 3 above)

---


## Validation and Testing

**Prerequisites:** Database container running (see [Quick Start](#quick-start-for-software-engineers-se) above).

**Note:** Commands use abbreviated form (no `-f` or `--env-file` flags) since container is already running.

### Verify Users Created

```bash
# Connect as postgres (admin)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev `
  exec database psql -U postgres -d {project}_dev

# List users
\du

# Expected output:
# postgres            | Superuser, Create role, Create DB
# {project}_app       | Cannot login (limited permissions)
# {project}_readonly  | Cannot login (read-only)
```

### Test {project}_app Permissions

**⚠️ IMPORTANT:** Replace `{Table}` with your actual table names (e.g., Users, Products, Orders).

```sql
-- Connect as {project}_app
\c {project}_dev {project}_app

-- ✅ CRUD should work
-- Replace {Table} and columns with your actual schema
INSERT INTO {Table} (Id, Column1, Column2, Column3)
VALUES (gen_random_uuid(), 'value1', 'value2', 'value3');

SELECT * FROM {Table} WHERE Id = '<some_id>';

UPDATE {Table} SET Column1 = 'new_value' WHERE Id = '<some_id>';

DELETE FROM {Table} WHERE Id = '<some_id>';

-- ✅ CREATE TABLE should work (migrations)
CREATE TABLE test_table (id INT, name TEXT);
DROP TABLE test_table;

-- ❌ Administrative operations should FAIL
DROP DATABASE {project}_dev;        -- ERROR: permission denied
CREATE ROLE hacker;                 -- ERROR: permission denied
\c template1;                       -- ERROR: permission denied
```

### Test {project}_readonly Permissions

```sql
-- Connect as {project}_readonly
\c {project}_dev {project}_readonly

-- ✅ SELECT should work
SELECT * FROM {Table};
SELECT COUNT(*) FROM {Table};

-- ❌ Modifications should FAIL
INSERT INTO {Table} (Id, Column1, Column2)
VALUES (gen_random_uuid(), 'value1', 'value2');
-- ERROR: permission denied for table {Table}

UPDATE {Table} SET Column1 = 'hacked';
-- ERROR: permission denied for table {Table}

DELETE FROM {Table};
-- ERROR: permission denied for table {Table}

-- ❌ DDL operations should FAIL
CREATE TABLE hacker_table (id INT);
-- ERROR: permission denied for schema public
```

### Verify Schema Migrations

```sql
-- List tables created
\dt

-- Expected output:
# {Table1}
# {Table2}
# {Table3}

-- Verify seed data
SELECT * FROM {TableWithSeeds} ORDER BY CreatedAt;
```

---

## EF Core Scaffolding Reference (Quick)

**Database-First Approach:** DBA creates SQL migrations → SE scaffolds EF Core models from PostgreSQL.

### Basic Command

```powershell
cd 02-backend

dotnet ef dbcontext scaffold `
  "Host=localhost;Database={project}_dev;Username={project}_app;Password=dev_password_123" `
  Npgsql.EntityFrameworkCore.PostgreSQL `
  --output-dir src/Infrastructure/Data/Models `
  --context-dir src/Infrastructure/Data `
  --context ApplicationDbContext `
  --no-onconfiguring `
  --force
```

### Key Options

- `--no-onconfiguring`: Don't generate OnConfiguring (use DI instead)
- `--force`: Overwrite existing files (required for subsequent epics)
- `--schema [name]`: Scaffold specific schema only

**For complete scaffolding guide:** See TODO-SE documentation above (02-backend/docs/SE-Backend-Setup.md)

---


## Migration Status

### {EPIC_NAME} - {Epic Description}

| Migration | Status | Date | Description |
|-----------|--------|------|-------------|
| [001_create_{epic_name}_schema.sql](migrations/001_create_{epic_name}_schema.sql) | ⏳ To Create | YYYY-MM-DD | Complete schema: {Table1}, {Table2}, {Table3} |
| [001_seed_{epic_name}_defaults.sql](seeds/001_seed_{epic_name}_defaults.sql) | ⏳ To Create | YYYY-MM-DD | Initial data: {seed description} |

**Note:** [000_update_passwords.sql](migrations/000_update_passwords.sql) is a maintenance utility (not a sequential migration) for password rotation. Use prefix `000_` for non-sequential utilities.

---

## Related Artifacts

This section connects operational README with strategic documentation.

| Artifact | Purpose | When to Consult |
|----------|---------|------------------|
| **[DBA-01-{EpicName}-Database-Design-Decisions.md](../00-doc-ddd/05-database-design/DBA-01-{EpicName}-Database-Design-Decisions.md)** | Architectural database design decisions (Value Objects, indexes, constraints, trade-offs) | To understand **WHY** the schema is modeled this way, evaluate alternatives, modify structure |
| **[FEEDBACK-XXX-DBA-{Topic}.md](../00-doc-ddd/00-feedback/FEEDBACK-XXX-DBA-{Topic}.md)** | Resolutions: {Feedback topic summary} | To understand security implementations, improvements, compliance |
| **[PE-00-Quick-Start.md (local dev) and PE-01-Server-Setup.md (server setup)](../00-doc-ddd/08-platform-engineering/PE-00-Quick-Start.md (local dev) and PE-01-Server-Setup.md (server setup))** | Docker Compose, infrastructure, connection strings per environment | To understand how containers are configured, volume mounts, init-scripts integration |
| **[SEC-00-Security-Baseline.md](../00-doc-ddd/09-security/SEC-00-Security-Baseline.md)** | Security baseline (Database User Segregation section) | To understand security benefits, compliance (LGPD/SOC2), defense in depth strategy |

---

## References

### Internal Documentation

- **Database Design Decisions:** [00-doc-ddd/05-database-design/DBA-01-{EpicName}-Database-Design-Decisions.md](../00-doc-ddd/05-database-design/DBA-01-{EpicName}-Database-Design-Decisions.md)  
  - Modeling decisions (Value Objects, indexes, constraints)  
  - Expected queries and performance estimates  
  - Trade-offs and technical justifications  

- **Platform Engineering Setup:** [00-doc-ddd/08-platform-engineering/PE-00-Quick-Start.md (local dev) and PE-01-Server-Setup.md (server setup)](../00-doc-ddd/08-platform-engineering/PE-00-Quick-Start.md (local dev) and PE-01-Server-Setup.md (server setup))  
  - Docker Compose configuration  
  - Connection strings per environment  
  - Volume mounts and init-scripts  

- **Security Baseline:** [00-doc-ddd/09-security/SEC-00-Security-Baseline.md](../00-doc-ddd/09-security/SEC-00-Security-Baseline.md)  
  - Database User Segregation section  
  - Security benefits documented  

### External Documentation

- **PostgreSQL Documentation:** https://www.postgresql.org/docs/15/  
- **PostgreSQL GRANT Documentation:** https://www.postgresql.org/docs/15/sql-grant.html  
- **PostgreSQL User Management:** https://www.postgresql.org/docs/15/user-manag.html  
- **CIS PostgreSQL Benchmark:** https://www.cisecurity.org/benchmark/postgresql  
  - Section 2.1: Database User Segregation  

---

## Troubleshooting

### Problem: Init script did not execute

**Symptom:** Users `{project}_app` and `{project}_readonly` do not exist  

**Cause:** PostgreSQL volume already existed (init scripts only execute on first time)  

**Solution:**
```bash
# 1. Stop container
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev down

# 2. Remove database volume (⚠️ WARNING: deletes data!)
docker volume rm postgres-data

# 3. Start again (init script will execute)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# 4. Verify logs
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev logs database | grep "Creating application users"
```

### Problem: Permission denied when executing migration

**Symptom:** `ERROR: permission denied for schema public`  

**Cause:** Connected with wrong user or user does not have permissions  

**Solution:**  
```bash
# Check current user
\conninfo

# Connect with {project}_app
\c {project}_dev {project}_app

# If still fails, re-execute init-scripts
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev `
  exec database psql -U postgres -d {project}_dev -f /docker-entrypoint-initdb.d/01-create-app-user.sql
```

### Problem: .NET application cannot connect to database

**Symptom:** `Npgsql.NpgsqlException: password authentication failed for user "{project}_app"`  

**Cause:** Incorrect password in `.env` or connection string  

**Solution:**  
```bash
# 1. Verify connection string in .env
cat 05-infra/configs/.env | grep ConnectionStrings__DefaultConnection

# 2. Should be:
# ConnectionStrings__DefaultConnection=Host=database;Port=5432;Database={project}_dev;Username={project}_app;Password={correct_password}

# 3. If wrong, fix .env and restart application
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev restart api
```

---

**DBA Agent** - {PROJECT_NAME} Database Management
**Last Updated:** {YYYY-MM-DD}  
**Status:** ⏳ {Epic Status}  
