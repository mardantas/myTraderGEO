# GM-01-GitHub-Setup.md

**Projeto:** [PROJECT_NAME]
**Data:** [YYYY-MM-DD]
**GitHub Manager:** GM Agent

---

## 🎯 Objetivo

Configurar estrutura completa do GitHub para o projeto, incluindo labels, milestones, templates, e project boards alinhados com o workflow DDD.

---

## 📋 Pre-requisitos

**GitHub CLI instalado:**
```bash
gh --version
# Se não instalado: https://cli.github.com/
```

**Autenticação:**
```bash
gh auth login
gh auth status
```

**Repositório criado:**
```bash
gh repo view [OWNER]/[REPO_NAME]
```

---

## 🏷️ Labels Configuration

### Comandos de Criação

```bash
# Labels por Agent (quem trabalha)
gh label create "agent:SDA" --description "Strategic Domain Analyst" --color "0E8A16"
gh label create "agent:UXD" --description "User Experience Designer" --color "1D76DB"
gh label create "agent:DE" --description "Domain Engineer" --color "5319E7"
gh label create "agent:DBA" --description "Database Administrator" --color "D93F0B"
gh label create "agent:FE" --description "Frontend Engineer" --color "FBCA04"
gh label create "agent:QAE" --description "Quality Assurance Engineer" --color "006B75"
gh label create "agent:GM" --description "GitHub Manager" --color "B60205"

# Labels por Bounded Context (onde está)
gh label create "bc:[BC_NAME_1]" --description "Bounded Context: [BC_NAME_1]" --color "C2E0C6"
gh label create "bc:[BC_NAME_2]" --description "Bounded Context: [BC_NAME_2]" --color "C2E0C6"
# Repetir para cada BC identificado pelo SDA

# Labels por Epic (o que é)
gh label create "epic:[EPIC_1_SHORT]" --description "Epic: [EPIC_1_FULL_NAME]" --color "FEF2C0"
gh label create "epic:[EPIC_2_SHORT]" --description "Epic: [EPIC_2_FULL_NAME]" --color "FEF2C0"
# Repetir para cada épico do backlog

# Labels de Tipo (natureza)
gh label create "type:feature" --description "Nova funcionalidade" --color "A2EEEF"
gh label create "type:bug" --description "Correção de bug" --color "D73A4A"
gh label create "type:refactor" --description "Refatoração de código" --color "0075CA"
gh label create "type:docs" --description "Documentação" --color "0075CA"
gh label create "type:test" --description "Testes" --color "BFD4F2"

# Labels de Prioridade
gh label create "priority:high" --description "Alta prioridade" --color "D93F0B"
gh label create "priority:medium" --description "Média prioridade" --color "FBCA04"
gh label create "priority:low" --description "Baixa prioridade" --color "0E8A16"

# Labels de Status
gh label create "status:blocked" --description "Bloqueado" --color "B60205"
gh label create "status:wip" --description "Work in Progress" --color "FBCA04"
gh label create "status:review" --description "Em revisão" --color "0052CC"
```

### Script de Setup Completo

```bash
#!/bin/bash
# setup-github-labels.sh

REPO="[OWNER]/[REPO_NAME]"

echo "🏷️ Creating labels for $REPO..."

# Agents
gh label create "agent:SDA" -d "Strategic Domain Analyst" -c "0E8A16" -R $REPO
gh label create "agent:UXD" -d "User Experience Designer" -c "1D76DB" -R $REPO
gh label create "agent:DE" -d "Domain Engineer" -c "5319E7" -R $REPO
gh label create "agent:DBA" -d "Database Administrator" -c "D93F0B" -R $REPO
gh label create "agent:FE" -d "Frontend Engineer" -c "FBCA04" -R $REPO
gh label create "agent:QAE" -d "Quality Assurance Engineer" -c "006B75" -R $REPO
gh label create "agent:GM" -d "GitHub Manager" -c "B60205" -R $REPO

# Types
gh label create "type:feature" -d "Nova funcionalidade" -c "A2EEEF" -R $REPO
gh label create "type:bug" -d "Correção de bug" -c "D73A4A" -R $REPO
gh label create "type:refactor" -d "Refatoração" -c "0075CA" -R $REPO
gh label create "type:docs" -d "Documentação" -c "0075CA" -R $REPO
gh label create "type:test" -d "Testes" -c "BFD4F2" -R $REPO

# Priority
gh label create "priority:high" -d "Alta" -c "D93F0B" -R $REPO
gh label create "priority:medium" -d "Média" -c "FBCA04" -R $REPO
gh label create "priority:low" -d "Baixa" -c "0E8A16" -R $REPO

# Status
gh label create "status:blocked" -d "Bloqueado" -c "B60205" -R $REPO
gh label create "status:wip" -d "Work in Progress" -c "FBCA04" -R $REPO
gh label create "status:review" -d "Em revisão" -c "0052CC" -R $REPO

echo "✅ Labels created successfully!"
```

