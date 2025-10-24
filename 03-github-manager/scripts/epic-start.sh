#!/usr/bin/env bash
# epic-start.sh
# Creates the MAIN branch for an epic where ALL agents will work
#
# This script:
#   1. Creates feature branch: feature/epic-N-<kebab-case-name>
#   2. Makes initial empty commit (following 03-GIT-PATTERNS.md)
#   3. Pushes branch with upstream tracking
#   4. Creates DRAFT PR linked to epic issue
#
# Usage: ./epic-start.sh <epic-number> <epic-issue-number> "<epic-name-kebab-case>"
#
# Examples:
#   ./epic-start.sh 1 5 "criar-estrategia"
#   ./epic-start.sh 2 12 "calcular-greeks"
#
# Note: All agents (DBA, SE, UXD, FE, QAE) will commit to this same branch

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Parameters
EPIC_NUM="${1:-}"
EPIC_ISSUE="${2:-}"
EPIC_NAME="${3:-}"

# Configuration (will be replaced by template processing)
BASE_BRANCH="develop"

# Validation
if [[ -z "$EPIC_NUM" || -z "$EPIC_ISSUE" || -z "$EPIC_NAME" ]]; then
    echo -e "${RED}❌ Error: Missing required parameters${NC}"
    echo ""
    echo "Usage: $0 <epic-number> <epic-issue-number> \"<epic-name-kebab-case>\""
    echo ""
    echo "Examples:"
    echo "  $0 1 5 \"criar-estrategia\""
    echo "  $0 2 12 \"calcular-greeks\""
    echo ""
    exit 1
fi

