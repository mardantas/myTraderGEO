# GM-00-GitHub-Setup.md

**Projeto:** [PROJECT_NAME]
**Data:** [YYYY-MM-DD]
**GitHub Manager:** GM Agent (v1.0)
**Repository:** [GITHUB_OWNER]/[REPO_NAME]

---

## 🎯 Objetivo

Documentar a configuração do GitHub para o projeto: templates pré-existentes (workflow), workflows CI/CD customizados (stack), labels via script, e passos manuais documentados.

**Versão 1.0:** Automate HIGH ROI tasks, manual for LOW FREQUENCY tasks.

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
gh label list --repo [OWNER]/[REPO]
```

---

### 🎯 Milestones

**Abordagem:** ✅ Criar manualmente conforme necessário (30s cada via UI, ou via CLI)

**Por quê manual:**
- Baixa frequência (5-10 milestones total)
- GitHub UI é rápido (30s)
- Milestones podem mudar (prioridades, datas)

**Milestones Planejados (conforme SDA-01 épicos):**

| Milestone | Descrição | Due Date | Issues Estimadas |
|-----------|-----------|----------|------------------|
| M0: Discovery Foundation | Setup inicial completo | (concluído ou +14 dias) | #1 |
| M1: [EPIC_1_NAME] | [EPIC_1_DESCRIPTION] | +6 semanas | ~15 |
| M2: [EPIC_2_NAME] | [EPIC_2_DESCRIPTION] | +10 semanas | ~15 |
| M3: [EPIC_3_NAME] | [EPIC_3_DESCRIPTION] | +14 semanas | ~12 |
| ... | ... | ... | ... |

---

**Como criar (Opção 1 - GitHub UI):**
```
GitHub UI → Issues → Milestones → New Milestone
→ Title: M1: [EPIC_1_NAME]
→ Due date: (calcular baseado em prioridade)
→ Description: [EPIC_1_DESCRIPTION]
→ Create milestone
```

**Como criar (Opção 2 - GitHub CLI via API):**

```bash
# M0: Discovery Foundation
gh api repos/[OWNER]/[REPO]/milestones -X POST \
  -f title="M0: Discovery Foundation" \
  -f description="Setup inicial completo: SDA, UXD, GM, PE, SEC, QAE deliverables" \
  -f state="open"

# M1: Primeiro Épico (com due date)
gh api repos/[OWNER]/[REPO]/milestones -X POST \
  -f title="M1: [EPIC_1_NAME]" \
  -f description="[EPIC_1_DESCRIPTION from SDA-01]" \
  -f due_on="2025-MM-DDTHH:MM:SSZ" \
  -f state="open"

# M2: Segundo Épico
gh api repos/[OWNER]/[REPO]/milestones -X POST \
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
gh api repos/[OWNER]/[REPO]/milestones
```

---

### 🎯 Epic Issues

**Localização do Template:** [.github/ISSUE_TEMPLATE/10-epic.yml](.github/ISSUE_TEMPLATE/10-epic.yml)

**Abordagem:** ✅ GitHub native form (substituiu bash script) + CLI alternativa

**Por quê GitHub form > bash script:**
- Mais rápido (2min form vs 5min bash customization)
- Mais flexível (fácil ajustar campos sem editar script)
- GitHub native (sem manutenção, sempre atualizado)
- Melhor UX (dropdowns, checkboxes, validação)

**Quando criar:** ✅ APÓS DE-01-{EpicName}-Domain-Model.md estar completo

---

**Epic Issues Planejadas (conforme SDA-01):**

| Issue # | Epic | Milestone | Bounded Contexts | Prioridade | Status |
|---------|------|-----------|------------------|------------|--------|
| #2 | [EPIC-01] [EPIC_1_NAME] | M1 | [BC_1], [BC_2] | High | ⏳ Aguardando DE-01 |
| #X | [EPIC-02] [EPIC_2_NAME] | M2 | [BC_2], [BC_3] | High | ⏳ Aguardando DE-01 |
| #X | [EPIC-03] [EPIC_3_NAME] | M3 | [BC_1], [BC_4] | Medium | ⏳ Aguardando DE-01 |
| ... | ... | ... | ... | ... | ... |

---

**Como criar (Opção 1 - GitHub Form UI):**
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

**Como criar (Opção 2 - GitHub CLI):**

```bash
# EPIC-01: Primeiro Épico (exemplo completo)
gh issue create --repo [OWNER]/[REPO] \
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
gh issue create --repo [OWNER]/[REPO] \
  --title "[EPIC-02] [EPIC_2_NAME]" \
  --label "epic,bc:[BC_2],bc:[BC_3],priority-high,agent:DE,agent:SE,agent:FE,agent:QAE" \
  --milestone "M2: [EPIC_2_NAME]" \
  --body "[Same structure as above, customize with EPIC-02 details from DE-01]"

