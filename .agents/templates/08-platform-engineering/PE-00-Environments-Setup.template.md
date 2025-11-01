<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# PE-00 - Environments Setup

**Agent:** PE (Platform Engineer)
**Phase:** Discovery (1x)
**Scope:** Basic environments with Docker Compose and deploy scripts
**Version:** 1.0

---

## 📋 Metadata

- **Project Name:** [PROJECT_NAME]
- **Created:** [DATE]
- **PE Engineer:** [NAME]
- **Target:** [PROJECT_TARGET]
- **Approach:** Docker Compose + Scripts (NOT full IaC)
- **Complexity:** [COMPLEXITY_LEVEL]

---

## 🎯 Objetivo

Configurar ambientes básicos (dev, staging, production) com Docker Compose e scripts de deploy simples para [PROJECT_NAME].

**Filosofia:** Pragmatic infrastructure - essencial para começar desenvolvimento rapidamente e deploy incremental por épico.

---

## 📊 Stack Tecnológico Definido

### Backend: [BACKEND_STACK]

**Justificativa:**
- [BENEFIT_1]
- [BENEFIT_2]
- [BENEFIT_3]
- [BENEFIT_N]

**Decisões Técnicas:**
- **Runtime:** [RUNTIME_VERSION]
- **Web Framework:** [FRAMEWORK]
- **ORM:** [ORM_CHOICE]
- **Real-time:** [REAL_TIME_TECH]
- **Logging:** [LOGGING_LIBRARY]
- **Testing:** [TEST_FRAMEWORKS]

---

### Frontend: [FRONTEND_STACK]

**Justificativa:**
- [BENEFIT_1]
- [BENEFIT_2]
- [BENEFIT_3]
- [BENEFIT_N]

**Decisões Técnicas:**
- **Framework:** [FRAMEWORK_VERSION]
- **Build Tool:** [BUILD_TOOL]
- **Language:** [LANGUAGE]
- **State Management:** [STATE_MGMT]
- **Router:** [ROUTER]
- **HTTP Client:** [HTTP_CLIENT]
- **Real-time:** [REAL_TIME_CLIENT]
- **UI Components:** [UI_LIBRARY]
- **Testing:** [TEST_FRAMEWORKS]

---

### Database: [DATABASE_CHOICE]

**Justificativa:**
- [BENEFIT_1]
- [BENEFIT_2]
- [BENEFIT_3]
- [BENEFIT_N]

**Decisões Técnicas:**
- **Versão:** [VERSION]
- **Connection Pooling:** [POOLING_STRATEGY]
- **Backup Strategy:** [BACKUP_APPROACH]
- **Migrations:** [MIGRATION_TOOL]

---

## 🏗️ Environments Overview

### Environment Strategy

| Environment | Purpose | Infrastructure | Deploy Method | Database |
|-------------|---------|----------------|---------------|----------|
| **Development** | Local development | Docker Compose (localhost) | `docker compose up` | [DATABASE] container |
| **Staging** | Pre-production testing | VPS / Cloud | `./deploy.sh staging` | [DATABASE] container |
| **Production** | Live users | VPS / Cloud | `./deploy.sh production` | [DATABASE] container* |

> \*[DATABASE] roda em container via Docker Compose para MVP. Migrar para managed database quando escalar (conforme seção "Estratégia de Escalabilidade").

### Hosting Strategy

**Selected Approach:** [HOSTING_APPROACH]

**Justificativa:**
- [REASON_1]
- [REASON_2]
- [REASON_3]
- [MIGRATION_PATH]

**Providers Recomendados:**
- [PROVIDER_1] - [REGION] - [PRICE]
- [PROVIDER_2] - [PRICE]
- [PROVIDER_3] - [REGION] - [PRICE]
- [PROVIDER_4] - [PRICE]

---

## 🌐 Network Architecture & Deployment

### Isolated Environments: Separate Servers

**Staging and Production run on SEPARATE servers/IPs:**

