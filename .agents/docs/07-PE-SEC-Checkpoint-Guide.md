<!-- FORMATAÇÃO: Todas as linhas de metadata abaixo DEVEM terminar com 2 espaços para forçar quebra de linha em Markdown -->
# PE/SEC Checkpoint Guide - Quando e Como Executar

**Versão:** 2.0  
**Data:** 2025-10-29  
**Objetivo:** Guia consolidado para determinar quando PE e SEC devem executar checkpoints opcionais e como executá-los com qualidade.  

---

## 🎯 Visão Geral

**PE** (Platform Engineer) e **SEC** (Security Specialist) executam **baseline obrigatório** na Discovery (1x):
- **PE platform engineering documentation (PE-00-Quick-Start.md, PE-01-Server-Setup.md, PE-02-Scaling-Strategy.md)**: Docker Compose, scripts deploy, env vars, logs, health checks, server setup
- **SEC-00-Security-Baseline.md**: OWASP Top 3, LGPD mínimo, auth strategy, input validation, secrets management

Durante **iteração por épico**, checkpoints são **OPCIONAIS** por padrão, mas **OBRIGATÓRIOS** se o épico atender aos critérios de decisão abaixo.

**Problema:** Épicos 4+ podem acumular dívida técnica (N+1 queries, falta de autorização, hardcoded secrets) sem revisão.

**Solução:** **Checkpoints leves opcionais** (15-30 min) quando necessário, baseados em critérios objetivos.

---

## 🔧 PE Checkpoint: Matriz de Decisão

### ✅ OBRIGATÓRIO (Execute PE Checkpoint)

Execute **PE checkpoint** (15-30 min) se o épico atender a **qualquer** critério abaixo:

| Critério | Descrição | Exemplo Prático |
|----------|-----------|-----------------|
| **Queries Complexas** | Epic com queries SQL usando >3 JOINs | Relatório consolidando Order + Customer + Product + Payment |
| **Real-time Calculations** | Epic com cálculos em tempo real (latência <200ms crítica) | Cálculo de Greeks de opções, pricing dinâmico |
| **Alto Volume de Dados** | Epic com queries retornando >1000 registros | Dashboard com histórico completo, exportação CSV |
| **Operações Assíncronas Críticas** | Epic com background jobs ou async/await complexo | Processamento de lote, integração externa |
| **Epic 4+ (Pós-MVP)** | A partir do 4º épico, revisar acúmulo de débito técnico | Qualquer épico após MVP estável |
| **Integração Externa** | Epic integra com APIs externas (3rd party) | Payment gateway, market data provider |

### 🟡 OPCIONAL (Considere PE Checkpoint)

Considere PE checkpoint se:
- Epic modifica queries existentes de épicos anteriores
- Epic adiciona novos índices ou altera schema significativamente
- Desenvolvedor solicita explicitamente review de performance

### ❌ NÃO NECESSÁRIO

Não execute PE checkpoint se:
- Epic é CRUD simples (<3 tabelas, queries básicas)
- Queries retornam <100 registros
- Nenhum cálculo ou processamento intensivo

---

## 🔒 SEC Checkpoint: Matriz de Decisão

### ✅ OBRIGATÓRIO (Execute SEC Checkpoint)

Execute **SEC checkpoint** (15-30 min) se o épico atender a **qualquer** critério abaixo:

| Critério | Descrição | Exemplo Prático |
|----------|-----------|-----------------|
| **Dados Pessoais (PII)** | Epic manipula dados pessoais (LGPD Art. 5º) | Nome, CPF, endereço, telefone, email |
| **Dados Sensíveis** | Epic manipula dados sensíveis (LGPD Art. 5º, II) | Origem racial, saúde, orientação sexual, biometria |
| **Dados Financeiros** | Epic manipula transações, saldo, pagamentos | Pagamento, saldo de conta, cartão de crédito |
| **Autenticação/Autorização** | Epic implementa login, controle de acesso, permissões | Login de usuário, roles, JWT, OAuth |
| **Epic 4+ com Dados Críticos** | A partir do 4º épico, se manipula dados críticos | Qualquer épico pós-MVP com dados PII/financeiros |
| **Integração Externa Sensível** | Epic integra com APIs externas que enviam dados sensíveis | Payment gateway, KYC provider, data analytics |
| **Upload de Arquivos** | Epic permite upload de arquivos pelo usuário | Upload de documentos, imagens, PDFs |

### 🟡 OPCIONAL (Considere SEC Checkpoint)

