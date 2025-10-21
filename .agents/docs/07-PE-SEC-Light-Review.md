# PE/SEC Light Review - Checkpoints Opcionais por Épico

**Versão:** 1.0
**Data:** 2025-10-10
**Objetivo:** Adicionar camada leve de revisão de performance e segurança sem sobrecarregar o processo

---

## 🎯 Conceito

**PE** e **SEC** executam **Discovery** (setup inicial), mas NÃO participam ativamente de cada épico.

**Problema:** Épicos 4+ podem acumular dívida técnica (N+1 queries, falta de autorização) sem revisão.

**Solução:** **Checkpoints leves opcionais** (15-30 min) quando necessário.

---

## 📊 Quando Usar

### **✅ SIM - Execute Checkpoint:**

| Cenário | Agente | Exemplo |
|---------|--------|---------|
| Epic 4+ (pós-MVP estável) | PE + SEC | A partir do 4º épico |
| Dados sensíveis (PII, credentials, payment) | SEC | Epic de Autenticação, Pagamentos |
| Queries complexas (>3 JOINs) | PE | Epic de Relatórios, Analytics |
| Real-time/Performance crítico | PE | Epic de Cálculo de Greeks |
| Auth/Authz introduzido | SEC | Epic de Gestão de Usuários |

### **❌ NÃO - Pule Checkpoint:**

| Cenário | Por quê? |
|---------|---------|
| Epic 1-3 (MVP) | Foco em funcionalidade, não otimização prematura |
| Epic simples (CRUD básico) | Não há riscos de performance/segurança |
| Queries simples (sem JOINs) | PE não adiciona valor |
| Sem dados sensíveis | SEC não adiciona valor |

---

## ⚙️ Como Funciona

### **Timing no Workflow**

```
Dia 7-9: FE implementa UI
       ↓
Dia 9 (OPCIONAL): PE + SEC Checkpoints (30 min TOTAL)
       ├─ PE: 15 min performance review
       └─ SEC: 15 min security review
       ↓
Dia 10: QAE Quality Gate
```

**Checkpoint NÃO bloqueia épico** (exceto se issue crítico encontrado)

---

## 🔧 PE Performance Checkpoint

### **Duração:** 15-30 min

### **O que PE Revisa:**

#### 1. **Database Performance** (5 min)
```csharp
// ❌ N+1 Query (PROBLEMA)
var strategies = await _context.Strategies.ToListAsync();
foreach (var strategy in strategies)
{
    var legs = await _context.StrategyLegs
        .Where(l => l.StrategyId == strategy.Id)
        .ToListAsync(); // N+1!
}

// ✅ Correto (PE sugere)
var strategies = await _context.Strategies
    .Include(s => s.Legs) // Eager loading
    .ToListAsync();
```

**Checklist:**
- [ ] N+1 queries identificados?
- [ ] `.Include()` usado para related data?
- [ ] Indexes em FK/query filters?
- [ ] Queries <100ms?

#### 2. **Async/Await** (5 min)
```csharp
// ❌ Deadlock Risk (PROBLEMA)
var result = _service.GetDataAsync().Result; // Sync-over-async!

// ✅ Correto (PE sugere)
var result = await _service.GetDataAsync();
```

**Checklist:**
- [ ] No `.Result` or `.Wait()`?
- [ ] I/O operations async?

#### 3. **Caching** (5 min)
```csharp
// PE sugere cachear market data
services.AddMemoryCache();
_cache.Set("market-data", data, TimeSpan.FromMinutes(5));
```

**Checklist:**
- [ ] Frequently accessed data cached?
- [ ] Cache expiration configured?

#### 4. **Resource Management** (5 min)
```csharp
// ✅ Usando using statement
using var connection = new SqlConnection(connectionString);
```

**Checklist:**
- [ ] Connections/streams disposed?
- [ ] No memory leaks?

---

### **Output PE:**

**Template:** `PE-EPIC-[N]-Performance-Checkpoint.md`

**Seções:**
1. ✅ Performance Checklist (4 categorias)
2. 📊 Issues Found (N+1 queries, missing indexes, etc)
3. 🔄 Feedback Created (se necessário)
4. ✅ Final Verdict (Approved / Issues / Critical)

