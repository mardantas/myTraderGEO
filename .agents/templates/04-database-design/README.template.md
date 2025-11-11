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

## 📋 About This Document

This is a **quick reference guide** for executing database migrations and managing database users. For strategic decisions, database design details, and trade-offs, consult [DBA-01-{EpicName}-Database-Design-Decisions.md](../00-doc-ddd/05-database-design/DBA-01-{EpicName}-Database-Design-Decisions.md).

**Document Separation:**  
- **This README:** Commands and checklists (HOW to execute)  
- **DBA-01:** Design decisions, justifications, and trade-offs (WHY and WHAT)  

**Principle:** README is an INDEX/QUICK-REFERENCE to DBA-01, not a duplicate.

---

> **💻 Comandos otimizados para PowerShell (Windows)**

---

## 📁 Directory Structure

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

## 🔐 PostgreSQL Users (Least Privilege)

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

## 🔒 Multi-Environment Password Strategy

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
2. Restart API container: `docker compose restart api`
3. Verify: `docker compose logs api | grep "Database connection"`
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

## 🛡️ Security Best Practices

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

- **Docker:** `docker compose logs database | grep AUDIT`  
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

## 🚀 How to Execute Migrations

### ⚠️ Correct Execution Order

**IMPORTANT**: Execute in this order to avoid permission issues:

```powershell
# 1. Start database (init-scripts create users and permissions)
docker compose -f 05-infra/docker/docker-compose.dev.yml `
  --env-file 05-infra/configs/.env.dev up database -d

# 2. Verify users were created
docker compose -f 05-infra/docker/docker-compose.dev.yml `
  --env-file 05-infra/configs/.env.dev `
  logs database | Select-String "Creating application users"

# 3. Execute migrations as POSTGRES (not as {project}_app!)
docker compose -f 05-infra/docker/docker-compose.dev.yml `
  --env-file 05-infra/configs/.env.dev `
  exec database psql -U postgres -d {project}_dev `
  -f /db-scripts/migrations/001_create_{epic_name}_schema.sql

# 4. Execute seeds (now with correct permissions)
docker compose -f 05-infra/docker/docker-compose.dev.yml `
  --env-file 05-infra/configs/.env.dev `
  exec database psql -U {project}_app -d {project}_dev `
  -f /db-scripts/seeds/001_seed_{epic_name}_defaults.sql
```

### 🔑 Why Use `postgres` for Migrations?

- **`postgres`** (superuser): Creates tables that automatically receive permissions configured in `ALTER DEFAULT PRIVILEGES`
- **`{project}_app`**: Can create tables, BUT `{project}_readonly` won't receive permissions automatically

### 🔧 Fix Permissions if Migration Was Run with Wrong User

If you ran migration as `{project}_app` and now `{project}_readonly` has no permission:

```powershell
# Fix permissions manually
docker compose -f 05-infra/docker/docker-compose.dev.yml `
  --env-file 05-infra/configs/.env.dev `
  exec database psql -U postgres -d {project}_dev -c `
  "GRANT SELECT ON ALL TABLES IN SCHEMA public TO {project}_readonly;"
```

### Staging/Production

```powershell
# On server (after SSH)
docker compose exec database psql -U postgres -d {project}_staging `
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

## 🚀 Quick Start for Software Engineers (SE)

**⚠️ Database-First Approach:** DBA creates SQL migrations FIRST, then SE scaffolds EF Core models from database.

