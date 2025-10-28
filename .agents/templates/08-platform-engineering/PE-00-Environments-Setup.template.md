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
**Version:** 3.0 (Simplified)  

---

## 📋 Metadata

- **Project Name:** [PROJECT_NAME]
- **Created:** [DATE]
- **PE Engineer:** [NAME]
- **Target:** Small/Medium Projects
- **Approach:** Scripts NOT full IaC

---

## 🎯 Objetivo

Configurar ambientes básicos (dev, staging, production) com Docker Compose e scripts de deploy simples - SEM Infrastructure as Code completo.

---

## 🏗️ Environments Overview

### Environment Strategy

| Environment | Purpose | Infrastructure | Deploy Method |
|-------------|---------|----------------|---------------|
| **Development** | Local development | Docker Compose | `docker-compose -f docker-compose.dev.yml --env-file .env.dev up` |
| **Staging** | Pre-production testing | [SERVER/CLOUD] | `./deploy.sh staging` |
| **Production** | Live users | [SERVER/CLOUD] | `./deploy.sh production` |

### Hosting Strategy

**Selected Approach:** [Choose one]  
- [ ] Single VPS (Contabo, DigitalOcean, Linode)
- [ ] Cloud Platform (AWS, Azure, GCP) - básico
- [ ] Managed Container Service (AWS ECS, Azure Container Instances)

**Justification:** [Why this choice fits small/medium project needs]  

---

## 🐳 Docker Compose Configuration

### Development Environment

**File:** `docker-compose.dev.yml`  

```yaml
version: '3.8'

services:
  # Backend API
  api:
    build:
      context: ./02-backend
      dockerfile: Dockerfile.dev
    ports:
      - "5000:5000"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - DATABASE_URL=${DATABASE_URL}
    volumes:
      - ./02-backend:/app
    depends_on:
      - database
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Frontend
  frontend:
    build:
      context: ./01-frontend
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    environment:
      - VITE_API_URL=http://localhost:5000
    volumes:
      - ./01-frontend:/app
    depends_on:
      - api

  # Database
  database:
    image: postgres:15-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

---

## 🔀 Traefik Reverse Proxy (Staging + Production)

### Por Que Traefik?

**Traefik v3.0** é usado em **staging e production** (não em development) para:

1. **SSL Automático (Let's Encrypt)**
   - Certificados HTTPS automáticos
   - Staging: usa Let's Encrypt staging CA (não polui rate limits)
   - Production: usa Let's Encrypt production CA (certificados trusted)

2. **Routing Declarativo**
   - Configuração via labels Docker (simples)
   - Não precisa editar arquivos nginx.conf complexos
   - Auto-discovery de serviços

3. **Load Balancing Nativo**
   - Preparado para escalar horizontalmente
   - Múltiplas réplicas do mesmo serviço

4. **Dashboard de Monitoramento**
   - Interface web para visualizar rotas e serviços
   - Útil para troubleshooting

### Quando NÃO Usar Traefik

**Development (localhost):**
- ❌ Sem domínio real → sem SSL necessário
- ❌ Acesso direto via `localhost:5173`, `localhost:5000` é mais simples
- ❌ Hot reload funciona melhor sem proxy reverso

### Traefik Configuration

**File:** `05-infra/configs/traefik.yml`

```yaml
# Traefik Static Configuration
# Docs: https://doc.traefik.io/traefik/

api:
  dashboard: true  # Enable web dashboard
  insecure: false  # Require authentication (configure in docker-compose)

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
  # Let's Encrypt Staging (for testing - doesn't hit rate limits)
  letsencrypt-staging:
    acme:
      email: ${LETSENCRYPT_EMAIL}
      storage: /letsencrypt/acme.json
      caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      httpChallenge:
        entryPoint: web

  # Let's Encrypt Production (for production - trusted certificates)
  letsencrypt:
    acme:
      email: ${LETSENCRYPT_EMAIL}
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web

providers:
  docker:
    exposedByDefault: false  # Only expose services with traefik.enable=true
```

### Docker Compose with Traefik (Staging)

**File:** `docker-compose.staging.yml`

```yaml
version: '3.8'

