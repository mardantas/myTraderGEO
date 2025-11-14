<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)  
- Use blank lines between sections for readability (content)  
- Validate in Markdown preview before committing  
-->

# DBA-01-[EpicName]-Schema-Review.md

**Agent:** DBA (Database Administrator)  
**Project:** [PROJECT_NAME]  
**Date:** [YYYY-MM-DD]  
**Epic:** [EPIC_NUMBER]: [EPIC_NAME]  
**Phase:** Iteration  
**Scope:** Database schema review and optimization for epic  
**Version:** 1.0  
  
---

## 🎯 Contexto

**Épico:** [Epic Name]  
**Bounded Contexts:** [BC1, BC2, BC3]  
**Schema Criado Por:** DE Agent (EF Core migrations)  

**Objetivo:** Validar schema, sugerir otimizações, definir indexing strategy  

---

## 📋 Schema Review por Bounded Context

### [BC Name 1]

#### Tabelas Criadas (EF Migrations)

##### Tabela: `[TableName]`

**Aggregate:** [AggregateName]  
**Purpose:** [O que armazena]  

**Colunas:**  

| Column | Type | Nullable | PK/FK | Description |
|--------|------|----------|-------|-------------|
| `Id` | GUID/INT | NOT NULL | PK | Primary Key |
| `Name` | VARCHAR(200) | NOT NULL | - | Nome do aggregate |
| `Status` | VARCHAR(50) | NOT NULL | - | Status atual |
| `CreatedAt` | DATETIME | NOT NULL | - | Data criação |
| `UpdatedAt` | DATETIME | NULL | - | Última atualização |
| `Version` | INT | NOT NULL | - | Concurrency control |

**Review:**  

| Aspecto | Status | Comentário |
|---------|--------|------------|
| **Normalização** | ✅ OK | Tabela normalizada adequadamente |
| **Data Types** | ⚠️ Revisar | VARCHAR(200) pode ser VARCHAR(100) para Name |
| **Nullable** | ✅ OK | Nullability correta |
| **Constraints** | ⚠️ Sugestão | Adicionar CHECK constraint em Status |

**Sugestões:**  
1. Reduzir `Name VARCHAR(200)` → `VARCHAR(100)` (economiza espaço)
2. Adicionar constraint: `CHECK (Status IN ('Active', 'Inactive', 'Pending'))`
3. Considerar index em `Status` (queries frequentes por status)

---

##### Tabela: `[ChildTable]` (Child Entity)

**Parent:** `[TableName]`  
**Relationship:** One-to-Many  

**Colunas:**  

| Column | Type | Nullable | PK/FK | Description |
|--------|------|----------|-------|-------------|
| `Id` | GUID | NOT NULL | PK | Primary Key |
| `[Parent]Id` | GUID | NOT NULL | FK | Foreign Key para [TableName] |
| `Property` | VARCHAR(100) | NOT NULL | - | Alguma propriedade |
| `CreatedAt` | DATETIME | NOT NULL | - | Data criação |

**Review:**  

| Aspecto | Status | Comentário |
|---------|--------|------------|
| **Foreign Key** | ✅ OK | FK com ON DELETE CASCADE configurado |
| **Index em FK** | ⚠️ FALTA | **CRÍTICO:** Adicionar index em `[Parent]Id` |

**Sugestões:**
1. **CRIAR INDEX:** `IX_[ChildTable]_[Parent]Id` em `[Parent]Id` (performance crítica)
2. Considerar index composto se queries filtram por `[Parent]Id + Status`

---

### [BC Name 2]
...

---

## 🔑 Primary Key Strategy

### Decision Criteria

When designing the database schema, one of the first decisions is choosing the primary key type. This section documents the rationale for UUID vs INT/SERIAL selection per table.

**Core Question:** Should this table use UUID (16 bytes) or INT/SERIAL (4 bytes)?

---

### UUID vs INT/SERIAL Selection Matrix

| Criteria | Use UUID | Use INT/SERIAL | Weight |
|----------|----------|----------------|--------|
| **Table Size** | High-volume tables (>100k rows expected) | Lookup tables (<100 rows) | 🔴 HIGH |
| **API Exposure** | Aggregate root exposed in public API (Users, Orders, Transactions) | Internal-only tables (not exposed) | 🔴 HIGH |
| **Security** | Non-enumerable IDs required (prevent user enumeration attacks) | Enumeration acceptable | 🟡 MEDIUM |
| **Distributed System** | Multi-database, distributed ID generation | Single database, centralized | 🟡 MEDIUM |
| **Merge/Import** | Data merging from multiple sources | No merging scenarios | 🟢 LOW |
| **Join Frequency** | Low join frequency (<3 joins per query) | High join frequency (>5 joins) | 🟡 MEDIUM |
| **Storage Optimization** | Storage cost acceptable | Storage optimization critical | 🟢 LOW |

