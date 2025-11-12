# Agents Overview

**Objective:** Detailed description of the 10 specialized agents executing the simplified DDD workflow for small/medium projects.  

**Version:** 1.0  
**Date:** 2025-10-09  

---

## 📊 Executive Summary - Discovery Execution Order

| Order | # | Code | Agent | Scope | Phase | Deliverables | Dependencies |
|-------|---|------|-------|-------|-------|--------------|--------------|
| **1** | 10 | SDA | Strategic Domain Analyst | Complete system | Discovery (Day 1-2) | 3 docs | - |
| **2** | 20 | UXD | User Experience Designer | System + Per epic | Discovery (Day 2-3) + Iteration | 1 doc + 1/epic | SDA |
| **3** | 30 | PE | Platform Engineer | Basic setup | Discovery (Day 2-3) | 1 doc + scripts | SDA |
| **4** | 60 | QAE | Quality Assurance Engineer | Strategy + Per epic | Discovery (Day 3-4) + Iteration | 1 doc + tests | SDA, **PE (stack)** |
| **5** | 35 | SEC | Security Specialist | Baseline | Discovery (Day 3-4) | 1 doc | SDA, **PE (stack)** |
| **6** | 25 | GM | GitHub Manager | Setup + Per epic | Discovery (Day 3-4) + Iteration | 1 doc + issues | SDA, **PE (stack)** |
| **7** | 15 | DE | Domain Engineer | Per epic ONLY | Iteration | 1 doc/epic | SDA |
| **8** | 50 | DBA | Database Administrator | Per epic | Iteration | Migrations | DE, PE |
| **9** | 45 | SE | Software Engineer | Per epic | Iteration | Code | DE, DBA |
| **10** | 55 | FE | Frontend Engineer | Per epic | Iteration | Code | SE, UXD |

**⚠️ Critical:** PE must execute BEFORE QAE, SEC, and GM because it defines the tech stack (Backend, Frontend, Database) that these agents need to choose compatible tools.  

---

## 10 - SDA (Strategic Domain Analyst)

### Objective
Discover and map the complete business domain - bounded contexts, strategic epics, ubiquitous language.

### Responsibilities
**Discovery (1x at project start):** Event Storming (domain event discovery), Bounded Contexts identification, Context Map (relationships), Ubiquitous Language (glossary), epic prioritization by business value.  

### When Executes
**1x at project start** - discovery phase (analyzes entire business domain)

### Key Deliverables
- **SDA-01-Event-Storming.md** - Domain events per BC  
- **SDA-02-Context-Map.md** - BCs and relationships  
- **SDA-03-Ubiquitous-Language.md** - Glossary  

### Example Invocations
```
# Discovery
"SDA, faça a modelagem estratégica completa do sistema myTrader"
→ Executes full Discovery: Event Storming + Context Map + Ubiquitous Language
→ Deliverables: SDA-01, SDA-02, SDA-03

"SDA, identifique Bounded Contexts e eventos de domínio para sistema de opções financeiras"
→ Focuses on BC identification first

# Review & Updates
"SDA, revise Event Storming verificando completude dos eventos por BC"
→ Validates all BCs have domain events, checks naming consistency

"SDA, processe FEEDBACK-001 sobre evento StrategyValidated faltante"
→ Reviews feedback, adds event to SDA-01

"SDA, adicione BC de Notificações ao Context Map como Upstream-Downstream com BC Strategy"
→ Updates SDA-02-Context-Map.md with new BC and relationship
```

**Note:** SDA executes ONLY in Discovery. For epic-specific changes, use DE.  

### Think Mode Policy
🔴 **MANDATORY** - Discovery involves 3 deliverables (Event Storming, Context Map, Ubiquitous Language)

### Dependencies
**Depends on:** None (first agent) | **Blocks:** All other agents (provides BCs, Context Map, UL)  

### Specification
[10-SDA - Strategic Domain Analyst.xml](../10-SDA%20-%20Strategic%20Domain%20Analyst.xml)

---

## 20 - UXD (User Experience Designer)

