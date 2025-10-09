# Agents Overview

**Objective:** Detailed description of the 10 specialized agents executing the simplified DDD workflow for small/medium projects.

**Version:** 1.0
**Date:** 2025-10-09

---

## 📊 Executive Summary

| # | Code | Agent | Scope | Phase | Deliverables |
|---|------|-------|-------|-------|--------------|
| 10 | SDA | Strategic Domain Analyst | Complete system | Discovery | 3 docs |
| 15 | DE | Domain Engineer | Per epic ONLY | Iteration | 1 doc/epic |
| 20 | UXD | User Experience Designer | System + Per epic | Discovery + Iteration | 1 doc + 1/epic |
| 25 | GM | GitHub Manager | Setup + Per epic | Discovery + Iteration | 1 doc + issues |
| 30 | PE | Platform Engineer | Basic setup | Discovery | 1 doc + scripts |
| 35 | SEC | Security Specialist | Baseline | Discovery | 1 doc |
| 45 | SE | Software Engineer | Per epic | Iteration | Code |
| 50 | DBA | Database Administrator | Per epic | Iteration | Migrations |
| 55 | FE | Frontend Engineer | Per epic | Iteration | Code |
| 60 | QAE | Quality Assurance Engineer | Strategy + Per epic | Discovery + Iteration | 1 doc + tests |

---

## 10 - SDA (Strategic Domain Analyst)

### Objective
Discover and map the complete business domain, defining bounded contexts and strategic epics.

### Responsibilities
- Event Storming (domain event discovery)
- Bounded Contexts identification
- Context Map with relationships
- Ubiquitous Language (glossary)
- Epic prioritization by business value

### When Executes
**1x at project start** - discovery phase

### Scope
**Complete system** - analyzes entire business domain

### Deliverables
```
00-doc-ddd/02-strategic-design/
├── SDA-01-Event-Storming.md
├── SDA-02-Context-Map.md
└── SDA-03-Ubiquitous-Language.md
```

### Example Invocation
```
"SDA, perform complete strategic modeling of the system"
"SDA, update Context Map adding Notifications BC"
"SDA, process FEEDBACK-003"
```

### Specification
[.agents/10-SDA - Strategic Domain Analyst.xml](.agents/10-SDA - Strategic Domain Analyst.xml)

---

## 20 - UXD (User Experience Designer)

### Objective
Design user experience: foundations in Discovery + specific wireframes per epic.

### Responsibilities
**Discovery (1x):**
- Design foundations (colors, typography, base components)
- Does not create complete user flows or detailed wireframes

**Per Epic (Nx):**
- Epic-specific wireframes
- Works in PARALLEL with SE (Days 3-6)
- FE receives ready wireframes on Day 7

### When Executes
- **Discovery:** UXD-00-Design-Foundations.md (1x)
- **Iteration:** UXD-01-[EpicName]-Wireframes.md (per epic, parallel with SE)

### Scope
- **Discovery:** System foundations
- **Iteration:** Epic-specific wireframes

### Deliverables
```
00-doc-ddd/03-ux-design/
├── UXD-00-Design-Foundations.md  (Discovery - 1x)
└── UXD-01-[EpicName]-Wireframes.md  (Per epic - Nx)
```

### Example Invocation
```
"UXD, create design foundations (colors, typography, base components)"
"UXD, create wireframes for epic 'Create Strategy'"
"UXD, process FEEDBACK-005"
```

### Specification
[.agents/20-UXD - User Experience Designer.xml](.agents/20-UXD - User Experience Designer.xml)

---

## 15 - DE (Domain Engineer)

### Objective
Model tactical domain PER EPIC (does NOT implement code).

### Responsibilities
- Detailed tactical modeling PER EPIC (Aggregates, Entities, Value Objects)
- Domain Events and business rules
- Use Cases / Application Services (specification)
- Repository interfaces (contracts)
- Integration contracts between epic BCs

### When Executes
- **Per epic (Nx):** DE-01-[EpicName]-Domain-Model ONLY

### Scope
- **Iteration ONLY:** Multiple epic BCs (detailed modeling)
- UXD, PE, SEC work with SDA outputs (BCs, Context Map, UL)

### Deliverables
```
00-doc-ddd/04-tactical-design/
└── DE-01-[EpicName]-Domain-Model.md  (Per epic - Nx)
```