```
┌─────────────────────────────────────┐
│   Staging Server (IP: [STAGING_IP]) │
├─────────────────────────────────────┤
│ • staging.[DOMAIN]                   │ → Frontend
│ • api.staging.[DOMAIN]               │ → Backend API
│ • traefik.staging.[DOMAIN]           │ → Traefik Dashboard
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Production Server (IP: [PROD_IP])   │
├─────────────────────────────────────┤
│ • [DOMAIN]                            │ → Frontend
│ • api.[DOMAIN]                        │ → Backend API
│ • traefik.[DOMAIN]                    │ → Traefik Dashboard
└─────────────────────────────────────┘
```

### DNS Configuration Required

Point each subdomain to its respective server IP:

**Staging (IP: [STAGING_IP]):**
```
staging.[DOMAIN]          A    [STAGING_IP]
api.staging.[DOMAIN]      A    [STAGING_IP]
traefik.staging.[DOMAIN]  A    [STAGING_IP]
```

**Production (IP: [PROD_IP]):**
```
[DOMAIN]                  A    [PROD_IP]
www.[DOMAIN]              A    [PROD_IP]
api.[DOMAIN]              A    [PROD_IP]
traefik.[DOMAIN]          A    [PROD_IP]
```

### Why Separate Servers?

- ✅ **Isolation:** Staging issues don't affect production
- ✅ **Security:** Breach containment
- ✅ **Performance:** Dedicated resources per environment
- ✅ **Compliance:** Separate audit trails and access control
- ✅ **Testing:** Can test deploy process without risk

### Infrastructure Options

**Option 1: Separate VPS (Recommended)**
- Staging: Small VPS ($5-10/month)
- Production: Robust VPS ($20-40/month)
- Total: ~$30/month for complete isolation

**Option 2: Cloudflare + Private IPs**
- Single public IP via Cloudflare Tunnel
- Internal routing to separate staging/production VMs
- DDoS protection + SSL management included
- See Cloudflare Tunnel docs for setup

**NOT Recommended: Single Server**
- Sharing ports (staging:8443, prod:443) is complex
- Risk of staging compromising production
- Not suitable for production applications

---

## 🏗️ Infraestrutura Física

**Todos os arquivos de configuração e scripts estão implementados em:** `05-infra/`

### Estrutura de Arquivos

```
05-infra/
├── docker/
│   ├── docker-compose.yml            # Development
│   ├── docker-compose.staging.yml    # Staging + Traefik
│   └── docker-compose.production.yml # Production + Traefik + Resource Limits
├── dockerfiles/
│   ├── backend/
│   │   ├── Dockerfile                # Production (multi-stage)
│   │   └── Dockerfile.dev            # Development (hot reload)
│   └── frontend/
│       ├── Dockerfile                # Production (build + Nginx)
│       ├── Dockerfile.dev            # Development (dev server)
│       └── nginx.conf                # SPA routing + security headers
├── configs/
│   ├── traefik.yml                   # Traefik static configuration
│   └── .env.example                  # Environment variables template
├── scripts/
│   ├── deploy.sh                     # Deployment automation
│   ├── backup-database.sh            # Database backup
│   └── restore-database.sh           # Database restore
└── README.md                         # Infrastructure guide
```

### Arquivos de Configuração

| Arquivo | Descrição | Documentação |
|---------|-----------|--------------|
| `05-infra/docker/docker-compose.yml` | Ambiente local (dev) com hot reload | Ver arquivo |
| `05-infra/docker/docker-compose.staging.yml` | Staging com Traefik + Let's Encrypt | Ver arquivo |
| `05-infra/docker/docker-compose.production.yml` | Production com resource limits + Traefik | Ver arquivo |
| `05-infra/configs/traefik.yml` | Reverse proxy + SSL automático | Ver arquivo |
| `05-infra/configs/.env.example` | Template de variáveis de ambiente | Ver arquivo |
| `05-infra/scripts/deploy.sh` | Script de deployment bash | Ver arquivo |
| `05-infra/README.md` | 📖 **Guia completo de uso** | Ver arquivo |

**📖 Para detalhes completos de configuração, consulte:** `05-infra/README.md`

---

## 🖥️ Setup Inicial do Servidor (Infraestrutura Base)

**Aplicável a:** Staging (`[project]-stage`) e Production (`[project]-prod`)
**Provider:** [VPS_PROVIDER]
**OS Required:** [OS_DISTRO] - clean install