services:
  # Traefik Reverse Proxy
  traefik:
    image: traefik:v3.0
    command:
      - "--configFile=/etc/traefik/traefik.yml"
      - "--certificatesresolvers.letsencrypt.acme.email=${LETSENCRYPT_EMAIL}"
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
      # Traefik Dashboard
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`traefik-staging.${DOMAIN}`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt-staging"
      - "traefik.http.routers.traefik.service=api@internal"
      # Basic Auth (user: admin, password: change_me)
      - "traefik.http.routers.traefik.middlewares=auth"
      - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$8EVjn/nj$$GiLUZqcbueTFeD23SuB6x0"

  # Backend API
  api:
    image: ${DOCKER_REGISTRY}/api:staging
    environment:
      - ASPNETCORE_ENVIRONMENT=Staging
      - DATABASE_URL=${DATABASE_URL_STAGING}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - database
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

  # Frontend
  frontend:
    image: ${DOCKER_REGISTRY}/frontend:staging
    environment:
      - VITE_API_URL=https://api-staging.${DOMAIN}
    depends_on:
      - api
    networks:
      - web
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend-staging.rule=Host(`staging.${DOMAIN}`)"
      - "traefik.http.routers.frontend-staging.entrypoints=websecure"
      - "traefik.http.routers.frontend-staging.tls.certresolver=letsencrypt-staging"
      - "traefik.http.services.frontend-staging.loadbalancer.server.port=80"

  # Database
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
    driver: bridge
  backend:
    driver: bridge

volumes:
  postgres_staging_data:
  traefik-letsencrypt:
```

### Docker Compose with Traefik (Production)

**File:** `docker-compose.prod.yml`

```yaml
version: '3.8'

services:
  # Traefik Reverse Proxy
  traefik:
    image: traefik:v3.0
    command:
      - "--configFile=/etc/traefik/traefik.yml"
      - "--certificatesresolvers.letsencrypt.acme.email=${LETSENCRYPT_EMAIL}"
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
      # Traefik Dashboard (Production - IP whitelist recommended)
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`traefik.${DOMAIN}`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
      - "traefik.http.routers.traefik.service=api@internal"
      # Basic Auth + IP Whitelist (configure YOUR_IP_ADDRESS)
      - "traefik.http.routers.traefik.middlewares=auth,ipwhitelist"
      - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$8EVjn/nj$$GiLUZqcbueTFeD23SuB6x0"
      - "traefik.http.middlewares.ipwhitelist.ipwhitelist.sourcerange=${YOUR_IP_ADDRESS}/32"

  # Backend API
  api:
    image: ${DOCKER_REGISTRY}/api:${VERSION}
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - DATABASE_URL=${DATABASE_URL_PROD}
      - JWT_SECRET=${JWT_SECRET_PROD}
    depends_on:
      - database
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
      - "traefik.http.services.api-prod.loadbalancer.server.port=5000"

  # Frontend
  frontend:
    image: ${DOCKER_REGISTRY}/frontend:${VERSION}
    environment:
      - VITE_API_URL=https://api.${DOMAIN}
    depends_on:
      - api
    networks:
      - web
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend-prod.rule=Host(`${DOMAIN}`)"
      - "traefik.http.routers.frontend-prod.entrypoints=websecure"
      - "traefik.http.routers.frontend-prod.tls.certresolver=letsencrypt"
      - "traefik.http.services.frontend-prod.loadbalancer.server.port=80"

  # Database
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
    driver: bridge
  backend:
    driver: bridge

volumes:
  postgres_prod_data:
  traefik-letsencrypt:
```

### Acesso aos Serviços

#### Staging
- **Frontend:** https://staging.{DOMAIN}
- **Backend API:** https://api-staging.{DOMAIN}
- **Traefik Dashboard:** https://traefik-staging.{DOMAIN} (user: `admin`, pwd: `change_me`)

#### Production
- **Frontend:** https://{DOMAIN}
- **Backend API:** https://api.{DOMAIN}
- **Traefik Dashboard:** https://traefik.{DOMAIN} (IP whitelist + basic auth)

### Troubleshooting Traefik

**Problema: SSL certificate not issued**

```bash
# 1. Check Traefik logs
docker compose logs traefik

# 2. Verify DNS points to server
nslookup {DOMAIN}

# 3. Check if ports 80/443 are open
curl -I http://{DOMAIN}

# 4. Verify email in .env (for Let's Encrypt)
cat .env.staging | grep LETSENCRYPT_EMAIL

# 5. Check acme.json permissions
docker exec traefik ls -la /letsencrypt/acme.json
# Should be 600 (rw-------)

# 6. Staging: Check if using Let's Encrypt staging CA
docker compose logs traefik | grep "acme-staging"

