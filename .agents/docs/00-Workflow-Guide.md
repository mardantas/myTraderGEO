# DDD Workflow Guide

**Objetivo:** Guia prático do processo de desenvolvimento Domain-Driven Design (DDD) para projetos pequenos e médios.

---

## 🎯 Visão Geral

Este workflow combina **DDD estratégico e tático** com **desenvolvimento ágil** através de **10 agentes especializados** trabalhando iterativamente para entregar valor incremental de forma simples e pragmática.

### Princípios

1. **Épicos por Funcionalidade** - não por Bounded Context
2. **Iteração rápida** - feedback contínuo
3. **Documentação mínima viável** - apenas o essencial
4. **Código como documentação** - código limpo é a fonte primária
5. **Deploy incremental** - por épico completo

---

## 👥 Agentes (10)

| Ordem | Sigla | Agente | Quando Executa | Escopo | Dependências |
|-------|-------|--------|----------------|--------|--------------|
| 1 | SDA | Strategic Domain Analyst | 1x Discovery (Dia 1-2) | Sistema completo | - |
| 2a | UXD | User Experience Designer | 1x Discovery (Dia 2-3) + Por épico | Fundamentos + Wireframes | SDA |
| 2b | **PE** | **Platform Engineer** | **1x Discovery (Dia 2-3)** | **Define stack + ambientes** | **SDA** |
| 3a | GM | GitHub Manager | 1x Discovery (Dia 3-4) + Por épico | Setup CI/CD + Issues | **PE** (stack) |
| 3b | SEC | Security Specialist | 1x Discovery (Dia 3-4) | Baseline de segurança | **PE** (stack) |
| 3c | QAE | Quality Assurance Engineer | 1x Discovery (Dia 3-4) + Por épico | Estratégia de testes + Quality gate | **PE** (stack) |
| - | DE | Domain Engineer | Por épico | Modelagem tática | SDA |
| - | DBA | Database Administrator | Por épico | Migrations e validação | DE, PE |
| - | SE | Software Engineer | Por épico | Implementação backend | DE, DBA |
| - | FE | Frontend Engineer | Por épico | Implementação frontend | SE, UXD |

**⚠️ Atenção:** PE (Platform Engineer) **deve executar ANTES** de GM, SEC e QAE na Discovery, pois define o stack tecnológico que estes agentes precisam para escolher ferramentas compatíveis.

Ver detalhes em [01-Agents-Overview.md](01-Agents-Overview.md)

---

## 🏗️ Estrutura do Processo

### **Fase 1: Discovery (1x por projeto)**

Executada uma vez no início para estabelecer a fundação estratégica **mínima**.

```
Dia 1-2: SDA
  - Event Storming
  - Context Map
  - Linguagem Ubíqua
  - Épicos priorizados (alto nível)

Dia 2-3: [UXD + PE] (PARALELO - Fundações Independentes)

  UXD:
    - Fundamentos de Design (cores, tipografia, componentes base)

  PE:
    - Define Stack Tecnológico (Backend, Frontend, Database)
    - Setup de Ambientes (dev/stage/prod com SCRIPTS)
    - Docker Compose
    - Setup de banco de dados
    - Scripts de deploy (ainda não IaC)

Dia 3-4: [GM + SEC + QAE] (PARALELO - Dependem do Stack do PE)

  GM:
    - Setup GitHub (labels, template PR, proteção de branch)
    - CI/CD básico baseado no stack do PE (build + test)
    - GitHub Actions (deploy staging/prod)
    - ❌ NÃO cria issues (épicos ainda não refinados)

  SEC:
    - Baseline de Segurança (threat model básico)
    - Checklist essencial de segurança
    - LGPD/compliance mínimo
    - Ferramentas de segurança compatíveis com stack

  QAE:
    - Estratégia de Testes baseada no stack do PE
    - Ferramentas de teste (unit, integration, E2E)
    - Cobertura mínima e critérios de qualidade
```

**Duração:** 3-4 dias
**Deliverables:** 7 documentos (SDA: 3, UXD: 1, PE: 1, GM: 1, SEC: 1, QAE: 1)

**Dependências Críticas na Discovery:**

```
SDA (Dia 1-2)
  ↓
  ├─→ UXD (Dia 2-3) - Independente de stack
  └─→ PE (Dia 2-3) - Define stack tecnológico
        ↓
        ├─→ GM (Dia 3-4) - CI/CD baseado no stack
        ├─→ SEC (Dia 3-4) - Ferramentas compatíveis com stack
        └─→ QAE (Dia 3-4) - Ferramentas de teste baseadas no stack
```

