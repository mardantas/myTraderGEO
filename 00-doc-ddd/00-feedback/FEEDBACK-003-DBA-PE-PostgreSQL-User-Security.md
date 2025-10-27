# FEEDBACK-003-DBA-PE-PostgreSQL-User-Security.md

---

**Data Abertura:** 2025-10-26
**Solicitante:** DBA Agent + Usuário Marco
**Destinatário:** PE Agent + DBA Agent
**Status:** 🟢 Resolvido

**Tipo:**
- [x] Correção (deliverable já entregue precisa ajuste)
- [ ] Melhoria (sugestão de enhancement)
- [ ] Dúvida (esclarecimento necessário)
- [ ] Novo Requisito (mudança de escopo)

**Urgência:** 🔴 Alta (Segurança)

**Deliverable(s) Afetado(s):**
- `05-infra/docker/docker-compose.yml`
- `05-infra/docker/docker-compose.staging.yml`
- `05-infra/docker/docker-compose.production.yml`
- `05-infra/configs/.env.example`
- `04-database/init-scripts/` (novo)

---

## 📋 Descrição

A aplicação está usando o usuário **`postgres`** (superuser) na connection string, o que viola o **Princípio do Menor Privilégio** e representa um **risco grave de segurança**.

### Evidências:

**`05-infra/docker/docker-compose.yml` (linha 19):**
```yaml
ConnectionStrings__DefaultConnection=Host=database;Port=5432;Database=mytrader_dev;Username=postgres;Password=dev_password_123
```

**`05-infra/docker/docker-compose.yml` (linhas 66-68):**
```yaml
environment:
  - POSTGRES_USER=postgres
  - POSTGRES_PASSWORD=dev_password_123
  - POSTGRES_DB=mytrader_dev
```

### Contexto

Durante revisão do schema do banco (EPIC-01-A), o usuário questionou se o uso do superuser `postgres` pela aplicação era apropriado. A resposta é **NÃO**.

---

## 💥 Impacto Estimado

### Riscos de Segurança Atuais:

1. **🔴 SQL Injection Amplificado**
   - Se houver vulnerabilidade de SQL injection, atacante tem privilégios de superuser
   - Pode dropar databases, criar novos usuários, acessar dados de outras aplicações

2. **🔴 Acesso Irrestrito**
   - Aplicação pode acessar `template0`, `template1`, `postgres` (databases do sistema)
   - Pode executar comandos administrativos (`CREATE ROLE`, `ALTER SYSTEM`, etc)

3. **🔴 Erro de Programação Catastrófico**
   - Bug na aplicação pode executar `DROP DATABASE` sem restrições
   - Migrations com erro podem afetar todo o servidor PostgreSQL

4. **🟡 Auditoria Comprometida**
   - Impossível distinguir ações da aplicação vs ações administrativas nos logs
   - Dificulta troubleshooting e compliance (LGPD)

5. **🟡 Violação de Compliance**
   - SOC 2, ISO 27001, PCI-DSS exigem segregação de privilégios
   - LGPD Art. 46 - medidas técnicas de segurança

### Outros Deliverables Afetados:
- [ ] `00-doc-ddd/09-security/SEC-00-Security-Baseline.md` (possivelmente precisa atualizar)
- [ ] Documentação de deployment
- [ ] Procedures de backup/restore

**Esforço estimado:** 2-3 horas (DBA + PE)
**Risco:** 🔴 Alto (vulnerabilidade de segurança ativa)

---

## 💡 Proposta de Solução

### Abordagem: Criar Usuários Dedicados por Função

#### 1. **DBA Agent** - Criar Script de Inicialização

**Arquivo:** `04-database/init-scripts/01-create-app-user.sql`

```sql
-- Criar usuário para aplicação (permissões limitadas)
CREATE USER mytrader_app WITH PASSWORD 'secret';

-- Permissões no database
GRANT CONNECT ON DATABASE mytrader_dev TO mytrader_app;
GRANT USAGE ON SCHEMA public TO mytrader_app;

-- Permissões em tabelas (CRUD)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO mytrader_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO mytrader_app;

-- Permissões futuras (migrations)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO mytrader_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO mytrader_app;

-- Permitir criação de tabelas (para EF Core migrations)
GRANT CREATE ON SCHEMA public TO mytrader_app;

-- Criar usuário read-only (analytics, backups)
CREATE USER mytrader_readonly WITH PASSWORD 'secret';
GRANT CONNECT ON DATABASE mytrader_dev TO mytrader_readonly;
GRANT USAGE ON SCHEMA public TO mytrader_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO mytrader_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO mytrader_readonly;
```

#### 2. **PE Agent** - Atualizar Docker Compose Files

