#!/usr/bin/env bash
# validate-structure.sh
# Valida estrutura do repositório DDD Workflow v2.0

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
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo -e "\n${CYAN}🔍 DDD Workflow Structure Validator${NC}\n"

# 1. Validate required folders
echo -e "${YELLOW}📁 Validating folder structure...${NC}"

required_folders=(
    "00-doc-ddd/00-feedback"
    "00-doc-ddd/01-inputs-raw"
    "00-doc-ddd/02-strategic-design"
    "00-doc-ddd/03-ux-design"
    "00-doc-ddd/04-tactical-design"
    "00-doc-ddd/05-database-design"
    "00-doc-ddd/06-quality-assurance"
    "00-doc-ddd/07-github-management"
    "00-doc-ddd/08-platform-engineering"
    "00-doc-ddd/09-security"
    ".agents/templates/01-strategic-design"
    ".agents/templates/02-ux-design"
    ".agents/templates/03-tactical-design"
    ".agents/templates/04-database-design"
    ".agents/templates/05-quality-assurance"
    ".agents/templates/06-github-management"
    ".agents/templates/07-feedback"
    ".agents/templates/08-platform-engineering"
    ".agents/templates/09-security"
)

for folder in "${required_folders[@]}"; do
    if [[ -d "$folder" ]]; then
        [[ "$VERBOSE" == "true" ]] && echo -e "  ${GREEN}✅ $folder${NC}"
    else
        echo -e "  ${RED}❌ Missing: $folder${NC}"
        ((ERROR_COUNT++))
    fi
done

# 2. Validate configuration files
echo -e "\n${YELLOW}📄 Validating configuration files...${NC}"