---

### Decision Tree

```
Is this table exposed in public API (REST endpoints)?
├─ YES → Is it an Aggregate Root (Users, Orders, etc)?
│         ├─ YES → ✅ Use UUID (security + distributed + API best practices)
│         └─ NO  → Is it a lookup/reference table (<100 rows)?
│                   ├─ YES → ✅ Use INT/SERIAL (performance + storage)
│                   └─ NO  → ⚠️ Evaluate case-by-case (default: UUID for flexibility)
│
└─ NO → Is it a lookup/reference table (<100 rows)?
         ├─ YES → ✅ Use INT/SERIAL (performance + storage + simplicity)
         └─ NO  → Is storage/performance critical (millions of rows + frequent joins)?
                   ├─ YES → ✅ Use INT/SERIAL (optimization)
                   └─ NO  → ✅ Use UUID (flexibility + future-proof)
```

---

### Recommended Patterns by Table Type

#### ✅ Use UUID When:

| Table Type | Example Tables | Reason |
|------------|----------------|--------|
| **Aggregate Roots (API-Exposed)** | Users, Orders, Transactions, Invoices | Security (non-enumerable), distributed systems, API best practices |
| **High-Volume Transactional** | AuditLogs, Events, Notifications | Distributed ID generation, merge scenarios |
| **Cross-System Integration** | ExternalOrders, ThirdPartyData | Merge from multiple sources, avoid ID collisions |
| **Security-Sensitive** | Passwords, Tokens, Sessions | Non-enumerable IDs prevent enumeration attacks |

**Benefits:**
- ✅ Non-enumerable (security: `/users/123` → attacker can guess IDs)
- ✅ Distributed-friendly (generate IDs in app, no DB round-trip)
- ✅ Merge-safe (no ID collisions when importing data)
- ✅ Future-proof (easier to scale to multi-database)

**Trade-offs:**
- ❌ Larger storage (16 bytes vs 4 bytes)
- ❌ Slower joins (string comparison vs integer)
- ❌ Less human-readable (debugging harder)

---

#### ✅ Use INT/SERIAL When:

| Table Type | Example Tables | Reason |
|------------|----------------|--------|
| **Lookup/Reference Tables** | SubscriptionPlans, Categories, Statuses, Countries | Small size (<100 rows), high join frequency, storage optimization |
| **Internal-Only Tables** | ConfigSettings, FeatureFlags | Not exposed in API, centralized, simplicity |
| **Audit/Logging (Low Volume)** | AdminAuditLog (<10k rows) | Simple, sequential, chronological ordering |
| **High-Join Tables** | ProductCategories (joined in every product query) | Performance-critical joins (integer comparison faster) |

**Benefits:**
- ✅ Storage-efficient (4 bytes vs 16 bytes → 75% reduction)
- ✅ Faster joins (integer comparison 2-3x faster than UUID string)
- ✅ Human-readable (debugging: "user ID 5" vs "550e8400-e29b-41d4-a716-446655440000")
- ✅ Sequential (natural ordering, simpler pagination)

**Trade-offs:**
- ❌ Enumerable (security: `/plans/1`, `/plans/2` → attacker can list all)
- ❌ Centralized (must query DB for next ID, not distributed-friendly)
- ❌ Merge conflicts (importing data with same IDs requires remapping)

---

### Trade-off Analysis: UUID vs INT/SERIAL

| Aspect | UUID (16 bytes) | INT/SERIAL (4 bytes) | Winner |
|--------|-----------------|----------------------|--------|
| **Storage Size** | 16 bytes | 4 bytes (75% smaller) | INT/SERIAL |
| **Index Size** | 2x-3x larger B-tree | Compact B-tree | INT/SERIAL |
| **Join Performance** | Slower (string comparison) | Faster (integer comparison) | INT/SERIAL |
| **Insert Performance** | Fast (app-generated, no DB lock) | Slower (DB sequence, lock contention) | UUID |
| **Security** | Non-enumerable | Enumerable (predictable) | UUID |
| **Distributed Systems** | ID generation in app | Must query DB | UUID |
| **Merge/Import** | No collisions | Requires ID remapping | UUID |
| **Human Readability** | Hard to debug | Easy to read | INT/SERIAL |
| **API Best Practices** | Industry standard (opaque IDs) | Exposes internal details | UUID |