### Objective
Design user experience: foundations in Discovery + specific wireframes per epic.

### Responsibilities
**Discovery (1x):** Design foundations (colors, typography, base components) independent of tech stack.  
**Per Epic (Nx):** Epic-specific wireframes with detailed components, work in PARALLEL with SE (Days 3-6), FE receives ready wireframes on Day 7.  

### When Executes
**Discovery:** UXD-00-Design-Foundations (1x)  
**Iteration:** UXD-01-[EpicName]-Wireframes (per epic, parallel with SE)  

### Key Deliverables
- **UXD-00-Design-Foundations.md** - Colors, typography, base components (1x)  
- **UXD-01-[EpicName]-Wireframes.md** - Epic-specific wireframes (per epic)  

### Example Invocations
```
# Discovery (1x)
"UXD, crie design foundations (cores, tipografia, componentes base)"
→ Creates UXD-00 independent of tech stack, consumed by FE later

# Per Epic
"UXD, crie wireframes para épico 'Criar Estratégia Bull Call Spread'"
→ Creates UXD-01-EPIC-01-Strategy-Wireframes.md with modal, form, leg management

"UXD, desenhe user flow e wireframes para Dashboard de P&L em tempo real"
→ Epic 2: Real-time Greeks calculation, data visualization, responsiveness

# Review & Updates
"UXD, revise wireframes do épico 1 verificando consistência com Design Foundations"
→ Checks colors, typography, component usage, ensures FE has clear guide

"UXD, processe FEEDBACK-005 do FE sobre comportamento do botão Adicionar Perna"
→ Clarifies ambiguous spec, updates UXD-01 with interaction states
```

### Think Mode Policy
🟡 **RECOMMENDED** for multiple flows/wireframes (>3 screens)

### Dependencies
**Depends on:** SDA (BCs for scope) | **Consumed by:** FE (wireframes for implementation)  

### Specification
[20-UXD - User Experience Designer.xml](../20-UXD%20-%20User%20Experience%20Designer.xml)

---

## 30 - PE (Platform Engineer)

### Objective
Define tech stack (Backend, Frontend, Database) and configure basic environments (dev/staging/prod) with deploy scripts - pragmatic setup for small/medium projects.

### Responsibilities
**Discovery (Day 2-3 - BLOCKS GM/SEC/QAE):**
Define tech stack, Docker Compose environments (dev/staging/prod with Traefik), server setup docs (OS, Docker, firewall, users, SSH), scaling strategy, deploy scripts with remote deployment, environment variables (.env files), logging, health checks.

### When Executes
**Discovery:** PE platform engineering documentation (BEFORE GM, SEC, QAE)  
**Per Epic (OPTIONAL):** Performance checkpoint (15-30 min) - See [07-PE-SEC-Checkpoint-Guide.md](07-PE-SEC-Checkpoint-Guide.md) for criteria  

### Key Deliverables
- **PE-00-Environments-Setup.md** - Complete infrastructure guide: tech stack + environments + server setup (automated + manual) + Traefik + scaling strategy
- **Docker Compose** files (dev, staging, prod with Traefik)
- **Deploy scripts** (deploy.sh) with SSH remote deployment
- **Server setup scripts** (server-setup.sh + 9 step scripts) - NEW: Automated server hardening
- **PE-EPIC-[N]-Performance-Checkpoint.md** (optional per epic when performance-critical)

