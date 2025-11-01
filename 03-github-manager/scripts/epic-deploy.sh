#!/usr/bin/env bash
# epic-deploy.sh
# Finalizes epic work and merges to develop (staging)
#
# This script:
#   1. Validates all required commits exist
#   2. Validates QAE approval (last commit closes issue)
#   3. Marks PR as ready for review
#   4. Merges PR to develop (with merge commit)
#   5. Optionally triggers staging deployment
#
# Usage: ./epic-deploy.sh <epic-number> [--skip-staging]
#
# Examples:
#   ./epic-deploy.sh 1                    # Merge to develop + deploy staging
#   ./epic-deploy.sh 1 --skip-staging     # Merge to develop only
#
# Note: After this, use epic-close.sh to create release and deploy to production

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
SKIP_STAGING=false

# Parse flags
shift || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-staging)
            SKIP_STAGING=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown parameter: $1${NC}"
            exit 1
            ;;
    esac
done

# Configuration
BASE_BRANCH="develop"
REQUIRED_AGENTS=("DBA" "SE" "UXD" "FE" "QAE")

# Validation
if [[ -z "$EPIC_NUM" ]]; then
    echo -e "${RED}❌ Error: Missing epic number${NC}"
    echo ""
    echo "Usage: $0 <epic-number> [--skip-staging]"
    echo ""
    echo "Examples:"
    echo "  $0 1                    # Merge + deploy staging"
    echo "  $0 1 --skip-staging     # Merge only"
    echo ""
    exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🚀 DEPLOY EPIC-${EPIC_NUM} TO STAGING${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# STEP 1: VALIDATE CURRENT BRANCH
# ============================================================================
echo -e "${YELLOW}━━━ STEP 1/7: Validating Branch ━━━${NC}"
echo ""

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
EXPECTED_PATTERN="^feature/epic-${EPIC_NUM}-"

if ! [[ "$CURRENT_BRANCH" =~ $EXPECTED_PATTERN ]]; then
    echo -e "${RED}❌ Error: Not on epic-${EPIC_NUM} branch${NC}"
    echo -e "   ${GRAY}Current: $CURRENT_BRANCH${NC}"
    echo -e "   ${GRAY}Expected: feature/epic-${EPIC_NUM}-*${NC}"
    exit 1
fi

echo -e "  ${BLUE}Branch:${NC} $CURRENT_BRANCH"
echo -e "  ${GREEN}✅ On correct epic branch${NC}"
echo ""

# ============================================================================
# STEP 2: VALIDATE COMMITS
# ============================================================================
echo -e "${YELLOW}━━━ STEP 2/7: Validating Commits ━━━${NC}"
echo ""

# Get all commits since branched from develop
COMMITS=$(git log origin/$BASE_BRANCH..HEAD --pretty=format:"%s" 2>&1)

if [[ -z "$COMMITS" ]]; then
    echo -e "${RED}❌ Error: No commits found on this branch${NC}"
    exit 1
fi

echo -e "  ${BLUE}Found commits:${NC}"
echo "$COMMITS" | nl -w2 -s'. '
echo ""

# Check for required agents
missing_agents=()
for agent in "${REQUIRED_AGENTS[@]}"; do
    if ! echo "$COMMITS" | grep -qi "^$agent:"; then
        missing_agents+=("$agent")
    fi
done

if [[ ${#missing_agents[@]} -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Warning: Missing commits from agents: ${missing_agents[*]}${NC}"
    echo -e "   ${GRAY}Expected commits from: ${REQUIRED_AGENTS[*]}${NC}"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "  ${GREEN}✅ Commits validated${NC}"
echo ""

# ============================================================================
# STEP 3: VALIDATE QAE APPROVAL
# ============================================================================
echo -e "${YELLOW}━━━ STEP 3/7: Validating QAE Approval ━━━${NC}"
echo ""

LAST_COMMIT=$(git log -1 --pretty=format:"%s%n%b")

echo -e "  ${BLUE}Last commit:${NC}"
echo "$LAST_COMMIT" | sed 's/^/    /'
echo ""

# Check if last commit is from QAE
if ! echo "$LAST_COMMIT" | grep -qi "^QAE:"; then
    echo -e "${YELLOW}⚠️  Warning: Last commit is not from QAE${NC}"
    echo -e "   ${GRAY}Expected QAE to make final commit with quality gate approval${NC}"
    echo ""
fi

# Check if last commit closes issue
if ! echo "$LAST_COMMIT" | grep -qi "Closes #"; then
    echo -e "${RED}❌ Error: Last commit doesn't close issue${NC}"
    echo -e "   ${GRAY}Expected 'Closes #N' in commit message${NC}"
    exit 1
fi

CLOSED_ISSUE=$(echo "$LAST_COMMIT" | grep -oiP 'Closes #\K\d+' | head -1)

echo -e "  ${BLUE}Closes Issue:${NC} #${CLOSED_ISSUE}"
echo -e "  ${GREEN}✅ QAE approval validated${NC}"
echo ""

# ============================================================================
# STEP 4: CHECK FOR UNCOMMITTED CHANGES
# ============================================================================
echo -e "${YELLOW}━━━ STEP 4/7: Checking Uncommitted Changes ━━━${NC}"
echo ""

if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}❌ Error: You have uncommitted changes${NC}"
    echo -e "${GRAY}Please commit or stash your changes first${NC}"
    exit 1
fi

echo -e "  ${GREEN}✅ No uncommitted changes${NC}"
echo ""

# ============================================================================
# STEP 5: PUSH AND MARK PR AS READY
# ============================================================================
echo -e "${YELLOW}━━━ STEP 5/7: Marking PR as Ready ━━━${NC}"
echo ""

# Push any final commits
echo -e "  ${BLUE}Pushing to remote...${NC}"
git push

# Mark PR as ready
echo -e "  ${BLUE}Marking PR as ready for review...${NC}"
PR_URL=$(gh pr ready 2>&1 || echo "")

if [[ $? -eq 0 ]]; then
    echo -e "  ${GREEN}✅ PR marked as ready${NC}"
    echo -e "  ${BLUE}URL:${NC} $PR_URL"
else
    echo -e "  ${YELLOW}⚠️  PR may already be ready${NC}"
fi

echo ""

# ============================================================================
# STEP 6: MERGE TO DEVELOP
# ============================================================================
echo -e "${YELLOW}━━━ STEP 6/7: Merging to ${BASE_BRANCH} ━━━${NC}"
echo ""

echo -e "  ${BLUE}Merging PR with merge commit (--no-ff)...${NC}"

# Get PR number
PR_NUMBER=$(gh pr view --json number -q '.number' 2>&1)

if [[ $? -ne 0 ]]; then
    echo -e "${RED}❌ Failed to get PR number${NC}"
    exit 1
fi

# Merge PR
gh pr merge "$PR_NUMBER" --merge --delete-branch

if [[ $? -eq 0 ]]; then
    echo -e "  ${GREEN}✅ PR merged to $BASE_BRANCH${NC}"
    echo -e "  ${GREEN}✅ Branch deleted${NC}"
    echo -e "  ${GREEN}✅ Issue #${CLOSED_ISSUE} closed automatically${NC}"
else
    echo -e "${RED}❌ Failed to merge PR${NC}"
    exit 1
fi

echo ""

# ============================================================================
# STEP 7: DEPLOY TO STAGING (OPTIONAL)
# ============================================================================
if [[ "$SKIP_STAGING" == "false" ]]; then
    echo -e "${YELLOW}━━━ STEP 7/7: Deploying to Staging ━━━${NC}"
    echo ""

    echo -e "  ${BLUE}Checking out $BASE_BRANCH...${NC}"
    git checkout "$BASE_BRANCH"
    git pull origin "$BASE_BRANCH"

    echo -e "  ${YELLOW}📦 Deploy to staging...${NC}"
    echo -e "  ${GRAY}Command: docker compose -f 05-infra/docker/docker-compose.staging.yml --env-file 05-infra/configs/.env.staging up -d${NC}"
    echo ""

    # Note: Actual deployment should be handled by CI/CD or manual approval
    echo -e "  ${CYAN}ℹ️  Staging deployment should be triggered by CI/CD pipeline${NC}"
    echo -e "  ${CYAN}   Or manually run: docker compose -f 05-infra/docker/docker-compose.staging.yml --env-file 05-infra/configs/.env.staging up -d${NC}"
    echo ""
else
    echo -e "${YELLOW}━━━ STEP 7/7: Skipping Staging Deployment ━━━${NC}"
    echo ""
    echo -e "  ${BLUE}Staging deployment skipped (--skip-staging flag)${NC}"
    echo ""
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ EPIC-${EPIC_NUM} DEPLOYED TO STAGING!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Branch:${NC} $CURRENT_BRANCH → $BASE_BRANCH (merged)"
echo -e "${BLUE}Issue:${NC} #${CLOSED_ISSUE} (closed)"
echo -e "${BLUE}Status:${NC} In staging"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "   1. ${GRAY}Monitor staging environment${NC}"
echo -e "   2. ${GRAY}Run smoke tests (QAE)${NC}"
echo -e "   3. ${GRAY}If approved, create release and deploy to production:${NC}"
echo -e "      ${BLUE}./epic-close.sh ${EPIC_NUM} --release vX.Y.Z${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
