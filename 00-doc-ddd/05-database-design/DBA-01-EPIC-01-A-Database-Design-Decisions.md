# DBA-01-EPIC-01-A-Database-Design-Decisions.md

**Projeto:** myTraderGEO  
**Épico:** EPIC-01-A - User Management  
**Data:** 2025-10-26  
**Engineer:** DBA Agent  
**Database:** PostgreSQL 14+  

---

## 🎯 Objetivo

Documentar as decisões de design do banco de dados para o **User Management Bounded Context** (EPIC-01-A), incluindo:
- Estratégias de modelagem de Value Objects
- Índices e otimizações de performance
- Constraints para garantir invariantes de negócio
- Trade-offs e justificativas

---

## 📖 Como Usar Esta Documentação

**Este documento (DBA-01) é a REFERÊNCIA COMPLETA e ESTRATÉGICA:**
- **Target:** Arquitetos, DBAs, tech leads, futuros mantenedores
- **Conteúdo:** Decisões de design (POR QUÊ), trade-offs, justificativas técnicas, alternativas avaliadas
- **Estilo:** Completo, detalhado, educacional, documentação DDD formal
- **Quando consultar:** Para entender decisões arquiteturais, modificar schema, avaliar alternativas, onboarding de novos membros

**Para EXECUÇÃO RÁPIDA de migrations, consulte:** [04-database/README.md](../../04-database/README.md)  
- **Target:** Desenvolvedores executando migrations, DevOps, troubleshooting operacional
- **Conteúdo:** Comandos CLI, troubleshooting prático, validação de permissões, quick reference
- **Estilo:** Minimalista, imperativo, orientado a tarefas
- **Quando consultar:** Para executar migrations, testar permissões de usuários, resolver problemas operacionais

**Princípio:** DBA-01 explica o **POR QUÊ** e **O QUÊ** (arquitetura), README explica o **COMO executar** (operacional).  

**Evitamos duplicação:** O README contém apenas comandos práticos e troubleshooting, não repete decisões de design.  

---

## 📊 Visão Geral do Schema

### Tabelas

| Tabela | Tipo | Agregados | Propósito |
|--------|------|-----------|-----------|
| **SubscriptionPlans** | Aggregate Root | SubscriptionPlan | Planos de assinatura (Básico, Pleno, Consultor) |
| **SystemConfigs** | Aggregate Root (Singleton) | SystemConfig | Configurações globais do sistema |
| **Users** | Aggregate Root | User | Usuários, autenticação, perfis |

### Relacionamentos

```
SubscriptionPlans (1) ----< (0..1) Users
SystemConfigs (1) ---- UpdatedBy ---> (1) Users
```

---

## 🔧 Decisões de Modelagem

### 1. Value Objects: Embedded vs JSON

#### 1.1 Value Objects Embedded (Colunas Separadas)

**Aplicado em:**
- `Email` → `Users.Email` (VARCHAR)
- `PasswordHash` → `Users.PasswordHash` (VARCHAR)
- `PhoneNumber` → `Users.PhoneCountryCode` + `Users.PhoneNumber` (VARCHAR)
- `Money` → `SubscriptionPlans.PriceMonthlyAmount` + `PriceMonthlyurrency` (DECIMAL + VARCHAR)
- `PlanFeatures` → `SubscriptionPlans.FeatureRealtimeData`, `FeatureAdvancedAlerts`, etc (BOOLEAN)

**Justificativa:**
- ✅ **Performance**: Queries diretas sem parsing JSON
- ✅ **Índices**: Suporte a índices B-Tree eficientes
- ✅ **Validação**: Constraints de banco garantem invariantes
- ✅ **Queries**: WHERE, ORDER BY, GROUP BY simples

**Exemplo:**
```sql
-- Query eficiente com índice
SELECT * FROM Users WHERE Email = 'trader@demo.com';

-- Query com features
SELECT * FROM SubscriptionPlans WHERE FeatureRealtimeData = TRUE;
```

---

#### 1.2 Value Objects como JSON (JSONB)

**Aplicado em:**
- `UserPlanOverride` → `Users.PlanOverride` (JSONB)
- `TradingFees` → `Users.CustomFees` (JSONB)

