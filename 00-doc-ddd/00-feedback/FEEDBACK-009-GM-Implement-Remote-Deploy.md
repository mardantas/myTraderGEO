<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# FEEDBACK-009-GM-Implement-Remote-Deploy.md

> **Objetivo:** Implementar deploy remoto via SSH/SCP no deploy.sh para ambientes staging e production.

---

**Data Abertura:** 2025-10-28
**Solicitante:** User (Marco) + PE Agent
**Destinatário:** GM Agent (GitHub Manager)
**Status:** 🔴 Aberto

**Tipo:**
- [x] Implementação (nova feature)
- [ ] Correção (deliverable já entregue precisa ajuste)
- [ ] Dúvida (esclarecimento necessário)
- [ ] Novo Requisito (mudança de escopo)

**Urgência:** 🟡 Média

**Dependências:**
- FEEDBACK-008 (resolvido pelo PE) - Setup do servidor e convenções documentadas

**Deliverable(s) Afetado(s):**
- `05-infra/scripts/deploy.sh`
- `.github/workflows/cd-staging.yml` (opcional)
- `.github/workflows/cd-production.yml` (opcional)
- `GM-00-GitHub-Setup.md`
- `03-github-manager/README.md`

---

## 📋 Descrição

### Problema

O script de deploy atual (`05-infra/scripts/deploy.sh`) **apenas suporta deploy local** (development). Não há implementação de deploy remoto via SSH/SCP para os ambientes staging e production.

**Status atual:**
- ✅ Deploy local (development) - funcionando
- ❌ Deploy remoto (staging) - **NÃO IMPLEMENTADO**
- ❌ Deploy remoto (production) - **NÃO IMPLEMENTADO**

### Impacto

Sem deploy remoto implementado:
- ⚠️ Não é possível fazer deploy para servidores staging/production
- ⚠️ Desenvolvedor precisa fazer deploy manual via SSH
- ⚠️ Não há automation de deploy (CI/CD incompleto)
- ⚠️ Convenções documentadas pelo PE não estão sendo usadas

---

## 🔄 Contexto Completo

### O que o PE já fez (FEEDBACK-008)

O **PE Agent** documentou no **FEEDBACK-008** toda a infraestrutura necessária para deploy remoto:

#### ✅ Setup completo do servidor (PE-00 - Etapas 0-9):

**Hostnames padronizados:**
- Staging: `mytrader-stage`
- Production: `mytrader-prod`

**Infraestrutura base:**
- Debian 12 (Bookworm)
- Docker Engine 27.0+ + Compose Plugin v2.0+
- Firewall UFW (portas 22, 80, 443)
- Security hardening (fail2ban, SSH key-based auth, NTP)
- User `mytrader` com grupos corretos (mytrader + docker)
- Estrutura de diretórios: `/home/mytrader/mytrader-app/`

#### ✅ Exemplo de deploy remoto (FEEDBACK-008 linhas 377-418):

O PE deixou um **exemplo completo** de como o deploy.sh deve ser expandido:

```bash
#!/bin/bash
ENV=$1  # staging ou production

SERVER_USER="mytrader"
APP_DIR="mytrader-app/app"  # <-- Path padronizado

# Definir hostname conforme ambiente
if [ "$ENV" == "staging" ]; then
  SERVER_HOST="mytrader-stage"
elif [ "$ENV" == "production" ]; then
  SERVER_HOST="mytrader-prod"
else
  echo "Ambiente inválido: $ENV"
  exit 1
fi

# Copiar arquivos
scp 05-infra/docker/docker-compose.$ENV.yml \
    $SERVER_USER@$SERVER_HOST:~/$APP_DIR/docker-compose.yml

scp 05-infra/configs/traefik.yml \
    $SERVER_USER@$SERVER_HOST:~/$APP_DIR/configs/traefik.yml

# Deploy
ssh $SERVER_USER@$SERVER_HOST << EOF
  cd ~/$APP_DIR
  docker compose pull
  docker compose up -d
  docker compose ps
EOF
```

#### ✅ Mapeamento repositório → servidor (FEEDBACK-008 linhas 165-171):