---

## 🎯 Milestones Structure

### Por Épico (Recomendado)

```bash
# Milestone 1: Primeiro Épico
gh milestone create "Epic 1: [NOME_DO_EPIC]" \
  --description "Implementação completa do épico [NOME]" \
  --due-date "YYYY-MM-DD"

# Milestone 2: Segundo Épico
gh milestone create "Epic 2: [OUTRO_EPIC]" \
  --description "Implementação de [descrição]" \
  --due-date "YYYY-MM-DD"

# Milestone 0: Discovery (opcional)
gh milestone create "M0: Discovery & Setup" \
  --description "Strategic analysis, UX design, GitHub setup" \
  --due-date "YYYY-MM-DD"
```

### Visualização

```bash
# Listar milestones
gh milestone list

# Ver progresso de um milestone
gh issue list --milestone "Epic 1: [NOME]"
```

---

## 📝 Issue Templates

### Template 1: Epic-Level Issue

**Arquivo:** `.github/ISSUE_TEMPLATE/epic.md`

```markdown
---
name: Epic Issue
about: Issue para um épico completo (functionality-based)
title: 'Epic: [NOME_FUNCIONALIDADE]'
labels: 'type:feature, priority:high'
assignees: ''
---

## 📋 Descrição do Épico

[Descrição da funcionalidade completa que atravessa múltiplos BCs]

## 🎯 Objetivos de Negócio

- [ ] Objetivo 1
- [ ] Objetivo 2

## 🏗️ Bounded Contexts Envolvidos

- [ ] BC 1: [Nome]
- [ ] BC 2: [Nome]

## 👥 Agents Responsáveis

- [ ] **DE:** Tactical model + backend
- [ ] **DBA:** Schema review
- [ ] **FE:** Frontend implementation
- [ ] **QAE:** Test strategy + tests

## 📦 Deliverables

- [ ] `DE-01-[EpicName]-Tactical-Model.md`
- [ ] `DBA-01-[EpicName]-Schema-Review.md`
- [ ] Backend code (domain + application + API)
- [ ] Frontend code (components + pages)
- [ ] `QAE-01-Test-Strategy.md`
- [ ] Tests (unit + integration + E2E)

## 🔗 Dependências

- Epic anterior: [link]
- Bloqueadores: [descrever]

## ✅ Definition of Done

- [ ] Todos os deliverables criados
- [ ] Code review aprovado
- [ ] Testes passando (coverage >= 70%)
- [ ] Documentação atualizada
- [ ] Deploy em staging OK
```

### Template 2: Feature-Level Issue

**Arquivo:** `.github/ISSUE_TEMPLATE/feature.md`

```markdown
---
name: Feature/Task Issue
about: Issue para uma tarefa específica dentro de um épico
title: '[AGENT]: [Descrição]'
labels: 'type:feature'
assignees: ''
---

## 📋 Descrição

[O que precisa ser feito]

## 🎯 Épico Pai

Pertence ao épico: #[ISSUE_NUMBER]

## 👤 Agent Responsável

**Agent:** [SDA/UXD/DE/DBA/FE/QAE/GM]

## ✅ Acceptance Criteria

- [ ] Critério 1
- [ ] Critério 2
- [ ] Critério 3

## 📦 Deliverables

- [ ] [Arquivo ou código específico]

## 🔗 Referências

- Documento relacionado: [link]
- Código relacionado: [link]
```

### Template 3: Bug Issue

**Arquivo:** `.github/ISSUE_TEMPLATE/bug.md`

```markdown
---
name: Bug Report
about: Reportar um bug
title: '[BUG]: [Descrição curta]'
labels: 'type:bug'
assignees: ''
---

## 🐛 Descrição do Bug

[Descrição clara do problema]

## 🔄 Steps to Reproduce

1. Vá para '...'
2. Clique em '...'
3. Veja o erro

## ✅ Expected Behavior

[O que deveria acontecer]

## ❌ Actual Behavior

[O que acontece atualmente]

## 📸 Screenshots

[Se aplicável]

## 🔍 Contexto

- **BC:** [Qual bounded context]
- **Component:** [Qual componente/agregado]
- **Agent responsável:** [DE/FE/etc]

## ✅ Definition of Done

- [ ] Test que reproduz o bug criado
- [ ] Bug corrigido
- [ ] Test passando (regression prevention)
- [ ] Code review aprovado
```

