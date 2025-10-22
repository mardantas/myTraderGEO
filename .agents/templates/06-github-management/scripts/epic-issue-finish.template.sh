#!/bin/bash

# epic-issue-finish.sh
# Finishes work on an epic issue
#
# Usage:
#   ./epic-issue-finish.sh <issue-number>                 # Just mark PR as ready
#   ./epic-issue-finish.sh <issue-number> --merge         # Mark ready + merge PR
#
# Examples:
#   ./epic-issue-finish.sh 6         # Mark PR as ready for review
#   ./epic-issue-finish.sh 6 --merge # Mark ready + merge
#
# This script:
#   1. Validates current branch
#   2. Checks for commits (beyond initial)
#   3. Makes final commit with "Closes #<issue>" (if needed)
#   4. Pushes to remote
#   5. Marks PR as "ready for review"
#   6. (Optional) Merges PR and deletes branch

set -e

# Configuration
REPO="[GITHUB_OWNER]/[REPO_NAME]"

# Parameters
ISSUE_NUMBER=$1
MERGE=false

if [ "$2" == "--merge" ]; then
  MERGE=true
fi

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
  echo "Usage: $0 <issue-number> [--merge]"
  echo ""
  echo "Examples:"
  echo "  $0 6         # Mark PR as ready"
  echo "  $0 6 --merge # Mark ready + merge"
  echo ""
  exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🏁 FINISH WORK ON ISSUE #${ISSUE_NUMBER}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Options:${NC}"
echo -e "  Merge PR: ${YELLOW}$MERGE${NC}"
echo ""

# ============================================================================
# STEP 1: FETCH ISSUE INFO
# ============================================================================
echo -e "${YELLOW}━━━ STEP 1/6: Fetching issue info ━━━${NC}"
echo ""

ISSUE_JSON=$(gh issue view $ISSUE_NUMBER --repo $REPO --json title,milestone 2>&1)

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
# STEP 2: VALIDATE COMMITS
# ============================================================================
echo -e "${YELLOW}━━━ STEP 2/6: Validating commits ━━━${NC}"
echo ""

# Count commits on current branch (excluding initial commit)
COMMIT_COUNT=$(git log develop..HEAD --oneline | wc -l)

echo -e "  ${BLUE}Commits on branch:${NC} $COMMIT_COUNT"

if [ $COMMIT_COUNT -le 1 ]; then
  echo -e "  ${YELLOW}⚠️  Warning: Only initial commit exists${NC}"
  echo ""
  read -p "  Continue anyway? Work may be incomplete. (y/n) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled. Add more work before finishing.${NC}"
    exit 0
  fi
fi

echo -e "  ${GREEN}✅ Commits validated${NC}"
echo ""

# ============================================================================
# STEP 3: FINAL COMMIT (if needed)
# ============================================================================
echo -e "${YELLOW}━━━ STEP 3/6: Checking for final commit ━━━${NC}"
echo ""

# Check if last commit has "Closes #<issue>"
LAST_COMMIT=$(git log -1 --pretty=%B)

if [[ "$LAST_COMMIT" =~ "Closes #$ISSUE_NUMBER" ]]; then
  echo -e "  ${GREEN}✅ Final commit already exists${NC}"
else
  echo "  Adding final commit with 'Closes #${ISSUE_NUMBER}'..."

  # Check if there are uncommitted changes
  if ! git diff --quiet || ! git diff --cached --quiet; then
    git add .
    HAS_CHANGES=true
  else
    HAS_CHANGES=false
  fi

  # Create final commit (empty if no changes)
  if [ "$HAS_CHANGES" = true ]; then
    git commit -m "chore: Finalização da issue #${ISSUE_NUMBER}

Closes #${ISSUE_NUMBER}"
  else
    git commit --allow-empty -m "chore: Finalização da issue #${ISSUE_NUMBER}

Closes #${ISSUE_NUMBER}"
  fi

  echo -e "  ${GREEN}✅ Final commit created${NC}"
fi

echo ""

# ============================================================================
# STEP 4: PUSH TO REMOTE
# ============================================================================
echo -e "${YELLOW}━━━ STEP 4/6: Pushing to remote ━━━${NC}"
echo ""

git push

echo -e "  ${GREEN}✅ Pushed to remote${NC}"
echo ""