| Arquivo no Repositório Git | Destino no Servidor | Como |
|----------------------------|---------------------|------|
| `05-infra/docker/docker-compose.staging.yml` | `/home/mytrader/mytrader-app/app/docker-compose.yml` | `deploy.sh` (scp) |
| `05-infra/docker/docker-compose.production.yml` | `/home/mytrader/mytrader-app/app/docker-compose.yml` | `deploy.sh` (scp) |
| `05-infra/configs/traefik.yml` | `/home/mytrader/mytrader-app/app/configs/traefik.yml` | `deploy.sh` (scp) |
| `05-infra/configs/.env.example` | `/home/mytrader/mytrader-app/app/.env` | Manual (primeira vez) |

### O que está faltando (responsabilidade do GM)

❌ **05-infra/scripts/deploy.sh:**
- Não detecta se é deploy local vs remoto
- Não implementa função `deploy_remote()`
- Não usa SSH/SCP para copiar arquivos
- Não faz health checks remotos via HTTPS

❌ **CD Pipeline (opcional):**
- Não há workflow para auto-deploy em staging
- Não há workflow para deploy manual em production
- Não há configuração de GitHub Secrets (SSH keys)

❌ **Documentação GM:**
- GM-00 não documenta estratégia de deploy remoto
- README.md não lista comandos de deploy remoto
- Não há link para pré-requisitos (PE-00)

---

## 💡 Proposta de Solução

### 1. Expandir deploy.sh para suportar deploy remoto

#### A. Detectar tipo de deploy (local vs remoto)

```bash
main() {
    local environment=${1:-}
    local version=${2:-latest}

    # ... validações ...

    # Detectar tipo de deploy
    if [ "$environment" = "development" ]; then
        # Deploy local (já implementado)
        deploy_local "$environment" "$version"
    else
        # Deploy remoto (NOVO - a implementar)
        deploy_remote "$environment" "$version"
    fi
}
```

#### B. Implementar função `deploy_remote()`

```bash
deploy_remote() {
    local env=$1
    local version=$2

    log_info "========================================="
    log_info "myTraderGEO Remote Deployment"
    log_info "========================================="
    log_info "Environment: $env"
    log_info "Version: $version"
    log_info "========================================="

    # 1. Definir hostname conforme ambiente
    local SERVER_USER="mytrader"
    local APP_DIR="mytrader-app/app"
    local SERVER_HOST

    if [ "$env" = "staging" ]; then
        SERVER_HOST="mytrader-stage"
    elif [ "$env" = "production" ]; then
        SERVER_HOST="mytrader-prod"
    else
        log_error "Ambiente inválido: $env"
        exit 1
    fi

    log_info "Target server: $SERVER_USER@$SERVER_HOST"

    # 2. Verificar conectividade SSH
    check_ssh_connection "$SERVER_USER" "$SERVER_HOST"

    # 3. Backup remoto do banco (via SSH)
    remote_backup_database "$SERVER_USER" "$SERVER_HOST" "$APP_DIR" "$env"

    # 4. Copiar arquivos via SCP
    log_info "Copying files to remote server..."

    scp "$INFRA_DIR/docker/docker-compose.$env.yml" \
        "$SERVER_USER@$SERVER_HOST:~/$APP_DIR/docker-compose.yml" || exit 1

    scp "$INFRA_DIR/configs/traefik.yml" \
        "$SERVER_USER@$SERVER_HOST:~/$APP_DIR/configs/traefik.yml" || exit 1

    log_info "Files copied successfully"

    # 5. Deploy via SSH
    log_info "Deploying services on remote server..."

    ssh "$SERVER_USER@$SERVER_HOST" << EOF
        set -e
        cd ~/$APP_DIR

        # Pull images
        echo "[REMOTE] Pulling Docker images..."
        docker compose pull

        # Deploy services
        echo "[REMOTE] Starting services..."
        docker compose up -d --remove-orphans

        # Show status
        echo "[REMOTE] Services status:"
        docker compose ps
EOF

    if [ $? -ne 0 ]; then
        log_error "Remote deployment failed"
        exit 1
    fi

    log_info "Remote deployment completed"

    # 6. Health checks remotos via HTTPS
    remote_health_check "$env"

    # 7. Logging de deploy
    log_deployment_history "$env" "$version" "$SERVER_HOST"

    log_info "========================================="
    log_info "Deployment completed successfully!"
    log_info "========================================="

    if [ "$env" = "staging" ]; then
        log_info "Frontend: https://staging.mytrader.com"
        log_info "API: https://api.staging.mytrader.com"
        log_info "Traefik Dashboard: https://traefik.staging.mytrader.com"
    else
        log_info "Frontend: https://mytrader.com"
        log_info "API: https://api.mytrader.com"
        log_info "Traefik Dashboard: https://traefik.mytrader.com"
    fi

    log_info "========================================="
}
```

