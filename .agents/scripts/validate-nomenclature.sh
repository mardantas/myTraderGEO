#!/usr/bin/env bash
# validate-nomenclature.sh
# Valida nomenclatura de documentos e código conforme padrões DDD Workflow

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Counters
ERROR_COUNT=0
WARNING_COUNT=0

# Parameters
PATH_ARG="${1:-.}"
CHECK_CODE=false
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --check-code)
            CHECK_CODE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        *)
            PATH_ARG="$1"
            shift
            ;;
    esac
done

echo -e "\n${CYAN}📝 DDD Workflow Nomenclature Validator${NC}\n"

# Business terms mapping (PT -> EN)
declare -A BUSINESS_TERMS=(
    ["Estrategia"]="Strategy"
    ["Perna"]="StrategyLeg"
    ["Opcao"]="Option"
    ["Portfolio"]="Portfolio"
    ["Risco"]="Risk"
    ["Greeks"]="Greeks"
    ["Expiracao"]="Expiration"
    ["Strike"]="Strike"
    ["Premium"]="Premium"
)

# 1. Validate document nomenclature in 00-doc-ddd
echo -e "${YELLOW}📋 Validating document nomenclature in 00-doc-ddd...${NC}"

# Define valid patterns for each folder
declare -A DOC_PATTERNS=(
    ["02-strategic-design"]='^SDA-[0-9]{2}-.*\.md$'
    ["03-ux-design"]='^UXD-[0-9]{2}-.*\.md$'
    ["04-tactical-design"]='^DE-[0-9]{2}-.*\.md$'
    ["05-database-design"]='^DBA-[0-9]{2}-.*\.md$'
    ["06-quality-assurance"]='^QAE-[0-9]{2}-.*\.md$'
    ["07-github-management"]='^GM-[0-9]{2}-.*\.md$'
    ["08-platform-engineering"]='^(PE-[0-9]{2}-.*|PE-EPIC-[0-9]+-.*)\..md$'
    ["09-security"]='^(SEC-[0-9]{2}-.*|SEC-EPIC-[0-9]+-.*)\.md$'
    ["00-feedback"]='^FEEDBACK-[0-9]{3}-[A-Z]+-[A-Z]+-.*\.md$'
)

