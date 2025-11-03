# GM-00-GitHub-Setup.md

**Agent:** GM (GitHub Manager)  
**Project:** myTraderGEO  
**Date:** 2025-10-18  
**Phase:** Discovery  
**Scope:** GitHub repository setup with templates, workflows, and automation  
**Version:** 1.0  
**Repository:** mardantas/myTraderGEO  

---  

## 🎯 Objetivo

Documentar a configuração do GitHub para o projeto: templates pré-existentes (workflow), workflows CI/CD customizados (stack), labels via script, e automação de milestones/epic issues por épico.

**Versão 1.0 - Philosophy:**
- ✅ **Automate HIGH ROI tasks:**
  - **Discovery (1x):** Labels via script, CI/CD workflows files, Dependabot config, helper scripts
  - **Per Epic (Nx):** Milestones + Epic issues (executed automatically by GM on Day 2)
- ✅ **Hybrid approach:** Scripts create base structure (fast, consistent) + User customizes with rich context (DE-01 details)
- ✅ **GitHub Free adaptations:** NO branch protection (discipline-based workflow documented)

---

## 📖 Como Usar Esta Documentação

**Este documento (GM-00) é a REFERÊNCIA COMPLETA e ESTRATÉGICA:**
- **Target:** Team leads, arquitetos, futuros mantenedores
- **Conteúdo:** Justificativas (POR QUÊ cada decisão), detalhes técnicos completos (O QUÊ foi configurado), integrações com SDA/PE, limitações do GitHub Free e estratégias de mitigação
- **Estilo:** Completo, detalhado, educacional, documentação DDD formal
- **Quando consultar:** Para entender estratégia, tomar decisões arquiteturais, modificar configurações

**Para EXECUÇÃO RÁPIDA de tarefas, consulte:** [03-github-manager/README.md](../../03-github-manager/README.md)  
- **Target:** Desenvolvedores executando tarefas do dia-a-dia
- **Conteúdo:** Comandos CLI, checklists de execução, quick start, **links para seções deste documento para detalhes**
- **Estilo:** Minimalista, imperativo, quick reference, focado em comandos
- **Quando consultar:** Para executar setup, verificar status, troubleshooting rápido

**Princípio:** GM-00 explica o **POR QUÊ** e **O QUÊ**, README explica o **COMO executar**.  

**Evitamos duplicação:** O README contém apenas comandos e links para seções específicas deste documento, não repete explicações.  

---

## ✅ 1. Pré-Configurado (Parte do Workflow Template)

Os seguintes recursos **já existem** no projeto (copiados do workflow template durante setup inicial):

### 📋 Issue Templates

**Localização:** [.github/ISSUE_TEMPLATE/](.github/ISSUE_TEMPLATE/)  

Templates disponíveis:

| Template | Quando Usar | Descrição |
|----------|-------------|-----------|
| `00-discovery-foundation.yml` | **Sempre Issue #1** | Discovery phase completa (SDA, UXD, GM, PE, SEC, QAE) |
| `20-technical-task.yml` | Tarefas técnicas gerais | Generic technical tasks |
| `30-feature.yml` | Features específicas | Feature development dentro de um epic |
| `40-user-story.yml` | User stories | User stories (se usar metodologia ágil) |
| `99-bug.yml` | Bug reports | Reportar bugs |

**Status:** ✅ **Prontos para uso** (não criados pelo GM, apenas documentados)  

---

### 🔀 Pull Request Template

**Localização:** [.github/PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md)  

**Contém:**
- Descrição das mudanças
- Epic/Issue relacionado
- Agent responsável
- Bounded Contexts afetados
- Checklist de testes (unit, integration, E2E)
- Checklist de qualidade (nomenclature, docs, migrations)
- Screenshots (se UI)

**Status:** ✅ **Pronto para uso** (não criado pelo GM, apenas documentado)  

---

## 🚀 2. Criado pelo GM (Customizado para este Projeto)

### 🏷️ Labels

**Localização:** Criadas via script [03-github-manager/setup-labels.sh](../../../03-github-manager/setup-labels.sh)  

**Executar:**
```bash
cd 03-github-manager
chmod +x setup-labels.sh
./setup-labels.sh
```

**Labels criadas:**