#### C. Funções auxiliares

```bash
check_ssh_connection() {
    local user=$1
    local host=$2

    log_info "Checking SSH connection to $user@$host..."

    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$user@$host" "echo 'SSH OK'" > /dev/null 2>&1; then
        log_error "Cannot connect to $user@$host via SSH"
        log_error "Prerequisites:"
        log_error "  1. Server prepared per PE-00 setup"
        log_error "  2. SSH keys configured"
        log_error "  3. Hostname $host resolving (DNS or /etc/hosts)"
        exit 1
    fi

    log_info "SSH connection OK"
}

remote_backup_database() {
    local user=$1
    local host=$2
    local app_dir=$3
    local env=$4

    log_info "Running remote database backup..."

    ssh "$user@$host" << EOF
        cd ~/$app_dir
        # TODO: Implementar backup via script (backup-database.sh)
        echo "[REMOTE] Database backup not implemented yet"
EOF
}

remote_health_check() {
    local env=$1
    local api_url

    if [ "$env" = "staging" ]; then
        api_url="https://api.staging.mytrader.com/health"
    else
        api_url="https://api.mytrader.com/health"
    fi

    log_info "Running remote health checks..."
    log_info "API URL: $api_url"

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -f -s -k "$api_url" > /dev/null 2>&1; then
            log_info "Remote API health check passed"
            return 0
        fi

        log_warn "API not ready yet (attempt $attempt/$max_attempts)..."
        sleep 5
        ((attempt++))
    done

    log_error "Remote API health check failed after $max_attempts attempts"
    return 1
}

log_deployment_history() {
    local env=$1
    local version=$2
    local host=$3
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Local log
    local log_dir="$INFRA_DIR/logs"
    mkdir -p "$log_dir"

    echo "[$timestamp] Deployed $env ($version) to $host - SUCCESS" >> "$log_dir/deploy-history.log"

    # Remote log (opcional)
    # ssh $SERVER_USER@$SERVER_HOST "echo '[$timestamp] Deployed $version - SUCCESS' >> ~/mytrader-app/logs/deploy-history.log"
}
```

---

### 2. CD Pipeline (Opcional mas recomendado)

#### Arquivo: `.github/workflows/cd-staging.yml`

```yaml
name: CD - Staging

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY_STAGING }}" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          echo "${{ secrets.SSH_KNOWN_HOSTS }}" > ~/.ssh/known_hosts

      - name: Deploy to Staging
        run: |
          ./05-infra/scripts/deploy.sh staging latest

      - name: Notify success
        if: success()
        run: echo "Deployment to staging succeeded"

      - name: Notify failure
        if: failure()
        run: echo "Deployment to staging failed"
```

#### Arquivo: `.github/workflows/cd-production.yml`

```yaml
name: CD - Production

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy (e.g., v1.0.0)'
        required: true
        type: string

jobs:
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://mytrader.com

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY_PRODUCTION }}" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          echo "${{ secrets.SSH_KNOWN_HOSTS }}" > ~/.ssh/known_hosts

      - name: Deploy to Production
        run: |
          ./05-infra/scripts/deploy.sh production ${{ inputs.version }}

      - name: Notify success
        if: success()
        run: echo "Deployment to production succeeded"

      - name: Notify failure
        if: failure()
        run: echo "Deployment to production failed"
```

**GitHub Secrets necessários:**
- `SSH_PRIVATE_KEY_STAGING` - SSH private key para mytrader@mytrader-stage
- `SSH_PRIVATE_KEY_PRODUCTION` - SSH private key para mytrader@mytrader-prod
- `SSH_KNOWN_HOSTS` - Known hosts para evitar prompt SSH

---

### 3. Documentação GM-00

#### Adicionar seção "Deployment Strategy"