Esta seção documenta o **setup completo do servidor do zero**, desde a instalação do sistema operacional até o servidor pronto para receber deploy. As instruções são genéricas para qualquer VPS.

---

### Pré-requisitos

- **VPS provisionado** com [OS_DISTRO] instalado
- **Acesso root via SSH** (usuário root ou usuário com sudo)
- **IP público fixo** atribuído ao servidor
- **Domínio configurado** (DNS A records apontando para o IP do servidor)

**Servidores:**
- **Staging:** Hostname `[project]-stage` (ex: IP [STAGING_IP])
- **Production:** Hostname `[project]-prod` (ex: IP [PROD_IP])

---

### Etapa 0: Configuração do Hostname

```bash
# ===== EXECUTAR NO SERVIDOR VIA SSH (root ou sudo) =====

# Definir hostname conforme ambiente
# Para staging:
sudo hostnamectl set-hostname [project]-stage

# OU para production:
sudo hostnamectl set-hostname [project]-prod

# Verificar hostname configurado
hostnamectl
# Espera-se:
#   Static hostname: [project]-stage (ou [project]-prod)
#   Icon name: computer-vm
#   Chassis: vm
#   Operating System: [OS_DISTRO]

# Adicionar hostname ao /etc/hosts (opcional mas recomendado)
echo "127.0.1.1 $(hostname)" | sudo tee -a /etc/hosts
```

---

### Etapa 1: Atualização do Sistema

```bash
# Atualizar lista de pacotes
sudo apt-get update

# Atualizar todos os pacotes instalados
sudo apt-get upgrade -y

# Instalar ferramentas básicas
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  wget \
  vim \
  git \
  tree \
  htop
```

---

### Etapa 2: Instalação Docker Engine

**Fonte oficial:** [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)

```bash
# Remover versões antigas (se existirem)
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# Adicionar Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/[os]/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Adicionar repositório Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/[os] \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Atualizar índice de pacotes
sudo apt-get update

# Instalar Docker Engine + Docker Compose Plugin
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Verificar instalação
sudo docker --version
sudo docker compose version

# Testar Docker (opcional)
sudo docker run hello-world
```

---

### Etapa 3: Configurar Firewall (UFW)

```bash
# Instalar UFW (Uncomplicated Firewall)
sudo apt-get install -y ufw

# Configurar regras padrão
sudo ufw default deny incoming   # Bloquear tudo por padrão
sudo ufw default allow outgoing  # Permitir saída

# Permitir portas necessárias
sudo ufw allow 22/tcp     # SSH (IMPORTANTE: testar antes de habilitar!)
sudo ufw allow 80/tcp     # HTTP (Traefik - redirect para HTTPS)
sudo ufw allow 443/tcp    # HTTPS (Traefik - aplicação)

# ⚠️ CUIDADO: Antes de habilitar, TESTAR SSH em outra janela
# Abrir nova janela SSH e verificar que consegue conectar

# Habilitar firewall
sudo ufw --force enable

# Verificar status
sudo ufw status verbose
```

**⚠️ IMPORTANTE:** Sempre manter uma sessão SSH aberta enquanto configura o firewall. Se houver erro na configuração e você perder acesso, precisará usar console do provedor.

---

### Etapa 4: Security Hardening

```bash
# Instalar fail2ban (proteção contra brute-force SSH)
sudo apt-get install -y fail2ban

# Habilitar e iniciar fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Verificar status
sudo fail2ban-client status

# Instalar ferramentas necessárias
sudo apt-get install -y apache2-utils  # htpasswd (Traefik dashboard auth)
sudo apt-get install -y chrony          # NTP client (sincronização de tempo)

# Verificar htpasswd instalado
htpasswd -v

# Configurar timezone
sudo timedatectl set-timezone [TIMEZONE]

# Verificar timezone
timedatectl

# Verificar sincronização NTP
systemctl status chrony
```

**Opcional - SSH Hardening (Recomendado para Production):**

```bash
# Backup do arquivo de configuração SSH
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Editar configuração SSH (após configurar SSH keys)
sudo nano /etc/ssh/sshd_config

# Adicionar/alterar estas linhas:
# PermitRootLogin no                # Desabilitar login root
# PasswordAuthentication no         # Desabilitar password auth (apenas keys)
# PubkeyAuthentication yes          # Habilitar key-based auth

# Reiniciar SSH (CUIDADO: apenas após configurar SSH keys!)
# sudo systemctl restart sshd
```

