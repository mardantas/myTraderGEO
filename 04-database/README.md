# 04-database - Database Scripts & Migrations

**Projeto:** myTraderGEO
**Database:** PostgreSQL 15+
**Responsible Agent:** DBA Agent

---

## 📁 Estrutura de Diretórios

```
04-database/
├── init-scripts/       # Scripts executados na PRIMEIRA inicialização do container
│   └── 01-create-app-user.sql
├── migrations/         # Schema migrations (tabelas, índices, constraints)
│   ├── 001_*.sql       # Schema creation (tabelas, índices, constraints)
│   └── 002_*.sql       # Atualizações específicas de ambiente (senhas, config)
├── seeds/              # Dados iniciais (planos, config, demo users)
│   └── 001_seed_user_management_defaults.sql
└── README.md           # Este arquivo
```

### Descrição dos Diretórios

| Diretório | Quando Executa | Propósito | Idempotente? |
|-----------|----------------|-----------|--------------|
| **init-scripts/** | **Apenas na primeira inicialização** do container (volume vazio) | Criar usuários PostgreSQL, configurações de segurança | ✅ Sim (usa `IF NOT EXISTS`) |
| **migrations/** | Manualmente pelo DBA ou CI/CD (cada vez que schema mudar) | Criar/alterar tabelas, índices, constraints | ⚠️ Depende (usar transações) |
| **seeds/** | Manualmente pelo DBA após migrations | Popular dados iniciais (planos, config, demos) | ✅ Sim (usa `ON CONFLICT DO NOTHING`) |

---

## 🔐 Usuários PostgreSQL (Least Privilege)

### Princípio de Segurança

**⚠️ NUNCA use o usuário `postgres` (superuser) na aplicação!**

A aplicação deve usar usuários dedicados com permissões limitadas, seguindo o **Princípio do Menor Privilégio** (Least Privilege).

### Usuários Disponíveis

| Usuário | Propósito | Permissões | Uso |
|---------|-----------|------------|-----|
| **postgres** | Administração de banco de dados | **SUPERUSER** (todos os privilégios) | **DBA APENAS** - Tarefas administrativas, troubleshooting |
| **mytrader_app** | Aplicação .NET | - SELECT, INSERT, UPDATE, DELETE (CRUD)<br>- USAGE em sequences<br>- CREATE TABLE (EF Core migrations)<br>- **Limitado ao database `mytrader_dev`** | **Connection string da aplicação** |
| **mytrader_readonly** | Analytics, Reports, Backups | - SELECT apenas<br>- **Limitado ao database `mytrader_dev`** | Ferramentas BI, backups, analytics read-only |

### Benefícios de Segurança

✅ **SQL Injection Mitigado:** Mesmo que atacante ganhe acesso via SQL injection:
- ❌ NÃO pode dropar databases (`DROP DATABASE` bloqueado)
- ❌ NÃO pode criar superusers (`CREATE ROLE` bloqueado)
- ❌ NÃO pode acessar databases do sistema (`template0`, `template1`, `postgres`)
- ❌ NÃO pode executar comandos administrativos (`ALTER SYSTEM`)

✅ **Defense in Depth:** Bug na aplicação não pode causar dano catastrófico (limitado a CRUD)

✅ **Audit Trail:** Separação clara entre ações da aplicação vs ações administrativas nos logs

✅ **Compliance:** Atende LGPD Art. 46 (medidas técnicas), SOC2/ISO27001 (RBAC)

### Connection Strings

```yaml
# ❌ INSEGURO (NUNCA FAZER):
ConnectionStrings__DefaultConnection=Host=database;Port=5432;Database=mytrader_dev;Username=postgres;Password=xxx

# ✅ SEGURO (CORRETO):
ConnectionStrings__DefaultConnection=Host=database;Port=5432;Database=mytrader_dev;Username=mytrader_app;Password=xxx

# ✅ READ-ONLY (Analytics, Backups):
ConnectionStrings__ReadOnlyConnection=Host=database;Port=5432;Database=mytrader_dev;Username=mytrader_readonly;Password=xxx
```

### Como os Usuários São Criados

Os usuários são criados automaticamente pelo script:

**Arquivo:** [init-scripts/01-create-app-user.sql](init-scripts/01-create-app-user.sql)

**Execução:** Automática na primeira inicialização do container PostgreSQL via `/docker-entrypoint-initdb.d/`

**Idempotência:** ✅ Sim (usa `IF NOT EXISTS` - seguro re-executar)

---

## 🌐 Multi-Environment Password Strategy

### Senhas por Ambiente

⚠️ **CRÍTICO:** Init script (`01-create-app-user.sql`) usa senhas default apropriadas APENAS para **development**.

Para **staging** e **production**, você DEVE alterar as senhas usando a migration `002_update_production_passwords.sql`.

| Ambiente | Senha Padrão (Init Script) | Ação Requerida |
|----------|---------------------------|----------------|
| **Development** | `app_dev_password_123` | ✅ OK - Senha simples aceitável para dev local |
| **Staging** | `app_dev_password_123` | ⚠️ **ALTERAR** - Usar senha forte via migration 002 |
| **Production** | `app_dev_password_123` | 🔴 **ALTERAR OBRIGATÓRIO** - Usar senha forte via migration 002 |

### Como Alterar Senhas (Staging/Production)

**Arquivo:** [migrations/002_update_production_passwords.sql](migrations/002_update_production_passwords.sql)

**Execução Recomendada (via environment variables):**

```bash
# 1. Definir senhas como variáveis de ambiente (não ficam no histórico bash)
export DB_APP_PASSWORD="SuaSenhaForte123!@#"
export DB_READONLY_PASSWORD="SuaSenhaReadonly456!@#"

# 2. Executar migration passando variáveis
psql -U postgres -d mytrader_staging \
  -f 04-database/migrations/002_update_production_passwords.sql \
  -v app_password="$DB_APP_PASSWORD" \
  -v readonly_password="$DB_READONLY_PASSWORD"

# 3. Atualizar .env.staging com novas senhas
# ConnectionStrings__DefaultConnection=...;Password=$DB_APP_PASSWORD

# 4. Reiniciar aplicação
docker compose -f 05-infra/docker/docker-compose.staging.yml \
  --env-file 05-infra/configs/.env.staging restart
```

**Execução Interativa (mais segura - senhas não aparecem):**

```bash
# 1. Conectar ao database
psql -U postgres -d mytrader_staging

# 2. Definir variáveis via prompt (senhas NÃO aparecem no terminal)
\set app_password `read -s -p "App Password: " pwd; echo $pwd`
\set readonly_password `read -s -p "Readonly Password: " pwd; echo $pwd`

# 3. Executar migration
\i 04-database/migrations/002_update_production_passwords.sql
```

### Requisitos de Senha (Staging/Production)

**Senha FORTE obrigatória:**
- ✅ Mínimo 16 caracteres
- ✅ Maiúsculas + minúsculas + números + símbolos
- ✅ Diferente entre staging e production
- ✅ Armazenada em gerenciador de senhas (1Password, Bitwarden, etc)
- ✅ Rotação trimestral recomendada

**Exemplos de senhas FORTES:**
```
✅ K7#mP9$vL2@nQ8!xR4^wT6*yU3
✅ Bx9#Ln2@Wp7$Mq5!Rt8^Ks4*Jv1
❌ senha123
❌ mytrader2024
❌ app_dev_password_123 (apenas dev!)
```

### Integração com .env Strategy (PE-00)

Conforme documentado em [PE-00-Environments-Setup.md](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md), cada ambiente tem seu próprio arquivo `.env`:

```bash
# .env.dev (Development - senhas simples OK)
DB_APP_USER=mytrader_app
DB_APP_PASSWORD=app_dev_password_123
DB_READONLY_USER=mytrader_readonly
DB_READONLY_PASSWORD=readonly_dev_password_123

# .env.staging (Staging - senhas FORTES)
DB_APP_USER=mytrader_app
DB_APP_PASSWORD=<SENHA_FORTE_STAGING>  # Alterar via migration 002
DB_READONLY_USER=mytrader_readonly
DB_READONLY_PASSWORD=<SENHA_FORTE_READONLY_STAGING>

# .env.production (Production - senhas MUITO FORTES)
DB_APP_USER=mytrader_app
DB_APP_PASSWORD=<SENHA_FORTE_PRODUCTION>  # Alterar via migration 002
DB_READONLY_USER=mytrader_readonly
DB_READONLY_PASSWORD=<SENHA_FORTE_READONLY_PRODUCTION>
```

**IMPORTANTE:** Senhas de staging e production devem ser DIFERENTES entre si.

---

## 🔒 Security Best Practices

### 1. Princípio do Menor Privilégio (Least Privilege)

✅ **DO:**
- Usar `mytrader_app` para aplicação .NET
- Usar `mytrader_readonly` para analytics/backups
- Reservar `postgres` superuser APENAS para tarefas de DBA

❌ **DON'T:**
- NUNCA usar `postgres` na connection string da aplicação
- NUNCA dar permissões de superuser para aplicação
- NUNCA usar mesma senha em dev/staging/production

### 2. Gestão de Credenciais

✅ **DO:**
- Armazenar senhas em gerenciador de senhas (1Password, Bitwarden)
- Usar variáveis de ambiente para passar senhas (não hardcode)
- Rotacionar senhas trimestralmente (production e staging)
- Usar senhas DIFERENTES para cada ambiente

❌ **DON'T:**
- NUNCA commitar senhas reais no Git
- NUNCA compartilhar senhas via Slack/Email/WhatsApp
- NUNCA usar senhas fracas em staging/production
- NUNCA reutilizar senhas entre ambientes

### 3. Defense in Depth

**Camadas de segurança implementadas:**

| Camada | Proteção | Benefício |
|--------|----------|-----------|
| **Network** | Database não exposto à internet (apenas containers internos) | Atacante precisa comprometer container primeiro |
| **Authentication** | Senhas fortes + usuários segregados | Credential stuffing mitigado |
| **Authorization** | Least Privilege (CRUD apenas, sem DROP DATABASE) | SQL injection não pode causar dano catastrófico |
| **Audit** | Logs separados por usuário (app vs admin) | Detecção de anomalias e troubleshooting |

### 4. Compliance

**LGPD (Lei Geral de Proteção de Dados):**
- ✅ Art. 46, §1º - "medidas técnicas e administrativas aptas a proteger os dados"
- ✅ Segregação de privilégios é "medida técnica essencial"
- ✅ Senhas fortes em produção atendem requisito de proteção

**SOC 2 / ISO 27001:**
- ✅ Controle de acesso baseado em função (RBAC)
- ✅ Auditoria de ações administrativas vs aplicação
- ✅ Rotação de credenciais documentada

### 5. Rotação de Senhas

**Frequência Recomendada:**
- **Production:** Trimestral (a cada 3 meses)
- **Staging:** Semestral (a cada 6 meses)
- **Development:** Não necessário (senha simples, ambiente local)

**Procedimento de Rotação:**

```bash
# 1. Gerar nova senha forte (16+ caracteres)
# 2. Executar migration 002 com nova senha
export DB_APP_PASSWORD="<NOVA_SENHA>"
psql -U postgres -d mytrader_prod -f 002_update_production_passwords.sql \
  -v app_password="$DB_APP_PASSWORD" \
  -v readonly_password="$DB_READONLY_PASSWORD"

# 3. Atualizar .env.prod
# 4. Reiniciar aplicação
docker compose -f 05-infra/docker/docker-compose.prod.yml \
  --env-file 05-infra/configs/.env.prod restart

# 5. Testar conectividade
docker compose -f 05-infra/docker/docker-compose.prod.yml --env-file 05-infra/configs/.env.prod logs api | grep "Database connection established"

# 6. Atualizar gerenciador de senhas
# 7. Documentar rotação (data, quem executou)
```

---

## 🚀 Como Executar Migrations

### Ordem de Execução

**⚠️ IMPORTANTE:** Executar na ordem correta para evitar erros de dependência.

```bash
# 1. Init Scripts (automático na primeira vez)
#    Executado automaticamente pelo Docker via /docker-entrypoint-initdb.d/
#    Se já executou: pular (não precisa re-executar)

# 2. Schema Migrations (manualmente ou CI/CD)
psql -h localhost -U mytrader_app -d mytrader_dev -f 04-database/migrations/001_create_user_management_schema.sql

# 3. Seed Data (manualmente)
psql -h localhost -U mytrader_app -d mytrader_dev -f 04-database/seeds/001_seed_user_management_defaults.sql
```

### Ambientes

#### Development (Docker Compose)

```bash
# Subir database
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# Verificar se init-scripts executou
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev logs database | grep "Creating application users"

# Conectar como mytrader_app
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev

# Executar migrations (se necessário)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev -f /db-scripts/migrations/001_create_user_management_schema.sql

# Executar seeds
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev -f /db-scripts/seeds/001_seed_user_management_defaults.sql
```

#### Staging/Production

```bash
# Usar credenciais do ambiente (via .env)
psql -h $DB_HOST -U $DB_APP_USER -d $DB_NAME -f 04-database/migrations/001_create_user_management_schema.sql
psql -h $DB_HOST -U $DB_APP_USER -d $DB_NAME -f 04-database/seeds/001_seed_user_management_defaults.sql
```

### Rollback Strategy

```sql
-- Rollback migrations (ordem INVERSA da criação)
-- CUIDADO: Vai dropar TODOS os dados!

-- 1. Drop tabelas do User Management BC
DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS SystemConfigs CASCADE;
DROP TABLE IF EXISTS SubscriptionPlans CASCADE;
```

---

## 🧪 Validação e Testes

### Verificar Usuários Criados

```bash
# Conectar como postgres (admin)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U postgres -d mytrader_dev

# Listar usuários
\du

# Expected output:
# postgres         | Superuser, Create role, Create DB
# mytrader_app     | Cannot login (limited permissions)
# mytrader_readonly| Cannot login (read-only)
```

### Testar Permissões do `mytrader_app`

```sql
-- Conectar como mytrader_app
\c mytrader_dev mytrader_app

-- ✅ CRUD deve funcionar
INSERT INTO Users (Id, Email, PasswordHash, FullName, DisplayName, Role, Status)
VALUES (gen_random_uuid(), 'test@test.com', 'hash', 'Test User', 'TestU', 'Administrator', 'Active');

SELECT * FROM Users WHERE Email = 'test@test.com';
DELETE FROM Users WHERE Email = 'test@test.com';

-- ✅ CREATE TABLE deve funcionar (migrations)
CREATE TABLE test_table (id INT);
DROP TABLE test_table;

-- ❌ Operações administrativas devem FALHAR
DROP DATABASE mytrader_dev;        -- ERROR: permission denied
CREATE ROLE hacker;                -- ERROR: permission denied
\c template1;                      -- ERROR: permission denied
```

### Testar Permissões do `mytrader_readonly`

```sql
-- Conectar como mytrader_readonly
\c mytrader_dev mytrader_readonly

-- ✅ SELECT deve funcionar
SELECT * FROM Users;

-- ❌ Modificações devem FALHAR
INSERT INTO Users (Id, Email, PasswordHash, FullName, DisplayName, Role, Status)
VALUES (gen_random_uuid(), 'test@test.com', 'hash', 'Test', 'Test', 'Trader', 'Active');
-- ERROR: permission denied for table Users

UPDATE Users SET Email = 'hacker@test.com';  -- ERROR
DELETE FROM Users;                           -- ERROR
```

### Verificar Schema Migrations

```sql
-- Listar tabelas criadas
\dt

-- Expected output:
# SubscriptionPlans
# SystemConfigs
# Users

-- Verificar dados seed
SELECT Name, PriceMonthlyAmount FROM SubscriptionPlans ORDER BY PriceMonthlyAmount;

-- Expected output:
# Básico   | 0.00
# Pleno    | 99.90
# Consultor| 299.00
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
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev ps database

# Expected output: database running on port 5432
```

**What happens:**
- PostgreSQL 15 container starts
- Init scripts in `04-database/init-scripts/` execute automatically (creates users)
- Named volume `mytrader_postgres_data` persists data

### Step 2: Verify Database Connection

```bash
# Connect to database as application user
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev

# Expected output: PostgreSQL prompt
# mytrader_dev=>
```

**Test connection:**
```sql
-- List tables (should be empty initially)
\dt

-- Check current user
SELECT current_user;  -- Should show: mytrader_app

-- Exit
\q
```

### Step 3: Apply SQL Migrations (created by DBA)

**Important:** DBA creates migrations FIRST in `04-database/migrations/`. SE only executes them.

```bash
# Execute migration (example for EPIC-01)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev \
  -f /db-scripts/migrations/001_create_user_management_schema.sql

# Verify tables created
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev \
  -c "\dt"

# Expected output: List of tables from migration
#  Schema |        Name         | Type  |     Owner
# --------+---------------------+-------+----------------
#  public | Users               | table | mytrader_app
#  public | SubscriptionPlans   | table | mytrader_app
```

### Step 4: Scaffold EF Core Models from Database

**Critical:** EF models are GENERATED from database, not created via Code-First migrations.

```bash
# Navigate to backend project
cd 02-backend

# Scaffold command (generates C# classes from database schema)
dotnet ef dbcontext scaffold \
  "Host=localhost;Database=mytrader_dev;Username=mytrader_app;Password=app_dev_password_123" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir src/Infrastructure/Data/Models \
  --context-dir src/Infrastructure/Data \
  --context ApplicationDbContext \
  --no-onconfiguring \
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
cd 02-backend/tests/MyTrader.IntegrationTests
dotnet add package Testcontainers.PostgreSql --version 3.x

# Create test fixture (see TestContainers section for full code)
# Tests will spin up PostgreSQL container, apply migrations, run tests, dispose container
```

### Common Workflows

#### Workflow 1: Start Development (First Time)

```bash
# 1. Start database
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# 2. Verify init-scripts executed (creates users)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev logs database | grep "Creating application users"

# 3. Apply DBA migrations
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev \
  -f /db-scripts/migrations/001_create_user_management_schema.sql

# 4. Scaffold EF models
cd 02-backend
dotnet ef dbcontext scaffold \
  "Host=localhost;Database=mytrader_dev;Username=mytrader_app;Password=app_dev_password_123" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir src/Infrastructure/Data/Models \
  --context-dir src/Infrastructure/Data \
  --context ApplicationDbContext \
  --no-onconfiguring \
  --force

# 5. Run application
dotnet run --project src/Api
```

#### Workflow 2: Update After New Migration (Subsequent Epics)

```bash
# 1. DBA creates new migration (e.g., 002_create_strategy_management_schema.sql)
# 2. Apply new migration
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev \
  -f /db-scripts/migrations/002_create_strategy_management_schema.sql

# 3. Re-scaffold (updates existing + adds new entities)
cd 02-backend
dotnet ef dbcontext scaffold \
  "Host=localhost;Database=mytrader_dev;Username=mytrader_app;Password=app_dev_password_123" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir src/Infrastructure/Data/Models \
  --context-dir src/Infrastructure/Data \
  --context ApplicationDbContext \
  --no-onconfiguring \
  --force

# 4. Review changes
git diff src/Infrastructure/Data/Models/

# 5. Create partial classes for new entities (see Scaffolding section)
```

#### Workflow 3: Reset Database (Clean Start)

```bash
# ⚠️ WARNING: This deletes all data!

# 1. Stop containers
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev down

# 2. Remove database volume
docker volume rm mytrader_postgres_data

# 3. Start again (init-scripts will re-execute)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# 4. Re-apply all migrations in order
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev \
  -f /db-scripts/migrations/001_create_user_management_schema.sql
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev \
  -f /db-scripts/migrations/002_create_strategy_management_schema.sql
```

### Troubleshooting

#### Problem: "Connection refused" when scaffolding

**Cause:** Database container not running or wrong host/port

**Solution:**
```bash
# Check container status
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev ps database

# If not running, start it
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# Test connection
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev -c "SELECT 1"
```

#### Problem: "Password authentication failed"

**Cause:** Wrong password in connection string

**Solution:**
```bash
# Development password is always: app_dev_password_123
# Check .env file or use correct connection string:
"Host=localhost;Database=mytrader_dev;Username=mytrader_app;Password=app_dev_password_123"
```

#### Problem: "No tables found" when scaffolding

**Cause:** Migrations not applied yet

**Solution:**
```bash
# List tables
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev -c "\dt"

# If empty, apply migrations
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev \
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
cd 02-backend/tests/MyTrader.IntegrationTests

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
// tests/MyTrader.IntegrationTests/DatabaseFixture.cs
using Npgsql;
using Testcontainers.PostgreSql;
using Xunit;

namespace MyTrader.IntegrationTests;

public class DatabaseFixture : IAsyncLifetime
{
    private readonly PostgreSqlContainer _container = new PostgreSqlBuilder()
        .WithDatabase("mytrader_test")
        .WithUsername("mytrader_app")
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
// tests/MyTrader.IntegrationTests/UserRepositoryIntegrationTests.cs
using Microsoft.EntityFrameworkCore;
using Xunit;
using MyTrader.Domain.Entities;
using MyTrader.Infrastructure.Data;
using MyTrader.Infrastructure.Repositories;

namespace MyTrader.IntegrationTests;

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
    .WithDatabase("mytrader_test")
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
  "Host=localhost;Port=5432;Database=mytrader_dev;Username=mytrader_app;Password=app_dev_password_123" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir Infrastructure/Data/Models \
  --context-dir Infrastructure/Data \
  --context ApplicationDbContext \
  --no-onconfiguring \
  --force
```

**Replace placeholders:**
- `mytrader_dev` → Database name (e.g., `mytrader_dev`)
- `mytrader_app` → Database user (e.g., `mytrader_app`)
- `app_dev_password_123` → User password

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
cd src/MyTrader.WebAPI

dotnet ef dbcontext scaffold \
  "Host=localhost;Port=5432;Database=mytrader_dev;Username=mytrader_app;Password=app_dev_password_123" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --output-dir Infrastructure/Data/Models \
  --context-dir Infrastructure/Data \
  --context ApplicationDbContext \
  --no-onconfiguring
```

**Generated files:**
```
src/MyTrader.WebAPI/
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
cd src/MyTrader.WebAPI

dotnet ef dbcontext scaffold \
  "Host=localhost;Port=5432;Database=mytrader_dev;Username=mytrader_app;Password=app_dev_password_123" \
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
  "Host=localhost;Port=5432;Database=mytrader_dev;Username=mytrader_app;Password=app_dev_password_123" \
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
- Test connection: `psql -h localhost -U mytrader_app -d mytrader_dev`

**Error: "Could not load assembly 'Npgsql.EntityFrameworkCore.PostgreSQL'"**
- Install NuGet package: `dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL`

**Generated entities have `public virtual` properties**
- This is normal for EF Core (enables lazy loading and change tracking)
- Keep `virtual` keyword unless you need to disable proxies

---

## 📊 Status das Migrations

### EPIC-01-A - User Management

| Migration | Status | Data | Descrição |
|-----------|--------|------|-----------|
| [001_create_user_management_schema.sql](migrations/001_create_user_management_schema.sql) | ✅ Criado | 2025-10-26 | Schema completo: SubscriptionPlans, SystemConfigs, Users |
| [002_update_production_passwords.sql](migrations/002_update_production_passwords.sql) | ✅ Criado | 2025-10-26 | Atualização de senhas para staging/production |
| [001_seed_user_management_defaults.sql](seeds/001_seed_user_management_defaults.sql) | ✅ Criado | 2025-10-26 | Planos, config, admin, demos |

---

## 🔗 Artefatos Relacionados

Esta seção conecta o README operacional com a documentação estratégica do projeto.

| Artefato | Propósito | Quando Consultar |
|----------|-----------|------------------|
| **[DBA-01-EPIC-01-A-Database-Design-Decisions.md](../00-doc-ddd/05-database-design/DBA-01-EPIC-01-A-Database-Design-Decisions.md)** | Decisões arquiteturais de database design (Value Objects, índices, constraints, trade-offs) | Para entender **POR QUÊ** o schema é modelado dessa forma, avaliar alternativas, modificar estrutura |
| **[FEEDBACK-003-DBA-PE-PostgreSQL-User-Security.md](../00-doc-ddd/00-feedback/FEEDBACK-003-DBA-PE-PostgreSQL-User-Security.md)** | Resolução: Segregação de usuários PostgreSQL (Princípio do Menor Privilégio) | Para entender a implementação de segurança, benefícios (SQL injection mitigado), compliance |
| **[PE-00-Environments-Setup.md](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md)** | Docker Compose, infraestrutura, connection strings por ambiente | Para entender como containers são configurados, volume mounts, init-scripts integration |
| **[SEC-00-Security-Baseline.md](../00-doc-ddd/09-security/SEC-00-Security-Baseline.md)** | Baseline de segurança (Database User Segregation section) | Para entender security benefits, compliance (LGPD/SOC2), defense in depth strategy |

---

## 📚 Referências

### Documentação Interna

- **Database Design Decisions:** [00-doc-ddd/05-database-design/DBA-01-EPIC-01-A-Database-Design-Decisions.md](../00-doc-ddd/05-database-design/DBA-01-EPIC-01-A-Database-Design-Decisions.md)
  - Decisões de modelagem (Value Objects, índices, constraints)
  - Queries esperadas e estimativas de performance
  - Trade-offs e justificativas técnicas

- **FEEDBACK-003 - PostgreSQL User Security:** [00-doc-ddd/00-feedback/FEEDBACK-003-DBA-PE-PostgreSQL-User-Security.md](../00-doc-ddd/00-feedback/FEEDBACK-003-DBA-PE-PostgreSQL-User-Security.md)
  - Resolução: Segregação de usuários PostgreSQL
  - Princípio do Menor Privilégio (Least Privilege)
  - Security benefits e compliance (LGPD, SOC2)

- **Platform Engineering Setup:** [00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md)
  - Docker Compose configuration
  - Connection strings por ambiente
  - Volume mounts e init-scripts

- **Security Baseline:** [00-doc-ddd/09-security/SEC-00-Security-Baseline.md](../00-doc-ddd/09-security/SEC-00-Security-Baseline.md)
  - Database User Segregation section
  - Security benefits documentados

### Documentação Externa

- **PostgreSQL Documentation:** https://www.postgresql.org/docs/15/
- **PostgreSQL GRANT Documentation:** https://www.postgresql.org/docs/15/sql-grant.html
- **PostgreSQL User Management:** https://www.postgresql.org/docs/15/user-manag.html
- **CIS PostgreSQL Benchmark:** https://www.cisecurity.org/benchmark/postgresql
  - Section 2.1: Database User Segregation

---

## 🔧 Troubleshooting

### Problema: Init script não executou

**Sintoma:** Usuários `mytrader_app` e `mytrader_readonly` não existem

**Causa:** Volume do PostgreSQL já existia (init scripts só executam na primeira vez)

**Solução:**
```bash
# 1. Parar container
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev down

# 2. Remover volume do database (⚠️ CUIDADO: apaga dados!)
docker volume rm mytrader-postgres-data

# 3. Subir novamente (init script vai executar)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up database -d

# 4. Verificar logs
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev logs database | grep "Creating application users"
```

### Problema: Permission denied ao executar migration

**Sintoma:** `ERROR: permission denied for schema public`

**Causa:** Conectou com usuário errado ou usuário não tem permissões

**Solução:**
```bash
# Verificar usuário atual
\conninfo

# Conectar com mytrader_app
\c mytrader_dev mytrader_app

# Se ainda falhar, re-executar init-scripts
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U postgres -d mytrader_dev -f /docker-entrypoint-initdb.d/01-create-app-user.sql
```

### Problema: Aplicação .NET não conecta ao banco

**Sintoma:** `Npgsql.NpgsqlException: password authentication failed for user "mytrader_app"`

**Causa:** Senha incorreta no `.env` ou connection string

**Solução:**
```bash
# 1. Verificar connection string no .env
cat 05-infra/configs/.env | grep ConnectionStrings__DefaultConnection

# 2. Deve ser:
# ConnectionStrings__DefaultConnection=Host=database;Port=5432;Database=mytrader_dev;Username=mytrader_app;Password=app_dev_password_123

# 3. Se errado, corrigir .env e reiniciar aplicação
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev restart api
```

---

**DBA Agent** - myTraderGEO Database Management
**Last Updated:** 2025-10-27
**Status:** ✅ EPIC-01-A migrations completed
