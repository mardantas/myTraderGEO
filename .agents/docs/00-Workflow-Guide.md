# DDD Workflow Guide

**Objective:** Practical guide for Domain-Driven Design (DDD) development process for **small and medium projects**.

**Version:** 1.0

---

## 🎯 Overview

This workflow combines **strategic and tactical DDD** with **agile development** through **10 specialized agents** working iteratively to deliver incremental value in a **simple and pragmatic** way.

### Principles

1. **Epics by Functionality** - not by Bounded Context
2. **Fast iteration** - continuous feedback
3. **Minimum viable documentation** - only the essential
4. **Code as documentation** - clean code is the primary source
5. **Incremental deploy** - per complete epic

---

## 👥 Agents (10)

| Code | Agent | When Executes | Scope |
|------|-------|---------------|-------|
| SDA | Strategic Domain Analyst | 1x Discovery | Complete system |
| UXD | User Experience Designer | 1x Discovery + Per epic | Foundations + Epic wireframes |
| GM | GitHub Manager | 1x Discovery + Per epic | Setup + Issue per epic |
| PE | Platform Engineer | 1x Discovery | Basic environments (dev/stage/prod) |
| SEC | Security Specialist | 1x Discovery | Security baseline |
| QAE | Quality Assurance Engineer | 1x Discovery + Per epic | Test strategy + Quality gate |
| DE | Domain Engineer | Per epic | Tactical modeling per epic |
| DBA | Database Administrator | Per epic | Migrations and validation |
| SE | Software Engineer | Per epic | Backend implementation |
| FE | Frontend Engineer | Per epic | Frontend implementation |

See details in [01-Agents-Overview.md](01-Agents-Overview.md)

---

## 🏗️ Process Structure

### **Phase 1: Discovery (1x per project)**

Executed once at the start to establish **minimum** strategic foundation.

```
Day 1-2: SDA
  - Event Storming
  - Context Map
  - Ubiquitous Language
  - Prioritized epics (high-level)

Day 2-4: [UXD + GM + PE + SEC + QAE] (PARALLEL)

  UXD:
    - Design Foundations (colors, typography, base components)

  GM:
    - GitHub Setup (labels, PR template, branch protection)
    - Basic CI/CD (build + test)
    - GitHub Actions (staging/prod deploy)
    - ❌ DOES NOT create issues (epics not refined yet)

  PE:
    - Environments Setup (dev/stage/prod with SCRIPTS)
    - Docker Compose
    - Database setup
    - Deploy scripts (not IaC yet)

  SEC:
    - Security Baseline (basic threat model)
    - Essential security checklist
    - LGPD/compliance minimum

  QAE:
    - Test Strategy (tools, minimum coverage, criteria)
```

**Duration:** 3-4 days
**Deliverables:** 7 documents (SDA: 3, UXD: 1, GM: 1, PE: 1, SEC: 1, QAE: 1)

---

### **Phase 2: Iteration per Epic (N iterations)**

Executed for each priority epic, delivering complete end-to-end functionality.

```
┌──────────────────────────────────────────────────────┐
│  EPIC: [Functionality Name]                          │
│  Ex: "EPIC-01: Create and View Strategy"             │
└──────────────────────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Day 1-2: DE                           │
        │ DE-01-[EpicName]-Domain-Model.md      │
        │ - Detailed Aggregates                 │
        │ - Domain Events                       │
        │ - Use Cases (complete specs)          │
        │ - Repository interfaces               │
        │ - Business rules (invariants)         │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Day 2: GM                             │
        │ - Reads DE-01                         │
        │ - Creates detailed GitHub issue       │
        │ - Issue: use cases + acceptance       │
        │   criteria + tasks                    │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Day 2-3: DBA                          │
        │ DBA-01-[EpicName]-Migrations          │
        │ - Validates DE-01 schema              │
        │ - Creates migrations (EF Core)        │
        │ - Indexing strategy                   │
        └───────────────────────────────────────┘
                        ↓
        ┌────────────────────────────────────────┐
        │ Day 3-6: SE + UXD (PARALLEL)           │
        │                                        │
        │ SE:                      UXD:          │
        │ - Domain layer           - UXD-01      │
        │ - Application layer      - Wireframes  │
        │ - Infrastructure         - Specific    │
        │ - API layer              components    │
        │ - Unit tests (≥70%)      per epic      │
        └────────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Day 7-9: FE                           │
        │ - Implements UI (using UXD-01)        │
        │ - Integrates with SE APIs             │
        │ - Component tests                     │
        │ - State management                    │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Day 10: QAE (QUALITY GATE)            │
        │ - Integration tests (SE ↔ FE)         │
        │ - E2E tests (user journeys)           │
        │ - Regression tests (previous epics)   │
        │ - Smoke test                          │
        │                                       │
        │ ✅ Tests pass → RELEASE DEPLOY        │
        │ ❌ Tests fail → RETURN SE/FE          │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ DEPLOY                                │
        │ - PE: Deploy staging (GitHub Actions) │
        │ - QAE: Smoke test staging             │
        │ - PE: Deploy production               │
        │ - Monitoring                          │
        └───────────────────────────────────────┘
                        ↓
              [USER FEEDBACK]
                        ↓
             [Next Epic]
```