---

### Etapa 5: Criar Grupo e User

```bash
# Criar grupo [project]
sudo groupadd [project]

# Criar user [project]_app com:
# - Grupo primário: [project]
# - Grupo secundário: docker (para rodar Docker sem sudo)
# - Shell: bash
# - Home directory: /home/[project]_app
sudo useradd -m -s /bin/bash -g [project] -G docker [project]_app

# Definir senha forte para o usuário
sudo passwd [project]_app

# Verificar grupos do user
id [project]_app

# Verificar que user pode executar Docker sem sudo
sudo su - [project]_app
docker --version
docker ps
exit
```

---

### Etapa 6: Configurar SSH Key (Deploy Automatizado)

```bash
# Trocar para user [project]_app
sudo su - [project]_app

# Criar diretório SSH
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Opção B: Adicionar public key existente (RECOMENDADO)
# Copiar public key do CI/CD ou dev machine e colar abaixo:
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample... deploy@[project]" >> ~/.ssh/authorized_keys

# Proteger arquivo authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Verificar conteúdo
cat ~/.ssh/authorized_keys

# Sair do user
exit
```

**Testar SSH key-based auth (de outra máquina):**

```bash
# Na máquina de deploy (dev ou CI/CD):
ssh -i ~/.ssh/id_ed25519 [project]_app@[project]-stage
# Deve conectar SEM pedir senha
```

---

### Etapa 7: Criar Estrutura de Diretórios

```bash
# Trocar para user [project]_app
sudo su - [project]_app

# Criar estrutura de diretórios do projeto
mkdir -p ~/[project]-app/app/configs
mkdir -p ~/[project]-app/backups/[database]
mkdir -p ~/[project]-app/scripts
mkdir -p ~/[project]-app/logs

# Verificar estrutura criada
tree ~/[project]-app/ -L 3

# Sair do user
exit
```

---

### Etapa 8: Criar .env Inicial

```bash
# Trocar para user [project]_app
sudo su - [project]_app

# Criar .env inicial (EDITAR COM SECRETS REAIS!)
cat > ~/[project]-app/app/.env << 'EOF'
# ===== [PROJECT_NAME] Environment Configuration =====
# ATENÇÃO: Este arquivo contém SECRETS - NUNCA versionar no Git!

# Environment: staging ou production
DOMAIN=staging.[DOMAIN]  # Ajustar: staging.[DOMAIN] OU [DOMAIN]
ACME_EMAIL=admin@[DOMAIN]

# Database (MUDAR SENHAS!)
DB_NAME=[project]
DB_USER=[project]_app
DB_PASSWORD=CHANGE_ME_STRONG_PASSWORD_HERE_32CHARS_MIN

# Traefik Dashboard (gerar com: htpasswd -nb admin password)
TRAEFIK_DASHBOARD_AUTH=admin:$apr1$xyz123...CHANGE_ME
EOF

# Proteger secrets (read-only apenas para owner)
chmod 600 ~/[project]-app/app/.env

# Verificar permissions
ls -la ~/[project]-app/app/.env

# Editar .env com secrets reais
nano ~/[project]-app/app/.env

# Sair do user
exit
```

**Gerar senha para Traefik Dashboard:**

```bash
# No servidor (ou localmente):
htpasswd -nb admin your_strong_password

# Exemplo de resultado:
# admin:$apr1$xyz123abc$AbCdEfGhIjKlMnOpQrStUv

# Copiar o resultado COMPLETO e adicionar ao .env
```

---

### Etapa 9: Verificação Final

```bash
# ===== Verificar Docker =====
sudo su - [project]_app
docker --version
docker compose version
docker ps  # Deve funcionar sem sudo
exit

# ===== Verificar estrutura de diretórios =====
sudo su - [project]_app
tree ~/[project]-app/ -L 2
ls -la ~/[project]-app/app/.env  # Deve existir com -rw-------
exit

# ===== Verificar hostname =====
hostnamectl

# ===== Verificar firewall =====
sudo ufw status verbose

# ===== Verificar fail2ban =====
sudo fail2ban-client status sshd

# ===== Verificar timezone =====
timedatectl

# ===== Verificar NTP =====
systemctl status chrony

# ===== Verificar user/grupos =====
id [project]_app
```