### Example Invocations
```
# Discovery (MANDATORY)
"PE, configure ambientes (dev/stage/prod) com Docker Compose e defina tech stack"
→ Creates PE-00-Environments-Setup.md with Backend + Frontend + Database stack definition
→ Docker Compose, Traefik, .env strategy, deploy.sh with remote deployment

"PE, documente setup do servidor (Debian 12, Docker, firewall, usuários SSH)"
→ Server hardening: 9 steps (hostname, system-update, docker, firewall, security, user, ssh-keys, directories, env-file, verification)
→ Automated setup: server-setup.sh master script (orchestrates all 9 steps)
→ Manual alternative: Step-by-step guide available in PE-00

"PE, gere scripts automatizados de server setup (9 hardening steps)"
→ Creates 05-infra/scripts/server-setup.sh (master orchestrator with interactive prompts)
→ Creates 05-infra/scripts/setup/*.sh (9 individual step scripts - idempotent and reusable)
→ Documents automated vs manual setup approaches in PE-00
→ Scripts log execution to /var/log/[project]-server-setup.log
→ Usage: sudo bash server-setup.sh --environment staging

# Optional per-epic performance checkpoint
"PE, checkpoint de performance para Epic 3 (Calculate Greeks - real-time)"
→ Quick 15-30 min review: N+1 queries, async/await, caching, resources

# Updates
"PE, adicione health check remoto HTTPS ao deploy.sh"
→ Updates deploy.sh with remote_health_check() function

"PE, processe FEEDBACK-004 sobre evolução da especificação PE"
→ Aligns PE-00-Environments-Setup.md with updated agent spec (Traefik staging CA, server docs)
```

### Think Mode Policy
🔴 **MANDATORY** - Infrastructure setup involves multiple files/configs (Docker Compose, deploy scripts, PE-00 comprehensive doc)

### Dependencies
**Depends on:** SDA (BCs estimate infrastructure) | **Blocks:** GM, QAE, SEC (wait for tech stack)  

### Specification
[30-PE - Platform Engineer.xml](../30-PE%20-%20Platform%20Engineer.xml)

---

## 60 - QAE (Quality Assurance Engineer)

### Objective
Ensure quality as **QUALITY GATE** at end of each epic - tests pass → approve deploy, tests fail → block deploy.

### Responsibilities
**Discovery (AFTER PE):** Test strategy (QAE-00), tools selection based on PE stack (xUnit vs Jest, Playwright vs Cypress), coverage criteria (≥70% domain, ≥60% application).  
**Per Epic (Day 10 - QUALITY GATE):** Integration tests (SE APIs), E2E tests (UXD-01 journeys), regression tests (previous epics), smoke test (critical paths), DECISION: ✅ approve OR ❌ block deploy.  

### When Executes
**Discovery:** QAE-00-Test-Strategy (AFTER PE defines stack)  
**Iteration:** Day 10 QUALITY GATE (integration + E2E + regression + smoke)  

### Key Deliverables
- **QAE-00-Test-Strategy.md** - Tools, coverage, quality gate criteria  
- **Integration tests** - 02-backend/tests/integration/  
- **E2E tests** - 01-frontend/tests/e2e/  

### Example Invocations
```
# Discovery (AFTER PE)
"QAE, crie estratégia de testes baseada no stack do PE (.NET + React + PostgreSQL)"
→ Creates QAE-00 with xUnit, Vitest, Playwright, coverage ≥70% domain

# Per Epic Quality Gate
"QAE, execute quality gate para épico 'Criar Estratégia' (Epic 1)"
→ Integration tests (SE APIs), E2E tests (UXD-01 journeys)
→ Regression tests (previous epics), Smoke test (critical paths)
→ DECISION: ✅ Approve deploy OR ❌ Block deploy + create feedback

"QAE, execute teste de regressão completo antes de deploy prod"
→ Validates all previous epics still work, critical before prod

# Updates
"QAE, processe FEEDBACK-010 sobre falha intermitente no teste de Greeks"
→ Investigates flaky test, fixes timing issue, updates test

"QAE, adicione teste de boundary condition para strike negativo"
→ Adds test to validate domain invariant
```

### Think Mode Policy
🟢 **OPTIONAL** - Tests have clear structure, but recommended for complete test suites

### Dependencies
**Depends on:** SDA (BCs for test strategy), PE (stack for test tools) | **Blocks:** Deploy (quality gate)  

### Specification
[60-QAE - Quality Assurance Engineer.xml](../60-QAE%20-%20Quality%20Assurance%20Engineer.xml)

---

## 35 - SEC (Security Specialist)

### Objective
Define essential security baseline: OWASP Top 3, LGPD minimum, authentication/authorization strategy - pragmatic for small/medium projects.

