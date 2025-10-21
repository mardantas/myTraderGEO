#!/bin/bash

# discovery-start.sh
# Initializes Discovery Foundation phase
#
# Usage: ./discovery-start.sh
#
# This script:
#   1. Creates Issue #1 (Discovery Foundation)
#   2. Creates Milestone M0
#   3. Switches to develop and updates it
#   4. Creates feature/discovery-foundation branch
#   5. Makes initial empty commit (workflow standard)
#   6. Pushes to remote with tracking
#   7. Creates Draft PR on GitHub

set -e

# Configuration
REPO="[GITHUB_OWNER]/[REPO_NAME]"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🚀 DISCOVERY FOUNDATION - START${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# STEP 1: CREATE ISSUE #1 (DISCOVERY FOUNDATION)
# ============================================================================
echo -e "${YELLOW}━━━ STEP 1/7: Creating Issue #1 (Discovery Foundation) ━━━${NC}"
echo ""

# Check if Issue #1 already exists
EXISTING_ISSUE=$(gh issue list --repo $REPO --limit 100 --json number,title --jq '.[] | select(.number == 1) | .number' 2>/dev/null || echo "")

if [ -n "$EXISTING_ISSUE" ]; then
  echo -e "  ${YELLOW}⚠️  Issue #1 already exists${NC}"
  echo -e "  ${BLUE}View Issue:${NC} gh issue view 1 --repo $REPO --web"
else
  ISSUE_BODY=$(cat <<'EOF'
## 🎯 Objetivo

Executar fase de Discovery completa do DDD Workflow v1.0, estabelecendo fundação estratégica e técnica do projeto.

## 👥 Agentes Envolvidos

- [ ] **SDA** - Strategic Domain Analyst
- [ ] **UXD** - User Experience Designer
- [ ] **GM** - GitHub Manager
- [ ] **PE** - Platform Engineer
- [ ] **SEC** - Security Specialist
- [ ] **QAE** - Quality Assurance Engineer

## 📋 Deliverables

### SDA (Strategic Domain Analyst)
- [ ] SDA-01-Event-Storming.md
- [ ] SDA-02-Context-Map.md
- [ ] SDA-03-Ubiquitous-Language.md

### UXD (User Experience Designer)
- [ ] UXD-00-Design-Foundations.md

### GM (GitHub Manager)
- [ ] GM-00-GitHub-Setup.md
- [ ] Labels configuradas
- [ ] CI/CD básico

### PE (Platform Engineer)
- [ ] PE-00-Environments-Setup.md
- [ ] Docker Compose (dev/stage/prod)
- [ ] Scripts de deploy

### SEC (Security Specialist)
- [ ] SEC-00-Security-Baseline.md

### QAE (Quality Assurance Engineer)
- [ ] QAE-00-Test-Strategy.md

## ⏱️ Estimativa

3-4 dias (conforme Workflow Guide - Fase Discovery)

## 🔗 Referências

- [Workflow Guide](.agents/docs/00-Workflow-Guide.md)
- [Agents Overview](.agents/docs/01-Agents-Overview.md)

---

🤖 **Issue criada via discovery-start.sh**
EOF
)

  gh issue create \
    --repo $REPO \
    --title "[EPIC-00] Discovery Foundation - Modelagem Estratégica e Setup Inicial" \
    --label "epic,discovery,setup,priority-high" \
    --body "$ISSUE_BODY" > /dev/null 2>&1

  echo -e "  ${GREEN}✅ Issue #1 created${NC}"
fi
echo ""

# ============================================================================
# STEP 2: CREATE MILESTONE M0
# ============================================================================
echo -e "${YELLOW}━━━ STEP 2/7: Creating Milestone M0 ━━━${NC}"
echo ""

# Check if milestone exists
EXISTING_MILESTONE=$(gh api repos/$REPO/milestones --jq '.[] | select(.title | startswith("M0:")) | .number' 2>/dev/null || echo "")

if [ -n "$EXISTING_MILESTONE" ]; then
  echo -e "  ${YELLOW}⚠️  Milestone M0 already exists${NC}"
else
  gh api repos/$REPO/milestones -X POST \
    -f title="M0: Discovery Foundation" \
    -f description="Setup inicial completo: SDA, UXD, GM, PE, SEC, QAE deliverables" \
    -f state="open" > /dev/null 2>&1

  echo -e "  ${GREEN}✅ Milestone M0 created${NC}"
fi
echo ""

# ============================================================================
# STEP 3: VALIDATE & SWITCH TO DEVELOP
# ============================================================================
echo -e "${YELLOW}━━━ STEP 3/7: Validating and switching to develop ━━━${NC}"
echo ""

CURRENT_BRANCH=$(git branch --show-current)
echo -e "  Current branch: ${BLUE}$CURRENT_BRANCH${NC}"

if [[ "$CURRENT_BRANCH" != "develop" ]]; then
  echo -e "  ${YELLOW}⚠️  Not on develop, switching...${NC}"
  git checkout develop
  git pull origin develop
  echo -e "  ${GREEN}✅ Switched to develop and updated${NC}"
else
  echo -e "  ${GREEN}✅ Already on develop${NC}"
  git pull origin develop
  echo -e "  ${GREEN}✅ Develop updated${NC}"
fi

echo ""

# ============================================================================
# STEP 4: CHECK IF BRANCH ALREADY EXISTS
# ============================================================================
echo -e "${YELLOW}━━━ STEP 4/7: Checking if branch exists ━━━${NC}"
echo ""

if git show-ref --verify --quiet refs/heads/feature/discovery-foundation; then
  echo -e "  ${YELLOW}⚠️  Branch 'feature/discovery-foundation' already exists${NC}"
  echo ""
  read -p "  Continue anyway? This will checkout the existing branch. (y/n) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
  fi
  git checkout feature/discovery-foundation
  echo -e "  ${GREEN}✅ Checked out existing branch${NC}"
  BRANCH_EXISTS=true
else
  echo -e "  ${GREEN}✅ Branch doesn't exist (will create)${NC}"
  BRANCH_EXISTS=false
fi
echo ""

# ============================================================================
# STEP 5: CREATE BRANCH & INITIAL COMMIT
# ============================================================================
echo -e "${YELLOW}━━━ STEP 5/7: Creating branch and initial commit ━━━${NC}"
echo ""

if [ "$BRANCH_EXISTS" = false ]; then
  # Create branch
  git checkout -b feature/discovery-foundation
  echo -e "  ${GREEN}✅ Branch created: feature/discovery-foundation${NC}"

  # Initial empty commit (workflow standard)
  git commit --allow-empty -m "chore: Início de uma nova feature

Feature: Discovery Foundation
Issue: #1

Este commit marca o início do trabalho na feature de Discovery Foundation."

  echo -e "  ${GREEN}✅ Initial empty commit created${NC}"

  # Push with tracking
  git push origin feature/discovery-foundation -u
  echo -e "  ${GREEN}✅ Pushed to remote${NC}"
else
  echo -e "  ${YELLOW}⚠️  Branch already exists, skipping creation${NC}"
fi
echo ""

# ============================================================================
# STEP 6: CREATE DRAFT PR
# ============================================================================
echo -e "${YELLOW}━━━ STEP 6/7: Creating Draft PR ━━━${NC}"
echo ""

# Check if PR already exists
EXISTING_PR=$(gh pr list --head feature/discovery-foundation --repo $REPO --json number -q '.[0].number' 2>/dev/null || echo "")

if [ -n "$EXISTING_PR" ]; then
  echo -e "  ${YELLOW}⚠️  PR already exists: #${EXISTING_PR}${NC}"
  echo -e "  ${BLUE}View PR:${NC} gh pr view $EXISTING_PR --repo $REPO --web"
else
  PR_BODY=$(cat <<EOF
🚧 Work in Progress - Discovery Foundation

## 📋 Deliverables

- [ ] SDA-01-Event-Storming.md
- [ ] SDA-02-Context-Map.md
- [ ] SDA-03-Ubiquitous-Language.md
- [ ] UXD-00-Design-Foundations.md
- [ ] GM-00-GitHub-Setup.md
- [ ] PE-00-Environments-Setup.md
- [ ] SEC-00-Security-Baseline.md
- [ ] QAE-00-Test-Strategy.md

## 📖 Reference

- Workflow: [.agents/docs/00-Workflow-Guide.md](.agents/docs/00-Workflow-Guide.md)
- Git Patterns: [.agents/docs/03-GIT-PATTERNS.md](.agents/docs/03-GIT-PATTERNS.md)

Ref #1

🤖 Generated with GM discovery-start.sh
EOF
)

  gh pr create --draft \
    --repo $REPO \
    --title "[DISCOVERY] Foundation" \
    --body "$PR_BODY" \
    --base develop \
    --head feature/discovery-foundation

  PR_NUMBER=$(gh pr list --head feature/discovery-foundation --repo $REPO --json number -q '.[0].number')
  echo -e "  ${GREEN}✅ Draft PR created: #${PR_NUMBER}${NC}"
fi
echo ""

# ============================================================================
# STEP 7: LINK ISSUE TO MILESTONE
# ============================================================================
echo -e "${YELLOW}━━━ STEP 7/7: Linking Issue #1 to Milestone M0 ━━━${NC}"
echo ""

# Get Milestone M0 number
MILESTONE_NUMBER=$(gh api repos/$REPO/milestones --jq '.[] | select(.title | startswith("M0:")) | .number' 2>/dev/null || echo "")

if [ -n "$MILESTONE_NUMBER" ]; then
  # Link Issue #1 to Milestone M0
  gh api repos/$REPO/issues/1 -X PATCH -f milestone="$MILESTONE_NUMBER" > /dev/null 2>&1
  echo -e "  ${GREEN}✅ Issue #1 linked to Milestone M0${NC}"
else
  echo -e "  ${YELLOW}⚠️  Milestone M0 not found, skipping link${NC}"
fi
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ DISCOVERY FOUNDATION STARTED!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo "1. Invoke agents to create deliverables:"
echo "   - SDA (Strategic Domain Analyst)"
echo "   - UXD (UX Designer)"
echo "   - GM (GitHub Manager)"
echo "   - PE (Platform Engineer)"
echo "   - SEC (Security Engineer)"
echo "   - QAE (Quality Assurance Engineer)"
echo ""
echo "2. When all deliverables complete:"
echo "   ./discovery-finish.sh --merge"
echo ""
echo -e "${BLUE}📖 Documentation:${NC}"
echo "   - Git workflow: .agents/docs/03-GIT-PATTERNS.md#guia-operacional-encerrar-discovery-foundation"
echo "   - Workflow guide: .agents/docs/00-Workflow-Guide.md"
echo ""
