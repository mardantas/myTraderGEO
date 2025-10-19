#!/bin/bash

# setup-labels.sh
# Script para criar/atualizar labels do GitHub para o projeto myTraderGEO
# Baseado em SDA-02 (Bounded Contexts) e SDA-01 (Epics)

set -e  # Exit on error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuração
OWNER="${GITHUB_OWNER:-mardantas}"
REPO="${GITHUB_REPO:-myTraderGEO}"

# Verificar se gh está instalado
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Erro: GitHub CLI (gh) não está instalado.${NC}"
    echo "Instale via: https://cli.github.com/"
    exit 1
fi

# Verificar autenticação
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Erro: Não autenticado no GitHub CLI.${NC}"
    echo "Execute: gh auth login"
    exit 1
fi

echo -e "${GREEN}=== Setup de Labels para ${OWNER}/${REPO} ===${NC}\n"

# Função para criar ou atualizar label
create_or_update_label() {
    local name="$1"
    local color="$2"
    local description="$3"

    # Verificar se label existe
    if gh label list --repo "${OWNER}/${REPO}" --json name --jq ".[].name" | grep -q "^${name}$"; then
        # Atualizar label existente
        gh label edit "$name" --repo "${OWNER}/${REPO}" --color "$color" --description "$description" 2>/dev/null || {
            echo -e "${YELLOW}⚠ Não foi possível atualizar label: ${name}${NC}"
        }
        echo -e "${YELLOW}↻ Atualizado: ${name}${NC}"
    else
        # Criar novo label
        gh label create "$name" --repo "${OWNER}/${REPO}" --color "$color" --description "$description" 2>/dev/null || {
            echo -e "${RED}✗ Erro ao criar label: ${name}${NC}"
            return 1
        }
        echo -e "${GREEN}✓ Criado: ${name}${NC}"
    fi
}

echo -e "${GREEN}1. Labels de Bounded Contexts (SDA-02)${NC}"

# Core Domain (vermelho forte)
create_or_update_label "bc:strategy-planning" "c92a2a" "Bounded Context: Strategy Planning (Core Domain)"
create_or_update_label "bc:trade-execution" "e03131" "Bounded Context: Trade Execution (Core Domain)"
create_or_update_label "bc:risk-management" "f03e3e" "Bounded Context: Risk Management (Core Domain)"

# Supporting Domain (azul)
create_or_update_label "bc:market-data" "1971c2" "Bounded Context: Market Data (Supporting)"
create_or_update_label "bc:asset-management" "1c7ed6" "Bounded Context: Asset Management (Supporting)"
create_or_update_label "bc:community-sharing" "339af0" "Bounded Context: Community & Sharing (Supporting)"
create_or_update_label "bc:consultant-services" "4dabf7" "Bounded Context: Consultant Services (Supporting)"

# Generic Domain (verde)
create_or_update_label "bc:user-management" "2f9e44" "Bounded Context: User Management (Generic)"
create_or_update_label "bc:analytics-ai" "51cf66" "Bounded Context: Analytics & AI (Generic - Futuro)"

echo ""
echo -e "${GREEN}2. Labels de Tipo de Issue${NC}"

create_or_update_label "epic" "5319e7" "Epic - Grande funcionalidade cross-BC"
create_or_update_label "user-story" "7950f2" "User Story - Funcionalidade do usuário"
create_or_update_label "task" "9775fa" "Task - Tarefa técnica ou subtarefa"
create_or_update_label "bug" "d73a4a" "Bug - Defeito a ser corrigido"
create_or_update_label "hotfix" "b60205" "Hotfix - Correção urgente em produção"
create_or_update_label "spike" "f9c74f" "Spike - Pesquisa/investigação técnica"
create_or_update_label "refactor" "fbca04" "Refactoring - Melhoria de código sem nova funcionalidade"
create_or_update_label "tech-debt" "fef2c0" "Tech Debt - Débito técnico a ser resolvido"

echo ""
echo -e "${GREEN}3. Labels de Prioridade${NC}"

create_or_update_label "priority-critical" "b60205" "Prioridade: Crítica (blocker)"
create_or_update_label "priority-high" "d93f0b" "Prioridade: Alta"
create_or_update_label "priority-medium" "fbca04" "Prioridade: Média"
create_or_update_label "priority-low" "0e8a16" "Prioridade: Baixa"

echo ""
echo -e "${GREEN}4. Labels de Status/Workflow${NC}"

