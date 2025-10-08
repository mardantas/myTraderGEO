# DDD Workflow Guide

**Objetivo:** Guia prático do processo de desenvolvimento usando Domain-Driven Design (DDD) para projetos production-ready (pequenos e médios).

---

## 🎯 Visão Geral

Este workflow combina **DDD estratégico e tático** com **desenvolvimento ágil** através de **9 agentes especializados** que trabalham de forma iterativa para entregar valor incremental com infraestrutura e segurança production-ready desde o dia 1.

### Princípios

1. **Épicos por Funcionalidade** - não por Bounded Context
2. **Iteração rápida** - feedback contínuo
3. **Documentação mínima viável** - apenas o essencial
4. **Código como documentação** - código limpo é a fonte primária
5. **Deploy incremental** - por épico completo

---

## 👥 Agentes (10)

| Sigla | Agente | Quando Executa | Escopo |
|-------|--------|----------------|--------|
| SDA | Strategic Domain Analyst | 1x início | Sistema completo |
| DE | Domain Engineer | 1x início + por épico | Sistema + Épico |
| UXD | User Experience Designer | 1x início + ajustes | Sistema completo |
| SE | Software Engineer | Por épico | Implementação backend |
| DBA | Database Administrator | Por épico | Validação/review |
| FE | Frontend Engineer | Por épico | Features transversais |
| QAE | Quality Assurance Engineer | Por épico | Testes integrados |
| GM | GitHub Manager | Setup + por épico | Rastreabilidade |
| PE | Platform Engineer | Setup + contínuo | Infraestrutura completa |
| SEC | Security Specialist | Setup + contínuo | Segurança transversal |

Ver detalhes em [01-Agents-Overview.md](01-Agents-Overview.md)

---

## 🏗️ Estrutura do Processo

### **Fase 1: Discovery (1x por projeto)**

Executado uma vez no início para estabelecer fundação estratégica.

```
SDA: Event Storming + Context Map + Ubiquitous Language
  ↓
DE: DE-00-System-Wide-Domain-Overview (Aggregates, VOs, Events - high-level)
  ↓
UXD: User Flows + Wireframes + Component Library (usando DE-00 para campos/validações)
  ↓
GM: GitHub Setup + Issues por Épico
  ↓
PE: Infrastructure Design + Observability Strategy + DR Plan (usando DE-00 para estimativas)
  ↓
SEC: Threat Model + Security Architecture (usando DE-00 para sensitive data)
```

**Duração:** 5-7 dias
**Deliverables:** 13-16 documentos base (+1 para DE-00)

---

### **Fase 2: Iteração por Épico (N iterações)**

Executado para cada épico prioritário, entregando funcionalidade completa end-to-end.

```
┌─────────────────────────────────────┐
│  ÉPICO: [Nome da Funcionalidade]    │
│  Ex: "Criar e Visualizar Estratégia"│
└─────────────────────────────────────┘
              ↓
    ┌─────────────────────────────────────┐
    │ DE: Modelo Tático Detalhado         │
    │ - Aggregates (invariantes)          │
    │ - Domain Events                     │
    │ - Use Cases (specs completas)       │
    │ - Repository interfaces             │
    │ DE-01-[EpicName]-Domain-Model.md    │
    └─────────────────────────────────────┘
              ↓
    ┌─────────────────────────────────────┐
    │ SE: Implementação Backend           │
    │ - Domain layer (DE-01 specs)        │
    │ - Application layer (Use Cases)     │
    │ - Infrastructure (Repos, EF)        │
    │ - API layer (REST, OpenAPI)         │
    │ - Unit tests (≥70%)                 │
    └─────────────────────────────────────┘
              ↓
    ┌─────────────────────────────────────┐
    │ DBA: Schema Review                  │
    │ - Valida EF migrations do SE        │
    │ - Indexing strategy                 │
    │ - Query optimization                │
    └─────────────────────────────────────┘
              ↓
    ┌─────────────────────────────────────┐
    │ FE: UI Components                   │
    │ - Telas do épico                    │
    │ - Integração com APIs do SE         │
    └─────────────────────────────────────┘
              ↓
    ┌─────────────────────────────────────┐
    │ QAE: Testes                         │
    │ - Integration tests (SE + FE)       │
    │ - E2E tests                         │
    └─────────────────────────────────────┘
              ↓
    ┌─────────────────────┐
    │ PE: Deploy Prod     │
    │ - Blue-Green deploy │
    │ - Health checks     │
    └─────────────────────┘
              ↓
    ┌─────────────────────┐
    │ SEC: Security Audit │
    │ - Vulnerability scan│
    │ - Pentest (periodic)│
    └─────────────────────┘
              ↓
    ┌─────────────────────┐
    │ SDA: UL Review      │
    │ - Revisar termos    │
    │ - Atualizar SDA-03  │
    └─────────────────────┘
              ↓
         [DEPLOY]
              ↓
      [USER FEEDBACK]
              ↓
     [Próximo Épico]
```

