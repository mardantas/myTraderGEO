# DDD Workflow Guide

**Objetivo:** Guia prático do processo de desenvolvimento Domain-Driven Design (DDD) para projetos pequenos e médios.

---

## 🎯 Visão Geral

Este workflow combina **DDD estratégico e tático** com **desenvolvimento ágil** através de **10 agentes especializados** trabalhando iterativamente para entregar valor incremental de forma simples e pragmática.

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
| SDA | Strategic Domain Analyst | 1x Discovery | Sistema completo |
| UXD | User Experience Designer | 1x Discovery + Por épico | Fundamentos + Wireframes por épico |
| GM | GitHub Manager | 1x Discovery + Por épico | Setup + Issue por épico |
| PE | Platform Engineer | 1x Discovery | Ambientes básicos (dev/stage/prod) |
| SEC | Security Specialist | 1x Discovery | Baseline de segurança |
| QAE | Quality Assurance Engineer | 1x Discovery + Por épico | Estratégia de testes + Quality gate |
| DE | Domain Engineer | Por épico | Modelagem tática por épico |
| DBA | Database Administrator | Por épico | Migrations e validação |
| SE | Software Engineer | Por épico | Implementação backend |
| FE | Frontend Engineer | Por épico | Implementação frontend |

Ver detalhes em [01-Agents-Overview.md](01-Agents-Overview.md)

---

## 🏗️ Estrutura do Processo

### **Fase 1: Discovery (1x por projeto)**

Executada uma vez no início para estabelecer a fundação estratégica **mínima**.

```
Dia 1-2: SDA
  - Event Storming
  - Context Map
  - Linguagem Ubíqua
  - Épicos priorizados (alto nível)

Dia 2-4: [UXD + GM + PE + SEC + QAE] (PARALELO)

  UXD:
    - Fundamentos de Design (cores, tipografia, componentes base)

  GM:
    - Setup GitHub (labels, template PR, proteção de branch)
    - CI/CD básico (build + test)
    - GitHub Actions (deploy staging/prod)
    - ❌ NÃO cria issues (épicos ainda não refinados)

  PE:
    - Setup de Ambientes (dev/stage/prod com SCRIPTS)
    - Docker Compose
    - Setup de banco de dados
    - Scripts de deploy (ainda não IaC)

  SEC:
    - Baseline de Segurança (threat model básico)
    - Checklist essencial de segurança
    - LGPD/compliance mínimo

  QAE:
    - Estratégia de Testes (ferramentas, cobertura mínima, critérios)
```

**Duração:** 3-4 dias
**Deliverables:** 7 documentos (SDA: 3, UXD: 1, GM: 1, PE: 1, SEC: 1, QAE: 1)

---

### **Fase 2: Iteração por Épico (N iterações)**

Executada para cada épico prioritário, entregando funcionalidade completa ponta-a-ponta.

