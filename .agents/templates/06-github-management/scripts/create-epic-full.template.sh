#!/bin/bash

# create-epic-full.sh
# Creates COMPLETE epic setup: milestone + epic issue + agent issues (all at once)
#
# Usage: ./create-epic-full.sh <epic-number> "<epic-name>" "<due-date-YYYY-MM-DD>"
#
# Examples:
#   ./create-epic-full.sh 1 "Criar Estratégia Bull Call Spread" "2026-02-28"
#   ./create-epic-full.sh 2 "Calcular Greeks em Tempo Real" "2026-03-31"
#
# This script creates:
#   1. Milestone M{N}
#   2. Issue #X: [EPIC-{N}] Epic Name (parent)
#   3. Issue #X+1: DE - Domain Model
#   4. Issue #X+2: DBA - Schema Review
#   5. Issue #X+3: SE - Backend Implementation
#   6. Issue #X+4: UXD - Wireframes
#   7. Issue #X+5: FE - Frontend Implementation
#   8. Issue #X+6: QAE - Quality Gate

set -e

# Configuration
REPO="[GITHUB_OWNER]/[REPO_NAME]"

# Parameters
EPIC_NUM=$1
EPIC_NAME=$2
DUE_DATE=$3

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Validation
if [ -z "$EPIC_NUM" ] || [ -z "$EPIC_NAME" ]; then
  echo -e "${RED}❌ Error: Missing required parameters${NC}"
  echo ""
  echo "Usage: $0 <epic-number> \"<epic-name>\" \"<due-date-YYYY-MM-DD>\""
  echo ""
  echo "Examples:"
  echo "  $0 1 \"Criar Estratégia Bull Call Spread\" \"2026-02-28\""
  echo "  $0 2 \"Calcular Greeks em Tempo Real\" \"2026-03-31\""
  echo ""
  exit 1
fi

