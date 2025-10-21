#!/bin/bash

# epic-modeling-finish.sh
# Finishes epic modeling phase (DE completes DE-01)
#
# Usage: ./epic-modeling-finish.sh <epic-number>
#
# Example:
#   ./epic-modeling-finish.sh 1  # EPIC-01
#
# This script:
#   1. Validates current branch (feature/epic-<N>-domain-model)
#   2. Validates DE-01-EPIC-<N>-*.md exists
#   3. Makes commit with "Ref #1"
#   4. Pushes to remote
#   5. Creates PR for review
#   6. Merges to develop
#   7. Deletes branch

set -e

# Configuration
REPO="[GITHUB_OWNER]/[REPO_NAME]"

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
  exit 1
fi

EPIC_NUM_PADDED=$(printf "%02d" $EPIC_NUM)
BRANCH_NAME="feature/epic-${EPIC_NUM_PADDED}-domain-model"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🏁 EPIC-${EPIC_NUM_PADDED} MODELING - FINISH${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# STEP 1: VALIDATE CURRENT BRANCH
# ============================================================================
echo -e "${YELLOW}━━━ STEP 1/6: Validating current branch ━━━${NC}"
echo ""

CURRENT_BRANCH=$(git branch --show-current)
echo -e "  Current branch: ${BLUE}$CURRENT_BRANCH${NC}"

if [[ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]]; then
  echo -e "  ${RED}❌ Error: Must be on '$BRANCH_NAME' branch${NC}"
  echo ""
  echo "  Switch to valid branch:"
  echo "    git checkout $BRANCH_NAME"
  exit 1
fi

echo -e "  ${GREEN}✅ Valid branch${NC}"
echo ""

# ============================================================================
# STEP 2: VALIDATE DE-01 FILE
# ============================================================================
echo -e "${YELLOW}━━━ STEP 2/6: Validating DE-01 file ━━━${NC}"
echo ""

DE_FILE=$(find 00-doc-ddd/04-tactical-design/ -name "DE-01-EPIC-${EPIC_NUM_PADDED}-*.md" 2>/dev/null | head -n 1)

if [[ -z "$DE_FILE" ]]; then
  echo -e "  ${RED}❌ Error: DE-01-EPIC-${EPIC_NUM_PADDED}-*.md not found${NC}"
  echo ""
  echo "  Create the domain model file first:"
  echo "    00-doc-ddd/04-tactical-design/DE-01-EPIC-${EPIC_NUM_PADDED}-<EpicName>-Domain-Model.md"
  exit 1
fi

echo -e "  ${GREEN}✅ File found: $DE_FILE${NC}"
echo ""

# ============================================================================
# STEP 3: COMMIT
# ============================================================================
echo -e "${YELLOW}━━━ STEP 3/6: Creating commit ━━━${NC}"
echo ""

# Check if there are changes
if git diff --quiet && git diff --cached --quiet; then
  echo -e "  ${YELLOW}⚠️  No changes to commit${NC}"
else
  git add .

  git commit -m "DE: Modelo de domínio EPIC-${EPIC_NUM_PADDED}

Domain model completo para EPIC-${EPIC_NUM_PADDED}:
- Aggregates (entities, value objects)
- Domain Events
- Use Cases
- Repository interfaces
- Business rules

Ref #1"

  echo -e "  ${GREEN}✅ Commit created${NC}"
fi

echo ""

# ============================================================================
# STEP 4: PUSH TO REMOTE
# ============================================================================
echo -e "${YELLOW}━━━ STEP 4/6: Pushing to remote ━━━${NC}"
echo ""

git push origin $BRANCH_NAME -u

echo -e "  ${GREEN}✅ Pushed to remote${NC}"
echo ""

# ============================================================================
# STEP 5: CREATE PR
# ============================================================================
echo -e "${YELLOW}━━━ STEP 5/6: Creating PR ━━━${NC}"
echo ""

# Check if PR already exists
EXISTING_PR=$(gh pr list --head $BRANCH_NAME --repo $REPO --json number -q '.[0].number' 2>/dev/null || echo "")

if [ -n "$EXISTING_PR" ]; then
  echo -e "  ${YELLOW}⚠️  PR already exists: #${EXISTING_PR}${NC}"
  PR_NUMBER=$EXISTING_PR
else
  gh pr create \
    --repo $REPO \
    --title "DE: Modelo de domínio EPIC-${EPIC_NUM_PADDED}" \
    --body "Domain model para EPIC-${EPIC_NUM_PADDED}. Ref #1" \
    --base develop \
    --head $BRANCH_NAME

  PR_NUMBER=$(gh pr list --head $BRANCH_NAME --repo $REPO --json number -q '.[0].number')
  echo -e "  ${GREEN}✅ PR created: #${PR_NUMBER}${NC}"
fi

echo ""

# ============================================================================
# STEP 6: MERGE PR
# ============================================================================
echo -e "${YELLOW}━━━ STEP 6/6: Merging PR ━━━${NC}"
echo ""

echo "  Merging PR #${PR_NUMBER}..."
gh pr merge $PR_NUMBER --repo $REPO --merge --delete-branch

echo -e "  ${GREEN}✅ PR merged and branch deleted${NC}"
echo ""

# Switch to develop
git checkout develop
git pull origin develop

echo -e "  ${GREEN}✅ Switched to develop${NC}"

# Delete local branch
git branch -d $BRANCH_NAME

echo -e "  ${GREEN}✅ Local branch deleted${NC}"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ EPIC-${EPIC_NUM_PADDED} MODELING FINISHED!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo "1. Create milestone and issues (GM):"
echo "   Command: \"GM, crie milestone e issues para EPIC-${EPIC_NUM_PADDED}\""
echo ""
echo "   GM will execute:"
echo "   ./epic-create.sh $EPIC_NUM \"<epic-name>\" \"<due-date-YYYY-MM-DD>\""
echo ""
echo "   Example:"
echo "   ./epic-create.sh $EPIC_NUM \"Criar Estratégia Bull Call Spread\" \"2026-02-28\""
echo ""
echo "   This creates:"
echo "   - Milestone M${EPIC_NUM}"
echo "   - Epic issue (parent)"
echo "   - 6 agent issues (DE, DBA, SE, UXD, FE, QAE)"
echo ""
echo -e "${BLUE}📖 Documentation:${NC}"
echo "   - Git workflow: .agents/docs/03-GIT-PATTERNS.md#scripts-épico-github-setup"
echo ""