Considere SEC checkpoint se:
- Epic altera fluxo de autorização existente
- Epic adiciona novos endpoints públicos (sem auth)
- Desenvolvedor tem dúvidas sobre input validation ou XSS

### ❌ NÃO NECESSÁRIO

Não execute SEC checkpoint se:
- Epic é CRUD simples sem dados sensíveis
- Epic não altera autenticação/autorização
- Epic não manipula dados de usuário

---

## 📋 Checklist de Decisão Rápida

### PE Checkpoint

```markdown
[ ] Epic tem queries com >3 JOINs?
[ ] Epic faz cálculos em tempo real (<200ms)?
[ ] Epic retorna >1000 registros?
[ ] Epic usa background jobs ou async/await complexo?
[ ] Epic integra com API externa?
[ ] É o Epic 4+ (pós-MVP)?

✅ Se QUALQUER checkbox marcado → EXECUTAR PE Checkpoint
❌ Se NENHUM checkbox marcado → PULAR PE Checkpoint
```

### SEC Checkpoint

```markdown
[ ] Epic manipula dados pessoais (nome, CPF, email, telefone)?
[ ] Epic manipula dados sensíveis (saúde, biometria, origem racial)?
[ ] Epic manipula dados financeiros (pagamento, saldo, transações)?
[ ] Epic implementa autenticação/autorização (login, roles)?
[ ] Epic integra com API externa sensível (payment, KYC)?
[ ] Epic permite upload de arquivos?
[ ] É o Epic 4+ com dados críticos?

✅ Se QUALQUER checkbox marcado → EXECUTAR SEC Checkpoint
❌ Se NENHUM checkbox marcado → PULAR SEC Checkpoint
```

---

## ⚙️ Timing no Workflow

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

## 🔧 PE Performance Checkpoint - Como Executar

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

#### 5. **Server Setup & Deployment** (Discovery - 5 min)

```bash
# PE verifica se servidor remoto está preparado
✅ UFW firewall configurado (ports 22, 80, 443)
✅ fail2ban ativo (SSH brute-force protection)
✅ SSH key-based auth (password auth disabled)
✅ User dedicado com docker group
✅ Directory structure criada
✅ .env files em ambiente (não commitados)
```

**Checklist:**
- [ ] Server hardening complete (UFW, fail2ban, SSH)?
- [ ] Multi-environment .env strategy documented?
- [ ] Remote deploy script functional (local vs remote detection)?
- [ ] Health checks configured (local HTTP + remote HTTPS)?

---

### **Output PE:**

**Template:** `PE-EPIC-[N]-Performance-Checkpoint.md`

**Seções:**
1. ✅ Performance Checklist (5 categorias: DB, Async, Cache, Resources, Server/Deploy)
2. 📊 Issues Found (N+1 queries, missing indexes, server hardening, etc)
3. 🔄 Feedback Created (se necessário)
4. ✅ Final Verdict (Approved / Issues / Critical)

**Ação:**
- Issues não-críticos → FEEDBACK para SE/DBA
- Issues críticos → BLOQUEIA QAE

---

## 🔒 SEC Security Checkpoint - Como Executar

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
- [ ] .env.staging and .env.prod NOT committed?
- [ ] Staging/prod use strong passwords (16+ chars)?

#### 4. **Multi-Environment Credentials** (Discovery + Per Epic - 5 min)

```sql
-- ❌ Hardcoded password in Git (PROBLEMA)
CREATE USER app_user WITH PASSWORD 'production_password_123';

-- ✅ Correto (SEC + DBA sugerem)
-- 1. Init script com dev default (committed)
CREATE USER app_user WITH PASSWORD 'dev_password_123';

-- 2. ALTER USER migration para staging/prod (committed sem senha real)
ALTER USER app_user WITH PASSWORD :'app_password';  -- via psql -v

-- 3. Execute com env var (NOT in Git, NOT in bash history)
export DB_APP_PASSWORD="Pr0d_VeryStr0ng!#$"
psql -v app_password="$DB_APP_PASSWORD" -f 002_update_passwords.sql
```

**Checklist:**
- [ ] Database passwords NOT hardcoded in Git?
- [ ] ALTER USER migration created (002_update_production_passwords.sql)?
- [ ] Password rotation procedure documented?
- [ ] Development uses simple passwords (OK)?
- [ ] Staging/Prod use strong passwords (16+ chars)?
- [ ] Compliance noted (LGPD Art. 46, SOC2, ISO 27001)?

---

### **Output SEC:**

**Template:** `SEC-EPIC-[N]-Security-Checkpoint.md`

