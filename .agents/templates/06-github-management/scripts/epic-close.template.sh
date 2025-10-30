#!/bin/bash

# epic-close.sh
# Closes an epic (milestone + optional release)
#
# Usage:
#   ./epic-close.sh <epic-number>                             # Close milestone only
#   ./epic-close.sh <epic-number> --release <version>         # Close + create release
#
# Examples:
#   ./epic-close.sh 1                      # Close milestone M1
#   ./epic-close.sh 1 --release v1.0.0     # Close M1 + create v1.0.0 release
#
# This script:
#   1. Fetches milestone M{N}
#   2. Validates all issues are closed
#   3. Closes milestone
#   4. (Optional) Creates release (tag + GitHub Release)
#   5. (Optional) Guides deploy process

set -e

# Configuration
REPO="[GITHUB_OWNER]/[REPO_NAME]"

# Parameters
EPIC_NUM=$1
RELEASE_VERSION=""

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
# STEP 4: CREATE RELEASE (OPTIONAL)
# ============================================================================
if [ -n "$RELEASE_VERSION" ]; then
  echo -e "${YELLOW}━━━ STEP 4/5: Creating Release ${RELEASE_VERSION} ━━━${NC}"
  echo ""

  # Switch to main
  echo "  Switching to main branch..."
  git checkout main > /dev/null 2>&1
  git pull origin main > /dev/null 2>&1

  # Merge develop to main
  echo "  Merging develop to main..."
  git merge develop --no-ff -m "Release: EPIC-${EPIC_NUM_PADDED}

EPIC-${EPIC_NUM_PADDED} completo e pronto para produção.

Closes milestone M${EPIC_NUM}" > /dev/null 2>&1

  # Create tag
  echo "  Creating tag ${RELEASE_VERSION}..."
  git tag -a "$RELEASE_VERSION" -m "Release $RELEASE_VERSION: EPIC-${EPIC_NUM_PADDED}

EPIC-${EPIC_NUM_PADDED}: ${MILESTONE_TITLE#*- }

Issues fechadas: ${CLOSED_ISSUES}
Milestone: M${EPIC_NUM}

🤖 Generated with GM epic-close.sh"

  # Push main and tag
  echo "  Pushing main and tag to remote..."
  git push origin main --tags > /dev/null 2>&1

  echo -e "  ${GREEN}✅ Tag ${RELEASE_VERSION} created and pushed${NC}"

  # Create GitHub Release
  echo "  Creating GitHub Release..."

  # Get list of closed issues
  ISSUE_LIST=$(gh issue list --milestone "$MILESTONE_TITLE" --repo $REPO --state closed --json number,title --jq '.[] | "- #\(.number): \(.title)"' | head -n 20)

  RELEASE_NOTES=$(cat <<EOF
## 📦 EPIC-${EPIC_NUM_PADDED}: ${MILESTONE_TITLE#*- }

Release do EPIC-${EPIC_NUM_PADDED} para produção.

## 🎯 Issues Fechadas

${ISSUE_LIST}

## 📊 Estatísticas

- **Total de Issues:** ${TOTAL}
- **Issues Fechadas:** ${CLOSED_ISSUES}
- **Milestone:** M${EPIC_NUM}

## 🔗 Referências

- **Milestone:** M${EPIC_NUM} (${MILESTONE_TITLE})
- **Git Workflow:** [03-GIT-PATTERNS.md](.agents/docs/03-GIT-PATTERNS.md)

🤖 Generated with GM epic-close.sh
EOF
)

  gh release create "$RELEASE_VERSION" \
    --repo $REPO \
    --title "$RELEASE_VERSION - EPIC-${EPIC_NUM_PADDED}" \
    --notes "$RELEASE_NOTES" > /dev/null 2>&1

  echo -e "  ${GREEN}✅ GitHub Release ${RELEASE_VERSION} created${NC}"
  echo ""
else
  echo -e "${YELLOW}━━━ STEP 4/5: Skipping release (use --release flag) ━━━${NC}"
  echo ""
fi

# ============================================================================
# STEP 5: DEPLOYMENT GUIDANCE
# ============================================================================
if [ -n "$RELEASE_VERSION" ]; then
  echo -e "${YELLOW}━━━ STEP 5/5: Deployment Guidance ━━━${NC}"
  echo ""

  echo -e "  ${BLUE}📋 Recommended deployment steps:${NC}"
  echo ""
  echo "  1. Deploy to staging:"
  echo "     docker compose -f docker-compose.staging.yml up -d"
  echo ""
  echo "  2. Run smoke tests (QAE):"
  echo "     npm run test:smoke"
  echo ""
  echo "  3. If tests pass, deploy to production:"
  echo "     docker compose -f docker-compose.prod.yml up -d"
  echo ""
  echo "  4. Monitor production:"
  echo "     Check logs, metrics, and error rates"
  echo ""
else
  echo -e "${YELLOW}━━━ STEP 5/5: Skipping deployment (no release created) ━━━${NC}"
  echo ""
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ EPIC-${EPIC_NUM_PADDED} CLOSED!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo ""
echo -e "  ${GREEN}✅${NC} Milestone M${EPIC_NUM} closed"
echo -e "  ${GREEN}✅${NC} All issues completed (${CLOSED_ISSUES}/${TOTAL})"

if [ -n "$RELEASE_VERSION" ]; then
  echo -e "  ${GREEN}✅${NC} Tag ${RELEASE_VERSION} created"
  echo -e "  ${GREEN}✅${NC} GitHub Release created"
  echo -e "  ${GREEN}✅${NC} Merged to main"
fi

echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""

if [ -n "$RELEASE_VERSION" ]; then
  echo "1. Deploy to staging and run smoke tests"
  echo "2. If approved, deploy to production"
  echo "3. Monitor production deployment"
  echo "4. Start next epic:"
  echo "   ./epic-modeling-start.sh $((EPIC_NUM + 1))"
else
  echo "1. (Optional) Create release:"
  echo "   ./epic-close.sh $EPIC_NUM --release v<X.Y.Z>"
  echo "2. Start next epic:"
  echo "   ./epic-modeling-start.sh $((EPIC_NUM + 1))"
fi

echo ""
echo -e "${BLUE}📖 Documentation:${NC}"
echo "   - Git workflow: .agents/docs/03-GIT-PATTERNS.md"
echo "   - Milestone M${EPIC_NUM}: gh api repos/$REPO/milestones/$MILESTONE_NUMBER"

if [ -n "$RELEASE_VERSION" ]; then
  echo "   - Release ${RELEASE_VERSION}: gh release view ${RELEASE_VERSION} --repo $REPO --web"
fi

echo ""
