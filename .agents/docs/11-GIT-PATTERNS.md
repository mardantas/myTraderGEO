# Padrões Git - DDD Workflow v1.0

Este documento estabelece os padrões de uso do Git no DDD Workflow.

---

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

## 🔀 Estratégias de Merge

### **Discovery Foundation (Issue #1)**

```bash
# Merge com merge commit (preserva histórico de 6+ commits)
git checkout develop
git merge feature/discovery-foundation --no-ff -m "Merge: Discovery Foundation

Completa fase de Discovery com todos os deliverables:
- SDA: Modelagem estratégica
- UXD: Design foundations
- GM: GitHub setup
- PE: Ambientes (dev/stage/prod)
- SEC: Security baseline
- QAE: Test strategy

Closes #1"
```

### **Épicos Funcionais (Sub-Issues)**

Cada agente tem sua própria issue e PR:

```bash
# DE
git merge feature/epic-01-domain-model --no-ff
# DBA
git merge feature/epic-01-schema --no-ff
# SE
git merge feature/epic-01-backend --no-ff
# UXD
git merge feature/epic-01-wireframes --no-ff
# FE
git merge feature/epic-01-frontend --no-ff
# QAE (última - fecha o épico)
git merge feature/epic-01-quality-gate --no-ff
```

**Estratégia:** `--no-ff` (no fast-forward) para preservar contexto histórico

---

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

## 🚫 O Que NÃO Fazer

❌ Commitar diretamente em `main` ou `develop`
❌ Esquecer o commit vazio inicial
❌ Usar fast-forward em merges importantes (`--ff`)
❌ Esquecer de referenciar Issue (`Ref #N` ou `Closes #N`)
❌ Commits genéricos ("fix", "update", "changes")
❌ Commitar código sem testes
❌ Fazer push sem validar localmente

---

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
# 4. MERGE PARA DEVELOP
# ====================================

# Esperar aprovação (se houver revisor)
# Caso contrário, prosseguir

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

# Criar tag de versão
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

# 4. (Opcional) Criar PR para review do DE-01
gh pr create \
  --title "DE: Modelo de domínio EPIC-01" \
  --body "Domain model para review antes de criar issue. Ref #1" \
  --base develop \
  --head feature/epic-01-domain-model

# 5. Após review (ou skip se solo dev), merge para develop
git checkout develop
git pull origin develop
git merge feature/epic-01-domain-model --no-ff -m "Merge: DE domain model EPIC-01"
git push origin develop

# 6. Deletar branch (opcional)
git branch -d feature/epic-01-domain-model
git push origin --delete feature/epic-01-domain-model

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

# Merge para develop (após QAE aprovar)
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

# Deploy production (PE)
# PE: docker compose -f docker-compose.prod.yml up -d

# (Opcional) Deletar branch
git branch -d feature/epic-01-criar-estrategia
git push origin --delete feature/epic-01-criar-estrategia

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
