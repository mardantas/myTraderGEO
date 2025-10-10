# Scripts de Validação

Scripts PowerShell para validação de qualidade do DDD Workflow.

## 📋 Scripts

- **validate-nomenclature.ps1** - Valida nomenclatura de documentos e código
- **validate-structure.ps1** - Valida estrutura de pastas e arquivos

## 📖 Documentação Completa

Ver documentação detalhada em: [00-Workflow-Guide.md](../docs/00-Workflow-Guide.md#-validação-de-qualidade)

## 🚀 Uso Rápido

```powershell
# Validar estrutura
.\validate-structure.ps1

# Validar nomenclatura
.\validate-nomenclature.ps1

# Validar nomenclatura + código
.\validate-nomenclature.ps1 -CheckCode
```

## 🔗 Referências

- **Workflow Guide:** [../docs/00-Workflow-Guide.md](../docs/00-Workflow-Guide.md)
- **Padrões de Nomenclatura:** [../docs/02-Nomenclature-Standards.md](../docs/02-Nomenclature-Standards.md)