for folder in "${!DOC_PATTERNS[@]}"; do
    folder_path="00-doc-ddd/$folder"

    if [[ -d "$folder_path" ]]; then
        pattern="${DOC_PATTERNS[$folder]}"

        while IFS= read -r -d '' doc; do
            basename_doc=$(basename "$doc")

            # Skip README.md
            [[ "$basename_doc" == "README.md" ]] && continue

            if [[ "$basename_doc" =~ $pattern ]]; then
                [[ "$VERBOSE" == "true" ]] && echo -e "  ${GREEN}✅ $folder/$basename_doc${NC}"
            else
                echo -e "  ${RED}❌ Invalid name: $folder/$basename_doc${NC}"
                echo -e "     ${GRAY}Expected pattern: $pattern${NC}"
                ((ERROR_COUNT++))
            fi

            # Validate placeholders not replaced in content
            if grep -q '\[PROJECT_NAME\]' "$doc"; then
                echo -e "  ${YELLOW}⚠️  Placeholder [PROJECT_NAME] not replaced in $basename_doc${NC}"
                ((WARNING_COUNT++))
            fi

            if grep -q '\[YYYY-MM-DD\]' "$doc"; then
                echo -e "  ${YELLOW}⚠️  Placeholder [YYYY-MM-DD] not replaced in $basename_doc${NC}"
                ((WARNING_COUNT++))
            fi

            if [[ "$folder" == "04-tactical-design" ]] && grep -q '\[EpicName\]' "$doc"; then
                echo -e "  ${YELLOW}⚠️  Placeholder [EpicName] not replaced in $basename_doc${NC}"
                ((WARNING_COUNT++))
            fi
        done < <(find "$folder_path" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
    fi
done

# 2. Validate backend code (if requested)
if [[ "$CHECK_CODE" == "true" ]]; then
    echo -e "\n${YELLOW}💻 Validating backend code nomenclature...${NC}"

    if [[ -d "02-backend" ]]; then
        # Validate Aggregates use English
        while IFS= read -r -d '' file; do
            # Check for Portuguese terms in domain classes
            for term_pt in "${!BUSINESS_TERMS[@]}"; do
                term_en="${BUSINESS_TERMS[$term_pt]}"
                if grep -q "class\s\+$term_pt\b" "$file"; then
                    basename_file=$(basename "$file")
                    echo -e "  ${YELLOW}⚠️  Portuguese term in code: '$term_pt' in $basename_file${NC}"
                    echo -e "     ${GRAY}Should use: '$term_en'${NC}"
                    ((WARNING_COUNT++))
                fi
            done

            # Validate Aggregate has domain event support
            if grep -q 'class\s\+\w\+\s*:\s*Entity\s*<' "$file"; then
                if ! grep -q 'AddDomainEvent\|RaiseDomainEvent' "$file"; then
                    basename_file=$(basename "$file")
                    echo -e "  ${YELLOW}⚠️  Aggregate without domain event support: $basename_file${NC}"
                    ((WARNING_COUNT++))
                fi
            fi
        done < <(find "02-backend" -path "*/Domain/*" -name "*.cs" ! -name "*.Tests.*" -type f -print0 2>/dev/null)

        # Validate Value Objects are immutable
        while IFS= read -r -d '' file; do
            if grep -q '{\s*get;\s*set;\s*}' "$file"; then
                basename_file=$(basename "$file")
                echo -e "  ${RED}❌ Value Object with setter: $basename_file${NC}"
                echo -e "     ${GRAY}Value Objects must be immutable${NC}"
                ((ERROR_COUNT++))
            fi
        done < <(find "02-backend" -path "*/Domain/*" -name "*.cs" -type f -print0 2>/dev/null | xargs -0 grep -l 'record\s\+\w\+\|class\s\+\w\+\s*:\s*ValueObject' 2>/dev/null)
    fi

    # 3. Validate frontend code
    echo -e "\n${YELLOW}🎨 Validating frontend code nomenclature...${NC}"

    if [[ -d "01-frontend" ]]; then
        # Validate components follow PascalCase
        if [[ -d "01-frontend/src/components" ]]; then
            while IFS= read -r -d '' component; do
                basename_comp=$(basename "$component" .tsx)

                if ! [[ "$basename_comp" =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
                    echo -e "  ${YELLOW}⚠️  Component not PascalCase: $(basename "$component")${NC}"
                    ((WARNING_COUNT++))
                fi

                # Validate export default
                if ! grep -q 'export\s\+default' "$component"; then
                    echo -e "  ${YELLOW}⚠️  Component without default export: $(basename "$component")${NC}"
                    ((WARNING_COUNT++))
                fi
            done < <(find "01-frontend/src/components" -name "*.tsx" -type f -print0 2>/dev/null)
        fi

        # Validate hooks follow use* pattern
        if [[ -d "01-frontend/src/hooks" ]]; then
            while IFS= read -r -d '' hook; do
                basename_hook=$(basename "$hook" .ts)

                if ! [[ "$basename_hook" =~ ^use[A-Z] ]]; then
                    echo -e "  ${RED}❌ Hook not following use* pattern: $(basename "$hook")${NC}"
                    ((ERROR_COUNT++))
                fi
            done < <(find "01-frontend/src/hooks" -name "*.ts" -type f -print0 2>/dev/null)
        fi
    fi
fi

# 4. Validate templates
echo -e "\n${YELLOW}📝 Validating template nomenclature...${NC}"

if [[ -d ".agents/templates" ]]; then
    while IFS= read -r -d '' template; do
        basename_tmpl=$(basename "$template")
        folder_name=$(basename "$(dirname "$template")")

        # Validate template has .template.md extension
        if ! [[ "$basename_tmpl" =~ \.template\.md$ ]]; then
            echo -e "  ${YELLOW}⚠️  Template without .template.md extension: $basename_tmpl${NC}"
            ((WARNING_COUNT++))
        fi

        # Validate template has placeholders
        required_placeholders=('[PROJECT_NAME]' '[YYYY-MM-DD]')
        missing_placeholders=()

        for placeholder in "${required_placeholders[@]}"; do
            if ! grep -Fq "$placeholder" "$template"; then
                missing_placeholders+=("$placeholder")
            fi
        done

        if [[ ${#missing_placeholders[@]} -gt 0 ]]; then
            echo -e "  ${YELLOW}⚠️  Template missing placeholders: $basename_tmpl${NC}"
            echo -e "     ${GRAY}Missing: ${missing_placeholders[*]}${NC}"
            ((WARNING_COUNT++))
        elif [[ "$VERBOSE" == "true" ]]; then
            echo -e "  ${GREEN}✅ $folder_name/$basename_tmpl${NC}"
        fi
    done < <(find ".agents/templates" -name "*.template.md" -type f -print0 2>/dev/null)
fi

# 5. Validate Feedback files nomenclature
echo -e "\n${YELLOW}💬 Validating feedback nomenclature...${NC}"

if [[ -d "00-doc-ddd/00-feedback" ]]; then
    valid_agents=("SDA" "UXD" "DE" "DBA" "SE" "FE" "QAE" "GM" "PE" "SEC" "USER")

    while IFS= read -r -d '' feedback; do
        basename_fb=$(basename "$feedback")

        # Pattern: FEEDBACK-NNN-FROM-TO-title.md
        if [[ "$basename_fb" =~ ^FEEDBACK-([0-9]{3})-([A-Z]+)-([A-Z]+)-(.+)\.md$ ]]; then
            from="${BASH_REMATCH[2]}"
            to="${BASH_REMATCH[3]}"

            # Validate agents exist
            from_valid=false
            to_valid=false

            for agent in "${valid_agents[@]}"; do
                [[ "$from" == "$agent" ]] && from_valid=true
                [[ "$to" == "$agent" ]] && to_valid=true
            done

            if [[ "$from_valid" == "false" ]]; then
                echo -e "  ${RED}❌ Invalid source agent: $from in $basename_fb${NC}"
                ((ERROR_COUNT++))
            fi

            if [[ "$to_valid" == "false" ]]; then
                echo -e "  ${RED}❌ Invalid target agent: $to in $basename_fb${NC}"
                ((ERROR_COUNT++))
            fi

            if [[ "$VERBOSE" == "true" && "$from_valid" == "true" && "$to_valid" == "true" ]]; then
                echo -e "  ${GREEN}✅ $basename_fb${NC}"
            fi
        else
            echo -e "  ${RED}❌ Invalid feedback name: $basename_fb${NC}"
            echo -e "     ${GRAY}Expected: FEEDBACK-NNN-FROM-TO-title.md${NC}"
            ((ERROR_COUNT++))
        fi
    done < <(find "00-doc-ddd/00-feedback" -name "FEEDBACK-*.md" -type f -print0 2>/dev/null)
fi

# Summary
echo -e "\n${CYAN}============================================================${NC}"
echo -e "${CYAN}📊 NOMENCLATURE VALIDATION SUMMARY${NC}"
echo -e "${CYAN}============================================================${NC}"

if [[ $ERROR_COUNT -eq 0 && $WARNING_COUNT -eq 0 ]]; then
    echo -e "\n${GREEN}✅ All nomenclature checks passed!${NC}"
    exit 0
elif [[ $ERROR_COUNT -eq 0 ]]; then
    echo -e "\n${YELLOW}⚠️  Warnings: $WARNING_COUNT${NC}"
    echo -e "${YELLOW}Nomenclature is mostly correct but some improvements recommended.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Errors: $ERROR_COUNT${NC}"
    echo -e "${YELLOW}⚠️  Warnings: $WARNING_COUNT${NC}"
    echo -e "\n${RED}Please fix errors before proceeding.${NC}"
    exit 1
fi