**Checklist Final:**

- [ ] Hostname configurado (`[project]-stage` ou `[project]-prod`)
- [ ] Docker instalado e funcionando
- [ ] Docker Compose Plugin instalado
- [ ] Firewall (UFW) ativo com portas 22, 80, 443 permitidas
- [ ] Fail2ban ativo e protegendo SSH
- [ ] User `[project]_app` criado com grupos corretos
- [ ] SSH key configurado para deploy automatizado
- [ ] Estrutura de diretórios criada em `/home/[project]_app/[project]-app/`
- [ ] Arquivo `.env` criado com secrets configurados
- [ ] Timezone configurado
- [ ] NTP sincronizando tempo

---

### Próximos Passos

Após completar este setup, o servidor está pronto para:

1. ✅ **Receber deploy via `deploy.sh`**
2. ✅ **Rodar containers Docker**
3. ✅ **Gerar certificados SSL** via Let's Encrypt (Traefik automático)
4. ✅ **Receber tráfego HTTPS** (porta 443)

**Para realizar o primeiro deploy:**

```bash
# Na máquina de desenvolvimento:
./05-infra/scripts/deploy.sh staging

# Ou para production:
./05-infra/scripts/deploy.sh production v1.0.0
```

---

### Estrutura no Servidor Remoto (Staging/Production)

**Convenção de Diretórios no VPS:**

Os arquivos de configuração e deploy ficam em um diretório dedicado no servidor remoto, separado do código-fonte e com ownership do user `[project]_app`.

```
/home/[project]_app/[project]-app/
├── app/                       # Deploy artifacts (docker-compose + configs)
│   ├── docker-compose.yml     # Copiado de 05-infra/docker/docker-compose.{env}.yml
│   ├── .env                   # Secrets (criado manualmente, NÃO versionado no Git)
│   └── configs/
│       └── traefik.yml        # Copiado de 05-infra/configs/traefik.yml
│
├── backups/                   # Database backups (gerados por scripts)
│   └── [database]/
│       ├── 2025-10-28.sql.gz
│       └── 2025-10-27.sql.gz
│
├── scripts/                   # Helper scripts (backup, restore, monitoring)
│   ├── backup-db.sh
│   ├── restore-db.sh
│   └── health-check.sh
│
└── logs/                      # Aggregated logs (opcional)
    ├── deploy-history.log
    └── app/
```

**Justificativa da Estrutura:**

- ✅ **User dedicado:** Isolamento de segurança (não root)
- ✅ **Ownership automático:** Tudo pertence ao user, sem necessidade de `sudo`
- ✅ **Pasta projeto:** Isola tudo do projeto em uma pasta
- ✅ **Subpasta `app/`:** Contém apenas arquivos de deploy
- ✅ **Escalável:** Permite adicionar outras apps no futuro
- ✅ **Named volumes:** Database data fica em Docker volumes gerenciados

**Mapeamento Repositório → Servidor:**

| Arquivo no Repositório Git | Destino no Servidor | Criado por |
|----------------------------|---------------------|------------|
| `05-infra/docker/docker-compose.staging.yml` | `/home/[project]_app/[project]-app/app/docker-compose.yml` | `deploy.sh` (scp) |
| `05-infra/docker/docker-compose.production.yml` | `/home/[project]_app/[project]-app/app/docker-compose.yml` | `deploy.sh` (scp) |
| `05-infra/configs/traefik.yml` | `/home/[project]_app/[project]-app/app/configs/traefik.yml` | `deploy.sh` (scp) |
| `05-infra/configs/.env.example` | `/home/[project]_app/[project]-app/app/.env` | **Manual** (primeira vez) |
| `05-infra/scripts/backup-database.sh` | `/home/[project]_app/[project]-app/scripts/backup-db.sh` | Manual ou `deploy.sh` |
| `05-infra/scripts/restore-database.sh` | `/home/[project]_app/[project]-app/scripts/restore-db.sh` | Manual ou `deploy.sh` |

