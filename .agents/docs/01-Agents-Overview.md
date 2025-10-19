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
| **3** | 30 | **PE** | **Platform Engineer** | **Basic setup** | **Discovery (Day 2-3)** | **1 doc + scripts** | **SDA** |
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
[10-SDA - Strategic Domain Analyst.xml](../10-SDA%20-%20Strategic%20Domain%20Analyst.xml)

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
[20-UXD - User Experience Designer.xml](../20-UXD%20-%20User%20Experience%20Designer.xml)

---

## 30 - PE (Platform Engineer)

### Objective
**Define tech stack** and configure basic environments (dev/stage/prod) with **deploy scripts** - NO complete IaC.

### Responsibilities
**Discovery ONLY (1x - Day 2-3):**
- **Define Tech Stack (Backend, Frontend, Database)** ← CRITICAL for GM/SEC/QAE
- Docker Compose for environments (dev, staging, production)
- Deploy scripts (deploy.sh)
- Environment variables configuration (.env.example)
- Basic logging (Docker logs + rotation)
- Configured health checks

### When Executes
- **Discovery (Day 2-3):** PE-00-Environments-Setup ← **BEFORE GM, SEC, QAE**
- **Per Epic (OPTIONAL - Light Review):** Quick performance checkpoint (15-30 min)

### Scope
- **Discovery:** Define stack + basic setup - pragmatic for small/medium projects
- **Per Epic:** Light performance review (optional, only if needed)

### Dependencies
- **Depends on:** SDA (BCs to estimate environments)
- **Blocks:** GM (CI/CD), SEC (security tools), QAE (test tools) until stack is defined

### Deliverables
```
00-doc-ddd/08-platform-engineering/
├── PE-00-Environments-Setup.md  (Discovery - 1x)
└── PE-EPIC-[N]-Performance-Checkpoint.md  (Per epic - OPTIONAL)

docker-compose.dev.yml
docker-compose.staging.yml
docker-compose.prod.yml
deploy.sh
.env.example
```

### PE Light Review per Epic (OPTIONAL)

**When to Execute:** See [07-PE-SEC-Checkpoint-Decision-Matrix.md](07-PE-SEC-Checkpoint-Decision-Matrix.md) for complete criteria.

**Summary:**
- Epic introduces critical performance path (ex: real-time calculations)
- Database queries becoming complex (>3 JOINs)
- Epic 4+ (after MVP is stable)
- Integration with external APIs

**What PE Reviews (15-30 min):**
1. ✅ **Database Performance**
   - N+1 queries identified? (use `.Include()`)
   - Missing indexes on FK/query filters?
   - Queries >100ms?

2. ✅ **Async/Await Correctness**
   - No `.Result` or `.Wait()` (deadlock risk)?
   - I/O operations are async?

3. ✅ **Caching Strategy**
   - Frequently accessed data cached? (Redis/In-Memory)
   - Cache invalidation clear?

4. ✅ **Resource Management**
   - Connections/streams disposed correctly?
   - No memory leaks in loops?

**Output:** Quick checklist (not full document), feedback to SE/DBA if issues found.

**Example Invocation:**
```
"PE, do a quick performance checkpoint for Epic 3 (Calculate Greeks)"
"PE, review database queries performance for Epic 5"
```

### Example Invocation
```
"PE, configure basic environments (dev/stage/prod) with Docker Compose"
"PE, create simple deploy scripts"
"PE, document required environment variables"
```

### Specification
[30-PE - Platform Engineer.xml](../30-PE%20-%20Platform%20Engineer.xml)

---

## 60 - QAE (Quality Assurance Engineer)

### Objective
Ensure quality as **QUALITY GATE** at end of each epic.

### Responsibilities
**Discovery (1x - Day 3-4):**
- QAE-00-Test-Strategy.md (tools, minimum coverage, criteria)
- **Test tools selection based on PE stack** (xUnit vs Jest, Vitest vs Mocha, Playwright vs Cypress)