**Conclusion:**
- **Small/medium projects (MVP):** INT/SERIAL for lookup tables (SubscriptionPlans, Categories), UUID for Users/Orders
- **Large-scale/distributed:** UUID everywhere except tiny lookup tables
- **Security-critical:** UUID for all user-facing IDs

---

### Examples from This Epic

#### [Epic Name] - Primary Key Decisions

| Table | PK Type | Rows Expected | API Exposed? | Rationale |
|-------|---------|---------------|--------------|-----------|
| `Users` | UUID | 10k-1M | ✅ Yes (GET /users/{id}) | Aggregate root, security (non-enumerable), distributed, API best practices |
| `SubscriptionPlans` | INT | 3-5 | ✅ Yes (GET /plans/{id}) | ⚠️ **Revisit:** Lookup table (<10 rows), high join frequency → INT/SERIAL better (storage + performance). **Trade-off:** API exposes enumerable IDs (acceptable for public plans catalog). |
| `Orders` | UUID | 100k-10M | ✅ Yes (GET /orders/{id}) | Aggregate root, high-volume, security, distributed |
| `OrderItems` | UUID | 1M-100M | ❌ No (internal) | High-volume, child of Orders (FK uses UUID), consistency |
| `SystemConfig` | UUID | 1 (singleton) | ❌ No (internal) | Singleton pattern (fixed ID: 00000000-0000-0000-0000-000000000001) |
| `AuditLog` | UUID | 1M-100M | ❌ No (internal) | High-volume, distributed writes, no joins |

**Key Decision:**
- **Users, Orders, Transactions:** UUID (security + distributed + API)
- **SubscriptionPlans:** INT/SERIAL recommended (lookup table, <10 rows, high joins) → ⚠️ Current implementation uses UUID (acceptable but sub-optimal)
- **OrderItems:** UUID (consistency with Orders FK, high-volume)

---

### When to Revisit PK Strategy

**Triggers for Re-evaluation:**

| Trigger | Action | Example |
|---------|--------|---------|
| Table grows >1M rows | Consider UUID if INT | Categories table unexpectedly grows to 10k rows |
| API exposure changes | Switch to UUID | Internal table now exposed in public API |
| Distributed system planned | Switch to UUID | Moving to multi-region architecture |
| Join performance issues | Consider INT if UUID | 10-table joins with UUID causing slowness |
| Security audit findings | Switch to UUID | Enumeration attack discovered |

**Migration Path (INT → UUID):**
1. Add new UUID column (nullable)
2. Backfill UUIDs for existing rows
3. Update app to use UUID (dual-write period)
4. Migrate FKs to point to UUID
5. Drop old INT column (after 2 sprints)

**Migration Path (UUID → INT):**
❌ **Not recommended** (breaking change, data loss risk)
- Only if table is internal-only AND <10k rows AND no distributed writes

---

### Best Practices Summary

#### ✅ DO:
- Use UUID for Aggregate Roots exposed in public APIs (Users, Orders, Transactions)
- Use INT/SERIAL for lookup tables (<100 rows, high join frequency)
- Document PK type decision rationale in DBA-01 (this section)
- Consider security implications (enumerable vs non-enumerable)
- Plan for future distributed systems (UUID = easier scaling)

#### ❌ DON'T:
- Use UUID everywhere "just because" (storage/performance cost)
- Use INT for security-sensitive user-facing IDs (enumeration attacks)
- Mix PK types arbitrarily (be consistent within bounded context)
- Ignore storage costs (UUID = 4x larger than INT in indexes)
- Change PK type after production (migration risk)

---

### References

- **PostgreSQL UUID Performance:** https://www.postgresql.org/docs/current/datatype-uuid.html
- **Stripe API Design (UUID):** https://stripe.com/docs/api
- **GitHub REST API (INT):** https://docs.github.com/en/rest
- **Sequential vs Random IDs:** https://www.2ndquadrant.com/en/blog/sequential-uuid-generators/

---

---

## 🚀 Indexing Strategy

