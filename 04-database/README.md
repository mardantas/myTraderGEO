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
│   └── 001_create_user_management_schema.sql
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

# 3. Atualizar .env.production
# 4. Reiniciar aplicação
docker compose -f docker-compose.production.yml \
  --env-file .env.production restart

# 5. Testar conectividade
docker compose logs api | grep "Database connection established"

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
docker compose -f 05-infra/docker/docker-compose.yml up database -d

# Verificar se init-scripts executou
docker compose logs database | grep "Creating application users"

# Conectar como mytrader_app
docker compose exec database psql -U mytrader_app -d mytrader_dev

# Executar migrations (se necessário)
docker compose exec database psql -U mytrader_app -d mytrader_dev -f /app/migrations/001_create_user_management_schema.sql

# Executar seeds
docker compose exec database psql -U mytrader_app -d mytrader_dev -f /app/seeds/001_seed_user_management_defaults.sql
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
docker compose exec database psql -U postgres -d mytrader_dev

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

## 📊 Status das Migrations

### EPIC-01-A - User Management

| Migration | Status | Data | Descrição |
|-----------|--------|------|-----------|
| [001_create_user_management_schema.sql](migrations/001_create_user_management_schema.sql) | ✅ Criado | 2025-10-26 | Schema completo: SubscriptionPlans, SystemConfigs, Users |
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
docker compose down

# 2. Remover volume do database (⚠️ CUIDADO: apaga dados!)
docker volume rm mytrader-postgres-data

# 3. Subir novamente (init script vai executar)
docker compose up database -d

# 4. Verificar logs
docker compose logs database | grep "Creating application users"
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
docker compose exec database psql -U postgres -d mytrader_dev -f /docker-entrypoint-initdb.d/01-create-app-user.sql
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
docker compose restart api
```

---

**DBA Agent** - myTraderGEO Database Management
**Last Updated:** 2025-10-27
**Status:** ✅ EPIC-01-A migrations completed