#### Agents (Quem está trabalhando)
- `agent:SDA`, `agent:UXD`, `agent:DE`, `agent:DBA`, `agent:SE`, `agent:FE`, `agent:QAE`, `agent:GM`, `agent:PE`, `agent:SEC`

#### Bounded Contexts (Onde está o trabalho) - **From SDA-02-Context-Map.md**
- `bc:[BC_1]`
- `bc:[BC_2]`
- `bc:[BC_3]`
- *(Customize baseado nos BCs identificados pelo SDA)*

#### Epics (O que é) - **From SDA-01-Event-Storming.md**
- `epic:[EPIC_1_SHORT_NAME]`
- `epic:[EPIC_2_SHORT_NAME]`
- `epic:[EPIC_3_SHORT_NAME]`
- *(Customize baseado nos épicos priorizados pelo SDA)*

#### Types (Natureza do trabalho)
- `type:feature`, `type:bug`, `type:refactor`, `type:docs`, `type:test`, `type:chore`

#### Priority
- `priority:high`, `priority:medium`, `priority:low`

#### Status
- `status:blocked`, `status:wip`, `status:review`, `status:ready`

#### Phase
- `phase:discovery`, `phase:iteration`

**Verificar:**
```bash
gh label list --repo mardantas/myTraderGEO
```

---

### 🎯 Milestones

**Abordagem:** ✅ Criar **sob demanda** (um por vez, quando iniciar cada épico)  

**Por quê sob demanda:**
- Baixa frequência (5-10 milestones total no projeto)
- GitHub UI é rápido (30s cada)
- Milestones podem mudar (prioridades, datas) - criar apenas quando necessário
- **Criar incrementalmente:** M0 no Discovery, M1 quando iniciar EPIC-01, M2 quando iniciar EPIC-02, etc
- **NÃO criar todos de uma vez** - épicos futuros podem mudar completamente

**Script auxiliar criado:** [03-github-manager/scripts/create-milestone.sh](../../../03-github-manager/scripts/create-milestone.sh) ⚙️ ON-DEMAND TOOL  

**Milestones Planejados (conforme SDA-01 épicos):**

| Milestone | Descrição | Due Date | Issues Estimadas |
|-----------|-----------|----------|------------------|
| M0: Discovery Foundation | Setup inicial completo | (concluído ou +14 dias) | #1 |
| M1: [EPIC_1_NAME] | [EPIC_1_DESCRIPTION] | +6 semanas | ~15 |
| M2: [EPIC_2_NAME] | [EPIC_2_DESCRIPTION] | +10 semanas | ~15 |
| M3: [EPIC_3_NAME] | [EPIC_3_DESCRIPTION] | +14 semanas | ~12 |
| ... | ... | ... | ... |

---

**Como usar (quando iniciar um épico):**

1. **Quando iniciar EPIC-01** → Criar M1 (opção 1, 2 ou 3 abaixo)
2. **Quando iniciar EPIC-02** → Criar M2 (opção 1, 2 ou 3 abaixo)
3. E assim por diante...

---

**Como criar (Opção 1 - GitHub UI - Mais simples):**
```
GitHub UI → Issues → Milestones → New Milestone
→ Title: M1: [EPIC_1_NAME]
→ Due date: (calcular baseado em prioridade)
→ Description: [EPIC_1_DESCRIPTION]
→ Create milestone
```

**Como criar (Opção 2 - Script auxiliar - Mais rápido):**
```bash
# M1: Primeiro Épico
./03-github-manager/scripts/create-milestone.sh \
  1 \
  "EPIC-01 - [EPIC_1_NAME]" \
  "[EPIC_1_DESCRIPTION from SDA-01]" \
  "2026-02-28"

# M2: Segundo Épico
./03-github-manager/scripts/create-milestone.sh \
  2 \
  "EPIC-02 - [EPIC_2_NAME]" \
  "[EPIC_2_DESCRIPTION from SDA-01]" \
  "2026-04-30"
```

**Como criar (Opção 3 - GitHub CLI direto - Mais customizável):**