EPIC_NUM_PADDED=$(printf "%02d" $EPIC_NUM)
MILESTONE_TITLE="M${EPIC_NUM}: EPIC-${EPIC_NUM_PADDED} - ${EPIC_NAME}"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🚀 CREATE EPIC-${EPIC_NUM_PADDED} FULL SETUP${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Epic Name:${NC} ${EPIC_NAME}"
echo -e "${BLUE}Milestone:${NC} ${MILESTONE_TITLE}"
echo -e "${BLUE}Due Date:${NC} ${DUE_DATE:-Not set}"
echo ""
echo -e "${YELLOW}This will create:${NC}"
echo "  1️⃣  Milestone M${EPIC_NUM}"
echo "  2️⃣  Epic Issue (parent)"
echo "  3️⃣  6 Agent Issues (DE, DBA, SE, UXD, FE, QAE)"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Cancelled.${NC}"
  exit 0
fi
echo ""

# ============================================================================
# STEP 1: CREATE MILESTONE
# ============================================================================
echo -e "${YELLOW}━━━ STEP 1/2: Creating Milestone M${EPIC_NUM} ━━━${NC}"
echo ""

# Build milestone command
MILESTONE_DESC="Epic ${EPIC_NUM_PADDED}: ${EPIC_NAME} - Automated setup via GM"
CMD="gh api repos/$REPO/milestones -X POST"
CMD="$CMD -f title=\"$MILESTONE_TITLE\""
CMD="$CMD -f description=\"$MILESTONE_DESC\""

if [ -n "$DUE_DATE" ]; then
  ISO_DATE="${DUE_DATE}T23:59:59Z"
  CMD="$CMD -f due_on=\"$ISO_DATE\""
fi

CMD="$CMD -f state=\"open\""

# Execute
echo "  Creating milestone..."
eval $CMD > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo -e "  ${GREEN}✅ Milestone M${EPIC_NUM} created${NC}"
else
  echo -e "  ${RED}❌ Failed to create milestone${NC}"
  exit 1
fi
echo ""

# ============================================================================
# STEP 2: CREATE ISSUES
# ============================================================================
echo -e "${YELLOW}━━━ STEP 2/2: Creating Issues ━━━${NC}"
echo ""

# Agent configurations
declare -a AGENTS=(
  "EPIC|[EPIC-${EPIC_NUM_PADDED}] ${EPIC_NAME}|epic,priority-high,type:epic"
  "DE|DE: Domain Model EPIC-${EPIC_NUM_PADDED}|agent:DE,type:technical-task,priority-high"
  "DBA|DBA: Schema Review EPIC-${EPIC_NUM_PADDED}|agent:DBA,type:technical-task,priority-high"
  "SE|SE: Backend Implementation EPIC-${EPIC_NUM_PADDED}|agent:SE,type:technical-task,priority-high"
  "UXD|UXD: Wireframes EPIC-${EPIC_NUM_PADDED}|agent:UXD,type:technical-task,priority-medium"
  "FE|FE: Frontend Implementation EPIC-${EPIC_NUM_PADDED}|agent:FE,type:technical-task,priority-high"
  "QAE|QAE: Quality Gate EPIC-${EPIC_NUM_PADDED}|agent:QAE,type:technical-task,priority-high"
)

# Epic issue body
EPIC_BODY=$(cat <<EOF
## 📋 Epic Overview

**Epic Number:** ${EPIC_NUM_PADDED}
**Epic Name:** ${EPIC_NAME}
**Milestone:** ${MILESTONE_TITLE}

---

## 🎯 Objectives

[TODO: Copy objectives from DE-01-EPIC-${EPIC_NUM_PADDED}-*.md]

1. Objective 1
2. Objective 2
3. Objective 3

---

## ✅ Acceptance Criteria

[TODO: Copy acceptance criteria from DE-01]

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

---

## 📦 Sub-Issues

This epic is tracked via the following issues:

- [ ] DE: Domain Model
- [ ] DBA: Schema Review
- [ ] SE: Backend Implementation
- [ ] UXD: Wireframes
- [ ] FE: Frontend Implementation
- [ ] QAE: Quality Gate

---

## 🔗 Related Documents

- **DE-01:** \`00-doc-ddd/04-tactical-design/DE-01-EPIC-${EPIC_NUM_PADDED}-*.md\`
- **SDA-01:** [00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md](00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md)
- **SDA-02:** [00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md](00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md)
- **Git Patterns:** [.agents/docs/03-GIT-PATTERNS.md](.agents/docs/03-GIT-PATTERNS.md)

---

**⚠️ TODO:** Customize this epic with DE-01 details:
- Add Bounded Context labels (bc:*)
- Copy objectives and acceptance criteria
- Update sub-issues checklist with actual issue numbers

🤖 Generated with GM create-epic-full.sh
EOF
)

# Agent issue bodies
DE_BODY="## 📋 Task: Domain Model

Create domain model for EPIC-${EPIC_NUM_PADDED}: ${EPIC_NAME}

**Deliverable:** \`00-doc-ddd/04-tactical-design/DE-01-EPIC-${EPIC_NUM_PADDED}-${EPIC_NAME// /-}-Domain-Model.md\`

**Checklist:**
- [ ] Aggregates identified
- [ ] Domain events defined
- [ ] Business rules documented
- [ ] Use cases specified

**Ref:** Epic issue (will be linked automatically)

🤖 Generated with GM"

DBA_BODY="## 📋 Task: Schema Review

Review schema for EPIC-${EPIC_NUM_PADDED}: ${EPIC_NAME}

**Deliverable:** \`00-doc-ddd/05-database-design/DBA-01-EPIC-${EPIC_NUM_PADDED}-Schema-Review.md\`

**Checklist:**
- [ ] EF Core migrations created
- [ ] Indexes defined
- [ ] Constraints validated
- [ ] Performance review

**Depends on:** DE domain model

🤖 Generated with GM"

SE_BODY="## 📋 Task: Backend Implementation

Implement backend for EPIC-${EPIC_NUM_PADDED}: ${EPIC_NAME}

**Checklist:**
- [ ] Domain layer (aggregates, entities, VOs)
- [ ] Application layer (commands, handlers)
- [ ] Infrastructure (repositories)
- [ ] API endpoints
- [ ] Unit tests (>80%)
- [ ] Integration tests

**Depends on:** DE + DBA

🤖 Generated with GM"

UXD_BODY="## 📋 Task: Wireframes

Create wireframes for EPIC-${EPIC_NUM_PADDED}: ${EPIC_NAME}

**Deliverable:** \`00-doc-ddd/03-ux-design/UXD-01-EPIC-${EPIC_NUM_PADDED}-Wireframes.md\`

**Checklist:**
- [ ] User flows
- [ ] Wireframes (desktop + mobile)
- [ ] Component breakdown
- [ ] States (loading, success, error)

**Depends on:** DE domain model

🤖 Generated with GM"

FE_BODY="## 📋 Task: Frontend Implementation

Implement frontend for EPIC-${EPIC_NUM_PADDED}: ${EPIC_NAME}

**Checklist:**
- [ ] Components implemented
- [ ] Stores (Pinia)
- [ ] API integration
- [ ] Responsive design
- [ ] Unit tests (Vitest)

**Depends on:** SE (API) + UXD (wireframes)

🤖 Generated with GM"

QAE_BODY="## 📋 Task: Quality Gate

Execute quality gate for EPIC-${EPIC_NUM_PADDED}: ${EPIC_NAME}

**Deliverable:** \`00-doc-ddd/06-quality-assurance/QAE-01-EPIC-${EPIC_NUM_PADDED}-Quality-Gate.md\`

**Checklist:**
- [ ] E2E tests (Playwright)
- [ ] Smoke tests (staging)
- [ ] Performance baseline
- [ ] Regression tests
- [ ] ✅ APPROVE or ❌ REJECT

**Closes epic** - Use \`Closes #X\` in final commit

🤖 Generated with GM"

# Create issues
for agent_config in "${AGENTS[@]}"; do
  IFS='|' read -r AGENT_CODE ISSUE_TITLE LABELS <<< "$agent_config"

  # Select body based on agent
  case $AGENT_CODE in
    EPIC) BODY="$EPIC_BODY" ;;
    DE)   BODY="$DE_BODY" ;;
    DBA)  BODY="$DBA_BODY" ;;
    SE)   BODY="$SE_BODY" ;;
    UXD)  BODY="$UXD_BODY" ;;
    FE)   BODY="$FE_BODY" ;;
    QAE)  BODY="$QAE_BODY" ;;
  esac

  echo -e "  Creating ${BLUE}${AGENT_CODE}${NC} issue..."

  gh issue create --repo $REPO \
    --title "$ISSUE_TITLE" \
    --label "$LABELS" \
    --milestone "$MILESTONE_TITLE" \
    --body "$BODY" > /dev/null 2>&1

  if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✅ ${AGENT_CODE} issue created${NC}"
  else
    echo -e "  ${RED}❌ Failed to create ${AGENT_CODE} issue${NC}"
  fi
done

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ EPIC-${EPIC_NUM_PADDED} SETUP COMPLETE!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo "1. View all issues:"
echo "   gh issue list --milestone \"${MILESTONE_TITLE}\" --repo $REPO"
echo ""
echo "2. Customize epic issue:"
echo "   - Add BC labels (bc:*)"
echo "   - Copy objectives from DE-01"
echo "   - Update sub-issues checklist with actual issue numbers"
echo ""
echo "3. Start working on DE issue:"
echo "   ./start-work-on-issue.sh <issue-number>"
echo ""
echo -e "${BLUE}📖 Documentation:${NC}"
echo "   - Git workflow: .agents/docs/03-GIT-PATTERNS.md"
echo "   - GM setup: 00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md"
echo ""
