# GM-00-GitHub-Setup.md

**Projeto:** [PROJECT_NAME]
**Data:** [YYYY-MM-DD]
**GitHub Manager:** GM Agent
**Repository:** [GITHUB_OWNER]/[REPO_NAME]

---

## 🎯 Objetivo

Documentar a configuração completa do GitHub para o projeto, incluindo templates pré-existentes (do workflow), workflows CI/CD customizados (por stack), e scripts de automação (por projeto).

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

**Localização:** Criados via script [03-github-manager/setup-milestones.sh](../../../03-github-manager/setup-milestones.sh)

**Executar:**
```bash
cd 03-github-manager
chmod +x setup-milestones.sh
./setup-milestones.sh
```

**Milestones criados:**

| Milestone | Descrição | Due Date | Epics |
|-----------|-----------|----------|-------|
| **M0: Discovery Foundation** | SDA, UXD, GM, PE, SEC, QAE deliverables | [DISCOVERY_DUE] | Issue #1 |
| **M1: [EPIC_1_NAME]** | [Epic 1 description from SDA] | [EPIC_1_DUE] | Epic 1 issues |
| **M2: [EPIC_2_NAME]** | [Epic 2 description from SDA] | [EPIC_2_DUE] | Epic 2 issues |
| **M3: [EPIC_3_NAME]** | [Epic 3 description from SDA] | [EPIC_3_DUE] | Epic 3 issues |

*(Customize baseado no Epic Backlog priorizado do SDA)*

**Verificar:**
```bash
gh milestone list --repo [OWNER]/[REPO]
```

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

- [ ] **Labels criadas** via `setup-labels.sh`
  - [ ] Agents (10 labels)
  - [ ] Bounded Contexts (do SDA-02)
  - [ ] Epics (do SDA-01)
  - [ ] Types, Priority, Status, Phase
- [ ] **Milestones criados** via `setup-milestones.sh`
  - [ ] M0: Discovery Foundation
  - [ ] M1-MN: Epic milestones (do SDA backlog)
- [ ] **Issue #1 criada** (Discovery Foundation)
  - [ ] Usa template `00-discovery-foundation.yml`
  - [ ] Assignada ao milestone M0
- [ ] **CI/CD Workflows criados**
  - [ ] `ci-backend.yml` (customizado do PE-00)
  - [ ] `ci-frontend.yml` (customizado do PE-00)
  - [ ] `security.yml` (languages do PE-00)
- [ ] **Dependabot configurado**
  - [ ] Ecosystems do PE-00 stack
- [ ] **Branch strategy documentada**
  - [ ] Naming conventions
  - [ ] PR workflow discipline
- [ ] **Scripts documentados**
  - [ ] README.md em 03-github-manager/

### Per Epic (GM - Por Iteração)

- [ ] **Epic issue criada** via `create-epic-issue.sh`
  - [ ] APÓS DE-01 completo
  - [ ] Populated com info do DE-01
  - [ ] Assignada ao milestone correto
  - [ ] Labels corretas (epic, BC, priority)
- [ ] **Sub-issues criadas** (opcional)
  - [ ] Uma por agent (DE, DBA, SE, UXD, FE, QAE)
  - [ ] Linked ao epic issue principal

---

## 🔗 Referências

### Documentos Consultados
- **SDA-01 Event Storming:** [00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md](00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md) - Epics para labels/milestones
- **SDA-02 Context Map:** [00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md](00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md) - BCs para labels
- **PE-00 Environments Setup:** [00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md](00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md) - Stack para CI/CD

### Scripts Criados
- [03-github-manager/setup-labels.sh](../../../03-github-manager/setup-labels.sh)
- [03-github-manager/setup-milestones.sh](../../../03-github-manager/setup-milestones.sh)
- [03-github-manager/create-epic-issue.sh](../../../03-github-manager/create-epic-issue.sh)
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

### Customização Necessária
Todos os scripts em `03-github-manager/` precisam ser customizados com:
- BCs do SDA-02
- Epics do SDA-01
- Stack do PE-00
- Datas de due dates
- Owner/Repo name

### Próximos Passos
1. ✅ Discovery completo → Issue #1 fechada
2. ✅ Workflows CI/CD rodando
3. ➡️ **Próximo:** DE-01 para primeiro épico → GM cria epic issue

---

**GitHub Setup Version:** 3.0 (Simplified)
**Status:** ✅ **Executado e validado**
**Última atualização:** [YYYY-MM-DD]
