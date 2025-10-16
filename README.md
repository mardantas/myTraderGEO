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

### **Passo 1: Criar Projeto no Servidor (GitHub)**

1. Acesse o GitHub e crie um novo repositório:
   - Nome: `nome-do-seu-projeto`
   - Visibilidade: Pública ou Privada
   - **NÃO** inicialize com README, .gitignore ou LICENSE

2. Copie a URL do repositório criado:
   ```
   https://github.com/seu-usuario/nome-do-seu-projeto.git
   ```

---

### **Passo 2: Clonar Localmente na Branch `main`**

```bash
# Clonar o repositório vazio
git clone https://github.com/seu-usuario/nome-do-seu-projeto.git
cd nome-do-seu-projeto
```

---

### **Passo 3: Copiar Estrutura do Workflow**

```bash
# Copiar TODO o conteúdo deste workflow repo para o novo projeto
# (ajuste o caminho conforme sua estrutura local)

# Windows (PowerShell)
Copy-Item -Path "C:\caminho\para\myTraderGEO\*" -Destination . -Recurse -Force

# Linux/Mac
cp -R /caminho/para/myTraderGEO/* .
```

**O que será copiado:**
- `.agents/` - Agentes especializados e templates
- `00-doc-ddd/` - Estrutura de documentação (vazia)
- `.github/` - Templates de Issues e PRs
- `workflow-config.json` - Configuração de caminhos
- Scripts de validação (`.agents/scripts/`)

---

### **Passo 4: Commit Inicial - Ambiente Pronto**

```bash
# Adicionar todos os arquivos
git add .

# Criar commit inicial
git commit -m "chore: Setup inicial do DDD Workflow v1.0

- Estrutura de 10 agentes especializados (.agents/)
- Templates de documentação DDD
- Templates de Issues/PRs (.github/)
- Scripts de validação (nomenclatura + estrutura)
- Configuração do workflow (workflow-config.json)

Este commit estabelece a fundação do processo DDD.

Próximo passo: Criar branch develop e executar Discovery Foundation (Issue #1)

🚀 Ambiente pronto para início do projeto"

# Push para o repositório remoto
git push origin main
```

---

### **Passo 5: Criar Branch `develop` a partir da `main`**

```bash
# Criar branch develop
git checkout -b develop

# Commit vazio marcando início do projeto
git commit --allow-empty -m "chore: Início do Projeto

Branch develop criada a partir da main.
Pronta para receber a primeira feature (Discovery Foundation).

Próximo passo: Criar Issue #1 (Discovery Foundation) e branch feature/discovery-foundation"

# Push da branch develop
git push origin develop -u
```

---

### **Passo 6: Criar Issue #1 - Discovery Foundation**

#### **Opção A: Usar Claude Code (Recomendado) 🤖**

Se você estiver usando Claude Code, basta solicitar:

```
Claude, crie a Issue #1 (Discovery Foundation) no GitHub usando o template
00-discovery-foundation.yml. O nome do projeto é [NOME-DO-SEU-PROJETO].
```

**Claude irá:**
- ✅ Ler o template [.github/ISSUE_TEMPLATE/00-discovery-foundation.yml](.github/ISSUE_TEMPLATE/00-discovery-foundation.yml)
- ✅ Preencher os campos automaticamente com informações do seu projeto
- ✅ Criar a issue via `gh issue create`
- ✅ Aplicar labels corretas (`epic`, `discovery`, `setup`, `priority-high`)

---

#### **Opção B: Criar Manualmente no GitHub**

1. Acesse seu repositório no GitHub
2. Vá para **Issues** → **New Issue**
3. Selecione o template **"🚀 Discovery Foundation"**
4. Preencha os campos solicitados:
   - Nome do projeto
   - Descrição do projeto
   - Tamanho estimado
5. Marque os checklists conforme completa cada deliverable
6. Clique em **Submit new issue**

---

#### **Opção C: Via GitHub CLI**

```bash
gh issue create \
  --title "[EPIC-00] Discovery Foundation - Modelagem Estratégica e Setup Inicial" \
  --label "epic,discovery,setup,priority-high" \
  --template "00-discovery-foundation.yml"
```

---

### **Passo 7: Criar Branch, Commit Inicial e PR Draft**

```bash
# Voltar para develop
git checkout develop

# Criar branch da feature
git checkout -b feature/discovery-foundation

# Fazer commit vazio marcando início da feature
git commit --allow-empty -m "chore: Início de uma nova feature

Feature: Discovery Foundation
Issue: #1

Este commit marca o início do trabalho na feature de Discovery Foundation."

# Push da branch
git push origin feature/discovery-foundation -u
```

**Agora criar PR como Draft (trabalho em progresso):**

#### **Opção A: Usar Claude Code (Recomendado) 🤖**

```
Claude, crie uma PR Draft da branch feature/discovery-foundation para develop.
Título: [EPIC-00] Discovery Foundation
Marque como Draft (trabalho em progresso) e inclua checklist dos deliverables.
```

#### **Opção B: Via GitHub CLI**

```bash
gh pr create \
  --draft \
  --base develop \
  --head feature/discovery-foundation \
  --title "[EPIC-00] Discovery Foundation" \
  --body "## 🚧 Work in Progress

Esta é a PR da Issue #1 - Discovery Foundation.

Marcada como **Draft** enquanto os agentes trabalham nos deliverables.

### Progress Checklist:
- [ ] SDA: Modelagem estratégica
- [ ] UXD: Design Foundations
- [ ] GM: GitHub Setup
- [ ] PE: Ambientes
- [ ] SEC: Security Baseline
- [ ] QAE: Test Strategy

Será marcada como ready for review quando todos os deliverables estiverem completos.

Ref #1"
```

