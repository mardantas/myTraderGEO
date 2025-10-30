# Markdown Style Guide

**Versão:** 1.0  
**Data:** 2025-10-30  
**Objetivo:** Garantir formatação consistente e correta em todos os documentos Markdown  

---

## 🚨 Regra Crítica: Trailing Spaces

**TODAS as listas e metadados DEVEM terminar com 2 espaços invisíveis**

---

## ❌ ERRADO (sem trailing spaces)

```markdown
- Item 1  
- Item 2  
- Item 3  
```

**Problema:** Renderiza incorretamente em muitos parsers Markdown (GitHub, VSCode, etc).  

---

## ✅ CORRETO (com 2 espaços no final)

```markdown
- Item 1··  
- Item 2··  
- Item 3··  
```

*Nota: `··` representa os 2 espaços invisíveis no final da linha*

**Resultado:** Cada item renderiza em linha separada com espaçamento correto.  

---

## 🔧 Como Detectar e Corrigir

### Manualmente (VSCode):
1. `View → Render Whitespace` - mostra espaços como `·`
2. `Ctrl+Shift+V` - preview antes de salvar

### Automaticamente:
```powershell
# Corrigir todos os .md
.\.agents\scripts\fix-markdown-trailing-spaces.ps1
```

---

## 📋 Onde Aplicar

| Elemento | Trailing Spaces? | Exemplo |
|----------|------------------|---------|
| **Listas** | ✅ OBRIGATÓRIO | `- Item··` |
| **Metadados** | ✅ OBRIGATÓRIO | `**Versão:** 1.0··` |
| **Tabelas** | ✅ OBRIGATÓRIO | `\| Cell 1 \| Cell 2 \|··` |
| **Parágrafos** | ❌ Opcional | `Texto normal` |
| **Títulos** | ❌ Não usar | `# Título` |
| **Código** | ❌ Não usar | ` ```code``` ` |

---

## 📚 Referência

- **CommonMark Spec:** Hard line breaks requerem 2+ trailing spaces  
- **GitHub Flavored Markdown:** Compatível  
- **VSCode Markdown Preview:** Compatível  

---

**Versão:** 1.0  
**Data:** 2025-10-30  
**Workflow:** DDD com 10 Agentes  