**Justificativa:**
- ✅ **Flexibilidade**: Estrutura complexa e aninhada
- ✅ **Nullable**: Maioria dos usuários não tem override/custom fees
- ✅ **Evolução**: Fácil adicionar campos sem ALTER TABLE
- ✅ **Atomicidade**: Objeto completo em uma coluna
- ⚠️ **Trade-off**: Performance de queries menor, mas aceitável para campos raramente filtrados

**Estrutura JSON:**

```json
// UserPlanOverride
{
  "StrategyLimitOverride": 50,
  "FeaturesOverride": {
    "RealtimeData": true,
    "AdvancedAlerts": true,
    "ConsultingTools": false,
    "CommunityAccess": true
  },
  "ExpiresAt": "2025-12-31T23:59:59Z",
  "Reason": "Beta Tester",
  "GrantedBy": "00000000-0000-0000-0000-000000000001",
  "GrantedAt": "2025-10-26T00:00:00Z"
}

// TradingFees (todos os campos são nullable)
{
  "BrokerCommissionRate": 0.001,
  "B3EmolumentRate": null,
  "SettlementFeeRate": null,
  "IncomeTaxRate": 0.10,
  "DayTradeIncomeTaxRate": null
}
```

**GIN Indexes para JSONB:**
```sql
CREATE INDEX IX_Users_PlanOverride_GIN ON Users USING GIN(PlanOverride);
CREATE INDEX IX_Users_CustomFees_GIN ON Users USING GIN(CustomFees);
```

---

### 2. Enums: VARCHAR vs INT

**Decisão:** VARCHAR para todos os enums  

**Aplicado em:**
- `UserRole` → `Users.Role` (VARCHAR) - "Trader", "Moderator", "Administrator"
- `UserStatus` → `Users.Status` (VARCHAR) - "Active", "Suspended", "Deleted"
- `RiskProfile` → `Users.RiskProfile` (VARCHAR) - "Conservador", "Moderado", "Agressivo"
- `BillingPeriod` → `Users.BillingPeriod` (INT) - 1=Monthly, 12=Annual

**Justificativa VARCHAR:**
- ✅ **Legibilidade**: Queries e logs mais claros
- ✅ **Manutenção**: Não precisa manter tabela de lookup
- ✅ **Performance**: CHECK constraints validam valores
- ✅ **Debugging**: SQL direto mostra valores semânticos

**Exceção - BillingPeriod como INT:**
- ✅ **Semântica**: Valor numérico representa meses (1, 12)
- ✅ **Cálculos**: Facilita matemática de billing

**Constraints:**
```sql
CONSTRAINT CK_User_Role_Valid
    CHECK (Role IN ('Trader', 'Moderator', 'Administrator'))
```

---

### 3. Índices

#### 3.1 Índices Únicos (Unique Indexes)

| Tabela | Coluna | Justificativa |
|--------|--------|---------------|
| Users | Email | Invariante: Email único no sistema |
| SubscriptionPlans | Name | Invariante: Nome de plano único |

```sql
CREATE UNIQUE INDEX UX_Users_Email ON Users(Email);
CREATE UNIQUE INDEX UX_SubscriptionPlans_Name ON SubscriptionPlans(Name);
```

---

#### 3.2 Índices de Performance

**Users:**
```sql
-- Query by Role (UC: GetByRoleAsync)
CREATE INDEX IX_Users_Role ON Users(Role);

-- Query by Status
CREATE INDEX IX_Users_Status ON Users(Status);

-- Query by SubscriptionPlanId (join/filter)
CREATE INDEX IX_Users_SubscriptionPlanId ON Users(SubscriptionPlanId)
    WHERE SubscriptionPlanId IS NOT NULL;

-- Audit queries (recent users, recent logins)
CREATE INDEX IX_Users_CreatedAt ON Users(CreatedAt DESC);
CREATE INDEX IX_Users_LastLoginAt ON Users(LastLoginAt DESC)
    WHERE LastLoginAt IS NOT NULL;
```

**SubscriptionPlans:**
```sql
-- Query active plans (UC: GetActiveAsync)
CREATE INDEX IX_SubscriptionPlans_IsActive ON SubscriptionPlans(IsActive);

-- Audit queries
CREATE INDEX IX_SubscriptionPlans_CreatedAt ON SubscriptionPlans(CreatedAt DESC);
```

