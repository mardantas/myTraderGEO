<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# FEEDBACK-006-DBA-PE-Multi-Environment-Credentials.md

> **Objetivo:** Alinhar deliverables do DBA Agent com estratégia multi-environment do PE Agent (FEEDBACK-004).

---

**Data Abertura:** 2025-01-28
**Solicitante:** DBA Agent (análise de impacto de FEEDBACK-004)
**Destinatário:** DBA Agent + PE Agent
**Status:** 🔴 Aberto

**Tipo:**
- [x] Correção (deliverable já entregue precisa ajuste)
- [ ] Melhoria (sugestão de enhancement)
- [ ] Dúvida (esclarecimento necessário)
- [ ] Novo Requisito (mudança de escopo)

**Urgência:** 🟡 Média (Segurança + Deployment)

**Deliverable(s) Afetado(s):**
- `04-database/init-scripts/01-create-app-user.sql` (hardcoded passwords)
- `04-database/README.md` (falta multi-environment docs)
- `05-infra/configs/.env.example` (validar se documenta DB credentials)

---

## 📋 Descrição

Durante análise de impacto dos FEEDBACKs 003, 004 e 005 nos deliverables do DBA Agent, foram identificadas divergências com a nova estratégia multi-environment do PE Agent (FEEDBACK-004).

### Problema Principal: Hardcoded Passwords no Init Script

**Arquivo:** `04-database/init-scripts/01-create-app-user.sql`

**Linhas 41 e 90:** Senhas de desenvolvimento hardcoded no script SQL

```sql
-- Linha 41 - HARDCODED DEV PASSWORD!
CREATE USER mytrader_app WITH
    PASSWORD 'app_dev_password_123'  -- ❌ PROBLEMA

-- Linha 90 - HARDCODED DEV PASSWORD!
CREATE USER mytrader_readonly WITH
    PASSWORD 'readonly_dev_password_123'  -- ❌ PROBLEMA
```

**Por que é problema:**
1. **Mesma senha em TODOS os ambientes** (dev, staging, production)
2. **Senha fraca em produção** (viola compliance LGPD/SOC2)
3. **Senha versionada no Git** (mesmo em arquivo SQL, ainda é visível)
4. **Não alinhado com estratégia .env do PE-00** (.env.dev, .env.staging, .env.production)

### Contexto

O FEEDBACK-004 (PE Agent) implementou estratégia `.env` por ambiente:
- `.env.dev` → Development (senhas simples OK)
- `.env.staging` → Staging (senhas fortes)
- `.env.production` → Production (senhas muito fortes + rotação)

O init script do DBA foi criado ANTES desta estratégia estar consolidada (FEEDBACK-003), então usa senhas hardcoded apropriadas apenas para development.

---

## 💥 Impacto Estimado

### Riscos Atuais:

1. **🟡 Senha Fraca em Produção**
   - Se init script rodar em production com senhas default, database fica vulnerável
   - Violação de compliance (LGPD Art. 46, SOC2, ISO 27001)

2. **🟡 Falta de Segregação**
   - Mesma senha em dev/staging/production não permite auditoria
   - Dificulta rotação de credenciais (staging ≠ production)

3. **🟢 Exposição no Git**
   - Senhas estão em SQL (não em .env), mas ainda visíveis no histórico
   - Baixo risco pois são senhas de DEV e database não está exposto

### Outros Deliverables Afetados:

- [ ] `05-infra/configs/.env.example` - Validar se documenta `DB_APP_PASSWORD` / `DB_READONLY_PASSWORD`
- [ ] `04-database/README.md` - Falta documentação de multi-environment strategy
- [ ] Docker Compose files - Validar se passam environment vars para init script

**Esforço estimado:** 2 horas (DBA + PE)
**Risco:** 🟡 Médio (segurança + deployment consistency)

---

## 💡 Proposta de Solução

### Abordagem: Usar Environment Variables no Init Script

#### Opção 1: PostgreSQL `envsubst` + Template (Recomendado)

**DBA Agent:**

1. **Renomear script:** `01-create-app-user.sql` → `01-create-app-user.sql.template`

2. **Usar variáveis de ambiente no template:**

```sql
-- 01-create-app-user.sql.template
CREATE USER mytrader_app WITH
    PASSWORD '${DB_APP_PASSWORD:-app_dev_password_123}'  -- Fallback para dev
    NOCREATEDB
    NOCREATEROLE
    NOSUPERUSER;

CREATE USER mytrader_readonly WITH
    PASSWORD '${DB_READONLY_PASSWORD:-readonly_dev_password_123}'  -- Fallback para dev
    NOCREATEDB
    NOCREATEROLE
    NOSUPERUSER;
```

