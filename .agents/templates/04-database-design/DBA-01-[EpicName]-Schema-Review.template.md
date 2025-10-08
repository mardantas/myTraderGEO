# DBA-01-[EpicName]-Schema-Review.md

**Projeto:** [PROJECT_NAME]
**Épico:** [Epic Name]
**Data:** [YYYY-MM-DD]
**Reviewer:** DBA Agent

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