```bash
# M0: Discovery Foundation
gh api repos/mardantas/myTraderGEO/milestones -X POST \
  -f title="M0: Discovery Foundation" \
  -f description="Setup inicial completo: SDA, UXD, GM, PE, SEC, QAE deliverables" \
  -f state="open"

# M1: Primeiro Épico (com due date)
gh api repos/mardantas/myTraderGEO/milestones -X POST \
  -f title="M1: [EPIC_1_NAME]" \
  -f description="[EPIC_1_DESCRIPTION from SDA-01]" \
  -f due_on="2025-MM-DDTHH:MM:SSZ" \
  -f state="open"

# M2: Segundo Épico
gh api repos/mardantas/myTraderGEO/milestones -X POST \
  -f title="M2: [EPIC_2_NAME]" \
  -f description="[EPIC_2_DESCRIPTION from SDA-01]" \
  -f due_on="2025-MM-DDTHH:MM:SSZ" \
  -f state="open"

# Repetir para M3, M4, M5...
```

**Formato de due_on:** ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`)  
- Exemplo: `2025-12-31T23:59:59Z` (31 Dec 2025, 23:59:59 UTC)

**Verificar milestones criadas:**
```bash
gh api repos/mardantas/myTraderGEO/milestones
```

---

### 🎯 Epic Issues

**Localização do Template:** [.github/ISSUE_TEMPLATE/10-epic.yml](.github/ISSUE_TEMPLATE/10-epic.yml)  

**Abordagem:** ✅ Criar **sob demanda** (um por vez, após milestone criado e DE-01 completo)  

**Opções disponíveis:**
1. **GitHub Form** (preferencial) - UX melhor, validação automática, 2min
2. **Script auxiliar** - Rápido, gera template base para editar depois
3. **CLI direto** - Customização total, requer copy-paste

**Quando criar:**
- ✅ **APÓS** milestone correspondente criado (M1, M2, etc)
- ✅ **APÓS** DE-01-{EpicName}-Domain-Model.md estar completo
- ✅ **Um por vez** (não criar todos os épicos de uma vez)

**Execução Automática (Per Epic - Day 2):**
- ⚙️ **GM executa `create-milestone.sh` automaticamente** quando executado por épico
- ⚙️ **GM executa `create-epic-issue.sh` automaticamente** quando executado por épico
- ⚠️ **User customiza epic issue** com detalhes completos do DE-01 (1min)

**Script auxiliar criado:** [03-github-manager/scripts/create-epic-issue.sh](../../../03-github-manager/scripts/create-epic-issue.sh) ⚙️ AUTO-EXECUTED BY GM  

---

**Epic Issues Planejadas (conforme SDA-01):**

| Issue # | Epic | Milestone | Bounded Contexts | Prioridade | Status |
|---------|------|-----------|------------------|------------|--------|
| #2 | [EPIC-01] [EPIC_1_NAME] | M1 | [BC_1], [BC_2] | High | ⏳ Aguardando DE-01 |
| #X | [EPIC-02] [EPIC_2_NAME] | M2 | [BC_2], [BC_3] | High | ⏳ Aguardando DE-01 |
| #X | [EPIC-03] [EPIC_3_NAME] | M3 | [BC_1], [BC_4] | Medium | ⏳ Aguardando DE-01 |
| ... | ... | ... | ... | ... | ... |

---

**Como criar (Opção 1 - GitHub Form - Preferencial):**
```
GitHub UI → New Issue → 🎯 Epic Issue
→ Preencher formulário (2min) com dados do DE-01:
  - Epic Number: 01
  - Epic Name: [EPIC_1_NAME]
  - Milestone: M1: [EPIC_1_NAME]
  - Priority: priority-high
  - Description: (copiar de DE-01)
  - Bounded Contexts: (selecionar do DE-01)
  - Acceptance Criteria: (copiar de DE-01)
  - Deliverables checklists: (pré-preenchido por agent)
→ Submit → Issue criada!
```

**Como criar (Opção 2 - Script auxiliar - Rápido):**
```bash
# EPIC-01: Primeiro Épico (após DE-01 completo)
./03-github-manager/scripts/create-epic-issue.sh \
  1 \
  "M1: EPIC-01 - [EPIC_1_NAME]"

# EPIC-02: Segundo Épico (após DE-02 completo)
./03-github-manager/scripts/create-epic-issue.sh \
  2 \
  "M2: EPIC-02 - [EPIC_2_NAME]"