**Por que esta ordem?**
- ✅ **PE primeiro:** Define .NET/Node, React/Vue, PostgreSQL/MongoDB → decisões que impactam GM, SEC, QAE
- ✅ **UXD paralelo com PE:** Design independe de stack técnico
- ✅ **GM, SEC, QAE depois de PE:** Escolhem ferramentas compatíveis (xUnit vs Jest, OWASP ZAP vs Snyk, GitHub Actions config específico)

---

### **Fase 2: Iteração por Épico (N iterações)**

Executada para cada épico prioritário, entregando funcionalidade completa ponta-a-ponta.

```
┌──────────────────────────────────────────────────────┐
│  ÉPICO: [Nome da Funcionalidade]                     │
│  Ex: "EPIC-01: Criar e Visualizar Estratégia"        │
└──────────────────────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 1-2: DE                           │
        │ DE-01-[NomeEpico]-Domain-Model.md     │
        │ - Aggregates detalhados               │
        │ - Domain Events                       │
        │ - Use Cases (specs completas)         │
        │ - Interfaces de repositório           │
        │ - Regras de negócio (invariantes)     │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 2: GM                             │
        │ - Lê DE-01                            │
        │ - Cria issue detalhada no GitHub      │
        │ - Issue: use cases + critérios de     │
        │   aceitação + tarefas                 │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 2-3: DBA                          │
        │ DBA-01-[NomeEpico]-Migrations         │
        │ - Valida schema do DE-01              │
        │ - Cria migrations (EF Core)           │
        │ - Estratégia de indexação             │
        └───────────────────────────────────────┘
                        ↓
        ┌────────────────────────────────────────┐
        │ Dia 3-6: SE + UXD (PARALELO)           │
        │                                        │
        │ SE:                      UXD:          │
        │ - Camada de domínio      - UXD-01      │
        │ - Camada de aplicação    - Wireframes  │
        │ - Infraestrutura         - Componentes │
        │ - Camada de API          específicos   │
        │ - Testes unitários (≥70%) por épico   │
        └────────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 7-9: FE                           │
        │ - Implementa UI (usando UXD-01)       │
        │ - Integra com APIs do SE              │
        │ - Testes de componentes               │
        │ - Gerenciamento de estado             │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 9 (OPCIONAL): PE + SEC Checkpoints│
        │ - PE: Quick performance review (15min)│
        │   • N+1 queries? Missing indexes?     │
        │   • Async/await correct?              │
        │ - SEC: Quick security review (15min)  │
        │   • OWASP Top 3? Authorization?       │
        │   • Input validation? Secrets safe?   │
        │                                       │
        │ ⚠️ QUANDO EXECUTAR (ver Decision      │
        │    Matrix para critérios completos):  │
        │ PE: Queries >3 JOINs, real-time       │
        │     calculations, Epic 4+, API extern │
        │ SEC: PII/financial data, auth logic,  │
        │      Epic 4+, upload arquivos         │
        │                                       │
        │ 📋 Ref: 07-PE-SEC-Checkpoint-Decision-│
        │         Matrix.md                     │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ Dia 10: QAE (QUALITY GATE)            │
        │ - Testes de integração (SE ↔ FE)      │
        │ - Testes E2E (jornadas do usuário)    │
        │ - Testes de regressão (épicos antigos)│
        │ - Smoke test                          │
        │                                       │
        │ ✅ Testes passam → DEPLOY RELEASE     │
        │ ❌ Testes falham → RETORNA SE/FE      │
        └───────────────────────────────────────┘
                        ↓
        ┌───────────────────────────────────────┐
        │ DEPLOY                                │
        │ - PE: Deploy staging (GitHub Actions) │
        │ - QAE: Smoke test staging             │
        │ - PE: Deploy production               │
        │ - Monitoramento                       │
        └───────────────────────────────────────┘
                        ↓
              [FEEDBACK DO USUÁRIO]
                        ↓
             [Próximo Épico]
```

**Duração por épico:** 10 dias (2 semanas)
**Deliverables:** 3 documentos (DE-01, DBA-01, UXD-01) + código + testes + 1 issue GitHub

---

## 📐 Épicos: Por Funcionalidade vs Por BC

### ✅ CORRETO: Épicos por Funcionalidade (Transversal)

