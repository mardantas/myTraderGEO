#!/bin/bash

# create-milestone.sh
# Creates a GitHub milestone on-demand (one at a time)
#
# Usage: ./create-milestone.sh <number> "<title>" "<description>" "<due-date-YYYY-MM-DD>"
#
# Examples:
#   ./create-milestone.sh 0 "Discovery Foundation" "Setup inicial completo" ""
#   ./create-milestone.sh 1 "EPIC-01 - Criação de Estratégias" "Templates e estratégias" "2026-02-28"

set -e

# Configuration
REPO="[GITHUB_OWNER]/[REPO_NAME]"

# Parameters
MILESTONE_NUM=$1
MILESTONE_TITLE=$2
MILESTONE_DESC=$3
DUE_DATE=$4

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation
if [ -z "$MILESTONE_NUM" ] || [ -z "$MILESTONE_TITLE" ]; then
  echo -e "${RED}❌ Error: Missing required parameters${NC}"
  echo ""
  echo "Usage: $0 <number> \"<title>\" \"<description>\" \"<due-date-YYYY-MM-DD>\""
  echo ""
  echo "Examples:"
  echo "  $0 0 \"Discovery Foundation\" \"Setup inicial completo\" \"\""
  echo "  $0 1 \"EPIC-01 - Name\" \"Description\" \"2026-02-28\""
  echo ""
  exit 1
fi

echo -e "${YELLOW}🚀 Creating Milestone M${MILESTONE_NUM}...${NC}"
echo ""

# Build command
CMD="gh api repos/$REPO/milestones -X POST -f title=\"$MILESTONE_TITLE\""

if [ -n "$MILESTONE_DESC" ]; then
  CMD="$CMD -f description=\"$MILESTONE_DESC\""
fi

if [ -n "$DUE_DATE" ]; then
  # Convert YYYY-MM-DD to ISO 8601
  ISO_DATE="${DUE_DATE}T23:59:59Z"
  CMD="$CMD -f due_on=\"$ISO_DATE\""
fi

CMD="$CMD -f state=\"open\""

# Execute
echo "Command: $CMD"
echo ""
eval $CMD

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✅ Milestone M${MILESTONE_NUM} created successfully!${NC}"
  echo ""
  echo "Verify:"
  echo "  gh api repos/$REPO/milestones | jq -r '.[] | select(.title==\"$MILESTONE_TITLE\")'"
  echo ""
  echo "Next step:"
  echo "  Create epic issue: ./create-epic-issue.sh $MILESTONE_NUM \"$MILESTONE_TITLE\""
else
  echo -e "${RED}❌ Failed to create milestone${NC}"
  exit 1
fi