# ⚠️ IMPORTANTE: Editar o epic issue criado para customizar com detalhes do DE-01:
#   - Atualizar título com epic name
#   - Adicionar BC labels (bc:*)
#   - Preencher objectives, acceptance criteria do DE-01
```

**Como criar (Opção 3 - GitHub CLI direto - Customizável):**

```bash
# EPIC-01: Primeiro Épico (exemplo completo)
gh issue create --repo mardantas/myTraderGEO \
  --title "[EPIC-01] [EPIC_1_NAME]" \
  --label "epic,bc:[BC_1],bc:[BC_2],priority-high,agent:DE,agent:DBA,agent:SE,agent:FE,agent:QAE" \
  --milestone "M1: [EPIC_1_NAME]" \
  --body "$(cat <<'EOF'
## 📋 Epic Overview

**Epic Number:** 01  
**Epic Name:** [EPIC_1_NAME]  
**Business Value:** [From DE-01: Why this epic is important]  

## 🎯 Bounded Contexts Involved

- **[BC_1]** (Core): [Brief description from SDA-02]
- **[BC_2]** (Supporting): [Brief description from SDA-02]

## 📊 Objectives

[From DE-01 - Domain Model objectives section]

1. Objective 1
2. Objective 2
3. Objective 3

## ✅ Acceptance Criteria

[From DE-01 - acceptance criteria]

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## 📦 Deliverables

### DE - Domain Engineer
- [ ] DE-01-[EpicName]-Domain-Model.md (aggregates, entities, VOs, domain events)
- [ ] Domain events identified and documented
- [ ] Business rules validated with domain experts

### DBA - Database Administrator
- [ ] DBA-01-[EpicName]-Schema-Review.md
- [ ] EF Core migrations created and tested
- [ ] Indexes and constraints defined

### SE - Software Engineer (Backend)
- [ ] Domain layer implemented (aggregates, entities, VOs)
- [ ] Application layer implemented (commands, queries, handlers)
- [ ] API endpoints implemented and documented
- [ ] Unit tests (>80% coverage)
- [ ] Integration tests (critical paths)

### FE - Frontend Engineer
- [ ] Vue components implemented
- [ ] Pinia stores implemented
- [ ] API integration complete
- [ ] Unit tests (components)
- [ ] Responsive design validated

### QAE - Quality Assurance Engineer (Quality Gate)
- [ ] E2E tests implemented (Playwright)
- [ ] Smoke tests passing
- [ ] Performance baseline validated
- [ ] QAE-01-[EpicName]-Quality-Gate.md

## 📋 Definition of Done

- [ ] All deliverables completed and reviewed
- [ ] All tests passing (unit, integration, E2E)
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Deployed to staging and validated
- [ ] Performance baseline met
- [ ] Security review passed (if required)
- [ ] Ready for production deployment

---

**Related Documents:**
- DE-01: [Link to domain model when available]
- SDA-01: [Link to event storming](00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md)
- SDA-02: [Link to context map](00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md)

🤖 Generated with GitHub Manager (GM) template
EOF
)"

# EPIC-02: Segundo Épico (exemplo simplificado)
gh issue create --repo mardantas/myTraderGEO \
  --title "[EPIC-02] [EPIC_2_NAME]" \
  --label "epic,bc:[BC_2],bc:[BC_3],priority-high,agent:DE,agent:SE,agent:FE,agent:QAE" \
  --milestone "M2: [EPIC_2_NAME]" \
  --body "[Same structure as above, customize with EPIC-02 details from DE-01]"

# Repetir para EPIC-03, EPIC-04...
```

**Assign to milestone após criação (se não feito no create):**
```bash
# Get milestone number
MILESTONE_NUMBER=$(gh api repos/mardantas/myTraderGEO/milestones | jq -r '.[] | select(.title=="M1: [EPIC_1_NAME]") | .number')

# Assign issue to milestone
gh issue edit [ISSUE_NUMBER] --milestone $MILESTONE_NUMBER --repo mardantas/myTraderGEO
```

**Verificar epic issues criadas:**
```bash
# List all epic issues
gh issue list --label "epic" --repo mardantas/myTraderGEO