### Responsibilities
**Discovery (Day 3-4 - AFTER PE defines stack):**
Identify main threats per BC, OWASP Top 3 mitigations (Broken Access Control, Cryptographic Failures, Injection), LGPD minimum (PII mapping, deletion strategy, privacy policy), auth/authz strategy (JWT, domain-level), input validation, secrets management, security tools compatible with PE stack, security monitoring.

### When Executes
**Discovery:** SEC-00-Security-Baseline (AFTER PE)  
**Per Epic (OPTIONAL):** Security checkpoint (15-30 min) - See [07-PE-SEC-Checkpoint-Guide.md](07-PE-SEC-Checkpoint-Guide.md) for criteria  

### Key Deliverables
- **SEC-00-Security-Baseline.md** - OWASP Top 3 + LGPD + auth strategy + threat identification per BC  
- **SEC-EPIC-[N]-Security-Checkpoint.md** (optional per epic when handles sensitive data/auth)  

### Example Invocations
```
# Discovery (AFTER PE)
"SEC, crie baseline de segurança (OWASP Top 3, LGPD mínimo, estratégia auth)"
→ Creates SEC-00 with OWASP Top 3 mitigations, LGPD PII mapping, JWT auth strategy
→ Security tools compatible with PE stack (OWASP ZAP, Snyk)

"SEC, identifique principais ameaças por BC e defina mitigações essenciais"
→ Basic threat identification per BC (essential MVP mitigations, not full STRIDE)

# Optional per-epic security checkpoint
"SEC, checkpoint de segurança para Epic 2 (Autenticação - manipula PII)"
→ Quick 15-30 min review: OWASP Top 3, input validation, auth/authz, secrets

# Updates
"SEC, processe FEEDBACK-008 sobre hardcoded secrets em database init"
→ Documents multi-environment password strategy (ALTER USER migration)

"SEC, adicione checklist de validação de input para Value Objects"
→ Updates SEC-00 with validation patterns for domain layer
```

### Think Mode Policy
🔴 **MANDATORY** - Security baseline involves threat identification, OWASP Top 3, LGPD compliance

### Dependencies
**Depends on:** SDA (BCs, UL for threats), PE (stack for tool selection) | **Blocks:** None (parallel with GM/QAE)  

### Specification
[35-SEC - Security Specialist.xml](../35-SEC%20-%20Security%20Specialist.xml)

---

## 25 - GM (GitHub Manager)

### Objective
Integrate DDD workflow with GitHub: automate labels (script), CI/CD workflows, epic template, Git automation scripts - pragmatic v1.0.

### Responsibilities
**Discovery (Day 3-4 - AFTER PE):**
Create setup-labels.sh (from SDA BCs + epics), execute script (creates labels in GitHub), epic issue template (.github/ISSUE_TEMPLATE/10-epic.yml), CI/CD workflows (ci-backend, ci-frontend, security, cd-staging, cd-prod customized from PE stack), Git workflow automation scripts (discovery-start/finish, epic-modeling-start/finish, epic-create, epic-issue-start/finish, epic-close), document setup in GM-00.

**Per Epic (Day 2 - AFTER DE-01):**
Read DE-01, extract epic info (number, name, BCs, objectives, acceptance criteria), execute epic-create.sh to create milestone + epic issue automatically populated from DE-01.

### When Executes
**Discovery:** GitHub setup (AFTER PE defines stack)  
**Per Epic:** Create milestone + epic issue (AFTER DE-01 complete)  

### Key Deliverables
- **GM-00-GitHub-Setup.md** - Documents pragmatic setup (labels, CI/CD, templates)  
- **setup-labels.sh** - Creates labels (agents, BCs, epics, types, priority, status) in GitHub  
- **CI/CD workflows** - ci-backend, ci-frontend, security, cd-staging, cd-prod (customized from PE stack)  
- **Epic template** - .github/ISSUE_TEMPLATE/10-epic.yml (GitHub native form)  
- **Git automation scripts** - discovery-start/finish, epic-create, epic-issue-start/finish, epic-close  