# Repetir para EPIC-03, EPIC-04...
```

**Assign to milestone após criação (se não feito no create):**
```bash
# Get milestone number
MILESTONE_NUMBER=$(gh api repos/[OWNER]/[REPO]/milestones | jq -r '.[] | select(.title=="M1: [EPIC_1_NAME]") | .number')

# Assign issue to milestone
gh issue edit [ISSUE_NUMBER] --milestone $MILESTONE_NUMBER --repo [OWNER]/[REPO]
```

**Verificar epic issues criadas:**
```bash
# List all epic issues
gh issue list --label "epic" --repo [OWNER]/[REPO]

# View specific epic
gh issue view [ISSUE_NUMBER] --repo [OWNER]/[REPO]
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
gh issue list --milestone "M1: [Epic Name]" --repo [OWNER]/[REPO]

# Issues por agent
gh issue list --label "agent:DE" --state open --repo [OWNER]/[REPO]

# Issues bloqueadas
gh issue list --label "status:blocked" --repo [OWNER]/[REPO]
```

### Velocity (Issues fechadas)
```bash
# Última semana
gh issue list --state closed --search "closed:>=YYYY-MM-DD" --repo [OWNER]/[REPO]

# Por épico
gh issue list --state closed --milestone "M1: [Epic]" --repo [OWNER]/[REPO]
```

### CI/CD Status
```bash
# Ver últimos workflow runs
gh run list --repo [OWNER]/[REPO]

# Ver run específico
gh run view [RUN_ID] --repo [OWNER]/[REPO]
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
- [ ] **Milestone M0 criado** via GitHub UI ⚠️ MANUAL
  - [ ] M0: Discovery Foundation (30s)
- [ ] **Epic issue template criado** ✅ AUTOMATED
  - [ ] `.github/ISSUE_TEMPLATE/10-epic.yml` (GitHub form)
- [ ] **CI/CD Workflows criados** ✅ AUTOMATED
  - [ ] `ci-backend.yml` (customizado do PE-00)
  - [ ] `ci-frontend.yml` (customizado do PE-00)
  - [ ] `security.yml` (languages do PE-00)
- [ ] **Dependabot** ⚠️ OPTIONAL
  - [ ] Config file criado OU
  - [ ] Habilitado via GitHub UI (Settings → Security)
- [ ] **Manual steps documentados**
  - [ ] Milestones via UI
  - [ ] Epic issues via form template
  - [ ] Merge strategy (Create merge commit)
- [ ] **Branch strategy documentada**
  - [ ] Naming conventions
  - [ ] PR workflow discipline
  - [ ] Merge strategy

### Per Epic (GM - Por Iteração)

- [ ] **Milestone criado** via GitHub UI ⚠️ MANUAL
  - [ ] M1, M2, etc conforme necessário (30s cada)
- [ ] **Epic issue criada** via GitHub form ⚠️ USER ACTION
  - [ ] APÓS DE-01 completo
  - [ ] User fills form with DE-01 details (2min)
  - [ ] Assigned to milestone
  - [ ] Labels: epic, BC, priority (manual ou automation)

---

## 🔗 Referências

### Documentos Consultados
- **SDA-01 Event Storming:** [00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md](00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md) - Epics para labels/milestones
- **SDA-02 Context Map:** [00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md](00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md) - BCs para labels
- **PE-00 Environments Setup:** [00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md](00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md) - Stack para CI/CD

### Scripts Criados
- [03-github-manager/setup-labels.sh](../../../03-github-manager/setup-labels.sh) ✅ ONE-TIME
- [03-github-manager/README.md](../../../03-github-manager/README.md)

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
**Última atualização:** [YYYY-MM-DD]