**Duração por épico:** 1-2 semanas
**Deliverables:** 6-9 documentos + código + infra updates

---

## 📐 Épicos: Por Funcionalidade vs Por BC

### ✅ CORRETO: Épicos por Funcionalidade (Transversal)

**Exemplo:**
```
Epic 1: "Criar e Visualizar Estratégia Bull Call Spread"
  → Atravessa: Strategy Management BC + Market Data BC + Portfolio BC

Epic 2: "Calcular Greeks e P&L em Tempo Real"
  → Atravessa: Strategy BC + Risk BC + Market Data BC

Epic 3: "Alertas de Risco Automáticos"
  → Atravessa: Risk BC + Strategy BC
```

**Por quê?**
- Entrega valor de negócio completo
- Usuário consegue testar funcionalidade end-to-end
- Feedback real e útil
- Integração entre BCs validada cedo

### ❌ EVITAR: Épicos por Bounded Context

```
Epic 1: "Strategy Management BC"
Epic 2: "Risk Management BC"
```

**Problema:** Usuário não consegue usar nada até todos BCs estarem prontos.

---

## 💬 Sistema de Feedback

Quando um agente identifica problema em deliverable de outro agente, cria um FEEDBACK formal.

### Formato

`FEEDBACK-[NNN]-[FROM]-[TO]-[titulo-curto].md`

**Exemplo:**
`FEEDBACK-003-DE-SDA-adicionar-evento-strategy-adjusted.md`

### Como Funciona

**1. Criar Feedback (Usuário → Agente):**
```
Usuário: "DE, crie feedback para SDA sobre evento faltante 'Strategy Adjusted'"

DE: [cria FEEDBACK-003-DE-SDA-adicionar-evento-strategy-adjusted.md]
    "✅ Feedback FEEDBACK-003 criado para SDA"
```

**2. Processar Feedback (Usuário → Agente):**
```
Usuário: "SDA, processe FEEDBACK-003"

SDA: [lê feedback]
     [atualiza SDA-01-Event-Storming.md]
     [documenta resolução em FEEDBACK-003]
     "✅ FEEDBACK-003 resolvido. Event Storming atualizado."
```

### Tipos de Feedback

- **Correção:** Deliverable tem erro que precisa ajuste
- **Melhoria:** Sugestão de enhancement
- **Dúvida:** Esclarecimento necessário
- **Novo Requisito:** Mudança de escopo

### Urgência

- 🔴 **Alta:** Bloqueia outro agente
- 🟡 **Média:** Importante mas não bloqueia
- 🟢 **Baixa:** Nice to have

---

## 🎭 Modos de Execução dos Agentes

Os agentes suportam execução em dois modos:

### Modo Natural (Principal)
```
"SDA, faça a modelagem estratégica completa do sistema"
"DE, modele épico 'Criar Estratégia' nos BCs Strategy + Market Data"
"SDA, atualize Context Map adicionando BC de Notificações"
```

### Modo Formal (Opcional, para automação)
```
@SDA: FULL_PROTOCOL
@DE: MODEL_EPIC epic="Criar Estratégia" bcs="Strategy,MarketData"
@SDA: UPDATE deliverable=SDA-02 feedback=FEEDBACK-003
```

**Recomendação:** Use modo natural no dia a dia. Modo formal para scripts/automação.

---

## 📂 Estrutura de Pastas