### Example Invocations
```
# Discovery
"GM, configure GitHub (labels, CI/CD, epic template)"
→ Creates setup-labels.sh from SDA BCs + epics, executes script (41 labels)
→ Creates CI/CD workflows customized from PE stack
→ Creates epic template (.github/ISSUE_TEMPLATE/10-epic.yml)
→ Documents in GM-00-GitHub-Setup.md

# Per Epic - Milestone + Issues
"GM, crie milestone e issues para EPIC-01 (lendo DE-01)"
→ Executes epic-create.sh: reads DE-01, extracts BCs/objectives/criteria
→ Creates milestone M1 + epic issue 100% populated from DE-01
→ Creates 6 agent issues (DE, DBA, SE, UXD, FE, QAE) linked to M1

# Git Workflow Automation (see 03-GIT-PATTERNS.md for complete documentation)
"GM, inicie Discovery Foundation"
→ Executes: discovery-start.sh (branch + PR + milestone)

"GM, finalize issue #7 e faça merge"
→ Executes: epic-issue-finish.sh 7 --merge

"GM, feche EPIC-01 e crie release v1.0.0"
→ Executes: epic-close.sh 1 --release v1.0.0

# Updates
"GM, processe FEEDBACK-005 sobre alinhamento com PE multi-env strategy"
→ Updates GM-00 deployment section, aligns scripts with .env strategy
```

### Think Mode Policy
🟢 **OPTIONAL** - Scripts are automatable, but recommended for complex Git automation workflows

### Dependencies
**Depends on:** SDA (BCs, epics), PE (stack for CI/CD), DE (DE-01 for epic creation) | **Blocks:** None  

### Specification
[25-GM - GitHub Manager.xml](../25-GM%20-%20GitHub%20Manager.xml)

---

## 15 - DE (Domain Engineer)

### Objective
Model tactical domain PER EPIC - Aggregates, Entities, Value Objects (does NOT implement code).

### Responsibilities
**Per Epic (Nx):** Detailed tactical modeling (Aggregates, Entities, Value Objects, Domain Events), business rules, Use Cases (specifications), Repository interfaces (contracts), integration contracts between epic BCs.  

### When Executes
**Per epic (Nx):** DE-01-[EpicName]-Domain-Model ONLY (Iteration phase)  

### Key Deliverables
- **DE-01-[EpicName]-Domain-Model.md** - Tactical modeling per epic  

### Example Invocations
```
# Per Epic
"DE, modele épico 'Criar Estratégia Bull Call Spread' nos BCs Strategy + Market Data"
→ Creates DE-01-EPIC-01-Strategy-Domain-Model.md
→ Tactical modeling: Aggregates, Entities, Value Objects, Domain Events
→ Use Cases with specifications, Repository interfaces

"DE, crie modelo de domínio para épico 'Calcular Greeks em Tempo Real'"
→ Epic 2: Risk BC + Market Data BC, invariants, business rules, integration contracts

# Review & Updates
"DE, revise DE-01-Strategy verificando completude dos Aggregates"
→ Validates all entities, value objects, domain events documented, checks testable invariants

"DE, processe FEEDBACK-003 do QAE sobre Strategy aceitar strike negativo"
→ Analyzes bug report, updates domain model with invariant

"DE, adicione Use Case 'Validar Estratégia' ao DE-01-Strategy-Domain-Model"
→ Adds new use case with specifications
```

**Note:** DE executes ONLY in Iteration (per epic). For strategic changes, use SDA.  

### Think Mode Policy
🟡 **RECOMMENDED** for complex epics (>3 Aggregates, >5 Use Cases)

### Dependencies
**Depends on:** SDA (BCs, Context Map, UL) | **Consumed by:** DBA (schema), SE (implementation), GM (epic creation)  

### Specification
[15-DE - Domain Engineer.xml](../15-DE%20-%20Domain%20Engineer.xml)

---

## 50 - DBA (Database Administrator)

### Objective
Validate and optimize database schema created by DE - indexing, performance, multi-environment password strategy.