required_files=(
    ".agents/docs/00-Workflow-Guide.md"
    ".agents/docs/01-Agents-Overview.md"
    ".agents/docs/02-Nomenclature-Standards.md"
    ".agents/docs/03-Security-And-Platform-Strategy.md"
    ".agents/docs/04-DDD-Patterns-Reference.md"
    ".agents/docs/05-API-Standards.md"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        [[ "$VERBOSE" == "true" ]] && echo -e "  ${GREEN}✅ $file${NC}"
    else
        echo -e "  ${RED}❌ Missing: $file${NC}"
        ((ERROR_COUNT++))
    fi
done

# 3. Validate agent XML definitions
echo -e "\n${YELLOW}🤖 Validating agent definitions...${NC}"

required_agents=(
    "10-SDA - Strategic Domain Analyst.xml"
    "15-DE - Domain Engineer.xml"
    "20-UXD - User Experience Designer.xml"
    "25-GM - GitHub Manager.xml"
    "30-PE - Platform Engineer.xml"
    "35-SEC - Security Specialist.xml"
    "45-SE - Software Engineer.xml"
    "50-DBA - Database Administrator.xml"
    "55-FE - Frontend Engineer.xml"
    "60-QAE - Quality Assurance Engineer.xml"
)

for agent in "${required_agents[@]}"; do
    agent_path=".agents/$agent"

    if [[ -f "$agent_path" ]]; then
        # Validate XML structure using xmllint if available
        if command -v xmllint &> /dev/null; then
            if xmllint --noout "$agent_path" 2>/dev/null; then
                # Count deliverables
                deliverable_count=$(grep -c '<deliverable>' "$agent_path" || echo "0")

                [[ "$VERBOSE" == "true" ]] && echo -e "  ${GREEN}✅ $agent ($deliverable_count deliverables)${NC}"

                # Validate templates referenced exist
                while IFS= read -r template_path; do
                    # Extract path from XML
                    template_path=$(echo "$template_path" | sed 's/.*<template>\(.*\)<\/template>.*/\1/')

                    if [[ -n "$template_path" && ! -f "$template_path" ]]; then
                        echo -e "    ${YELLOW}⚠️  Template missing: $template_path${NC}"
                        ((WARNING_COUNT++))
                    fi
                done < <(grep '<template>' "$agent_path" 2>/dev/null || true)
            else
                echo -e "  ${RED}❌ Invalid XML: $agent${NC}"
                ((ERROR_COUNT++))
            fi
        else
            # Basic validation without xmllint
            if grep -q '<agent>' "$agent_path"; then
                [[ "$VERBOSE" == "true" ]] && echo -e "  ${GREEN}✅ $agent${NC}"
            else
                echo -e "  ${RED}❌ Invalid XML: $agent${NC}"
                ((ERROR_COUNT++))
            fi
        fi
    else
        echo -e "  ${RED}❌ Missing: $agent${NC}"
        ((ERROR_COUNT++))
    fi
done

# 4. Validate templates
echo -e "\n${YELLOW}📝 Validating templates...${NC}"

required_templates=(
    ".agents/templates/01-strategic-design/SDA-01-Event-Storming.template.md"
    ".agents/templates/01-strategic-design/SDA-02-Context-Map.template.md"
    ".agents/templates/01-strategic-design/SDA-03-Ubiquitous-Language.template.md"
    ".agents/templates/02-ux-design/UXD-00-Design-Foundations.template.md"
    ".agents/templates/02-ux-design/UXD-01-[EpicName]-Wireframes.template.md"
    ".agents/templates/03-tactical-design/DE-01-[EpicName]-Tactical-Model.template.md"
    ".agents/templates/04-database-design/DBA-01-[EpicName]-Schema-Review.template.md"
    ".agents/templates/05-quality-assurance/QAE-00-Test-Strategy.template.md"
    ".agents/templates/06-github-management/GM-00-GitHub-Setup.template.md"
    ".agents/templates/07-feedback/FEEDBACK.template.md"
    ".agents/templates/08-platform-engineering/PE-00-Environments-Setup.template.md"
    ".agents/templates/08-platform-engineering/PE-EPIC-N-Performance-Checkpoint.template.md"
    ".agents/templates/09-security/SEC-00-Security-Baseline.template.md"
    ".agents/templates/09-security/SEC-EPIC-N-Security-Checkpoint.template.md"
)

for template in "${required_templates[@]}"; do
    if [[ -f "$template" ]]; then
        [[ "$VERBOSE" == "true" ]] && echo -e "  ${GREEN}✅ $template${NC}"
    else
        echo -e "  ${RED}❌ Missing: $template${NC}"
        ((ERROR_COUNT++))
    fi
done

# 5. Validate existing documents nomenclature
echo -e "\n${YELLOW}📋 Validating existing documents nomenclature...${NC}"

if [[ -d "00-doc-ddd" ]]; then
    valid_pattern='^(SDA|UXD|DE|DBA|SE|FE|QAE|GM|PE|SEC)-[0-9]{2}-.*\.md$'

    while IFS= read -r -d '' folder; do
        folder_name=$(basename "$folder")

        # Only check folders with pattern NN-*
        if [[ "$folder_name" =~ ^[0-9]{2}- ]]; then
            while IFS= read -r -d '' doc; do
                basename_doc=$(basename "$doc")

                # Skip README.md
                [[ "$basename_doc" == "README.md" ]] && continue

                if ! [[ "$basename_doc" =~ $valid_pattern ]]; then
                    echo -e "  ${YELLOW}⚠️  Non-standard name: $folder_name/$basename_doc${NC}"
                    ((WARNING_COUNT++))
                fi
            done < <(find "$folder" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
        fi
    done < <(find "00-doc-ddd" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
fi

# 6. Validate feedback files
echo -e "\n${YELLOW}💬 Validating feedback files...${NC}"

if [[ -d "00-doc-ddd/00-feedback" ]]; then
    valid_pattern='^FEEDBACK-[0-9]{3}-[A-Z]+-[A-Z]+-.*\.md$'
    feedback_count=0

    while IFS= read -r -d '' feedback; do
        basename_fb=$(basename "$feedback")
        ((feedback_count++))

        if [[ "$basename_fb" =~ $valid_pattern ]]; then
            [[ "$VERBOSE" == "true" ]] && echo -e "  ${GREEN}✅ $basename_fb${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Non-standard feedback name: $basename_fb${NC}"
            ((WARNING_COUNT++))
        fi
    done < <(find "00-doc-ddd/00-feedback" -name "FEEDBACK-*.md" -type f -print0 2>/dev/null)

    if [[ $feedback_count -eq 0 && "$VERBOSE" == "true" ]]; then
        echo -e "  ${CYAN}[INFO] No feedback files found (OK for new projects)${NC}"
    fi
fi

# 7. Check for duplicates/old folders
echo -e "\n${YELLOW}🔍 Checking for duplicates/old folders...${NC}"

old_folders=(
    "00-doc-ddd/05-security"
    "00-doc-ddd/10-github-management"
)

found_old=false
for old_folder in "${old_folders[@]}"; do
    if [[ -d "$old_folder" ]]; then
        echo -e "  ${YELLOW}⚠️  Old folder still present: $old_folder${NC}"
        ((WARNING_COUNT++))
        found_old=true
    fi
done

if [[ "$found_old" == "false" && "$VERBOSE" == "true" ]]; then
    echo -e "  ${GREEN}✅ No old folders found${NC}"
fi

# Summary
echo -e "\n${CYAN}============================================================${NC}"
echo -e "${CYAN}📊 VALIDATION SUMMARY${NC}"
echo -e "${CYAN}============================================================${NC}"

if [[ $ERROR_COUNT -eq 0 && $WARNING_COUNT -eq 0 ]]; then
    echo -e "\n${GREEN}✅ All checks passed! Structure is valid.${NC}"
    exit 0
elif [[ $ERROR_COUNT -eq 0 ]]; then
    echo -e "\n${YELLOW}⚠️  Warnings: $WARNING_COUNT${NC}"
    echo -e "${YELLOW}Structure is valid but some improvements recommended.${NC}"
    exit 0
else
    echo -e "\n${RED}Errors: $ERROR_COUNT${NC}"
    echo -e "${YELLOW}Warnings: $WARNING_COUNT${NC}"
    echo -e "${RED}Please fix errors before proceeding.${NC}"
    exit 1
fi