**Partial Indexes (WHERE clause):**
- Otimiza espaço para colunas nullable/sparse
- Exemplo: `LastLoginAt` - muitos usuários nunca logaram

---

#### 3.3 GIN Indexes para JSONB

```sql
CREATE INDEX IX_Users_PlanOverride_GIN ON Users USING GIN(PlanOverride)
    WHERE PlanOverride IS NOT NULL;

CREATE INDEX IX_Users_CustomFees_GIN ON Users USING GIN(CustomFees)
    WHERE CustomFees IS NOT NULL;
```

**Uso:**
```sql
-- Query por campo dentro do JSON
SELECT * FROM Users
WHERE PlanOverride @> '{"Reason": "Beta Tester"}';

-- Query por feature override
SELECT * FROM Users
WHERE PlanOverride -> 'FeaturesOverride' ->> 'RealtimeData' = 'true';
```

---

### 4. Constraints (Invariantes de Negócio)

#### 4.1 Check Constraints - Users

```sql
-- DisplayName length (invariante #3)
CONSTRAINT CK_User_DisplayName_Length
    CHECK (LENGTH(DisplayName) >= 2 AND LENGTH(DisplayName) <= 30)

-- Role values (invariante #8)
CONSTRAINT CK_User_Role_Valid
    CHECK (Role IN ('Trader', 'Moderator', 'Administrator'))

-- Trader must have Subscription (invariante #9)
CONSTRAINT CK_User_Trader_MustHave_Subscription
    CHECK (Role != 'Trader' OR (SubscriptionPlanId IS NOT NULL AND BillingPeriod IS NOT NULL))

-- Trader must have RiskProfile (invariante #7)
CONSTRAINT CK_User_Trader_MustHave_RiskProfile
    CHECK (Role != 'Trader' OR RiskProfile IS NOT NULL)

-- Admin/Moderator cannot have Subscription (invariante #10)
CONSTRAINT CK_User_AdminModerator_NoSubscription
    CHECK (Role = 'Trader' OR (SubscriptionPlanId IS NULL AND BillingPeriod IS NULL))

-- Phone: both fields or none (invariante #5)
CONSTRAINT CK_User_Phone_BothOrNone
    CHECK ((PhoneCountryCode IS NULL AND PhoneNumber IS NULL) OR
           (PhoneCountryCode IS NOT NULL AND PhoneNumber IS NOT NULL))
```

**Benefícios:**
- ✅ Invariantes garantidos no banco (defense in depth)
- ✅ Evita dados inconsistentes mesmo com bugs no código
- ✅ Documentação viva das regras de negócio

---

#### 4.2 Check Constraints - SubscriptionPlans

```sql
-- Prices non-negative (invariante #2, #3)
CONSTRAINT CK_SubscriptionPlan_PriceMonthly_NonNegative
    CHECK (PriceMonthlyAmount >= 0)

-- Annual price must have discount (invariante #4)
CONSTRAINT CK_SubscriptionPlan_AnnualPrice_Discounted
    CHECK (PriceMonthlyAmount = 0 OR PriceAnnualAmount < (PriceMonthlyAmount * 12))

-- Strategy limit positive (invariante #6)
CONSTRAINT CK_SubscriptionPlan_StrategyLimit_Positive
    CHECK (StrategyLimit > 0)

-- Discount percent valid (invariante #5)
CONSTRAINT CK_SubscriptionPlan_AnnualDiscount_Valid
    CHECK (AnnualDiscountPercent >= 0 AND AnnualDiscountPercent <= 1)
```

---

#### 4.3 Check Constraints - SystemConfigs

```sql
-- All rates between 0 and 1 (invariantes #1-6)
CONSTRAINT CK_SystemConfig_BrokerCommissionRate_Valid
    CHECK (BrokerCommissionRate >= 0 AND BrokerCommissionRate <= 1)

-- Limites positivos (invariantes #7-8)
CONSTRAINT CK_SystemConfig_MaxOpenStrategies_Positive
    CHECK (MaxOpenStrategiesPerUser > 0)
```

---

### 5. Foreign Keys