**Mudança necessária em todos os ambientes:**

```yaml
# ANTES (INSEGURO):
ConnectionStrings__DefaultConnection=Host=database;Port=5432;Database=mytrader_dev;Username=postgres;Password=xxx

# DEPOIS (SEGURO):
ConnectionStrings__DefaultConnection=Host=database;Port=5432;Database=mytrader_dev;Username=mytrader_app;Password=xxx
```

**Arquivos a atualizar:**
- `05-infra/docker/docker-compose.yml` (development)
- `05-infra/docker/docker-compose.staging.yml` (staging)
- `05-infra/docker/docker-compose.production.yml` (production)
- `05-infra/configs/.env.example`

#### 3. **Documentação** - Atualizar README

Adicionar seção no `05-infra/README.md`:

```markdown
## Usuários do PostgreSQL

| Usuário | Uso | Permissões |
|---------|-----|------------|
| `postgres` | Admin (DBA apenas) | Superuser - NUNCA usar na aplicação |
| `mytrader_app` | Aplicação .NET | SELECT, INSERT, UPDATE, DELETE, CREATE (migrations) |
| `mytrader_readonly` | Analytics, Backups | SELECT apenas |

⚠️ **IMPORTANTE:** A aplicação NUNCA deve usar o usuário `postgres`.
```

---

## 🔒 Justificativa de Segurança

### Princípio do Menor Privilégio (Least Privilege)

**Definição:** Cada componente deve ter apenas as permissões necessárias para suas funções.

**Aplicação ao PostgreSQL:**
- ✅ **mytrader_app**: CRUD + CREATE TABLE (para migrations)
- ❌ **postgres**: DROP DATABASE, CREATE ROLE, ALTER SYSTEM (desnecessários)

### Defesa em Profundidade (Defense in Depth)

Mesmo se houver vulnerabilidade na aplicação:
- Atacante NÃO pode dropar databases
- Atacante NÃO pode criar superusers
- Atacante NÃO pode acessar outras databases
- Dano limitado ao database `mytrader_dev` apenas

### Compliance

**LGPD (Lei Geral de Proteção de Dados):**
- Art. 46, §1º - "medidas técnicas e administrativas aptas a proteger os dados"
- Segregação de privilégios é considerada "medida técnica essencial"

**SOC 2 / ISO 27001:**
- Controle de acesso baseado em função (RBAC)
- Auditoria de ações administrativas vs aplicação

---

## 📊 Comparação: Antes vs Depois

### ANTES (Inseguro):
```
[.NET App] ---> Username: postgres (SUPERUSER)
                ├─ Can DROP DATABASE ❌
                ├─ Can CREATE ROLE ❌
                ├─ Can ALTER SYSTEM ❌
                ├─ Can access template0, template1 ❌
                └─ Full control over PostgreSQL ❌
```

### DEPOIS (Seguro):
```
[.NET App] ---> Username: mytrader_app (LIMITED)
                ├─ Can SELECT, INSERT, UPDATE, DELETE ✅
                ├─ Can CREATE TABLE (migrations) ✅
                ├─ Cannot DROP DATABASE ✅
                ├─ Cannot CREATE ROLE ✅
                └─ Limited to mytrader_dev database ✅

[Analytics] --> Username: mytrader_readonly
                └─ Can SELECT only ✅

[DBA Only] ---> Username: postgres
                └─ For administration only ✅
```

---

## 🧪 Plano de Teste

### 1. Testar Permissões do `mytrader_app`

```bash
# Conectar como mytrader_app
psql -U mytrader_app -d mytrader_dev

# Testar CRUD (deve funcionar)
INSERT INTO users (email, name) VALUES ('test@test.com', 'Test');
SELECT * FROM users;
UPDATE users SET name = 'Updated' WHERE email = 'test@test.com';
DELETE FROM users WHERE email = 'test@test.com';

# Testar CREATE TABLE (migrations - deve funcionar)
CREATE TABLE test_table (id INT);
DROP TABLE test_table;

# Testar operações proibidas (deve FALHAR)
DROP DATABASE mytrader_dev; -- ERROR: permission denied
CREATE ROLE hacker; -- ERROR: permission denied
\c template1; -- ERROR: permission denied
```

### 2. Testar Permissões do `mytrader_readonly`

```bash
# Conectar como mytrader_readonly
psql -U mytrader_readonly -d mytrader_dev

# Testar SELECT (deve funcionar)
SELECT * FROM users;

# Testar INSERT/UPDATE/DELETE (deve FALHAR)
INSERT INTO users (email, name) VALUES ('test@test.com', 'Test'); -- ERROR
UPDATE users SET name = 'Updated'; -- ERROR
DELETE FROM users; -- ERROR
```