# View specific epic
gh issue view [ISSUE_NUMBER] --repo mardantas/myTraderGEO
```

---

**Template contém (quando usar GitHub Form):**
- Epic number, name input fields
- Milestone dropdown (options customizadas com epics do projeto)
- Priority dropdown (high, medium, low)
- Bounded Contexts (multiselect from project BCs)
- Description, objectives, acceptance criteria (text areas)
- Deliverables checklist (checkboxes por agent: DE, DBA, SE, FE, QAE, PE, SEC)
- Definition of Done (checkboxes)

**Recomendação:**
- **GitHub Form** para primeiro epic (aprender estrutura, 2min)
- **CLI** para epics subsequentes (mais rápido quando conhece estrutura, copy-paste)

---

### ⚙️ CI/CD Workflows

**Localização:** `.github/workflows/` (criados pelo GM, customizados baseado em PE-00 stack)  

#### Backend CI Pipeline

**Arquivo:** [.github/workflows/ci-backend.yml](.github/workflows/ci-backend.yml)  

**Stack:** [From PE-00: e.g., .NET 8.0]  

**Triggers:**
- Push para `develop`, `main`
- Pull requests para `develop`, `main`
- Apenas quando arquivos em `02-backend/` mudam

**Jobs:**
1. **build-and-test**
   - Setup .NET [VERSION from PE-00]
   - Restore dependencies
   - Build (Release)
   - Run unit tests (`Category=Unit`)
   - Run integration tests (`Category=Integration`)
   - Publish test results

2. **build-docker** (opcional, se usar Docker)
   - Build Docker image
   - Cache layers para performance

**Status checks:** ✅ Required before merge (discipline-based, GitHub Free)  

---

#### Frontend CI Pipeline

**Arquivo:** [.github/workflows/ci-frontend.yml](.github/workflows/ci-frontend.yml)  

**Stack:** [From PE-00: e.g., React 18 + Vite, Node 20.x, npm]  

**Triggers:**
- Push para `develop`, `main`
- Pull requests para `develop`, `main`
- Apenas quando arquivos em `01-frontend/` mudam

**Jobs:**
1. **build-and-test**
   - Setup Node.js [VERSION from PE-00]
   - Install dependencies ([PACKAGE_MANAGER from PE-00: npm/yarn/pnpm])
   - Lint code
   - Type check (TypeScript)
   - Run unit tests
   - Build (production)
   - Upload artifacts (optional)

2. **build-docker** (opcional, se usar Docker)
   - Build Docker image
   - Cache layers para performance

**Status checks:** ✅ Required before merge (discipline-based, GitHub Free)  

---

#### Security Scanning

**Arquivo:** [.github/workflows/security.yml](.github/workflows/security.yml)  

**Triggers:**
- Push para `main`, `develop`
- Pull requests
- Schedule: Semanal (Sundays, 00:00 UTC)
- Manual dispatch

**Jobs:**
1. **CodeQL Analysis**
   - Languages: [From PE-00: e.g., csharp, javascript-typescript]
   - Security-extended queries
   - Autobuild (for compiled languages)

2. **Secret Scanning**
   - TruffleHog OSS
   - Detecta secrets commitados

3. **Dependency Review** (apenas em PRs)
   - Fail on: moderate+ severity
   - Deny licenses: GPL-2.0, GPL-3.0

4. **OWASP Dependency Check** (opcional)
   - Weekly full scan
   - HTML report gerado

**Reports:** Disponíveis na aba Security do GitHub  

---

#### Dependabot Configuration

**Arquivo:** [.github/dependabot.yml](.github/dependabot.yml)  

**Package ecosystems:** [From PE-00 stack]  

| Ecosystem | Directory | Schedule | Notes |
|-----------|-----------|----------|-------|
| `nuget` | `/02-backend` | Weekly (Mondays, 09:00) | .NET packages |
| `npm` | `/01-frontend` | Weekly (Mondays, 09:00) | Node packages, ignora major de React/Vite |
| `github-actions` | `/` | Weekly (Mondays, 09:00) | GitHub Actions versions |

**Configuration:**
- Open PRs limit: 5 per ecosystem
- Auto-reviewers: [GITHUB_USERNAME]
- Labels: `dependencies`, `backend`/`frontend`, `security`
- Grouped updates: minor + patch together

---

#### CD Staging Pipeline (Opcional)

**Arquivo:** [.github/workflows/cd-staging.yml](.github/workflows/cd-staging.yml)  

**Triggers:**
- Push para `develop`
- Manual dispatch

**Environments:**
- **Staging:** [STAGING_URL from PE-00]

**Jobs:**
1. **deploy-backend**
   - Build + Publish
   - Run migrations
   - Deploy (Azure/AWS/Docker - customizar)
   - Health check

2. **deploy-frontend**
   - Build (production)
   - Deploy (S3/Azure Static Web Apps/Vercel - customizar)
   - Health check

3. **notify**
   - Slack/Discord/Email notification (optional)

**Status:** ⚠️ **Requires customization** (deployment target from PE-00)  

**Prerequisites:**
- `.env.staging` configured on staging server (see [PE-00](../08-platform-engineering/PE-00-Environments-Setup.md#env-strategy))
- Staging server IP configured (separate from production)
- Docker Compose v2+ installed on staging server

**Manual Deploy Command:**
```bash
# On staging server (SSH)
docker compose -f 05-infra/docker/docker-compose.staging.yml \
  --env-file 05-infra/configs/.env.staging \
  up -d