```markdown
## Deployment Strategy

### Overview

myTraderGEO usa diferentes estratégias de deploy conforme o ambiente:

| Environment | Method | Automation | Target |
|-------------|--------|------------|--------|
| **Development** | Local `docker compose` | Manual | Localhost |
| **Staging** | Remote SSH/SCP | Auto (CD pipeline) | mytrader-stage VPS |
| **Production** | Remote SSH/SCP | Manual approval | mytrader-prod VPS |

---

### Local Deployment (Development)

**Characteristics:**
- Runs directly on developer machine
- Uses `docker compose` without SSH/SCP
- Hot reload enabled (backend + frontend)
- No health checks via HTTPS

**Command:**
```bash
./05-infra/scripts/deploy.sh development
```

**Prerequisites:**
- Docker Desktop installed
- `.env` file configured locally

---

### Remote Deployment (Staging/Production)

**Characteristics:**
- Deploys to remote VPS via SSH/SCP
- Copies files from `05-infra/` to server
- Executes `docker compose` remotely
- Health checks via HTTPS

**Servers:**
- **Staging:** `mytrader-stage` (mytrader@mytrader-stage)
- **Production:** `mytrader-prod` (mytrader@mytrader-prod)

**Target directory:** `/home/mytrader/mytrader-app/app/`

**Commands:**
```bash
# Staging
./05-infra/scripts/deploy.sh staging latest

# Production
./05-infra/scripts/deploy.sh production v1.0.0
```

**Files copied:**
- `docker-compose.{env}.yml` → `docker-compose.yml`
- `traefik.yml` → `configs/traefik.yml`

**Remote execution:**
- `docker compose pull` (pull latest images)
- `docker compose up -d --remove-orphans` (start services)
- `docker compose ps` (show status)

**Health checks:**
- Staging: `https://api.staging.mytrader.com/health`
- Production: `https://api.mytrader.com/health`

---

### Prerequisites for Remote Deploy

**Server must be prepared per PE-00 setup:**

1. ✅ Hostname configured (`mytrader-stage` or `mytrader-prod`)
2. ✅ Docker Engine 27.0+ installed
3. ✅ Docker Compose Plugin v2.0+ installed
4. ✅ Firewall UFW active (ports 22, 80, 443)
5. ✅ User `mytrader` created with groups (mytrader + docker)
6. ✅ SSH keys configured (key-based auth)
7. ✅ Directory structure created (`/home/mytrader/mytrader-app/`)
8. ✅ `.env` file created with secrets (manual - first time)

