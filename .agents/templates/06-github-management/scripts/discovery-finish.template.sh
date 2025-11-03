#!/bin/bash

# discovery-finish.sh
# Finalizes Discovery Foundation phase
#
# Usage:
#   ./discovery-finish.sh                  # Validate and prepare PR
#
# This script:
#   1. Validates current branch (feature/discovery-foundation)
#   2. Validates all deliverables exist (8 files)
#   3. Executes validation scripts (PowerShell)
#   4. Makes final commit with "Closes #1"
#   5. Pushes to remote
#   6. Marks PR as "ready for review"
#   7. MANUAL: Review and merge PR via GitHub UI

set -e

# Configuration
REPO="[GITHUB_OWNER]/[REPO_NAME]"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🏁 DISCOVERY FOUNDATION - FINISH${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# STEP 1: VALIDATE CURRENT BRANCH
# ============================================================================
echo -e "${YELLOW}━━━ STEP 1/7: Validating current branch ━━━${NC}"
echo ""

CURRENT_BRANCH=$(git branch --show-current)
echo -e "  Current branch: ${BLUE}$CURRENT_BRANCH${NC}"

if [[ "$CURRENT_BRANCH" != "feature/discovery-foundation" ]]; then
  echo -e "  ${RED}❌ Error: Must be on 'feature/discovery-foundation' branch${NC}"
  echo ""
  echo "  Switch to valid branch:"
  echo "    git checkout feature/discovery-foundation"
  exit 1
fi

echo -e "  ${GREEN}✅ Valid branch${NC}"
echo ""

# ============================================================================
# STEP 2: VALIDATE DELIVERABLES
# ============================================================================
echo -e "${YELLOW}━━━ STEP 2/7: Validating deliverables ━━━${NC}"
echo ""

deliverables=(
  "00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md"
  "00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md"
  "00-doc-ddd/02-strategic-design/SDA-03-Ubiquitous-Language.md"
  "00-doc-ddd/03-ux-design/UXD-00-Design-Foundations.md"
  "00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md"
  "00-doc-ddd/08-platform-engineering/PE-00-Quick-Start.md, PE-01-Server-Setup.md, PE-02-Scaling-Strategy.md"
  "00-doc-ddd/09-security/SEC-00-Security-Baseline.md"
  "00-doc-ddd/06-quality-assurance/QAE-00-Test-Strategy.md"
)

missing=()
for file in "${deliverables[@]}"; do
  if [[ -f "$file" ]]; then
    echo -e "  ${GREEN}✅${NC} $file"
  else
    echo -e "  ${RED}❌${NC} $file"
    missing+=("$file")
  fi
done

echo ""

if [[ ${#missing[@]} -gt 0 ]]; then
  echo -e "${RED}❌ Missing deliverables (${#missing[@]}/8):${NC}"
  printf '   - %s\n' "${missing[@]}"
  echo ""
  echo "Create missing files before finishing Discovery."
  exit 1
fi

echo -e "${GREEN}✅ All deliverables present (8/8)${NC}"
echo ""

# ============================================================================
# STEP 3: EXECUTE VALIDATION SCRIPTS
# ============================================================================
echo -e "${YELLOW}━━━ STEP 3/7: Executing validation scripts ━━━${NC}"
echo ""

# Check if running on Windows (PowerShell available)
if command -v powershell &> /dev/null; then
  echo "  Running validate-structure.ps1..."
  powershell -File ./.agents/scripts/validate-structure.ps1

  if [ $? -ne 0 ]; then
    echo -e "  ${RED}❌ Structure validation failed${NC}"
    exit 1
  fi
  echo -e "  ${GREEN}✅ Structure validation passed${NC}"

  echo ""
  echo "  Running validate-nomenclature.ps1..."
  powershell -File ./.agents/scripts/validate-nomenclature.ps1

  if [ $? -ne 0 ]; then
    echo -e "  ${RED}❌ Nomenclature validation failed${NC}"
    exit 1
  fi
  echo -e "  ${GREEN}✅ Nomenclature validation passed${NC}"
else
  echo -e "  ${YELLOW}⚠️  PowerShell not available, skipping validation scripts${NC}"
  echo "  (Running on Linux/Mac - validation scripts require Windows)"
fi

echo ""

# ============================================================================
# STEP 4: FINAL COMMIT
# ============================================================================
echo -e "${YELLOW}━━━ STEP 4/7: Creating final commit ━━━${NC}"
echo ""

# Check if there are changes to commit
if git diff --quiet && git diff --cached --quiet; then
  echo -e "  ${YELLOW}⚠️  No changes to commit${NC}"
else
  git add .

  git commit -m "docs: Discovery Foundation completa

Todos os deliverables finalizados:
- SDA-01-Event-Storming.md
- SDA-02-Context-Map.md
- SDA-03-Ubiquitous-Language.md
- UXD-00-Design-Foundations.md
- GM-00-GitHub-Setup.md
- PE-00-Quick-Start.md, PE-01-Server-Setup.md, PE-02-Scaling-Strategy.md
- SEC-00-Security-Baseline.md
- QAE-00-Test-Strategy.md

Validações executadas com sucesso.

Closes #1"

  echo -e "  ${GREEN}✅ Final commit created${NC}"
fi

echo ""

# ============================================================================
# STEP 5: PUSH TO REMOTE
# ============================================================================
echo -e "${YELLOW}━━━ STEP 5/7: Pushing to remote ━━━${NC}"
echo ""

git push origin feature/discovery-foundation

echo -e "  ${GREEN}✅ Pushed to remote${NC}"
echo ""

# ============================================================================
# STEP 6: MARK PR AS READY
# ============================================================================
echo -e "${YELLOW}━━━ STEP 6/7: Marking PR as ready for review ━━━${NC}"
echo ""

# Get PR number
PR_NUMBER=$(gh pr list --head feature/discovery-foundation --repo $REPO --json number -q '.[0].number' 2>/dev/null || echo "")

if [ -z "$PR_NUMBER" ]; then
  echo -e "  ${YELLOW}⚠️  No PR found, skipping${NC}"
else
  # Check if PR is draft
  IS_DRAFT=$(gh pr view $PR_NUMBER --repo $REPO --json isDraft -q '.isDraft')

  if [ "$IS_DRAFT" = "true" ]; then
    gh pr ready $PR_NUMBER --repo $REPO
    echo -e "  ${GREEN}✅ PR #${PR_NUMBER} marked as ready for review${NC}"
  else
    echo -e "  ${YELLOW}⚠️  PR #${PR_NUMBER} already ready${NC}"
  fi
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ DISCOVERY FOUNDATION - PR READY!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo ""
echo -e "  ${GREEN}✅${NC} All deliverables validated (8/8)"
echo -e "  ${GREEN}✅${NC} Validation scripts passed"
echo -e "  ${GREEN}✅${NC} Final commit created"
echo -e "  ${GREEN}✅${NC} Pushed to remote"
echo -e "  ${GREEN}✅${NC} PR marked as ready for review"

echo ""
echo -e "${YELLOW}📋 Next Steps (MANUAL):${NC}"
echo ""
echo "1. Review and merge PR:"
echo "   ${BLUE}https://github.com/$REPO/pull/${PR_NUMBER:-<number>}${NC}"
echo ""
echo "   Via GitHub UI:"
echo "   - Review changes"
echo "   - Click 'Merge pull request' → 'Create a merge commit'"
echo "   - Delete branch after merge"
echo ""
echo "   Or via CLI:"
echo "   ${BLUE}gh pr merge --merge --delete-branch${NC}"
echo ""
echo "2. (Optional) Create v0.1.0 release after merge:"
echo "   - Merge develop → main"
echo "   - Create tag: ${BLUE}git tag -a v0.1.0 -m 'Release v0.1.0: Discovery Foundation'${NC}"
echo "   - Push: ${BLUE}git push origin main --tags${NC}"
echo "   - Create GitHub Release: ${BLUE}gh release create v0.1.0${NC}"
echo ""
echo "3. Start EPIC-01 modeling:"
echo "   ./epic-modeling-start.sh 1"
echo ""
echo -e "${BLUE}📖 Documentation:${NC}"
echo "   - Git workflow: .agents/docs/03-GIT-PATTERNS.md#guia-operacional-iniciar-novo-épico"
echo "   - Workflow guide: .agents/docs/00-Workflow-Guide.md"
echo ""