**Per Epic (Nx - Day 10 - QUALITY GATE):**
- Integration tests (SE APIs, cross-BC communication)
- E2E tests (UXD-01 wireframe user journeys)
- Regression tests (previous epics still work)
- Smoke test (critical functionality)

**QUALITY GATE DECISION:**
- ✅ **Tests pass** → APPROVE deploy to staging/production
- ❌ **Tests fail** → BLOCK deploy, send feedback to SE/FE

### When Executes
- **Discovery (Day 3-4):** QAE-00-Test-Strategy - **AFTER PE defines stack**
- **Iteration (Day 10):** FINAL quality gate (integration + E2E + regression + smoke)

### Scope
**Per epic** - mandatory quality gate before deploy

### Dependencies
- **Depends on:** SDA (BCs for test strategy), **PE (stack for test tools selection)**

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
[60-QAE - Quality Assurance Engineer.xml](../60-QAE%20-%20Quality%20Assurance%20Engineer.xml)

---

## 35 - SEC (Security Specialist)

### Objective
Define **essential security baseline** - OWASP Top 3, LGPD minimum, auth strategy.

### Responsibilities
**Discovery ONLY (1x - Day 3-4):**
- Identify main threats per BC
- OWASP Top 3 mitigations (Broken Access Control, Cryptographic Failures, Injection)
- LGPD minimum (personal data mapping, deletion strategy, privacy policy)
- Authentication & Authorization strategy (JWT, domain-level authz)
- Input validation strategy
- Secrets management strategy (environment variables)
- **Security tools compatible with PE stack** (OWASP ZAP, Snyk, etc)
- Basic security monitoring (security events logging)

### When Executes
- **Discovery (Day 3-4):** SEC-00-Security-Baseline - **AFTER PE defines stack**
- **Per Epic (OPTIONAL - Light Review):** Quick security checkpoint (15-30 min)

### Scope
- **Discovery:** Essential baseline - pragmatic for small/medium projects
- **Per Epic:** Light security review (optional, only if needed)

### Dependencies
- **Depends on:** SDA (BCs, UL for threat identification), **PE (stack for compatible tools)**

### Deliverables
```
00-doc-ddd/09-security/
├── SEC-00-Security-Baseline.md  (Discovery - 1x)
└── SEC-EPIC-[N]-Security-Checkpoint.md  (Per epic - OPTIONAL)
```

### SEC Light Review per Epic (OPTIONAL)

**When to Execute:** See [07-PE-SEC-Checkpoint-Decision-Matrix.md](07-PE-SEC-Checkpoint-Decision-Matrix.md) for complete criteria.

**Summary:**
- Epic handles sensitive data (PII, credentials, financial)
- Epic introduces authentication/authorization logic
- Epic 4+ (after MVP is stable)
- Epic allows file uploads

**What SEC Reviews (15-30 min):**
1. ✅ **OWASP Top 3 Compliance**
   - **Broken Access Control:** Authorization checks in place?
   - **Cryptographic Failures:** Sensitive data encrypted? (at rest/transit)
   - **Injection:** Parameterized queries? Input validation?

2. ✅ **Input Validation**
   - Value Objects validate input?
   - DTOs have [Required], [MaxLength]?
   - XSS prevention? (React auto-escapes)

3. ✅ **Authentication & Authorization**
   - JWT token validated?
   - Domain-level authorization? (only owner can modify)
   - Sensitive operations require re-auth?

4. ✅ **Secrets Management**
   - No hardcoded secrets?
   - Environment variables used?
   - .env in .gitignore?

**Output:** Quick checklist (not full document), feedback to SE/DE/FE if issues found.

**Example Invocation:**
```
"SEC, do a quick security checkpoint for Epic 2 (User Authentication)"
"SEC, review security for Epic 4 (Payment Processing)"
```

### Example Invocation
```
"SEC, identify main threats per BC"
"SEC, define OWASP Top 3 mitigations"
"SEC, document LGPD minimum (data mapping, deletion, privacy policy)"
"SEC, define JWT authentication strategy"
```