**Exemplo:**
```
Épico 1: "Criar e Visualizar Estratégia Bull Call Spread"
  → Atravessa: BC Gestão de Estratégias + BC Dados de Mercado + BC Portfólio

Épico 2: "Calcular Greeks e P&L em Tempo Real"
  → Atravessa: BC Estratégia + BC Risco + BC Dados de Mercado

Épico 3: "Alertas Automáticos de Risco"
  → Atravessa: BC Risco + BC Estratégia
```

**Por quê?**
- Entrega valor de negócio completo
- Usuário pode testar funcionalidade ponta-a-ponta
- Feedback real e útil
- Integração de BCs validada cedo

### ❌ EVITAR: Épicos por Bounded Context

```
Épico 1: "BC Gestão de Estratégias"
Épico 2: "BC Gestão de Risco"
```

**Problema:** Usuário não consegue usar nada até que todos os BCs estejam prontos.

---

## 💬 Sistema de Feedback

Quando um agente identifica um problema no entregável de outro agente, cria um FEEDBACK formal.

### Formato

`FEEDBACK-[NNN]-[DE]-[PARA]-[titulo-curto].md`

**Exemplo:**
`FEEDBACK-003-DE-SDA-adicionar-evento-strategy-adjusted.md`

### Como Funciona

**1. Criar Feedback (Usuário → Agente):**
```
Usuário: "DE, crie feedback para SDA sobre evento 'Strategy Adjusted' faltante"

DE: [cria FEEDBACK-003-DE-SDA-adicionar-evento-strategy-adjusted.md]
    "✅ Feedback FEEDBACK-003 criado para SDA"
```

**2. Processar Feedback (Usuário → Agente):**
```
Usuário: "SDA, processe FEEDBACK-003"

SDA: [lê feedback]
     [atualiza SDA-01-Event-Storming.md]
     [documenta resolução em FEEDBACK-003]
     "✅ FEEDBACK-003 resolvido. Event Storming atualizado."
```

### Tipos de Feedback

- **Correção:** Entregável tem erro que requer ajuste
- **Melhoria:** Sugestão de aprimoramento
- **Pergunta:** Esclarecimento necessário
- **Novo Requisito:** Mudança de escopo

### Urgência

- 🔴 **Alta:** Bloqueia outro agente
- 🟡 **Média:** Importante mas não bloqueia
- 🟢 **Baixa:** Desejável

---

## 🎭 Modos de Execução dos Agentes

Agentes suportam execução em dois modos:

### Modo Natural (Principal)
```
"SDA, faça a modelagem estratégica completa do sistema"
"DE, modele épico 'Criar Estratégia' nos BCs Strategy + Market Data"
"SDA, atualize Context Map adicionando BC de Notificações"
```

### Modo Formal (Opcional, para automação)
```
@SDA: FULL_PROTOCOL
@DE: MODEL_EPIC epic="Criar Estratégia" bcs="Strategy,MarketData"
@SDA: UPDATE deliverable=SDA-02 feedback=FEEDBACK-003
```

**Recomendação:** Use modo natural no dia a dia. Modo formal para scripts/automação.

---

## 📂 Estrutura de Pastas

```
[RAIZ-PROJETO]/
├── .agents/                              # Agentes e templates
│   ├── docs/                             # Documentação do workflow
│   │   ├── 00-Workflow-Guide.md          # Este documento
│   │   ├── 01-Agents-Overview.md         # Detalhes dos agentes
│   │   ├── 02-Nomenclature-Standards.md  # Padrões de nomenclatura
│   │   ├── 03-Security-And-Platform-Strategy.md
│   │   ├── 04-DDD-Patterns-Reference.md
│   │   └── 05-API-Standards.md
│   ├── 10-SDA.xml ... 60-QAE.xml         # Especificações dos agentes
│   ├── templates/                         # Templates para deliverables
│   └── workflow/                          # Checklists e validações
│
├── 00-doc-ddd/                            # Documentação DDD
│   ├── 00-feedback/                       # Feedbacks entre agentes
│   ├── 01-inputs-raw/                     # Requisitos iniciais
│   ├── 02-strategic-design/               # Deliverables SDA
│   ├── 03-ux-design/                      # Deliverables UXD
│   ├── 04-tactical-design/                # Deliverables DE
│   ├── 05-database-design/                # Deliverables DBA
│   ├── 06-quality-assurance/              # Deliverables QAE
│   ├── 07-github-management/              # Deliverables GM
│   ├── 08-platform-engineering/           # Deliverables PE
│   └── 09-security/                       # Deliverables SEC
│
├── 01-frontend/                           # Código frontend (FE)
├── 02-backend/                            # Código backend (SE)
├── 03-github-manager/                     # Scripts GM (opcional)
├── 04-database/                           # Migrations e scripts
│
└── workflow-config.json                   # Configuração do workflow
```

