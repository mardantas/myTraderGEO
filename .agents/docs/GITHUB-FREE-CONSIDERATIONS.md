# GitHub Free - Considerações e Limitações

**Data:** 2025-10-08
**Versão Workflow:** 3.0
**Contexto:** Projeto usando GitHub Free (versão gratuita)

---

## 🆓 Limitações do GitHub Free

### ❌ Recursos NÃO Disponíveis

| Recurso | GitHub Free | GitHub Pro | Impacto |
|---------|-------------|------------|---------|
| **Branch Protection Rules** | ❌ Não | ✅ Sim | Alto - Não bloqueia push direto para main |
| **Required Reviewers** | ❌ Não | ✅ Sim | Alto - Não força code review |
| **Required Status Checks** | ❌ Não | ✅ Sim | Médio - CI pode falhar e ainda fazer merge |
| **CODEOWNERS** | ❌ Não | ✅ Sim | Baixo - Não atribui reviewers automaticamente |
| **Multiple PR Reviewers** | ❌ Não | ✅ Sim | Baixo - Apenas 1 reviewer por PR |

### ✅ Recursos Disponíveis

| Recurso | Disponível | Notas |
|---------|------------|-------|
| **Pull Requests** | ✅ Sim | Workflow PR funciona normalmente |
| **GitHub Actions** | ✅ Sim | 2000 min/mês (suficiente para small/medium) |
| **Issues & Projects** | ✅ Sim | Ilimitado |
| **Labels & Milestones** | ✅ Sim | Ilimitado |
| **Dependabot** | ✅ Sim | Security alerts + PRs automáticos |
| **CodeQL** | ✅ Sim | SAST gratuito |
| **GitHub Pages** | ✅ Sim | Para documentação |

---

## 🛡️ Estratégias de Mitigação (GitHub Free)

### 1. Disciplina de Code Review

**Problema:** Branch protection não existe
**Solução:** Disciplina manual + processo claro

```bash
# ❌ NUNCA fazer:
git checkout main
git merge feature/xyz
git push origin main

# ✅ SEMPRE fazer:
git checkout feature/xyz
git push origin feature/xyz
gh pr create --base main --head feature/xyz
# Aguardar review antes de merge
```

**Checklist de Disciplina:**
- [ ] NUNCA fazer push direto para `main`
- [ ] NUNCA fazer push direto para `develop`
- [ ] SEMPRE criar PR para mudanças
- [ ] SEMPRE aguardar CI passar (✅) antes de merge
- [ ] SEMPRE solicitar code review (mesmo que não obrigatório)

---

### 2. GitHub Actions como "Gatekeeper"

**Problema:** Status checks não bloqueiam merge automaticamente
**Solução:** CI mostra status ❌ (developer deve respeitar)

**CI Pipeline:**
```yaml
# .github/workflows/ci.yml
name: CI
on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [feature/**, bugfix/**]

jobs:
  backend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: dotnet test
      - name: Block if tests fail
        if: failure()
        run: exit 1

  frontend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: npm test
      - name: Block if tests fail
        if: failure()
        run: exit 1
```

**Como funciona:**
- PR criado → Actions roda automaticamente
- Status aparece no PR: ✅ All checks passed ou ❌ Some checks failed
- Developer deve **respeitar** o status ❌ e NÃO fazer merge

**Limitação:** GitHub Free não bloqueia merge se CI falhar (apenas mostra status).

---

### 3. Git Hooks Locais

**Problema:** Sem proteção de branch no servidor
**Solução:** Prevenção local com Git hooks

**Criar hook `pre-push`:**
```bash
# .git/hooks/pre-push (criar e dar chmod +x)
#!/bin/bash

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" == "main" ]; then
  echo "❌ ERRO: Push direto para main não permitido!"
  echo "   Use PR: git checkout -b feature/... && git push origin feature/..."
  exit 1
fi

if [ "$CURRENT_BRANCH" == "develop" ]; then
  echo "⚠️  AVISO: Push para develop. Tem certeza?"
  echo "   Pressione Ctrl+C para cancelar ou aguarde 5 segundos..."
  sleep 5
fi

echo "✅ Push permitido para $CURRENT_BRANCH"
```

