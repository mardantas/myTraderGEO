# Padrões Git - DDD Workflow v1.0

Este documento estabelece os padrões de uso do Git no DDD Workflow.

---

## 📑 Índice

### **Fundamentos**
1. [🌳 Estrutura de Branches](#estrutura-de-branches)
2. [📝 Padrão: Commit Inicial de Feature](#padrão-commit-inicial-de-feature)
3. [🔄 Padrão de Commits por Agente](#padrão-de-commits-por-agente)
4. [📋 Nomenclatura de Branches](#nomenclatura-de-branches)
5. [🔀 Estratégias de Merge](#estratégias-de-merge)
6. [🏷️ Convenção de Mensagens de Commit](#convenção-de-mensagens-de-commit)

### **Ferramentas e Gestão**
7. [🔍 Git Log Básico](#git-log-básico)
8. [🏷️ Milestones e Tags](#milestones-e-tags)
9. [🚀 Deployment Patterns](#deployment-patterns)

### **Boas Práticas**
10. [🚫 O Que NÃO Fazer](#o-que-não-fazer)
11. [✅ Checklist de Qualidade](#checklist-de-qualidade)

### **Guias Operacionais**
12. [📋 Quick Reference: Discovery](#quick-reference-discovery)
13. [📋 Quick Reference: Épico](#quick-reference-épico)

### **Referências**
14. [🎯 Quem Faz O Quê?](#quem-faz-o-quê)
15. [📚 Mais Informações](#mais-informações)

---

<a id="estrutura-de-branches"></a>
## 🌳 Estrutura de Branches

### **Branches Principais**

```
workflow     ← Base do workflow (templates, docs, estrutura)
    ↓
  main       ← Versão estável (produção)
    ↓
 develop     ← Integração (staging)
    ↓
feature/*    ← Features/Épicos individuais
```

### **Fluxo de Merge**

```
workflow → main → develop → feature/*
```

**Regra de Ouro:** NUNCA commitar diretamente em `main` ou `develop`

---

<a id="padrão-commit-inicial-de-feature"></a>
## 📝 Padrão: Commit Inicial de Feature

### **Obrigatório para TODAS as features/épicos**

Toda branch `feature/*` deve começar com um **commit vazio** marcando o início formal da feature.

### **Formato do Commit Inicial**

```bash
git commit --allow-empty -m "chore: Início de uma nova feature

Feature: [Nome Descritivo do Épico/Feature]
Issue: #[número da issue]

Este commit marca o início do trabalho na feature [descrição breve]."
```

### **Exemplo: Discovery Foundation**

```bash
git checkout develop
git checkout -b feature/discovery-foundation

git commit --allow-empty -m "chore: Início de uma nova feature

Feature: Discovery Foundation
Issue: #1

Este commit marca o início do trabalho na feature de Discovery Foundation."

git push origin feature/discovery-foundation -u
```

### **Justificativa**

- ✅ Marco temporal claro no histórico Git
- ✅ Rastreabilidade - vincula feature à Issue
- ✅ Consistência - todas as features seguem o mesmo padrão
- ✅ Facilita rollback preciso

---

<a id="padrão-de-commits-por-agente"></a>
## 🔄 Padrão de Commits por Agente

### **Formato**

```bash
git commit -m "[AGENTE]: Descrição curta

- Detalhe 1
- Detalhe 2
- Detalhe 3

Ref #[issue-number]"
```

### **Exemplos por Agente**

#### DE (Domain Engineer)
```bash
git commit -m "DE: Modelagem tática do épico Criar Estratégia

- DE-01-CreateStrategy-Domain-Model.md
- Aggregates: Strategy, Position, Asset
- Domain Events: StrategyCreated, PositionOpened
- Use Cases: CreateStrategy, CalculateGreeks

Ref #5"
```

#### QAE (Quality Assurance Engineer) - Último Commit
```bash
git commit -m "QAE: Testes E2E épico Criar Estratégia

- Cenário: Usuário cria Bull Call Spread
- Cenário: Validação de posições inválidas
- Smoke tests staging
- Testes de regressão passando

Closes #5"
```

**Nota:** Use `Closes #N` apenas no **último commit** antes do merge (QAE ou final da feature)

---

<a id="nomenclatura-de-branches"></a>
## 📋 Nomenclatura de Branches

### **Padrão**

```
feature/[tipo]-[numero]-[nome-kebab-case]
```

### **Tipos**

- `discovery` - Fase de Discovery (Issue #1)
- `epic-NN` - Épicos funcionais
- `hotfix` - Correções urgentes
- `refactor` - Refatorações

### **Exemplos**

```
feature/discovery-foundation
feature/epic-01-criar-estrategia
feature/epic-02-calcular-greeks
feature/hotfix-strategy-validation
feature/refactor-aggregate-structure
```

---

<a id="estratégias-de-merge"></a>
## 🔀 Estratégias de Merge

**IMPORTANTE:** Todos os merges devem ser feitos **via Pull Request** no GitHub.

### **Padrão de Merge**

**Via GitHub UI (Recomendado)**
- Acesse a PR no GitHub
- Clique em "Merge pull request"
- Escolha "**Create a merge commit**" (equivalente a `--no-ff`)
- Confirme o merge

**Via GitHub CLI**
```bash
gh pr merge --merge --delete-branch
```

### **Discovery Foundation**

Merge via PR com merge commit (preserva histórico de múltiplos commits):

```bash
# GitHub CLI:
gh pr merge --merge --delete-branch
```

**Mensagem do merge commit:**
```
Merge: Discovery Foundation

Completa fase de Discovery com todos os deliverables:
- SDA: Modelagem estratégica
- UXD: Design foundations
- GM: GitHub setup
- PE: Ambientes (dev/stage/prod)
- SEC: Security baseline
- QAE: Test strategy

Closes #1
```

### **Épicos Funcionais**

**Estratégia:** Todos os agentes trabalham na **mesma branch** `feature/epic-N-nome`. O merge para `develop` acontece **apenas uma vez**, quando o épico está completo (após QAE aprovar).

**Como funciona na prática:**
1. **GM cria a branch** via `epic-start.sh` (commit vazio + PR draft)
2. **Você invoca cada agente:** "DE, modele EPIC-01" → Agente cria arquivos → Você commita e pusha
3. **Repete para todos agentes:** DBA, SE, UXD, FE, QAE (cada um commita na mesma branch)
4. **GM valida e faz merge** via `epic-deploy.sh` (após QAE aprovar)

Durante um épico, os agentes trabalham em sequência commitando na mesma branch:

```bash
# Todos os agentes commitam na mesma branch feature/epic-N-nome
# Sequência: DE → DBA → SE → UXD (paralelo com SE) → FE → QAE

git checkout feature/epic-01-criar-estrategia

# DE: Domain Model
git add 00-doc-ddd/04-tactical-design/DE-01-*.md
git commit -m "DE: Modelagem tática épico Criar Estratégia ... Ref #5"
git push

# DBA: Schema Review
git add 00-doc-ddd/05-database-design/DBA-01-*.md
git commit -m "DBA: Schema review épico Criar Estratégia ... Ref #5"
git push

# SE: Backend Implementation
git add 02-backend/src/*
git commit -m "SE: Implementação backend épico Criar Estratégia ... Ref #5"
git push

# UXD: Wireframes (paralelo com SE)
git add 00-doc-ddd/03-ux-design/UXD-01-*.md
git commit -m "UXD: Wireframes épico Criar Estratégia ... Ref #5"
git push

# FE: Frontend Implementation
git add 01-frontend/src/*
git commit -m "FE: UI para criação de estratégias ... Ref #5"
git push

# QAE: Quality Gate (último commit - fecha issue)
git add 02-backend/tests/* 01-frontend/tests/*
git commit -m "QAE: Quality gate épico Criar Estratégia ... Closes #5"
git push

# ✅ APENAS AGORA: Merge único para develop (após QAE aprovar)
gh pr ready
gh pr merge --merge --delete-branch
```

**Razões para 1 merge por épico:**
- ✅ `develop` sempre **estável** (features completas e testadas)
- ✅ **Menos overhead** de gerenciamento (1 merge vs 5-6 merges)
- ✅ **Alinhado com DDD** (bounded context completo antes do merge)
- ✅ **Ideal para equipes pequenas** e MVPs (1-2 desenvolvedores)
- ✅ **Histórico linear** na branch do épico (fácil de revisar)

**Nota:** Sempre usar "Create a merge commit" (equivalente a `--no-ff`) ao fazer merge para `develop` para preservar contexto histórico

---

<a id="convenção-de-mensagens-de-commit"></a>
## 🏷️ Convenção de Mensagens de Commit

### **Tipos (Conventional Commits)**

- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Documentação
- `refactor:` - Refatoração de código
- `test:` - Adição/modificação de testes
- `chore:` - Tarefas de manutenção
- `style:` - Formatação de código
- `perf:` - Melhorias de performance

### **Formato Completo**

```
<tipo>(<escopo>): <descrição curta>

<corpo opcional com detalhes>

<rodapé opcional com refs/closes>
```

### **Exemplos**

```bash
feat(strategy): Adiciona cálculo de Greeks em tempo real

Implementa GreeksCalculator com suporte a:
- Delta, Gamma, Theta, Vega
- Atualização a cada mudança de preço
- Cache de resultados (5s TTL)

Ref #8

---

fix(position): Corrige validação de quantidade mínima

A validação permitia quantidade 0, causando erro no cálculo
de P&L. Agora valida >= 1.

Closes #12

---

docs(readme): Atualiza seção de instalação

Adiciona instruções para Docker Compose e .env

---

chore: Início de uma nova feature

Feature: Calcular Greeks
Issue: #8

Este commit marca o início do trabalho no épico de cálculo de Greeks.
```

---

<a id="git-log-básico"></a>
## 🔍 Git Log Básico

### **Ver Histórico da Feature**

```bash
# Log da feature atual
git log --oneline --graph

# Log detalhado com diffs
git log -p

# Log apenas dos commits da feature (desde develop)
git log develop..HEAD --oneline
```

### **Verificar Sincronização**

```bash
# Ver diferenças entre branches
git diff workflow..main
git diff main..develop

# Se retornar vazio = branches sincronizadas
```

---

<a id="milestones-e-tags"></a>
## 🏷️ Milestones e Tags

### **Resumo Rápido**

**Milestones** e **Tags** trabalham **juntos** no ciclo de vida de um épico:

- **Milestone (GitHub)** → Gerencia trabalho e progresso do épico
- **Tag (Git)** → Marca versão do código quando vai para produção

**Ambos são usados**, não é um "ou" outro!

---

### **🎯 Milestones (GitHub Issues)**

**O que são:**
- Agrupadores de issues relacionadas a um épico
- Mostram progresso visual (ex: 5/15 issues completas = 33%)
- Têm data de entrega (due date)
- Vivem no GitHub (não no Git)

**Convenção de nomenclatura:**
```
M0: Discovery Foundation
M1: EPIC-01 - Criar Estratégia
M2: EPIC-02 - Calcular Greeks
M3: EPIC-03 - Nome do Épico
```

**Quando criar:**
- ✅ **Sob demanda** (um por vez, quando iniciar o épico)
- ✅ M0 → Criado durante Discovery Foundation
- ✅ M1 → Criado no Dia 2 do EPIC-01 (após DE-01 completo)
- ❌ **NÃO criar todos de uma vez** - épicos futuros podem mudar de escopo

**Relação com Épicos:**
- 1 Milestone = 1 Épico
- Milestone agrupa **TODAS** as issues do épico

**Quando fechar:**
- ✅ Quando **todas as issues** do milestone estão completas
- ✅ Após merge do épico para `develop`

---

### **🏷️ Tags (Git/Releases)**

**O que são:**
- Marcadores de versões específicas do código no Git
- Imutáveis (sempre apontam para o mesmo commit)
- Usadas para releases em produção

**Convenção: Semantic Versioning**
```
v0.1.0 - Discovery Foundation (MINOR release)
v1.0.0 - EPIC-01 completo (MAJOR release - primeira versão)
v1.1.0 - EPIC-02 completo (MINOR release - nova feature)
v1.1.1 - Bugfix crítico (PATCH release)
v2.0.0 - Breaking change (MAJOR release)
```

**Formato Semantic Versioning:**
```
vMAJOR.MINOR.PATCH

MAJOR: Breaking changes (incompatível com versão anterior)
MINOR: Nova funcionalidade (compatível com versão anterior)
PATCH: Bugfix (compatível com versão anterior)
```

**Quando criar:**
- ✅ Após merge para `main` (produção)
- ✅ Quando marcar uma release/versão
- ✅ Após smoke test em staging passar

**Como criar:**
```bash
# 1. Garantir que está na main atualizada
git checkout main
git pull origin main

# 2. Criar tag anotada
git tag -a v1.0.0 -m "Release v1.0.0: EPIC-01 - Criar Estratégia

Features:
- Criação de estratégias Bull Call Spread
- Cálculo automático de Greeks
- Dashboard de estratégias

Closes #5"

# 3. Push da tag
git push origin v1.0.0

# 4. Criar GitHub Release
gh release create v1.0.0 \
  --title "v1.0.0 - EPIC-01: Criar Estratégia" \
  --notes "Changelog baseado nas issues do M1"
```

---

### **📊 Comparação: Milestone vs Tag**

| Aspecto | Milestone | Tag |
|---------|-----------|-----|
| **Onde vive?** | GitHub Issues | Git Repository |
| **Propósito** | Gerenciar trabalho | Marcar versões |
| **Quando criar?** | Início do épico | Merge para main |
| **Quando fechar?** | Todas issues completas | N/A (imutável) |
| **Vincula a** | Issues (#5, #6, #7) | Commit específico (SHA) |
| **Mutável?** | Sim (pode reabrir) | Não (imutável) |
| **Usado para** | Tracking, Velocity | Deploy, Rollback |

---

<a id="deployment-patterns"></a>
## 🚀 Deployment Patterns

### **Local vs Remote Deployment**

**Tipos de Deployment:**
```
Development (local)    → Localhost (docker compose direto)
Staging (remote)       → Server VPS (SSH/SCP + docker compose remoto)
Production (remote)    → Server VPS (SSH/SCP + docker compose remoto)
```

### **Local Deployment (Development)**

**Características:**
- Executa na máquina do desenvolvedor
- Usa `docker compose` sem SSH/SCP
- Hot reload habilitado (backend + frontend)
- Health checks via HTTP localhost

**Comando:**
```bash
docker compose -f docker-compose.yml --env-file .env.dev up
```

### **Remote Deployment (Staging/Production)**

**Características:**
- Executa em servidor remoto via SSH
- Copia arquivos via SCP (docker-compose, traefik.yml)
- Executa `docker compose` remotamente via SSH
- Health checks via HTTPS com retry logic

**Servidor patterns:**
```bash
# Hostnames padronizados
myproject-stage     # staging
myproject-prod      # production

# Deploy scripts detectam automaticamente
./deploy.sh staging     # remote deployment
./deploy.sh production  # remote deployment
```

**Fluxo de Deploy:**
```
1. check_ssh_connection()      # Valida SSH antes
2. Copy files via SCP          # docker-compose + configs
3. SSH remote execution        # docker compose pull && up -d
4. remote_health_check()       # HTTPS (30 retries, 5s interval)
5. log_deployment_history()    # Log local
```

### **CD Pipelines**

**Staging (Auto-deploy):**
```yaml
# .github/workflows/cd-staging.yml
on:
  push:
    branches: [main]

# Auto-deploy to myproject-stage
./deploy.sh staging latest
```

**Production (Manual approval):**
```yaml
# .github/workflows/cd-production.yml
on:
  workflow_dispatch:
    inputs:
      version:  # e.g., v1.0.0

environment:
  name: production  # Requires approval

# Manual deploy to myproject-prod
./deploy.sh production ${{ inputs.version }}
```

**GitHub Secrets Required:**
- `SSH_PRIVATE_KEY_STAGING`
- `SSH_PRIVATE_KEY_PRODUCTION`
- `SSH_KNOWN_HOSTS`

### **Prerequisites for Remote Deploy**

**Server must be prepared (PE-00 setup):**
- ✅ OS: Debian/Ubuntu
- ✅ Docker Engine + Compose Plugin
- ✅ Firewall (UFW): ports 22, 80, 443
- ✅ User with docker group
- ✅ SSH keys configured
- ✅ Directory structure created
- ✅ `.env` file with secrets

**See:** PE-00-Environments-Setup.md for complete server setup guide

---

<a id="o-que-não-fazer"></a>
## 🚫 O Que NÃO Fazer

- ❌ Commitar diretamente em `main` ou `develop`
- ❌ Esquecer o commit vazio inicial
- ❌ Usar fast-forward em merges importantes (`--ff`)
- ❌ Esquecer de referenciar Issue (`Ref #N` ou `Closes #N`)
- ❌ Commits genéricos ("fix", "update", "changes")
- ❌ Commitar código sem testes
- ❌ Fazer push sem validar localmente

---

<a id="checklist-de-qualidade"></a>
## ✅ Checklist de Qualidade

Antes de fazer push:

- [ ] Commit inicial vazio existe?
- [ ] Todos os commits têm mensagem descritiva?
- [ ] Commits referenciam Issues (`Ref #N`)?
- [ ] Último commit usa `Closes #N` (se fecha issue)?
- [ ] Código está formatado?
- [ ] Testes estão passando?
- [ ] Validações executadas (`.agents/scripts/validate-*.sh`)?

---

<a id="quick-reference-discovery"></a>
## 📋 Quick Reference: Discovery

| Passo | Responsável | Ação | Invocação GM (Opcional) |
|-------|-------------|------|-------------------------|
| **1. Setup Inicial** | GitHub Actions | Cria Issue #1, Milestone M0, branch `feature/discovery-foundation`, commit vazio, PR Draft | Automático (GitHub Workflow) |
| **2. Clone** | Você | `git clone <repo>` → `git checkout feature/discovery-foundation` | Manual (não automatizável) |
| **3. Trabalho** | Agentes (SDA, UXD, PE, GM, SEC, QAE) | Criar deliverables (7 documentos) → Commit cada deliverable | **Exemplo por agente:**<br>`"SDA, faça Event Storming do myTraderGEO"`<br>→ Cria SDA-01, SDA-02, SDA-03<br>→ `git commit -m "SDA: Modelagem estratégica ... Ref #1"`<br><br>`"UXD, crie Design Foundations"`<br>→ Cria UXD-00<br>→ `git commit -m "UXD: Design Foundations ... Ref #1"`<br><br>(Repetir para GM, PE, SEC, QAE) |
| **4. Validação** | Você | Executar `bash .agents/scripts/validate-nomenclature.sh` e `validate-structure.sh` | Manual (análise de output requer humano) |
| **5. Commit Final** | Você | `git commit -m "docs: Discovery completa ... Closes #1"` | Manual (mensagem de commit requer contexto) |
| **6. PR Ready** | Você | `gh pr ready` | Manual |
| **7. Merge** | Você | Merge via GitHub UI ("Create a merge commit") | `"GM, finalize a Discovery Foundation e faça o merge"` → Executa `discovery-finish.sh --merge` |
| **8. (Opcional) Release** | Você/GM | Merge `develop → main` + tag `v0.1.0` | `"GM, crie release v0.1.0 da Discovery"` → Executa `discovery-finish.sh --release` |

**Resultado:** Issue #1 fechada, Discovery completa em `develop`

### **Automação com GM (Discovery)**

O GitHub Manager (GM) pode automatizar partes finais da Discovery:

**Passos Automatizáveis:**
- ✅ **Passo 7:** Validar deliverables + merge para develop (`discovery-finish.sh --merge`)
- ✅ **Passo 8:** Criar release v0.1.0 (`discovery-finish.sh --release`)

**Passos Manuais (requerem humano):**
- ⚠️ **Passos 1-6:** Setup, clone, criação de docs, validação, commits (requerem decisões e contexto humano)

**Invocação Típica:**
```
Você: [Completa todos os 7 deliverables de Discovery]
Você: "GM, finalize a Discovery Foundation e faça o merge"
GM: Valida deliverables (8/8) → Executa validações → Merge para develop → Fecha Issue #1
```

---

<a id="quick-reference-épico"></a>
## 📋 Quick Reference: Épico

| Fase | Responsável | Ação | Invocação GM (Opcional) |
|------|-------------|------|-------------------------|
| **1. Modelagem (DE)** | DE | **Branch temporária** para DE-01:<br>`git checkout -b feature/epic-01-domain-model`<br>→ Criar `DE-01-EPIC-01-<Nome>-Domain-Model.md`<br>→ Commit + PR + Merge para `develop`<br>→ Deletar branch | `"GM, prepare branch para DE modelar EPIC-01"` → Executa `epic-modeling-start.sh 1`<br><br>`"GM, finalize modelagem EPIC-01"` → Executa `epic-modeling-finish.sh 1` (merge + delete) |
| **2. GitHub Setup (GM)** | GM | Ler DE-01 (agora em `develop`) → Criar Milestone M{N} → Criar Issue épico #{N} (100% populada com BCs, objetivos, critérios) | `"GM, crie milestone e issue para EPIC-01"` → Lê DE-01 + Executa `epic-create.sh 1 ...` |
| **3. Branch Principal** | Você/GM | **Branch principal do épico** (onde TODOS trabalham):<br>`git checkout -b feature/epic-01-criar-estrategia`<br>→ Commit vazio → Push → PR Draft | `"GM, inicie branch do EPIC-01 'criar-estrategia'"` → Executa `epic-start.sh 1 5 "criar-estrategia"`<br>(cria branch + commit vazio + push + PR draft) |
| **4. Implementação** | Agentes | **Todos trabalham na MESMA branch** `feature/epic-01-criar-estrategia`:<br>**DBA** → Schema Review → commit + push<br>**SE** → Backend (paralelo com UXD) → commit + push<br>**UXD** → Wireframes → commit + push<br>**FE** → Frontend → commit + push<br>**QAE** → Quality Gate (testes) → commit + push (último commit com `Closes #issue`) | Cada agente invocado individualmente:<br>`"DBA, revise schema EPIC-01"`<br>`"SE, implemente backend EPIC-01"`<br>`"UXD, crie wireframes EPIC-01"`<br>`"FE, implemente UI EPIC-01"`<br>`"QAE, execute quality gate EPIC-01"` |
| **5. Deploy Staging** | Você/GM | Validar commits → PR ready → Merge para `develop` → Deploy staging | `"GM, faça deploy do EPIC-01 para staging"` → Executa `epic-deploy.sh 1`<br>(valida QAE + merge + staging) |
| **6. Release** | Você/GM | Fechar Milestone M{N} → Tag `vX.Y.Z` → GitHub Release | `"GM, feche EPIC-01 e crie release v1.0.0"` → Executa `epic-close.sh 1 --release v1.0.0` |

**Resultado:** Epic completo, Issue #{N} fechada, Milestone M{N} fechado, tag criada

### **Automação com GM**

O GitHub Manager (GM) pode automatizar grande parte do processo Git/GitHub:

**Passos Automatizáveis:**
- ✅ **Fase 1:** Criar branch de modelagem (`epic-modeling-start.sh` + `epic-modeling-finish.sh`)
- ✅ **Fase 2:** Criar milestone + issue épica 100% populada (`epic-create.sh`)
- ✅ **Fase 3:** Criar branch principal do épico (`epic-start.sh`)
- ✅ **Fase 5:** Validar + merge + deploy staging (`epic-deploy.sh`)
- ✅ **Fase 6:** Fechar milestone + criar tag/release + deploy production (`epic-close.sh --release`)

**Passos Manuais (requerem humano):**
- ⚠️ **Fase 4:** Invocar agentes individualmente (DBA, SE, UXD, FE, QAE) - cada um faz commit + push na mesma branch
- ⚠️ **Monitoramento:** Smoke tests staging (entre Fase 5 e 6)

**Invocação Típica:**
```
Você: "GM, prepare o EPIC-01 'Criar Estratégia'"
GM: [Lê DE-01] → Cria milestone M1 → Cria issue #5 com objetivos/critérios extraídos
Você: [Trabalha no épico com agentes DBA, SE, UXD, FE, QAE]
Você: "GM, finalize EPIC-01 e crie release v1.0.0"
GM: Fecha M1 → Cria tag v1.0.0 → Publica GitHub Release
```

---

<a id="quem-faz-o-quê"></a>
## 🎯 Quem Faz O Quê?

### **GM (GitHub Manager)**
- ✅ Cria milestone automaticamente (após DE-01)
- ✅ Cria issue épico automaticamente (100% populada, sem edição manual)
- ✅ Fornece scripts de automação Git/GitHub:
  - ✅ Cria branches (via `epic-start.sh`, `epic-modeling-start.sh`)
  - ✅ Cria PRs draft (via `epic-start.sh`)
  - ✅ Faz merges para develop (via `epic-deploy.sh`)
  - ✅ Cria tags e releases (via `epic-close.sh`)

**GM NÃO FAZ:**
- ❌ Fazer commits de código/documentação (exceto commit vazio inicial)
- ❌ Invocar outros agentes (DBA, SE, UXD, FE, QAE)

### **VOCÊ (Desenvolvedor/Product Owner)**
- ✅ Cria branches
- ✅ Faz commit inicial obrigatório
- ✅ Cria PRs
- ✅ Trabalha nos deliverables (invocando agentes)
- ✅ Faz merges para develop
- ✅ Deleta branches (opcional)

### **Agentes (SDA, DE, SE, etc.)**
- ✅ Criam deliverables
- ✅ Fazem commits (se você estiver usando eles via automação)

**Agentes NÃO FAZEM:**
- ❌ Gerenciar branches
- ❌ Criar PRs
- ❌ Fazer merges

---

<a id="mais-informações"></a>
## 📚 Mais Informações

Este documento apresenta os padrões Git essenciais. Para informações detalhadas:

### **Scripts de Automação**

Durante a **fase de Discovery**, o GitHub Manager (GM) criará scripts de automação em:
- `03-github-manager/scripts/` (setup-labels.sh, create-milestone.sh, create-epic-issue.sh, epic-*.sh)
- `03-github-manager/README.md` (documentação dos scripts e comandos GitHub CLI)

Os scripts automatizam:
- Setup de labels no GitHub
- Criação de milestones sob demanda
- Criação de issues épicas (100% populadas, sem edição manual)
- Workflow completo de épicos (start, finish, close)

### **Setup do GitHub**

Durante a **fase de Discovery**, o GM criará documentação completa em:
- `00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md`

Inclui:
- Estratégia de labels (41 labels: agents, BCs, tipos, prioridades, status)
- Estratégia de milestones (M0, M1, M2, ...)
- CI/CD workflows (backend, frontend, security)
- Issue templates
- Dependabot configuration

### **Outras Referências**

- [Guia de Workflow](00-Workflow-Guide.md) - Visão completa do processo DDD
- [Nomenclature Standards](../02-Nomenclature-Standards.md) - Padrões de nomenclatura
- [DDD Patterns Reference](../04-DDD-Patterns-Reference.md) - Padrões táticos de DDD
- [API Standards](../05-API-Standards.md) - Padrões de API REST

---

**Versão:** 1.0
**Data:** 2025-10-22
**Workflow:** DDD com 10 Agentes
**Changelog:**
- v1.0 (2025-10-22): Versão inicial estável
  - Documento simplificado (-70% linhas para ~600 linhas)
  - Automação completa via GM: epic-start.sh, epic-deploy.sh, epic-modeling-*.sh, epic-close.sh
  - Quick Reference com invocações GM em todas as fases automatizáveis
  - Estratégia de merge: 1 branch por épico (todos agentes trabalham na mesma branch)
  - Scripts de validação: validate-nomenclature.sh, validate-structure.sh
  - Clarificação: GM automatiza Git/GitHub (branches, PRs, merges), desenvolvedores invocam agentes e commitam código