```

---

### 🔗 Deployment Strategy (PE-00 Integration)

**IMPORTANT:** All deployment commands MUST use `--env-file` flag explicitly per environment.  

#### Environment-Specific .env Files

See [PE-00 Environments Setup](../08-platform-engineering/PE-00-Environments-Setup.md) for complete strategy.

| Environment | .env File | Usage |
|-------------|-----------|-------|
| Development | `.env.dev` | Local Docker Compose |
| Staging | `.env.staging` | Staging server deployment |
| Production | `.env.production` | Production server deployment |

**Command Pattern:**
```bash
# Development
docker compose -f 05-infra/docker/docker-compose.yml \
  --env-file 05-infra/configs/.env.dev up

# Staging
docker compose -f 05-infra/docker/docker-compose.staging.yml \
  --env-file 05-infra/configs/.env.staging up -d

# Production
docker compose -f 05-infra/docker/docker-compose.production.yml \
  --env-file 05-infra/configs/.env.production up -d
```

#### Multi-Server Architecture

**Staging and Production run on SEPARATE servers/IPs:**
- **Staging Server:** Dedicated IP (e.g., 203.0.113.10)
- **Production Server:** Dedicated IP (e.g., 203.0.113.20)

**Why separate servers:**
- ✅ Complete isolation (staging issues don't affect production)
- ✅ Security (breach containment - critical for financial apps)
- ✅ Independent resource allocation
- ✅ Separate audit trails and access control

See [PE-00 Network Architecture](../08-platform-engineering/PE-00-Environments-Setup.md#network-architecture) for details.

#### Key PE-00 Decisions Affecting CI/CD

1. **Docker Compose Commands:** ALWAYS use `--env-file` (no implicit `.env` loading)
2. **Traefik Integration:** Staging + Production use Traefik v3.0 (separate instances)
3. **Certificate Resolvers:** Staging uses Let's Encrypt staging CA, Production uses production CA
4. **Windows Compatibility:** Scripts must run in Git Bash or WSL2 (see PE-00)

---

## 🔒 3. Branch Strategy (GitHub Free)

**⚠️ GitHub Free Limitation:** Branch protection rules não disponíveis.  

### Estratégia Discipline-Based

#### Fluxo Obrigatório
```
feature/* → develop → main
```

**Regras (aplicadas manualmente):**
- ❌ **NUNCA** push direto para `main` ou `develop`
- ✅ **SEMPRE** criar PR para merge
- ✅ **SEMPRE** verificar CI status checks antes de merge
- ✅ **Recomendado:** Pelo menos 1 code review

#### Branch Naming Convention
```
feature/epic-N-[short-name]    # Feature branches (por épico)
feature/de-[task]              # Domain Engineer tasks
feature/fe-[component]         # Frontend tasks
feature/se-[feature]           # Backend tasks
bugfix/[issue]-[name]          # Bug fixes
hotfix/[critical]              # Production hotfixes
```

#### Git Hooks Locais (Opcional - Prevenção)

**Localização:** [03-github-manager/pre-push-hook.sh](../../../03-github-manager/pre-push-hook.sh) (se criado)  

Previne push acidental para `main`:
```bash
cp 03-github-manager/pre-push-hook.sh .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

**Nota:** Git hooks são locais (cada dev precisa configurar).  

---

### Semantic Versioning

**Format:** `vMAJOR.MINOR.PATCH`  

| Tipo | Exemplo | Quando |
|------|---------|--------|
| **MAJOR** | v2.0.0 | Breaking changes (API incompatível) |
| **MINOR** | v1.1.0 | New features (backward compatible) |
| **PATCH** | v1.0.1 | Bug fixes |

**Tagging:**
```bash
# Após merge em main
git tag -a v1.0.0 -m "Release v1.0.0: [Epic Name]"
git push origin v1.0.0

# GitHub Release
gh release create v1.0.0 \
  --title "v1.0.0: [Epic Name]" \
  --notes "- Feature: [description]
           - Fix: [description]"
```

---

## 📊 4. Métricas e Monitoramento

### Ver Progresso de Épico
```bash
# Issues em um milestone
gh issue list --milestone "M1: [Epic Name]" --repo mardantas/myTraderGEO

# Issues por agent
gh issue list --label "agent:DE" --state open --repo mardantas/myTraderGEO

# Issues bloqueadas
gh issue list --label "status:blocked" --repo mardantas/myTraderGEO
```

### Velocity (Issues fechadas)
```bash
# Última semana
gh issue list --state closed --search "closed:>=YYYY-MM-DD" --repo mardantas/myTraderGEO

# Por épico
gh issue list --state closed --milestone "M1: [Epic]" --repo mardantas/myTraderGEO
```

### CI/CD Status
```bash
# Ver últimos workflow runs
gh run list --repo mardantas/myTraderGEO

# Ver run específico
gh run view [RUN_ID] --repo mardantas/myTraderGEO
```

---

## 📋 5. Checklist de Verificação

### Discovery (GM-00 - Uma vez)

- [ ] **Labels criadas** via `setup-labels.sh` ✅ AUTOMATED
  - [ ] Script executado (creates 41 labels, saves ~10min)
  - [ ] Agents (10 labels)
  - [ ] Bounded Contexts (do SDA-02)
  - [ ] Epics (do SDA-01)
  - [ ] Types, Priority, Status, Phase
- [ ] **Helper scripts criados** ✅ AUTOMATED
  - [ ] `create-milestone.sh` (para criar milestones sob demanda)
  - [ ] `create-epic-issue.sh` (para criar epic issues sob demanda)
- [ ] **Milestone M0 criado** ⚠️ ON-DEMAND
  - [ ] M0: Discovery Foundation (30s - UI, script, ou CLI)
- [ ] **Epic issue template criado** ✅ AUTOMATED
  - [ ] `.github/ISSUE_TEMPLATE/10-epic.yml` (GitHub form)
- [ ] **CI/CD Workflows criados** ✅ AUTOMATED
  - [ ] `ci-backend.yml` (customizado do PE-00)
  - [ ] `ci-frontend.yml` (customizado do PE-00)
  - [ ] `security.yml` (languages do PE-00)
- [ ] **Dependabot** ⚠️ OPTIONAL
  - [ ] Config file criado OU
  - [ ] Habilitado via GitHub UI (Settings → Security)
- [ ] **Documentação criada**
  - [ ] GM-00: Estratégia e justificativas (POR QUÊ/O QUÊ)
  - [ ] README: Comandos e quick reference (COMO)
  - [ ] Scripts auxiliares documentados
- [ ] **Branch strategy documentada**
  - [ ] Naming conventions
  - [ ] PR workflow discipline
  - [ ] Merge strategy

### Per Epic (Por Iteração - Sob Demanda)

**Quando:** Ao iniciar cada novo épico (após DE-01 completo)  

- [ ] **Milestone criado** ⚙️ ON-DEMAND (um por vez)
  - [ ] Opção 1: GitHub UI (30s)
  - [ ] Opção 2: Script `create-milestone.sh` (20s)
  - [ ] Opção 3: CLI direto
  - [ ] **NÃO criar todos de uma vez** - apenas quando necessário
- [ ] **Epic issue criada** ⚙️ ON-DEMAND (após milestone + DE-01)
  - [ ] APÓS milestone correspondente criado
  - [ ] APÓS DE-01-{EpicName}-Domain-Model.md completo
  - [ ] Opção 1: GitHub Form (2min - preferencial)
  - [ ] Opção 2: Script `create-epic-issue.sh` + edição manual
  - [ ] Opção 3: CLI direto
  - [ ] Customizar com detalhes do DE-01
  - [ ] Assigned to milestone
  - [ ] Labels: epic, BC, priority

---

## 🔗 Referências

### Documentos Consultados
- **SDA-01 Event Storming:** [00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md](00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md) - Epics para labels/milestones
- **SDA-02 Context Map:** [00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md](00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md) - BCs para labels
- **PE-00 Environments Setup:** [00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md](00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md) - Stack para CI/CD

### Scripts Criados

**Setup (One-time):**
- [03-github-manager/scripts/setup-labels.sh](../../../03-github-manager/scripts/setup-labels.sh) ✅ ONE-TIME (Discovery)

**Epic Lifecycle (Mandatory):**
- [03-github-manager/scripts/epic-create.sh](../../../03-github-manager/scripts/epic-create.sh) 🚀 Creates milestone + epic issue + 6 agent issues
- [03-github-manager/scripts/epic-start.sh](../../../03-github-manager/scripts/epic-start.sh) 🌱 Creates epic branch + empty commit + draft PR
- [03-github-manager/scripts/epic-modeling-start.sh](../../../03-github-manager/scripts/epic-modeling-start.sh) 📐 Starts DE-01 domain modeling
- [03-github-manager/scripts/epic-modeling-finish.sh](../../../03-github-manager/scripts/epic-modeling-finish.sh) ✅ Finishes DE-01 (commit + PR, manual merge)
- [03-github-manager/scripts/epic-deploy.sh](../../../03-github-manager/scripts/epic-deploy.sh) 🚢 Validates epic + prepares PR for manual merge
- [03-github-manager/scripts/epic-close.sh](../../../03-github-manager/scripts/epic-close.sh) 🏁 Closes milestone + manual release instructions
- [03-github-manager/scripts/discovery-finish.sh](../../../03-github-manager/scripts/discovery-finish.sh) 🎉 Finalizes Discovery (validate + PR, manual merge)

**Optional Helpers:**
- [03-github-manager/scripts/create-milestone.sh](../../../03-github-manager/scripts/create-milestone.sh) ⚙️ ON-DEMAND (Per Epic)
- [03-github-manager/scripts/create-epic-issue.sh](../../../03-github-manager/scripts/create-epic-issue.sh) ⚙️ ON-DEMAND (Per Epic)

**Documentation:**
- [03-github-manager/README.md](../../../03-github-manager/README.md) 📋 Quick reference with usage examples

### Workflows Criados
- [.github/workflows/ci-backend.yml](.github/workflows/ci-backend.yml)
- [.github/workflows/ci-frontend.yml](.github/workflows/ci-frontend.yml)
- [.github/workflows/security.yml](.github/workflows/security.yml)
- [.github/dependabot.yml](.github/dependabot.yml)
- [.github/workflows/cd-staging.yml](.github/workflows/cd-staging.yml) *(opcional)*

### Templates Pré-Existentes
- [.github/ISSUE_TEMPLATE/](.github/ISSUE_TEMPLATE/) (8 templates)
- [.github/PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md)

---

## 📝 Notas

### GitHub Free Limitations
- ❌ Branch protection rules não disponíveis
- ❌ Required reviewers não forçados
- ❌ Required status checks não bloqueiam merge automaticamente
- ✅ **Mitigation:** Disciplina + PR workflow + CI status visibility

### Customização Executada
`setup-labels.sh` customizado com:
- ✅ BCs do SDA-02
- ✅ Epics do SDA-01
- ✅ Owner/Repo name

Epic issue template customizado com:
- ✅ Milestone dropdown options (project epics)

CI/CD workflows customizados com:
- ✅ Stack do PE-00 (backend, frontend, languages)

### Passos Manuais Documentados
- ⚠️ Milestones: Criar via GitHub UI conforme necessário
- ⚠️ Epic issues: Usar GitHub form template (AFTER DE-01)
- ⚠️ Dependabot: Habilitar via UI (opcional)

### Próximos Passos
1. ✅ Discovery completo → Issue #1 fechada
2. ✅ Workflows CI/CD rodando
3. ➡️ **Próximo:** DE-01 para primeiro épico → User creates epic issue via form

---

**GitHub Setup Version:** 1.0  
**Status:** ✅ **Executado e validado**  
**Última atualização:** 2025-10-18  