### Example Invocation
```
"DE, model epic 'Create Strategy' in Strategy + Market Data BCs"
"DE, create DE-01-Calculate-Greeks-Domain-Model"
"DE, create feedback for SDA about missing event"
```

### Specification
[.agents/15-DE - Domain Engineer.xml](.agents/15-DE - Domain Engineer.xml)

---

## 25 - GM (GitHub Manager)

### Objective
Integrate DDD workflow with GitHub. **Issues created AFTER DE-01** (refined epic).

### Responsibilities
**Discovery (1x):**
- Initial GitHub setup (labels, CI/CD, templates, branch protection)
- **❌ DOES NOT create issues** (epics not refined yet)

**Per Epic (Nx - Day 2):**
- Reads DE-01-[EpicName]-Domain-Model
- Creates detailed GitHub issue with:
  - Use cases (from DE-01)
  - Acceptance criteria
  - Tasks checklist

### When Executes
- **Discovery:** GitHub setup (labels, CI/CD, templates) - NO issues
- **Iteration (Day 2):** Creates issue AFTER DE-01

### Scope
**Complete system** - traceability of all epics

### Deliverables
```
00-doc-ddd/07-github-management/
└── GM-00-GitHub-Setup.md

.github/
├── ISSUE_TEMPLATE/
├── PULL_REQUEST_TEMPLATE/
└── workflows/ci.yml  (basic build + test)
```

### Example Invocation
```
"GM, configure GitHub for the project (Discovery)"
"GM, read DE-01-Create-Strategy and create detailed issue (Iteration)"
```

### Specification
[.agents/25-GM - GitHub Manager.xml](.agents/25-GM - GitHub Manager.xml)

---

## 30 - PE (Platform Engineer)

### Objective
Configure basic environments (dev/stage/prod) with **deploy scripts** - NO complete IaC.

### Responsibilities
**Discovery ONLY (1x):**
- Docker Compose for environments (dev, staging, production)
- Deploy scripts (deploy.sh)
- Environment variables configuration (.env.example)
- Basic logging (Docker logs + rotation)
- Configured health checks

### When Executes
- **Discovery ONLY:** PE-00-Environments-Setup (1x)
- **❌ DOES NOT execute** per epic

### Scope
**Basic setup** - pragmatic for small/medium projects

### Deliverables
```
00-doc-ddd/08-platform-engineering/
└── PE-00-Environments-Setup.md  (ONLY this doc)

docker-compose.dev.yml
docker-compose.staging.yml
docker-compose.prod.yml
deploy.sh
.env.example
```

### Example Invocation
```
"PE, configure basic environments (dev/stage/prod) with Docker Compose"
"PE, create simple deploy scripts"
"PE, document required environment variables"
```

### Specification
[.agents/30-PE - Platform Engineer.xml](.agents/30-PE - Platform Engineer.xml)

---

## 35 - SEC (Security Specialist)

### Objective
Define **essential security baseline** - OWASP Top 3, LGPD minimum, auth strategy.

### Responsibilities
**Discovery ONLY (1x):**
- Identify main threats per BC
- OWASP Top 3 mitigations (Broken Access Control, Cryptographic Failures, Injection)
- LGPD minimum (personal data mapping, deletion strategy, privacy policy)
- Authentication & Authorization strategy (JWT, domain-level authz)
- Input validation strategy
- Secrets management strategy (environment variables)
- Basic security monitoring (security events logging)

### When Executes
- **Discovery ONLY:** SEC-00-Security-Baseline (1x)
- **❌ DOES NOT execute** per epic

### Scope
**Essential baseline** - pragmatic for small/medium projects

### Deliverables
```
00-doc-ddd/09-security/
└── SEC-00-Security-Baseline.md  (ONLY this doc)
```

### Example Invocation
```
"SEC, identify main threats per BC"
"SEC, define OWASP Top 3 mitigations"
"SEC, document LGPD minimum (data mapping, deletion, privacy policy)"
"SEC, define JWT authentication strategy"
```

### Specification
[.agents/35-SEC - Security Specialist.xml](.agents/35-SEC - Security Specialist.xml)

---

## 45 - SE (Software Engineer)

### Objective
Implement complete backend based on DE domain model.

