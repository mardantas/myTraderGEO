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

## 🔒 Multi-Environment Password Strategy

### Security Principle

**⚠️ NEVER hardcode production passwords in Git!**

Database passwords must follow a **multi-environment strategy** where development uses safe defaults (committed to Git), but staging/production use strong passwords (created on server, NEVER committed).

### Password Requirements by Environment

| Environment | Password Complexity | Rotation Frequency | Git Status | Example |
|-------------|---------------------|-------------------|-----------|---------|
| **Development** | Simple (dev_password_123) | ❌ No rotation | ✅ Committed (.env.dev) | `DB_APP_PASSWORD=dev_password_123` |
| **Staging** | Strong (16+ chars, mixed case, numbers, symbols) | Semi-annual | ❌ NOT committed (.env.staging) | `DB_APP_PASSWORD=St@g!ng_SecureP@ss2025!#` |
| **Production** | Very Strong (20+ chars, mixed case, numbers, symbols) | Quarterly | ❌ NOT committed (.env.production) | `DB_APP_PASSWORD=Pr0d_V3ry$trong#P@ssw0rd2025!` |

### Implementation Pattern: ALTER USER Migration

**Problem:** If we commit passwords to Git (even in migrations), they become visible in repository history.  

**Solution:** Use a **two-step approach**:  

1. **Init script (committed to Git):** Creates users with development passwords
2. **ALTER USER migration (committed WITHOUT real passwords):** Updates passwords for staging/production via environment variables

#### Step 1: Init Script (Development Passwords)

**File:** [init-scripts/01-create-app-user.sql](init-scripts/01-create-app-user.sql)  

```sql
-- This file is COMMITTED to Git with DEV passwords
-- (safe because dev passwords are public)

CREATE USER {project}_app WITH PASSWORD 'dev_password_123';
CREATE USER {project}_readonly WITH PASSWORD 'dev_readonly_123';

-- Grant permissions...
```

**Execution:** Automatic on first PostgreSQL container initialization  

---

#### Step 2: ALTER USER Migration (Staging/Production Passwords)

**File:** [migrations/002_update_prod_passwords.sql](migrations/002_update_prod_passwords.sql)  

```sql
-- This file is COMMITTED to Git WITHOUT real passwords
-- Passwords are passed via psql -v parameter

-- ⚠️ WARNING: This migration should ONLY be executed on staging/production
-- Development continues using dev_password_123 from init script

-- Usage:
-- export DB_APP_PASSWORD="St@g!ng_SecureP@ss2025!#"
-- export DB_READONLY_PASSWORD="St@g!ng_ReadOnly2025!#"
-- psql -v app_password="$DB_APP_PASSWORD" -v readonly_password="$DB_READONLY_PASSWORD" -f 002_update_prod_passwords.sql

-- Update application user password
ALTER USER {project}_app WITH PASSWORD :'app_password';

-- Update readonly user password
ALTER USER {project}_readonly WITH PASSWORD :'readonly_password';

-- Log password change (do NOT log password itself!)
DO $$
BEGIN
    RAISE NOTICE 'Database passwords updated successfully at %', NOW();
END $$;
```

**Execution (Staging/Production ONLY):**

```bash
# Set environment variables (from .env.staging or .env.production)
export DB_APP_PASSWORD="[STRONG_PASSWORD_FROM_ENV]"
export DB_READONLY_PASSWORD="[STRONG_PASSWORD_FROM_ENV]"

# Execute migration with variables
psql -h $DB_HOST -U postgres -d {project}_dev \
  -v app_password="$DB_APP_PASSWORD" \
  -v readonly_password="$DB_READONLY_PASSWORD" \
  -f 04-database/migrations/002_update_prod_passwords.sql
```

**⚠️ IMPORTANT:**
- ✅ **DO commit** `002_update_prod_passwords.sql` to Git (file contains NO passwords)  
- ❌ **DO NOT commit** real passwords (passed via `psql -v` from environment)  
- ✅ **DO document** execution instructions in this README  
- ❌ **DO NOT execute** on development (use dev_password_123 from init script)  

---

### Password Storage Locations

| Environment | Password Storage Location | Access Method | Git Status |
|-------------|---------------------------|---------------|-----------|
| **Development** | `init-scripts/01-create-app-user.sql` | Committed to Git | ✅ Public (safe) |
| **Staging** | Server: `/home/{project}_app/{project}/.env.staging` | SSH to server | ❌ NOT in Git |
| **Production** | Server: `/home/{project}_app/{project}/.env.production` | SSH to server | ❌ NOT in Git |

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
     -f migrations/002_update_prod_passwords.sql
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

- [ ] Database users created with least privilege ([01-create-app-user.sql](init-scripts/01-create-app-user.sql))  
- [ ] Development passwords committed to Git (safe defaults)  
- [ ] Staging/production passwords documented (NOT committed)  
- [ ] ALTER USER migration created ([002_update_prod_passwords.sql](migrations/002_update_prod_passwords.sql))  
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

- ✅ Database is running: `docker compose -f 05-infra/docker/docker-compose.yml up database -d`
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