**Ação:**
- Issues não-críticos → FEEDBACK para SE/DBA
- Issues críticos → BLOQUEIA QAE

---

## 🔒 SEC Security Checkpoint

### **Duração:** 15-30 min

### **O que SEC Revisa:**

#### 1. **OWASP Top 3** (10 min)

**A) Broken Access Control**
```csharp
// ❌ Sem autorização (PROBLEMA)
public void DeleteStrategy(Guid id)
{
    var strategy = _repo.GetById(id);
    _repo.Delete(strategy); // Qualquer user pode deletar!
}

// ✅ Correto (SEC sugere)
public void DeleteStrategy(Guid id, UserId requestingUser)
{
    var strategy = _repo.GetById(id);

    if (strategy.OwnerId != requestingUser)
        throw new UnauthorizedException();

    _repo.Delete(strategy);
}
```

**Checklist:**
- [ ] Authorization checks em aggregates?
- [ ] User só acessa own resources?
- [ ] API tem `[Authorize]`?

**B) Cryptographic Failures**
```csharp
// ❌ Senha em plain text (PROBLEMA)
user.Password = request.Password;

// ✅ Correto (SEC sugere)
user.PasswordHash = BCrypt.HashPassword(request.Password);
```

**Checklist:**
- [ ] Sensitive data encrypted?
- [ ] HTTPS enforced?
- [ ] Passwords hashed?

**C) Injection**
```csharp
// ❌ SQL Injection (PROBLEMA)
var query = $"SELECT * FROM Users WHERE Email = '{email}'";

// ✅ Correto (SEC sugere - EF parameterized)
var user = await _context.Users
    .Where(u => u.Email == email)
    .FirstOrDefaultAsync();
```

**Checklist:**
- [ ] Parameterized queries?
- [ ] Input validation in VOs?
- [ ] DTOs have validation?

#### 2. **Input Validation** (5 min)
```csharp
// ✅ Value Object com validação
public record Strike(decimal Value)
{
    public Strike
    {
        if (Value <= 0)
            throw new DomainException("Strike must be > 0");
    }
}
```

**Checklist:**
- [ ] Value Objects validate?
- [ ] DTOs have `[Required]`, `[MaxLength]`?

#### 3. **Secrets Management** (5 min)
```csharp
// ❌ Hardcoded secret (PROBLEMA)
var apiKey = "sk_live_123456789";

// ✅ Correto (SEC sugere)
var apiKey = Environment.GetEnvironmentVariable("API_KEY");
```

**Checklist:**
- [ ] No hardcoded secrets?
- [ ] .env in .gitignore?

---

### **Output SEC:**

**Template:** `SEC-EPIC-[N]-Security-Checkpoint.md`

**Seções:**
1. ✅ Security Checklist (OWASP Top 3 + Validation + Secrets)
2. 🔍 Issues Found (missing authz, hardcoded secrets, etc)
3. ⚠️ Threats Identified (if new)
4. 🔄 Feedback Created (se necessário)
5. ✅ Final Verdict (Approved / Issues / Critical)

**Ação:**
- Issues não-críticos → FEEDBACK para SE/DE/FE
- Issues críticos → BLOQUEIA QAE

---

## 📋 Exemplo Prático

### **Epic 4: Calculate Greeks in Real-Time**

#### **PE Checkpoint (15 min):**

**Trigger:** Epic 4 (pós-MVP) + performance crítico (real-time)

**PE revisa código:**
```csharp
// StrategyService.cs
public async Task<Greeks> CalculateGreeks(Guid strategyId)
{
    var strategy = await _repo.GetById(strategyId);

    // ❌ PE encontra N+1 query
    foreach (var leg in strategy.Legs)
    {
        var marketData = await _marketDataService.GetPrice(leg.StrikePrice);
    }
}
```