### Indexes Sugeridos

#### Bounded Context: [BC1]

| Table | Index Name | Columns | Type | Justificativa |
|-------|------------|---------|------|---------------|
| `[TableName]` | `IX_[Table]_Status` | `Status` | NONCLUSTERED | Query `GetActiveAsync` filtra por Status |
| `[TableName]` | `IX_[Table]_CreatedAt` | `CreatedAt DESC` | NONCLUSTERED | Ordenação recente-primeiro frequente |
| `[ChildTable]` | `IX_[Child]_ParentId` | `[Parent]Id` | NONCLUSTERED | **CRÍTICO:** FK lookup |
| `[ChildTable]` | `IX_[Child]_Parent_Status` | `[Parent]Id, Status` | NONCLUSTERED COVERING | Query composta frequente |

**Prioridade:**  
- 🔴 **Alta:** `IX_[Child]_ParentId` (blocking FK queries)  
- 🟡 **Média:** `IX_[Table]_Status` (performance improvement)  
- 🟢 **Baixa:** `IX_[Table]_CreatedAt` (nice to have)  

---

### Query Performance Estimativas

| Repository Method | Affected Tables | Estimated Impact | With Index |
|-------------------|-----------------|------------------|------------|
| `GetByIdAsync` | `[Table]` | Fast (PK lookup) | N/A (PK já indexado) |
| `GetActiveAsync` | `[Table]` | Slow (table scan) | **Fast** (com IX_Status) |
| `GetChildrenAsync` | `[ChildTable]` | **Very Slow** (no index) | **Fast** (com IX_ParentId) |

---

## 📊 Database Constraints

### Constraints a Adicionar (via migration)

```sql
-- Status constraint
ALTER TABLE [TableName]
ADD CONSTRAINT CHK_[Table]_Status
CHECK (Status IN ('Active', 'Inactive', 'Pending'));

-- Data integrity
ALTER TABLE [TableName]
ADD CONSTRAINT CHK_[Table]_Dates
CHECK (UpdatedAt IS NULL OR UpdatedAt >= CreatedAt);
```

---

## 🔄 Integração Entre BCs (Database Level)

### [BC1] ↔ [BC2]

**Estratégia:** Separate schemas, NO foreign keys between BCs  

**Schemas:**  
- `[BC1]`: Schema `[BC1Name]`  
- `[BC2]`: Schema `[BC2Name]`  

**Integração:**  
- Via Domain Events (aplicação)  
- Via Materialized Views (read model) se necessário  

**❌ NÃO FAZER:**  
- Foreign Keys entre schemas de BCs diferentes  
- Joins diretos entre tabelas de BCs diferentes  

---

## 🛡️ Data Integrity & Concurrency

### Concurrency Control

**Estratégia:** Optimistic Concurrency (EF Core)  

**Implementação:**  
- Coluna `Version` (ROWVERSION/TIMESTAMP) em tabelas principais  
- EF Core tracked entities com concurrency token  

**Validação:**  
```sql
-- Verificar se Version está configurado
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME = 'Version'
  AND TABLE_SCHEMA IN ('[BC1]', '[BC2]');
```

---

### Data Integrity

**Validações Necessárias:**  

| Table | Validation | Type | Status |
|-------|------------|------|--------|
| `[Table]` | Status values | CHECK constraint | ⚠️ Adicionar |
| `[Table]` | Date logic | CHECK constraint | ⚠️ Adicionar |
| `[ChildTable]` | FK cascade | ON DELETE CASCADE | ✅ OK |

---

## 📈 Scalability Considerations

### Current Volume Estimates
- `[Table]`: ~[N] records/month  
- `[ChildTable]`: ~[N*10] records/month (10 children per parent)  

### Partitioning Strategy (Future)
**Quando considerar:**  
- `[Table]` > 10M records  
- Queries por time range (particionar por `CreatedAt`)  

**Não implementar agora** (MVP não precisa)

---

## 🔍 Migration Script Review

### DE Migration: `[MigrationName]`

**Arquivo:** `02-backend/src/Infrastructure/Persistence/Migrations/[timestamp]_[MigrationName].cs`  

**Review:**  

| Aspecto | Status | Comentário |
|---------|--------|------------|
| **Schema correto** | ✅ OK | Tabelas criadas em schema apropriado |
| **Data types** | ⚠️ Ajustar | Ver sugestões acima |
| **Indexes** | 🔴 FALTA | **Migration não criou indexes sugeridos** |
| **Constraints** | ⚠️ FALTA | CHECK constraints não implementados |
| **Seed Data** | ✅ N/A | Não aplicável para este epic |

