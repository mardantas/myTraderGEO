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

## 📁 Directory Structure

```
04-database/
├── init-scripts/       # Scripts executed on FIRST container initialization
│   └── 01-create-app-user.sql
├── migrations/         # Schema migrations (tables, indexes, constraints)
│   └── 001_create_{epic_name}_schema.sql
├── seeds/              # Initial data (plans, config, demo users)
│   └── 001_seed_{epic_name}_defaults.sql
└── README.md           # This file
```

### Directory Description

| Directory | When Executes | Purpose | Idempotent? |
|-----------|---------------|---------|-------------|
| **init-scripts/** | **Only on first initialization** (empty volume) | Create database users, security configurations | ✅ Yes (uses `IF NOT EXISTS`) |
| **migrations/** | Manually by DBA or CI/CD (each schema change) | Create/alter tables, indexes, constraints | ⚠️ Depends (use transactions) |
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

**File:** [init-scripts/01-create-app-user.sql](init-scripts/01-create-app-user.sql)  

**Execution:** Automatic on first PostgreSQL container initialization via `/docker-entrypoint-initdb.d/`  

**Idempotency:** ✅ Yes (uses `IF NOT EXISTS` - safe to re-execute)  

---

## 🚀 How to Execute Migrations

### Execution Order

**⚠️ IMPORTANT:** Execute in correct order to avoid dependency errors.  

```bash
# 1. Init Scripts (automatic on first time)
#    Executed automatically by Docker via /docker-entrypoint-initdb.d/
#    If already executed: skip (no need to re-execute)

# 2. Schema Migrations (manually or CI/CD)
psql -h localhost -U {project}_app -d {project}_dev -f 04-database/migrations/001_create_{epic_name}_schema.sql

# 3. Seed Data (manually)
psql -h localhost -U {project}_app -d {project}_dev -f 04-database/seeds/001_seed_{epic_name}_defaults.sql
```

### Environments

#### Development (Docker Compose)

```bash
# Start database
docker compose -f 05-infra/docker/docker-compose.yml up database -d

# Verify init-scripts executed
docker compose logs database | grep "Creating application users"

# Connect as {project}_app
docker compose exec database psql -U {project}_app -d {project}_dev

# Execute migrations (if needed)
docker compose exec database psql -U {project}_app -d {project}_dev -f /app/migrations/001_create_{epic_name}_schema.sql

# Execute seeds
docker compose exec database psql -U {project}_app -d {project}_dev -f /app/seeds/001_seed_{epic_name}_defaults.sql
```

#### Staging/Production

```bash
# Use environment credentials (via .env)
psql -h $DB_HOST -U $DB_APP_USER -d $DB_NAME -f 04-database/migrations/001_create_{epic_name}_schema.sql
psql -h $DB_HOST -U $DB_APP_USER -d $DB_NAME -f 04-database/seeds/001_seed_{epic_name}_defaults.sql
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

---

## 🔗 Related Artifacts

This section connects operational README with strategic documentation.

| Artifact | Purpose | When to Consult |
|----------|---------|------------------|
| **[DBA-01-{EpicName}-Database-Design-Decisions.md](../00-doc-ddd/05-database-design/DBA-01-{EpicName}-Database-Design-Decisions.md)** | Architectural database design decisions (Value Objects, indexes, constraints, trade-offs) | To understand **WHY** the schema is modeled this way, evaluate alternatives, modify structure |
| **[FEEDBACK-XXX-DBA-{Topic}.md](../00-doc-ddd/00-feedback/FEEDBACK-XXX-DBA-{Topic}.md)** | Resolutions: {Feedback topic summary} | To understand security implementations, improvements, compliance |
| **[PE-00-Environments-Setup.md](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md)** | Docker Compose, infrastructure, connection strings per environment | To understand how containers are configured, volume mounts, init-scripts integration |
| **[SEC-00-Security-Baseline.md](../00-doc-ddd/09-security/SEC-00-Security-Baseline.md)** | Security baseline (Database User Segregation section) | To understand security benefits, compliance (LGPD/SOC2), defense in depth strategy |

---

## 📚 References

### Internal Documentation

- **Database Design Decisions:** [00-doc-ddd/05-database-design/DBA-01-{EpicName}-Database-Design-Decisions.md](../00-doc-ddd/05-database-design/DBA-01-{EpicName}-Database-Design-Decisions.md)
  - Modeling decisions (Value Objects, indexes, constraints)
  - Expected queries and performance estimates
  - Trade-offs and technical justifications

- **Platform Engineering Setup:** [00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md)
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
docker volume rm {project}-postgres-data

# 3. Start again (init script will execute)
docker compose up database -d

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
