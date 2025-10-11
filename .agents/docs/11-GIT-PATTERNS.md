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

**Versão:** 1.0
**Data:** 2025-10-11
**Workflow:** DDD com 10 Agentes