```sql
-- Users -> SubscriptionPlans
CONSTRAINT FK_Users_SubscriptionPlanId
    FOREIGN KEY (SubscriptionPlanId) REFERENCES SubscriptionPlans(Id)

-- SystemConfigs -> Users (UpdatedBy)
CONSTRAINT FK_SystemConfigs_UpdatedBy
    FOREIGN KEY (UpdatedBy) REFERENCES Users(Id)
```

**Decisão: No CASCADE DELETE**
- Users → SubscriptionPlans: RESTRICT (não permitir deletar plano com usuários)
- SystemConfigs → Users: RESTRICT (não permitir deletar admin que atualizou config)

**Soft Delete Strategy:**
- Users: `Status = 'Deleted'` (não DELETE físico)
- SubscriptionPlans: `IsActive = FALSE` (desativar, não deletar)

---

### 6. Singleton Pattern (SystemConfigs)

**Estratégia:** ID fixo + constraint de aplicação  

```sql
-- Sempre usar este ID
Id = '00000000-0000-0000-0000-000000000001'

-- No código C#
public static readonly SystemConfigId SingletonId =
    new(Guid.Parse("00000000-0000-0000-0000-000000000001"));
```

**Alternativas Consideradas:**
1. ❌ Trigger para impedir INSERT adicional → complexidade desnecessária
2. ❌ CHECK constraint com subquery → não suportado em PostgreSQL
3. ✅ **Escolhido:** Convenção + validação em Application Layer

---

### 7. Audit Columns

**Padrão:**
- `CreatedAt` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
- `UpdatedAt` TIMESTAMP NULL
- `UpdatedBy` UUID (apenas em SystemConfigs)

**Ausências:**
- ❌ `CreatedBy`: Implícito (usuário sempre cria a própria conta)
- ❌ `DeletedAt`: Usar `Status = 'Deleted'` explicitamente
- ❌ `DeletedBy`: Trackear via Domain Event, não no DB

---

### 8. Decisões de Tipo de Dados

| Conceito | Tipo PostgreSQL | Justificativa |
|----------|-----------------|---------------|
| IDs (UUIDs) | UUID | Distributed ID generation, segurança |
| Email | VARCHAR(255) | Padrão RFC 5321 (max 254 chars) |
| PasswordHash | VARCHAR(255) | BCrypt output = 60 chars (buffer futuro) |
| Money | DECIMAL(10,2) | Precisão exata, até R$ 99.999.999,99 |
| Rates | DECIMAL(10,8) | Precisão para taxas pequenas (0.000325) |
| Timestamps | TIMESTAMP | UTC (sempre usar UTC no código) |
| Booleans | BOOLEAN | Nativo PostgreSQL |
| Enums | VARCHAR(20) | Legibilidade + CHECK constraints |
| Complex VOs | JSONB | Flexibilidade + GIN indexes |

---

#### 8.1 Decisão: UUID vs BIGINT para Primary Keys

**Escolha:** UUID v4 (mantido)  

**Alternativas Avaliadas:**

| Tipo | Tamanho | Prós | Contras | Decisão |
|------|---------|------|---------|---------|
| **UUID v4** | 16 bytes | Geração distribuída, segurança, não expõe quantidade | Storage maior, índice menos eficiente | ✅ **Escolhido** |
| **BIGINT** | 8 bytes | Performance máxima, compacto, legível | Expõe quantidade, centralizado, merge difícil | ❌ |
| **UUID v7** | 16 bytes | Ordenação temporal, melhor performance | Requer PostgreSQL 14+ | 🔄 Futuro |
| **ULID** | 26 bytes | Ordenação temporal, URL-safe | Não nativo, menos adoção | ❌ |

**Justificativa da Escolha:**
1. ✅ **Segurança**: Não expõe quantidade de registros em APIs públicas
2. ✅ **Geração distribuída**: Código C# gera IDs sem round-trip ao banco
3. ✅ **Merge-friendly**: Facilita migração de dados entre dev/staging/prod
4. ✅ **Preparado para escala**: Se migrar para microservices, IDs independentes
5. ✅ **Suficiente para escala prevista**: Performance aceitável até ~1M registros

**Trade-offs Aceitos:**
- ⚠️ Storage: 16 bytes vs 8 bytes (BIGINT) - aceitável para volume esperado
- ⚠️ Performance de índice: ~10% mais lento - impacto negligenciável

**Alternativa Futura:**
- Migrar para **UUID v7** quando PostgreSQL 14+ for baseline
- Performance ~50% melhor que UUID v4 em índices