**Ação para DE:**  
Criar migration adicional com:
1. Indexes sugeridos
2. CHECK constraints
3. Otimizações de data types

---

## ✅ Checklist de Validação

### Schema Design
- [ ] Tabelas normalizadas adequadamente  
- [ ] Foreign Keys corretos com CASCADE apropriado  
- [ ] Data types otimizados (VARCHAR sizes, etc)  
- [ ] Nullable correto (NOT NULL onde obrigatório)  

### Performance
- [ ] **CRÍTICO:** Indexes em todas as FKs  
- [ ] Indexes em colunas de filtro frequente  
- [ ] Indexes compostos para queries complexas  
- [ ] Covering indexes onde apropriado  

### Data Integrity
- [ ] CHECK constraints para enums/status  
- [ ] Data validation constraints  
- [ ] Concurrency control (Version column)  

### Best Practices
- [ ] Schemas separados por BC  
- [ ] NO FKs entre BCs diferentes  
- [ ] Naming conventions consistentes  

---

## 🎯 Ações para DE

### Priority 1 - CRÍTICO (Blocking)
1. ✅ **Criar index:** `IX_[ChildTable]_ParentId`
2. ✅ **Criar index:** `IX_[Table]_Status`

### Priority 2 - Importante
3. ⚠️ **Adicionar constraints:** CHECK em Status
4. ⚠️ **Otimizar data types:** VARCHAR sizes

### Priority 3 - Opcional (Performance)
5. 🟢 **Criar indexes:** Compostos para queries complexas

**Migration Sugerida:**  

```csharp
public partial class Add[Epic]Indexes : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // Critical indexes
        migrationBuilder.CreateIndex(
            name: "IX_[ChildTable]_ParentId",
            schema: "[BC]",
            table: "[ChildTable]",
            column: "[Parent]Id");

        migrationBuilder.CreateIndex(
            name: "IX_[Table]_Status",
            schema: "[BC]",
            table: "[Table]",
            column: "Status");

        // Constraints
        migrationBuilder.Sql(@"
            ALTER TABLE [BC].[Table]
            ADD CONSTRAINT CHK_[Table]_Status
            CHECK (Status IN ('Active', 'Inactive', 'Pending'))
        ");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        // Reversal logic
    }
}
```

---

## 🔄 Migration Rollback Strategy

### Princípio Fundamental

**Toda migration deve ser rollback-safe** - o método `Down()` não pode falhar em produção.

### Pattern: Expand/Contract (3-Step Migration)

Para breaking changes (rename, change type, etc), use o padrão **Expand/Contract**:

#### ❌ Problema: Breaking Change Direto

```csharp
// Migration 001: Rename column (QUEBRA apps antigas!)
public override void Up(MigrationBuilder mb)
{
    mb.RenameColumn("OldName", "Users", "NewName");  // ❌ App antiga para
}
```

**Consequência:** Aplicação antiga para (procura coluna `OldName` que não existe mais)  

---

#### ✅ Solução: Expand/Contract (3 Deploys)

**Step 1: EXPAND - Adicionar novo campo (nullable)**
```csharp
// Migration 001: Adiciona nova coluna
public override void Up(MigrationBuilder mb)
{
    mb.AddColumn<string>("NewName", "Users", nullable: true);
}

public override void Down(MigrationBuilder mb)
{
    mb.DropColumn("NewName", "Users");  // ✅ Safe rollback
}
```
**Deploy 1:** App antiga ainda funciona (ignora `NewName`)  

---

**Step 2: MIGRATE - Copiar dados (backfill)**
```csharp
// Migration 002: Copia dados OldName → NewName
public override void Up(MigrationBuilder mb)
{
    mb.Sql("UPDATE Users SET NewName = OldName WHERE NewName IS NULL");
}

public override void Down(MigrationBuilder mb)
{
    mb.Sql("UPDATE Users SET OldName = NewName WHERE OldName IS NULL");
}
```
**Deploy 2:** App atualizada usa `NewName`, app antiga usa `OldName` (ambas funcionam)  

---