### Specification
[35-SEC - Security Specialist.xml](../35-SEC%20-%20Security%20Specialist.xml)

---

## 25 - GM (GitHub Manager)

### Objective
Integrate DDD workflow with GitHub (v1.0). **Issues created via GitHub form AFTER DE-01** (refined epic).

### Version
**1.0**

**Philosophy:**
- ✅ Automate HIGH ROI tasks (labels via script, CI/CD workflows)
- ✅ Manual for LOW FREQUENCY tasks (milestones via UI, epic issues via GitHub form)
- ✅ Prefer GitHub native features over custom scripts

### Responsibilities

#### **Discovery (1x - Day 3-4):**
- ✅ **Create setup-labels.sh** in `03-github-manager/scripts/` (customized from SDA BCs and Epics)
- ✅ **Execute script**: Create labels in GitHub (agents, BCs, epics, types, priority, status, phase)
- ✅ **Create helper scripts**: `create-milestone.sh`, `create-epic-issue.sh` (for iteration phase)
- ✅ **Create epic issue template**: `.github/ISSUE_TEMPLATE/10-epic.yml` (GitHub native form)
- ✅ **Create CI/CD workflows** in `.github/workflows/` (customized from PE-00 stack):
  - `ci-backend.yml` (build, test for backend)
  - `ci-frontend.yml` (build, test for frontend)
  - `security.yml` (CodeQL, secret scanning)
  - `dependabot.yml` (dependency updates)
- ✅ **Document pre-existing templates**: Issue/PR templates already exist in `.github/`
- ❌ **DOES NOT create milestones** (created per epic during iteration - not all at once)
- ❌ **DOES NOT create issues** (epics not refined yet - no DE-01)

#### **Per Epic (Nx - Day 2):**
- ✅ Read `DE-01-[EpicName]-Domain-Model.md`
- ✅ Extract epic information:
  - Epic number (from filename: DE-01-EPIC-01-*.md)
  - Epic name and description
  - Objectives and acceptance criteria
  - BCs involved
- ✅ **EXECUTE `create-milestone.sh` automatically:**
  - Creates milestone: `M{number}: EPIC-{number} - {name from DE-01}`
  - Sets due date: Today + 6 weeks
  - Sets description: First paragraph from DE-01
- ✅ **EXECUTE `create-epic-issue.sh` automatically:**
  - Creates epic issue with base template
  - Links to milestone created above
  - Populates with basic structure
- ✅ **Guide user to customize epic issue:**
  - Edit issue to add complete DE-01 objectives
  - Edit issue to add complete acceptance criteria
  - Add BC labels (bc:*)
  - Add any epic-specific details from DE-01

### When Executes
- **Discovery (Day 3-4):** GitHub setup (labels script, CI/CD, epic template, helper scripts) - **AFTER PE defines stack**
- **Iteration (Day 2):** Execute scripts to create milestone + epic issue **AFTER DE-01** is complete

### Scope
**Complete system** - traceability of all epics, CI/CD automation

### Dependencies
- **Depends on:**
  - SDA (BCs for labels, epics for labels/template)
  - **PE (stack for CI/CD configuration - CRITICAL)**
  - DE (DE-01 for epic issue creation in iteration)

### Deliverables

#### Discovery (1x)
```
00-doc-ddd/07-github-management/
└── GM-00-GitHub-Setup.md  (documents pragmatic setup)

03-github-manager/scripts/
├── setup-labels.sh          (executable - creates labels, ONE-TIME)
├── create-milestone.sh      (executable - creates milestone per epic, ON-DEMAND)
├── create-epic-issue.sh     (executable - creates epic issue per epic, ON-DEMAND)
└── README.md                (documentation: scripts usage)

.github/workflows/
├── ci-backend.yml           (created - customized from PE-00)
├── ci-frontend.yml          (created - customized from PE-00)
├── security.yml             (created - languages from PE-00)
└── dependabot.yml           (created - ecosystems from PE-00)

.github/ISSUE_TEMPLATE/
├── 10-epic.yml              (created - GitHub native form for epics)
└── (other templates pre-existing - NOT created by GM)

.github/PULL_REQUEST_TEMPLATE.md  (pre-existing - NOT created by GM)
```

