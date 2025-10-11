# GitHub Actions - DDD Workflow

Este diretório contém GitHub Actions para automatizar tarefas do DDD Workflow.

---

## 🤖 Setup New Project

**Arquivo:** [`setup-new-project.yml`](setup-new-project.yml)

**Propósito:** Automatizar o setup completo de um novo projeto usando este workflow como template.

### Como Usar

#### **Opção 1: Via GitHub Actions UI (Recomendado)**

1. **Pré-requisito:** Criar repositório vazio no GitHub
   - Acesse https://github.com/new
   - Nome: `nome-do-seu-projeto`
   - **NÃO** inicialize com README, .gitignore ou LICENSE
   - Copie a URL do repositório (ex: `https://github.com/seu-usuario/nome-do-seu-projeto.git`)

2. **Execute a Action:**
   - Acesse este repositório no GitHub
   - Vá para **Actions** → **Setup New Project**
   - Clique em **Run workflow**
   - Preencha os inputs:
     - **project_name:** Nome do projeto (ex: `SistemaVendas`)
     - **project_repo_url:** URL do repo criado no passo 1
     - **create_discovery_issue:** `true` (criar Issue #1 automaticamente)
   - Clique em **Run workflow**

3. **Aguarde a execução** (2-3 minutos)

4. **Verifique o resultado:**
   - Branch `main` com commit inicial
   - Branch `develop` criada
   - Issue #1 (Discovery Foundation) criada
   - Estrutura completa copiada

#### **Opção 2: Via GitHub CLI**

```bash
# Criar repositório vazio
gh repo create seu-usuario/nome-do-projeto --public --clone=false

# Executar workflow via CLI
gh workflow run setup-new-project.yml \
  --repo seu-usuario/myTraderGEO \
  -f project_name="SistemaVendas" \
  -f project_repo_url="https://github.com/seu-usuario/nome-do-projeto.git" \
  -f create_discovery_issue=true

# Monitorar execução
gh run watch
```

---

### O que a Action Faz

1. ✅ **Clone do workflow template**
   - Clona este repositório (myTraderGEO) como template

2. ✅ **Clone do novo projeto**
   - Clona o repositório destino (vazio ou com conteúdo mínimo)

3. ✅ **Copia estrutura completa**
   - `.agents/` - Agentes e templates
   - `00-doc-ddd/` - Estrutura de documentação
   - `.github/` - Templates de Issues/PRs
   - `workflow-config.json` - Configuração
   - Scripts de validação

4. ✅ **Customiza arquivos**
   - Substitui `myTraderGEO` pelo nome do novo projeto
   - Ajusta `workflow-config.json`

5. ✅ **Commit inicial na `main`**
   ```
   chore: Setup inicial do DDD Workflow v1.0
   ```

6. ✅ **Cria branch `develop`**
   ```
   chore: Início do Projeto
   ```

7. ✅ **Push para o remote**
   - Push de `main` e `develop`

8. ✅ **Cria Issue #1 (opcional)**
   - Issue "[EPIC-00] Discovery Foundation"
   - Labels: `epic`, `discovery`, `setup`, `priority-high`

---

### Inputs

| Input | Descrição | Obrigatório | Tipo | Padrão |
|-------|-----------|-------------|------|--------|
| `project_name` | Nome do novo projeto | ✅ Sim | string | - |
| `project_repo_url` | URL do repositório GitHub | ✅ Sim | string | - |
| `create_discovery_issue` | Criar Issue #1 automaticamente? | ❌ Não | boolean | `true` |

---

### Permissões Necessárias

A Action requer as seguintes permissões:

1. **GITHUB_TOKEN** com permissões de:
   - `repo` (full control)
   - `workflow` (para executar workflows)

2. **Para criar Issues:**
   - A Action usa `gh issue create` com `GITHUB_TOKEN`
   - Certifique-se de que o token tem permissão de escrita em Issues

#### Configurar Token (se necessário)

Se o `GITHUB_TOKEN` padrão não funcionar, crie um **Personal Access Token (PAT)**:

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Permissões:
   - ✅ `repo` (full control)
   - ✅ `workflow`
4. Copie o token
5. No repositório do workflow:
   - Settings → Secrets and variables → Actions
   - New repository secret
   - Name: `PAT_TOKEN`
   - Value: [cole o token]
6. Atualize o workflow para usar `${{ secrets.PAT_TOKEN }}` ao invés de `${{ secrets.GITHUB_TOKEN }}`

---

### Troubleshooting

#### Erro: "Permission denied"

**Causa:** Token sem permissões suficientes

**Solução:**
- Verifique permissões do `GITHUB_TOKEN`
- Ou use um PAT com permissões `repo` e `workflow`

---

#### Erro: "Repository not found"

**Causa:** URL do repositório incorreta ou repositório não existe

**Solução:**
- Verifique se o repositório foi criado no GitHub
- Confirme que a URL está correta (com `.git` no final)
- Exemplo correto: `https://github.com/usuario/projeto.git`

---

#### Erro: "gh: command not found"

**Causa:** GitHub CLI não está instalado no runner

**Solução:**
- A Action usa `ubuntu-latest` que já inclui `gh`
- Se estiver rodando localmente, instale: `https://cli.github.com/`

---

#### Issue #1 não foi criada

**Causa:** Permissões insuficientes ou `create_discovery_issue: false`

**Solução:**
1. Verifique se `create_discovery_issue: true` foi passado
2. Verifique permissões do token (deve ter acesso a Issues)
3. Crie a issue manualmente usando o template `.github/ISSUE_TEMPLATE/00-discovery-foundation.yml`

---

### Limitações

1. **Repositório destino deve estar vazio ou quase vazio**
   - A Action sobrescreve arquivos existentes
   - Se o repo já tem conteúdo, faça backup antes

2. **Não configura branch protection automaticamente**
   - GM (GitHub Manager) faz isso durante Discovery (Issue #1)

3. **Não configura CI/CD avançado**
   - GM configura durante Discovery

4. **Requer autenticação**
   - Action precisa de token com permissões adequadas

---

### Alternativa: Setup Manual

Se preferir não usar a Action, siga as instruções do [README.md principal](../../README.md):

1. Criar repositório no GitHub
2. Clonar localmente
3. Copiar estrutura manualmente
4. Commit inicial
5. Criar branch `develop`
6. Criar Issue #1 manualmente

---

### Próximas Melhorias

- [ ] Suporte para GitLab/Bitbucket
- [ ] Configurar branch protection rules automaticamente
- [ ] Gerar relatório de setup em Markdown
- [ ] Notificação via email/Slack após conclusão
- [ ] Validação automática de estrutura pós-setup

---

## 🤝 Contribuindo

Encontrou um bug ou tem sugestão de melhoria?

1. Abra uma Issue descrevendo o problema/sugestão
2. Ou envie um Pull Request com a correção/melhoria

---

**Versão:** 1.0
**Data:** 2025-10-11