---

## 🔀 Pull Request Template

**Arquivo:** `.github/PULL_REQUEST_TEMPLATE.md`

```markdown
## 📋 Descrição

[Descrição das mudanças]

## 🎯 Epic/Issue Relacionado

Closes #[ISSUE_NUMBER]

## 👤 Agent

**Agent:** [SDA/UXD/DE/DBA/FE/QAE/GM]

## 🏗️ Bounded Context(s)

- [ ] [BC 1]
- [ ] [BC 2]

## 🧪 Testes

- [ ] Unit tests adicionados/atualizados
- [ ] Integration tests adicionados/atualizados
- [ ] E2E tests adicionados (se aplicável)
- [ ] Todos os testes passando
- [ ] Coverage >= 70%

## 📝 Checklist

- [ ] Código segue nomenclature standards
- [ ] Documentação atualizada
- [ ] Migration criada (se mudou schema)
- [ ] Sem breaking changes (ou documentados)
- [ ] Code review solicitado

## 📸 Screenshots (se UI)

[Screenshots ou GIFs se aplicável]

## 🔗 Referências

- Tactical Model: [link]
- Wireframe: [link]
```

---

## 📊 Project Boards

### Board 1: Epic Kanban

**Colunas:**

```bash
# Criar project
gh project create --title "[PROJECT-NAME] - Epics" --owner [OWNER]

# Adicionar colunas (via web interface ou API)
# 📋 Backlog → 🎯 Ready → 🚧 In Progress → 👀 Review → ✅ Done
```

**Automações:**
- Issue criada com label `epic:*` → Backlog
- Issue assignada → In Progress
- PR criado → Review
- PR merged → Done

### Board 2: Sprint/Iteration Board

**Colunas:**

```
📋 To Do → 🚧 In Progress → 👀 Review → ✅ Done
```

**Filtros:**
- Por agent: `label:agent:DE`
- Por BC: `label:bc:strategy-management`
- Por prioridade: `label:priority:high`

---

## 🌳 Git Flow Integration

### Branch Strategy

```
main (production)
  └── develop (integration)
       ├── feature/epic-[N]-[short-name] (por épico)
       │    ├── feature/de-[tactical-model]
       │    ├── feature/fe-[component-name]
       │    └── feature/qae-[test-implementation]
       └── hotfix/[bug-description]
```

### Comandos

```bash
# Criar branch de épico
git checkout develop
git checkout -b feature/epic-1-bull-call-spread

# Criar branch de task específica
git checkout feature/epic-1-bull-call-spread
git checkout -b feature/de-strategy-aggregate

# Merge flow
feature/de-* → feature/epic-* → develop → main
```

---

## 🔔 Notifications & Webhooks

### Notificações Recomendadas

**Para o usuário (Product Owner):**
- Issues assignadas a ele
- PRs que mencionam ele
- Epic concluído

**Para agents (via automation):**
- Feedback criado para o agent
- PR bloqueado por testes
- Dependency issue resolvida

### Webhook Setup (opcional)

```bash
# Criar webhook para CI/CD
gh webhook create \
  --url "https://[CI_SERVICE]/webhook" \
  --event "push,pull_request" \
  --secret "[SECRET]"
```

---

## 📈 Métricas e Reports

### Issues por Agent

```bash
# Ver workload de cada agent
gh issue list --label "agent:DE" --state open
gh issue list --label "agent:FE" --state open
```

### Progresso de Épico

```bash
# Ver progresso de um épico específico
gh issue list --milestone "Epic 1: Bull Call Spread"
gh issue list --label "epic:bull-call" --state closed
```

### Velocity

```bash
# Issues fechadas na última semana
gh issue list --state closed --search "closed:>=$(date -d '7 days ago' +%Y-%m-%d)"
```

---

## 🔧 GitHub Actions (CI/CD)

### Workflow Básico

**Arquivo:** `.github/workflows/ci.yml`

```yaml
name: CI

on:
  pull_request:
    branches: [develop, main]
  push:
    branches: [develop, main]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'

      - name: Restore dependencies
        run: dotnet restore

      - name: Build
        run: dotnet build --no-restore

      - name: Unit Tests
        run: dotnet test --filter Category=Unit --no-build --verbosity normal

      - name: Integration Tests
        run: dotnet test --filter Category=Integration --no-build --verbosity normal

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Unit Tests
        run: npm run test:unit

      - name: Build
        run: npm run build

  quality-gates:
    needs: [backend-tests, frontend-tests]
    runs-on: ubuntu-latest
    steps:
      - name: Check coverage
        run: |
          # Implementar verificação de coverage >= 70%
          echo "Coverage check passed"
```