**Named Volumes (Gerenciados pelo Docker):**

Os dados persistentes ficam em **Docker named volumes**, gerenciados automaticamente:

```bash
# Localização real no servidor:
/var/lib/docker/volumes/
├── [project]_[database]_data/    # Database files
├── [project]_letsencrypt/        # Traefik SSL certificates
└── [project]_logs/               # Application logs

# Comandos úteis:
docker volume ls                              # Listar todos os volumes
docker volume inspect [project]_[database]_data  # Ver path real e metadata
docker volume prune                           # Remover volumes não usados (CUIDADO!)
```

---

## 🚀 Quick Start

**Para instruções detalhadas de Getting Started, consulte:** `05-infra/README.md#quick-start`

### Desenvolvimento Local (Resumo)

```bash
# 1. Configurar environment
cp 05-infra/configs/.env.example 05-infra/configs/.env.dev

# 2. Iniciar serviços
docker compose -f 05-infra/docker/docker-compose.yml --env-file 05-infra/configs/.env.dev up -d

# 3. Verificar saúde
docker compose -f 05-infra/docker/docker-compose.yml --env-file 05-infra/configs/.env.dev ps
```

**Acessos:**
- Frontend: [FRONTEND_DEV_URL]
- Backend API: [BACKEND_DEV_URL]
- Database: localhost:[DB_PORT]

### Deploy para Staging/Production

```bash
# Deploy staging
./05-infra/scripts/deploy.sh staging

# Deploy production (com confirmação)
./05-infra/scripts/deploy.sh production v1.0.0
```

---

## 📊 Monitoring & Logging

**Para detalhes completos, consulte:** `05-infra/README.md#logging`

### Logging Strategy (Resumo)

| Environment | Level | Output | Retention |
|-------------|-------|--------|-----------|
| Development | Information | Console (stdout) | N/A |
| Staging | Information | Console + File | 3 files x 10MB |
| Production | Warning | Console + File | 5 files x 10MB |

### Health Checks

- **Backend:** `GET /health` → JSON status (database, services)
- **Frontend:** `GET /health` → "healthy"
- **Traefik:** Dashboard em `https://traefik.[DOMAIN]`

---

## 🔒 HTTPS & SSL

### Arquitetura de Rede (Production)

```
Internet
   ↓
Cloudflare (DNS + DDoS Protection + CDN)
   ↓ HTTPS (Full/Strict SSL mode)
VPS / Cloud Server
   ↓
Traefik v3.0 (Reverse Proxy + Let's Encrypt)
   ↓
   ├─→ Frontend Container
   ├─→ API Container
   └─→ Database Container (apenas rede interna)
```

### Traefik + Let's Encrypt (Automático)

**Implementado:** `05-infra/configs/traefik.yml` + Docker Compose labels

**Funcionalidades:**
- ✅ HTTP → HTTPS redirect automático
- ✅ Let's Encrypt SSL certificates (renovação automática)
- ✅ Service discovery via Docker labels
- ✅ Rate limiting configurado
- ✅ Dashboard protegido com Basic Auth
- ✅ WebSocket support

**Configuração Traefik:** `05-infra/configs/traefik.yml`

```yaml
# Entry Points
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true

  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt

# Let's Encrypt
certificatesResolvers:
  letsencrypt:
    acme:
      email: ${ACME_EMAIL}
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

**Docker Compose Labels (Production):**

```yaml
# API Service
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.api.rule=Host(`api.${DOMAIN}`)"
  - "traefik.http.routers.api.entrypoints=websecure"
  - "traefik.http.routers.api.tls.certresolver=letsencrypt"
  - "traefik.http.services.api.loadbalancer.server.port=8080"

# Frontend Service
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.frontend.rule=Host(`${DOMAIN}`)"
  - "traefik.http.routers.frontend.entrypoints=websecure"
  - "traefik.http.routers.frontend.tls.certresolver=letsencrypt"
  - "traefik.http.services.frontend.loadbalancer.server.port=80"
