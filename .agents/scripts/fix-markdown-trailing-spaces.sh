#!/bin/bash

# fix-markdown-trailing-spaces.sh
# Corrige listas em arquivos Markdown adicionando 2 trailing spaces

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de output
info() { echo -e "${CYAN}$1${NC}"; }
success() { echo -e "${GREEN}$1${NC}"; }
warning() { echo -e "${YELLOW}$1${NC}"; }
error() { echo -e "${RED}$1${NC}"; }

# Parâmetros
DRY_RUN=false
PATH_ARG=".agents/docs"

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        *)
            PATH_ARG="$1"
            shift
            ;;
    esac
done

info "\n🔧 Markdown Trailing Spaces Fixer"
info "=================================="

if [ "$DRY_RUN" = true ]; then
    warning "⚠️  DRY RUN MODE - Nenhuma alteração será feita\n"
fi

# Encontrar arquivos .md
if [ -f "$PATH_ARG" ]; then
    files=("$PATH_ARG")
elif [ -d "$PATH_ARG" ]; then
    mapfile -t files < <(find "$PATH_ARG" -name "*.md" -type f)
else
    error "❌ Caminho não encontrado: $PATH_ARG"
    exit 1
fi

if [ ${#files[@]} -eq 0 ]; then
    error "❌ Nenhum arquivo .md encontrado"
    exit 1
fi

info "📁 Encontrados ${#files[@]} arquivo(s) .md\n"

total_changes=0
files_changed=0

for file in "${files[@]}"; do
    filename=$(basename "$file")
    info "📝 Processando: $filename"

    changes=0
    temp_file=$(mktemp)

    # Usa sed para processar o arquivo
    sed -E '
        # Ignora code blocks, títulos, separadores
        /^```/b
        /^#+/b
        /^---+$/b
        /^\s*\|.*\|$/b

        # Para listas: adiciona 2 trailing spaces
        /^[[:space:]]*[-*+][[:space:]]+/{
            s/[[:space:]]*$//
            s/$/  /
        }

        # Para metadados: adiciona 2 trailing spaces
        /^\*\*[^:]+:\*\*[[:space:]]+/{
            s/[[:space:]]*$//
            s/$/  /
        }
    ' "$file" > "$temp_file"

    # Verifica se houve mudanças
    if ! cmp -s "$file" "$temp_file"; then
        changes=$(wc -l < "$temp_file")
        if [ "$DRY_RUN" = false ]; then
            mv "$temp_file" "$file"
            success "  ✅ Corrigido: $changes linha(s) modificada(s)"
        else
            warning "  🔍 Seria modificado: $changes linha(s)"
            rm "$temp_file"
        fi
        ((total_changes += changes))
        ((files_changed++))
    else
        echo -e "  \033[90mℹ️  Nenhuma correção necessária\033[0m"
        rm "$temp_file"
    fi
done

info "\n=================================="
info "📊 RESUMO"
info "=================================="
echo "Arquivos processados: ${#files[@]}"
echo -e "${GREEN}Arquivos modificados: $files_changed${NC}"
echo -e "${GREEN}Total de linhas corrigidas: $total_changes${NC}"

if [ "$DRY_RUN" = true ]; then
    warning "\n⚠️  DRY RUN - Execute sem --dry-run para aplicar as mudanças"
elif [ $files_changed -gt 0 ]; then
    success "\n✅ Correção concluída com sucesso!"
    info "💡 Tip: Execute 'git diff' para revisar as mudanças"
else
    success "\n✅ Todos os arquivos já estão corretos!"
fi

exit 0