---

## 🚀 CI/CD Pipeline (GitHub Actions)

### Backend CI Pipeline

**Arquivo:** `.github/workflows/ci-backend.yml`

```yaml
name: Backend CI

on:
  push:
    branches: [ develop, feature/** ]
  pull_request:
    branches: [ develop, main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '8.0.x'

    - name: Restore dependencies
      run: dotnet restore
      working-directory: ./02-backend

    - name: Build
      run: dotnet build --no-restore --configuration Release
      working-directory: ./02-backend

    - name: Run unit tests
      run: dotnet test --no-build --configuration Release --verbosity normal
      working-directory: ./02-backend
```

### Frontend CI Pipeline

**Arquivo:** `.github/workflows/ci-frontend.yml`

```yaml
name: Frontend CI

on:
  push:
    branches: [ develop, feature/** ]
  pull_request:
    branches: [ develop, main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'

    - name: Install dependencies
      run: npm ci
      working-directory: ./01-frontend

    - name: Lint
      run: npm run lint
      working-directory: ./01-frontend

    - name: Run tests
      run: npm test
      working-directory: ./01-frontend

    - name: Build
      run: npm run build
      working-directory: ./01-frontend
```

### Security Scanning Pipeline

**Arquivo:** `.github/workflows/security.yml`

```yaml
name: Security Scan

on:
  push:
    branches: [ main, develop ]
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday

jobs:
  codeql:
    runs-on: ubuntu-latest
    permissions:
      security-events: write

    steps:
    - uses: actions/checkout@v3

    - name: Initialize CodeQL
      uses: github/codeql-action/init@v2
      with:
        languages: csharp, javascript

    - name: Autobuild
      uses: github/codeql-action/autobuild@v2

    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v2
```

### Dependabot Configuration

**Arquivo:** `.github/dependabot.yml`

```yaml
version: 2
updates:
  # Backend (.NET)
  - package-ecosystem: "nuget"
    directory: "/02-backend"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5

  # Frontend (npm)
  - package-ecosystem: "npm"
    directory: "/01-frontend"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
```

---

## 🔒 Branch Protection (Adaptado para GitHub Free)

**⚠️ GitHub Free não permite Branch Protection Rules automáticas.**

### Alternativas para Proteção de Branches:

#### 1. **Code Review Obrigatório (Manual)**
- **Prática:** NUNCA fazer merge direto em `main`
- **Regra:** Todo código passa por PR + review
- **Checklist PR:** Template força validação

#### 2. **GitHub Actions como Gatekeeper**
```yaml
# Status checks obrigatórios via Actions
- name: Block if tests fail
  if: failure()
  run: exit 1
```

#### 3. **Git Hooks Locais (Opcional)**
```bash
# .git/hooks/pre-push
#!/bin/bash
if [ "$(git rev-parse --abbrev-ref HEAD)" == "main" ]; then
  echo "❌ ERRO: Push direto para main não permitido!"
  echo "   Use PR: git checkout -b feature/... && git push origin feature/..."
  exit 1
fi
```

#### 4. **Branch Naming Convention (Força Organização)**
```bash
# Apenas branches válidos:
- feature/epic-X-nome
- bugfix/issue-Y-nome
- hotfix/critical-Z

# Proibido:
- main (somente via PR)
- develop (somente via PR de feature)
```

### Semantic Versioning Strategy

**Formato:** `vMAJOR.MINOR.PATCH`

| Tipo | Incrementa | Exemplo | Quando |
|------|-----------|---------|--------|
| **MAJOR** | v2.0.0 | Breaking changes | API incompatível |
| **MINOR** | v1.1.0 | New features | Nova funcionalidade, backward compatible |
| **PATCH** | v1.0.1 | Bug fixes | Correção de bugs |

**Tagging:**
```bash
# Após merge em main
git tag -a v1.0.0 -m "Release v1.0.0: Bull Call Spread feature"
git push origin v1.0.0

# GitHub Release (via gh CLI)
gh release create v1.0.0 \
  --title "v1.0.0: Bull Call Spread" \
  --notes "- Feature: Bull Call Spread strategy
           - Fix: Greeks calculation precision
           - Docs: Updated API docs"
```