### Responsibilities
**Per Epic (AFTER DE):** Validate DE-01 schema, indexing strategy, query optimization, performance review, guidance for DE adjustments, multi-environment password strategy (dev simple, staging/prod strong via ALTER USER), security best practices (least privilege, rotation, LGPD/SOC2).  

### When Executes
**Per Epic:** After DE creates schema  

### Key Deliverables
- **README.md** - Multi-environment password strategy, security best practices  
- **DBA-01-[EpicName]-Schema-Review.md** - Per epic validation  
- **Migrations** - 001_initial_schema.sql (dev passwords), 002_update_prod_passwords.sql (ALTER USER)  

### Example Invocations
```
# Per Epic (AFTER DE)
"DBA, revise schema para épico 'Criar Estratégia'"
→ Creates DBA-01-EPIC-01-Schema-Review.md
→ Validates DE-01 schema, suggests indexes, checks FK relationships

"DBA, crie migration para épico 'Calculate Greeks' com índices de performance"
→ Creates migration file with indexes for query optimization
→ Validates schema supports DE-01 repository interfaces

# Security & Performance
"DBA, processe FEEDBACK-006 sobre senhas hardcoded no Git"
→ Documents multi-environment password strategy (dev simple, staging/prod strong)
→ Creates ALTER USER migration for staging/prod (LGPD/SOC2)

"DBA, processe FEEDBACK-007 sobre performance de query com >3 JOINs"
→ Analyzes slow query, suggests composite index or query refactoring

# Updates
"DBA, adicione índice em Strategy.UserId para query de listagem"
→ Small performance optimization based on monitoring
```

**Security:** NEVER hardcode passwords in Git. Dev: simple OK. Staging/Prod: strong via ALTER USER. Rotation: quarterly (prod), semi-annual (staging).  

### Think Mode Policy
🟡 **RECOMMENDED** for complex migrations (>5 files, complex indexes, data transformations)

### Dependencies
**Depends on:** DE (schema), PE (database tech) | **Consumed by:** SE (migrations for implementation)  

### Specification
[50-DBA - Database Administrator.xml](../50-DBA%20-%20Database%20Administrator.xml)

---

## 45 - SE (Software Engineer)

### Objective
Implement complete backend based on DE domain model - Domain, Application, Infrastructure, REST APIs.

### Responsibilities
**Per Epic (AFTER DE + DBA):** Domain layer (DE-01 Aggregates), Application layer (Use Cases), Infrastructure layer (Repositories, EF Migrations), REST/GraphQL APIs (Controllers, DTOs, OpenAPI), unit tests (≥70% line coverage of src/Domain/ namespace - QAE later expands with edge cases + integration/E2E tests).

### When Executes
**Per epic** - after DE creates DE-01 and DBA validates schema