**Important:** This section covers LOCAL DEVELOPMENT. For CI/CD pipelines and GitHub Actions, see [GM-00 - Database Migrations in CI/CD](../07-github-management/GM-00-GitHub-Setup.md#database-migrations-in-cicd-database-first-approach).

### Prerequisites

Before starting, ensure you have:

- ✅ **Docker Desktop** installed and running
- ✅ **.NET 8 SDK** installed
- ✅ **EF Core CLI tools:** `dotnet tool install --global dotnet-ef`
- ✅ **PostgreSQL client** (psql) - included in Docker image

### Step 1: Start PostgreSQL Container

```bash
# Start database service only
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# Verify container is running
docker compose ps database

# Expected output: database running on port 5432
```

**What happens:**
- PostgreSQL 15 container starts
- Init scripts in `04-database/init-scripts/` execute automatically (creates users)
- Named volume `postgres-data` persists data

### Step 2: Verify Database Connection

```bash
# Connect to database as application user
docker compose exec database psql -U {project}_app -d {project}_dev

# Expected output: PostgreSQL prompt
# {project}_dev=>
```

**Test connection:**
```sql
-- List tables (should be empty initially)
\dt

-- Check current user
SELECT current_user;  -- Should show: {project}_app

-- Exit
\q
```

### Step 3: Apply SQL Migrations (created by DBA)

**Important:** DBA creates migrations FIRST in `04-database/migrations/`. SE only executes them.

```powershell
# Execute migration (example for EPIC-01) - Use POSTGRES for proper permissions
docker compose exec database psql -U postgres -d {project}_dev `
  -f /db-scripts/migrations/001_create_user_management_schema.sql

# Verify tables created
docker compose exec database psql -U {project}_app -d {project}_dev `
  -c "\dt"

# Expected output: List of tables from migration
#  Schema |        Name         | Type  |     Owner
# --------+---------------------+-------+----------------
#  public | Users               | table | postgres
#  public | SubscriptionPlans   | table | postgres
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

# What this creates:
# - src/Infrastructure/Data/Models/User.cs (entity class)
# - src/Infrastructure/Data/Models/SubscriptionPlan.cs
# - src/Infrastructure/Data/ApplicationDbContext.cs (DbContext)
```

**Important Parameters:**
- `--output-dir`: Where to generate entity classes
- `--context`: DbContext name
- `--no-onconfiguring`: Removes connection string from DbContext (use DI instead)
- `--force`: Overwrites existing files (safe for re-scaffolding)

**For complete scaffolding documentation, see:** [EF Core Scaffolding Commands](#ef-core-scaffolding-commands) section below.

### Step 5: Setup Integration Tests with TestContainers

**Purpose:** Run integration tests against REAL PostgreSQL (not in-memory SQLite).

**For complete setup, see:** [TestContainers Setup](#testcontainers-setup-for-integration-tests) section below.

**Quick example:**
```bash
# Add NuGet packages
cd 02-backend/tests/{ProjectName}.IntegrationTests
dotnet add package Testcontainers.PostgreSql --version 3.x

# Create test fixture (see TestContainers section for full code)
# Tests will spin up PostgreSQL container, apply migrations, run tests, dispose container
```

### Common Workflows

#### Workflow 1: Start Development (First Time)

```powershell
# 1. Start database
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# 2. Verify init-scripts executed (creates users)
docker compose logs database | Select-String "Creating application users"

# 3. Apply DBA migrations - Use POSTGRES for proper permissions
docker compose exec database psql -U postgres -d {project}_dev `
  -f /db-scripts/migrations/001_create_user_management_schema.sql

# 4. Scaffold EF models
cd 02-backend
dotnet ef dbcontext scaffold `
  "Host=localhost;Database={project}_dev;Username={project}_app;Password=dev_password_123" `
  Npgsql.EntityFrameworkCore.PostgreSQL `
  --output-dir src/Infrastructure/Data/Models `
  --context-dir src/Infrastructure/Data `
  --context ApplicationDbContext `
  --no-onconfiguring `
  --force

# 5. Run application
dotnet run --project src/Api
```

#### Workflow 2: Update After New Migration (Subsequent Epics)

```powershell
# 1. DBA creates new migration (e.g., 002_create_strategy_management_schema.sql)
# 2. Apply new migration - Use POSTGRES for proper permissions
docker compose exec database psql -U postgres -d {project}_dev `
  -f /db-scripts/migrations/002_create_strategy_management_schema.sql

# 3. Re-scaffold (updates existing + adds new entities)
cd 02-backend
dotnet ef dbcontext scaffold `
  "Host=localhost;Database={project}_dev;Username={project}_app;Password=dev_password_123" `
  Npgsql.EntityFrameworkCore.PostgreSQL `
  --output-dir src/Infrastructure/Data/Models `
  --context-dir src/Infrastructure/Data `
  --context ApplicationDbContext `
  --no-onconfiguring `
  --force

# 4. Review changes
git diff src/Infrastructure/Data/Models/

# 5. Create partial classes for new entities (see Scaffolding section)
```

#### Workflow 3: Reset Database (Clean Start)

```bash
# ⚠️ WARNING: This deletes all data!

# 1. Stop containers
docker compose down

# 2. Remove database volume
docker volume rm postgres-data

# 3. Start again (init-scripts will re-execute)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# 4. Re-apply all migrations in order
docker compose exec database psql -U {project}_app -d {project}_dev \
  -f /db-scripts/migrations/001_create_user_management_schema.sql
docker compose exec database psql -U {project}_app -d {project}_dev \
  -f /db-scripts/migrations/002_create_strategy_management_schema.sql
```

### Troubleshooting

#### Problem: "Connection refused" when scaffolding

**Cause:** Database container not running or wrong host/port

**Solution:**
```bash
# Check container status
docker compose ps database

# If not running, start it
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# Test connection
docker compose exec database psql -U {project}_app -d {project}_dev -c "SELECT 1"
```

#### Problem: "Password authentication failed"

**Cause:** Wrong password in connection string

**Solution:**
```bash
# Development password is always: dev_password_123
# Check .env file or use correct connection string:
"Host=localhost;Database={project}_dev;Username={project}_app;Password=dev_password_123"
```

#### Problem: "No tables found" when scaffolding

**Cause:** Migrations not applied yet

**Solution:**
```bash
# List tables
docker compose exec database psql -U {project}_app -d {project}_dev -c "\dt"

# If empty, apply migrations
docker compose exec database psql -U {project}_app -d {project}_dev \
  -f /db-scripts/migrations/001_create_user_management_schema.sql
```

### Next Steps

- **Learn about TestContainers:** [TestContainers Setup](#testcontainers-setup-for-integration-tests)
- **Learn about EF scaffolding:** [EF Core Scaffolding Commands](#ef-core-scaffolding-commands)
- **Learn about multi-epic workflow:** [Scaffolding Strategy Across Multiple Epics](#-para-se-scaffolding-strategy-across-multiple-epics)
- **CI/CD setup:** [GM-00 - Database Migrations in CI/CD](../07-github-management/GM-00-GitHub-Setup.md#database-migrations-in-cicd-database-first-approach)

---

## 🧪 TestContainers Setup for Integration Tests

**Purpose:** Run integration tests against REAL PostgreSQL (not in-memory SQLite).

**Philosophy:** Database-First approach means tests must validate against actual SQL schema created by DBA, not Code-First migrations.

### Why TestContainers?

**Problem with In-Memory Databases:**
- ❌ SQLite in-memory has different SQL dialect than PostgreSQL
- ❌ Missing PostgreSQL-specific features (JSONB, arrays, CTEs)
- ❌ Different constraint behavior
- ❌ False positives: tests pass with SQLite but fail in production

**Solution: TestContainers**
- ✅ Real PostgreSQL container (same as production)
- ✅ Isolated tests (each test class gets fresh database)
- ✅ Applies DBA migrations (SQL-First approach)
- ✅ Automatic cleanup (container destroyed after tests)

### NuGet Packages Required

```bash
# Navigate to integration tests project
cd 02-backend/tests/{ProjectName}.IntegrationTests

# Install TestContainers for PostgreSQL
dotnet add package Testcontainers.PostgreSql --version 3.x

# Install testing framework (if not already installed)
dotnet add package xunit
dotnet add package xunit.runner.visualstudio

# Install Npgsql for direct SQL execution
dotnet add package Npgsql
```

### Base Test Fixture (xUnit)

Create a shared fixture that all integration tests will use:

```csharp
// tests/{ProjectName}.IntegrationTests/DatabaseFixture.cs
using Npgsql;
using Testcontainers.PostgreSql;
using Xunit;

namespace {ProjectName}.IntegrationTests;

public class DatabaseFixture : IAsyncLifetime
{
    private readonly PostgreSqlContainer _container = new PostgreSqlBuilder()
        .WithDatabase("{project}_test")
        .WithUsername("{project}_app")
        .WithPassword("test_password")
        .WithImage("postgres:15-alpine")  // Same version as production
        .WithCleanUp(true)  // Auto-cleanup after tests
        .Build();

    public string ConnectionString => _container.GetConnectionString();

    public async Task InitializeAsync()
    {
        // 1. Start PostgreSQL container
        await _container.StartAsync();

        // 2. Apply DBA migrations (SQL-First approach)
        await using var connection = new NpgsqlConnection(ConnectionString);
        await connection.OpenAsync();

        // Read and execute DBA migration scripts
        var migrationFiles = new[]
        {
            "../../../../04-database/migrations/001_create_user_management_schema.sql",
            "../../../../04-database/migrations/002_create_strategy_management_schema.sql"
            // Add more migrations as needed
        };

        foreach (var file in migrationFiles)
        {
            if (!File.Exists(file)) continue;  // Skip if migration doesn't exist yet

            var migrationScript = await File.ReadAllTextAsync(file);

            await using var cmd = new NpgsqlCommand(migrationScript, connection);
            await cmd.ExecuteNonQueryAsync();
        }

        // 3. Apply seed data (if needed for tests)
        var seedFiles = new[]
        {
            "../../../../04-database/seeds/001_seed_user_management_defaults.sql"
        };

        foreach (var file in seedFiles)
        {
            if (!File.Exists(file)) continue;

            var seedScript = await File.ReadAllTextAsync(file);
            await using var cmd = new NpgsqlCommand(seedScript, connection);
            await cmd.ExecuteNonQueryAsync();
        }
    }

    public async Task DisposeAsync()
    {
        // Cleanup: Stop and remove container
        await _container.DisposeAsync();
    }
}
```

### Example Integration Test

```csharp
// tests/{ProjectName}.IntegrationTests/UserRepositoryIntegrationTests.cs
using Microsoft.EntityFrameworkCore;
using Xunit;
using {ProjectName}.Domain.Entities;
using {ProjectName}.Infrastructure.Data;
using {ProjectName}.Infrastructure.Repositories;

namespace {ProjectName}.IntegrationTests;

public class UserRepositoryIntegrationTests : IClassFixture<DatabaseFixture>
{
    private readonly DatabaseFixture _fixture;

    public UserRepositoryIntegrationTests(DatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [Fact]
    public async Task CreateUser_ShouldPersistToDatabase()
    {
        // Arrange
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseNpgsql(_fixture.ConnectionString)
            .Options;

        await using var context = new ApplicationDbContext(options);
        var repository = new UserRepository(context);

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "test@example.com",
            Name = "Test User",
            Role = UserRole.Trader,
            Status = UserStatus.Active
        };

        // Act
        await repository.AddAsync(user);
        await context.SaveChangesAsync();

        // Assert
        var retrieved = await repository.GetByIdAsync(user.Id);
        Assert.NotNull(retrieved);
        Assert.Equal("test@example.com", retrieved.Email);
    }

    [Fact]
    public async Task GetByEmail_ShouldReturnUser()
    {
        // Arrange
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseNpgsql(_fixture.ConnectionString)
            .Options;

        await using var context = new ApplicationDbContext(options);
        var repository = new UserRepository(context);

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "john@example.com",
            Name = "John Doe"
        };
        await repository.AddAsync(user);
        await context.SaveChangesAsync();

        // Act
        var result = await repository.GetByEmailAsync("john@example.com");

        // Assert
        Assert.NotNull(result);
        Assert.Equal(user.Id, result.Id);
    }

    [Fact]
    public async Task UpdateUser_ShouldPersistChanges()
    {
        // Arrange
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseNpgsql(_fixture.ConnectionString)
            .Options;

        await using var context = new ApplicationDbContext(options);
        var repository = new UserRepository(context);

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "update@example.com",
            Name = "Original Name"
        };
        await repository.AddAsync(user);
        await context.SaveChangesAsync();

        // Act
        user.Name = "Updated Name";
        await repository.UpdateAsync(user);
        await context.SaveChangesAsync();

        // Assert (query fresh from DB)
        var updated = await repository.GetByIdAsync(user.Id);
        Assert.Equal("Updated Name", updated.Name);
    }
}
```

### Running Tests

```bash
# Run all integration tests
dotnet test --filter "Category=Integration"

# Run specific test class
dotnet test --filter "FullyQualifiedName~UserRepositoryIntegrationTests"

# Run with verbose output
dotnet test --logger "console;verbosity=detailed"
```

**What happens:**
1. xUnit detects `IClassFixture<DatabaseFixture>`
2. Fixture starts PostgreSQL container ONCE for all tests in class
3. Applies DBA migrations (SQL-First)
4. Each test method runs with fresh DbContext
5. After all tests, container is destroyed

### Key Principles

- ✅ **SQL migrations BEFORE tests** - Apply DBA scripts in fixture initialization
- ✅ **Real PostgreSQL** - Not in-memory SQLite (same as production)
- ✅ **Idempotent migrations** - Safe to re-execute (`CREATE TABLE IF NOT EXISTS`)
- ✅ **Isolated tests** - Each test class gets fresh database instance
- ✅ **Database-First** - Tests validate against actual SQL schema, not Code-First migrations

### Best Practices

#### 1. Use Collection Fixtures for Expensive Setup

If fixture initialization is slow (many migrations), share container across multiple test classes:

```csharp
// DatabaseCollection.cs
[CollectionDefinition("Database")]
public class DatabaseCollection : ICollectionFixture<DatabaseFixture>
{
    // This class has no code - it's just a marker
}

// Use in test classes
[Collection("Database")]
public class UserRepositoryTests : IClassFixture<DatabaseFixture>
{
    // Tests...
}

[Collection("Database")]
public class StrategyRepositoryTests : IClassFixture<DatabaseFixture>
{
    // Tests share same container/database
}
```

#### 2. Reset Database State Between Tests (if needed)

```csharp
public class UserRepositoryTests : IClassFixture<DatabaseFixture>
{
    private readonly DatabaseFixture _fixture;

    public UserRepositoryTests(DatabaseFixture fixture)
    {
        _fixture = fixture;
        CleanDatabase().Wait();  // Reset before each test
    }

    private async Task CleanDatabase()
    {
        await using var connection = new NpgsqlConnection(_fixture.ConnectionString);
        await connection.OpenAsync();

        // Truncate tables (keeps schema)
        var cmd = new NpgsqlCommand(@"
            TRUNCATE TABLE Users, Strategies, TradingRules RESTART IDENTITY CASCADE;
        ", connection);
        await cmd.ExecuteNonQueryAsync();
    }
}
```

#### 3. Use Test Categories

```csharp
[Trait("Category", "Integration")]
public class UserRepositoryTests
{
    // Tests...
}

// Run only integration tests
// dotnet test --filter "Category=Integration"
```

### Troubleshooting

#### Problem: "Docker daemon not running"

**Symptom:** `Cannot connect to Docker daemon`

**Solution:**
```bash
# Start Docker Desktop
# Or on Linux:
sudo systemctl start docker
```

#### Problem: "Tests timeout or hang"

**Symptom:** Tests never complete

**Cause:** Container takes time to start

**Solution:**
```csharp
private readonly PostgreSqlContainer _container = new PostgreSqlBuilder()
    .WithDatabase("{project}_test")
    .WithWaitStrategy(Wait.ForUnixContainer().UntilPortIsAvailable(5432))  // Wait for port
    .Build();
```

#### Problem: "Migration file not found"

**Symptom:** `FileNotFoundException` when reading migration SQL

**Solution:**
```csharp
// Use correct relative path from test project
var file = "../../../../04-database/migrations/001_create_user_management_schema.sql";
var fullPath = Path.GetFullPath(file);
Console.WriteLine($"Looking for: {fullPath}");  // Debug
```

### Performance Tips

**Fixture Initialization (~2-5 seconds):**
- Container start: ~1-2s
- Apply migrations: ~1-2s
- Total: ~3-4s per test class

**Optimization:**
- ✅ Use `[Collection]` to share container across test classes
- ✅ Keep migrations idempotent (safe to re-run)
- ❌ Don't create/destroy container per test method (use fixture)

### CI/CD Integration

**For GitHub Actions setup, see:** [GM-00 - Database Migrations in CI/CD](../07-github-management/GM-00-GitHub-Setup.md#database-migrations-in-cicd-database-first-approach)

**Local vs CI:**
- **Local:** TestContainers starts PostgreSQL automatically
- **CI:** GitHub Actions uses `services: postgres:` (see GM-00)

---

## 🛠️ EF Core Scaffolding Commands Reference

### Overview

**Database-First Approach:** DBA creates SQL migrations → SE scaffolds EF Core models from PostgreSQL database.

**Key Command:** `dotnet ef dbcontext scaffold`

### Prerequisites

**Install EF Core CLI tools:**
```bash
dotnet tool install --global dotnet-ef
# or update if already installed:
dotnet tool update --global dotnet-ef
```

**Required NuGet packages** (add to your project):
```xml
<PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.*" />
<PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.*" />
```

### Basic Scaffold Command

**Template:**
```bash
dotnet ef dbcontext scaffold \
  "Host=localhost;Port=5432;Database={project}_dev;Username={project}_app;Password={project}_dev_password" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir Infrastructure/Data/Models \
  --context-dir Infrastructure/Data \
  --context ApplicationDbContext \
  --no-onconfiguring \
  --force
```

**Replace placeholders:**
- `{project}_dev` → Database name (e.g., `mytrader_dev`)
- `{project}_app` → Database user (e.g., `mytrader_app`)
- `{project}_dev_password` → User password

### Command Options Explained

| Option | Description | Recommendation |
|--------|-------------|----------------|
| `--output-dir` | Where entity classes are generated | `Infrastructure/Data/Models` |
| `--context-dir` | Where DbContext is generated | `Infrastructure/Data` |
| `--context` | DbContext class name | `ApplicationDbContext` |
| `--no-onconfiguring` | Don't generate `OnConfiguring` method | ✅ **Always use** (connection strings go in DI) |
| `--force` | Overwrite existing files | ⚠️ **Use after Epic 1** (see partial classes pattern below) |
| `--schema` | Scaffold specific schema only | Optional: `--schema user_management` |
| `--table` | Scaffold specific table(s) only | Optional: `--table users --table subscription_plans` |
| `--data-annotations` | Use attributes instead of Fluent API | ❌ **Avoid** (prefer Fluent API for complex mappings) |

### Workflow Examples

#### 1️⃣ First Time (Epic 1)

**Scenario:** DBA created first SQL migration with `users` and `subscription_plans` tables.

**Command:**
```bash
cd src/{ProjectName}.WebAPI

dotnet ef dbcontext scaffold \
  "Host=localhost;Port=5432;Database={project}_dev;Username={project}_app;Password={project}_dev_password" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir Infrastructure/Data/Models \
  --context-dir Infrastructure/Data \
  --context ApplicationDbContext \
  --no-onconfiguring
```

**Generated files:**
```
src/{ProjectName}.WebAPI/
├── Infrastructure/Data/
│   └── ApplicationDbContext.cs       # DbContext with DbSet<User>, DbSet<SubscriptionPlan>
└── Infrastructure/Data/Models/
    ├── User.cs                        # Entity for users table
    └── SubscriptionPlan.cs            # Entity for subscription_plans table
```

#### 2️⃣ Subsequent Epics (Epic 2+)

**Scenario:** DBA added new migration with `strategies` table. You already added domain logic to `User.cs`.

**⚠️ CRITICAL:** Use `--force` flag to regenerate ALL entities (including new ones).

**Command:**
```bash
cd src/{ProjectName}.WebAPI

dotnet ef dbcontext scaffold \
  "Host=localhost;Port=5432;Database={project}_dev;Username={project}_app;Password={project}_dev_password" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir Infrastructure/Data/Models \
  --context-dir Infrastructure/Data \
  --context ApplicationDbContext \
  --no-onconfiguring \
  --force
```

**What happens:**
- ✅ Creates `Strategy.cs` for new table
- ⚠️ **OVERWRITES** `User.cs` and `SubscriptionPlan.cs` (your custom code is LOST!)

**Solution:** Use **partial classes pattern** (see next section) to separate auto-generated code from custom domain logic.

#### 3️⃣ Scaffold Specific Schema Only

**Use case:** Multi-bounded-context projects (e.g., only scaffold `strategy_management` schema).

**Command:**
```bash
dotnet ef dbcontext scaffold \
  "Host=localhost;Port=5432;Database={project}_dev;Username={project}_app;Password={project}_dev_password" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir Infrastructure/Data/Models \
  --context-dir Infrastructure/Data \
  --context ApplicationDbContext \
  --no-onconfiguring \
  --schema strategy_management \
  --force
```

### Best Practices

1. **Connection Strings:** Never hardcode in commands
   - Use environment variables: `$Env:DB_CONNECTION_STRING` (PowerShell) or `$DB_CONNECTION_STRING` (Bash)
   - Or read from `appsettings.Development.json`

2. **After Scaffolding:** Always review generated code
   - Check entity property types (PostgreSQL types → C# types)
   - Verify foreign key relationships
   - Review navigation properties (one-to-many, many-to-many)

3. **Custom Code Protection:** See "Scaffolding Strategy Across Multiple Epics" section below

4. **Version Control:** Commit scaffolded files separately
   ```bash
   git add Infrastructure/Data/Models/*.cs Infrastructure/Data/ApplicationDbContext.cs
   git commit -m "chore(db): Scaffold EF Core models from Epic X migration"
   ```

### Troubleshooting

**Error: "No DbContext was found"**
- Check `--context-dir` path is correct
- Ensure project file has `<Project Sdk="Microsoft.NET.Sdk.Web">`

**Error: "Unable to connect to PostgreSQL"**
- Verify Docker container is running: `docker ps | grep postgres`
- Test connection: `psql -h localhost -U {project}_app -d {project}_dev`

**Error: "Could not load assembly 'Npgsql.EntityFrameworkCore.PostgreSQL'"**
- Install NuGet package: `dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL`

**Generated entities have `public virtual` properties**
- This is normal for EF Core (enables lazy loading and change tracking)
- Keep `virtual` keyword unless you need to disable proxies

---

## 🔄 Para SE: Scaffolding Strategy Across Multiple Epics

### ⚠️ CRITICAL: Understanding the Scaffolding Problem

**Question:** "E do segundo épico em diante? As estruturas dos anteriores são substituídas?"

**Answer:** YES - scaffolded files ARE overwritten, but customizations are SAFE with correct pattern!

### The Problem: EF Scaffold `--force` Behavior

**What `--force` does:**
- ✅ Creates new entity files for new tables
- ⚠️ **REGENERATES ALL existing entity files** (not just changed ones)
- ❌ **DELETES custom code** added to scaffolded files

**Example Scenario:**
```
EPIC-01: Scaffold creates User.cs, SubscriptionPlan.cs
         You add domain logic to User.cs

EPIC-02: Scaffold --force regenerates ALL files
         Result: Your domain logic in User.cs is LOST!
```

### ✅ The Solution: Hybrid Approach (Partial Classes Pattern)

**Industry standard for Database-First + DDD projects.**

**Key Principle:**
> "Separate auto-generated code from custom domain logic using partial classes."

**File Organization:**

| Location | Type | Touched by Scaffold? | Purpose |
|----------|------|---------------------|---------|
| `src/Infrastructure/Data/Models/*.cs` | ⚠️ Auto-Generated | **YES - Overwritten every epic** | Base entity classes (DB columns only) |
| `src/Infrastructure/Data/ApplicationDbContext.cs` | ⚠️ Auto-Generated | **YES - Overwritten** | DbContext base |
| `src/Domain/Entities/*.Partial.cs` | ✅ Custom | **NO - Never touched** | Domain logic, business methods, domain events |
| `src/Infrastructure/Persistence/Configurations/*.cs` | ✅ Custom | **NO - Never touched** | FluentAPI (Value Objects, JSONB, complex mappings) |
| `src/Infrastructure/Data/ApplicationDbContext.Partial.cs` | ✅ Custom | **NO - Never touched** | Custom OnModelCreating (registers configs) |

---

### Workflow: EPIC-01 (Initial Scaffold)

#### Step 1: DBA Executes Migrations (Already Done)

```bash
psql -h localhost -U {project}_app -d {project}_dev \
  -f 04-database/migrations/001_create_{epic_name}_schema.sql
```

#### Step 2: SE Scaffolds from Database

```bash
cd 02-backend

dotnet ef dbcontext scaffold \
  "Host=localhost;Port=5432;Database=[PROJECT_NAME]_dev;Username=[PROJECT_NAME]_app;Password={DB_APP_PASSWORD}" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir src/Infrastructure/Data/Models \
  --context-dir src/Infrastructure/Data \
  --context ApplicationDbContext \
  --force \
  --no-onconfiguring

# Creates (AUTO-GENERATED):
# - src/Infrastructure/Data/Models/User.cs
# - src/Infrastructure/Data/Models/SubscriptionPlan.cs
# - src/Infrastructure/Data/ApplicationDbContext.cs
```

#### Step 3: SE Creates Custom Partial Classes

**Domain Logic (SAFE):**
```csharp
// ✅ src/Domain/Entities/User.Partial.cs (NEVER touched by scaffold)
public partial class User
{
    // Domain methods from DE-01
    public void UpdateRiskProfile(RiskProfile newProfile)
    {
        if (Role != UserRole.Trader)
            throw new DomainException("Only traders can have risk profile");
        RiskProfile = newProfile;
    }

    // Domain events
    private List<IDomainEvent> _domainEvents = new();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();
}
```

**FluentAPI Configuration (SAFE):**
```csharp
// ✅ src/Infrastructure/Persistence/Configurations/UserConfiguration.cs
public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        // Value Objects
        builder.OwnsOne(u => u.PhoneNumber, phone =>
        {
            phone.Property(p => p.CountryCode).HasColumnName("PhoneCountryCode");
            phone.Property(p => p.Number).HasColumnName("PhoneNumber");
        });

        // JSONB columns
        builder.Property(u => u.PlanOverride)
               .HasColumnType("jsonb");

        // Enum as string
        builder.Property(u => u.Role)
               .HasConversion<string>();
    }
}
```

**DbContext Partial (SAFE):**
```csharp
// ✅ src/Infrastructure/Data/ApplicationDbContext.Partial.cs
public partial class ApplicationDbContext
{
    partial void OnModelCreatingPartial(ModelBuilder modelBuilder)
    {
        // Register all custom configurations
        modelBuilder.ApplyConfiguration(new UserConfiguration());
        modelBuilder.ApplyConfiguration(new SubscriptionPlanConfiguration());
        modelBuilder.ApplyConfiguration(new SystemConfigConfiguration());
    }
}
```

---

### Workflow: EPIC-02+ (Re-Scaffold with NEW Tables)

#### Step 1: DBA Creates NEW Migrations

```bash
# DBA creates migrations for NEW tables
psql -h localhost -U {project}_app -d {project}_dev \
  -f 04-database/migrations/002_create_strategy_management_schema.sql

# Adds tables: Strategies, TradingRules, Backtests
```

#### Step 2: SE Re-Scaffolds ENTIRE Database (⚠️ WITH --force)

```bash
cd 02-backend

# SAME command as EPIC-01 - scaffold ALL tables again
dotnet ef dbcontext scaffold \
  "Host=localhost;Port=5432;Database=[PROJECT_NAME]_dev;Username=[PROJECT_NAME]_app;Password={DB_APP_PASSWORD}" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir src/Infrastructure/Data/Models \
  --context-dir src/Infrastructure/Data \
  --context ApplicationDbContext \
  --force \
  --no-onconfiguring

# What happens:
# ✅ NEW files created:
#    - src/Infrastructure/Data/Models/Strategy.cs
#    - src/Infrastructure/Data/Models/TradingRule.cs
#    - src/Infrastructure/Data/Models/Backtest.cs
#
# ⚠️ EPIC-01 files REGENERATED (but this is OK!):
#    - src/Infrastructure/Data/Models/User.cs (OVERWRITTEN from DB)
#    - src/Infrastructure/Data/Models/SubscriptionPlan.cs (OVERWRITTEN)
#
# ✅ CUSTOM files UNTOUCHED (your code is SAFE):
#    - src/Domain/Entities/User.Partial.cs (NOT touched)
#    - src/Infrastructure/Persistence/Configurations/UserConfiguration.cs (NOT touched)
#    - src/Infrastructure/Data/ApplicationDbContext.Partial.cs (NOT touched)
```

**KEY INSIGHT:**
- User.cs gets regenerated (base properties only)
- But User.Partial.cs with domain logic is NEVER touched!
- Your customizations are 100% safe!

#### Step 3: SE Creates Partial Classes for NEW Entities

```csharp
// ✅ src/Domain/Entities/Strategy.Partial.cs (NEW for EPIC-02)
public partial class Strategy
{
    public void Activate()
    {
        if (Status != StrategyStatus.Draft)
            throw new DomainException("Only draft strategies can be activated");
        Status = StrategyStatus.Active;
        _domainEvents.Add(new StrategyActivated(Id, DateTime.UtcNow));
    }

    private List<IDomainEvent> _domainEvents = new();
}

// ✅ src/Infrastructure/Persistence/Configurations/StrategyConfiguration.cs
public class StrategyConfiguration : IEntityTypeConfiguration<Strategy>
{
    public void Configure(EntityTypeBuilder<Strategy> builder)
    {
        builder.HasMany(s => s.TradingRules)
               .WithOne(r => r.Strategy)
               .HasForeignKey(r => r.StrategyId);
    }
}
```

#### Step 4: SE Updates DbContext Partial (ADD new configs)

```csharp
// ✅ src/Infrastructure/Data/ApplicationDbContext.Partial.cs (UPDATE)
public partial class ApplicationDbContext
{
    partial void OnModelCreatingPartial(ModelBuilder modelBuilder)
    {
        // EPIC-01 configs (unchanged)
        modelBuilder.ApplyConfiguration(new UserConfiguration());
        modelBuilder.ApplyConfiguration(new SubscriptionPlanConfiguration());
        modelBuilder.ApplyConfiguration(new SystemConfigConfiguration());

        // EPIC-02 configs (NEW)
        modelBuilder.ApplyConfiguration(new StrategyConfiguration());
        modelBuilder.ApplyConfiguration(new TradingRuleConfiguration());
        modelBuilder.ApplyConfiguration(new BacktestConfiguration());
    }
}
```

---

### Final File Structure (After Multiple Epics)

```
02-backend/src/
├── Infrastructure/Data/
│   ├── Models/                       # ⚠️ AUTO-GENERATED (DO NOT EDIT)
│   │   ├── User.cs                   # EPIC-01 (regenerated in EPIC-02, EPIC-03...)
│   │   ├── SubscriptionPlan.cs       # EPIC-01 (regenerated)
│   │   ├── Strategy.cs               # EPIC-02 (NEW)
│   │   ├── TradingRule.cs            # EPIC-02 (NEW)
│   │   └── Backtest.cs               # EPIC-03 (NEW)
│   ├── ApplicationDbContext.cs       # AUTO-GENERATED (regenerated every epic)
│   └── ApplicationDbContext.Partial.cs  # ✅ CUSTOM (cumulative updates)
│
├── Domain/Entities/                  # ✅ CUSTOM (domain logic)
│   ├── User.Partial.cs               # EPIC-01 (NEVER touched after creation)
│   ├── SubscriptionPlan.Partial.cs   # EPIC-01
│   ├── Strategy.Partial.cs           # EPIC-02 (added)
│   ├── TradingRule.Partial.cs        # EPIC-02 (added)
│   └── Backtest.Partial.cs           # EPIC-03 (added)
│
└── Infrastructure/Persistence/Configurations/  # ✅ CUSTOM (FluentAPI)
    ├── UserConfiguration.cs          # EPIC-01 (NEVER touched)
    ├── SubscriptionPlanConfiguration.cs  # EPIC-01
    ├── StrategyConfiguration.cs      # EPIC-02 (added)
    ├── TradingRuleConfiguration.cs   # EPIC-02 (added)
    └── BacktestConfiguration.cs      # EPIC-03 (added)
```

---

### Why This Works: Technical Explanation

**C# Partial Classes:**

When you have multiple files with `partial class`, the compiler merges them:

```csharp
// File 1: User.cs (AUTO-GENERATED)
public partial class User
{
    public Guid Id { get; set; }
    public string Email { get; set; }
}

// File 2: User.Partial.cs (CUSTOM)
public partial class User
{
    public bool IsActive() => Status == "Active";
}

// Compiler merges into single class with both properties and methods
```

**EF Core OnModelCreatingPartial Hook:**

Scaffold generates this pattern:
```csharp
// ApplicationDbContext.cs (AUTO-GENERATED)
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // Auto-generated basic config
    modelBuilder.Entity<User>(entity => { /* ... */ });

    OnModelCreatingPartial(modelBuilder);  // ⚠️ Calls your method
}

partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
```

You implement in separate file:
```csharp
// ApplicationDbContext.Partial.cs (CUSTOM)
partial void OnModelCreatingPartial(ModelBuilder modelBuilder)
{
    // Your FluentAPI configs (never overwritten!)
    modelBuilder.ApplyConfiguration(new UserConfiguration());
}
```

---

### Common Mistakes to Avoid

❌ **NEVER add domain logic to scaffolded files:**
```csharp
// ❌ WRONG: src/Infrastructure/Data/Models/User.cs
public partial class User
{
    public Guid Id { get; set; }

    // ❌ This will be LOST on next scaffold!
    public bool IsActive() => Status == "Active";
}
```

✅ **DO use separate partial class:**
```csharp
// ✅ CORRECT: src/Domain/Entities/User.Partial.cs
public partial class User
{
    // ✅ This is SAFE (never touched by scaffold)
    public bool IsActive() => Status == "Active";
}
```

❌ **NEVER add FluentAPI to scaffolded DbContext:**
```csharp
// ❌ WRONG: src/Infrastructure/Data/ApplicationDbContext.cs
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // Auto-generated
    // ❌ Adding custom config here will be LOST!
    modelBuilder.Entity<User>().OwnsOne(u => u.PhoneNumber);
}
```

✅ **DO use Configuration class:**
```csharp
// ✅ CORRECT: src/Infrastructure/Persistence/Configurations/UserConfiguration.cs
public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        // ✅ This is SAFE
        builder.OwnsOne(u => u.PhoneNumber);
    }
}
```

---

### Prerequisites for Scaffolding

Before running scaffold command, ensure:

- ✅ Database is running: `docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d`
- ✅ DBA migrations executed (see "How to Execute Migrations" above)
- ✅ Connection string correct (from `.env.dev`)
- ✅ EF Core tools installed: `dotnet tool install --global dotnet-ef`
- ✅ Npgsql provider installed: `dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL`

---

### Troubleshooting

**Problem:** "I lost my domain logic after re-scaffolding!"

**Cause:** Domain logic was in `src/Infrastructure/Data/Models/User.cs` (auto-generated file)

**Solution:**
1. Restore from Git: `git restore src/Domain/Entities/User.Partial.cs`
2. Move domain logic to correct location (User.Partial.cs)
3. Re-scaffold

---

**Problem:** "New tables don't have FK relationships to old tables"

**Cause:** Scaffold generates basic config only

**Solution:**
Add FK configuration in Configuration class:
```csharp
public class StrategyConfiguration : IEntityTypeConfiguration<Strategy>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.HasOne<User>()
               .WithMany()
               .HasForeignKey(s => s.UserId);
    }
}
```

---

### References

- **Workflow Guide - SQL-First**: [00-Workflow-Guide.md](../../.agents/docs/00-Workflow-Guide.md#database-workflow-sql-first-approach)
- **SE Agent Overview**: [01-Agents-Overview.md](../../.agents/docs/01-Agents-Overview.md#se---software-engineer)
- **DBA Schema Review**: [DBA-01-[EpicName]-Schema-Review.md](../../00-doc-ddd/05-database-design/DBA-01-[EpicName]-Schema-Review.md)
- **EF Core Reverse Engineering**: [Microsoft Docs](https://learn.microsoft.com/en-us/ef/core/managing-schemas/scaffolding/)
- **C# Partial Classes**: [Microsoft Docs](https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/partial-classes-and-methods)

---

## 🧪 Validation and Testing

### Verify Users Created

```bash
# Connect as postgres (admin)
docker compose exec database psql -U postgres -d {project}_dev

# List users
\du

# Expected output:
# postgres            | Superuser, Create role, Create DB
# {project}_app       | Cannot login (limited permissions)
# {project}_readonly  | Cannot login (read-only)
```

### Test {project}_app Permissions

```sql
-- Connect as {project}_app
\c {project}_dev {project}_app

-- ✅ CRUD should work
INSERT INTO {Table} (Id, Name) VALUES (gen_random_uuid(), 'Test');
SELECT * FROM {Table} WHERE Name = 'Test';
DELETE FROM {Table} WHERE Name = 'Test';

-- ✅ CREATE TABLE should work (migrations)
CREATE TABLE test_table (id INT);
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

-- ❌ Modifications should FAIL
INSERT INTO {Table} (Id, Name) VALUES (gen_random_uuid(), 'Test');  -- ERROR
UPDATE {Table} SET Name = 'hacker';                                 -- ERROR
DELETE FROM {Table};                                                -- ERROR
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

## 📊 Migration Status

### {EPIC_NAME} - {Epic Description}

| Migration | Status | Date | Description |
|-----------|--------|------|-------------|
| [001_create_{epic_name}_schema.sql](migrations/001_create_{epic_name}_schema.sql) | ⏳ To Create | YYYY-MM-DD | Complete schema: {Table1}, {Table2}, {Table3} |
| [001_seed_{epic_name}_defaults.sql](seeds/001_seed_{epic_name}_defaults.sql) | ⏳ To Create | YYYY-MM-DD | Initial data: {seed description} |

**Note:** [000_update_passwords.sql](migrations/000_update_passwords.sql) is a maintenance utility (not a sequential migration) for password rotation. Use prefix `000_` for non-sequential utilities.

---

## 🔗 Related Artifacts

This section connects operational README with strategic documentation.

| Artifact | Purpose | When to Consult |
|----------|---------|------------------|
| **[DBA-01-{EpicName}-Database-Design-Decisions.md](../00-doc-ddd/05-database-design/DBA-01-{EpicName}-Database-Design-Decisions.md)** | Architectural database design decisions (Value Objects, indexes, constraints, trade-offs) | To understand **WHY** the schema is modeled this way, evaluate alternatives, modify structure |
| **[FEEDBACK-XXX-DBA-{Topic}.md](../00-doc-ddd/00-feedback/FEEDBACK-XXX-DBA-{Topic}.md)** | Resolutions: {Feedback topic summary} | To understand security implementations, improvements, compliance |
| **[PE-00-Quick-Start.md (local dev) and PE-01-Server-Setup.md (server setup)](../00-doc-ddd/08-platform-engineering/PE-00-Quick-Start.md (local dev) and PE-01-Server-Setup.md (server setup))** | Docker Compose, infrastructure, connection strings per environment | To understand how containers are configured, volume mounts, init-scripts integration |
| **[SEC-00-Security-Baseline.md](../00-doc-ddd/09-security/SEC-00-Security-Baseline.md)** | Security baseline (Database User Segregation section) | To understand security benefits, compliance (LGPD/SOC2), defense in depth strategy |

---

## 📚 References

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

## 🛠️ Troubleshooting

### Problem: Init script did not execute

**Symptom:** Users `{project}_app` and `{project}_readonly` do not exist  

**Cause:** PostgreSQL volume already existed (init scripts only execute on first time)  

**Solution:**  
```bash
# 1. Stop container
docker compose down

# 2. Remove database volume (⚠️ WARNING: deletes data!)
docker volume rm postgres-data

# 3. Start again (init script will execute)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# 4. Verify logs
docker compose logs database | grep "Creating application users"
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
docker compose exec database psql -U postgres -d {project}_dev -f /docker-entrypoint-initdb.d/01-create-app-user.sql
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
docker compose restart api
```

---

**DBA Agent** - {PROJECT_NAME} Database Management
**Last Updated:** {YYYY-MM-DD}  
**Status:** ⏳ {Epic Status}  
