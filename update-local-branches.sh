#!/bin/bash

# ==================================
# update-local-branches.sh
# ==================================
# Atualiza todas as branches locais do repositório
# - Verifica se há mudanças/commits pendentes (aborta se houver)
# - Faz fetch --prune para sincronizar com o servidor
# - Detecta se a branch atual foi deletada no servidor
# - Atualiza main, develop, workflow
# - Lista novas branches remotas disponíveis

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
INFO="${BLUE}📥${NC}"
LIST="${CYAN}📋${NC}"
BULB="${CYAN}💡${NC}"
STAR="${GREEN}✨${NC}"

echo ""
echo "🔍 Verificando estado do repositório..."

# 1. Verificar mudanças não commitadas
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${CROSS} ERRO: Há mudanças não commitadas no working tree"
    echo ""
    git status --short
    echo ""
    echo -e "${YELLOW}Por favor, faça commit ou stash das mudanças antes de continuar${NC}"
    exit 1
fi
echo -e "${CHECK} Working tree limpo"

# Salvar branch atual
CURRENT_BRANCH=$(git branch --show-current)

# 2. Verificar commits não pushados (se a branch tem remote)
if git rev-parse --abbrev-ref --symbolic-full-name @{u} > /dev/null 2>&1; then
    UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
    COMMITS_AHEAD=$(git rev-list ${UPSTREAM}..HEAD --count)

    if [[ $COMMITS_AHEAD -gt 0 ]]; then
        echo -e "${CROSS} ERRO: Há ${COMMITS_AHEAD} commit(s) não pushado(s) na branch '${CURRENT_BRANCH}'"
        echo ""
        git log ${UPSTREAM}..HEAD --oneline
        echo ""
        echo -e "${YELLOW}Por favor, faça push dos commits antes de continuar${NC}"
        exit 1
    fi
fi
echo -e "${CHECK} Sem commits pendentes"

echo ""
echo "📡 Sincronizando com servidor..."

# 3. Fetch com prune (remove branches remotas deletadas)
git fetch --all --prune > /dev/null 2>&1
echo -e "${CHECK} Fetch concluído (branches remotas deletadas foram removidas)"

# 4. Verificar se a branch atual ainda existe no servidor
BRANCH_EXISTS_ON_REMOTE=false
if git show-ref --verify --quiet refs/remotes/origin/${CURRENT_BRANCH}; then
    BRANCH_EXISTS_ON_REMOTE=true
else
    echo ""
    echo -e "${WARN}  Branch '${CURRENT_BRANCH}' não existe mais no servidor"
    echo -e "    → Mudando para 'develop'..."
    git checkout develop > /dev/null 2>&1
    CURRENT_BRANCH="develop"
fi

echo ""
echo -e "${INFO} Atualizando branches principais..."

# 5. Atualizar branches principais
BRANCHES_TO_UPDATE=("main" "develop" "workflow")

for branch in "${BRANCHES_TO_UPDATE[@]}"; do
    # Verificar se a branch existe localmente
    if git show-ref --verify --quiet refs/heads/${branch}; then
        if [[ "$branch" != "$CURRENT_BRANCH" ]]; then
            git checkout ${branch} > /dev/null 2>&1
        fi

        # Tentar fazer pull
        if git pull origin ${branch} > /dev/null 2>&1; then
            echo -e "  ${CHECK} ${branch} atualizada"
        else
            echo -e "  ${WARN}  ${branch} - erro ao atualizar"
        fi
    else
        echo -e "  ${WARN}  ${branch} - não existe localmente"
    fi
done

# 6. Voltar para a branch original e atualizar
if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "develop" && "$CURRENT_BRANCH" != "workflow" ]]; then
    git checkout ${CURRENT_BRANCH} > /dev/null 2>&1

    if $BRANCH_EXISTS_ON_REMOTE; then
        if git pull origin ${CURRENT_BRANCH} > /dev/null 2>&1; then
            echo -e "  ${CHECK} ${CURRENT_BRANCH} atualizada"
        else
            echo -e "  ${WARN}  ${CURRENT_BRANCH} - erro ao atualizar"
        fi
    fi
