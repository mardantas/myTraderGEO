# CHANGELOG - Workflow v3.0 (Simplificado)

**Data:** 2025-10-08
**Versão:** 3.0
**Descrição:** Workflow DDD simplificado para projetos pequenos e médios

---

## 🎯 OBJETIVO DA VERSÃO 3.0

Simplificar o workflow DDD para projetos **pequenos e médios**, reduzindo:
- Overhead de documentação (de 13-16 docs para 7 docs na Discovery)
- Tempo de Discovery (de 5-7 dias para 3-4 dias)
- Complexidade de infraestrutura (scripts básicos em vez de IaC completo)
- Modelagem especulativa (removido DE-00 System Overview)

---

## 📊 COMPARAÇÃO v2.1 → v3.0

| Aspecto | v2.1 (Enterprise) | v3.0 (Simplificado) |
|---------|-------------------|---------------------|
| **Discovery** | 5-7 dias | **3-4 dias** (-40%) |
| **Docs Discovery** | 13-16 documentos | **7 documentos** (-50%) |
| **Épico** | 1-2 semanas | **10 dias (2 semanas)** |
| **Docs por Épico** | 6-9 documentos | **3 documentos** (-60%) |
| **Overhead Documental** | <30% | **<20%** |
| **Foco** | Enterprise (production-ready desde dia 1) | **Small/Medium** (pragmático) |

---

## 🔄 MUDANÇAS PRINCIPAIS

### **DISCOVERY (3-4 dias)**

#### ❌ REMOVIDO:
1. **DE-00 System-Wide Domain Overview**
   - Motivo: Modelagem especulativa (Big Design Up Front)
   - UXD, PE, SEC trabalham com outputs do SDA (BCs, Context Map, Ubiquitous Language)

2. **GM cria issues por épico na Discovery**
   - Motivo: Épicos não estão refinados ainda (falta detalhamento tático do DE)
   - GM cria issues **DEPOIS** do DE-01 (por épico)

3. **PE Infrastructure Design completo (4 docs)**
   - Removido: PE-01 (IaC Terraform), PE-02 (Observability), PE-03 (DR Plan), PE-04 (Blue-Green)
   - Substituído por: PE-00-Environments-Setup.md (apenas Docker Compose + deploy scripts)

4. **SEC deliverables completos (5 docs)**
   - Removido: STRIDE completo, Pentest, Incident Response, Security Monitoring
   - Substituído por: SEC-00-Security-Baseline.md (essencial: OWASP Top 3, LGPD mínimo)

#### ✅ ADICIONADO:
1. **QAE-00-Test-Strategy** na Discovery
   - QAE define estratégia de testes 1x no início (ferramentas, coverage, critérios)

2. **Paralelização no Discovery**
   - SDA (Dia 1-2) → [UXD + GM + PE + SEC + QAE em PARALELO] (Dia 2-4)

#### ✅ MODIFICADO:
1. **UXD na Discovery**
   - Antes: User Flows + Wireframes + Component Library completos
   - Agora: UXD-00-Design-Foundations apenas (cores, tipografia, componentes base)

---

### **ITERAÇÃO POR ÉPICO (10 dias)**

#### ❌ REMOVIDO:
1. **DE-00 na Iteration**
   - DE executa APENAS DE-01 por épico (sem overview do sistema)

#### ✅ MODIFICADO:
1. **Ordem da Iteração**
   - **Antes (v2.1):** DE → SE → DBA → FE → QAE
   - **Agora (v3.0):** **DE → GM → DBA → [SE + UXD paralelo] → FE → QAE**

2. **GM executa POR ÉPICO (Dia 2)**
   - GM lê DE-01 e cria issue detalhada no GitHub
   - Issue contém: use cases, acceptance criteria, tasks

3. **SE + UXD em PARALELO (Dia 3-6)**
   - SE implementa backend ENQUANTO UXD cria wireframes do épico
   - FE recebe wireframes prontos (UXD-01) no Dia 7

4. **UXD por Épico**
   - UXD-01-[EpicName]-Wireframes.md criado para cada épico
   - Wireframes específicos (não apenas "ajustes")

5. **QAE como QUALITY GATE (Dia 10)**
   - QAE no FINAL do épico (não durante)
   - Executa: Integration tests + E2E tests + Regression tests + Smoke test
   - **✅ Testes passam → LIBERA deploy**
   - **❌ Testes falham → BLOQUEIA deploy** (volta para SE/FE)

---

## 📋 DELIVERABLES v3.0

### **Discovery (7 documentos):**
1. **SDA-01-Event-Storming.md** (Strategic Design)
2. **SDA-02-Context-Map.md** (Strategic Design)
3. **SDA-03-Ubiquitous-Language.md** (Strategic Design)
4. **UXD-00-Design-Foundations.md** (UX Design)
5. **GM-00-GitHub-Setup.md** (GitHub Management)
6. **PE-00-Environments-Setup.md** (Platform Engineering)
7. **SEC-00-Security-Baseline.md** (Security)
8. **QAE-00-Test-Strategy.md** (Quality Assurance)

**Total:** 8 documentos (7 primários + 1 QAE)

### **Por Épico (3 documentos + código):**
1. **DE-01-[EpicName]-Domain-Model.md** (Tactical Design)
2. **DBA-01-[EpicName]-Migrations** (Database)
3. **UXD-01-[EpicName]-Wireframes.md** (UX Design)
4. **Código:** Backend + Frontend + Testes
5. **GitHub Issue** (criada pelo GM)

**Total:** 3 docs + código + 1 issue

