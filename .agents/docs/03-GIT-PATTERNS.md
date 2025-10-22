# Padrões Git - DDD Workflow v1.1

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

### **Boas Práticas**
9. [🚫 O Que NÃO Fazer](#o-que-não-fazer)
10. [✅ Checklist de Qualidade](#checklist-de-qualidade)

### **Guias Operacionais**
11. [📋 Quick Reference: Discovery](#quick-reference-discovery)
12. [📋 Quick Reference: Épico](#quick-reference-épico)

### **Referências**
13. [🎯 Quem Faz O Quê?](#quem-faz-o-quê)
14. [📚 Mais Informações](#mais-informações)

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

# FE: Frontend Implementation
gh pr merge --merge

# QAE: Quality Gate (última - fecha o épico)
gh pr merge --merge
```

**Estratégia:** Sempre usar "Create a merge commit" (equivalente a `--no-ff`) para preservar contexto histórico

### **⏱️ Quando fazer merge para `develop`?**

**Decisão: Merge por Epic (conclusão completa)**

Durante as iterações de um épico, múltiplos agentes trabalham em sequência (DE → DBA → SE → FE → QAE). O merge para `develop` acontece **apenas ao final do épico**, quando todos os agentes completaram seus trabalhos.

**Razões:**
- ✅ `develop` sempre **estável** (features completas e testadas)
- ✅ **Menos overhead** de gerenciamento (1 merge por epic vs 5-6 merges)
- ✅ **Alinhado com DDD** (bounded context completo antes do merge)
- ✅ **Ideal para equipes pequenas** e MVPs (1-2 desenvolvedores)

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

<a id="quick-reference-discovery"></a>
## 📋 Quick Reference: Discovery

| Passo | Responsável | Ação |
|-------|-------------|------|
| **1. Setup Inicial** | GitHub Actions | Cria Issue #1, Milestone M0, branch `feature/discovery-foundation`, commit vazio, PR Draft |
| **2. Clone** | Você | `git clone <repo>` → `git checkout feature/discovery-foundation` |
| **3. Trabalho** | Agentes (SDA, UXD, PE, GM, SEC, QAE) | Criar deliverables (7 documentos) |
| **4. Validação** | Você | Executar `.agents/scripts/validate-*.ps1` |
| **5. Commit Final** | Você | `git commit -m "docs: Discovery completa ... Closes #1"` |
| **6. PR Ready** | Você | `gh pr ready` |
| **7. Merge** | Você | Merge via GitHub UI ("Create a merge commit") |
| **8. (Opcional) Release** | Você | Merge `develop → main` + tag `v0.1.0` |

**Resultado:** Issue #1 fechada, Discovery completa em `develop`

---

<a id="quick-reference-épico"></a>
## 📋 Quick Reference: Épico

| Fase | Responsável | Ação |
|------|-------------|------|
| **1. Modelagem** | DE | Criar `DE-01-EPIC-N-<Nome>-Domain-Model.md` em branch separada → Merge para `develop` |
| **2. GitHub Setup** | GM | Ler DE-01 → Criar Milestone M{N} → Criar Issue épico #{N} (100% populada) |
| **3. Git Workflow** | Você | `git checkout -b feature/epic-N-<nome>` → Commit vazio → Push → PR Draft |
| **4. Implementação** | Agentes | **DBA** → Schema Review<br>**SE** → Backend (paralelo com UXD)<br>**UXD** → Wireframes<br>**FE** → Frontend<br>**QAE** → Quality Gate (testes) |
| **5. Encerramento** | Você | `gh pr ready` → Merge PR → Deploy staging → Deploy production |
| **6. Release** | Você | Fechar Milestone M{N} → Tag `vX.Y.Z` → GitHub Release |

**Resultado:** Epic completo, Issue #{N} fechada, Milestone M{N} fechado, tag criada

---

<a id="quem-faz-o-quê"></a>
## 🎯 Quem Faz O Quê?

### **GM (GitHub Manager)**
- ✅ Cria milestone automaticamente (após DE-01)
- ✅ Cria issue épico automaticamente (100% populada, sem edição manual)
- ✅ Fornece scripts de automação

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

**Versão:** 1.1
**Data:** 2025-10-22
**Workflow:** DDD com 10 Agentes
**Changelog:**
- v1.1 (2025-10-22): Documento simplificado (-70% linhas), seção de scripts removida (link para arquivos futuros), guias operacionais em tabelas
- v1.0 (2025-10-20): Versão inicial completa com guias operacionais detalhados