# Validate epic name is kebab-case
if ! [[ "$EPIC_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo -e "${RED}❌ Error: Epic name must be in kebab-case (lowercase, hyphens only)${NC}"
    echo -e "${GRAY}Example: 'criar-estrategia', not 'Criar Estratégia'${NC}"
    exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🚀 START EPIC-${EPIC_NUM}: ${EPIC_NAME}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# STEP 1: CHECK PREREQUISITES
# ============================================================================
echo -e "${YELLOW}━━━ STEP 1/6: Checking Prerequisites ━━━${NC}"
echo ""

# Check if on correct base branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "$BASE_BRANCH" ]]; then
    echo -e "${YELLOW}⚠️  Not on $BASE_BRANCH branch (currently on: $CURRENT_BRANCH)${NC}"
    echo -e "   Switching to $BASE_BRANCH..."
    git checkout "$BASE_BRANCH"
fi

# Pull latest changes
echo -e "  ${BLUE}Updating $BASE_BRANCH...${NC}"
git pull origin "$BASE_BRANCH"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}❌ Error: You have uncommitted changes${NC}"
    echo -e "${GRAY}Please commit or stash your changes first${NC}"
    exit 1
fi

echo -e "  ${GREEN}✅ Prerequisites OK${NC}"
echo ""

# ============================================================================
# STEP 2: VERIFY EPIC ISSUE EXISTS
# ============================================================================
echo -e "${YELLOW}━━━ STEP 2/6: Verifying Epic Issue ━━━${NC}"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: GitHub CLI (gh) not found${NC}"
    echo -e "${GRAY}Install from: https://cli.github.com/${NC}"
    exit 1
fi

# Verify issue exists and get details
ISSUE_JSON=$(gh issue view "$EPIC_ISSUE" --json title,state,milestone 2>&1)

if [[ $? -ne 0 ]]; then
    echo -e "${RED}❌ Failed to fetch issue #${EPIC_ISSUE}${NC}"
    echo "$ISSUE_JSON"
    exit 1
fi

ISSUE_TITLE=$(echo "$ISSUE_JSON" | jq -r '.title')
ISSUE_STATE=$(echo "$ISSUE_JSON" | jq -r '.state')
MILESTONE=$(echo "$ISSUE_JSON" | jq -r '.milestone.title // "No milestone"')

echo -e "  ${BLUE}Issue:${NC} #${EPIC_ISSUE}"
echo -e "  ${BLUE}Title:${NC} $ISSUE_TITLE"
echo -e "  ${BLUE}State:${NC} $ISSUE_STATE"
echo -e "  ${BLUE}Milestone:${NC} $MILESTONE"

# Verify it's an epic issue
if ! [[ "$ISSUE_TITLE" =~ ^\[EPIC-[0-9]+\] ]]; then
    echo -e "${YELLOW}⚠️  Warning: Issue title doesn't start with [EPIC-N]${NC}"
    echo -e "${GRAY}Expected format: [EPIC-${EPIC_NUM}] <Name>${NC}"
fi

# Verify issue is open
if [[ "$ISSUE_STATE" != "OPEN" ]]; then
    echo -e "${YELLOW}⚠️  Warning: Issue #${EPIC_ISSUE} is ${ISSUE_STATE}${NC}"
fi

echo -e "  ${GREEN}✅ Epic issue verified${NC}"
echo ""

# ============================================================================
# STEP 3: CREATE BRANCH
# ============================================================================
echo -e "${YELLOW}━━━ STEP 3/6: Creating Branch ━━━${NC}"
echo ""

BRANCH_NAME="feature/epic-${EPIC_NUM}-${EPIC_NAME}"

# Check if branch already exists locally
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    echo -e "${RED}❌ Error: Branch '$BRANCH_NAME' already exists locally${NC}"
    echo -e "${GRAY}Use: git checkout $BRANCH_NAME (if you want to continue)${NC}"
    exit 1
fi

# Check if branch exists remotely
if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
    echo -e "${RED}❌ Error: Branch '$BRANCH_NAME' already exists on remote${NC}"
    echo -e "${GRAY}Use: git checkout -b $BRANCH_NAME origin/$BRANCH_NAME${NC}"
    exit 1
fi

echo -e "  ${BLUE}Creating branch:${NC} $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

echo -e "  ${GREEN}✅ Branch created${NC}"
echo ""

# ============================================================================
# STEP 4: INITIAL EMPTY COMMIT
# ============================================================================
echo -e "${YELLOW}━━━ STEP 4/6: Making Initial Commit ━━━${NC}"
echo ""

COMMIT_MSG="chore: Início de uma nova feature

Feature: EPIC-${EPIC_NUM} - ${EPIC_NAME}
Issue: #${EPIC_ISSUE}

Este commit marca o início do trabalho no épico ${EPIC_NUM}.
Todos os agentes (DBA, SE, UXD, FE, QAE) trabalharão nesta branch."

echo -e "  ${BLUE}Making empty commit...${NC}"
git commit --allow-empty -m "$COMMIT_MSG"

echo -e "  ${GREEN}✅ Initial commit created${NC}"
echo ""

# ============================================================================
# STEP 5: PUSH BRANCH
# ============================================================================
echo -e "${YELLOW}━━━ STEP 5/6: Pushing Branch ━━━${NC}"
echo ""

echo -e "  ${BLUE}Pushing to origin...${NC}"
git push -u origin "$BRANCH_NAME"

echo -e "  ${GREEN}✅ Branch pushed with upstream tracking${NC}"
echo ""

# ============================================================================
# STEP 6: CREATE DRAFT PR
# ============================================================================
echo -e "${YELLOW}━━━ STEP 6/6: Creating Draft PR ━━━${NC}"
echo ""

PR_TITLE="[EPIC-${EPIC_NUM}] ${EPIC_NAME//-/ }"
PR_BODY="## 🚧 Work in Progress

Épico: EPIC-${EPIC_NUM}
Issue: #${EPIC_ISSUE}

### Deliverables
- [ ] DBA: Schema Review
- [ ] SE: Backend Implementation (paralelo com UXD)
- [ ] UXD: Wireframes
- [ ] FE: Frontend Implementation
- [ ] QAE: Quality Gate (integration + E2E tests)

### Workflow
Todos os agentes trabalham **nesta mesma branch**.

Sequência: DBA → SE (|| UXD) → FE → QAE → Merge

### Progresso
- [x] Branch criada
- [x] Commit inicial
- [ ] DBA: Schema Review
- [ ] SE: Backend
- [ ] UXD: Wireframes
- [ ] FE: Frontend
- [ ] QAE: Quality Gate

Ref #${EPIC_ISSUE}"

echo -e "  ${BLUE}Creating draft PR...${NC}"

PR_URL=$(gh pr create \
    --draft \
    --base "$BASE_BRANCH" \
    --head "$BRANCH_NAME" \
    --title "$PR_TITLE" \
    --body "$PR_BODY")

if [[ $? -eq 0 ]]; then
    echo -e "  ${GREEN}✅ Draft PR created${NC}"
    echo -e "  ${BLUE}URL:${NC} $PR_URL"
else
    echo -e "  ${RED}❌ Failed to create PR${NC}"
    exit 1
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ EPIC-${EPIC_NUM} STARTED SUCCESSFULLY!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Branch:${NC} $BRANCH_NAME"
echo -e "${BLUE}Issue:${NC} #${EPIC_ISSUE}"
echo -e "${BLUE}PR:${NC} $PR_URL"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "   1. Invoke agents to work on this epic:"
echo -e "      ${GRAY}\"DBA, revise schema do EPIC-${EPIC_NUM}\"${NC}"
echo -e "      ${GRAY}\"SE, implemente backend do EPIC-${EPIC_NUM}\"${NC}"
echo -e "      ${GRAY}\"UXD, crie wireframes do EPIC-${EPIC_NUM}\"${NC}"
echo -e "      ${GRAY}\"FE, implemente UI do EPIC-${EPIC_NUM}\"${NC}"
echo -e "      ${GRAY}\"QAE, execute quality gate do EPIC-${EPIC_NUM}\"${NC}"
echo ""
echo -e "   2. Each agent commits to THIS branch:"
echo -e "      ${GRAY}git commit -m \"AGENT: Description ... Ref #${EPIC_ISSUE}\"${NC}"
echo -e "      ${GRAY}git push${NC}"
echo ""
echo -e "   3. When complete (QAE approved):"
echo -e "      ${GRAY}gh pr ready${NC}"
echo -e "      ${GRAY}Merge via GitHub UI (Create a merge commit)${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