**PE Output:**
```markdown
# PE-EPIC-04-Calculate-Greeks-Performance-Checkpoint

## Issues Found
- ❌ N+1 query: StrategyService.cs:45 (loading market data in loop)
- ⚠️ Missing cache: Market data should be cached (5-min expiration)

## Feedback Created
- FEEDBACK-010-PE-SE-n-plus-1-query-calculate-greeks.md

## Verdict
⚠️ Issues Found (non-blocking) - Epic can proceed to QAE
```

#### **SEC Checkpoint (15 min):**

**Trigger:** Epic 4 (pós-MVP)

**SEC revisa código:**
```csharp
// GreeksController.cs
[HttpGet("{strategyId}/greeks")] // ❌ Missing [Authorize]
public async Task<IActionResult> GetGreeks(Guid strategyId)
{
    var greeks = await _service.CalculateGreeks(strategyId);
    return Ok(greeks); // ❌ Qualquer user pode ver Greeks de qualquer strategy!
}
```

**SEC Output:**
```markdown
# SEC-EPIC-04-Calculate-Greeks-Security-Checkpoint

## Issues Found
- 🔴 CRITICAL: GreeksController.cs:25 - Missing [Authorize] attribute
- 🔴 CRITICAL: No ownership check - any user can view any strategy's Greeks

## Feedback Created
- FEEDBACK-011-SEC-SE-missing-authorization-greeks-endpoint.md

## Verdict
🔴 CRITICAL ISSUES - BLOCKS QAE until fixed
```

**Resultado:** SE corrige issues críticos antes de QAE testar.

---

## ✅ Benefícios

| Benefício | Descrição |
|-----------|-----------|
| **Não sobrecarrega** | 30 min total, apenas quando necessário |
| **Previne dívida técnica** | Catch issues cedo (N+1, authz missing) |
| **Complementa QAE** | QAE testa funcionalidade, PE/SEC checam quality |
| **Feedback direcionado** | PE → SE/DBA, SEC → SE/DE/FE |
| **Opcional** | Epic 1-3 não precisa (foco em MVP) |

---

## 🚫 O que NÃO É

| O que NÃO é | O que É |
|-------------|---------|
| ❌ Revisão completa de código | ✅ Checklist rápido de hotspots |
| ❌ Profiling completo | ✅ Identificação de anti-patterns |
| ❌ Pentest | ✅ OWASP Top 3 compliance check |
| ❌ Bloqueio obrigatório | ✅ Checkpoint opcional |
| ❌ Deliverable extenso | ✅ Checklist de 1 página |

---

## 📊 Métricas de Sucesso

**Objetivo:** Identificar 70% dos issues de performance/segurança ANTES de QAE.

| Métrica | Target | Como Medir |
|---------|--------|------------|
| Issues encontrados por PE/SEC | ≥3 por épico (Epic 4+) | Count in checkpoint docs |
| Feedbacks críticos | <10% do total | FEEDBACK-*-PE-*.md, FEEDBACK-*-SEC-*.md |
| Tempo de checkpoint | <30 min | Timestamp em checkpoint docs |
| Issues reincidentes | <5% | Track same issue across epics |

---

## 🔗 Referências

- **Templates:**
  - `.agents/templates/08-platform-engineering/PE-EPIC-N-Performance-Checkpoint.template.md`
  - `.agents/templates/09-security/SEC-EPIC-N-Security-Checkpoint.template.md`
- **Agent Specs:**
  - [30-PE - Platform Engineer.xml](../30-PE - Platform Engineer.xml)
  - [35-SEC - Security Specialist.xml](../35-SEC - Security Specialist.xml)
- **Workflow:** [00-Workflow-Guide.md](00-Workflow-Guide.md)
- **OWASP Top 10:** https://owasp.org/www-project-top-ten/

---

## 📝 Comandos de Invocação

### **PE Checkpoint:**
```
"PE, execute performance checkpoint para Epic 4 (Calculate Greeks)"
"PE, revise queries de performance para Epic 5"
```

### **SEC Checkpoint:**
```
"SEC, execute security checkpoint para Epic 2 (User Authentication)"
"SEC, revise segurança do Epic 4 (Payment Processing)"
```

---

**Versão:** 1.0
**Status:** Ativo
**Última Atualização:** 2025-10-10