```
┌──────────────────────────────────────────────────────┐
│  ÉPICO: [Nome da Funcionalidade]                     │
│  Ex: "EPIC-01: Criar e Visualizar Estratégia"        │
└──────────────────────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 1-2: DE                           │
        │ DE-01-[NomeEpico]-Domain-Model.md     │
        │ - Aggregates detalhados               │
        │ - Domain Events                       │
        │ - Use Cases (specs completas)         │
        │ - Interfaces de repositório           │
        │ - Regras de negócio (invariantes)     │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 2: GM                             │
        │ - Lê DE-01                            │
        │ - Cria issue detalhada no GitHub      │
        │ - Issue: use cases + critérios de     │
        │   aceitação + tarefas                 │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 2-3: DBA                          │
        │ DBA-01-[NomeEpico]-Migrations         │
        │ - Valida schema do DE-01              │
        │ - Cria migrations (EF Core)           │
        │ - Estratégia de indexação             │
        └───────────────────────────────────────┘
                        ↓
        ┌────────────────────────────────────────┐
        │ Dia 3-6: SE + UXD (PARALELO)           │
        │                                        │
        │ SE:                      UXD:          │
        │ - Camada de domínio      - UXD-01      │
        │ - Camada de aplicação    - Wireframes  │
        │ - Infraestrutura         - Componentes │
        │ - Camada de API          específicos   │
        │ - Testes unitários (≥70%) por épico   │
        └────────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 7-9: FE                           │
        │ - Implementa UI (usando UXD-01)       │
        │ - Integra com APIs do SE              │
        │ - Testes de componentes               │
        │ - Gerenciamento de estado             │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 9 (OPCIONAL): PE + SEC Checkpoints│
        │ - PE: Quick performance review (15min)│
        │   • N+1 queries? Missing indexes?     │
        │   • Async/await correct?              │
        │ - SEC: Quick security review (15min)  │
        │   • OWASP Top 3? Authorization?       │
        │   • Input validation? Secrets safe?   │
        │                                       │
        │ ⚠️ QUANDO EXECUTAR (ver Decision      │
        │    Matrix para critérios completos):  │
        │ PE: Queries >3 JOINs, real-time       │
        │     calculations, Epic 4+, API extern │
        │ SEC: PII/financial data, auth logic,  │
        │      Epic 4+, upload arquivos         │
        │                                       │
        │ 📋 Ref: 07-PE-SEC-Checkpoint-Decision-│
        │         Matrix.md                     │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 10: QAE (QUALITY GATE)            │
        │ - Testes de integração (SE ↔ FE)      │
        │ - Testes E2E (jornadas do usuário)    │
        │ - Testes de regressão (épicos antigos)│
        │ - Smoke test                          │
        │                                       │
        │ ✅ Testes passam → DEPLOY RELEASE     │
        │ ❌ Testes falham → RETORNA SE/FE      │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ DEPLOY                                │
        │ - PE: Deploy staging (GitHub Actions) │
        │ - QAE: Smoke test staging             │
        │ - PE: Deploy production               │
        │ - Monitoramento                       │
        └───────────────────────────────────────┘
                        ↓
              [FEEDBACK DO USUÁRIO]
                        ↓
             [Próximo Épico]
```

**Duração por épico:** 10 dias (2 semanas)
**Deliverables:** 3 documentos (DE-01, DBA-01, UXD-01) + código + testes + 1 issue GitHub

---

## 📐 Épicos: Por Funcionalidade vs Por BC

### ✅ CORRETO: Épicos por Funcionalidade (Transversal)

**Exemplo:**
```
Épico 1: "Criar e Visualizar Estratégia Bull Call Spread"
  → Atravessa: BC Gestão de Estratégias + BC Dados de Mercado + BC Portfólio

Épico 2: "Calcular Greeks e P&L em Tempo Real"
  → Atravessa: BC Estratégia + BC Risco + BC Dados de Mercado

Épico 3: "Alertas Automáticos de Risco"
  → Atravessa: BC Risco + BC Estratégia
```

**Por quê?**
- Entrega valor de negócio completo
- Usuário pode testar funcionalidade ponta-a-ponta
- Feedback real e útil
- Integração de BCs validada cedo

### ❌ EVITAR: Épicos por Bounded Context

```
Épico 1: "BC Gestão de Estratégias"
Épico 2: "BC Gestão de Risco"
```

**Problema:** Usuário não consegue usar nada até que todos os BCs estejam prontos.

---

## 💬 Sistema de Feedback

Quando um agente identifica um problema no entregável de outro agente, cria um FEEDBACK formal.

### Formato

`FEEDBACK-[NNN]-[DE]-[PARA]-[titulo-curto].md`

**Exemplo:**
`FEEDBACK-003-DE-SDA-adicionar-evento-strategy-adjusted.md`

### Como Funciona

