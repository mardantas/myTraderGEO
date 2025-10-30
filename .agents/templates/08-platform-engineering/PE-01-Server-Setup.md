<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# PE-01 - Server Setup & Remote Deployment

**Agent:** PE (Platform Engineer)
**Phase:** Discovery (1x)
**Scope:** Production-ready remote server configuration and deployment
**Version:** 4.0 (Split from PE-00-Environments-Setup)

---

## 📋 Metadata

- **Project Name:** [PROJECT_NAME]
- **Created:** [DATE]
- **PE Engineer:** [NAME]
- **Target:** Staging and production server setup
- **Security:** UFW, fail2ban, SSH key-based auth, NTP sync

---

## 🎯 Objetivo

Configure servidores remotos (staging/production) com segurança, deploy via SSH/SCP, e Traefik para SSL automático.

**Foundation:** Veja [PE-00-Quick-Start.md](./PE-00-Quick-Start.md) para setup local primeiro
**Future scaling:** Veja [PE-02-Scaling-Strategy.md](./PE-02-Scaling-Strategy.md) quando precisar escalar

---

## 🖥️ Server Setup Documentation

### Overview

**9-step process** para configurar servidores staging/production do zero.

**Target:** Linux server (Ubuntu 22.04 LTS or Debian 12)
**Time:** ~30 minutes per server
**Security:** UFW firewall, fail2ban, SSH key-based auth, NTP time sync

### Prerequisites

