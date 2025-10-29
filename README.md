# DDD Workflow v1.0

> **Workflow completo de Domain-Driven Design (DDD) para projetos pequenos e médios com 10 agentes especializados**

[![DDD](https://img.shields.io/badge/DDD-Tactical%20%26%20Strategic-blue)](https://martinfowler.com/tags/domain%20driven%20design.html)
[![Agents](https://img.shields.io/badge/Agents-10%20Especializados-green)](.agents/docs/01-Agents-Overview.md)
[![Version](https://img.shields.io/badge/Version-1.0-orange)](.agents/docs/00-Workflow-Guide.md)

---

## 🎯 O que é este Workflow?

Este repositório contém uma **estrutura completa e replicável** para desenvolvimento de software usando **Domain-Driven Design (DDD)** com:

- **10 agentes especializados** (SDA, DE, UXD, GM, PE, SEC, DBA, SE, FE, QAE)
- **Processo iterativo por épicos** (funcionalidades completas ponta-a-ponta)
- **Documentação mínima viável** (apenas o essencial)
- **Templates de Issues e PRs** alinhados com DDD
- **Scripts de validação** (nomenclatura, estrutura, qualidade)

---

## 🚀 Quick Start: Como Usar este Workflow em um Novo Projeto

### 🎯 Processo em 2 Fases

O setup do workflow é dividido em **2 fases**:

| Fase | O que faz | Ferramenta | Tempo |
|------|-----------|------------|-------|
| **1️⃣ [Setup Completo](#fase-1-setup-completo-via-github-actions)** | Setup completo automático (Issue, branches, PR, etc) | GitHub Actions | ~2 min |
| **2️⃣ [Trabalhar](#fase-2-trabalhar-nos-deliverables)** | Criar deliverables (SDA, UXD, PE, GM, SEC, QAE) | Agentes + Commits | 3-4 dias |
| **3️⃣ [Finalizar](#fase-3-finalizar-discovery)** | Merge para develop e release opcional | Script GM | ~1 min |

---

## Fase 1: Setup Completo (via GitHub Actions)

**O que será criado automaticamente:**
- ✅ Estrutura completa do workflow copiada
- ✅ Branches `main` e `develop` criadas
- ✅ **Issue #1** (Discovery Foundation) criada
- ✅ **Milestone M0** criada
- ✅ Branch `feature/discovery-foundation` criada
- ✅ **Commit inicial vazio** (`--allow-empty`)
- ✅ **PR Draft** criada
- ✅ Push para repositório remoto

### Passo 1: Criar Repositório Vazio no GitHub

1. Acesse [github.com/new](https://github.com/new)
2. Configure:
   - **Nome:** `nome-do-seu-projeto`
   - **Visibilidade:** Pública ou Privada
   - **⚠️ IMPORTANTE:** Deixe **VAZIO** (não inicialize com README, .gitignore ou LICENSE)
3. Clique em **Create repository**
4. Copie a URL:
   ```
   https://github.com/seu-usuario/nome-do-seu-projeto.git
   ```

### Passo 2: Executar Workflow de Setup

1. **Vá para este repositório (myTraderGEO)** no GitHub
2. Clique em **Actions** (menu superior)
3. No menu lateral esquerdo, clique em **"Setup New Project"**
4. Clique no botão **"Run workflow"** (canto superior direito)
5. Preencha os campos:
   - **project_name:** `nome-do-seu-projeto`
   - **project_repo_url:** `https://github.com/seu-usuario/nome-do-seu-projeto.git`
   - **create_discovery_issue:** ✅ (marcado - cria Issue #1 automaticamente)
6. Clique em **"Run workflow"** (botão verde)

### Passo 3: Aguardar Conclusão (1-2 minutos)

O workflow executará automaticamente:
- ✅ Copia estrutura completa do workflow
- ✅ Customiza arquivos com nome do projeto
- ✅ Cria commit inicial na branch `main`
- ✅ Cria branch `develop`
- ✅ Faz push para o repositório remoto

Você pode acompanhar o progresso na aba **Actions**.

**✅ Fase 1 Completa!** Tudo configurado automaticamente. Agora vá para a **Fase 2**.

---

## Fase 2: Trabalhar nos Deliverables

Agora que tudo está configurado, trabalhe nos deliverables.

### Passo 1: Clonar e Começar

```bash
git clone https://github.com/seu-usuario/nome-do-seu-projeto.git
cd nome-do-seu-projeto

# Checkout da branch (já criada pelo GitHub Actions)
git checkout feature/discovery-foundation
```

### Passo 2: Trabalhar nos Deliverables

Invoque os agentes para criar os deliverables e faça commits conforme completa:

```bash
# Exemplo: Depois que SDA completar
git add 00-doc-ddd/02-strategic-design/SDA-*.md
git commit -m "SDA: Modelagem estratégica completa

- SDA-01-Event-Storming.md
- SDA-02-Context-Map.md
- SDA-03-Ubiquitous-Language.md

Ref #1"
git push

# Repita para cada agente: UXD, PE, GM, SEC, QAE
```

**Importante:** GM criará os scripts de automação como parte do deliverable GM-00.

---

## Fase 3: Finalizar Discovery

Quando todos os deliverables estiverem completos, finalize a Discovery.

### Opção A: Usando Script do GM (Recomendado)

O GM cria o script `discovery-finish.sh` como parte do GM-00. Use-o para finalizar:

```bash
# Validar, fazer merge e criar release
bash 00-doc-ddd/07-github-management/scripts/discovery-finish.sh --merge --release
```

O script irá:
- ✅ Validar que todos os 8 deliverables existem
- ✅ Executar scripts de validação (PowerShell)
- ✅ Marcar PR como ready for review
- ✅ Fazer merge para develop
- ✅ Criar release v0.1.0 (se `--release` fornecido)
- ✅ Deletar branches local e remota

### Opção B: Manual (se GM não criou scripts)

```bash
# Marcar PR como pronta
gh pr ready

# Fazer merge
gh pr merge --merge

# Opcional: criar release
gh release create v0.1.0 --title "Discovery Foundation Complete" --generate-notes
```

**🎉 Discovery Completa!** Agora você pode iniciar os épicos funcionais.

---

## 📝 Setup Manual (Sem GitHub Actions)

<details>
<summary>Clique aqui se preferir fazer todo o setup manualmente</summary>

### Passos Resumidos:

1. **Criar repositório vazio no GitHub**
2. **Clonar e copiar estrutura:**
   ```bash
   git clone https://github.com/seu-usuario/nome-do-seu-projeto.git
   cd nome-do-seu-projeto

   # Copiar estrutura do myTraderGEO
   # Windows: Copy-Item -Path "C:\caminho\myTraderGEO\*" -Destination . -Recurse -Force
   # Linux/Mac: cp -R /caminho/myTraderGEO/* .
   ```

3. **Commits iniciais e setup Discovery:**
   ```bash
   git add .
   git commit -m "chore: Setup inicial do DDD Workflow v1.0"
   git push origin main

   git checkout -b develop
   git commit --allow-empty -m "chore: Início do Projeto"
   git push origin develop -u

   # Criar Issue #1, Milestone M0, branch e PR manualmente via gh CLI
   # (consulte documentação do GitHub CLI ou crie via interface web)
   ```

4. **Trabalhar nos deliverables**
5. **Finalizar com discovery-finish.sh (criado pelo GM)**

</details>

---

## 📚 Documentação Completa

- [**00-Workflow-Guide.md**](.agents/docs/00-Workflow-Guide.md) - Guia completo do processo
- [**01-Agents-Overview.md**](.agents/docs/01-Agents-Overview.md) - Detalhes dos 10 agentes
- [**02-Nomenclature-Standards.md**](.agents/docs/02-Nomenclature-Standards.md) - Padrões de nomenclatura
- [**03-GIT-PATTERNS.md**](.agents/docs/03-GIT-PATTERNS.md) - Padrões Git (branches, commits, PRs, deployment)
- [**04-Security-And-Platform-Strategy.md**](.agents/docs/04-Security-And-Platform-Strategy.md) - Estratégia de segurança e plataforma
- [**05-DDD-Patterns-Reference.md**](.agents/docs/05-DDD-Patterns-Reference.md) - Padrões DDD
- [**06-API-Standards.md**](.agents/docs/06-API-Standards.md) - Padrões de API
- [**07-PE-SEC-Light-Review.md**](.agents/docs/07-PE-SEC-Light-Review.md) - Review rápido PE/SEC
- [**08-PE-SEC-Checkpoint-Decision-Matrix.md**](.agents/docs/08-PE-SEC-Checkpoint-Decision-Matrix.md) - Matriz de decisão PE/SEC
- [**09-FEEDBACK-FLOW-GUIDE.md**](.agents/docs/09-FEEDBACK-FLOW-GUIDE.md) - Fluxo de feedback entre agentes
- [**10-THINK-MODE-GUIDE.md**](.agents/docs/10-THINK-MODE-GUIDE.md) - Modo de pensamento estratégico
- [**11-STANDARDS-COMPLIANCE-ANALYSIS.md**](.agents/docs/11-STANDARDS-COMPLIANCE-ANALYSIS.md) - Análise de conformidade

---

## 🧪 Scripts de Validação

Execute os scripts de validação regularmente para garantir qualidade:

```powershell
# Validar estrutura de pastas e agentes
.\.agents\scripts\validate-structure.ps1

# Validar nomenclatura de documentos e código
.\.agents\scripts\validate-nomenclature.ps1

# Validar com código backend/frontend
.\.agents\scripts\validate-nomenclature.ps1 -CheckCode
```

---

## 👥 Os 10 Agentes

| Sigla | Agente | Quando Executa | Escopo |
|-------|--------|----------------|--------|
| **SDA** | Strategic Domain Analyst | 1x Discovery | Sistema completo |
| **UXD** | User Experience Designer | Discovery + Por épico | Fundamentos + Wireframes |
| **GM** | GitHub Manager | Discovery + Por épico | Setup + Issues |
| **PE** | Platform Engineer | Discovery + Checkpoints | Ambientes + Performance |
| **SEC** | Security Specialist | Discovery + Checkpoints | Segurança baseline + Auditorias |
| **QAE** | Quality Assurance Engineer | Discovery + Por épico | Estratégia + Quality Gates |
| **DE** | Domain Engineer | Por épico | Modelagem tática |
| **DBA** | Database Administrator | Por épico | Migrations e schema |
| **SE** | Software Engineer | Por épico | Backend implementation |
| **FE** | Frontend Engineer | Por épico | Frontend implementation |

---

## 🏗️ Estrutura de Pastas

```
[PROJETO]/
├── .agents/                              # Agentes e templates
│   ├── docs/                             # Documentação do workflow
│   ├── 10-SDA.xml ... 60-QAE.xml         # Especificações dos agentes
│   ├── templates/                        # Templates para deliverables
│   └── scripts/                          # Scripts de validação
│
├── .github/                              # GitHub templates
│   ├── ISSUE_TEMPLATE/                   # Templates de Issues
│   └── pull_request_template.md          # Template de PR
│
├── 00-doc-ddd/                           # Documentação DDD
│   ├── 00-feedback/                      # Feedbacks entre agentes
│   ├── 02-strategic-design/              # Deliverables SDA
│   ├── 03-ux-design/                     # Deliverables UXD
│   ├── 04-tactical-design/               # Deliverables DE
│   ├── 05-database-design/               # Deliverables DBA
│   ├── 06-quality-assurance/             # Deliverables QAE
│   ├── 07-github-management/             # Deliverables GM
│   ├── 08-platform-engineering/          # Deliverables PE
│   └── 09-security/                      # Deliverables SEC
│
├── 01-frontend/                          # Código frontend (FE)
├── 02-backend/                           # Código backend (SE)
├── 04-database/                          # Migrations e scripts (DBA)
│
└── workflow-config.json                  # Configuração do workflow
```

---

## 🔄 Fluxo Típico de Desenvolvimento

### **Fase 1: Discovery (1x por projeto - Issue #1)**

```
Dia 1-2: SDA
  → Event Storming
  → Context Map
  → Linguagem Ubíqua

Dia 2-3: [UXD + PE] (PARALELO - Fundações Independentes)
  → UXD: Design Foundations
  → PE: Define Stack + Ambientes (dev/stage/prod com Docker)
  → PE: Server Setup Documentation (OS, Docker, firewall, users, SSH)
  → PE: Scaling Strategy (quando migrar de Compose para orquestração)

Dia 3-4: [GM + SEC + QAE] (PARALELO - Dependem do Stack do PE)
  → GM: GitHub Setup (CI/CD baseado no stack)
  → GM: Deployment Strategy (local vs remote, CD pipelines)
  → SEC: Security Baseline (ferramentas compatíveis + server hardening)
  → QAE: Test Strategy (ferramentas baseadas no stack)

Duração: 3-4 dias
Deliverables: 7 documentos

⚠️ Ordem Crítica: PE deve executar ANTES de GM/SEC/QAE
   PE define stack → GM/SEC/QAE escolhem ferramentas compatíveis
```

---

### **Fase 2: Épicos Funcionais (Iterativo - Issues N)**

```
Epic N: [Nome da Funcionalidade]

Dia 1-2: DE
  → DE-01-[EpicName]-Domain-Model.md

Dia 2: GM
  → Cria sub-issues detalhadas (1 por agente)

Dia 2: Criar Branch + Commit Inicial
  → git checkout -b feature/epic-N-nome-do-epic
  → git commit --allow-empty -m "chore: Início de uma nova feature"
  → git push origin feature/epic-N-nome-do-epic -u

Dia 2-3: DBA
  → DBA-01-[EpicName]-Schema-Review.md
  → Migrations (EF Core)

Dia 3-6: SE + UXD (PARALELO)
  → SE: Backend (domain, application, API)
  → UXD: UXD-01-[EpicName]-Wireframes.md

Dia 7-9: FE
  → Frontend (UI + integração com APIs)

Dia 9 (OPCIONAL): PE + SEC Checkpoints
  → PE: Performance review (15min)
  → SEC: Security review (15min)

Dia 10: QAE (QUALITY GATE)
  → Testes E2E
  → Smoke tests
  → ✅ OK → Deploy | ❌ Falhou → Volta SE/FE

Deploy
  → PE/GM: Deploy staging (auto via CD pipeline)
  → PE/GM: Deploy production (manual approval)
  → Monitoramento

**Nota:** Deploy remoto requer servidor preparado conforme PE-00 (Discovery).

Duração: 10 dias (2 semanas)
```

**🔹 Padrão: Commit Inicial Obrigatório**

Toda feature/épico deve começar com commit vazio:
```bash
git commit --allow-empty -m "chore: Início de uma nova feature

Feature: [Nome do Épico]
Issue: #[número]

Este commit marca o início do trabalho na feature."
```

---

## 📋 Abordagem de Issues

### **Discovery Foundation: Issue Única com Checklist**

```
Issue #1: [EPIC-00] Discovery Foundation
├─ Checklist por agente (SDA, UXD, GM, PE, SEC, QAE)
├─ Branch: feature/discovery-foundation
├─ Commits: 1 por agente (ou agrupados)
└─ Merge: Create a merge commit (preserva histórico)
```

---

### **Épicos Funcionais: Sub-Issues por Agente**

```
Epic #2: [EPIC-01] Criar Estratégia
├─ Issue #3: [DE] Domain Model - Criar Estratégia
├─ Issue #4: [DBA] Schema Review - Criar Estratégia
├─ Issue #5: [SE] Backend Implementation
├─ Issue #6: [UXD] Wireframes - Criar Estratégia
├─ Issue #7: [FE] Frontend Implementation
└─ Issue #8: [QAE] Quality Gate - Epic 1

Cada issue = 1 PR independente → develop
Permite paralelização e code review focado
```

---

## 🤖 Usando Claude Code

Claude Code pode automatizar várias tarefas do workflow:

### **Criar Issues**
```
Claude, crie a Issue #1 (Discovery Foundation) no GitHub.
```

### **Criar Pull Requests**
```
Claude, crie um PR de feature/discovery-foundation para develop.
```

### **Executar Validações**
```
Claude, execute os scripts de validação do workflow.
```

### **Trabalhar com Agentes**
```
Claude, atue como SDA e crie o Event Storming para o projeto X.
```

Consulte a [documentação completa dos agentes](.agents/docs/01-Agents-Overview.md) para mais exemplos.

---

## 🤝 Contribuindo

Este é um **workflow template**. Para melhorias:

1. Fork este repositório
2. Crie uma branch (`feature/melhoria-xyz`)
3. Commit suas mudanças
4. Crie um Pull Request com descrição detalhada

---

## 📄 Licença

Este workflow é fornecido "as is" para uso livre em projetos pessoais e comerciais.

---

## 🙋 Suporte

- **Issues:** Para reportar problemas ou sugerir melhorias
- **Discussions:** Para perguntas e discussões sobre o workflow
- **Wiki:** Documentação adicional e exemplos práticos

---

**Versão:** 1.0
**Data:** 2025-10-11
**Workflow:** DDD com 10 Agentes (Projetos Pequenos/Médios)