**Setup:**
```bash
# Criar hook
nano .git/hooks/pre-push
# Colar código acima
# Salvar e dar permissão de execução
chmod +x .git/hooks/pre-push

# Testar
git checkout main
git push origin main
# Deve bloquear com erro ❌
```

**Limitação:** Git hooks são locais (não commitados no repo). Cada desenvolvedor precisa configurar manualmente.

---

### 4. Branch Naming Convention

**Problema:** Sem restrição de branches no servidor
**Solução:** Convenção clara + disciplina

**Branches Permitidos:**
```bash
# ✅ Feature branches
feature/epic-1-user-registration
feature/epic-2-payment-integration
feature/de-order-aggregate
feature/fe-dashboard-component

# ✅ Bugfix branches
bugfix/issue-42-login-error
bugfix/null-reference-exception

# ✅ Hotfix branches (produção)
hotfix/critical-payment-bug
hotfix/security-vulnerability

# ✅ Refactor branches
refactor/extract-validation-service
refactor/optimize-query-performance

# ❌ Evitar push direto (usar PR)
main       # Somente via PR
develop    # Somente via PR de feature/*
```

**Nomenclatura:**
- `feature/epic-X-nome` → Nova funcionalidade (por épico)
- `bugfix/issue-Y-nome` → Correção de bug (referencia issue #Y)
- `hotfix/critical-Z` → Hotfix de produção (urgente)
- `refactor/nome` → Refatoração (sem mudança de comportamento)

---

### 5. PR Template com Checklist Manual

**Problema:** Sem required reviewers ou checks obrigatórios
**Solução:** Template força checklist manual

**.github/PULL_REQUEST_TEMPLATE.md:**
```markdown
## ✅ Checklist Obrigatório

### Code Quality
- [ ] Código revisado por pelo menos 1 pessoa (self-review não conta)
- [ ] Testes unitários adicionados/atualizados
- [ ] Todos os testes passando localmente
- [ ] GitHub Actions CI passou (✅ verde)

### Standards
- [ ] Código segue nomenclature standards
- [ ] Documentação atualizada (se necessário)
- [ ] Sem console.log ou código de debug

### Database (se aplicável)
- [ ] Migration criada (EF Core)
- [ ] Migration testada localmente
- [ ] DBA review (se schema change)

### Security (se aplicável)
- [ ] Sem secrets hardcoded
- [ ] Input validation implementada
- [ ] Authorization checks implementadas

## 🚫 Não Fazer Merge Se:
- ❌ CI falhando (Actions com ❌ vermelho)
- ❌ Merge conflicts não resolvidos
- ❌ Sem code review (mínimo 1 pessoa)
- ❌ Testes não passando

## 📝 Descrição
[Descrever mudanças...]

## 🎯 Issue Relacionada
Closes #[número]
```

---

## 📋 Workflow Recomendado (GitHub Free)

### Discovery Phase

1. **GM cria setup inicial:**
   ```bash
   # Labels, milestones, templates
   gh label create "epic:user-auth" -c "FEF2C0"
   gh milestone create "Epic 1: User Authentication"

   # CI/CD pipelines
   # .github/workflows/ci.yml
   # .github/workflows/cd-staging.yml
   ```

2. **Developer configura Git hooks locais:**
   ```bash
   # Cada dev executa:
   chmod +x .git/hooks/pre-push
   # Testa: git checkout main && git push origin main (deve bloquear)
   ```

### Per Epic (Iteration)

1. **DE cria DE-01 (Day 1-2)**
   ```bash
   git checkout develop
   git checkout -b feature/epic-1-user-auth
   # Trabalha no DE-01
   git add .
   git commit -m "feat(de): add user authentication domain model"
   git push origin feature/epic-1-user-auth
   ```

2. **GM cria issue (Day 2)**
   ```bash
   gh issue create \
     --title "Epic 1: User Authentication" \
     --label "epic:user-auth,priority:high" \
     --milestone "Epic 1: User Authentication" \
     --body "$(cat epic-1-description.md)"
   ```

3. **SE implementa backend (Day 3-6)**
   ```bash
   git checkout feature/epic-1-user-auth
   git checkout -b feature/se-auth-aggregate
   # Implementa código
   git add .
   git commit -m "feat(backend): implement user authentication aggregate"
   git push origin feature/se-auth-aggregate

   # Cria PR
   gh pr create \
     --base feature/epic-1-user-auth \
     --head feature/se-auth-aggregate \
     --title "feat(backend): implement user authentication"
   ```

4. **Code Review + Merge**
   ```bash
   # Reviewer verifica:
   # - ✅ CI passou (Actions verde)
   # - ✅ Testes passando
   # - ✅ Código OK
   # - ✅ Checklist do PR completo

   # Merge via GitHub UI ou:
   gh pr merge feature/se-auth-aggregate --merge
   ```

5. **QAE Quality Gate (Day 10)**
   ```bash
   # Se testes passam:
   gh pr create \
     --base develop \
     --head feature/epic-1-user-auth \
     --title "Epic 1: User Authentication - Ready for Staging"

   # Após review + CI passar:
   gh pr merge --merge

   # Deploy staging
   git checkout develop
   git pull
   ./deploy.sh staging
   ```

---

## 💰 Quando Considerar GitHub Pro?

**GitHub Pro:** $4/usuário/mês

**Vale a pena se:**
- [ ] Time com 3+ desenvolvedores
- [ ] Necessidade de branch protection automática
- [ ] Necessidade de required reviewers (compliance)
- [ ] Necessidade de CODEOWNERS (auto-assign reviewers)
- [ ] Projeto crítico (produção com >1000 usuários)

**NÃO vale a pena se:**
- [ ] Projeto solo ou dupla
- [ ] Projeto em fase MVP/protótipo
- [ ] Time disciplinado com PR workflow
- [ ] Baixo volume de commits (< 10/semana)

---

## ✅ Checklist Final (GitHub Free Setup)

### Setup Inicial
- [ ] Labels criados (epic, agent, type, priority, status)
- [ ] Milestones criados (Discovery + Epics)
- [ ] Templates criados (issue, PR)
- [ ] CI/CD pipelines criados (.github/workflows/ci.yml)
- [ ] Dependabot configurado (.github/dependabot.yml)
- [ ] CodeQL configurado (.github/workflows/security.yml)
- [ ] Branch naming convention documentada (README.md ou CONTRIBUTING.md)
- [ ] Git hooks exemplo fornecido (docs/git-hooks-setup.md)

### Developer Onboarding
- [ ] Developer leu workflow documentation
- [ ] Developer configurou Git hooks locais
- [ ] Developer testou bloqueio de push para main (deve falhar)
- [ ] Developer criou primeiro PR de teste
- [ ] Developer verificou CI status no PR

### Processo Contínuo
- [ ] Todo código passa por PR (NUNCA push direto para main/develop)
- [ ] CI status respeitado (❌ vermelho = NÃO fazer merge)
- [ ] Code review solicitado (mínimo 1 pessoa)
- [ ] PR checklist preenchido antes de merge
- [ ] Branches deletados após merge (cleanup)

---

## 📚 Referências

- **GM Template:** `.agents/templates/06-github-management/GM-00-GitHub-Setup.template.md`
- **GM Agent XML:** `.agents/25-GM - GitHub Manager.xml`
- **Workflow Guide:** `.agents/00-Workflow-Guide.md`
- **GitHub Free vs Pro:** https://docs.github.com/en/get-started/learning-about-github/githubs-plans
- **Git Hooks Documentation:** https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks

---

**Status:** Documentado para uso com GitHub Free
**Última Atualização:** 2025-10-08
**Workflow Version:** 3.0