#### Per Epic (Nx)
```
Milestone M{number} created by GM via create-milestone.sh script
Epic Issue created by GM via create-epic-issue.sh script
User customizes issue with DE-01 complete details (1min)
```

### Example Invocation

#### Discovery
```
"GM, configure GitHub for the project (Discovery)"
```

**What GM does (step-by-step):**

1. **Read inputs:**
   - `SDA-02-Context-Map.md` → Extract BCs (for labels)
   - `SDA-01-Event-Storming.md` → Extract Epics (for labels)
   - `PE-00-Environments-Setup.md` → Extract tech stack (for CI/CD)

2. **Create setup-labels.sh** in `03-github-manager/`:
   - Populated with:
     - Agent labels (agent:SDA, agent:DE, etc.)
     - BC labels (bc:strategy-planning, bc:market-data, etc.) **from SDA-02**
     - Epic labels (epic:strategy-creation, epic:trade-execution, etc.) **from SDA-01**
     - Type, Priority, Status, Phase labels
   - `README.md` → Documentation (script + manual steps)

3. **Execute script:**
   ```bash
   cd 03-github-manager
   chmod +x setup-labels.sh
   ./setup-labels.sh       # Creates 41 labels in GitHub (~10min saved)
   ```

4. **Create epic issue template:**
   - `.github/ISSUE_TEMPLATE/10-epic.yml`
   - GitHub native form with:
     - Epic number, name, milestone dropdown
     - Description, objectives, acceptance criteria (text areas)
     - Deliverables checklist (checkboxes)
     - Definition of Done (checkboxes)

5. **Create CI/CD workflows** in `.github/workflows/`:
   - `ci-backend.yml` → Customized from PE-00 stack
   - `ci-frontend.yml` → Customized from PE-00 stack
   - `security.yml` → Languages from PE-00
   - `dependabot.yml` → Ecosystems from PE-00 (optional)

6. **Document setup:**
   - Create `GM-00-GitHub-Setup.md`:
     - Section 1: Pre-existing templates (Issue/PR templates)
     - Section 2: Created by GM (labels script, workflows, epic template)
     - Section 3: Manual steps (milestones via UI, Dependabot enable)
     - Section 4: Branch strategy (discipline-based, merge strategy)
     - Section 5: Metrics and monitoring commands

**Output:**
- ✅ Labels created in GitHub via script (agents, BCs, epics, types, priority, status)
- ✅ Epic issue template ready (GitHub form)
- ✅ CI/CD workflows created and running
- ✅ Manual steps documented (milestones, Dependabot)
- ✅ GM-00-GitHub-Setup.md documenting pragmatic approach

---

#### Iteration
```
"GM, create milestone and epic issue for EPIC-01 (Iteration)"
```

**What GM does (step-by-step):**

1. **Read DE-01:**
   - `DE-01-EPIC-01-Strategy-Creation-Domain-Model.md`
   - Extract:
     - Epic number: 01 (from filename)
     - Epic name: Strategy Creation (from filename)
     - Epic description (first paragraph)
     - Business objectives
     - Acceptance criteria
     - BCs involved

2. **Execute create-milestone.sh automatically:**
   ```bash
   ./03-github-manager/scripts/create-milestone.sh \
     1 \
     "EPIC-01 - Strategy Creation and Analysis" \
     "Catálogo de templates, criação de estratégias, cálculos automáticos" \
     "2026-02-28"
   ```
   - Milestone M1 created in GitHub
   - Due date: Today + 6 weeks

3. **Execute create-epic-issue.sh automatically:**
   ```bash
   ./03-github-manager/scripts/create-epic-issue.sh \
     1 \
     "M1: EPIC-01 - Strategy Creation and Analysis"
   ```
   - Epic issue created with base template
   - Title: `[EPIC-01] [TODO: Epic Name]`
   - Milestone: `M1: EPIC-01 - Strategy Creation and Analysis`
   - Labels: `epic`, `priority-high`, `agent:DE`, `agent:DBA`, `agent:SE`, `agent:FE`, `agent:QAE`