### Key Deliverables
- **02-backend/src/Domain/** - Aggregates, Entities, Value Objects  
- **02-backend/src/Application/** - Use Cases, Commands, Queries, Handlers  
- **02-backend/src/Infrastructure/** - Repositories, EF Migrations, DB Context  
- **02-backend/src/Api/** - REST Controllers, DTOs, OpenAPI/Swagger  
- **02-backend/tests/unit/** - Unit tests (≥70% line coverage of src/Domain/ namespace)
- **02-backend/tests/coverage/** - Coverage report (verification)

### Example Invocations
```
# Per Epic (AFTER DE + DBA)
"SE, implemente domain layer para épico 'Criar Estratégia'"
→ Implements Aggregates, Entities, Value Objects from DE-01
→ Domain layer: 02-backend/src/Domain/, Unit tests ≥70% coverage

"SE, crie APIs REST para épico 'Calcular Greeks em Tempo Real'"
→ Application layer (Use Cases, Commands, Queries, Handlers)
→ Infrastructure layer (Repositories, EF Migrations, DB Context)
→ API layer (Controllers, DTOs, OpenAPI/Swagger)

# Review & Updates
"SE, revise cobertura de testes unitários do domain layer (target ≥70%)"
→ Validates domain logic has comprehensive tests (aggregates, value objects, events)

"SE, processe FEEDBACK-003 do QAE sobre aggregate Strategy aceitar strike negativo"
→ Fixes validation bug in domain layer, adds guard clause, updates unit tests

"SE, crie endpoint GET /strategies/{id}/greeks para cálculo de Greeks"
→ New API endpoint for Epic 2
```

**Critical Note:** SE implements AFTER DE (domain model) and DBA (schema validation).  

### Think Mode Policy
🔴 **MANDATORY** - Backend implementation involves 5 layers (Domain/Application/Infrastructure/API/Tests)

### Dependencies
**Depends on:** DE (domain model), DBA (schema validation), PE (tech stack) | **Consumed by:** FE (APIs), QAE (tests)  

### Specification
[45-SE - Software Engineer.xml](../45-SE%20-%20Software%20Engineer.xml)

---

## 55 - FE (Frontend Engineer)

### Objective
Implement user interfaces following UXD specs - UI components, state management, API integration, accessibility.

### Responsibilities
**Per Epic (AFTER SE + UXD):** UI components implementation, frontend skeleton (project structure), state management (Context/Redux), API integration (SE backend), responsiveness and accessibility (WCAG AA), basic component unit tests.  

### When Executes
**Per epic** - after SE (APIs) and UXD (wireframes), works in parallel with SE on Days 3-6

### Key Deliverables
- **01-frontend/src/components/** - Reusable UI components  
- **01-frontend/src/pages/** - Page-level components  
- **01-frontend/src/services/** - API integration layer  
- **01-frontend/tests/** - Component unit tests  

### Example Invocations
```
# Per Epic (AFTER SE + UXD)
"FE, implemente UI para épico 'Criar Estratégia' usando wireframes UXD-01"
→ Implements components based on UXD-01-EPIC-01-Wireframes.md
→ Integrates with SE APIs (POST /strategies, GET /market-data)
→ State management (React Context or Redux), basic component unit tests

"FE, crie componente Greeks Visualization para Dashboard de P&L"
→ Epic 2: Real-time Greeks display, Chart library (Recharts, Chart.js)
→ WebSocket integration for real-time updates

# Review & Updates
"FE, revise componentes do épico 1 verificando consistência com UXD-00 Design Foundations"
→ Validates colors, typography, spacing, checks PascalCase naming

"FE, valide acessibilidade dos componentes (WCAG AA, screen readers)"
→ Checks color contrast, keyboard navigation, ARIA labels, form labels and errors

"FE, processe FEEDBACK-002 do UXD sobre comportamento do botão Adicionar Perna"
→ Implements inline leg addition (not nested modal), adds limit of 4 legs with counter

"FE, adicione loading spinner ao modal Criar Estratégia durante submit"
→ UX improvement for async operation
```

**Note:** FE implements AFTER SE (APIs) and UXD (wireframes). Works in parallel with SE on Days 3-6.  

### Think Mode Policy
🔴 **MANDATORY** - Frontend implementation involves complete stack (Components/State/API integration/Tests)

### Dependencies
**Depends on:** SE (APIs), UXD (wireframes), PE (tech stack) | **Consumed by:** QAE (E2E tests)  

### Specification
[55-FE - Frontend Engineer.xml](../55-FE%20-%20Frontend%20Engineer.xml)

---

## 🔄 Agent Interactions

### Discovery Phase (Days 1-4)
**Day 1-2:** SDA (Event Storming, Context Map, Ubiquitous Language, prioritized epics)  

**Day 2-3 (PARALLEL):** UXD (Design Foundations - independent of tech stack) + PE (Environments Setup - DEFINES tech stack)  

**Day 3-4 (PARALLEL, AFTER PE):** QAE (Test Strategy - tools from PE stack) + SEC (Security Baseline - tools from PE stack) + GM (GitHub Setup - CI/CD from PE stack)  

**Critical:** PE must execute BEFORE QAE, SEC, GM because it defines the tech stack.  

### Iteration Phase (Days 1-10 per epic)
**Day 1-2:** DE (DE-01-[EpicName]-Domain-Model)  

**Day 2:** GM (reads DE-01, creates milestone + epic issue)  

**Day 2-3:** DBA (validates DE-01 schema, feedback to DE if needed)  

**Day 3-6 (PARALLEL):** SE (implements backend: Domain, Application, Infrastructure, API, unit tests ≥70%) + UXD (UXD-01-[EpicName]-Wireframes for FE)  

**Day 7-9:** FE (implements UI using UXD-01, integrates with SE APIs)  

**Day 10 (QUALITY GATE):** QAE (integration + E2E + regression + smoke tests) → ✅ Approve deploy OR ❌ Block deploy  

**DEPLOY:** Only if QAE approved  

### Feedback Loops
Any agent can create FEEDBACK for another: SE → DE (ambiguous invariant), FE → UXD (inconsistent wireframe), QAE → SE/FE (failing tests), DBA → DE (schema issues), GM → DE (unclear criteria), etc.

---

## 📋 Templates per Agent

| Agent | Templates |
|-------|-----------|
| SDA | 3 templates (Event-Storming, Context-Map, Ubiquitous-Language) |
| UXD | 2 templates (Design-Foundations, Epic-Wireframes) |
| PE | 1 template (Environments-Setup) |
| QAE | 1 template (Test-Strategy) |
| SEC | 1 template (Security-Baseline) |
| GM | 1 template (GitHub-Setup) |
| DE | 1 template (Epic-Domain-Model) |
| DBA | 1 template (Epic-Schema-Review) |
| SE | 0 (code is documentation) |
| FE | 0 (code is documentation) |
| All | 1 shared template (FEEDBACK) |

**Total:** 12 templates  

**Note:** Templates DE-00 and SE-01 archived (removed in v1.0 - code is primary documentation)  

---

## 📚 References

### Documentation
- **Workflow Guide:** [00-Workflow-Guide.md](00-Workflow-Guide.md)  
- **Nomenclature:** [02-Nomenclature-Standards.md](02-Nomenclature-Standards.md)  
- **Git Patterns:** [03-GIT-PATTERNS.md](03-GIT-PATTERNS.md)  
- **Security & Platform:** [04-Security-And-Platform-Strategy.md](04-Security-And-Platform-Strategy.md)  
- **DDD Patterns:** [05-DDD-Patterns-Reference.md](05-DDD-Patterns-Reference.md)  
- **API Standards:** [06-API-Standards.md](06-API-Standards.md)  

### Agent XML Specifications
- [10-SDA - Strategic Domain Analyst.xml](../10-SDA%20-%20Strategic%20Domain%20Analyst.xml)  
- [15-DE - Domain Engineer.xml](../15-DE%20-%20Domain%20Engineer.xml)  
- [20-UXD - User Experience Designer.xml](../20-UXD%20-%20User%20Experience%20Designer.xml)  
- [25-GM - GitHub Manager.xml](../25-GM%20-%20GitHub%20Manager.xml)  
- [30-PE - Platform Engineer.xml](../30-PE%20-%20Platform%20Engineer.xml)  
- [35-SEC - Security Specialist.xml](../35-SEC%20-%20Security%20Specialist.xml)  
- [45-SE - Software Engineer.xml](../45-SE%20-%20Software%20Engineer.xml)  
- [50-DBA - Database Administrator.xml](../50-DBA%20-%20Database%20Administrator.xml)  
- [55-FE - Frontend Engineer.xml](../55-FE%20-%20Frontend%20Engineer.xml)  
- [60-QAE - Quality Assurance Engineer.xml](../60-QAE%20-%20Quality%20Assurance%20Engineer.xml)  

### Resources
- **Templates:** `.agents/templates/`  
- **Checklists:** `.agents/workflow/02-checklists/`  
- **Workflow Config:** `workflow-config.json`  

---

**Version:** 1.0  
**Date:** 2025-10-09  
**Focus:** Small/Medium Projects  
**Agents:** 10 specialized agents  
**Philosophy:** Simple, pragmatic, value-driven  