```

### Cloudflare Configuration

**DNS Records (apontar para IP do servidor):**

| Type | Name | Target | Proxy |
|------|------|--------|-------|
| A | @ | [PROD_IP] | ✅ Proxied |
| A | api | [PROD_IP] | ✅ Proxied |
| A | staging | [STAGING_IP] | ✅ Proxied |
| A | api.staging | [STAGING_IP] | ✅ Proxied |
| A | traefik | [PROD_IP] | ⚠️ DNS Only |

**SSL/TLS Settings:**
- **SSL Mode:** Full (Strict) ← IMPORTANTE
- **Always Use HTTPS:** Enabled
- **Minimum TLS Version:** 1.2
- **Opportunistic Encryption:** Enabled

**Firewall Rules (opcional):**
- Rate limiting adicional no Cloudflare
- Bot protection
- WAF rules

### Traefik Dashboard

**Acesso:** `https://traefik.[DOMAIN]`

**Autenticação:** Basic Auth (configurado via `.env`)

```bash
# Gerar senha para dashboard
htpasswd -nb admin your_password

# Resultado (adicionar ao .env):
TRAEFIK_DASHBOARD_AUTH=admin:$apr1$xyz...
```

**Ver serviços no dashboard:**
- HTTP Routers ativos
- Middlewares configurados
- Certificados SSL status
- Health checks

---

## 🪟 Desenvolvimento no Windows

### Pré-requisitos

- **Docker Desktop for Windows** (WSL2 backend enabled)
- **Git for Windows** (inclui Git Bash)
- **Windows 10/11** com WSL2 configurado

### Executar Scripts Bash

Todos os scripts (deploy, backup) usam Bash. No Windows, use uma destas opções:

**Opção 1: Git Bash (Recomendado)**
```bash
bash ./05-infra/scripts/deploy.sh staging
bash ./05-infra/scripts/backup-database.sh
```

**Opção 2: WSL2**
```bash
wsl bash ./05-infra/scripts/deploy.sh staging
```

### Named Volumes no Windows

Docker Desktop armazena named volumes no filesystem WSL2:
```
\\wsl$\docker-desktop-data\data\docker\volumes\
```

**Benefícios:**
- **Performance:** ~60x mais rápido que bind mounts para databases
- **Compatibilidade:** Funciona identicamente em Windows/Linux/Mac
- **Gestão automática:** Docker gerencia espaço e backups

**Quando usar bind mounts:**
- Apenas para código-fonte (hot reload)
- Não para databases (performance ruim)

### Troubleshooting Windows