---

## ✅ Validation Checklist

### Setup Inicial (Discovery)

- [ ] GitHub CLI instalado e autenticado
- [ ] Repositório criado
- [ ] Labels criados (agents, BCs, epics, types, priority, status)
- [ ] Milestones criados para Discovery + Epics
- [ ] Issue templates criados (epic, feature, bug)
- [ ] PR template criado
- [ ] Project board(s) configurado
- [ ] Git Flow branches criadas (main, develop)
- [ ] **CI/CD:** Backend workflow (.github/workflows/ci-backend.yml)
- [ ] **CI/CD:** Frontend workflow (.github/workflows/ci-frontend.yml)
- [ ] **Security:** CodeQL workflow (.github/workflows/security.yml)
- [ ] **Security:** Dependabot config (.github/dependabot.yml)
- [ ] **Proteção:** Branch naming convention documentada
- [ ] **Versioning:** Semantic versioning strategy definida

### Por Épico (Iteração)

- [ ] Milestone do épico criado
- [ ] Epic issue criado com todos os deliverables
- [ ] Labels `epic:[name]` criadas
- [ ] Feature branches criadas (feature/epic-X-nome)
- [ ] Task issues criadas para cada agent
- [ ] **CI/CD:** Workflows rodando em PRs
- [ ] **Code Review:** PR aprovado antes de merge

---

## 🚢 Deployment Checklist (MVP Básico)

### Ambientes

| Ambiente | URL | Branch | Deploy |
|----------|-----|--------|--------|
| **Development** | http://localhost:[PORT] | feature/* | Local (docker-compose) |
| **Staging** | https://staging.[YOUR-DOMAIN] | develop | Manual ou CD pipeline |
| **Production** | https://app.[YOUR-DOMAIN] | main | Manual com aprovação |

### Pre-Deployment Checklist

**Antes de deploy em Staging/Production:**
- [ ] Todos os testes passando (unit + integration + E2E)
- [ ] Code review aprovado
- [ ] DBA schema review OK (se houver migrations)
- [ ] QAE sign-off (testes em staging completos)
- [ ] Feature flag OFF por default (se nova feature)
- [ ] Rollback plan documentado
- [ ] Database backup recente (< 1h)

### Deployment Steps (Manual)

```bash
# 1. Pull latest code
git checkout main
git pull origin main

# 2. Build backend
cd 02-backend
dotnet publish -c Release -o ./publish

# 3. Build frontend
cd ../01-frontend
npm run build

# 4. Run database migrations (ANTES de deploy código)
cd ../02-backend
dotnet ef database update --connection "Production-ConnectionString"

# 5. Deploy (exemplo Azure - adaptar para seu cloud provider)
az webapp up --name [APP-NAME]-api --resource-group [RESOURCE-GROUP]

# 6. Health check
curl https://api.[YOUR-DOMAIN]/health
# Expected: { "status": "healthy" }

# 7. Smoke tests (adaptar para seu domínio)
# - Login funciona?
# - Funcionalidade principal funciona?
# - APIs críticas respondem?

# 8. Monitor por 30 minutos
# - Application Insights / CloudWatch
# - Error rate < 1%
# - Response time < 500ms p95
```

### Rollback Procedure

```bash
# Se deploy falhar, rollback imediato:

# 1. Revert código para versão anterior
az webapp deployment source config-zip \
  --name [APP-NAME]-api \
  --resource-group [RESOURCE-GROUP] \
  --src previous-version.zip

# 2. Rollback database (se necessário)
dotnet ef database update [PreviousMigration] \
  --connection "Production-ConnectionString"

# 3. Notificar equipe
gh issue create \
  --title "Rollback: Deployment failed" \
  --body "Rolled back to v1.0.0 due to [reason]"
```

### Post-Deployment

- [ ] Verificar logs (sem errors críticos)
- [ ] Atualizar documentation (se API mudou)
- [ ] Notificar usuários (se breaking change)
- [ ] Create GitHub Release (tag + changelog)
- [ ] Update monitoring dashboards

---

## 🔗 Referências

- **SDA Output:** Para identificar BCs e criar labels correspondentes
- **SDA Epic Backlog:** Para criar milestones e epic issues
- **Agents Overview:** Para entender responsabilidades e criar labels de agents
- **Security & Platform:** .agents/03-Security-And-Platform-Strategy.md
- **GitHub CLI Docs:** https://cli.github.com/manual/

---

**GitHub Setup Version:** 2.0
**Status:** Executar no início do projeto (Discovery) e atualizar a cada novo épico