# 7. Production: Ensure using production CA (not staging)
docker compose logs traefik | grep "acme-v02.api.letsencrypt.org"
```

**Problema: Service not accessible**

```bash
# 1. Check if service is registered in Traefik
docker compose exec traefik wget -O- http://localhost:8080/api/http/routers

# 2. Verify labels are correct
docker compose config | grep -A 10 "labels:"

# 3. Check if service is in correct network
docker compose exec traefik ping api
docker compose exec traefik ping frontend

# 4. Verify traefik.enable=true label
docker inspect {container_name} | grep traefik.enable
```

---

## 📜 Deploy Scripts

### deploy.sh

**Location:** Project root  

```bash
#!/bin/bash

# deploy.sh - Simple deployment script for staging/production
# Usage: ./deploy.sh [staging|production]

set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./deploy.sh [staging|production]"
  exit 1
fi

if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
  echo "Error: Environment must be 'staging' or 'production'"
  exit 1
fi

echo "🚀 Deploying to $ENVIRONMENT..."

# Load environment variables
if [ -f ".env.$ENVIRONMENT" ]; then
  export $(cat ".env.$ENVIRONMENT" | xargs)
else
  echo "Error: .env.$ENVIRONMENT file not found"
  exit 1
fi

# Build Docker images
echo "📦 Building Docker images..."
docker build -t ${DOCKER_REGISTRY}/api:${VERSION} ./02-backend
docker build -t ${DOCKER_REGISTRY}/frontend:${VERSION} ./01-frontend

# Push to registry (if using remote registry)
if [ -n "$DOCKER_REGISTRY" ]; then
  echo "⬆️  Pushing images to registry..."
  docker push ${DOCKER_REGISTRY}/api:${VERSION}
  docker push ${DOCKER_REGISTRY}/frontend:${VERSION}
fi

# Deploy to server
echo "🚢 Deploying containers..."
docker-compose -f docker-compose.$ENVIRONMENT.yml --env-file .env.$ENVIRONMENT down
docker-compose -f docker-compose.$ENVIRONMENT.yml --env-file .env.$ENVIRONMENT up -d

# Run migrations
echo "🗄️  Running database migrations..."
docker-compose -f docker-compose.$ENVIRONMENT.yml --env-file .env.$ENVIRONMENT exec -T api dotnet ef database update

# Health check
echo "🏥 Running health checks..."
sleep 10
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health)

if [ "$HEALTH_STATUS" -eq 200 ]; then
  echo "✅ Deployment successful! API is healthy."
else
  echo "❌ Deployment failed! API health check returned $HEALTH_STATUS"
  exit 1
fi

echo "🎉 Deployment to $ENVIRONMENT completed successfully!"
```

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
docker-compose -f docker-compose.$ENVIRONMENT.yml --env-file .env.$ENVIRONMENT down
docker-compose -f docker-compose.$ENVIRONMENT.yml --env-file .env.$ENVIRONMENT up -d

echo "✅ Rollback completed!"
```

---

## 🔐 Environment Variables

### .env.example

**Location:** Project root  

```bash
# Project
PROJECT_NAME=myTraderGEO
VERSION=1.0.0

# Docker Registry (optional - for remote deployments)
DOCKER_REGISTRY=

# Domain (for Traefik SSL certificates - staging/production only)
DOMAIN=tradergeo.com
LETSENCRYPT_EMAIL=admin@tradergeo.com

# IP Whitelist (for Traefik Dashboard - production only)
YOUR_IP_ADDRESS=203.0.113.0

# Database
DB_NAME=tradergeo
DB_USER=postgres
DB_PASSWORD=CHANGE_ME_IN_PRODUCTION

# Database URLs
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@database:5432/${DB_NAME}
DATABASE_URL_STAGING=postgresql://${DB_USER}:${DB_PASSWORD}@staging-db-host:5432/${DB_NAME_STAGING}
DATABASE_URL_PROD=postgresql://${DB_USER}:${DB_PASSWORD}@prod-db-host:5432/${DB_NAME_PROD}

# API URLs
API_URL_STAGING=https://api-staging.${DOMAIN}
API_URL_PROD=https://api.${DOMAIN}

# Secrets (CHANGE IN PRODUCTION!)
JWT_SECRET=CHANGE_ME_MINIMUM_32_CHARACTERS
JWT_SECRET_PROD=CHANGE_ME_DIFFERENT_FOR_PRODUCTION

# Third-party APIs (examples)
STRIPE_API_KEY=
SENDGRID_API_KEY=

# Monitoring (optional for v1.0)
LOG_LEVEL=Information
```