**Otimização Prematura Evitada:**
- BIGINT + HashIds (PublicId ofuscado) - complexidade desnecessária no momento

---

**DECIMAL vs FLOAT:**
- ✅ DECIMAL: Precisão exata (critical para dinheiro)
- ❌ FLOAT: Erro de arredondamento (nunca usar para money)

---

## 📋 Queries Esperadas (Performance Targets)

### Repository Queries (do Domain Model)

| Repository | Método | Índice Usado | Performance |
|------------|--------|--------------|-------------|
| IUserRepository | GetByEmailAsync | UX_Users_Email (UNIQUE) | O(log n) - Excelente |
| IUserRepository | GetByRoleAsync | IX_Users_Role | O(n/k) - Boa |
| ISubscriptionPlanRepository | GetByNameAsync | UX_SubscriptionPlans_Name (UNIQUE) | O(log n) - Excelente |
| ISubscriptionPlanRepository | GetActiveAsync | IX_SubscriptionPlans_IsActive | O(n/k) - Boa |
| ISystemConfigRepository | GetAsync | PK (Singleton) | O(1) - Excelente |

### Ad-hoc Queries (Admin Dashboard)

```sql
-- 1. Contagem de usuários por plano
SELECT sp.Name, COUNT(u.Id) as UserCount
FROM SubscriptionPlans sp
LEFT JOIN Users u ON u.SubscriptionPlanId = sp.Id
GROUP BY sp.Name
ORDER BY UserCount DESC;

-- 2. Usuários com Plan Override ativos
SELECT u.DisplayName, u.Email,
       u.PlanOverride->>'Reason' as OverrideReason,
       u.PlanOverride->>'ExpiresAt' as ExpiresAt
FROM Users u
WHERE u.PlanOverride IS NOT NULL
  AND (u.PlanOverride->>'ExpiresAt')::timestamp > CURRENT_TIMESTAMP;

-- 3. Revenue estimado (MRR - Monthly Recurring Revenue)
SELECT
    SUM(CASE
        WHEN u.BillingPeriod = 1 THEN sp.PriceMonthlyAmount
        WHEN u.BillingPeriod = 12 THEN sp.PriceAnnualAmount / 12
    END) as EstimatedMRR
FROM Users u
INNER JOIN SubscriptionPlans sp ON u.SubscriptionPlanId = sp.Id
WHERE u.Role = 'Trader' AND u.Status = 'Active';

-- 4. Usuários inativos (sem login há 30 dias)
SELECT u.Email, u.LastLoginAt, u.CreatedAt
FROM Users u
WHERE u.Status = 'Active'
  AND (u.LastLoginAt IS NULL OR u.LastLoginAt < CURRENT_TIMESTAMP - INTERVAL '30 days')
ORDER BY u.CreatedAt DESC;
```

---

## 🔄 Migration Strategy

### Arquivos de Migrations

- **Schema**: `04-database/migrations/001_create_user_management_schema.sql`
- **Seed Data**: `04-database/seeds/001_seed_user_management_defaults.sql`

### Ordem de Execução

```bash
# 1. Schema (tabelas, índices, constraints)
psql -d mytradergeo -f 04-database/migrations/001_create_user_management_schema.sql

# 2. Seed data (planos, config, admin, demos)
psql -d mytradergeo -f 04-database/seeds/001_seed_user_management_defaults.sql
```

### Rollback Strategy

```sql
-- Rollback (ordem inversa da criação)
DROP TABLE Users CASCADE;
DROP TABLE SystemConfigs CASCADE;
DROP TABLE SubscriptionPlans CASCADE;
```

---

## 🧪 Testing & Validation

### Validation Queries (pós-migration)