```
[PROJECT-ROOT]/
├── .agents/                              # Agentes e templates
│   ├── 00-Workflow-Guide.md             # Este documento
│   ├── 01-Agents-Overview.md            # Detalhes dos agentes
│   ├── 02-Nomenclature-Standards.md     # Padrões de nomenclatura
│   ├── 10-SDA.xml ... 70-GM.xml         # Especificações dos agentes
│   ├── templates/                        # Templates para deliverables
│   └── workflow/                         # Checklists e validações
│
├── 00-doc-ddd/                           # Documentação DDD
│   ├── 00-feedback/                      # Feedbacks entre agentes
│   ├── 01-inputs-raw/                    # Requisitos iniciais
│   ├── 02-strategic-design/              # SDA deliverables
│   ├── 03-ux-design/                     # UXD deliverables
│   ├── 04-tactical-design/               # DE deliverables
│   ├── 05-database-design/               # DBA deliverables
│   ├── 06-quality-assurance/             # QAE deliverables
│   └── 07-github-management/             # GM deliverables
│
├── 01-frontend/                          # Código frontend (FE)
├── 02-backend/                           # Código backend (DE)
├── 03-github-manager/                    # Scripts GM (opcional)
├── 04-database/                          # Migrations e scripts
│
└── .ddd-workflow-config.json             # Configuração do workflow
```

---

## 🔄 Workflow Típico

### Início do Projeto

```
1. SDA: Modelagem estratégica (BCs, Context Map, UL, Épicos)
2. DE: DE-00 System Overview (aggregates high-level)
3. UXD: User flows e wireframes (usando DE-00)
4. GM: Setup GitHub + issues por épico
5. PE: Infrastructure Design (usando DE-00)
6. SEC: Threat Model (usando DE-00)
7. Usuário: Prioriza épicos
8. Inicia Epic 1
```

### Desenvolvimento do Epic 1

```
9. DE: Modela BCs do Epic 1 (DE-01-Epic1-Domain-Model.md)
10. SE: Implementa domain + application + infrastructure + APIs
11. DBA: Revisa schema (EF migrations), sugere índices
12. FE: Implementa UI do Epic 1 (consumindo APIs do SE)
13. QAE: Testa integração + E2E
14. PE: Deploy automation para Epic 1
15. SEC: Vulnerability scan
16. SDA: Revisa UL (5-10min)
17. Deploy + Feedback do usuário
18. Ajustes se necessário
```

### Epic 2, 3, N...

```
13. Repete passos 6-12 para cada épico
14. Feedbacks entre agentes quando necessário
15. Incremental deployment
```

---

## 📊 Métricas de Sucesso

- **Tempo de Epic:** 1-2 semanas
- **Docs por Epic:** 3-5 documentos
- **Deploy frequency:** A cada epic (1-2 semanas)
- **Feedback loop:** Imediato após deploy
- **Overhead documental:** <30% do tempo

---

## 🗂️ Configuração de Paths

**IMPORTANTE:** Todas as paths do workflow são definidas em `workflow-config.json` (single source of truth).

### Como Funciona

**Nos XMLs dos agentes:**
```xml
<deliverable path="SDA-01-Event-Storming.md" base-path="strategic-design">
<template base-path="templates">01-strategic-design/SDA-01.template.md</template>
<quality-checklist path="SDA-checklist.yml" base-path="checklists">
```

**Sistema resolve via config.json:**
```json
"strategic-design": "00-doc-ddd/02-strategic-design/"
"templates": ".agents/templates/"
"checklists": ".agents/workflow/02-checklists/"
```

**Path final:** `00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md`

### Vantagem
Mudar estrutura de pastas = atualizar **apenas** `workflow-config.json` (zero mudanças nos XMLs).

---

## 📚 Referências

- **Agentes:** [01-Agents-Overview.md](01-Agents-Overview.md)
- **Nomenclatura:** [02-Nomenclature-Standards.md](02-Nomenclature-Standards.md)
- **Segurança:** [03-Security-And-Platform-Strategy.md](03-Security-And-Platform-Strategy.md)
- **Padrões DDD:** [04-DDD-Patterns-Reference.md](04-DDD-Patterns-Reference.md)
- **API Standards:** [05-API-Standards.md](05-API-Standards.md)
- **Config Master:** `workflow-config.json`

---

**Versão:** 2.1
**Data:** 2025-10-08
**Processo:** 10 Agentes DDD Workflow (Production-Ready)