---

### **Passo 8: Trabalhar nos Deliverables**

```bash
# Trabalhar nos deliverables (SDA, UXD, GM, PE, SEC, QAE)
# Fazer commits conforme cada agente completa seu trabalho

# Exemplo de commit (SDA):
git add 00-doc-ddd/02-strategic-design/SDA-*.md
git commit -m "SDA: Modelagem estratégica completa

- SDA-01-Event-Storming.md (domain events identificados)
- SDA-02-Context-Map.md (5 Bounded Contexts mapeados)
- SDA-03-Ubiquitous-Language.md (glossário de termos)

Ref #1"

# Push das mudanças (atualiza PR automaticamente)
git push
```

**Nota:** Cada push atualiza a PR Draft automaticamente. Reviewers podem acompanhar o progresso.

---

### **Passo 9: Marcar PR como Ready for Review**

Quando todos os deliverables estiverem completos e todos os commits feitos:

#### **Opção A: Usar Claude Code (Recomendado) 🤖**

```
Claude, marque a PR como ready for review e atualize o body com todos os deliverables completados.
```

#### **Opção B: Via GitHub CLI**

```bash
# Marcar PR como ready for review
gh pr ready

# Atualizar body da PR com deliverables completos
gh pr edit --body "## ✅ Discovery Foundation Complete

Todos os deliverables foram completados:

### 📊 SDA - Strategic Domain Analyst
- ✅ SDA-01-Event-Storming.md
- ✅ SDA-02-Context-Map.md
- ✅ SDA-03-Ubiquitous-Language.md

### 🎨 UXD - User Experience Designer
- ✅ UXD-00-Design-Foundations.md

### ⚙️ GM - GitHub Manager
- ✅ GM-00-GitHub-Setup.md
- ✅ Labels, CI/CD, branch protection

### 🏗️ PE - Platform Engineer
- ✅ PE-00-Environments-Setup.md
- ✅ Docker Compose (dev/staging/prod)

### 🔒 SEC - Security Specialist
- ✅ SEC-00-Security-Baseline.md

### ✅ QAE - Quality Assurance Engineer
- ✅ QAE-00-Test-Strategy.md

Closes #1"
```

#### **Opção C: Manualmente no GitHub**

1. Acesse a PR no GitHub
2. Clique em **Ready for review** (botão no topo)
3. Edite a descrição marcando todos os checkboxes como completos
   - Listar deliverables completados
   - Marcar checklists de testes e validação
4. No final do corpo do PR, adicione: `Closes #1`
5. Clique em **Create Pull Request**

---

#### **Opção C: Via GitHub CLI**

```bash
gh pr create \
  --base develop \
  --head feature/discovery-foundation \
  --title "[EPIC-00] Discovery Foundation" \
  --body "## 🎯 Issue Relacionada
Closes #1

## 📋 Tipo de Mudança
- [x] 📚 Documentação (Discovery Foundation)

## 🏗️ Contexto DDD
- **Fase:** Discovery (Setup Inicial)
- **Agentes:** SDA, UXD, GM, PE, SEC, QAE

## 📖 Descrição

### Deliverables Completados:
- SDA-01-Event-Storming.md
- SDA-02-Context-Map.md
- SDA-03-Ubiquitous-Language.md
- UXD-00-Design-Foundations.md
- GM-00-GitHub-Setup.md
- PE-00-Environments-Setup.md
- SEC-00-Security-Baseline.md
- QAE-00-Test-Strategy.md

## ✅ Checklist de Review
- [x] Documentação completa
- [x] Scripts de validação executados
- [x] Estrutura de pastas validada"
```

---

#### **Após Criar o PR:**

1. **Review:** Revise o PR (ou peça para colega revisar)
2. **Merge:** Após aprovação, faça merge usando:
   - **Estratégia:** "Create a merge commit" (preserva histórico dos agentes)
3. **Issue #1 fecha automaticamente** se o PR tem `Closes #1`

---

## 📚 Documentação Completa

- [**00-Workflow-Guide.md**](.agents/docs/00-Workflow-Guide.md) - Guia completo do processo
- [**01-Agents-Overview.md**](.agents/docs/01-Agents-Overview.md) - Detalhes dos 10 agentes
- [**02-Nomenclature-Standards.md**](.agents/docs/02-Nomenclature-Standards.md) - Padrões de nomenclatura
- [**03-Security-And-Platform-Strategy.md**](.agents/docs/03-Security-And-Platform-Strategy.md) - Estratégia de segurança
- [**04-DDD-Patterns-Reference.md**](.agents/docs/04-DDD-Patterns-Reference.md) - Padrões DDD
- [**05-API-Standards.md**](.agents/docs/05-API-Standards.md) - Padrões de API
- [**07-PE-SEC-Checkpoint-Decision-Matrix.md**](.agents/docs/07-PE-SEC-Checkpoint-Decision-Matrix.md) - Matriz de decisão PE/SEC
- [**08-FEEDBACK-FLOW-GUIDE.md**](.agents/docs/08-FEEDBACK-FLOW-GUIDE.md) - Fluxo de feedback entre agentes

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

Dia 3-4: [GM + SEC + QAE] (PARALELO - Dependem do Stack do PE)
  → GM: GitHub Setup (CI/CD baseado no stack)
  → SEC: Security Baseline (ferramentas compatíveis)
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
  → PE: Deploy staging → production
  → Monitoramento

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