**1. Criar Feedback (Usuário → Agente):**
```
Usuário: "DE, crie feedback para SDA sobre evento 'Strategy Adjusted' faltante"

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

- **Correção:** Entregável tem erro que requer ajuste
- **Melhoria:** Sugestão de aprimoramento
- **Pergunta:** Esclarecimento necessário
- **Novo Requisito:** Mudança de escopo

### Urgência

- 🔴 **Alta:** Bloqueia outro agente
- 🟡 **Média:** Importante mas não bloqueia
- 🟢 **Baixa:** Desejável

---

## 🎭 Modos de Execução dos Agentes

Agentes suportam execução em dois modos:

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
[RAIZ-PROJETO]/
├── .agents/                              # Agentes e templates
│   ├── docs/                             # Documentação do workflow
│   │   ├── 00-Workflow-Guide.md          # Este documento
│   │   ├── 01-Agents-Overview.md         # Detalhes dos agentes
│   │   ├── 02-Nomenclature-Standards.md  # Padrões de nomenclatura
│   │   ├── 03-Security-And-Platform-Strategy.md
│   │   ├── 04-DDD-Patterns-Reference.md
│   │   └── 05-API-Standards.md
│   ├── 10-SDA.xml ... 60-QAE.xml         # Especificações dos agentes
│   ├── templates/                         # Templates para deliverables
│   └── workflow/                          # Checklists e validações
│
├── 00-doc-ddd/                            # Documentação DDD
│   ├── 00-feedback/                       # Feedbacks entre agentes
│   ├── 01-inputs-raw/                     # Requisitos iniciais
│   ├── 02-strategic-design/               # Deliverables SDA
│   ├── 03-ux-design/                      # Deliverables UXD
│   ├── 04-tactical-design/                # Deliverables DE
│   ├── 05-database-design/                # Deliverables DBA
│   ├── 06-quality-assurance/              # Deliverables QAE
│   ├── 07-github-management/              # Deliverables GM
│   ├── 08-platform-engineering/           # Deliverables PE
│   └── 09-security/                       # Deliverables SEC
│
├── 01-frontend/                           # Código frontend (FE)
├── 02-backend/                            # Código backend (SE)
├── 03-github-manager/                     # Scripts GM (opcional)
├── 04-database/                           # Migrations e scripts
│
└── workflow-config.json                   # Configuração do workflow
```

---

## 🔄 Workflow Típico

### Início do Projeto

```
1. SDA: Modelagem estratégica (BCs, Context Map, UL, Épicos)
2. [UXD + GM + PE + SEC + QAE] paralelo: Fundamentos
3. Usuário: Prioriza épicos
4. Iniciar Épico 1
```

### Desenvolvimento do Épico 1

```
5. DE: Modelar BCs do Épico 1 (DE-01-Epic1-Domain-Model.md)
6. GM: Criar issue detalhada no GitHub
7. DBA: Revisar schema (migrations EF), sugerir índices
8. SE: Implementar domain + application + infrastructure + APIs
9. UXD: Criar wireframes (paralelo com SE)
10. FE: Implementar UI do Épico 1 (consumindo APIs do SE)
11. QAE: Testar integração + E2E (QUALITY GATE)
12. PE: Deploy staging → production
13. Feedback do usuário
14. Ajustes se necessário
```

### Épicos 2, 3, N...

```
15. Repetir passos 5-14 para cada épico
16. Feedback entre agentes quando necessário
17. Deploy incremental
```

---

## 📊 Métricas de Sucesso

**Discovery:**
- **Tempo:** 3-4 dias
- **Docs:** 7 documentos
- **Overhead:** ~25% do primeiro épico

**Por Épico:**
- **Tempo:** 10 dias úteis (2 semanas)
- **Docs:** 3 documentos (DE-01, DBA-01, UXD-01)
- **Frequência de deploy:** Cada épico (2 semanas)
- **Loop de feedback:** Imediato após deploy
- **Overhead de documentação:** <20% do tempo

---

## 🗂️ Configuração de Caminhos

**IMPORTANTE:** Todos os caminhos do workflow são definidos em `workflow-config.json` (única fonte da verdade).

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

**Caminho final:** `00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md`

### Vantagem
Mudar estrutura de pastas = atualizar **apenas** `workflow-config.json` (zero mudanças nos XMLs).

---

## 📚 Referências

- **Agentes:** [01-Agents-Overview.md](01-Agents-Overview.md)
- **Nomenclatura:** [02-Nomenclature-Standards.md](02-Nomenclature-Standards.md)
- **Segurança:** [03-Security-And-Platform-Strategy.md](03-Security-And-Platform-Strategy.md)
- **Padrões DDD:** [04-DDD-Patterns-Reference.md](04-DDD-Patterns-Reference.md)
- **Padrões de API:** [05-API-Standards.md](05-API-Standards.md)
- **PE/SEC Checkpoints:** [07-PE-SEC-Checkpoint-Decision-Matrix.md](07-PE-SEC-Checkpoint-Decision-Matrix.md)
- **Fluxo de Feedback:** [../workflow/FEEDBACK-FLOW-GUIDE.md](../workflow/FEEDBACK-FLOW-GUIDE.md)
- **Think Mode:** [../workflow/THINK-MODE-GUIDE.md](../workflow/THINK-MODE-GUIDE.md)
- **Config Master:** `workflow-config.json`

---

**Versão:** 1.0
**Data:** 2025-10-09
**Processo:** Workflow DDD com 10 Agentes (Projetos Pequenos/Médios)