### Environment-Specific Files

Create these files (DO NOT commit to git):
- `.env.dev` (local development)
- `.env.staging` (staging server)
- `.env.production` (production server)

**Add to .gitignore:**
```
.env*
!.env.example
```

**Usage:**
```bash
# Development
docker-compose -f docker-compose.dev.yml --env-file .env.dev up

# Staging
docker-compose -f docker-compose.staging.yml --env-file .env.staging up

# Production
docker-compose -f docker-compose.production.yml --env-file .env.production up
```

---

## 📊 Logging Configuration

### Docker Logging

All containers configured with JSON logging:
- **max-size:** 10m (staging), 10m (production)
- **max-file:** 3 (staging), 5 (production)

### Log Access

```bash
# View logs (development)
docker-compose -f docker-compose.dev.yml --env-file .env.dev logs -f api
docker-compose -f docker-compose.dev.yml --env-file .env.dev logs -f frontend

# View logs (staging/production)
docker-compose -f docker-compose.staging.yml --env-file .env.staging logs -f api
docker-compose -f docker-compose.production.yml --env-file .env.production logs -f api

# Filter by time
docker-compose -f docker-compose.dev.yml --env-file .env.dev logs --since 30m api
docker-compose -f docker-compose.dev.yml --env-file .env.dev logs --tail=100 api
```

---

## 🏥 Health Checks

### API Health Endpoint

**Implementation Required:** `GET /health`  

```csharp
// Example: ASP.NET Core
app.MapGet("/health", () =>
{
    return Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
});
```

### Health Check Script

**Location:** `scripts/health-check.sh`  

```bash
#!/bin/bash

ENVIRONMENT=$1
API_URL=${2:-"http://localhost:5000"}

echo "🏥 Checking health of $ENVIRONMENT..."

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $API_URL/health)

if [ "$RESPONSE" -eq 200 ]; then
  echo "✅ $ENVIRONMENT is healthy"
  exit 0
else
  echo "❌ $ENVIRONMENT is unhealthy (HTTP $RESPONSE)"
  exit 1
fi
```

---

## 🔄 Backup Strategy (Basic)

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

docker-compose -f docker-compose.$ENVIRONMENT.yml exec -T database \
  pg_dump -U $DB_USER $DB_NAME > $BACKUP_DIR/${ENVIRONMENT}_${TIMESTAMP}.sql

echo "✅ Backup saved to $BACKUP_DIR/${ENVIRONMENT}_${TIMESTAMP}.sql"

# Keep only last 7 backups
ls -t $BACKUP_DIR/${ENVIRONMENT}_*.sql | tail -n +8 | xargs rm -f
```

### Backup Schedule

**Recommended:**  
- **Staging:** Manual backups before major changes
- **Production:** Daily backups (cron job or manual)

**Cron example (production):**  
```cron
0 2 * * * /path/to/scripts/backup-db.sh production
```

---

## 📦 CI/CD Integration (Basic)

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

## 🪟 Desenvolvimento no Windows

### Executando Scripts Bash no Windows

Este projeto usa **scripts Bash** (`deploy.sh`, `rollback.sh`, `backup-db.sh`, etc.) para automação. No Windows, existem duas formas de executar esses scripts:

**Opção 1: Git Bash (Recomendado)**
```bash
# Git Bash vem incluído no Git for Windows
bash ./deploy.sh staging
bash ./scripts/backup-db.sh staging
```

**Opção 2: WSL2**
```bash
# Docker Desktop usa WSL2 como backend, então você pode usar:
wsl bash ./deploy.sh staging
```

### Named Volumes e Desempenho

Docker Desktop no Windows armazena **named volumes** no sistema de arquivos do WSL2:
```
\\wsl$\docker-desktop-data\data\docker\volumes\
```

**Vantagens:**  
- ✅ Performance otimizada (60x mais rápido que bind mounts para databases)
- ✅ Funciona identicamente em Windows/Linux/Mac
- ✅ Docker gerencia automaticamente (não precisa gerenciamento manual)

**Bind mounts** para código-fonte (hot reload) continuam funcionando normalmente:
```yaml
volumes:
  - ./02-backend:/app  # Hot reload funciona via WSL2 file watching
  - ./01-frontend:/app # Hot reload funciona via WSL2 file watching