4. **Guide user to customize epic issue:**
   ```
   ⚠️ NEXT STEPS:
   1. Open epic issue in GitHub
   2. Edit title: [EPIC-01] Strategy Creation and Analysis
   3. Add complete objectives from DE-01
   4. Add complete acceptance criteria from DE-01
   5. Add BC labels: bc:strategy-planning, bc:market-data
   6. Verify deliverables checklist matches DE-01
   ```

**Output:**
- ✅ Milestone M1 created automatically (20s)
- ✅ Epic issue created automatically with base template (20s)
- ✅ User customizes issue with DE-01 rich details (1min)
- ✅ Total time: 1min40s (vs 3min manual)
- ✅ Traceability: Issue → Milestone → DE-01 → Code → Tests

**Why automated scripts + guided customization:**
- Faster (GM creates structure 40s vs user 3min)
- Consistent (milestone and issue always created, always linked)
- Flexible (user adds rich DE-01 context)
- Best of both worlds (automation + human context)

### Specification
[25-GM - GitHub Manager.xml](../25-GM%20-%20GitHub%20Manager.xml)

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
[15-DE - Domain Engineer.xml](../15-DE%20-%20Domain%20Engineer.xml)

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
[50-DBA - Database Administrator.xml](../50-DBA%20-%20Database%20Administrator.xml)

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
[45-SE - Software Engineer.xml](../45-SE%20-%20Software%20Engineer.xml)

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
[55-FE - Frontend Engineer.xml](../55-FE%20-%20Frontend%20Engineer.xml)

---

## 🔄 Agent Interactions

### Discovery Phase (SDA → [UXD + PE] → [QAE + SEC + GM])
```
Day 1-2: SDA
  - Event Storming
  - Context Map
  - Ubiquitous Language
  - Prioritized epics
    ↓
Day 2-3: [UXD + PE] in PARALLEL (Independent Foundations)

  UXD: UXD-00-Design-Foundations (colors, typography, base components)
       - Consumes: BCs, Context Map (from SDA)
       - ✅ Independent of tech stack

  PE: PE-00-Environments-Setup (Docker Compose, scripts)
      - Consumes: BCs (from SDA) to estimate environments
      - ✅ DEFINES tech stack (Backend, Frontend, Database)
    ↓
Day 3-4: [QAE + SEC + GM] in PARALLEL (Depend on PE Stack)

  QAE: QAE-00-Test-Strategy (tools, coverage, criteria)
       - Consumes: BCs (from SDA) to define test strategy
       - Consumes: PE stack to choose test tools (xUnit vs Jest, etc)
       - ⚠️ DEPENDS on PE stack

  SEC: SEC-00-Security-Baseline (OWASP Top 3, LGPD, auth strategy)
       - Consumes: BCs, UL (from SDA) to identify threats
       - Consumes: PE stack for compatible security tools
       - ⚠️ DEPENDS on PE stack

  GM: GM-00-GitHub-Setup (labels, CI/CD, templates)
      - Consumes: PE stack definition for CI/CD configuration
      - ❌ DOES NOT create issues (epics not refined)
      - ⚠️ DEPENDS on PE stack
```

### Iteration Phase (DE → GM → DBA → [SE + UXD] → FE → QAE → DEPLOY)
```
Day 1-2: DE
  - DE-01-[EpicName]-Domain-Model
    ↓
Day 2: GM
  - Reads DE-01
  - Executes create-milestone.sh (milestone M{N} created)
  - Executes create-epic-issue.sh (epic issue created with base template)
  - User customizes issue with DE-01 details (1min)
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
- **DDD Patterns:** [04-DDD-Patterns-Reference.md](04-DDD-Patterns-Reference.md)
- **API Standards:** [05-API-Standards.md](05-API-Standards.md)

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
