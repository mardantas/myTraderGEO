# PE/SEC Checkpoint Decision Matrix

**Versão:** 1.0
**Data:** 2025-10-10
**Objetivo:** Definir critérios objetivos para determinar quando PE e SEC devem executar checkpoints opcionais durante iteração de épicos.

---

## 🎯 Visão Geral

PE (Platform Engineer) e SEC (Security Specialist) executam **baseline obrigatório** na Discovery (1x):
- **PE-00-Environments-Setup.md**: Docker Compose, scripts deploy, env vars, logs, health checks
- **SEC-00-Security-Baseline.md**: OWASP Top 3, LGPD mínimo, auth strategy, input validation

Durante **iteração por épico**, checkpoints são **OPCIONAIS** por padrão, mas **OBRIGATÓRIOS** se o épico atender aos critérios abaixo.

---

## 🔧 PE Checkpoint: Quando Executar

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

## 🔒 SEC Checkpoint: Quando Executar

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

## 🎬 Fluxo de Decisão Visual

```
┌─────────────────────────────────────────┐
│ Épico em Implementação (Day 9)          │
└─────────────────────────────────────────┘
                 ↓
    ┌────────────────────────────┐
    │ Consultar Decision Matrix  │
    └────────────────────────────┘
                 ↓
         ┌───────┴───────┐
         │               │
    ┌────▼────┐    ┌────▼────┐
    │ PE      │    │ SEC     │
    │ Needed? │    │ Needed? │
    └────┬────┘    └────┬────┘
         │              │
    ┌────▼────┐    ┌────▼────┐
    │ ✅ Sim  │    │ ✅ Sim  │
    │ ❌ Não  │    │ ❌ Não  │
    └────┬────┘    └────┬────┘
         │              │
         └──────┬───────┘
                ↓
    ┌───────────────────────────┐
    │ Se ✅: Executar Checkpoint│
    │ Se ❌: Prosseguir para QAE│
    └───────────────────────────┘
```

---

## 📝 O Que PE/SEC Fazem no Checkpoint

### PE Checkpoint (15-30 min)

**Entregável:** Quick checklist (NOT full document), feedback to SE/DBA if issues found

**Itens Revisados:**
1. ✅ **Database Performance**
   - N+1 queries identificados? (usar `.Include()`)
   - Índices faltando em FK/filtros?
   - Queries >100ms?

2. ✅ **Async/Await Correctness**
   - Sem `.Result` ou `.Wait()` (risco deadlock)?
   - Operações I/O são async?

3. ✅ **Caching Strategy**
   - Dados frequentes cacheados? (Redis/In-Memory)
   - Invalidação de cache clara?

4. ✅ **Resource Management**
   - Connections/streams disposed corretamente?
   - Sem memory leaks em loops?

**Saída:**
- Se OK: Aprovação verbal/chat (sem documento)
- Se issues: `FEEDBACK-XXX-PE-SE-[issue].md` ou `FEEDBACK-XXX-PE-DBA-[issue].md`

---

### SEC Checkpoint (15-30 min)

**Entregável:** Quick checklist (NOT full document), feedback to SE/DE/FE if issues found

**Itens Revisados:**
1. ✅ **OWASP Top 3 Compliance**
   - **Broken Access Control:** Authorization checks em place?
   - **Cryptographic Failures:** Dados sensíveis encrypted? (at rest/transit)
   - **Injection:** Queries parametrizadas? Input validation?

2. ✅ **Input Validation**
   - Value Objects validam input?
   - DTOs têm `[Required]`, `[MaxLength]`?
   - Prevenção de XSS? (React auto-escapes)

3. ✅ **Authentication & Authorization**
   - JWT token validado?
   - Autorização no domínio? (somente owner modifica)
   - Operações sensíveis requerem re-auth?

4. ✅ **Secrets Management**
   - Sem hardcoded secrets?
   - Environment variables usadas?
   - `.env` no `.gitignore`?

**Saída:**
- Se OK: Aprovação verbal/chat (sem documento)
- Se issues: `FEEDBACK-XXX-SEC-SE-[issue].md` ou `FEEDBACK-XXX-SEC-DE-[issue].md` ou `FEEDBACK-XXX-SEC-FE-[issue].md`