```

### Backups em Development

**Não há necessidade de backups** no ambiente de desenvolvimento:
- Dados são efêmeros e podem ser recriados com migrations + seed data
- Para resetar o banco: `docker compose down -v && docker compose up -d`
- Git já versiona migrations e seed data

**Backups são importantes apenas em staging/production** (ver seção "Backup Strategy").

### Pré-requisitos Windows

- **Docker Desktop for Windows** (com WSL2 backend habilitado)
- **Git for Windows** (inclui Git Bash)
- **Windows 10/11** com WSL2 configurado

### Troubleshooting Windows

**Problema: Hot reload não funciona**
- Solução: Certifique-se que Docker Desktop está usando WSL2 backend (não Hyper-V)
- Verificar: Docker Desktop → Settings → General → "Use the WSL 2 based engine"

**Problema: Performance lenta**
- Solução: Manter o projeto dentro do filesystem WSL2 (`\\wsl$\Ubuntu\home\user\projects\`) ao invés de `C:\Users\...`
- Alternativa: Se precisar manter em `C:\`, usar named volumes para databases (já configurado nos templates)

---

## ✅ Checklist de Validação

### Development Environment
- [ ] `docker-compose.dev.yml` criado
- [ ] `.env.dev` configurado
- [ ] `docker-compose -f docker-compose.dev.yml --env-file .env.dev up` funciona localmente
- [ ] API responde em `http://localhost:5000/health`
- [ ] Frontend carrega em `http://localhost:3000`
- [ ] Database conecta corretamente

### Staging Environment
- [ ] `docker-compose.staging.yml` criado com Traefik
- [ ] `.env.staging` configurado (secrets corretos, DOMAIN e LETSENCRYPT_EMAIL)
- [ ] `05-infra/configs/traefik.yml` criado
- [ ] Traefik Dashboard acessível em https://traefik-staging.{DOMAIN}
- [ ] Frontend acessível via HTTPS em https://staging.{DOMAIN}
- [ ] Backend API acessível via HTTPS em https://api-staging.{DOMAIN}
- [ ] `./deploy.sh staging` funciona
- [ ] Health check passa
- [ ] Logs acessíveis via `docker-compose -f docker-compose.staging.yml --env-file .env.staging logs`

### Production Environment
- [ ] `docker-compose.prod.yml` criado com Traefik
- [ ] `.env.production` configurado (secrets fortes, DOMAIN, LETSENCRYPT_EMAIL, YOUR_IP_ADDRESS)
- [ ] `05-infra/configs/traefik.yml` criado
- [ ] Traefik Dashboard acessível em https://traefik.{DOMAIN} (IP whitelist + basic auth)
- [ ] Frontend acessível via HTTPS em https://{DOMAIN}
- [ ] Backend API acessível via HTTPS em https://api.{DOMAIN}
- [ ] SSL certificates issued by Let's Encrypt (trusted CA)
- [ ] `./deploy.sh production` funciona
- [ ] Health check passa
- [ ] Rollback testado (`./rollback.sh production [version]`)

### Scripts
- [ ] `deploy.sh` com permissão de execução (`chmod +x`)
- [ ] `rollback.sh` com permissão de execução
- [ ] `backup-db.sh` criado e testado
- [ ] Health check script funcional

### Security
- [ ] `.env` files adicionados ao `.gitignore`
- [ ] Secrets NUNCA commitados
- [ ] Passwords fortes em production
- [ ] JWT secrets diferentes por ambiente

### Documentation
- [ ] README.md atualizado com instruções de deploy
- [ ] Variáveis de ambiente documentadas
- [ ] Processo de rollback documentado

---

## 🚫 O QUE NÃO FAZEMOS em v1.0

Para manter a simplicidade em projetos small/medium, v1.0 **NÃO inclui**:

- ❌ **IaC completo** (Terraform, Bicep, CloudFormation)
- ❌ **Observability stack** (Prometheus, Grafana, Jaeger, Loki)
- ❌ **Disaster Recovery Plan** completo (RTO/RPO formal)
- ❌ **Blue-Green deployment**
- ❌ **Canary deployment**
- ❌ **Auto-scaling policies**
- ❌ **VPC/Network complexo**
- ❌ **Load Balancer gerenciado** (usar reverse proxy se necessário)

**Quando adicionar:** Quando escalar para enterprise ou tiver >100k usuários.  

---

## 📚 Referências

- **Checklist PE:** `.agents/workflow/02-checklists/PE-checklist.yml`
- **Agent XML:** `.agents/30-PE - Platform Engineer.xml`
- **Workflow Guide:** `.agents/00-Workflow-Guide.md`

---

**Template Version:** 3.0  
**Last Updated:** 2025-10-08  
