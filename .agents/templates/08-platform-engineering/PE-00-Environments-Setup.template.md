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
| **Development** | Local development | Docker Compose | `docker-compose up` |
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

### Staging Environment

**File:** `docker-compose.staging.yml`

```yaml
version: '3.8'

services:
  api:
    image: ${DOCKER_REGISTRY}/api:staging
    ports:
      - "5000:5000"
    environment:
      - ASPNETCORE_ENVIRONMENT=Staging
      - DATABASE_URL=${DATABASE_URL_STAGING}
      - JWT_SECRET=${JWT_SECRET}
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    restart: unless-stopped

  frontend:
    image: ${DOCKER_REGISTRY}/frontend:staging
    ports:
      - "3000:3000"
    environment:
      - VITE_API_URL=${API_URL_STAGING}
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    restart: unless-stopped

  database:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=${DB_NAME_STAGING}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_staging_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_staging_data:
```

### Production Environment

**File:** `docker-compose.prod.yml`

```yaml
version: '3.8'

services:
  api:
    image: ${DOCKER_REGISTRY}/api:${VERSION}
    ports:
      - "5000:5000"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - DATABASE_URL=${DATABASE_URL_PROD}
      - JWT_SECRET=${JWT_SECRET_PROD}
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    image: ${DOCKER_REGISTRY}/frontend:${VERSION}
    ports:
      - "80:80"
      - "443:443"
    environment:
      - VITE_API_URL=${API_URL_PROD}
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
    restart: always

  database:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=${DB_NAME_PROD}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_prod_data:/var/lib/postgresql/data
    restart: always

volumes:
  postgres_prod_data:
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
docker-compose -f docker-compose.$ENVIRONMENT.yml down
docker-compose -f docker-compose.$ENVIRONMENT.yml up -d

# Run migrations
echo "🗄️  Running database migrations..."
docker-compose -f docker-compose.$ENVIRONMENT.yml exec -T api dotnet ef database update

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
docker-compose -f docker-compose.$ENVIRONMENT.yml down
docker-compose -f docker-compose.$ENVIRONMENT.yml up -d

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

# Database
DB_NAME=tradergeo
DB_USER=postgres
DB_PASSWORD=CHANGE_ME_IN_PRODUCTION

# Database URLs
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@database:5432/${DB_NAME}
DATABASE_URL_STAGING=postgresql://${DB_USER}:${DB_PASSWORD}@staging-db-host:5432/${DB_NAME_STAGING}
DATABASE_URL_PROD=postgresql://${DB_USER}:${DB_PASSWORD}@prod-db-host:5432/${DB_NAME_PROD}

# API URLs
API_URL_STAGING=https://staging-api.tradergeo.com
API_URL_PROD=https://api.tradergeo.com

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
.env
.env.dev
.env.staging
.env.production
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
docker-compose logs -f api
docker-compose logs -f frontend

# View logs (staging/production)
docker-compose -f docker-compose.staging.yml logs -f api
docker-compose -f docker-compose.production.yml logs -f api

# Filter by time
docker-compose logs --since 30m api
docker-compose logs --tail=100 api
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

## ✅ Checklist de Validação

### Development Environment
- [ ] `docker-compose.dev.yml` criado
- [ ] `docker-compose up` funciona localmente
- [ ] API responde em `http://localhost:5000/health`
- [ ] Frontend carrega em `http://localhost:3000`
- [ ] Database conecta corretamente

### Staging Environment
- [ ] `docker-compose.staging.yml` criado
- [ ] `.env.staging` configurado (secrets corretos)
- [ ] `./deploy.sh staging` funciona
- [ ] Health check passa
- [ ] Logs acessíveis via `docker-compose logs`

### Production Environment
- [ ] `docker-compose.prod.yml` criado
- [ ] `.env.production` configurado (secrets fortes)
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