---

## 🔄 Workflow Típico

### Início do Projeto

```
1. SDA: Modelagem estratégica (BCs, Context Map, UL, Épicos)
2. [UXD + PE] paralelo: Fundamentos independentes de stack
3. [GM + SEC + QAE] paralelo: Baseados no stack definido por PE
4. Usuário: Prioriza épicos
5. Iniciar Épico 1
```

### Desenvolvimento do Épico 1

```
5. DE: Modelar BCs do Épico 1 (DE-01-Epic1-Domain-Model.md)
6. GM: Criar issue detalhada no GitHub
7. Criar branch: git checkout -b feature/epic-01-nome-do-epic
8. Commit vazio inicial: git commit --allow-empty -m "chore: Início de uma nova feature"
9. DBA: Revisar schema (migrations EF), sugerir índices
10. SE: Implementar domain + application + infrastructure + APIs
11. UXD: Criar wireframes (paralelo com SE)
12. FE: Implementar UI do Épico 1 (consumindo APIs do SE)
13. QAE: Testar integração + E2E (QUALITY GATE)
14. PE: Deploy staging → production
15. Feedback do usuário
16. Ajustes se necessário
```

**Padrão de Commit Inicial:**
Todo épico/feature deve começar com um commit vazio marcando o início formal:
```bash
git commit --allow-empty -m "chore: Início de uma nova feature

Feature: [Nome do Épico]
Issue: #[número]

Este commit marca o início do trabalho na feature [descrição]."
```

### Épicos 2, 3, N...

```
15. Repetir passos 5-14 para cada épico
16. Feedback entre agentes quando necessário
17. Deploy incremental
```

---

## 📊 Métricas de Sucesso

**Discovery:**
- **Tempo:** 3-4 dias
- **Docs:** 7 documentos
- **Overhead:** ~25% do primeiro épico

**Por Épico:**
- **Tempo:** 10 dias úteis (2 semanas)
- **Docs:** 3 documentos (DE-01, DBA-01, UXD-01)
- **Frequência de deploy:** Cada épico (2 semanas)
- **Loop de feedback:** Imediato após deploy
- **Overhead de documentação:** <20% do tempo

---

## 🗂️ Configuração de Caminhos

**IMPORTANTE:** Todos os caminhos do workflow são definidos em `workflow-config.json` (única fonte da verdade).

### Como Funciona

**Nos XMLs dos agentes:**
```xml
<deliverable path="SDA-01-Event-Storming.md" base-path="strategic-design">
<template base-path="templates">01-strategic-design/SDA-01.template.md</template>
<quality-checklist path="SDA-checklist.yml" base-path="checklists">
```

**Sistema resolve via config.json:**
```json
"strategic-design": "00-doc-ddd/02-strategic-design/"
"templates": ".agents/templates/"
"checklists": ".agents/workflow/02-checklists/"
```

**Caminho final:** `00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md`

### Vantagem
Mudar estrutura de pastas = atualizar **apenas** `workflow-config.json` (zero mudanças nos XMLs).

---

## 🔍 Validação de Qualidade

O workflow inclui scripts PowerShell para validar nomenclatura e estrutura do projeto automaticamente.

### 📋 Scripts Disponíveis

#### 1. validate-nomenclature.ps1

**Objetivo:** Valida nomenclatura de documentos, feedbacks e código conforme padrões DDD.

**Localização:** `.agents/scripts/validate-nomenclature.ps1`

**O que valida:**
- ✅ Nomenclatura de documentos em `00-doc-ddd/` (SDA-XX, DE-XX, UXD-XX, etc)
- ✅ Formato de feedbacks (FEEDBACK-NNN-FROM-TO-title.md)
- ✅ Agentes válidos em feedbacks (SDA, UXD, DE, DBA, SE, FE, QAE, GM, PE, SEC)
- ✅ Placeholders em documentos ([PROJECT_NAME], [YYYY-MM-DD], [EpicName])
- ✅ Templates têm extensão `.template.md`
- ✅ Templates têm placeholders obrigatórios
- ✅ *(Opcional)* Código backend/frontend (com flag `-CheckCode`)