```sql
-- 1. Verificar planos criados
SELECT Name, PriceMonthlyAmount, StrategyLimit, FeatureRealtimeData
FROM SubscriptionPlans
ORDER BY PriceMonthlyAmount;

-- 2. Verificar configuração do sistema
SELECT BrokerCommissionRate, IncomeTaxRate, MaxOpenStrategiesPerUser
FROM SystemConfigs;

-- 3. Verificar usuários criados
SELECT Email, Role, SubscriptionPlanId, RiskProfile
FROM Users
ORDER BY CreatedAt;

-- 4. Testar constraint violation (deve falhar)
INSERT INTO Users (Id, Email, PasswordHash, FullName, DisplayName, Role, Status)
VALUES (gen_random_uuid(), 'test@test.com', 'hash', 'Test', 'T', 'Trader', 'Active');
-- ERROR: CK_User_DisplayName_Length (DisplayName muito curto)

-- 5. Testar unique constraint (deve falhar)
INSERT INTO Users (Id, Email, PasswordHash, FullName, DisplayName, Role, Status)
VALUES (gen_random_uuid(), 'admin@mytradergeo.com', 'hash', 'Test', 'Test', 'Administrator', 'Active');
-- ERROR: UX_Users_Email (email duplicado)
```

---

## 📊 Estimativas de Storage

| Tabela | Rows (Ano 1) | Row Size (avg) | Total Size | Indexes Size |
|--------|--------------|----------------|------------|--------------|
| SubscriptionPlans | 10 | 500 bytes | 5 KB | 10 KB |
| SystemConfigs | 1 | 200 bytes | 200 bytes | 1 KB |
| Users | 10,000 | 1 KB | 10 MB | 5 MB |
| **TOTAL** | | | **~10 MB** | **~5 MB** |

**Crescimento Esperado:**
- Users: +5,000/ano
- Storage Year 2: ~20 MB (dados + índices)

---

## 🔐 Security Considerations

### 1. Password Storage
- ✅ BCrypt com cost=11 (padrão seguro)
- ✅ Hash armazenado (nunca plaintext)
- ⚠️ Seed data tem senhas default → **MUDAR NO PRIMEIRO LOGIN**

### 2. PII (Personal Identifiable Information)
- Email, FullName, PhoneNumber → **Encrypt at rest** (PostgreSQL pgcrypto ou disk encryption)
- DisplayName → Público (não precisa criptografia)

### 3. GDPR Compliance
- Soft delete: `Status = 'Deleted'`
- Anonimização: Procedure para limpar PII após período legal
- Export: Query para extrair dados de um usuário (right to data portability)

### 4. Database User Segregation (Least Privilege)

**⚠️ IMPORTANTE:** A aplicação NUNCA deve usar o usuário `postgres` (superuser).  

**Implementação:**
- [FEEDBACK-003 - PostgreSQL User Security](../00-feedback/FEEDBACK-003-DBA-PE-PostgreSQL-User-Security.md)
  - Resolução: Segregação de usuários PostgreSQL
  - Princípio do Menor Privilégio (Least Privilege)
  - Usuários dedicados:
    - `postgres`: Admin (DBA apenas) - SUPERUSER
    - `mytrader_app`: Aplicação .NET - CRUD + CREATE TABLE (migrations)
    - `mytrader_readonly`: Analytics/Backups - SELECT apenas
  - Security benefits: SQL injection mitigado, defense in depth, compliance LGPD/SOC2

**Guia Operacional:**
- [04-database/README.md - Seção Usuários PostgreSQL](../../04-database/README.md#-usuários-postgresql-least-privilege)
  - Connection strings seguras
  - Como testar permissões
  - Troubleshooting de usuários

---

## 📚 Referências

- **Domain Model**: `00-doc-ddd/04-tactical-design/DE-01-EPIC-01-A-User-Management-Domain-Model.md`
- **Context Map**: `00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md`
- **DDD Patterns**: `.agents/docs/05-DDD-Patterns-Reference.md`
- **PostgreSQL Docs**: https://www.postgresql.org/docs/14/
- **JSONB Indexing**: https://www.postgresql.org/docs/14/datatype-json.html#JSON-INDEXING

---

## ✅ Checklist de Implementação

- [x] Schema SQL criado
- [x] Índices definidos (unique + performance + GIN)
- [x] Constraints implementadas (todas as invariantes)
- [x] Foreign keys configuradas
- [x] Seed data criado (planos, config, demo users)
- [x] Documentação de decisões
- [ ] Testes de migration (dev environment)
- [ ] Testes de performance (queries esperadas)
- [ ] Testes de constraints (violation scenarios)
- [ ] Review de segurança (PII, passwords)
- [ ] Deploy em staging
- [ ] Deploy em production

---

**DBA Agent** - 2025-10-26