# ============================================================================
# STEP 5: MARK PR AS READY
# ============================================================================
echo -e "${YELLOW}━━━ STEP 5/6: Marking PR as ready ━━━${NC}"
echo ""

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Find PR for current branch
PR_NUMBER=$(gh pr list --head $CURRENT_BRANCH --repo $REPO --json number -q '.[0].number' 2>/dev/null || echo "")

if [ -z "$PR_NUMBER" ]; then
  echo -e "  ${RED}❌ No PR found for branch $CURRENT_BRANCH${NC}"
  echo "  Create PR first or check branch name"
  exit 1
fi

# Check if PR is draft
IS_DRAFT=$(gh pr view $PR_NUMBER --repo $REPO --json isDraft -q '.isDraft')

if [ "$IS_DRAFT" = "true" ]; then
  gh pr ready $PR_NUMBER --repo $REPO
  echo -e "  ${GREEN}✅ PR #${PR_NUMBER} marked as ready for review${NC}"
else
  echo -e "  ${YELLOW}⚠️  PR #${PR_NUMBER} already ready${NC}"
fi

echo ""

# ============================================================================
# STEP 6: MERGE (OPTIONAL)
# ============================================================================
if [ "$MERGE" = true ]; then
  echo -e "${YELLOW}━━━ STEP 6/6: Merging PR ━━━${NC}"
  echo ""

  echo "  Merging PR #${PR_NUMBER}..."
  gh pr merge $PR_NUMBER --repo $REPO --merge --delete-branch

  echo -e "  ${GREEN}✅ PR merged and branch deleted${NC}"
  echo -e "  ${GREEN}✅ Issue #${ISSUE_NUMBER} closed automatically${NC}"
  echo ""

  # Switch to develop
  git checkout develop
  git pull origin develop

  echo -e "  ${GREEN}✅ Switched to develop${NC}"
  echo ""

  # Get milestone progress
  EPIC_NUM=$(echo "$MILESTONE" | grep -oP 'EPIC-\K\d+' || echo "")
  if [ -n "$EPIC_NUM" ]; then
    MILESTONE_INFO=$(gh api repos/$REPO/milestones --jq ".[] | select(.title | startswith(\"M${EPIC_NUM}:\"))")
    OPEN_ISSUES=$(echo "$MILESTONE_INFO" | jq -r '.open_issues')
    CLOSED_ISSUES=$(echo "$MILESTONE_INFO" | jq -r '.closed_issues')
    TOTAL=$((OPEN_ISSUES + CLOSED_ISSUES))
    PERCENT=$((CLOSED_ISSUES * 100 / TOTAL))

    echo -e "${BLUE}📊 Milestone Progress:${NC}"
    echo -e "  ${GREEN}$CLOSED_ISSUES${NC}/$TOTAL issues complete (${PERCENT}%)"
    echo ""
  fi
else
  echo -e "${YELLOW}━━━ STEP 6/6: Skipping merge (use --merge flag) ━━━${NC}"
  echo ""
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ ISSUE #${ISSUE_NUMBER} FINISHED!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo ""
echo -e "  ${GREEN}✅${NC} Commits validated"
echo -e "  ${GREEN}✅${NC} Final commit created"
echo -e "  ${GREEN}✅${NC} Pushed to remote"
echo -e "  ${GREEN}✅${NC} PR #${PR_NUMBER} marked as ready"

if [ "$MERGE" = true ]; then
  echo -e "  ${GREEN}✅${NC} PR merged"
  echo -e "  ${GREEN}✅${NC} Issue #${ISSUE_NUMBER} closed"
  echo -e "  ${GREEN}✅${NC} Branch deleted"
fi

echo ""

if [ "$MERGE" = false ]; then
  echo -e "${YELLOW}📋 Next Steps:${NC}"
  echo ""
  echo "1. Wait for PR review and approval"
  echo "2. After approval, merge PR:"
  echo "   gh pr merge $PR_NUMBER --merge --delete-branch"
  echo ""
fi

echo -e "${BLUE}📖 Documentation:${NC}"
echo "   - Git workflow: .agents/docs/03-GIT-PATTERNS.md"
echo "   - PR #${PR_NUMBER}: gh pr view ${PR_NUMBER} --repo $REPO --web"
echo ""