**Uso:**

```powershell
# Validação básica (apenas documentos)
.\.agents\scripts\validate-nomenclature.ps1

# Com validação de código backend/frontend
.\.agents\scripts\validate-nomenclature.ps1 -CheckCode

# Modo verbose (mostra todos os arquivos validados)
.\.agents\scripts\validate-nomenclature.ps1 -Verbose

# Combinado (código + verbose)
.\.agents\scripts\validate-nomenclature.ps1 -CheckCode -Verbose
```

**Validações de Código (se `-CheckCode`):**

Backend (C#):
- ✅ Classes de domínio usam inglês (não português)
- ✅ Aggregates têm suporte a Domain Events
- ✅ Value Objects são immutable (sem setters)

Frontend (React):
- ✅ Componentes seguem PascalCase
- ✅ Componentes têm `export default`
- ✅ Hooks seguem padrão `use*`

**Exemplo de Output:**
```
📝 DDD Workflow Nomenclature Validator

📋 Validating document nomenclature in 00-doc-ddd...
  ✅ 02-strategic-design/SDA-01-Event-Storming.md
  ✅ 04-tactical-design/DE-01-CreateStrategy-Domain-Model.md
  ❌ Invalid name: 04-tactical-design/modelo-tatico.md
     Expected pattern: ^DE-\d{2}-.*\.md$

💬 Validating feedback nomenclature...
  ✅ FEEDBACK-001-DE-SDA-adicionar-evento.md
  ❌ Invalid source agent: XYZ in FEEDBACK-002-XYZ-DE-test.md

===========================================================
📊 NOMENCLATURE VALIDATION SUMMARY
===========================================================

❌ Errors: 2
⚠️  Warnings: 0

Please fix errors before proceeding.
```

---

#### 2. validate-structure.ps1

**Objetivo:** Valida estrutura de pastas, arquivos e agentes do workflow.

**Localização:** `.agents/scripts/validate-structure.ps1`

**O que valida:**
- ✅ Pastas obrigatórias existem (`00-doc-ddd/*`, `.agents/templates/*`)
- ✅ Arquivos de documentação presentes (00-Workflow-Guide.md, 01-Agents-Overview.md, etc)
- ✅ Agentes XML válidos e estruturados corretamente
- ✅ Templates obrigatórios presentes
- ✅ Nomenclatura de documentos existentes
- ✅ Formato de feedbacks
- ✅ Detecção de pastas obsoletas

**Uso:**

```powershell
# Validação básica
.\.agents\scripts\validate-structure.ps1

# Modo verbose (mostra todos os arquivos validados)
.\.agents\scripts\validate-structure.ps1 -Verbose
```

**Pastas Obrigatórias Validadas:**
```
00-doc-ddd/
├── 00-feedback/
├── 01-inputs-raw/
├── 02-strategic-design/
├── 03-ux-design/
├── 04-tactical-design/
├── 05-database-design/
├── 06-quality-assurance/
├── 07-github-management/
├── 08-platform-engineering/
└── 09-security/

.agents/templates/
├── 01-strategic-design/
├── 02-ux-design/
├── 03-tactical-design/
├── 04-database-design/
├── 05-quality-assurance/
├── 06-github-management/
├── 07-feedback/
├── 08-platform-engineering/
└── 09-security/
```

**Agentes XML Validados:**
- 10-SDA - Strategic Domain Analyst.xml
- 15-DE - Domain Engineer.xml
- 20-UXD - User Experience Designer.xml
- 25-GM - GitHub Manager.xml
- 30-PE - Platform Engineer.xml
- 35-SEC - Security Specialist.xml
- 45-SE - Software Engineer.xml
- 50-DBA - Database Administrator.xml
- 55-FE - Frontend Engineer.xml
- 60-QAE - Quality Assurance Engineer.xml

**Exemplo de Output:**
```
🔍 DDD Workflow Structure Validator

📁 Validating folder structure...
  ✅ 00-doc-ddd/00-feedback
  ✅ 00-doc-ddd/02-strategic-design
  ❌ Missing: 00-doc-ddd/08-platform-engineering

🤖 Validating agent definitions...
  ✅ 10-SDA - Strategic Domain Analyst.xml (3 deliverables)
  ✅ 15-DE - Domain Engineer.xml (1 deliverables)
  ❌ Missing: 30-PE - Platform Engineer.xml

📝 Validating templates...
  ✅ .agents/templates/01-strategic-design/SDA-01-Event-Storming.template.md
  ⚠️  Template missing placeholders: UXD-02-Wireframes.template.md
     Missing: [PROJECT_NAME], [YYYY-MM-DD]

===========================================================
📊 VALIDATION SUMMARY
===========================================================

Errors: 2
Warnings: 1
Please fix errors before proceeding.
```

---

### 🔄 Quando Executar os Scripts

**Obrigatório:**
- ✅ **Antes de criar Pull Request** (garante qualidade)
- ✅ **Após adicionar novos documentos** (valida nomenclatura)
- ✅ **Após criar novos agentes XML** (valida estrutura)

**Recomendado:**
- ⏰ **Semanalmente** (detecção proativa de problemas)
- 🆕 **Após onboarding de novo dev** (garante conhecimento dos padrões)
- 🔧 **Após modificar templates** (valida consistência)

**Opcional:**
- 🔄 **Antes de cada commit** (git hook - configuração manual)
- 🚀 **CI/CD** (GitHub Actions - futuro)

---

### 📊 Exit Codes

Ambos os scripts retornam exit codes para integração com CI/CD:

| Exit Code | Significado | Ação |
|-----------|-------------|------|
| `0` | ✅ Tudo OK ou apenas warnings | Pode prosseguir |
| `1` | ❌ Erros encontrados | **Corrigir antes de continuar** |

**Exemplo de uso em CI:**
```powershell
.\.agents\scripts\validate-structure.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Validation failed!"
    exit 1
}
```

---

### 🛠️ Configuração de Git Hook (Opcional)

Para executar validação automaticamente antes de cada commit:

**1. Criar `.git/hooks/pre-commit` (Windows):**
```powershell
#!/usr/bin/env pwsh

Write-Host "`n🔍 Running validation checks...`n" -ForegroundColor Cyan

# Validar estrutura
.\.agents\scripts\validate-structure.ps1
$structureResult = $LASTEXITCODE

# Validar nomenclatura
.\.agents\scripts\validate-nomenclature.ps1
$nomenclatureResult = $LASTEXITCODE

if ($structureResult -ne 0 -or $nomenclatureResult -ne 0) {
    Write-Host "`n❌ Validation failed! Fix errors before committing.`n" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ All validations passed!`n" -ForegroundColor Green
exit 0
```

**2. Dar permissão de execução (Git Bash):**
```bash
chmod +x .git/hooks/pre-commit
```

---

### 💡 Troubleshooting

**Problema: "Execution of scripts is disabled on this system"**

**Solução (Windows PowerShell):**
```powershell
# Permitir execução de scripts locais (uma vez)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Ou executar diretamente
powershell -ExecutionPolicy Bypass -File .\.agents\scripts\validate-nomenclature.ps1
```

**Problema: "Cannot find path .agents/scripts"**

**Solução:**
```powershell
# Executar da raiz do projeto
cd c:\Users\Marco\Projetos\myTraderGEO
.\.agents\scripts\validate-nomenclature.ps1
```

**Problema: Script falha em Linux/Mac**

**Solução:**
- Scripts PowerShell requerem PowerShell Core (multiplataforma)
- Instalar: https://github.com/PowerShell/PowerShell
- Ou executar no Windows

---

## 📚 Referências

- **Agentes:** [01-Agents-Overview.md](01-Agents-Overview.md)
- **Nomenclatura:** [02-Nomenclature-Standards.md](02-Nomenclature-Standards.md)
- **Segurança:** [03-Security-And-Platform-Strategy.md](03-Security-And-Platform-Strategy.md)
- **Padrões DDD:** [04-DDD-Patterns-Reference.md](04-DDD-Patterns-Reference.md)
- **Padrões de API:** [05-API-Standards.md](05-API-Standards.md)
- **PE/SEC Checkpoints:** [07-PE-SEC-Checkpoint-Decision-Matrix.md](07-PE-SEC-Checkpoint-Decision-Matrix.md)
- **Fluxo de Feedback:** [08-FEEDBACK-FLOW-GUIDE.md](08-FEEDBACK-FLOW-GUIDE.md)
- **Think Mode:** [09-THINK-MODE-GUIDE.md](09-THINK-MODE-GUIDE.md)
- **Config Master:** `workflow-config.json`

---

**Versão:** 1.0
**Data:** 2025-10-09
**Processo:** Workflow DDD com 10 Agentes (Projetos Pequenos/Médios)