else
    # Se já estamos em uma das branches principais, garantir que estamos nela
    git checkout ${CURRENT_BRANCH} > /dev/null 2>&1
fi

# 7. Verificar sincronização de branches (local vs remoto)
echo ""
echo -e "${LIST} Verificando sincronização de branches..."

# Obter branches remotas (exceto HEAD)
REMOTE_BRANCHES=$(git branch -r | grep -v '\->' | sed 's/origin\///' | tr -d ' ')

# Obter branches locais
LOCAL_BRANCHES=$(git branch | tr -d ' *')

# A) Encontrar branches LOCAIS que NÃO existem mais no servidor
OLD_LOCAL_BRANCHES=()
while IFS= read -r local_branch; do
    # Ignorar branches principais e do dependabot
    if [[ "$local_branch" != "main" && "$local_branch" != "develop" && "$local_branch" != "workflow" && "$local_branch" != *"dependabot"* ]]; then
        if ! echo "$REMOTE_BRANCHES" | grep -q "^${local_branch}$"; then
            OLD_LOCAL_BRANCHES+=("$local_branch")
        fi
    fi
done <<< "$LOCAL_BRANCHES"

# B) Encontrar branches REMOTAS que NÃO existem localmente
NEW_REMOTE_BRANCHES=()
while IFS= read -r remote_branch; do
    # Ignorar branches principais e do dependabot
    if [[ "$remote_branch" != "main" && "$remote_branch" != "develop" && "$remote_branch" != "workflow" && "$remote_branch" != *"dependabot"* ]]; then
        if ! echo "$LOCAL_BRANCHES" | grep -q "^${remote_branch}$"; then
            NEW_REMOTE_BRANCHES+=("$remote_branch")
        fi
    fi
done <<< "$REMOTE_BRANCHES"

# Mostrar branches locais antigas (não existem mais no servidor)
if [[ ${#OLD_LOCAL_BRANCHES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Branches locais que não existem mais no servidor:${NC}"
    for old_branch in "${OLD_LOCAL_BRANCHES[@]}"; do
        echo -e "  ${YELLOW}•${NC} ${old_branch}"
    done
    echo ""
    echo -e "${BULB} Para deletar uma branch local:"
    echo -e "   ${BLUE}git branch -d <nome-da-branch>${NC}     ${CYAN}# Delete se já foi mergeada${NC}"
    echo -e "   ${BLUE}git branch -D <nome-da-branch>${NC}     ${CYAN}# Force delete${NC}"
    echo ""
    echo -e "${YELLOW}Exemplo:${NC}"
    if [[ ${#OLD_LOCAL_BRANCHES[@]} -gt 0 ]]; then
        echo -e "   ${BLUE}git branch -d ${OLD_LOCAL_BRANCHES[0]}${NC}"
    fi
fi

# Mostrar branches remotas novas (não existem localmente)
if [[ ${#NEW_REMOTE_BRANCHES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${CYAN}📥 Novas branches disponíveis no servidor:${NC}"
    for new_branch in "${NEW_REMOTE_BRANCHES[@]}"; do
        echo -e "  ${CYAN}•${NC} ${new_branch}"
    done
    echo ""
    echo -e "${BULB} Para criar e trabalhar em uma branch remota:"
    echo -e "   ${BLUE}git checkout <nome-da-branch>${NC}     ${CYAN}# Git cria automaticamente da origin${NC}"
    echo ""
    echo -e "${YELLOW}Exemplo:${NC}"
    if [[ ${#NEW_REMOTE_BRANCHES[@]} -gt 0 ]]; then
        echo -e "   ${BLUE}git checkout ${NEW_REMOTE_BRANCHES[0]}${NC}"
    fi
fi

# Se tudo está sincronizado
if [[ ${#OLD_LOCAL_BRANCHES[@]} -eq 0 && ${#NEW_REMOTE_BRANCHES[@]} -eq 0 ]]; then
    echo -e "${CHECK} Todas as branches estão sincronizadas"
fi

echo ""
echo -e "${LIST} Situação das branches locais:"
echo ""
git branch -vv

echo ""
echo -e "${STAR} Atualização concluída! Branch atual: ${GREEN}${CURRENT_BRANCH}${NC}"
echo ""
