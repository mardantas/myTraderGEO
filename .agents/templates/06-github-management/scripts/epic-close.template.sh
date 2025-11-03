#!/bin/bash

# epic-close.sh
# Closes an epic milestone
#
# Usage:
#   ./epic-close.sh <epic-number>
#
# Examples:
#   ./epic-close.sh 1                      # Close milestone M1
#
# This script:
#   1. Fetches milestone M{N}
#   2. Validates all issues are closed
#   3. Closes milestone
#   4. Provides manual instructions for release creation

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
  echo "Usage: $0 <epic-number> [--release <version>]"
  echo ""
  echo "Examples:"
  echo "  $0 1                      # Close milestone M1"
  echo "  $0 1 --release v1.0.0     # Close M1 + create release"
  echo ""
  exit 1
fi

# Parse flags
shift
while [[ $# -gt 0 ]]; do
  case $1 in
    --release)
      RELEASE_VERSION="$2"
      shift 2
      ;;
    *)
      echo "Unknown flag: $1"
      exit 1
      ;;
  esac
done

EPIC_NUM_PADDED=$(printf "%02d" $EPIC_NUM)

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🏁 CLOSE EPIC-${EPIC_NUM_PADDED}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Options:${NC}"
echo -e "  Create release: ${YELLOW}${RELEASE_VERSION:-No}${NC}"
echo ""

# ============================================================================
# STEP 1: FETCH MILESTONE
# ============================================================================
echo -e "${YELLOW}━━━ STEP 1/5: Fetching Milestone M${EPIC_NUM} ━━━${NC}"
echo ""

MILESTONE_PREFIX="M${EPIC_NUM}: EPIC-${EPIC_NUM_PADDED}"
MILESTONE_INFO=$(gh api repos/$REPO/milestones --jq ".[] | select(.title | startswith(\"$MILESTONE_PREFIX\"))" 2>&1)

if [ -z "$MILESTONE_INFO" ]; then
  echo -e "${RED}❌ Milestone not found: $MILESTONE_PREFIX${NC}"
  echo ""
  echo "Available milestones:"
  gh api repos/$REPO/milestones --jq '.[] | "\(.number): \(.title)"'
  exit 1
fi

MILESTONE_NUMBER=$(echo "$MILESTONE_INFO" | jq -r '.number')
MILESTONE_TITLE=$(echo "$MILESTONE_INFO" | jq -r '.title')
OPEN_ISSUES=$(echo "$MILESTONE_INFO" | jq -r '.open_issues')
CLOSED_ISSUES=$(echo "$MILESTONE_INFO" | jq -r '.closed_issues')
TOTAL=$((OPEN_ISSUES + CLOSED_ISSUES))

echo -e "  ${BLUE}Milestone:${NC} $MILESTONE_TITLE"
echo -e "  ${BLUE}Number:${NC} #${MILESTONE_NUMBER}"
echo -e "  ${BLUE}Progress:${NC} ${CLOSED_ISSUES}/${TOTAL} issues closed"
echo ""

# ============================================================================
# STEP 2: VALIDATE ALL ISSUES CLOSED
# ============================================================================
echo -e "${YELLOW}━━━ STEP 2/5: Validating all issues closed ━━━${NC}"
echo ""

if [ $OPEN_ISSUES -gt 0 ]; then
  echo -e "${RED}❌ Error: Milestone M${EPIC_NUM} still has $OPEN_ISSUES open issue(s)${NC}"
  echo ""
  echo "Open issues:"
  gh issue list --milestone "$MILESTONE_TITLE" --repo $REPO --state open
  echo ""
  echo "Close all issues before closing the milestone."
  exit 1
fi

echo -e "  ${GREEN}✅ All issues closed (${CLOSED_ISSUES}/${TOTAL})${NC}"
echo ""

# ============================================================================
# STEP 3: CLOSE MILESTONE
# ============================================================================
echo -e "${YELLOW}━━━ STEP 3/5: Closing Milestone M${EPIC_NUM} ━━━${NC}"
echo ""

gh api "repos/$REPO/milestones/$MILESTONE_NUMBER" -X PATCH -f state=closed > /dev/null 2>&1

echo -e "  ${GREEN}✅ Milestone M${EPIC_NUM} closed${NC}"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ EPIC-${EPIC_NUM_PADDED} CLOSED!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo ""
echo -e "  ${GREEN}✅${NC} Milestone: ${MILESTONE_TITLE}"
echo -e "  ${GREEN}✅${NC} Total Issues: ${TOTAL}"
echo -e "  ${GREEN}✅${NC} Closed Issues: ${CLOSED_ISSUES}"
echo -e "  ${GREEN}✅${NC} Status: Milestone closed"
echo ""
echo -e "${YELLOW}📋 Next Steps (MANUAL - Optional):${NC}"
echo ""
echo "1. Create release (if ready for production):"
echo ""
echo "   a) Merge develop to main:"
echo "      ${BLUE}git checkout main${NC}"
echo "      ${BLUE}git pull origin main${NC}"
echo "      ${BLUE}git merge develop --no-ff -m 'Release: EPIC-${EPIC_NUM_PADDED}'${NC}"
echo ""
echo "   b) Create and push tag:"
echo "      ${BLUE}git tag -a v1.0.0 -m 'Release v1.0.0: EPIC-${EPIC_NUM_PADDED}'${NC}"
echo "      ${BLUE}git push origin main --tags${NC}"
echo ""
echo "   c) Create GitHub Release:"
echo "      ${BLUE}gh release create v1.0.0 --title 'v1.0.0 - EPIC-${EPIC_NUM_PADDED}' --notes 'Release notes...'${NC}"
echo ""
echo "2. Deploy to production (after release):"
echo "   ${BLUE}docker compose -f docker-compose.prod.yml up -d${NC}"
echo ""
echo "3. Start next epic:"
echo "   ${BLUE}./epic-modeling-start.sh $((EPIC_NUM + 1))${NC}"
echo ""
echo -e "${BLUE}📖 Documentation:${NC}"
echo "   - Git workflow: .agents/docs/03-GIT-PATTERNS.md"
echo "   - Milestone M${EPIC_NUM}: ${BLUE}https://github.com/$REPO/milestone/$MILESTONE_NUMBER${NC}"
echo ""