---

## 🚀 Exemplo Prático: myTraderGEO

### Epic 1: "Criar e Visualizar Estratégia Bull Call Spread"

**PE Checkpoint?**
- [ ] Queries >3 JOINs? → Não (apenas Strategy + StrategyLeg)
- [ ] Real-time calculations? → Não (cálculo on-demand, não crítico)
- [ ] >1000 registros? → Não (usuário tem <100 estratégias)
- [ ] Background jobs? → Não
- [ ] API externa? → Não
- [ ] Epic 4+? → Não (Epic 1)

**Decisão PE:** ❌ **NÃO executar** checkpoint

---

**SEC Checkpoint?**
- [x] Dados pessoais? → **Sim** (usuário cria estratégia, associada ao UserId)
- [ ] Dados sensíveis? → Não
- [ ] Dados financeiros? → Parcial (estratégia tem valor, mas não é transação)
- [x] Autenticação? → **Sim** (apenas usuário logado cria estratégia)
- [ ] API externa sensível? → Não
- [ ] Upload arquivos? → Não
- [ ] Epic 4+? → Não

**Decisão SEC:** ✅ **EXECUTAR** checkpoint (2 critérios atendidos: dados pessoais + autenticação)

**Ações SEC:**
- Validar que `Strategy` tem `UserId` (ownership)
- Validar que `CreateStrategyCommand` valida JWT token
- Validar que endpoint `/api/strategies` requer `[Authorize]`
- Validar que usuário A não pode modificar estratégia de usuário B

---

### Epic 3: "Calcular Greeks e P&L em Tempo Real"

**PE Checkpoint?**
- [ ] Queries >3 JOINs? → Não
- [x] **Real-time calculations?** → **Sim** (Greeks calculados em <200ms)
- [ ] >1000 registros? → Não
- [ ] Background jobs? → Não
- [x] **API externa?** → **Sim** (integração com B3 para market data)
- [ ] Epic 4+? → Não

**Decisão PE:** ✅ **EXECUTAR** checkpoint (2 critérios atendidos: real-time + API externa)

**Ações PE:**
- Validar que cálculo de Greeks é assíncrono
- Validar que market data API tem circuit breaker (Polly)
- Validar que market data é cacheada (Redis, TTL 5 min)
- Validar que queries de Strategy + MarketData usam `.Include()` para evitar N+1

---

**SEC Checkpoint?**
- [ ] Dados pessoais? → Não (apenas cálculos)
- [ ] Dados sensíveis? → Não
- [ ] Dados financeiros? → Sim (P&L é financeiro)
- [ ] Autenticação? → Sim (já validado em Epic 1)
- [x] **API externa sensível?** → **Sim** (B3 API envia dados de mercado proprietários)
- [ ] Upload arquivos? → Não
- [ ] Epic 4+? → Não

**Decisão SEC:** ✅ **EXECUTAR** checkpoint (2 critérios atendidos: financeiro + API externa)

**Ações SEC:**
- Validar que API B3 usa HTTPS
- Validar que API key B3 está em env var (não hardcoded)
- Validar que P&L só é visível para owner da estratégia
- Validar que logs não expõem dados de mercado sensíveis

---

## 📚 Referências

- **Workflow Guide:** [.agents/docs/00-Workflow-Guide.md](.agents/docs/00-Workflow-Guide.md)
- **Agents Overview:** [.agents/docs/01-Agents-Overview.md](.agents/docs/01-Agents-Overview.md)
- **PE Agent Spec:** [.agents/30-PE - Platform Engineer.xml](.agents/30-PE%20-%20Platform%20Engineer.xml)
- **SEC Agent Spec:** [.agents/35-SEC - Security Specialist.xml](.agents/35-SEC%20-%20Security%20Specialist.xml)
- **PE Checklist:** [.agents/workflow/02-checklists/PE-checklist.yml](.agents/workflow/02-checklists/PE-checklist.yml)
- **SEC Checklist:** [.agents/workflow/02-checklists/SEC-checklist.yml](.agents/workflow/02-checklists/SEC-checklist.yml)

---

**Versão:** 1.0
**Data:** 2025-10-10
**Autores:** Workflow Optimization Team
**Status:** Ativo
