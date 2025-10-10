# GitHub Free - Setup Guide

**Objetivo:** Guia essencial para usar o workflow DDD com GitHub Free (versão gratuita).

**Versão:** 1.0
**Data:** 2025-10-09

---

## 🆓 GitHub Free vs Pro

### Limitações Principais (GitHub Free)

| Recurso | GitHub Free | GitHub Pro ($4/mês) |
|---------|-------------|---------------------|
| Branch Protection Rules | ❌ | ✅ |
| Required Reviewers | ❌ | ✅ |
| Required Status Checks | ❌ | ✅ |
| GitHub Actions | ✅ 2000 min/mês | ✅ 3000 min/mês |
| Pull Requests | ✅ | ✅ |
| Issues & Projects | ✅ | ✅ |
| Dependabot | ✅ | ✅ |
| CodeQL | ✅ | ✅ |

**Impacto:** Não há bloqueio automático de push direto para `main` ou merge de PRs com CI falhando.

---

## 🛡️ Estratégias para GitHub Free

### 1. Disciplina Manual

**Regra de Ouro:** NUNCA push direto para `main` ou `develop`

```bash
# ❌ ERRADO
git checkout main
git push origin main

# ✅ CORRETO
git checkout -b feature/epic-1-criar-estrategia
git push origin feature/epic-1-criar-estrategia
gh pr create
```

---

### 2. Git Hook Local (Pre-Push)

Criar `.git/hooks/pre-push`:

```bash
#!/bin/bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" == "main" ] || [ "$CURRENT_BRANCH" == "develop" ]; then
  echo "❌ ERRO: Push direto para $CURRENT_BRANCH não permitido!"
  echo "   Use: git checkout -b feature/... && gh pr create"
  exit 1
fi

echo "✅ Push permitido para $CURRENT_BRANCH"
```

**Setup:**
```bash
chmod +x .git/hooks/pre-push
```

**Limitação:** Cada desenvolvedor precisa configurar localmente.

---

### 3. CI como Gatekeeper

GitHub Actions mostra status no PR (✅/❌) mas NÃO bloqueia merge automaticamente.

**.github/workflows/ci.yml:**
```yaml
name: CI
on:
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          dotnet test 02-backend
          npm test --prefix 01-frontend
```

**Regra:** Respeitar status ❌ e NÃO fazer merge se CI falhar.

---

### 4. PR Template com Checklist

**.github/PULL_REQUEST_TEMPLATE.md:**
```markdown
## ✅ Checklist Obrigatório

- [ ] CI passou (✅ verde)
- [ ] Code review por 1+ pessoa
- [ ] Testes unitários passando
- [ ] Sem secrets hardcoded
- [ ] Documentação atualizada (se necessário)

## 🚫 Não Fazer Merge Se:
- ❌ CI falhando
- ❌ Sem code review
- ❌ Merge conflicts

## 📝 Descrição
[Descrever mudanças]

## 🎯 Issue
Closes #[número]
```

---

### 5. Branch Naming Convention

```bash
# ✅ Usar
feature/epic-1-user-auth
feature/de-order-aggregate
bugfix/issue-42-login-error
hotfix/critical-payment-bug

# ❌ Evitar push direto
main
develop
```

---

## 📋 Setup Inicial (GM Agent)

**GM cria durante Discovery:**

1. **Labels:**
```bash
gh label create "type:feature" -c "0E8A16"
gh label create "type:bug" -c "D93F0B"
gh label create "agent:de" -c "1D76DB"
gh label create "priority:high" -c "B60205"
```

2. **Templates:**
- `.github/ISSUE_TEMPLATE/epic.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

3. **CI/CD:**
- `.github/workflows/ci.yml`
- `.github/workflows/cd-staging.yml`

4. **Dependabot:**
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "nuget"
    directory: "/02-backend"
    schedule:
      interval: "weekly"
```

---

## 💰 Quando Considerar GitHub Pro?

**Vale a pena ($4/usuário/mês) se:**
- Time com 3+ desenvolvedores
- Projeto crítico (produção com >1000 usuários)
- Necessidade de branch protection automática (compliance)

**NÃO vale a pena se:**
- Projeto solo ou dupla
- MVP/protótipo
- Time disciplinado com PR workflow

---

## ✅ Checklist Developer Onboarding

- [ ] Ler workflow documentation ([00-Workflow-Guide.md](00-Workflow-Guide.md))
- [ ] Configurar Git hook pre-push (`.git/hooks/pre-push`)
- [ ] Testar bloqueio: `git checkout main && git push` (deve falhar ❌)
- [ ] Criar primeiro PR de teste
- [ ] Verificar CI status no PR (✅/❌)

---

## 🔗 Referências

- **GM Agent:** [01-Agents-Overview.md](01-Agents-Overview.md#25---gm-gerente-github)
- **Workflow Guide:** [00-Workflow-Guide.md](00-Workflow-Guide.md)
- **GitHub Free vs Pro:** https://docs.github.com/en/get-started/learning-about-github/githubs-plans

---

**Versão:** 1.0 (Simplified for Small/Medium Projects)
**Status:** Active