**Detailed setup guide:** [PE-00 - Setup Inicial do Servidor](../08-platform-engineering/PE-00-Environments-Setup.md#-setup-inicial-do-servidor-infraestrutura-base)

---

### CD Pipeline (Optional - Implemented)

**Auto-deploy to Staging:**
- **Trigger:** Push to `main` branch
- **Workflow:** `.github/workflows/cd-staging.yml`
- **Target:** mytrader-stage VPS
- **Version:** `latest`

**Manual deploy to Production:**
- **Trigger:** Manual workflow dispatch
- **Workflow:** `.github/workflows/cd-production.yml`
- **Target:** mytrader-prod VPS
- **Version:** Input parameter (e.g., v1.0.0)
- **Approval:** Requires manual approval via GitHub UI

**Secrets management:**
- SSH private keys stored in GitHub Secrets
- `SSH_PRIVATE_KEY_STAGING` - Staging server
- `SSH_PRIVATE_KEY_PRODUCTION` - Production server
- `SSH_KNOWN_HOSTS` - Known hosts file

---

### Deployment Workflow

```
Developer
   ↓
Push to main
   ↓
GitHub Actions (CD - Staging)
   ↓
./deploy.sh staging latest
   ↓
   ├─→ SCP files to mytrader-stage
   ├─→ SSH: docker compose pull
   ├─→ SSH: docker compose up -d
   └─→ Health check via HTTPS
   ↓
Staging deployed ✅

---

Manual workflow dispatch (Production)
   ↓
Approval required
   ↓
./deploy.sh production v1.0.0
   ↓
   ├─→ SCP files to mytrader-prod
   ├─→ SSH: docker compose pull
   ├─→ SSH: docker compose up -d
   └─→ Health check via HTTPS
   ↓
Production deployed ✅
```

---

### Troubleshooting

**SSH connection failed:**
```bash
# Test SSH connection
ssh mytrader@mytrader-stage "echo 'SSH OK'"

# Check SSH keys
ls -la ~/.ssh/
cat ~/.ssh/id_ed25519.pub

# Check server setup
# Follow PE-00 setup guide
```

**Health check timeout:**
```bash
# Check if Traefik is running
ssh mytrader@mytrader-stage "docker ps | grep traefik"

# Check Traefik logs
ssh mytrader@mytrader-stage "docker logs mytrader-traefik"

# Check Let's Encrypt certificate
ssh mytrader@mytrader-stage "docker exec mytrader-traefik cat /letsencrypt/acme.json"
```

**SCP failed:**
```bash
# Check target directory exists
ssh mytrader@mytrader-stage "ls -la ~/mytrader-app/app/"

# Check permissions
ssh mytrader@mytrader-stage "ls -la ~/mytrader-app/"
# Should show: drwxr-xr-x mytrader mytrader
```
```

---

### 4. Documentação README.md

#### Adicionar seção "Deployment"

```markdown
## Deployment

### Local (Development)

Deploy local com hot reload:

```bash
./05-infra/scripts/deploy.sh development
```

Acesso:
- Frontend: http://localhost:5173
- API: http://localhost:5000
- Database: localhost:5432

---

### Remote (Staging)

Deploy para servidor de staging:

```bash
./05-infra/scripts/deploy.sh staging latest
```

Acesso:
- Frontend: https://staging.mytrader.com
- API: https://api.staging.mytrader.com
- Traefik: https://traefik.staging.mytrader.com

**Requer:** Servidor preparado conforme [PE-00 - Setup Inicial do Servidor](link)

---

### Remote (Production)

Deploy para servidor de production:

```bash
./05-infra/scripts/deploy.sh production v1.0.0
```

Acesso:
- Frontend: https://mytrader.com
- API: https://api.mytrader.com
- Traefik: https://traefik.mytrader.com

**Requer:**
- Servidor preparado conforme [PE-00 - Setup Inicial do Servidor](link)
- Confirmação manual no prompt

---

### Prerequisites para Remote Deploy

Antes de fazer deploy remoto, o servidor precisa estar preparado:

1. ✅ Debian 12 instalado
2. ✅ Docker + Compose instalado
3. ✅ Firewall configurado (UFW)
4. ✅ User `mytrader` criado
5. ✅ SSH keys configurados
6. ✅ Estrutura de diretórios criada
7. ✅ `.env` criado com secrets

**Guia completo:** [PE-00 - Setup Inicial do Servidor](link)

---

### CD Pipeline (Auto-deploy)

**Staging:** Auto-deploy em push para `main`
- Workflow: `.github/workflows/cd-staging.yml`
- Target: mytrader-stage

**Production:** Manual workflow dispatch
- Workflow: `.github/workflows/cd-production.yml`
- Target: mytrader-prod
- Requer: Aprovação manual

**Detalhes:** Ver [GM-00 - Deployment Strategy](link)
```

---

## 🎯 Critérios de Aceitação

### Deploy Script (Obrigatório):
- [ ] `deploy.sh` detecta ambiente (development, staging, production)
- [ ] Chama `deploy_local()` para development (já implementado)
- [ ] Chama `deploy_remote()` para staging/production (NOVO)
- [ ] Usa hostnames `mytrader-stage` e `mytrader-prod`
- [ ] Copia arquivos para `/home/mytrader/mytrader-app/app/` via SCP
- [ ] Executa `docker compose pull && up -d` via SSH
- [ ] Verifica conectividade SSH antes de deploy
- [ ] Health checks remotos via HTTPS funcionando (retry logic)
- [ ] Logging de deploy implementado (local: `05-infra/logs/deploy-history.log`)
- [ ] Tratamento de erros (SSH falha, SCP falha, health check timeout)
- [ ] Confirmação obrigatória para production (prompt "yes/no")

### CD Pipeline (Opcional mas recomendado):
- [ ] Workflow `cd-staging.yml` criado (auto-deploy em push para main)
- [ ] Workflow `cd-production.yml` criado (manual dispatch com version input)
- [ ] GitHub Secrets configurados (SSH_PRIVATE_KEY_STAGING, SSH_PRIVATE_KEY_PRODUCTION, SSH_KNOWN_HOSTS)
- [ ] Environment `production` configurado no GitHub (manual approval)
- [ ] Documentado no GM-00 seção "CD Pipeline"

### Documentação (Obrigatório):
- [ ] GM-00 seção "Deployment Strategy" criada
- [ ] GM-00 seção "Prerequisites" com link para PE-00
- [ ] GM-00 seção "CD Pipeline" (se implementado)
- [ ] GM-00 seção "Troubleshooting" com comandos de debug
- [ ] README.md seção "Deployment" criada
- [ ] README.md lista comandos de deploy (development, staging, production)
- [ ] README.md link para PE-00 setup do servidor
- [ ] README.md link para GM-00 deployment strategy

### Validação (Teste real):
- [ ] Deploy local (development) continua funcionando
- [ ] Deploy remoto para staging funciona via SSH/SCP
- [ ] Health checks remotos passam (HTTPS)
- [ ] Deploy remoto para production funciona (com confirmação)
- [ ] Logging de deploy gera arquivo `deploy-history.log`

---

## 📝 Notas Adicionais

### Ordem de Implementação Recomendada

1. **Etapa 1:** Expandir `deploy.sh` com `deploy_remote()`
   - Implementar funções auxiliares (check_ssh, remote_health_check, etc)
   - Testar deploy manual: `./deploy.sh staging latest`

2. **Etapa 2:** Criar workflows CD (opcional)
   - Criar `.github/workflows/cd-staging.yml`
   - Criar `.github/workflows/cd-production.yml`
   - Configurar GitHub Secrets

3. **Etapa 3:** Documentar no GM-00
   - Seção "Deployment Strategy"
   - Seção "Prerequisites"
   - Seção "CD Pipeline" (se implementado)
   - Seção "Troubleshooting"

4. **Etapa 4:** Atualizar README.md
   - Seção "Deployment" com comandos
   - Links para PE-00 e GM-00

---

### Diferenças entre deploy.sh local e remoto

| Aspecto | Local (Development) | Remoto (Staging/Production) |
|---------|---------------------|----------------------------|
| **Execução** | `docker compose` direto | SSH + SCP |
| **Target** | localhost | mytrader-stage / mytrader-prod |
| **Files** | Usa arquivos locais | Copia via SCP |
| **Compose** | `docker-compose.yml` | `docker-compose.{env}.yml` |
| **Health checks** | http://localhost:5000 | https://{domain}/health |
| **Logging** | Console apenas | Console + `deploy-history.log` |
| **Backup** | Não faz | Deve fazer backup antes |
| **Confirmação** | Não requer | Production requer "yes" |

---

### Segurança

**SSH Keys:**
- Usar Ed25519 ou RSA 4096
- **NUNCA** versionar private keys no Git
- Armazenar em GitHub Secrets (CI/CD)
- Configurar `authorized_keys` no servidor

**Permissions:**
- User `mytrader` deve ter acesso Docker (grupo docker)
- `.env` no servidor deve ser `chmod 600` (read-only owner)
- Private keys locais devem ser `chmod 600`

**Best Practices:**
- Desabilitar password auth no SSH (apenas keys)
- Usar fail2ban para proteção SSH
- Firewall deve permitir apenas portas necessárias (22, 80, 443)
- Health checks com timeout (evitar hang infinito)

---

## 📚 Referências

### FEEDBACK-008 (PE Agent):
- **Linhas 377-418:** Exemplo completo de deploy remoto (base para implementação)
- **Linhas 75-98:** Lacunas identificadas (hostnames, paths, estrutura)
- **Linhas 165-171:** Mapeamento repositório → servidor
- **Seção "Setup Inicial do Servidor":** Pré-requisitos do servidor (Etapas 0-8)

### PE-00-Environments-Setup.md:
- **Seção "Setup Inicial do Servidor (Infraestrutura Base)":** Etapas 0-9 de preparação
- **Seção "Estrutura no Servidor Remoto":** Paths e ownership
- **Seção "Network Architecture & Deployment":** Hostnames e DNS

### GM Specification (.agents/25-GM - GitHub Manager.xml):
- **Linhas 177-183:** CD pipeline deliverable (opcional)
- **Linhas 69-79:** Responsabilidades do GM (incluem CI/CD)
- **Linhas 260-333:** Definition of Done

### Deploy.sh atual:
- **05-infra/scripts/deploy.sh:** Deploy local implementado (base para expansão)
- **Funções existentes:** `check_prerequisites()`, `load_env_file()`, `deploy_services()`, `health_check()`

---

## 📝 Histórico

| Data | Mudança | Autor |
|------|---------|-------|
| 2025-10-28 | Criado (derivado do FEEDBACK-008) | User (Marco) + PE Agent |
