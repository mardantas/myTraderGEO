#!/bin/bash

# ==================================
# workflow-cascade.sh
# ==================================
# Automatiza o fluxo de merge em cascata do workflow até a feature:
# 1. Commit e push na branch workflow (deve estar nela)
# 2. Merge workflow → main e push
# 3. Merge main → develop e push
# 4. Merge develop → feature e push

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Símbolos
CHECK="${GREEN}✅${NC}"
CROSS="${RED}❌${NC}"
WARN="${YELLOW}⚠️${NC}"
ARROW="${BLUE}→${NC}"
STAR="${GREEN}✨${NC}"

echo ""
echo "🔄 Workflow Cascade - Merge em cascata do workflow até feature"
echo ""

# 1. Verificar branch atual - DEVE estar na workflow
CURRENT_BRANCH=$(git branch --show-current)

if [[ "$CURRENT_BRANCH" != "workflow" ]]; then
    echo -e "${CROSS} ERRO: Este script deve ser executado da branch 'workflow'"
    echo -e "${YELLOW}Branch atual: ${CURRENT_BRANCH}${NC}"
    echo ""
    echo -e "${CYAN}Use: git checkout workflow${NC}"
    exit 1
fi

echo -e "📍 Branch atual: ${GREEN}workflow${NC} ✓"
echo ""

# 2. Detectar a feature branch de destino
echo "🔍 Detectando branches de feature..."
FEATURE_BRANCHES=$(git branch | grep -v "main" | grep -v "develop" | grep -v "workflow" | grep -v "^\*" | sed 's/^[* ]*//')

if [[ -z "$FEATURE_BRANCHES" ]]; then
    echo -e "${CROSS} ERRO: Nenhuma branch de feature encontrada"
    echo -e "${YELLOW}Crie uma feature branch primeiro${NC}"
    exit 1
fi

# Se houver múltiplas features, perguntar qual usar
FEATURE_COUNT=$(echo "$FEATURE_BRANCHES" | wc -l)
TARGET_BRANCH=""

if [[ $FEATURE_COUNT -eq 1 ]]; then
    TARGET_BRANCH="$FEATURE_BRANCHES"
    echo -e "🎯 Branch de destino: ${GREEN}${TARGET_BRANCH}${NC}"
else
    echo -e "${CYAN}Múltiplas branches de feature encontradas:${NC}"
    echo ""
    PS3="Selecione a branch de destino: "
    select branch in $FEATURE_BRANCHES; do
        if [[ -n "$branch" ]]; then
            TARGET_BRANCH="$branch"
            echo ""
            echo -e "🎯 Branch selecionada: ${GREEN}${TARGET_BRANCH}${NC}"
            break
        fi
    done
fi

if [[ -z "$TARGET_BRANCH" ]]; then
    echo -e "${CROSS} Nenhuma branch selecionada"
    exit 1
fi

echo ""

# 3. Verificar se há mudanças para commitar na workflow
if [[ -z $(git status --porcelain) ]]; then
    echo -e "${WARN}  Nenhuma mudança para commitar na branch 'workflow'"
    echo ""
    read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operação cancelada${NC}"
        exit 1
    fi
else
    # Há mudanças - pedir mensagem de commit
    echo ""
    echo -e "${CYAN}Digite a mensagem do commit para a branch 'workflow':${NC}"
    read -p "> " COMMIT_MSG

    if [[ -z "$COMMIT_MSG" ]]; then
        echo -e "${CROSS} Mensagem de commit não pode ser vazia"
        exit 1
    fi

    # Fazer commit
    echo ""
    echo "💾 Commitando mudanças na 'workflow'..."
    git add .
    git commit -m "$COMMIT_MSG" > /dev/null 2>&1
    echo -e "${CHECK} Commit realizado"
fi

# 4. Push workflow
echo ""
echo "📤 Fazendo push da branch 'workflow'..."
if git push origin workflow; then
    echo -e "${CHECK} Push workflow concluído"
else
    echo -e "${CROSS} Erro ao fazer push da workflow"
    exit 1
fi

# 5. Merge workflow → main e push
echo ""
echo -e "${ARROW} Merge: workflow ${ARROW} main"
git checkout main > /dev/null 2>&1

if git merge workflow --no-edit; then
    echo -e "${CHECK} Merge workflow → main concluído"

    echo "📤 Fazendo push da branch 'main'..."
    if git push origin main; then
        echo -e "${CHECK} Push main concluído"
    else
        echo -e "${CROSS} Erro ao fazer push da main"
        git checkout workflow > /dev/null 2>&1
        exit 1
    fi
else
    echo -e "${CROSS} Erro no merge workflow → main"
    echo -e "${YELLOW}Resolva os conflitos manualmente${NC}"
    git checkout workflow > /dev/null 2>&1
    exit 1
fi

# 6. Merge main → develop e push
echo ""
echo -e "${ARROW} Merge: main ${ARROW} develop"
git checkout develop > /dev/null 2>&1

if git merge main --no-edit; then
    echo -e "${CHECK} Merge main → develop concluído"

    echo "📤 Fazendo push da branch 'develop'..."
    if git push origin develop; then
        echo -e "${CHECK} Push develop concluído"
    else
        echo -e "${CROSS} Erro ao fazer push da develop"
        git checkout workflow > /dev/null 2>&1
        exit 1
    fi
else
    echo -e "${CROSS} Erro no merge main → develop"
    echo -e "${YELLOW}Resolva os conflitos manualmente${NC}"
    git checkout workflow > /dev/null 2>&1
    exit 1
fi

# 7. Merge develop → feature e PUSH
echo ""
echo -e "${ARROW} Merge: develop ${ARROW} ${TARGET_BRANCH}"
git checkout ${TARGET_BRANCH} > /dev/null 2>&1

if git merge develop --no-edit; then
    echo -e "${CHECK} Merge develop → ${TARGET_BRANCH} concluído"

    echo "📤 Fazendo push da branch '${TARGET_BRANCH}'..."
    if git push origin ${TARGET_BRANCH}; then
        echo -e "${CHECK} Push ${TARGET_BRANCH} concluído"
    else
        echo -e "${CROSS} Erro ao fazer push da ${TARGET_BRANCH}"
        git checkout workflow > /dev/null 2>&1
        exit 1
    fi
else
    echo -e "${CROSS} Erro no merge develop → ${TARGET_BRANCH}"
    echo -e "${YELLOW}Resolva os conflitos manualmente${NC}"
    git checkout workflow > /dev/null 2>&1
    exit 1
fi

# 8. Resumo final (permanece na feature)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${STAR} Cascade concluído com sucesso!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}Fluxo executado:${NC}"
echo -e "  1. ${CHECK} workflow commitada e pushed"
echo -e "  2. ${CHECK} workflow → main (merged e pushed)"
echo -e "  3. ${CHECK} main → develop (merged e pushed)"
echo -e "  4. ${CHECK} develop → ${TARGET_BRANCH} (merged e pushed)"
echo ""
echo -e "${CYAN}Branch atual: ${GREEN}${TARGET_BRANCH}${NC}"
echo ""