### Responsibilities
- Domain layer implementation (DE-01 Aggregates)
- Application layer implementation (DE-01 Use Cases)
- Infrastructure layer implementation (Repositories, EF Migrations)
- REST/GraphQL APIs (Controllers, DTOs, OpenAPI)
- Basic unit tests (≥70% coverage domain layer)

### When Executes
**Per epic** - after DE creates DE-01-[EpicName]-Domain-Model.md

### Scope
**Multiple epic BCs** - completely implements DE-specified model

### Deliverables
```
02-backend/
├── src/Domain/           (Aggregates, Entities, Value Objects)
├── src/Application/      (Use Cases, Commands, Queries, Handlers)
├── src/Infrastructure/   (Repositories, EF Migrations, DB Context)
├── src/Api/              (REST Controllers, DTOs, OpenAPI/Swagger)
└── tests/unit/           (Domain layer tests ≥70% coverage)
```

### Example Invocation
```
"SE, implement domain layer for epic 'Create Strategy'"
"SE, create REST APIs for epic 'Calculate Greeks'"
"SE, add unit tests for Strategy aggregate"
"SE, create feedback for DE about ambiguous invariant"
```

### Specification
[.agents/45-SE - Software Engineer.xml](.agents/45-SE - Software Engineer.xml)

---

## 50 - DBA (Database Administrator)

### Objective
Validate and optimize database schema created by DE.

### Responsibilities
- **Validation** of DE-created schema
- Indexing strategy
- Query optimization
- Performance review
- Guidance for DE to adjust schema

### When Executes
**Per epic** - after DE creates schema

### Scope
**Multiple epic BCs** - validates coordinated schema between BCs

### Deliverables
```
00-doc-ddd/05-database-design/
└── DBA-01-[EpicName]-Schema-Review.md
```

### Example Invocation
```
"DBA, review schema for epic 'Create Strategy'"
"DBA, suggest indexes for Greeks query"
"DBA, process FEEDBACK-007"
```

### Specification
[.agents/50-DBA - Database Administrator.xml](.agents/50-DBA - Database Administrator.xml)

---

## 55 - FE (Frontend Engineer)

### Objective
Implement user interfaces following UXD specs.

### Responsibilities
- UI components implementation
- **Frontend skeleton** (project structure)
- State management
- API integration (backend)
- Responsiveness and accessibility
- **Basic component unit tests**

### When Executes
**Per epic** - iterative, parallel to DE

### Scope
**Epic cross-cutting features** - UI integrating multiple BCs

### Deliverables
```
01-frontend/
├── src/components/
├── src/pages/
├── src/services/
└── tests/
```

### Example Invocation
```
"FE, implement UI for epic 'Create Strategy'"
"FE, create Greeks visualization component"
"FE, create feedback for UXD about dashboard wireframe"
```

### Specification
[.agents/55-FE - Frontend Engineer.xml](.agents/55-FE - Frontend Engineer.xml)

---

## 60 - QAE (Quality Assurance Engineer)

### Objective
Ensure quality as **QUALITY GATE** at end of each epic.

### Responsibilities
**Discovery (1x):**
- QAE-00-Test-Strategy.md (tools, minimum coverage, criteria)

**Per Epic (Nx - Day 10 - QUALITY GATE):**
- Integration tests (SE APIs, cross-BC communication)
- E2E tests (UXD-01 wireframe user journeys)
- Regression tests (previous epics still work)
- Smoke test (critical functionality)

**QUALITY GATE DECISION:**
- ✅ **Tests pass** → APPROVE deploy to staging/production
- ❌ **Tests fail** → BLOCK deploy, send feedback to SE/FE

### When Executes
- **Discovery:** QAE-00-Test-Strategy (1x)
- **Iteration (Day 10):** FINAL quality gate (integration + E2E + regression + smoke)

### Scope
**Per epic** - mandatory quality gate before deploy

### Deliverables
```
00-doc-ddd/06-quality-assurance/
└── QAE-00-Test-Strategy.md  (Discovery - 1x)

02-backend/tests/integration/
01-frontend/tests/e2e/
```

### Example Invocation
```
"QAE, create test strategy (tools, coverage, criteria)"
"QAE, execute quality gate for epic 'Create Strategy' (Day 10)"
"QAE, execute integration + E2E + regression + smoke tests"
```