- ✅ Root or sudo access to server
- ✅ SSH access to server
- ✅ Domain DNS pointing to server IP (for Let's Encrypt SSL)
- ✅ SSH key pair generated (`ssh-keygen -t ed25519 -C "[PROJECT_NAME]-[environment]"`)

### Step 1: Set Hostname

```bash
# Staging server
sudo hostnamectl set-hostname [project]-stage

# Production server
sudo hostnamectl set-hostname [project]-prod

# Verify
hostnamectl
```

### Step 2: Install Docker Engine

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
docker compose version
```

### Step 3: Configure UFW Firewall

```bash
# Reset to defaults
sudo ufw --force reset

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH, HTTP, HTTPS
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP (redirect to HTTPS)
sudo ufw allow 443/tcp  # HTTPS

# Enable firewall
sudo ufw --force enable
sudo ufw status numbered
```

### Step 4: Install and Configure fail2ban

```bash
# Install fail2ban
sudo apt install fail2ban -y

# Configure SSH jail
sudo tee /etc/fail2ban/jail.d/sshd.conf <<EOF
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOF

# Restart fail2ban
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

### Step 5: Create Dedicated User and Group

```bash
# Create group and user (NOT root for least privilege)
sudo groupadd [project]_app
sudo useradd -m -s /bin/bash -g [project]_app -G docker [project]_app

# Set up SSH key for user
sudo mkdir -p /home/[project]_app/.ssh
sudo tee /home/[project]_app/.ssh/authorized_keys <<EOF
[PASTE YOUR PUBLIC SSH KEY HERE]
EOF
sudo chmod 700 /home/[project]_app/.ssh
sudo chmod 600 /home/[project]_app/.ssh/authorized_keys
sudo chown -R [project]_app:[project]_app /home/[project]_app/.ssh
```

### Step 6: Harden SSH (Key-Based Auth Only)

```bash
# Disable password authentication (key-based only)
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Verify configuration
sudo grep -E '^(PasswordAuthentication|PubkeyAuthentication)' /etc/ssh/sshd_config

# Restart SSH
sudo systemctl restart sshd
```

**⚠️ IMPORTANT:** Test SSH login with key BEFORE logging out of root session!

```bash
# From your local machine, test SSH login
ssh -i ~/.ssh/[project]_[environment]_ed25519 [project]_app@[SERVER_IP]
```

### Step 7: Install NTP Time Synchronization

```bash
# Install chrony (NTP client)
sudo apt install chrony -y

# Verify time sync
timedatectl status
```

**Why:** Accurate time is critical for audit logs (LGPD Art. 46, SOC2, ISO 27001), TLS certificates, database timestamps.

### Step 8: Create Project Directory Structure

```bash
# Switch to dedicated user
sudo su - [project]_app

# Create directory structure
mkdir -p ~/[project]/{configs,logs,backups}

# Clone repository (or SCP files from CI/CD)
cd ~/[project]
git clone https://github.com/[YOUR_ORG]/[project].git .

# Create .env files (DO NOT commit to Git!)
cp .env.example .env.staging   # For staging server
cp .env.example .env.production # For production server

# Edit .env with real secrets
nano .env.staging   # or .env.production
```

### Step 9: Verify Server Setup

```bash
# Verification checklist
echo "1. Hostname: $(hostname)"
echo "2. Docker: $(docker --version)"
echo "3. UFW: $(sudo ufw status | grep Status)"
echo "4. fail2ban: $(sudo systemctl is-active fail2ban)"
echo "5. User: $(id [project]_app)"
echo "6. SSH Key: $(test -f ~/.ssh/authorized_keys && echo 'OK' || echo 'MISSING')"
echo "7. NTP: $(timedatectl | grep 'synchronized' | awk '{print $4}')"
echo "8. Directory: $(test -d ~/[project] && echo 'OK' || echo 'MISSING')"
```

✅ **Server is now hardened and ready for deployment!**

---

## 🔀 Traefik Reverse Proxy (Staging + Production)

### Why Traefik?

**Traefik v3.0** is used in **staging and production** for:

1. **Automatic SSL (Let's Encrypt)** - HTTPS certificates automatically issued and renewed
2. **Declarative Routing** - Configuration via Docker labels (simple, no nginx.conf editing)
3. **Built-in Load Balancing** - Ready for horizontal scaling with multiple service replicas
4. **Dashboard** - Web UI for monitoring routes and services

**Not in development:** localhost needs no SSL or reverse proxy; see [PE-00-Quick-Start.md](./PE-00-Quick-Start.md).

### Traefik Configuration

**File:** `05-infra/configs/traefik.yml`

```yaml
api:
  dashboard: true
  insecure: false

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

certificatesResolvers:
  letsencrypt-staging:
    acme:
      email: ${LETSENCRYPT_EMAIL}
      storage: /letsencrypt/acme.json
      caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      httpChallenge:
        entryPoint: web

  letsencrypt:
    acme:
      email: ${LETSENCRYPT_EMAIL}
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web

providers:
  docker:
    exposedByDefault: false
```

### Docker Compose (Staging)

**File:** `docker-compose.staging.yml`

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v3.0
    command:
      - "--configFile=/etc/traefik/traefik.yml"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./05-infra/configs/traefik.yml:/etc/traefik/traefik.yml:ro
      - traefik-letsencrypt:/letsencrypt
    networks:
      - web
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`traefik-staging.${DOMAIN}`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt-staging"
      - "traefik.http.routers.traefik.service=api@internal"

  api:
    image: ${DOCKER_REGISTRY}/api:staging
    environment:
      - ASPNETCORE_ENVIRONMENT=Staging
      - DATABASE_URL=${DATABASE_URL_STAGING}
    networks:
      - web
      - backend
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api-staging.rule=Host(`api-staging.${DOMAIN}`)"
      - "traefik.http.routers.api-staging.entrypoints=websecure"
      - "traefik.http.routers.api-staging.tls.certresolver=letsencrypt-staging"
      - "traefik.http.services.api-staging.loadbalancer.server.port=5000"

  frontend:
    image: ${DOCKER_REGISTRY}/frontend:staging
    environment:
      - VITE_API_URL=https://api-staging.${DOMAIN}
    networks:
      - web
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend-staging.rule=Host(`staging.${DOMAIN}`)"
      - "traefik.http.routers.frontend-staging.entrypoints=websecure"
      - "traefik.http.routers.frontend-staging.tls.certresolver=letsencrypt-staging"

  database:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=${DB_NAME_STAGING}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_staging_data:/var/lib/postgresql/data
    networks:
      - backend
    restart: unless-stopped

networks:
  web:
  backend:

volumes:
  postgres_staging_data:
  traefik-letsencrypt:
```

### Docker Compose (Production)

**File:** `docker-compose.production.yml`

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v3.0
    command:
      - "--configFile=/etc/traefik/traefik.yml"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./05-infra/configs/traefik.yml:/etc/traefik/traefik.yml:ro
      - traefik-letsencrypt:/letsencrypt
    networks:
      - web
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`traefik.${DOMAIN}`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
      - "traefik.http.routers.traefik.middlewares=ipwhitelist"
      - "traefik.http.middlewares.ipwhitelist.ipwhitelist.sourcerange=${YOUR_IP_ADDRESS}/32"

  api:
    image: ${DOCKER_REGISTRY}/api:${VERSION}
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - DATABASE_URL=${DATABASE_URL_PROD}
      - JWT_SECRET=${JWT_SECRET_PROD}
    networks:
      - web
      - backend
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api-prod.rule=Host(`api.${DOMAIN}`)"
      - "traefik.http.routers.api-prod.entrypoints=websecure"
      - "traefik.http.routers.api-prod.tls.certresolver=letsencrypt"

  frontend:
    image: ${DOCKER_REGISTRY}/frontend:${VERSION}
    environment:
      - VITE_API_URL=https://api.${DOMAIN}
    networks:
      - web
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend-prod.rule=Host(`${DOMAIN}`)"
      - "traefik.http.routers.frontend-prod.entrypoints=websecure"
      - "traefik.http.routers.frontend-prod.tls.certresolver=letsencrypt"

  database:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=${DB_NAME_PROD}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_prod_data:/var/lib/postgresql/data
    networks:
      - backend
    restart: always

networks:
  web:
  backend:

volumes:
  postgres_prod_data:
  traefik-letsencrypt:
```

### Service Access

**Staging:**
- Frontend: https://staging.{DOMAIN}
- API: https://api-staging.{DOMAIN}
- Dashboard: https://traefik-staging.{DOMAIN}

**Production:**
- Frontend: https://{DOMAIN}
- API: https://api.{DOMAIN}
- Dashboard: https://traefik.{DOMAIN} (IP whitelist required)

### Troubleshooting

**SSL Certificate Not Issued:**
```bash
docker compose logs traefik
nslookup {DOMAIN}
curl -I http://{DOMAIN}
grep LETSENCRYPT_EMAIL .env.staging
```

**Service Not Accessible:**
```bash
docker compose exec traefik wget -O- http://localhost:8080/api/http/routers
docker compose config | grep -A 10 "labels:"
docker compose exec traefik ping api
```

---

## 📡 Remote Deployment Architecture

### Overview

Remote deployment uses SSH/SCP for file transfer and remote command execution to staging/production servers.

### Deployment Flow

```
Local Machine → check_ssh_connection() → Remote Server [project]-stage/prod
             → SCP files → SSH: docker compose up -d
             → remote_health_check() (HTTPS, 30 attempts × 5s)
             → log_deployment_history()
```

### deploy.sh - Remote Deployment

**Location:** Project root

```bash
#!/bin/bash

# deploy.sh - Remote deployment with SSH/SCP
# Usage: ./deploy.sh [staging|production] [version]

set -e

ENVIRONMENT=$1
VERSION=${2:-"latest"}
DEPLOY_LOG="deployments.log"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_ssh_connection() {
    local SERVER_HOST=$1
    local SSH_USER=$2
    echo -e "${YELLOW}🔑 Checking SSH connection to $SERVER_HOST...${NC}"
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$SSH_USER@$SERVER_HOST" "exit" 2>/dev/null; then
        echo -e "${GREEN}✅ SSH connection successful${NC}"
        return 0
    else
        echo -e "${RED}❌ SSH connection failed${NC}"
        return 1
    fi
}

remote_health_check() {
    local HEALTH_URL=$1
    local MAX_ATTEMPTS=30
    local SLEEP_INTERVAL=5

    echo -e "${YELLOW}🏥 Running health checks...${NC}"

    for ((i=1; i<=MAX_ATTEMPTS; i++)); do
        HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$HEALTH_URL" 2>/dev/null || echo "000")
        if [ "$HEALTH_STATUS" -eq 200 ]; then
            echo -e "${GREEN}✅ Health check passed after $i attempts${NC}"
            return 0
        else
            echo -e "${YELLOW}⏳ Attempt $i/$MAX_ATTEMPTS: HTTP $HEALTH_STATUS. Retrying in ${SLEEP_INTERVAL}s...${NC}"
            sleep "$SLEEP_INTERVAL"
        fi
    done

    echo -e "${RED}❌ Health check failed after $MAX_ATTEMPTS attempts${NC}"
    return 1
}

log_deployment_history() {
    local ENV=$1
    local VER=$2
    local STATUS=$3
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$TIMESTAMP | Environment: $ENV | Version: $VER | Status: $STATUS" >> "$DEPLOY_LOG"
}

deploy_remote() {
    local ENV=$1
    local VER=$2

    if [ "$ENV" = "staging" ]; then
        SERVER_HOST="[project]-stage"
    elif [ "$ENV" = "production" ]; then
        SERVER_HOST="[project]-prod"
    else
        echo -e "${RED}❌ Invalid environment: $ENV${NC}"
        exit 1
    fi

    SSH_USER="[project]_app"
    REMOTE_DIR="/home/$SSH_USER/[project]"

    echo -e "${GREEN}🚀 Starting REMOTE deployment to $ENV ($SERVER_HOST)...${NC}"

    if ! check_ssh_connection "$SERVER_HOST" "$SSH_USER"; then
        log_deployment_history "$ENV" "$VER" "FAILED_SSH"
        exit 1
    fi

    echo -e "${YELLOW}📦 Copying files to $SERVER_HOST...${NC}"
    scp "docker-compose.$ENV.yml" "$SSH_USER@$SERVER_HOST:$REMOTE_DIR/docker-compose.$ENV.yml"
    scp -r "05-infra/configs/" "$SSH_USER@$SERVER_HOST:$REMOTE_DIR/05-infra/"
    echo -e "${GREEN}✅ Files copied${NC}"

    echo -e "${YELLOW}🚢 Deploying containers...${NC}"
    ssh "$SSH_USER@$SERVER_HOST" << EOF
        cd "$REMOTE_DIR"
        docker compose -f docker-compose.$ENV.yml --env-file .env.$ENV down
        docker compose -f docker-compose.$ENV.yml --env-file .env.$ENV up -d
        echo "✅ Containers started"
EOF

    if [ "$ENV" = "staging" ]; then
        HEALTH_URL="https://api-staging.{DOMAIN}/health"
    elif [ "$ENV" = "production" ]; then
        HEALTH_URL="https://api.{DOMAIN}/health"
    fi

    if remote_health_check "$HEALTH_URL"; then
        log_deployment_history "$ENV" "$VER" "SUCCESS"
        echo -e "${GREEN}🎉 REMOTE deployment completed successfully!${NC}"
    else
        log_deployment_history "$ENV" "$VER" "FAILED_HEALTH_CHECK"
        echo -e "${RED}❌ Deployment failed health check${NC}"
        exit 1
    fi
}

deploy_remote "$ENVIRONMENT" "$VERSION"
```

**Usage:**
```bash
# Deploy to staging
bash deploy.sh staging

# Deploy to production with version tag
bash deploy.sh production v1.2.3
```

---

## ⏪ Rollback Strategy

### rollback.sh

**Location:** Project root

```bash
#!/bin/bash

# rollback.sh - Rollback to previous version
# Usage: ./rollback.sh [staging|production] [version]

set -e

ENVIRONMENT=$1
PREVIOUS_VERSION=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$PREVIOUS_VERSION" ]; then
  echo "Usage: ./rollback.sh [staging|production] [version]"
  exit 1
fi

echo "⏪ Rolling back $ENVIRONMENT to version $PREVIOUS_VERSION..."

# Load environment variables
export $(cat ".env.$ENVIRONMENT" | xargs)
export VERSION=$PREVIOUS_VERSION

# Deploy previous version
docker compose -f docker-compose.$ENVIRONMENT.yml --env-file .env.$ENVIRONMENT down
docker compose -f docker-compose.$ENVIRONMENT.yml --env-file .env.$ENVIRONMENT up -d

echo "✅ Rollback completed!"
```

**Usage:**
```bash
bash rollback.sh production v1.2.2
```

---

## 🔄 Backup Strategy

### Database Backup Script

**Location:** `scripts/backup-db.sh`

```bash
#!/bin/bash

# backup-db.sh - Simple database backup
# Usage: ./backup-db.sh [staging|production]

ENVIRONMENT=$1
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "💾 Backing up $ENVIRONMENT database..."

docker compose -f docker-compose.$ENVIRONMENT.yml exec -T database \
  pg_dump -U $DB_USER $DB_NAME > $BACKUP_DIR/${ENVIRONMENT}_${TIMESTAMP}.sql

echo "✅ Backup saved to $BACKUP_DIR/${ENVIRONMENT}_${TIMESTAMP}.sql"

# Keep only last 7 backups
ls -t $BACKUP_DIR/${ENVIRONMENT}_*.sql | tail -n +8 | xargs rm -f
```

### Backup Schedule

**Recommended:**
- **Staging:** Manual backups before major changes
- **Production:** Daily backups (cron job)

**Cron example (production):**
```cron
0 2 * * * /path/to/scripts/backup-db.sh production
```

---

## 📦 CI/CD Integration

### GitHub Actions Workflow

**Location:** `.github/workflows/deploy.yml`

```yaml
name: Deploy

on:
  push:
    branches:
      - main  # production
      - staging

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set environment
        run: |
          if [ "${{ github.ref }}" == "refs/heads/main" ]; then
            echo "ENVIRONMENT=production" >> $GITHUB_ENV
          else
            echo "ENVIRONMENT=staging" >> $GITHUB_ENV
          fi

      - name: Deploy
        run: |
          chmod +x deploy.sh
          ./deploy.sh ${{ env.ENVIRONMENT }}
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          JWT_SECRET: ${{ secrets.JWT_SECRET }}
```

---

## ✅ Validation Checklist

### Staging Environment
- [ ] Server hardened (Steps 1-9 completed)
- [ ] `docker-compose.staging.yml` created with Traefik
- [ ] `.env.staging` configured with real secrets
- [ ] DNS points to staging server IP
- [ ] `./deploy.sh staging` succeeds
- [ ] https://staging.{DOMAIN} loads
- [ ] https://api-staging.{DOMAIN}/health returns 200
- [ ] SSL certificate issued (Let's Encrypt staging CA)

### Production Environment
- [ ] Server hardened (Steps 1-9 completed)
- [ ] `docker-compose.production.yml` created with Traefik
- [ ] `.env.production` configured with strong passwords (16+ chars)
- [ ] DNS points to production server IP
- [ ] `./deploy.sh production` succeeds
- [ ] https://{DOMAIN} loads
- [ ] https://api.{DOMAIN}/health returns 200
- [ ] SSL certificate issued (Let's Encrypt production CA - trusted)
- [ ] Backups scheduled (cron)

---

## 📚 Referências

### Documentação Relacionada
- **[PE-00-Quick-Start.md](./PE-00-Quick-Start.md)** - Local development MVP
- **[PE-02-Scaling-Strategy.md](./PE-02-Scaling-Strategy.md)** - Future growth and scaling

### Recursos do Projeto
- **Checklist PE:** `.agents/workflow/02-checklists/PE-checklist.yml`
- **Agent XML:** `.agents/30-PE - Platform Engineer.xml`
- **Workflow Guide:** `.agents/docs/00-Workflow-Guide.md`

---

**Template Version:** 4.0 (Server Setup)
**Last Updated:** 2025-10-29
**Split From:** PE-00-Environments-Setup.template.md v3.0