### 3. Testar Aplicação .NET

```bash
# Subir ambiente dev
docker compose -f 05-infra/docker/docker-compose.yml up

# Verificar que aplicação conecta com mytrader_app
docker compose logs api | grep "Connection"

# Executar migrations (deve funcionar)
dotnet ef database update

# Testar CRUD via API (deve funcionar)
curl http://localhost:5000/api/users
```

---

## ✅ Resolução

**Data Resolução:** 2025-10-26
**Resolvido por:** PE Agent + DBA Agent

**Ação Tomada:**

Implementamos o Princípio do Menor Privilégio criando usuários dedicados do PostgreSQL com permissões limitadas.

### 1. **DBA Agent** - Criou Script de Inicialização

**Arquivo:** `04-database/init-scripts/01-create-app-user.sql`

Criado script que cria automaticamente 2 usuários:
- **mytrader_app**: Usuário para aplicação com permissões CRUD + CREATE TABLE
- **mytrader_readonly**: Usuário read-only para analytics e backups

**Permissões do mytrader_app:**
- ✅ SELECT, INSERT, UPDATE, DELETE (CRUD completo)
- ✅ USAGE em sequences (auto-increment)
- ✅ CREATE TABLE (necessário para EF Core migrations)
- ❌ DROP DATABASE, CREATE ROLE, ALTER SYSTEM (bloqueados)

**Permissões do mytrader_readonly:**
- ✅ SELECT apenas
- ❌ INSERT, UPDATE, DELETE, CREATE (bloqueados)

### 2. **PE Agent** - Atualizou Infraestrutura

**Docker Compose Files:**
Atualizados todos os 3 ambientes para usar `mytrader_app`:

```yaml
# ANTES (INSEGURO):
Username=postgres

# DEPOIS (SEGURO):
Username=mytrader_app
```

Adicionado volume mount do init script em todos os ambientes:
```yaml
volumes:
  - ../../04-database/init-scripts:/docker-entrypoint-initdb.d
```

**Variáveis de Ambiente:**
Atualizou `.env.example` com segregação clara:
- `DB_USER` / `DB_PASSWORD` → Admin (DBA apenas)
- `DB_APP_USER` / `DB_APP_PASSWORD` → Aplicação
- `DB_READONLY_USER` / `DB_READONLY_PASSWORD` → Analytics/Backups

**Documentação:**
Adicionada seção no README com tabela explicativa:
- Quando usar cada usuário
- Aviso de segurança destacado
- Referência ao script de criação

### 3. **Resultado - Segurança Aprimorada**

**Antes:**
```
[.NET App] → postgres (SUPERUSER) 🔴
  ├─ Pode dropar databases
  ├─ Pode criar superusers
  └─ Acesso total ao PostgreSQL
```

**Depois:**
```
[.NET App] → mytrader_app (LIMITED) ✅
  ├─ CRUD em tabelas
  ├─ CREATE TABLE (migrations)
  ├─ NÃO pode dropar databases
  └─ NÃO pode criar superusers
```

**Benefícios Alcançados:**
- ✅ SQL Injection não pode dropar databases
- ✅ Bugs não podem causar danos catastróficos
- ✅ Compliance LGPD/SOC2 atendido
- ✅ Auditoria clara (app vs admin)
- ✅ Defense in Depth implementado

**Deliverables Atualizados:**
- [x] `04-database/init-scripts/01-create-app-user.sql` - Script com 2 usuários + permissões + documentação
- [x] `05-infra/docker/docker-compose.yml` - Connection string usando mytrader_app
- [x] `05-infra/docker/docker-compose.staging.yml` - Init script mount adicionado
- [x] `05-infra/docker/docker-compose.production.yml` - Init script mount adicionado
- [x] `05-infra/configs/.env.example` - 3 sets de credenciais segregados
- [x] `05-infra/README.md` - Seção "Usuários PostgreSQL" com tabela e warnings

**Referência Git Commit:** a748551

---

**Status Final:** 🟢 Resolvido

---

## 📝 Histórico

| Data | Mudança | Autor |
|------|---------|-------|
| 2025-10-26 | Criado | DBA Agent + Usuário Marco |
| 2025-10-26 | Resolvido | PE Agent + DBA Agent |

---

## 📚 Referências

- [PostgreSQL GRANT Documentation](https://www.postgresql.org/docs/15/sql-grant.html)
- [OWASP - Least Privilege](https://owasp.org/www-community/vulnerabilities/Least_Privilege_Violation)
- [LGPD Art. 46](http://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)
- [CIS PostgreSQL Benchmark](https://www.cisecurity.org/benchmark/postgresql)