### Specification
[.agents/60-QAE - Quality Assurance Engineer.xml](.agents/60-QAE - Quality Assurance Engineer.xml)

---

## 🔄 Agent Interactions

### Discovery Phase (SDA → [UXD + GM + PE + SEC + QAE] parallel)
```
Day 1-2: SDA
  - Event Storming
  - Context Map
  - Ubiquitous Language
  - Prioritized epics
    ↓
Day 2-4: [UXD + GM + PE + SEC + QAE] in PARALLEL

  UXD: UXD-00-Design-Foundations (colors, typography, base components)
       - Consumes: BCs, Context Map (from SDA)

  GM: GM-00-GitHub-Setup (labels, CI/CD, templates)
      - ❌ DOES NOT create issues (epics not refined)

  PE: PE-00-Environments-Setup (Docker Compose, scripts)
      - Consumes: BCs (from SDA) to estimate environments

  SEC: SEC-00-Security-Baseline (OWASP Top 3, LGPD, auth strategy)
       - Consumes: BCs, Ubiquitous Language (from SDA) to identify threats

  QAE: QAE-00-Test-Strategy (tools, coverage, criteria)
       - Consumes: BCs (from SDA) to define test strategy
```

### Iteration Phase (DE → GM → DBA → [SE + UXD] → FE → QAE → DEPLOY)
```
Day 1-2: DE
  - DE-01-[EpicName]-Domain-Model
    ↓
Day 2: GM
  - Reads DE-01
  - Creates detailed GitHub issue
    ↓
Day 2-3: DBA
  - Validates DE-01 schema
  - Feedback to DE if needed
    ↓
Day 3-6: [SE + UXD] in PARALLEL

  SE: Implements backend
      ├─→ Domain layer (DE-01 Aggregates)
      ├─→ Application layer (DE-01 Use Cases)
      ├─→ Infrastructure layer (Repositories, Migrations)
      ├─→ API layer (REST Controllers)
      └─→ Unit tests (≥70% coverage domain)

  UXD: UXD-01-[EpicName]-Wireframes
       - Epic-specific wireframes
       - FE receives ready wireframes on Day 7
    ↓
Day 7-9: FE
  - Implements UI using UXD-01 wireframes
  - Integrates with SE APIs
    ↓
Day 10: QAE (QUALITY GATE)
  - Integration tests (SE APIs)
  - E2E tests (user journeys)
  - Regression tests (previous epics)
  - Smoke test
  - ✅ Tests pass → APPROVE DEPLOY
  - ❌ Tests fail → BLOCK DEPLOY (return to SE/FE)
    ↓
DEPLOY (only if QAE approved)
```

### Feedback Loops
```
Any agent can create FEEDBACK for another:
- SE → DE (ambiguous invariant in DE-01)
- FE → UXD (inconsistent wireframe in UXD-01)
- QAE → SE (failing integration test)
- QAE → FE (failing E2E test)
- DBA → DE (schema with performance issue)
- GM → DE (unclear acceptance criteria)
- etc.
```

---

## 📋 Templates per Agent

| Agent | Templates |
|-------|-----------|
| SDA | 3 templates (Event-Storming, Context-Map, Ubiquitous-Language) |
| DE | 1 template (Epic-Domain-Model) |
| UXD | 2 templates (Design-Foundations, Epic-Wireframes) |
| GM | 1 template (GitHub-Setup) |
| PE | 1 template (Environments-Setup) |
| SEC | 1 template (Security-Baseline) |
| QAE | 1 template (Test-Strategy) |
| SE | 0 (code is documentation) |
| DBA | 0 (migrations are documentation) |
| FE | 0 (code is documentation) |
| All | 1 shared template (FEEDBACK) |

**Total:** 11 templates

---

## 📚 References

- **Workflow Guide:** [00-Workflow-Guide.md](00-Workflow-Guide.md)
- **Nomenclature:** [02-Nomenclature-Standards.md](02-Nomenclature-Standards.md)
- **XML Specifications:** `.agents/10-SDA.xml` through `.agents/60-QAE.xml`
- **Templates:** `.agents/templates/`
- **Checklists:** `.agents/workflow/02-checklists/`

---

**Version:** 1.0
**Date:** 2025-10-09
**Focus:** Small/Medium Projects
**Agents:** 10 specialized agents
**Philosophy:** Simple, pragmatic, value-driven