**Step 3: CONTRACT - Remover campo antigo**
```csharp
// Migration 003: Remove coluna antiga (após 2 sprints)
public override void Up(MigrationBuilder mb)
{
    mb.DropColumn("OldName", "Users");
}

public override void Down(MigrationBuilder mb)
{
    mb.AddColumn<string>("OldName", "Users", nullable: true);
    mb.Sql("UPDATE Users SET OldName = NewName");  // ⚠️ Rollback possível mas dados podem estar desatualizados
}
```
**Deploy 3:** App antiga não existe mais, seguro remover `OldName`  

---

### Rollback-Safe Patterns

#### 1. Adding Columns

**✅ SAFE:**  
```csharp
// Nullable ou com default value
mb.AddColumn<string>("Email", "Users", nullable: true);
// ou
mb.AddColumn<string>("Email", "Users", nullable: false, defaultValue: "");
```

**❌ UNSAFE:**  
```csharp
// NOT NULL sem default em tabela com dados
mb.AddColumn<string>("Email", "Users", nullable: false);  // ❌ Falha se Users tem linhas!
```

**Rollback:** `DropColumn` sempre funciona (mas dados perdidos)  

---

#### 2. Dropping Columns

**⚠️ CUIDADO:** Não pode recuperar dados perdidos  

```csharp
public override void Up(MigrationBuilder mb)
{
    mb.DropColumn("ObsoleteField", "Users");
}

public override void Down(MigrationBuilder mb)
{
    mb.AddColumn<string>("ObsoleteField", "Users", nullable: true);
    // ⚠️ Coluna recriada, mas DADOS PERDIDOS!
}
```

**Safe approach:**  
1. Deprecate código que usa a coluna (comentar/remover)
2. Aguardar 2 sprints (garantir que app antiga não existe mais)
3. Então drop coluna

---

#### 3. Renaming Columns

**Use Expand/Contract** (3 steps acima)

Nunca use `RenameColumn` diretamente em produção.

---

#### 4. Changing Column Types

```csharp
// Step 1: Adicionar nova coluna com novo tipo
mb.AddColumn<int>("QuantityNew", "Orders", nullable: true);

// Step 2: Migrar dados
mb.Sql("UPDATE Orders SET QuantityNew = TRY_CAST(QuantityOld AS INT)");

// Step 3 (migration separada): Drop coluna antiga
mb.DropColumn("QuantityOld", "Orders");
mb.RenameColumn("QuantityNew", "Orders", "Quantity");
```

---

#### 5. Adding NOT NULL Constraints

**❌ UNSAFE:**  
```csharp
mb.AddColumn<string>("Email", "Users", nullable: false);  // Quebra!
```

**✅ SAFE (2 steps):**  
```csharp
// Migration 1: Adicionar nullable
mb.AddColumn<string>("Email", "Users", nullable: true, defaultValue: "");

// Migration 2 (após backfill): Tornar NOT NULL
mb.AlterColumn<string>("Email", "Users", nullable: false);
```

---

### Checklist: Is This Migration Rollback-Safe?

Antes de fazer merge do PR:

- [ ] `Down()` migration testada localmente?  
- [ ] Colunas NOT NULL têm default value ou são nullable inicialmente?  
- [ ] Breaking changes usam Expand/Contract (3 deploys)?  
- [ ] Dados críticos não são perdidos em `Down()`?  
- [ ] Aplicação antiga continua funcionando após `Up()`?  
- [ ] Rollback testado: `update → rollback → update novamente`?  

---

### Testing Rollback Locally

```bash
# Aplicar migration
dotnet ef database update [MigrationName]

# Testar rollback
dotnet ef database update [PreviousMigration]

# Re-aplicar (deve funcionar)
dotnet ef database update [MigrationName]
```

**Se `Down()` falhar → Migration NÃO é production-ready!**

---

### Common Rollback Failures

| Cenário | Por que falha | Solução |
|---------|---------------|---------|
| Add NOT NULL sem default | Tabela tem linhas existentes | Adicionar nullable primeiro, backfill, depois NOT NULL |
| Drop column com dados | Rollback recria coluna vazia | Usar Expand/Contract (não dropar imediatamente) |
| Rename column | App antiga procura nome antigo | Expand/Contract (ambos nomes existem temporariamente) |
| Change type incompatível | Dados não podem ser convertidos de volta | Manter ambas colunas temporariamente |

---

### Emergency Rollback Procedure

Se deploy falhou e precisa rollback urgente:

