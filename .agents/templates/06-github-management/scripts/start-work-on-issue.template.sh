#!/bin/bash

# start-work-on-issue.sh
# Automates starting work on a GitHub issue:
#   1. Creates feature branch
#   2. Makes initial empty commit (following 03-GIT-PATTERNS.md)
#   3. Pushes branch
#   4. Creates draft PR linked to issue
#
# Usage: ./start-work-on-issue.sh <issue-number>
#
# Examples:
#   ./start-work-on-issue.sh 6   # Start work on issue #6

set -e

# Configuration
REPO="[GITHUB_OWNER]/[REPO_NAME]"
BASE_BRANCH="develop"  # Default base branch for PRs

# Parameters
ISSUE_NUMBER=$1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Validation
if [ -z "$ISSUE_NUMBER" ]; then
  echo -e "${RED}❌ Error: Missing issue number${NC}"
  echo ""
  echo "Usage: $0 <issue-number>"
  echo ""
  echo "Examples:"
  echo "  $0 6   # Start work on issue #6"
  echo ""
  exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🚀 START WORK ON ISSUE #${ISSUE_NUMBER}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# STEP 1: FETCH ISSUE INFO
# ============================================================================
echo -e "${YELLOW}━━━ STEP 1/5: Fetching Issue Info ━━━${NC}"
echo ""

# Get issue details
ISSUE_JSON=$(gh issue view $ISSUE_NUMBER --repo $REPO --json title,labels,milestone 2>&1)

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Failed to fetch issue #${ISSUE_NUMBER}${NC}"
  echo "$ISSUE_JSON"
  exit 1
fi

ISSUE_TITLE=$(echo "$ISSUE_JSON" | jq -r '.title')
MILESTONE=$(echo "$ISSUE_JSON" | jq -r '.milestone.title // "No milestone"')

echo -e "  ${BLUE}Issue:${NC} #${ISSUE_NUMBER}"
echo -e "  ${BLUE}Title:${NC} $ISSUE_TITLE"
echo -e "  ${BLUE}Milestone:${NC} $MILESTONE"
echo ""

# ============================================================================
# STEP 2: GENERATE BRANCH NAME
# ============================================================================
echo -e "${YELLOW}━━━ STEP 2/5: Generating Branch Name ━━━${NC}"
echo ""

# Extract epic number from milestone (e.g., "M1: EPIC-01 - Name" → "01")
EPIC_NUM=$(echo "$MILESTONE" | grep -oP 'EPIC-\K\d+' || echo "")

# Extract agent from title (e.g., "DE: Domain Model" → "de")
AGENT=$(echo "$ISSUE_TITLE" | grep -oP '^[A-Z]+(?=:)' | tr '[:upper:]' '[:lower:]' || echo "task")

# Clean title for branch name (kebab-case)
CLEAN_TITLE=$(echo "$ISSUE_TITLE" | \
  sed 's/^[A-Z]*: //' | \
  sed 's/EPIC-[0-9]* //' | \
  tr '[:upper:]' '[:lower:]' | \
  sed 's/[^a-z0-9]/-/g' | \
  sed 's/--*/-/g' | \
  sed 's/^-//;s/-$//')

# Build branch name
if [ -n "$EPIC_NUM" ]; then
  BRANCH_NAME="feature/epic-${EPIC_NUM}-${AGENT}-${CLEAN_TITLE}"
else
  BRANCH_NAME="feature/${AGENT}-${CLEAN_TITLE}"
fi

# Truncate if too long (max 80 chars)
if [ ${#BRANCH_NAME} -gt 80 ]; then
  BRANCH_NAME="${BRANCH_NAME:0:77}..."
fi

echo -e "  ${GREEN}Branch:${NC} $BRANCH_NAME"
echo ""

# ============================================================================
# STEP 3: CREATE AND CHECKOUT BRANCH
# ============================================================================
echo -e "${YELLOW}━━━ STEP 3/5: Creating Branch ━━━${NC}"
echo ""

# Ensure we're on base branch and up to date
echo "  Updating $BASE_BRANCH..."
git checkout $BASE_BRANCH > /dev/null 2>&1
git pull origin $BASE_BRANCH > /dev/null 2>&1

# Create and checkout new branch
echo "  Creating branch $BRANCH_NAME..."
git checkout -b $BRANCH_NAME > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo -e "  ${GREEN}✅ Branch created and checked out${NC}"
else
  echo -e "  ${RED}❌ Failed to create branch${NC}"
  exit 1
fi
echo ""

# ============================================================================
# STEP 4: INITIAL EMPTY COMMIT
# ============================================================================
echo -e "${YELLOW}━━━ STEP 4/5: Initial Empty Commit ━━━${NC}"
echo ""

# Generate commit message following 03-GIT-PATTERNS.md standard
COMMIT_MSG=$(cat <<EOF
chore: Início de uma nova feature

Feature: ${ISSUE_TITLE}
Issue: #${ISSUE_NUMBER}

Este commit marca o início do trabalho na issue #${ISSUE_NUMBER}.
EOF
)

echo "  Creating initial commit..."
git commit --allow-empty -m "$COMMIT_MSG" > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo -e "  ${GREEN}✅ Initial commit created${NC}"
else
  echo -e "  ${RED}❌ Failed to create commit${NC}"
  exit 1
fi

# Push branch
echo "  Pushing branch to origin..."
git push -u origin $BRANCH_NAME > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo -e "  ${GREEN}✅ Branch pushed${NC}"
else
  echo -e "  ${RED}❌ Failed to push branch${NC}"
  exit 1
fi
echo ""

# ============================================================================
# STEP 5: CREATE DRAFT PR
# ============================================================================
echo -e "${YELLOW}━━━ STEP 5/5: Creating Draft PR ━━━${NC}"
echo ""

# PR body template
PR_BODY=$(cat <<EOF
## 📋 Issue

Closes #${ISSUE_NUMBER}

## 🎯 Milestone

${MILESTONE}

## 📝 Description

[TODO: Describe your changes]

## ✅ Checklist

- [ ] Code follows project standards
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Self-review completed

## 🔗 Related Documents

- **Issue:** #${ISSUE_NUMBER}
- **Git Patterns:** [03-GIT-PATTERNS.md](.agents/docs/03-GIT-PATTERNS.md)

🤖 Generated with GM start-work-on-issue.sh
EOF
)

echo "  Creating draft PR..."

gh pr create --repo $REPO \
  --base $BASE_BRANCH \
  --head $BRANCH_NAME \
  --title "$ISSUE_TITLE" \
  --body "$PR_BODY" \
  --draft > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo -e "  ${GREEN}✅ Draft PR created${NC}"
else
  echo -e "  ${YELLOW}⚠️  PR may already exist or failed to create${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ READY TO WORK!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📌 Current Status:${NC}"
echo "  • Branch: $BRANCH_NAME (checked out)"
echo "  • Commit: Initial empty commit"
echo "  • PR: Draft created (linked to issue #${ISSUE_NUMBER})"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo "1. Start working on your task"
echo "2. Make commits as you progress"
echo "3. When ready for review:"
echo "   gh pr ready  # Mark PR as ready"
echo ""
echo "4. When all tests pass and PR approved:"
echo "   gh pr merge --merge --delete-branch"
echo ""
echo -e "${BLUE}📖 Documentation:${NC}"
echo "   - Git workflow: .agents/docs/03-GIT-PATTERNS.md"
echo "   - Issue #${ISSUE_NUMBER}: gh issue view ${ISSUE_NUMBER} --repo $REPO"
echo ""
