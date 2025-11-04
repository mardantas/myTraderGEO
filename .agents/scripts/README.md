# Validation Scripts

Quality validation scripts for the DDD Workflow.

## 📋 Available Scripts

This folder contains validation scripts for maintaining code quality and documentation standards:

- **validate-nomenclature.sh** - Validates document and code nomenclature
- **validate-structure.sh** - Validates folder structure and required files
- **epic-deploy.sh** - Epic deployment automation script
- **epic-start.sh** - Epic initialization script
- **fix-markdown-trailing-spaces.sh** - Fixes markdown trailing spaces

## 📖 Complete Documentation

For detailed documentation about validation rules and standards, see:
[00-Workflow-Guide.md](../docs/00-Workflow-Guide.md#-validação-de-qualidade)

## 🚀 Quick Usage

### Validate Structure
```bash
./validate-structure.sh

# Verbose mode (shows all validated files)
./validate-structure.sh --verbose
```

### Validate Nomenclature
```bash
./validate-nomenclature.sh

# With backend/frontend code validation
./validate-nomenclature.sh --check-code

# Verbose mode
./validate-nomenclature.sh --verbose

# Combined (code + verbose)
./validate-nomenclature.sh --check-code --verbose
```

## 💻 Windows Users

To run these shell scripts on Windows, use one of the following:

- **Git Bash** (recommended, installed with Git for Windows)
- **WSL2** (Windows Subsystem for Linux)
- **PowerShell 7+** with bash compatibility

Example using Git Bash:
```bash
# From Git Bash terminal
cd /c/Users/Marco/Projetos/myTraderGEO
./.agents/scripts/validate-nomenclature.sh
```

## 🔗 References

- **Workflow Guide:** [../docs/00-Workflow-Guide.md](../docs/00-Workflow-Guide.md)
- **Nomenclature Standards:** [../docs/02-Nomenclature-Standards.md](../docs/02-Nomenclature-Standards.md)