**Duration per epic:** 10 days (2 weeks)
**Deliverables:** 3 documents (DE-01, DBA-01, UXD-01) + code + tests + 1 GitHub issue

---

## 📐 Epics: By Functionality vs By BC

### ✅ CORRECT: Epics by Functionality (Cross-cutting)

**Example:**
```
Epic 1: "Create and View Bull Call Spread Strategy"
  → Crosses: Strategy Management BC + Market Data BC + Portfolio BC

Epic 2: "Calculate Greeks and P&L Real-Time"
  → Crosses: Strategy BC + Risk BC + Market Data BC

Epic 3: "Automatic Risk Alerts"
  → Crosses: Risk BC + Strategy BC
```

**Why?**
- Delivers complete business value
- User can test end-to-end functionality
- Real and useful feedback
- BC integration validated early

### ❌ AVOID: Epics by Bounded Context

```
Epic 1: "Strategy Management BC"
Epic 2: "Risk Management BC"
```

**Problem:** User cannot use anything until all BCs are ready.

---

## 💬 Feedback System

When an agent identifies a problem in another agent's deliverable, creates a formal FEEDBACK.

### Format

`FEEDBACK-[NNN]-[FROM]-[TO]-[short-title].md`

**Example:**
`FEEDBACK-003-DE-SDA-add-event-strategy-adjusted.md`

### How It Works

**1. Create Feedback (User → Agent):**
```
User: "DE, create feedback for SDA about missing 'Strategy Adjusted' event"

DE: [creates FEEDBACK-003-DE-SDA-add-event-strategy-adjusted.md]
    "✅ Feedback FEEDBACK-003 created for SDA"
```

**2. Process Feedback (User → Agent):**
```
User: "SDA, process FEEDBACK-003"

SDA: [reads feedback]
     [updates SDA-01-Event-Storming.md]
     [documents resolution in FEEDBACK-003]
     "✅ FEEDBACK-003 resolved. Event Storming updated."
```

### Feedback Types

- **Correction:** Deliverable has error requiring adjustment
- **Improvement:** Enhancement suggestion
- **Question:** Clarification needed
- **New Requirement:** Scope change

### Urgency

- 🔴 **High:** Blocks another agent
- 🟡 **Medium:** Important but doesn't block
- 🟢 **Low:** Nice to have

---

## 🎭 Agent Execution Modes

Agents support execution in two modes:

### Natural Mode (Primary)
```
"SDA, perform complete strategic modeling of the system"
"DE, model epic 'Create Strategy' in Strategy + Market Data BCs"
"SDA, update Context Map adding Notifications BC"
```

### Formal Mode (Optional, for automation)
```
@SDA: FULL_PROTOCOL
@DE: MODEL_EPIC epic="Create Strategy" bcs="Strategy,MarketData"
@SDA: UPDATE deliverable=SDA-02 feedback=FEEDBACK-003
```

**Recommendation:** Use natural mode day-to-day. Formal mode for scripts/automation.

---

## 📂 Folder Structure

