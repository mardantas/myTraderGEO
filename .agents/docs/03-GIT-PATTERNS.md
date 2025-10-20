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
7. [🔍 Git Log Recomendado](#git-log-recomendado)
8. [🏷️ Milestones e Tags](#milestones-e-tags)
   - [Milestones (GitHub)](#milestones-github-issuesprojects)
   - [Tags (Git/Releases)](#tags-gitreleases)
   - [Comparação: Milestone vs Tag](#comparação-milestone-vs-tag)
   - [Workflow Completo (Milestone + Tag)](#workflow-completo-milestone--tag)

### **Boas Práticas**
9. [🚫 O Que NÃO Fazer](#o-que-não-fazer)
10. [✅ Checklist de Qualidade](#checklist-de-qualidade)

### **Guias Operacionais**
11. [📋 GUIA OPERACIONAL: Encerrar Discovery Foundation](#guia-operacional-encerrar-discovery-foundation)
12. [📋 GUIA OPERACIONAL: Iniciar Novo Épico](#guia-operacional-iniciar-novo-épico)
    - [FASE 1: Modelagem Tática (DE)](#fase-1-modelagem-tática-de)
    - [FASE 2: GitHub Setup (GM)](#fase-2-github-setup-gm)
    - [FASE 3: Git Workflow](#fase-3-git-workflow-você)
    - [FASE 4: Implementação](#fase-4-implementação-iterativa)
    - [FASE 5: Encerramento](#fase-5-encerramento)

### **Referências**
13. [🎯 Quem Faz O Quê?](#quem-faz-o-quê)

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

### **Exemplos**

#### Discovery Foundation
```bash
git checkout develop
git checkout -b feature/discovery-foundation

git commit --allow-empty -m "chore: Início de uma nova feature

Feature: Discovery Foundation
Issue: #1

Este commit marca o início do trabalho na feature de Discovery Foundation."

git push origin feature/discovery-foundation -u

# Criar PR Draft imediatamente
gh pr create --draft --title "[EPIC-00] Discovery Foundation" --body "🚧 WIP - Ref #1"
```

#### Épico Funcional
```bash
git checkout develop
git checkout -b feature/epic-01-criar-estrategia

git commit --allow-empty -m "chore: Início de uma nova feature

Feature: Criar Estratégia Bull Call Spread
Issue: #5

Este commit marca o início do trabalho no épico de criação de estratégias."

git push origin feature/epic-01-criar-estrategia -u
```

### **Justificativa**

1. ✅ **Marco temporal claro** no histórico Git
2. ✅ **Rastreabilidade** - vincula feature à Issue
3. ✅ **Consistência** - todas as features seguem o mesmo padrão
4. ✅ **Facilita git log** - identifica início de cada feature
5. ✅ **Permite rollback preciso** - sabe onde a feature começou

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

#### SDA (Strategic Domain Analyst)
```bash
git commit -m "SDA: Modelagem estratégica completa

- SDA-01-Event-Storming.md (15 domain events)
- SDA-02-Context-Map.md (5 Bounded Contexts)
- SDA-03-Ubiquitous-Language.md (glossário inicial)

Ref #1"
```

#### DE (Domain Engineer)
```bash
git commit -m "DE: Modelagem tática do épico Criar Estratégia

- DE-01-CreateStrategy-Domain-Model.md
- Aggregates: Strategy, Position, Asset
- Domain Events: StrategyCreated, PositionOpened
- Use Cases: CreateStrategy, CalculateGreeks

Ref #5"
```

#### SE (Software Engineer)
```bash
git commit -m "SE: Implementação domain layer - Criar Estratégia

- Strategy Aggregate com invariantes
- Position Value Object
- StrategyRepository interface
- Domain Services: GreeksCalculator
- Testes unitários (cobertura 85%)

Ref #5"
```

#### FE (Frontend Engineer)
```bash
git commit -m "FE: UI para criação de estratégias

- StrategyForm component
- PositionTable component
- Integração com API CreateStrategy
- Validações client-side
- Testes de componente (React Testing Library)

Ref #5"
```

#### QAE (Quality Assurance Engineer)
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

1. **Via GitHub UI (Recomendado)**
   - Acesse a PR no GitHub
   - Clique em "Merge pull request"
   - Escolha "**Create a merge commit**" (equivalente a `--no-ff`)
   - Confirme o merge

2. **Via GitHub CLI**
   ```bash
   gh pr merge --merge --delete-branch
   ```

3. **Manual (apenas se não houver PR)**
   ```bash
   git merge <branch> --no-ff -m "Mensagem do merge"
   ```

### **Discovery Foundation (Issue #1)**

```bash
# Merge via PR com merge commit (preserva histórico de 6+ commits)
# GitHub UI: Escolha "Create a merge commit"
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

Cada deliverable tem sua própria branch e PR. Merges feitos via PR:

```bash
# Cada agente cria PR e faz merge via GitHub
# Todos usando "Create a merge commit" (--no-ff)

# DE: Domain Model
gh pr merge --merge

# DBA: Schema Review
gh pr merge --merge

# SE: Backend Implementation
gh pr merge --merge

# UXD: Wireframes
gh pr merge --merge

# FE: Frontend Implementation
gh pr merge --merge

# QAE: Quality Gate (última - fecha o épico)
gh pr merge --merge
```

**Estratégia:** Sempre usar "Create a merge commit" (equivalente a `--no-ff`) para preservar contexto histórico

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

<a id="git-log-recomendado"></a>
## 🔍 Git Log Recomendado

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

### **🎯 Milestones (GitHub Issues/Projects)**

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
...
```

**Quando criar:**
- ✅ **Sob demanda** (um por vez, quando iniciar o épico)
- ✅ M0 → Criado durante Discovery Foundation
- ✅ M1 → Criado no Dia 2 do EPIC-01 (após DE-01 completo)
- ✅ M2 → Criado no Dia 2 do EPIC-02 (após DE-02 completo)
- ❌ **NÃO criar todos de uma vez** - épicos futuros podem mudar de escopo

**Como criar:**

1. **Via Script (Automático pelo GM)**
   ```bash
   ./03-github-manager/scripts/create-milestone.sh \
     1 \
     "EPIC-01 - Criar Estratégia Bull Call Spread" \
     "Descrição do épico" \
     "2026-02-28"
   ```

2. **Via GitHub CLI**
   ```bash
   gh api repos/OWNER/REPO/milestones -X POST \
     -f title="M1: EPIC-01 - Criar Estratégia" \
     -f description="Epic description" \
     -f due_on="2025-12-31T23:59:59Z" \
     -f state="open"
   ```

3. **Via GitHub UI** (30s - mais simples)
   ```
   GitHub → Issues → Milestones → New Milestone
   Title: M1: EPIC-01 - Criar Estratégia
   Due date: 2025-12-31
   ```

**Relação com Épicos:**
- 1 Milestone = 1 Épico
- Milestone agrupa **TODAS** as issues do épico:
  ```
  M1: EPIC-01 - Criar Estratégia
  ├── Issue #5: [EPIC-01] Criar Estratégia (épico pai)
  ├── Issue #6: DE: Domain Model
  ├── Issue #7: DBA: Schema Review
  ├── Issue #8: SE: Backend Implementation
  ├── Issue #9: UXD: Wireframes
  ├── Issue #10: FE: Frontend Implementation
  └── Issue #11: QAE: Quality Gate

  Progresso: 5/7 completas (71%)
  Due Date: 2025-11-30
  Status: Open
  ```

**Quando fechar:**
- ✅ Quando **todas as issues** do milestone estão completas
- ✅ Após merge do épico para `develop`
- ✅ Antes de criar a release/tag

**Fechar milestone:**
```bash
# Via GitHub CLI
gh api repos/OWNER/REPO/milestones/1 -X PATCH -f state=closed

# Via GitHub UI
GitHub → Issues → Milestones → M1 → Close milestone
```

---

### **🏷️ Tags (Git/Releases)**

**O que são:**
- Marcadores de versões específicas do código no Git
- Imutáveis (sempre apontam para o mesmo commit)
- Usadas para releases em produção
- Vivem no Git (não no GitHub Issues)

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
- ✅ Geralmente após épico completo e deploy em produção
- ✅ Após smoke test em staging passar

**Como criar:**

1. **Via Git + GitHub CLI (Recomendado)**
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

   # 4. Criar GitHub Release com changelog
   gh release create v1.0.0 \
     --title "v1.0.0 - EPIC-01: Criar Estratégia" \
     --notes "Changelog baseado nas issues do M1"
   ```

2. **Via GitHub UI**
   ```
   GitHub → Releases → Create a new release
   Choose tag: v1.0.0 (create new tag)
   Title: v1.0.0 - EPIC-01: Criar Estratégia
   Description: [Changelog do épico]
   Publish release
   ```

**Usar em deploy:**
```bash
# Deploy referencia a tag específica
docker build -t myapp:v1.0.0 .
kubectl set image deployment/myapp myapp=myapp:v1.0.0

# Rollback para versão anterior
kubectl set image deployment/myapp myapp=myapp:v0.1.0
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
| **Visível em** | GitHub Projects | Git log, Releases |
| **Usado para** | Tracking, Velocity | Deploy, Rollback |
| **Criado por** | GM (automaticamente) | Desenvolvedor (manualmente) |
| **Tem data?** | Sim (due date) | Não (apenas timestamp) |

---

### **🔄 Workflow Completo (Milestone + Tag)**

**Linha do tempo de um épico:**

```bash
# ==============================
# DIA 1: MODELAGEM (DE)
# ==============================
# DE cria DE-01-EPIC-01-CreateStrategy-Domain-Model.md

# ==============================
# DIA 2: GITHUB SETUP (GM)
# ==============================
# GM cria MILESTONE M1
./03-github-manager/scripts/create-milestone.sh \
  1 "EPIC-01 - Criar Estratégia" "..." "2025-11-30"

# GM cria ISSUE épico #5 vinculada a M1
./03-github-manager/scripts/create-epic-issue.sh \
  1 "M1: EPIC-01 - Criar Estratégia"

# ==============================
# DIA 3-10: IMPLEMENTAÇÃO
# ==============================
# Criar issues para cada agente, todas vinculadas a M1
gh issue create --title "DE: Domain Model" --milestone "M1: EPIC-01" --label "agent:DE"
gh issue create --title "DBA: Schema Review" --milestone "M1: EPIC-01" --label "agent:DBA"
gh issue create --title "SE: Backend" --milestone "M1: EPIC-01" --label "agent:SE"
gh issue create --title "UXD: Wireframes" --milestone "M1: EPIC-01" --label "agent:UXD"
gh issue create --title "FE: Frontend" --milestone "M1: EPIC-01" --label "agent:FE"
gh issue create --title "QAE: Quality Gate" --milestone "M1: EPIC-01" --label "agent:QAE"

# Trabalho no épico... issues sendo fechadas...
# Progresso visível: M1 (3/7 completas → 5/7 completas → 7/7 completas)

# ==============================
# DIA 10: FIM DO ÉPICO
# ==============================
# QAE aprova → Merge PR para develop
gh pr merge --merge --delete-branch

# ✅ FECHAR MILESTONE M1 (todas issues completas)
gh api repos/OWNER/REPO/milestones/1 -X PATCH -f state=closed

# ==============================
# DIA 11: RELEASE PARA PRODUÇÃO
# ==============================
# Deploy staging → smoke test → aprovado

# Merge develop → main (via PR)
gh pr create --base main --head develop --title "Release: EPIC-01"
gh pr merge --merge

# ✅ CRIAR TAG v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0: EPIC-01 - Criar Estratégia

Features:
- Criação de estratégias Bull Call Spread
- Cálculo automático de Greeks

Closes #5"

git push origin v1.0.0

# ✅ CRIAR GITHUB RELEASE
gh release create v1.0.0 \
  --title "v1.0.0 - EPIC-01: Criar Estratégia" \
  --notes "Changelog:
- Criação de estratégias Bull Call Spread
- Cálculo automático de Greeks
- Dashboard de estratégias

Issues fechadas: #5, #6, #7, #8, #9, #10, #11
Milestone: M1 (7/7 completas)"

# Deploy production
# PE: docker-compose -f docker-compose.prod.yml up -d
```

---

### **✅ Checklist: Milestones e Tags**

**Ao iniciar épico:**
- [ ] ✅ DE-01 criado e mergeado em `develop`
- [ ] ✅ GM criou Milestone M{N}
- [ ] ✅ GM criou Issue épico #{N}
- [ ] ✅ Issue customizada com detalhes do DE-01
- [ ] ✅ Todas as issues do épico vinculadas ao Milestone M{N}

**Ao finalizar épico:**
- [ ] ✅ Todas as issues do Milestone M{N} fechadas
- [ ] ✅ PR mergeada para `develop`
- [ ] ✅ Milestone M{N} fechado
- [ ] ✅ Deploy staging + smoke test aprovado
- [ ] ✅ PR de `develop` → `main` criada e mergeada
- [ ] ✅ Tag v{X.Y.Z} criada
- [ ] ✅ GitHub Release criada com changelog
- [ ] ✅ Deploy production executado

**Referências:**
- Para detalhes completos sobre Milestones: [GM-00-GitHub-Setup.md](../../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md)
- Para scripts de automação: [03-github-manager/README.md](../../03-github-manager/README.md)

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
- [ ] Validações executadas (`.agents/scripts/validate-*.ps1`)?

---

<a id="guia-operacional-encerrar-discovery-foundation"></a>
## 📋 GUIA OPERACIONAL: Encerrar Discovery Foundation

### **Contexto**
Você está na branch `feature/discovery-foundation` e completou todos os deliverables (SDA, UXD, PE, SEC, QAE, GM).

### **Passo a Passo Completo**

```bash
# ====================================
# 1. VERIFICAR COMPLETUDE
# ====================================

# Listar deliverables criados
ls -la 00-doc-ddd/02-strategic-design/  # SDA-01, SDA-02, SDA-03
ls -la 00-doc-ddd/03-ux-design/         # UXD-00
ls -la 00-doc-ddd/07-github-management/ # GM-00
ls -la 00-doc-ddd/08-platform-engineering/ # PE-00
ls -la 00-doc-ddd/09-security/          # SEC-00
ls -la 00-doc-ddd/06-quality-assurance/ # QAE-00

# Executar validações
.\.agents\scripts\validate-structure.ps1
.\.agents\scripts\validate-nomenclature.ps1

# ====================================
# 2. COMMIT FINAL (Closes #1)
# ====================================

git add .
git commit -m "docs: Discovery Foundation completa

Todos os deliverables finalizados:
- SDA-01-Event-Storming.md (15 domain events, 5 BCs)
- SDA-02-Context-Map.md (relações entre BCs documentadas)
- SDA-03-Ubiquitous-Language.md (glossário 30+ termos)
- UXD-00-Design-Foundations.md (cores, tipografia, componentes base)
- GM-00-GitHub-Setup.md (labels, CI/CD, templates)
- PE-00-Environments-Setup.md (Docker Compose dev/stage/prod)
- SEC-00-Security-Baseline.md (OWASP Top 3, LGPD mínimo)
- QAE-00-Test-Strategy.md (estratégia de testes)

Validações executadas com sucesso.

Closes #1"

git push origin feature/discovery-foundation

# ====================================
# 3. ATUALIZAR PR PARA "READY FOR REVIEW"
# ====================================

# Opção A: Via GitHub CLI
gh pr ready

# Opção B: Via GitHub UI
# 1. Acesse a PR no GitHub
# 2. Clique em "Ready for review"
# 3. Marque todos os checkboxes como completos

# ====================================
# 4. MERGE PARA DEVELOP (VIA PR)
# ====================================

# Opção A: Via GitHub UI (Recomendado)
# 1. Acesse a PR no GitHub
# 2. Espere aprovação (se houver revisor)
# 3. Clique em "Merge pull request"
# 4. Escolha "Create a merge commit" (equivalente a --no-ff)
# 5. Confirme o merge
# 6. (Opcional) Delete a branch via UI

# Opção B: Via GitHub CLI
gh pr merge --merge --delete-branch

# Opção C: Merge Manual (apenas se não houver PR)
# ⚠️ Use apenas se por algum motivo não criou PR
git checkout develop
git pull origin develop
git merge feature/discovery-foundation --no-ff -m "Merge: Discovery Foundation

Completa fase de Discovery com todos os deliverables:
- Modelagem estratégica (SDA)
- Design foundations (UXD)
- GitHub setup (GM)
- Ambientes dev/stage/prod (PE)
- Security baseline (SEC)
- Test strategy (QAE)

Closes #1"
git push origin develop

# ====================================
# 5. (OPCIONAL) MERGE PARA MAIN - RELEASE
# ====================================

# Fazer isso apenas se Discovery é marco importante
# (Ex: v0.1.0 - Fundação do Projeto)

# Opção A: Via GitHub UI (Recomendado)
# 1. Crie uma PR de develop → main
# 2. Título: "Release: Discovery Foundation Complete (v0.1.0)"
# 3. Faça o merge via "Create a merge commit"
# 4. Após merge, crie tag via GitHub Releases

# Opção B: Via GitHub CLI
# Criar PR de develop para main
gh pr create \
  --base main \
  --head develop \
  --title "Release: Discovery Foundation Complete (v0.1.0)" \
  --body "Primeira release do projeto com fundação DDD estabelecida."

# Fazer merge da PR
gh pr merge --merge

# Criar release com tag
gh release create v0.1.0 \
  --title "v0.1.0 - Discovery Foundation" \
  --notes "Primeira release do projeto com fundação DDD estabelecida."

# Opção C: Merge Manual (apenas se não usar PR)
# ⚠️ Use apenas se por algum motivo não criou PR
git checkout main
git pull origin main
git merge develop --no-ff -m "Release: Discovery Foundation Complete (v0.1.0)

Primeira release do projeto com fundação DDD estabelecida.

Deliverables:
- Strategic design (BCs, Context Map, Ubiquitous Language)
- UX foundations
- Infrastructure baseline
- Security baseline
- Test strategy

Próximo passo: Iniciar épicos funcionais."

git tag v0.1.0
git push origin main --tags

# ====================================
# 6. (OPCIONAL) DELETAR BRANCH FEATURE
# ====================================

# Local
git branch -d feature/discovery-foundation

# Remote
git push origin --delete feature/discovery-foundation

# ====================================
# 7. VERIFICAR ESTADO FINAL
# ====================================

git checkout develop
git log --oneline --graph -n 10

# Deve mostrar merge commit da Discovery
```

### **Checklist de Verificação**

- [ ] ✅ Todos os 7+ deliverables completos
- [ ] ✅ Scripts de validação passam
- [ ] ✅ Commit final com `Closes #1`
- [ ] ✅ Push para remote
- [ ] ✅ PR marcada "ready for review"
- [ ] ✅ PR aprovada (se aplicável)
- [ ] ✅ Merge para `develop` com `--no-ff`
- [ ] ✅ (Opcional) Merge para `main` + tag v0.1.0
- [ ] ✅ (Opcional) Branch deletada
- [ ] ✅ Issue #1 fechada automaticamente
- [ ] ✅ Estado do git verificado (`git log`)

---

<a id="guia-operacional-iniciar-novo-épico"></a>
## 📋 GUIA OPERACIONAL: Iniciar Novo Épico

### **Contexto**
Discovery completa. Você quer iniciar EPIC-01 (ex: "Criar Estratégia").

### **Passo a Passo Completo**

```bash
# ====================================
# FASE 1: MODELAGEM TÁTICA (DE)
# ====================================

# DE cria o domain model do épico
# Arquivo: 00-doc-ddd/04-tactical-design/DE-01-EPIC-01-CreateStrategy-Domain-Model.md

# =====================================
# ESCOLHA UMA ABORDAGEM:
# =====================================

# -------------------------------------
# OPÇÃO A: Branch Separada (Recomendado)
# -------------------------------------
# ✅ Quando usar:
#    - Equipes 3+ devs (permite review do DE-01)
#    - Quer rastreabilidade completa
#    - Segue regra "nunca commit direto em develop"
#
# ✅ Vantagens:
#    - DE-01 tem sua própria branch e histórico
#    - GM lê DE-01 de develop (estável)
#    - DE-01 pode ser revisado antes de criar issue
#    - Separação clara: modelagem → issue → implementação

git checkout develop
git pull origin develop

# 1. Criar branch específica para modelagem
git checkout -b feature/epic-01-domain-model

# 2. Invocar: "DE, modele o épico 'Criar Estratégia' nos BCs Strategy + MarketData"
# DE cria o arquivo

# 3. Commit do DE
git add 00-doc-ddd/04-tactical-design/DE-01-EPIC-01-CreateStrategy-Domain-Model.md
git commit -m "DE: Modelo de domínio épico Criar Estratégia

- Aggregates: Strategy, Position, Asset
- Domain Events: StrategyCreated, PositionOpened
- Use Cases: CreateStrategy, ValidateStrategy, CalculateGreeks
- Repository interfaces

Ref #1"

git push origin feature/epic-01-domain-model -u

# 4. Criar PR para review do DE-01
gh pr create \
  --title "DE: Modelo de domínio EPIC-01" \
  --body "Domain model para review antes de criar issue. Ref #1" \
  --base develop \
  --head feature/epic-01-domain-model

# 5. Fazer merge da PR (após review ou skip se solo dev)
# Opção 5A: Via GitHub UI
# 1. Acesse a PR no GitHub
# 2. Clique em "Merge pull request"
# 3. Escolha "Create a merge commit"
# 4. (Opcional) Delete a branch via UI

# Opção 5B: Via GitHub CLI
gh pr merge --merge --delete-branch

# -------------------------------------
# OPÇÃO B: Direto em Develop (Pragmático)
# -------------------------------------
# ✅ Quando usar:
#    - Solo dev ou equipe muito pequena (1-2 devs)
#    - MVP rápido (sem necessidade de review de doc)
#    - Confiança total na modelagem do DE
#
# ⚠️ Desvantagens:
#    - Viola regra "nunca commit direto em develop"
#    - Sem review antes de criar issue
#    - Menos rastreabilidade

git checkout develop
git pull origin develop

# 1. Invocar: "DE, modele o épico 'Criar Estratégia' nos BCs Strategy + MarketData"
# DE cria o arquivo

# 2. Commit direto em develop
git add 00-doc-ddd/04-tactical-design/DE-01-EPIC-01-CreateStrategy-Domain-Model.md
git commit -m "DE: Modelo de domínio épico Criar Estratégia

- Aggregates: Strategy, Position, Asset
- Domain Events: StrategyCreated, PositionOpened
- Use Cases: CreateStrategy, ValidateStrategy, CalculateGreeks
- Repository interfaces"

git push origin develop

# =====================================
# CONTINUAR COM FASE 2 (GM)
# =====================================
# A partir daqui, o fluxo é idêntico para ambas as opções

# ====================================
# FASE 2: GITHUB SETUP (GM)
# ====================================

# Você invoca GM:
# "GM, crie milestone e issue para EPIC-01 baseado em DE-01-EPIC-01-CreateStrategy-Domain-Model.md"

# GM executa automaticamente:
# 1. Lê DE-01 para extrair: Epic name, description, BCs, objectives
# 2. Executa: ./03-github-manager/scripts/create-milestone.sh
./03-github-manager/scripts/create-milestone.sh \
  1 \
  "EPIC-01 - Criar Estratégia Bull Call Spread" \
  "Catálogo de templates, criação de estratégias, cálculos automáticos" \
  "2026-02-28"

# Output: Milestone M1 created

# 3. Executa: ./03-github-manager/scripts/create-epic-issue.sh
./03-github-manager/scripts/create-epic-issue.sh \
  1 \
  "M1: EPIC-01 - Criar Estratégia Bull Call Spread"

# Output: Issue #5 created

# 4. GM te guia:
# "✅ Milestone M1 criada. Issue #5 criada.
#  ⚠️  PRÓXIMO PASSO: Customize Issue #5 no GitHub (adicione detalhes do DE-01).
#     Tempo estimado: 1min"

# Você vai no GitHub:
# - Edita Issue #5
# - Adiciona objetivos completos do DE-01
# - Adiciona critérios de aceitação do DE-01
# - Adiciona labels: bc:strategy, bc:market-data

# ====================================
# FASE 3: GIT WORKFLOW (VOCÊ)
# ====================================

# Garantir que está na develop atualizada
git checkout develop
git pull origin develop

# Criar branch do épico
git checkout -b feature/epic-01-criar-estrategia

# Commit inicial OBRIGATÓRIO (padrão do workflow)
git commit --allow-empty -m "chore: Início de uma nova feature

Feature: Criar Estratégia Bull Call Spread
Issue: #5

Este commit marca o início do trabalho no épico de criação de estratégias."

# Push da branch
git push origin feature/epic-01-criar-estrategia -u

# Criar PR Draft
gh pr create \
  --draft \
  --base develop \
  --head feature/epic-01-criar-estrategia \
  --title "[EPIC-01] Criar Estratégia" \
  --body "## 🚧 Work in Progress

Épico: Criar Estratégia Bull Call Spread
Issue: #5

### Deliverables
- [x] DE-01-CreateStrategy-Domain-Model.md (já existe)
- [ ] DBA-01-CreateStrategy-Schema-Review.md
- [ ] UXD-01-CreateStrategy-Wireframes.md
- [ ] Backend (SE) - Domain + Application + Infrastructure + API
- [ ] Frontend (FE) - UI para criação de estratégias
- [ ] Tests (QAE) - Integration + E2E

### BCs Envolvidos
- bc:strategy
- bc:market-data

### Progresso
- [x] DE: Domain Model
- [ ] GM: Issue criada (#5)
- [ ] DBA: Schema Review
- [ ] SE: Backend Implementation
- [ ] UXD: Wireframes
- [ ] FE: Frontend Implementation
- [ ] QAE: Quality Gate

Ref #5"

# ====================================
# FASE 4: IMPLEMENTAÇÃO (Iterativa)
# ====================================

# DIA 2-3: DBA
# "DBA, revise schema do épico Criar Estratégia (baseado em DE-01)"
git add 00-doc-ddd/05-database-design/DBA-01-CreateStrategy-Schema-Review.md
git commit -m "DBA: Schema review épico Criar Estratégia

- Validação de schema do DE-01
- Migrations EF Core criadas
- Índices sugeridos (StrategyId, UserId)
- Performance review (ok para MVP)

Ref #5"
git push

# DIA 3-6: SE (Backend)
# "SE, implemente backend do épico Criar Estratégia (baseado em DE-01)"
git add 02-backend/src/Domain/Strategy/*
git add 02-backend/src/Application/Strategy/*
git add 02-backend/src/Infrastructure/Strategy/*
git add 02-backend/src/Api/Controllers/StrategyController.cs
git add 02-backend/tests/unit/Strategy/*
git commit -m "SE: Implementação backend épico Criar Estratégia

Domain Layer:
- Strategy Aggregate com invariantes
- Position Value Object
- StrategyCreated Domain Event

Application Layer:
- CreateStrategyCommand + Handler
- ValidateStrategyCommand + Handler
- DTOs (CreateStrategyRequest, StrategyResponse)

Infrastructure:
- StrategyRepository (EF Core)
- Migrations

API:
- StrategyController (POST /api/v1/strategies)
- OpenAPI/Swagger docs

Tests:
- Unit tests (cobertura 87%)

Ref #5"
git push

# DIA 3-6: UXD (Wireframes) - EM PARALELO com SE
# "UXD, crie wireframes do épico Criar Estratégia"
git add 00-doc-ddd/03-ux-design/UXD-01-CreateStrategy-Wireframes.md
git commit -m "UXD: Wireframes épico Criar Estratégia

- Modal: Criar Estratégia (form + validações)
- Tabela de estratégias criadas
- Detalhes da estratégia (Greeks, P&L)
- States: loading, success, error
- Responsividade mobile

Ref #5"
git push

# DIA 7-9: FE (Frontend)
# "FE, implemente UI do épico Criar Estratégia (usando UXD-01)"
git add 01-frontend/src/components/Strategy/*
git add 01-frontend/src/pages/StrategyPage.tsx
git add 01-frontend/src/services/strategyService.ts
git add 01-frontend/tests/Strategy/*
git commit -m "FE: UI para criação de estratégias

Components:
- StrategyForm (modal)
- StrategyTable (listagem)
- StrategyDetails (visualização)

Services:
- strategyService (API integration)

Tests:
- Component tests (React Testing Library)

Ref #5"
git push

# DIA 10: QAE (Quality Gate)
# "QAE, execute quality gate do épico Criar Estratégia"
git add 02-backend/tests/integration/Strategy/*
git add 01-frontend/tests/e2e/CreateStrategy.spec.ts
git commit -m "QAE: Quality gate épico Criar Estratégia

Integration Tests:
- POST /api/v1/strategies (sucesso + falhas)
- GET /api/v1/strategies
- Validações cross-BC (Strategy + MarketData)

E2E Tests:
- Cenário: Usuário cria Bull Call Spread
- Cenário: Validação de posições inválidas
- Smoke test staging

Regression Tests:
- Discovery épicos anteriores passando

✅ Quality Gate: PASS
✅ Deploy autorizado

Closes #5"
git push

# ====================================
# FASE 5: ENCERRAMENTO
# ====================================

# Marcar PR como ready for review
gh pr ready

# Opção A: Merge via GitHub UI (Recomendado)
# 1. Acesse a PR no GitHub
# 2. Espere aprovação do QAE (ou revisor)
# 3. Clique em "Merge pull request"
# 4. Escolha "Create a merge commit" (equivalente a --no-ff)
# 5. Confirme o merge
# 6. Issue #5 fechada automaticamente (devido ao "Closes #5" no commit)
# 7. (Opcional) Delete a branch via UI

# Opção B: Merge via GitHub CLI
gh pr merge --merge --delete-branch

# Opção C: Merge Manual (apenas se não houver PR)
# ⚠️ Use apenas se por algum motivo não criou PR
git checkout develop
git pull origin develop
git merge feature/epic-01-criar-estrategia --no-ff -m "Merge: EPIC-01 - Criar Estratégia

Funcionalidade completa de criação de estratégias implementada.

Deliverables:
- DE-01: Domain Model
- DBA-01: Schema Review + Migrations
- UXD-01: Wireframes
- Backend: Domain + Application + Infrastructure + API
- Frontend: UI completa
- Tests: Unit + Integration + E2E

Quality Gate: PASS ✅

Closes #5"
git push origin develop

# Deploy staging (PE)
# PE: docker compose -f docker-compose.staging.yml up -d

# Smoke test staging (QAE)

# (Opcional) Se aprovado em staging, promover para main/production
# Criar PR de develop → main
gh pr create \
  --base main \
  --head develop \
  --title "Release: EPIC-01 - Criar Estratégia" \
  --body "Release do EPIC-01 para produção após aprovação em staging."

# Fazer merge da PR (via UI ou CLI)
gh pr merge --merge

# Deploy production (PE)
# PE: docker compose -f docker-compose.prod.yml up -d

# ====================================
# VERIFICAR ESTADO FINAL
# ====================================

git log --oneline --graph -n 10
```

### **Checklist de Verificação**

**Fase 1: Modelagem (DE)**
- [ ] ✅ Escolhida abordagem: Opção A (branch separada) ou Opção B (direto em develop)
- [ ] ✅ DE-01-[EpicName]-Domain-Model.md criado
- [ ] ✅ Commit com `Ref #1`
- [ ] ✅ (Opção A) Branch `feature/epic-01-domain-model` criada
- [ ] ✅ (Opção A) PR criada para review (opcional)
- [ ] ✅ (Opção A) Merge para develop + branch deletada
- [ ] ✅ DE-01 está em develop (estável) para GM ler

**Fase 2: GitHub Setup (GM)**
- [ ] ✅ GM invocado: "GM, crie milestone e issue para [EpicName]"
- [ ] ✅ Milestone M{N} criada automaticamente
- [ ] ✅ Issue #{N} criada automaticamente
- [ ] ✅ Issue customizada manualmente com detalhes do DE-01

**Fase 3: Git Workflow (VOCÊ)**
- [ ] ✅ Branch `feature/epic-{N}-{name}` criada
- [ ] ✅ Commit inicial vazio (obrigatório)
- [ ] ✅ Push da branch
- [ ] ✅ PR Draft criada

**Fase 4: Implementação**
- [ ] ✅ DBA: Schema review
- [ ] ✅ SE: Backend implementation
- [ ] ✅ UXD: Wireframes (paralelo com SE)
- [ ] ✅ FE: Frontend implementation
- [ ] ✅ QAE: Quality gate (PASS ✅)

**Fase 5: Encerramento**
- [ ] ✅ PR marcada "ready for review"
- [ ] ✅ Merge para `develop`
- [ ] ✅ Deploy staging → smoke test
- [ ] ✅ Deploy production
- [ ] ✅ Issue fechada automaticamente
- [ ] ✅ Branch deletada (opcional)

---

<a id="quem-faz-o-quê"></a>
## 🎯 Quem Faz O Quê?

### **GM (GitHub Manager)**
- ✅ Cria milestone automaticamente (via script)
- ✅ Cria issue automaticamente (via script)
- ✅ Te guia para customizar issue manualmente

**GM NÃO FAZ:**
- ❌ Criar branches
- ❌ Fazer commits
- ❌ Criar PRs
- ❌ Fazer merges

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

**Versão:** 1.1
**Data:** 2025-10-20
**Workflow:** DDD com 10 Agentes
**Changelog:** Adicionados guias operacionais para encerrar Discovery e iniciar épicos