3. **Criar script wrapper:** `04-database/init-scripts/00-process-templates.sh`

```bash
#!/bin/bash
# Process SQL templates with environment variables
envsubst < /docker-entrypoint-initdb.d/01-create-app-user.sql.template \
         > /docker-entrypoint-initdb.d/01-create-app-user-processed.sql
```

**PE Agent:**

4. **Atualizar Docker Compose para passar env vars:**

```yaml
# docker-compose.staging.yml
database:
  environment:
    - DB_APP_PASSWORD=${DB_APP_PASSWORD}
    - DB_READONLY_PASSWORD=${DB_READONLY_PASSWORD}
```

5. **Atualizar `.env.example`:**

```bash
# Database - Application User Credentials (per environment)
DB_APP_USER=mytrader_app
DB_APP_PASSWORD=CHANGE_ME_STAGING_STRONG_PASSWORD  # staging/production

# Database - Read-Only User Credentials
DB_READONLY_USER=mytrader_readonly
DB_READONLY_PASSWORD=CHANGE_ME_READONLY_PASSWORD  # staging/production
```

---

#### Opção 2: PostgreSQL `ALTER USER` Approach (Mais Simples)

**Abordagem:** Init script cria usuários com senhas default, depois altera via migration

**DBA Agent:**

1. **Init script mantém senhas default** (apenas development)

2. **Criar migration separada:** `04-database/migrations/002_update_production_passwords.sql`

```sql
-- Executar APENAS em staging/production (manualmente)
-- NUNCA commitar senhas reais no Git!

-- Usar senhas das variáveis de ambiente ou passar via psql -v
ALTER USER mytrader_app WITH PASSWORD :'app_password';
ALTER USER mytrader_readonly WITH PASSWORD :'readonly_password';
```

3. **Executar migration com variáveis:**

```bash
# Staging
psql -U postgres -d mytrader_staging \
  -v app_password="$DB_APP_PASSWORD" \
  -v readonly_password="$DB_READONLY_PASSWORD" \
  -f 002_update_production_passwords.sql

# Production
psql -U postgres -d mytrader_prod \
  -v app_password="$DB_APP_PASSWORD" \
  -v readonly_password="$DB_READONLY_PASSWORD" \
  -f 002_update_production_passwords.sql
```

---

### Recomendação: **Opção 2** (ALTER USER)

**Por quê:**
- ✅ Mais simples (sem templates, sem script wrapper)
- ✅ Senhas NUNCA commitadas no Git (passadas via CLI)
- ✅ Development mantém senhas simples (sem impacto)
- ✅ Staging/Production controladas via deployment manual seguro
- ✅ Compatível com rotação de senhas (re-executar ALTER USER)

---

## 📋 Checklist de Implementação

### DBA Agent:

- [ ] Criar `04-database/migrations/002_update_production_passwords.sql`
- [ ] Adicionar instruções no README: "Como alterar senhas em staging/production"
- [ ] Documentar no README: estratégia multi-environment
- [ ] Adicionar seção "Security Best Practices" no README

### PE Agent:

- [ ] Validar `.env.example` tem `DB_APP_PASSWORD` / `DB_READONLY_PASSWORD`
- [ ] Adicionar nota no PE-00: "DBA credentials diferentes por ambiente"
- [ ] Documentar procedimento de password rotation

### Testes:

- [ ] Development: Verificar que init script funciona com senhas default
- [ ] Staging: Simular ALTER USER com senha forte
- [ ] Production: Documentar procedimento de deployment com password change

---

## ✅ Resolução

> _Seção preenchida pelo DBA Agent após resolver_

**Data Resolução:** [YYYY-MM-DD]
**Resolvido por:** DBA Agent + PE Agent

**Ação Tomada:**
[Descrição do que foi feito]

**Deliverables Atualizados:**
- [ ] `04-database/migrations/002_update_production_passwords.sql` - Migration para alterar senhas
- [ ] `04-database/README.md` - Documentação multi-environment + password rotation
- [ ] `05-infra/configs/.env.example` - Validação de DB credentials docs

**Referência Git Commit:** [hash]

---

**Status Final:** 🔴 Aberto

---

## 📝 Histórico

| Data | Mudança | Autor |
|------|---------|-------|
| 2025-01-28 | Criado (análise de impacto FEEDBACK-004) | DBA Agent |

---

## 📚 Referências

- FEEDBACK-003: PostgreSQL User Security (DBA + PE) - Resolvido
- FEEDBACK-004: PE Agent Specification Evolution (USER → PE) - Resolvido
- [PostgreSQL ALTER USER Documentation](https://www.postgresql.org/docs/15/sql-alteruser.html)
- [Docker Secrets for PostgreSQL](https://docs.docker.com/engine/swarm/secrets/)
