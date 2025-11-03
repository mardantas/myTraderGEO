#!/bin/bash

# epic-modeling-start.sh
# Starts epic modeling phase (Domain Engineer creates DE-01)
#
# Usage: ./epic-modeling-start.sh <epic-number>
#
# Example:
#   ./epic-modeling-start.sh 1  # EPIC-01
#
# This script:
#   1. Validates current branch (develop)
#   2. Updates develop
#   3. Creates feature/epic-<N>-domain-model branch
#   4. Guides DE to create DE-01-EPIC-<N>-*.md

set -e

# Configuration
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "[GITHUB_OWNER]/[REPO_NAME]")

# Parameters
EPIC_NUM=$1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Validation
if [ -z "$EPIC_NUM" ]; then
  echo -e "${RED}❌ Error: Missing epic number${NC}"
  echo ""
  echo "Usage: $0 <epic-number>"
  echo ""
  echo "Examples:"
  echo "  $0 1  # EPIC-01"
  echo "  $0 2  # EPIC-02"
  echo ""
  exit 1
fi

EPIC_NUM_PADDED=$(printf "%02d" $EPIC_NUM)
BRANCH_NAME="feature/epic-${EPIC_NUM_PADDED}-domain-model"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🎨 EPIC-${EPIC_NUM_PADDED} MODELING - START${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# STEP 1: VALIDATE CURRENT BRANCH
# ============================================================================
echo -e "${YELLOW}━━━ STEP 1/3: Validating current branch ━━━${NC}"
echo ""

CURRENT_BRANCH=$(git branch --show-current)
echo -e "  Current branch: ${BLUE}$CURRENT_BRANCH${NC}"

if [[ "$CURRENT_BRANCH" != "develop" ]]; then
  echo -e "  ${RED}❌ Error: Must be on 'develop' branch${NC}"
  echo ""
  echo "  Switch to develop:"
  echo "    git checkout develop"
  exit 1
fi

echo -e "  ${GREEN}✅ Valid branch${NC}"
echo ""

# ============================================================================
# STEP 2: UPDATE DEVELOP
# ============================================================================
echo -e "${YELLOW}━━━ STEP 2/3: Updating develop ━━━${NC}"
echo ""

git pull origin develop

echo -e "  ${GREEN}✅ Develop updated${NC}"
echo ""

# ============================================================================
# STEP 3: CREATE BRANCH
# ============================================================================
echo -e "${YELLOW}━━━ STEP 3/3: Creating branch ━━━${NC}"
echo ""

# Check if branch already exists
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
  echo -e "  ${YELLOW}⚠️  Branch '$BRANCH_NAME' already exists${NC}"
  echo ""
  read -p "  Continue anyway? This will checkout the existing branch. (y/n) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
  fi
  git checkout $BRANCH_NAME
  echo -e "  ${GREEN}✅ Checked out existing branch${NC}"
else
  git checkout -b $BRANCH_NAME
  echo -e "  ${GREEN}✅ Branch created: $BRANCH_NAME${NC}"
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ EPIC-${EPIC_NUM_PADDED} MODELING STARTED!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps for Domain Engineer (DE):${NC}"
echo ""
echo "1. Create domain model file:"
echo "   ${BLUE}00-doc-ddd/04-tactical-design/DE-01-EPIC-${EPIC_NUM_PADDED}-<EpicName>-Domain-Model.md${NC}"
echo ""
echo "2. Document in DE-01:"
echo "   - Aggregates (entities, value objects)"
echo "   - Domain Events"
echo "   - Use Cases"
echo "   - Repository interfaces"
echo "   - Business rules"
echo ""
echo "3. When complete, finalize modeling:"
echo "   ./epic-modeling-finish.sh $EPIC_NUM"
echo ""
echo -e "${BLUE}📖 Reference:${NC}"
echo "   - Template: .agents/templates/03-tactical-design/DE-01-[EpicName]-Tactical-Model.template.md"
echo "   - DDD Patterns: .agents/docs/05-DDD-Patterns-Reference.md"
echo ""