```bash
# 1. Rollback application (container/código)
git revert [commit-hash]
docker service update --rollback myapp

# 2. Rollback database (EF Core)
dotnet ef database update [PreviousMigration] --connection "[prod-connection]"

# 3. Verificar aplicação funcionando
curl https://api.prod/health

# 4. Post-mortem: Por que Down() não estava safe?
```

---

## 🔄 Backup & Recovery (MVP Básico)

### RTO/RPO para MVP
**RTO (Recovery Time Objective):** 2 horas  
**RPO (Recovery Point Objective):** 30 minutos  

### Estratégia de Backup MVP
```yaml
backup-strategy:
  full-backup:
    frequency: Daily at 3 AM UTC
    retention: 7 days

  incremental-backup:
    frequency: Every 30 minutes
    retention: 24 hours

  storage:
    location: Same cloud provider (Azure Blob / S3)
    encryption: AES-256
```

### Restore Test
- [ ] Backup restaurado com sucesso em ambiente de teste?  
- [ ] Procedimento de restore documentado?  

**⚠️ Para Produção:** Considerar geo-replication e DR secundário quando tiver usuários reais.  

---

## 📅 Data Retention Policy

### Retenção por Tipo de Dado (Requisito Legal Trading)

| Tipo de Dado | Retenção Mínima | Base Legal | Ação Após Período |
|--------------|-----------------|------------|-------------------|
| **Trade records** | 5 anos | CVM/SEC regulation | Arquivar em cold storage |
| **Audit logs** | 7 anos | SOX compliance | Arquivar, deletar após 7y |
| **User data** | Até solicitação de exclusão | LGPD/GDPR | Permitir delete on request |
| **Market data** | 2 anos | Business need | Arquivar ou deletar |

### Implementação
```sql
-- Exemplo: Job mensal para arquivar dados antigos
CREATE PROCEDURE ArchiveOldTrades
AS
BEGIN
    INSERT INTO TradeArchive
    SELECT * FROM Trades
    WHERE CreatedAt < DATEADD(year, -5, GETDATE());

    DELETE FROM Trades
    WHERE CreatedAt < DATEADD(year, -5, GETDATE());
END
```

---

## 🔒 Transaction Isolation (Prevenção de Race Conditions)

### Isolation Levels por Cenário

| Operação | Isolation Level | Justificativa |
|----------|----------------|---------------|
| **Criar estratégia** | READ COMMITTED | Default, suficiente |
| **Atualizar estratégia** | REPEATABLE READ | Evitar leitura inconsistente durante update |
| **Cálculo Greeks** | READ UNCOMMITTED | Read-only, performance crítica |
| **Portfolio valuation** | SNAPSHOT | Snapshot consistente no tempo |

### Deadlock Prevention BÁSICO

**Regra:** Sempre adquirir locks na MESMA ORDEM  

```sql
-- ✅ CORRETO: Lock Strategy → depois StrategyLeg
BEGIN TRANSACTION
    UPDATE Strategy SET Status = 'Closed' WHERE Id = @strategyId;
    UPDATE StrategyLeg SET Status = 'Closed' WHERE StrategyId = @strategyId;
COMMIT;

-- ❌ ERRADO: Lock StrategyLeg → depois Strategy (pode deadlock)
```

**Dica:** Manter transações curtas (<100ms), não fazer chamadas externas dentro de transaction.  

---

## 📝 Notas Finais

**Schema Quality Score:** [X]/10  

**Approval Status:**  
- [ ] ✅ **APPROVED** - Schema pronto para produção  
- [x] ⚠️ **APPROVED WITH CHANGES** - Implementar ações Priority 1  
- [ ] ❌ **REJECTED** - Redesign necessário  

**Checklist MVP:**  
- [ ] Backup strategy configurado  
- [ ] Data retention policy documentado  
- [ ] Transaction isolation definido para operações críticas  
- [ ] Indexes em todas FK  
- [ ] Concurrency control (Version column)  

**Next Steps:**  
1. DE implementa ações Priority 1 (indexes, constraints)
2. Configurar backup automático
3. Re-review após migration
4. Performance testing com dados reais

---

## 🔗 Referências

- **DE Tactical Model:** `00-doc-ddd/04-tactical-design/DE-01-[EpicName]-Tactical-Model.md`  
- **EF Migrations:** `02-backend/src/Infrastructure/Persistence/Migrations/`  
- **Repository Interfaces:** Verificar queries em `DE-01` para entender index needs  