**Seções:**
1. ✅ Security Checklist (OWASP Top 3 + Validation + Secrets + Multi-Env Credentials)
2. 🔍 Issues Found (missing authz, hardcoded secrets, hardcoded passwords, etc)
3. ⚠️ Threats Identified (if new)
4. 🔄 Feedback Created (se necessário)
5. ✅ Final Verdict (Approved / Issues / Critical)

**Ação:**
- Issues não-críticos → FEEDBACK para SE/DE/FE
- Issues críticos → BLOQUEIA QAE

---

## 🚀 Exemplo Prático: myTraderGEO

### **Epic 1: "Criar e Visualizar Estratégia Bull Call Spread"**

#### **PE Checkpoint?**

```markdown
[ ] Queries >3 JOINs? → Não (apenas Strategy + StrategyLeg)
[ ] Real-time calculations? → Não (cálculo on-demand, não crítico)
[ ] >1000 registros? → Não (usuário tem <100 estratégias)
[ ] Background jobs? → Não
[ ] API externa? → Não
[ ] Epic 4+? → Não (Epic 1)
```

**Decisão PE:** ❌ **NÃO executar** checkpoint

---

#### **SEC Checkpoint?**

```markdown
[x] Dados pessoais? → Sim (usuário cria estratégia, associada ao UserId)
[ ] Dados sensíveis? → Não
[ ] Dados financeiros? → Parcial (estratégia tem valor, mas não é transação)
[x] Autenticação? → Sim (apenas usuário logado cria estratégia)
[ ] API externa sensível? → Não
[ ] Upload arquivos? → Não
[ ] Epic 4+? → Não
```

**Decisão SEC:** ✅ **EXECUTAR** checkpoint (2 critérios atendidos: dados pessoais + autenticação)

**Ações SEC:**
- Validar que `Strategy` tem `UserId` (ownership)
- Validar que `CreateStrategyCommand` valida JWT token
- Validar que endpoint `/api/strategies` requer `[Authorize]`
- Validar que usuário A não pode modificar estratégia de usuário B

---

### **Epic 3: "Calcular Greeks e P&L em Tempo Real"**

#### **PE Checkpoint?**

```markdown
[ ] Queries >3 JOINs? → Não
[x] Real-time calculations? → Sim (Greeks calculados em <200ms)
[ ] >1000 registros? → Não
[ ] Background jobs? → Não
[x] API externa? → Sim (integração com B3 para market data)
[ ] Epic 4+? → Não
```

**Decisão PE:** ✅ **EXECUTAR** checkpoint (2 critérios atendidos: real-time + API externa)

**Ações PE:**
- Validar que cálculo de Greeks é assíncrono
- Validar que market data API tem circuit breaker (Polly)
- Validar que market data é cacheada (Redis, TTL 5 min)
- Validar que queries de Strategy + MarketData usam `.Include()` para evitar N+1

---

#### **SEC Checkpoint?**

```markdown
[ ] Dados pessoais? → Não (apenas cálculos)
[ ] Dados sensíveis? → Não
[x] Dados financeiros? → Sim (P&L é financeiro)
[ ] Autenticação? → Sim (já validado em Epic 1)
[x] API externa sensível? → Sim (B3 API envia dados de mercado proprietários)
[ ] Upload arquivos? → Não
[ ] Epic 4+? → Não
```

**Decisão SEC:** ✅ **EXECUTAR** checkpoint (2 critérios atendidos: financeiro + API externa)

**Ações SEC:**
- Validar que API B3 usa HTTPS
- Validar que API key B3 está em env var (não hardcoded)
- Validar que P&L só é visível para owner da estratégia
- Validar que logs não expõem dados de mercado sensíveis

---

### **Epic 4: "Calculate Greeks in Real-Time" - Checkpoint Completo**

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

---

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
| **Critérios objetivos** | Decision matrix clara evita ambiguidade |

---

## 🚫 O que NÃO É

| O que NÃO é | O que É |
|-------------|---------|
| ❌ Revisão completa de código | ✅ Checklist rápido de hotspots |
| ❌ Profiling completo | ✅ Identificação de anti-patterns |
| ❌ Pentest | ✅ OWASP Top 3 compliance check |
| ❌ Bloqueio obrigatório | ✅ Checkpoint opcional baseado em critérios |
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

**Versão:** 2.0
**Status:** Ativo
**Última Atualização:** 2025-10-29
**Consolidado de:** 07-PE-SEC-Light-Review.md + 08-PE-SEC-Checkpoint-Decision-Matrix.md
