#!/bin/bash

# create-epic-issue.sh
# Creates an epic issue on-demand (after DE-01 is complete)
#
# Usage: ./create-epic-issue.sh <epic-number> "<milestone-title>"
#
# Examples:
#   ./create-epic-issue.sh 1 "M1: EPIC-01 - Criação e Análise de Estratégias"
#   ./create-epic-issue.sh 2 "M2: EPIC-02 - Execução e Monitoramento"

set -e

# Configuration
REPO="[GITHUB_OWNER]/[REPO_NAME]"

# Parameters
EPIC_NUM=$1
MILESTONE_TITLE=$2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation
if [ -z "$EPIC_NUM" ] || [ -z "$MILESTONE_TITLE" ]; then
  echo -e "${RED}❌ Error: Missing required parameters${NC}"
  echo ""
  echo "Usage: $0 <epic-number> \"<milestone-title>\""
  echo ""
  echo "Examples:"
  echo "  $0 1 \"M1: EPIC-01 - Criação e Análise de Estratégias\""
  echo "  $0 2 \"M2: EPIC-02 - Execução e Monitoramento\""
  echo ""
  exit 1
fi

EPIC_NUM_PADDED=$(printf "%02d" $EPIC_NUM)

echo -e "${YELLOW}🚀 Creating Epic Issue #EPIC-${EPIC_NUM_PADDED}...${NC}"
echo ""

# Check if DE-01 exists (optional warning)
DE_PATTERN="00-doc-ddd/04-tactical-design/DE-01-EPIC-${EPIC_NUM_PADDED}-*.md"
if ! ls $DE_PATTERN 1> /dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  Warning: DE-01 file not found at:${NC}"
  echo "  $DE_PATTERN"
  echo ""
  echo -e "${BLUE}ℹ️  Expected: Epic issue should be created AFTER DE-01 is complete${NC}"
  echo ""
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Epic issue body template
ISSUE_BODY=$(cat <<EOF
## 📋 Epic Overview

**Epic Number:** ${EPIC_NUM_PADDED}
**Epic Name:** [TODO: Customize from DE-01]
**Business Value:** [TODO: Customize from DE-01]

---

## 🎯 Bounded Contexts Involved

[TODO: List BCs from DE-01 and SDA-02]

- **[BC_1]** (Core/Supporting/Generic): [Brief description]
- **[BC_2]** (Core/Supporting/Generic): [Brief description]

---

## 📊 Objectives

[TODO: Copy objectives from DE-01]

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

## 📦 Deliverables

### DE - Domain Engineer
- [ ] DE-01-EPIC-${EPIC_NUM_PADDED}-{EpicName}-Domain-Model.md
- [ ] Domain events identified and documented
- [ ] Business rules validated with domain experts

### DBA - Database Administrator
- [ ] DBA-01-EPIC-${EPIC_NUM_PADDED}-Schema-Review.md
- [ ] EF Core migrations created and tested
- [ ] Indexes and constraints defined

### SE - Software Engineer (Backend)
- [ ] Domain layer implemented (aggregates, entities, VOs)
- [ ] Application layer implemented (commands, queries, handlers)
- [ ] API endpoints implemented and documented
- [ ] Unit tests (>80% coverage)
- [ ] Integration tests (critical paths)

### FE - Frontend Engineer
- [ ] Vue components implemented
- [ ] Pinia stores implemented
- [ ] API integration complete
- [ ] Unit tests (Vitest)
- [ ] Responsive design validated

### QAE - Quality Assurance Engineer (Quality Gate)
- [ ] E2E tests implemented (Playwright)
- [ ] Smoke tests passing
- [ ] Performance baseline validated
- [ ] QAE-01-EPIC-${EPIC_NUM_PADDED}-Quality-Gate.md

---

## 📋 Definition of Done

- [ ] All deliverables completed and reviewed
- [ ] All tests passing (unit, integration, E2E)
- [ ] Code reviewed and approved
- [ ] Documentation updated (API docs, ADRs, user docs)
- [ ] Deployed to staging and validated
- [ ] Performance baseline met
- [ ] Security review passed (if required)
- [ ] Ready for production deployment

---

## 🔗 Related Documents

- **DE-01:** [Link to domain model when available]
- **SDA-01:** [00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md](00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md)
- **SDA-02:** [00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md](00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md)

---

**⚠️ TODO:** Edit this epic issue to customize with DE-01 details:
- Epic name and business value
- Bounded Contexts involved
- Objectives and acceptance criteria
- Add BC labels (bc:*)

🤖 Generated with GM create-epic-issue.sh
EOF
)

# Default labels (customize based on project)
LABELS="epic,priority-high,agent:DE,agent:DBA,agent:SE,agent:FE,agent:QAE"

# Create issue
echo "Creating epic issue..."
echo ""

gh issue create --repo $REPO \
  --title "[EPIC-${EPIC_NUM_PADDED}] [TODO: Epic Name]" \
  --label "$LABELS" \
  --milestone "$MILESTONE_TITLE" \
  --body "$ISSUE_BODY"

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✅ Epic issue created successfully!${NC}"
  echo ""
  echo -e "${YELLOW}⚠️  NEXT STEPS:${NC}"
  echo "1. Edit the issue to customize with DE-01 details"
  echo "2. Update title: [EPIC-${EPIC_NUM_PADDED}] <Epic Name from DE-01>"
  echo "3. Add BC labels: bc:strategy-planning, bc:market-data, etc"
  echo "4. Fill objectives, acceptance criteria, business value"
  echo ""
  echo "View issue:"
  echo "  gh issue list --label epic --repo $REPO"
else
  echo -e "${RED}❌ Failed to create epic issue${NC}"
  exit 1
fi