**Problema: Performance lenta**
- **Solução:** Manter projeto dentro do filesystem WSL2
- **Alternativa:** Se precisar manter em `C:\`, usar named volumes para databases (já configurado)

**Problema: Scripts Bash não executam**
- **Verificar:** Docker Desktop → Settings → General → "Use the WSL 2 based engine"
- **Verificar:** Git Bash instalado (`git --version`)

---

## 🚀 Estratégia de Escalabilidade

### Abordagem Atual: Docker Compose Standalone

**Why Docker Compose for MVP?**

- ✅ **Simplicidade:** Comandos simples, debugging direto, logs centralizados
- ✅ **Custo:** Um único servidor por ambiente vs cluster
- ✅ **Desenvolvimento Rápido:** Deploy manual aceitável para MVP
- ✅ **Adequado para Scale Inicial:** Suporta até 10-50k usuários com escalabilidade vertical
- ✅ **Menor Complexidade Operacional:** Time pequeno consegue gerenciar
- ✅ **Pragmatismo:** Implementar HA/auto-scaling prematuramente é over-engineering

**Adequado para:**

- 👍 MVP e validação de mercado
- 👍 Até 10-50k usuários simultâneos
- 👍 SLA informal de 95-98%
- 👍 Orçamento limitado
- 👍 Time pequeno

**Limitações:**

- ⚠️ **Single-host:** Se servidor cai, aplicação fica indisponível
- ⚠️ **Escalabilidade Horizontal Limitada:** Difícil adicionar réplicas
- ⚠️ **Zero-downtime Deploy:** Difícil implementar
- ⚠️ **Auto-healing Básico:** Depende apenas de `restart: unless-stopped`
- ⚠️ **Load Balancing Manual:** Traefik faz LB no mesmo host

---

### Quando Migrar: Matriz de Decisão

**Migre para orquestração quando atingir QUALQUER um destes thresholds:**

| Metric | Docker Compose | Managed Cloud | Kubernetes |
|--------|----------------|---------------|------------|
| **Usuários Simultâneos** | <10k | 10k-50k | >50k |
| **SLA Target** | 95-98% | 99%+ | 99.9%+ |
| **Downtime Aceitável** | Alguns minutos | <5 min | <1 min |
| **Custo Mensal** | $30-60 | $100-300 | $500+ |
| **Team Size** | 1-3 pessoas | 3-5 pessoas | 5+ pessoas (com SRE) |
| **Revenue** | Pre-revenue/MVP | $10k-100k MRR | $100k+ MRR |
| **Deploy Frequency** | Semanal/Mensal | Diário | Múltiplos/dia |

**Sinais que é hora de migrar:**

- 🔴 **Downtime frequente** por saturação de recursos (CPU/RAM constantemente >80%)
- 🔴 **Reclamações de usuários** sobre indisponibilidade ou lentidão
- 🔴 **Crescimento rápido** (duplicação de usuários a cada 2-3 meses)
- 🔴 **Requisitos de SLA** contratuais (clientes enterprise exigem 99%+)
- 🔴 **Necessidade de multi-região** (latência para usuários geograficamente distribuídos)

**Princípio:** **Start simple, scale when needed** (não fazer over-engineering prematuro)

---

## ✅ PE Definition of Done Checklist

### Infrastructure
- [ ] Stack tecnológico definido
- [ ] Docker Compose criado para dev/staging/production
- [ ] Dockerfiles criados (backend dev/prod, frontend dev/prod)
- [ ] Database configurado
- [ ] Nginx configurado (frontend production)
- [ ] Traefik configurado (reverse proxy + SSL automático)

### Deployment
- [ ] Deploy script criado (`05-infra/scripts/deploy.sh`)
- [ ] Backup script documentado
- [ ] Restore script documentado
- [ ] `.env.example` criado com todas variáveis

### Networking & Security
- [ ] Traefik v3.0 integrado (production + staging)
- [ ] Let's Encrypt SSL automático configurado
- [ ] Cloudflare + Traefik architecture documentado
- [ ] Rate limiting configurado
- [ ] Dashboard protegido (Basic Auth)
- [ ] Secrets management configurado
- [ ] Health checks configurados

### Logging & Monitoring
- [ ] Logging básico documentado
- [ ] Health checks endpoints documentados
- [ ] Traefik logs configurados

### Documentation
- [ ] PE-00-Environments-Setup.md criado
- [ ] Deploy process documentado
- [ ] Traefik architecture documentado
- [ ] Cloudflare configuration documentado
- [ ] Getting started guide documentado
- [ ] Stack tecnológico justificado
- [ ] 05-infra/README.md criado

### Physical Files Created
- [ ] `05-infra/docker/docker-compose.yml`
- [ ] `05-infra/docker/docker-compose.staging.yml`
- [ ] `05-infra/docker/docker-compose.production.yml`
- [ ] `05-infra/dockerfiles/backend/Dockerfile.dev`
- [ ] `05-infra/dockerfiles/backend/Dockerfile`
- [ ] `05-infra/dockerfiles/frontend/Dockerfile.dev`
- [ ] `05-infra/dockerfiles/frontend/Dockerfile`
- [ ] `05-infra/dockerfiles/frontend/nginx.conf`
- [ ] `05-infra/configs/traefik.yml`
- [ ] `05-infra/configs/.env.example`
- [ ] `05-infra/scripts/deploy.sh`
- [ ] `05-infra/README.md`
- [ ] `.gitignore`

### Validation
- [ ] Outros agentes podem começar desenvolvimento (environments prontos)
- [ ] Deploy testado em staging
- [ ] Database connection testada
- [ ] Health checks funcionando
- [ ] Traefik SSL certificates gerados

---

## 🎯 Próximos Passos

**Agora que o stack está definido, os próximos agentes podem executar:**

1. ✅ **GM (GitHub Manager)** - Configurar CI/CD
2. ✅ **SEC (Security Specialist)** - Escolher ferramentas compatíveis
3. ✅ **QAE (Quality Assurance Engineer)** - Definir ferramentas de teste

---

**Template Version:** 1.0
**Last Updated:** [DATE]