create_or_update_label "status:blocked" "d73a4a" "Bloqueado - aguardando dependência"
create_or_update_label "status:ready" "0e8a16" "Pronto para desenvolvimento"
create_or_update_label "status:in-progress" "fbca04" "Em desenvolvimento"
create_or_update_label "status:in-review" "1d76db" "Em revisão (code review)"
create_or_update_label "status:testing" "5319e7" "Em teste (QA)"
create_or_update_label "status:done" "0e8a16" "Concluído"

echo ""
echo -e "${GREEN}5. Labels de Agents Responsáveis${NC}"

create_or_update_label "agent:SDA" "d4c5f9" "Agent: Strategic Design Architect"
create_or_update_label "agent:DE" "1f77b4" "Agent: Domain Engineer (Backend .NET)"
create_or_update_label "agent:FE" "ff7f0e" "Agent: Frontend Engineer (Vue 3)"
create_or_update_label "agent:DBA" "2ca02c" "Agent: Database Architect (PostgreSQL)"
create_or_update_label "agent:PE" "9467bd" "Agent: Platform Engineer (Infra)"
create_or_update_label "agent:GM" "8c564b" "Agent: GitHub Manager"
create_or_update_label "agent:SEC" "e377c2" "Agent: Security Specialist"
create_or_update_label "agent:QAE" "7f7f7f" "Agent: Quality Assurance Engineer"
create_or_update_label "agent:UXD" "bcbd22" "Agent: UX Designer"
create_or_update_label "agent:SE" "17becf" "Agent: Solution Engineer (Integrator)"

echo ""
echo -e "${GREEN}6. Labels de Épicos (SDA-01/SDA-02)${NC}"

create_or_update_label "EPIC-01" "5319e7" "Epic 01: Criação e Análise de Estratégias"
create_or_update_label "EPIC-02" "5319e7" "Epic 02: Execução e Monitoramento"
create_or_update_label "EPIC-03" "5319e7" "Epic 03: Gestão de Risco e Controle Financeiro"
create_or_update_label "EPIC-04" "5319e7" "Epic 04: Comunidade e Compartilhamento"
create_or_update_label "EPIC-05" "5319e7" "Epic 05: Serviços para Consultores"
create_or_update_label "EPIC-06" "9775fa" "Epic 06: Backtesting e Análise (Futuro)"
create_or_update_label "EPIC-07" "9775fa" "Epic 07: Execução Automatizada (Futuro)"

echo ""
echo -e "${GREEN}7. Labels Técnicas${NC}"

create_or_update_label "tech:backend" "1971c2" "Tech: Backend .NET 8"
create_or_update_label "tech:frontend" "ff7f0e" "Tech: Frontend Vue 3"
create_or_update_label "tech:database" "2f9e44" "Tech: Database PostgreSQL"
create_or_update_label "tech:infra" "9467bd" "Tech: Infrastructure/DevOps"
create_or_update_label "tech:security" "e377c2" "Tech: Security"
create_or_update_label "tech:testing" "7f7f7f" "Tech: Testing/QA"

echo ""
echo -e "${GREEN}8. Labels de Documentação${NC}"

create_or_update_label "docs" "0075ca" "Documentation - Documentação técnica"
create_or_update_label "docs:api" "1d76db" "API Documentation"
create_or_update_label "docs:architecture" "5319e7" "Architecture Documentation"
create_or_update_label "docs:user" "51cf66" "User Documentation"

echo ""
echo -e "${GREEN}9. Labels de Ambiente${NC}"

create_or_update_label "env:development" "bfd4f2" "Environment: Development"
create_or_update_label "env:staging" "fbca04" "Environment: Staging"
create_or_update_label "env:production" "d73a4a" "Environment: Production"

echo ""
echo -e "${GREEN}10. Labels Especiais${NC}"

create_or_update_label "good-first-issue" "7057ff" "Boa primeira issue para novos contribuidores"
create_or_update_label "help-wanted" "008672" "Ajuda externa necessária"
create_or_update_label "question" "d876e3" "Questão/dúvida a ser respondida"
create_or_update_label "duplicate" "cfd3d7" "Issue duplicada"
create_or_update_label "wontfix" "ffffff" "Não será corrigido/implementado"
create_or_update_label "invalid" "e4e669" "Issue inválida"
create_or_update_label "dependencies" "0366d6" "Atualização de dependências"

echo ""
echo -e "${GREEN}=== Setup Completo! ===${NC}"
echo -e "Total de labels configurados: ${GREEN}$(gh label list --repo "${OWNER}/${REPO}" --json name --jq '. | length')${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Revisar labels criados: gh label list --repo ${OWNER}/${REPO}"
echo "2. Criar milestones para os épicos: ver GM-00-GitHub-Setup.md"
echo "3. Criar epic issues: ver GM-00-GitHub-Setup.md"