```
[PROJECT-ROOT]/
├── .agents/                              # Agents and templates
│   ├── docs/                             # Workflow documentation
│   │   ├── 00-Workflow-Guide.md          # This document
│   │   ├── 01-Agents-Overview.md         # Agent details
│   │   ├── 02-Nomenclature-Standards.md  # Naming standards
│   │   ├── 03-Security-And-Platform-Strategy.md
│   │   ├── 04-DDD-Patterns-Reference.md
│   │   └── 05-API-Standards.md
│   ├── 10-SDA.xml ... 60-QAE.xml         # Agent specifications
│   ├── templates/                         # Templates for deliverables
│   └── workflow/                          # Checklists and validations
│
├── 00-doc-ddd/                            # DDD Documentation
│   ├── 00-feedback/                       # Agent feedbacks
│   ├── 01-inputs-raw/                     # Initial requirements
│   ├── 02-strategic-design/               # SDA deliverables
│   ├── 03-ux-design/                      # UXD deliverables
│   ├── 04-tactical-design/                # DE deliverables
│   ├── 05-database-design/                # DBA deliverables
│   ├── 06-quality-assurance/              # QAE deliverables
│   ├── 07-github-management/              # GM deliverables
│   ├── 08-platform-engineering/           # PE deliverables
│   └── 09-security/                       # SEC deliverables
│
├── 01-frontend/                           # Frontend code (FE)
├── 02-backend/                            # Backend code (SE)
├── 03-github-manager/                     # GM scripts (optional)
├── 04-database/                           # Migrations and scripts
│
└── workflow-config.json                   # Workflow configuration
```

---

## 🔄 Typical Workflow

### Project Start

```
1. SDA: Strategic modeling (BCs, Context Map, UL, Epics)
2. [UXD + GM + PE + SEC + QAE] parallel: Foundations
3. User: Prioritizes epics
4. Start Epic 1
```

### Epic 1 Development

```
5. DE: Model Epic 1 BCs (DE-01-Epic1-Domain-Model.md)
6. GM: Create detailed GitHub issue
7. DBA: Schema review (EF migrations), suggest indexes
8. SE: Implement domain + application + infrastructure + APIs
9. UXD: Create wireframes (parallel with SE)
10. FE: Implement Epic 1 UI (consuming SE APIs)
11. QAE: Test integration + E2E (QUALITY GATE)
12. PE: Deploy staging → production
13. User feedback
14. Adjustments if needed
```

### Epic 2, 3, N...

```
15. Repeat steps 5-14 for each epic
16. Feedback between agents when needed
17. Incremental deployment
```

---

## 📊 Success Metrics

**Discovery:**
- **Time:** 3-4 days
- **Docs:** 7 documents
- **Overhead:** ~25% of first epic

**Per Epic:**
- **Time:** 10 business days (2 weeks)
- **Docs:** 3 documents (DE-01, DBA-01, UXD-01)
- **Deploy frequency:** Each epic (2 weeks)
- **Feedback loop:** Immediate after deploy
- **Documentation overhead:** <20% of time

---

## 🗂️ Path Configuration

**IMPORTANT:** All workflow paths are defined in `workflow-config.json` (single source of truth).

### How It Works

**In agent XMLs:**
```xml
<deliverable path="SDA-01-Event-Storming.md" base-path="strategic-design">
<template base-path="templates">01-strategic-design/SDA-01.template.md</template>
<quality-checklist path="SDA-checklist.yml" base-path="checklists">
```

**System resolves via config.json:**
```json
"strategic-design": "00-doc-ddd/02-strategic-design/"
"templates": ".agents/templates/"
"checklists": ".agents/workflow/02-checklists/"
```

**Final path:** `00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md`

### Advantage
Change folder structure = update **only** `workflow-config.json` (zero changes in XMLs).

---

## 📚 References

- **Agents:** [01-Agents-Overview.md](01-Agents-Overview.md)
- **Nomenclature:** [02-Nomenclature-Standards.md](02-Nomenclature-Standards.md)
- **Security:** [03-Security-And-Platform-Strategy.md](03-Security-And-Platform-Strategy.md)
- **DDD Patterns:** [04-DDD-Patterns-Reference.md](04-DDD-Patterns-Reference.md)
- **API Standards:** [05-API-Standards.md](05-API-Standards.md)
- **Feedback Flow:** [../workflow/FEEDBACK-FLOW-GUIDE.md](../workflow/FEEDBACK-FLOW-GUIDE.md)
- **Think Mode:** [../workflow/THINK-MODE-GUIDE.md](../workflow/THINK-MODE-GUIDE.md)
- **Config Master:** `workflow-config.json`

---

**Version:** 1.0
**Date:** 2025-10-09
**Process:** 10 Agents DDD Workflow (Small/Medium Projects)
**Philosophy:** Simple, pragmatic, value-driven