---

## 🔧 AGENTS MODIFICADOS

### **DE (Domain Engineer):**
- ❌ Removido: DE-00 System Overview
- ✅ Executa APENAS: DE-01-[EpicName]-Domain-Model (por épico)
- ✅ Phase: `iteration` (sem discovery)

### **GM (GitHub Manager):**
- ✅ Discovery: GitHub setup (labels, CI/CD, templates) - **NÃO cria issues**
- ✅ Iteração: Cria issue DEPOIS do DE-01 (Dia 2 do épico)

### **PE (Platform Engineer):**
- ❌ Removido: IaC (Terraform), Observability completa, DR Plan, Blue-Green
- ✅ Discovery: PE-00-Environments-Setup (Docker Compose + deploy scripts)
- ✅ Phase: `discovery` apenas

### **SEC (Security Specialist):**
- ❌ Removido: STRIDE completo, Pentest, Incident Response, SIEM
- ✅ Discovery: SEC-00-Security-Baseline (OWASP Top 3, LGPD mínimo)
- ✅ Phase: `discovery` apenas

### **UXD (User Experience Designer):**
- ✅ Discovery: UXD-00-Design-Foundations (cores, tipografia, base components)
- ✅ Iteração: UXD-01-[EpicName]-Wireframes (wireframes específicos, paralelo com SE)
- ✅ Phase: `discovery-and-iteration`

### **QAE (Quality Assurance Engineer):**
- ✅ Discovery: QAE-00-Test-Strategy (ferramentas, coverage, critérios)
- ✅ Iteração: Testes no FINAL (Dia 10) como **QUALITY GATE**
- ✅ Aprova ou BLOQUEIA deploy
- ✅ Phase: `discovery-and-iteration`

---

## 🎯 WORKFLOW PHASES v3.0

### **Phase 1: Discovery (3-4 dias)**

**Agentes:** SDA, UXD, GM, PE, SEC, QAE

**Sequência:**
```
Dia 1-2: SDA (Event Storming, Context Map, UL, Épicos priorizados)
         ↓
Dia 2-4: [UXD + GM + PE + SEC + QAE] em PARALELO
```

**Output:**
- 3 BCs mínimo
- Context Map
- Épicos priorizados (high-level)
- Design Foundations
- GitHub setup (sem issues)
- Environments (dev/stage/prod com scripts)
- Security Baseline
- Test Strategy

**Deliverables:** 7-8 documentos

---

### **Phase 2: Iteração (10 dias por épico)**

**Agentes:** DE, GM, DBA, SE, UXD, FE, QAE

**Sequência:**
```
Dia 1-2: DE (DE-01 Domain Model)
         ↓
Dia 2:   GM (cria issue no GitHub baseado no DE-01)
         ↓
Dia 2-3: DBA (migrations, validação de schema)
         ↓
Dia 3-6: [SE + UXD em PARALELO]
         SE: Backend (domain + app + infra + API + unit tests)
         UXD: Wireframes específicos do épico
         ↓
Dia 7-9: FE (implementa UI usando UXD-01)
         ↓
Dia 10:  QAE (QUALITY GATE)
         - Integration tests
         - E2E tests
         - Regression tests
         - Smoke test
         ✅ Passa → DEPLOY
         ❌ Falha → BLOQUEIA
```

**Output:**
- Domain model detalhado
- GitHub issue
- Migrations
- Backend code
- Wireframes
- Frontend code
- Testes (integration + E2E + regression)

**Deliverables:** 3 docs + código + 1 issue

---

## ✅ BENEFÍCIOS v3.0

1. **Discovery 40% mais rápida** (3-4 dias vs 5-7 dias)
2. **50% menos documentação** na Discovery (7 docs vs 13-16)
3. **Elimina modelagem especulativa** (sem DE-00)
4. **Paralelização SE + UXD** (FE recebe wireframes no tempo certo)
5. **QAE como quality gate** (deploy seguro, testes obrigatórios)
6. **GM cria issues quando épico está refinado** (issues precisas)
7. **Infraestrutura pragmática** (scripts, não IaC complexo)
8. **Segurança essencial** (baseline, sem overhead enterprise)
9. **Overhead documental <20%** (vs <30% na v2.1)
10. **Foco em small/medium projects** (não enterprise)

---

## 🚀 PRÓXIMOS PASSOS

1. ✅ **workflow-config.json** atualizado
2. ✅ **00-Workflow-Guide.md** atualizado
3. ✅ **XMLs dos agentes** atualizados (DE, GM, PE, SEC, UXD, QAE)
4. ⏳ **Checklists** simplificados (PE, SEC)
5. ⏳ **01-Agents-Overview.md** atualizado
6. ⏳ **Templates** criados/atualizados (PE-00, SEC-00, UXD-00, UXD-01, QAE-00)

---

## 📝 NOTAS DE MIGRAÇÃO

### **Se você está vindo da v2.1:**

1. **DE-00 foi removido** - não execute mais DE na Discovery
2. **GM não cria issues na Discovery** - cria DEPOIS do DE-01
3. **PE cria apenas PE-00** - não crie PE-01/02/03/04
4. **SEC cria apenas SEC-00** - não crie SEC-01/02/03/04/05
5. **UXD executa 2x** - Discovery (UXD-00) + Por Épico (UXD-01)
6. **QAE executa 2x** - Discovery (QAE-00) + Por Épico (quality gate)

---

**Versão:** 3.0
**Status:** Implementado
**Data:** 2025-10-08
**Autor:** DDD Workflow Team
