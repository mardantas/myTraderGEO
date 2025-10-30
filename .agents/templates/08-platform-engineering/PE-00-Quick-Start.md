<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# PE-00 - Quick Start (Local Development MVP)

**Agent:** PE (Platform Engineer)
**Phase:** Discovery (1x)
**Scope:** Minimal viable setup for local development with Docker Compose
**Version:** 4.0 (Split from PE-00-Environments-Setup)

---

## 📋 Metadata

- **Project Name:** [PROJECT_NAME]  
- **Created:** [DATE]  
- **PE Engineer:** [NAME]  
- **Target:** Local development only  
- **Approach:** Docker Compose with minimal configuration  

---

## 🎯 Objetivo

Configure um ambiente de desenvolvimento local funcional em **menos de 15 minutos**. Este guia cobre APENAS o necessário para começar a desenvolver localmente.

**Para deploy remoto e produção:** Veja [PE-01-Server-Setup.md](./PE-01-Server-Setup.md)
**Para estratégia de escalabilidade:** Veja [PE-02-Scaling-Strategy.md](./PE-02-Scaling-Strategy.md)

---

## 🏗️ Environments Overview

### Environment Strategy

| Environment | Purpose | Infrastructure | Deploy Method |
|-------------|---------|----------------|---------------|
| **Development** | Local development | Docker Compose | `docker compose -f docker-compose.dev.yml --env-file .env.dev up` |
| **Staging** | Pre-production testing | [SERVER/CLOUD] | See PE-01-Server-Setup.md |
| **Production** | Live users | [SERVER/CLOUD] | See PE-01-Server-Setup.md |

**Este guia cobre apenas Development (local).**

### Hosting Strategy (Future Reference)

**Selected Approach:** [Choose one for staging/production]
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

## 🔀 Por Que NÃO Usar Traefik em Development?

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
- ❌ Acesso direto via `localhost:3000`, `localhost:5000` é mais simples
- ❌ Hot reload funciona melhor sem proxy reverso

**Para configuração completa de Traefik (staging/production), veja [PE-01-Server-Setup.md](./PE-01-Server-Setup.md)**

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
DB_PASSWORD=dev_password_123

# Database URLs
DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@database:5432/${DB_NAME}
DATABASE_URL_STAGING=postgresql://${DB_USER}:${DB_PASSWORD}@staging-db-host:5432/${DB_NAME_STAGING}
DATABASE_URL_PROD=postgresql://${DB_USER}:${DB_PASSWORD}@prod-db-host:5432/${DB_NAME_PROD}

# API URLs
API_URL_STAGING=https://api-staging.${DOMAIN}
API_URL_PROD=https://api.${DOMAIN}

# Secrets (CHANGE IN PRODUCTION!)
JWT_SECRET=dev_secret_minimum_32_characters_1234567890
JWT_SECRET_PROD=CHANGE_ME_DIFFERENT_FOR_PRODUCTION

# Third-party APIs (examples)
STRIPE_API_KEY=
SENDGRID_API_KEY=

# Monitoring (optional for v1.0)
LOG_LEVEL=Information
```

### Environment-Specific Files

Create these files (DO NOT commit to git):
- `.env.dev` (local development) - **Use simple passwords, it's OK for dev**
- `.env.staging` (staging server) - See PE-01-Server-Setup.md
- `.env.prod` (production server) - See PE-01-Server-Setup.md

**Add to .gitignore:**
```
.env*
!.env.example
```

**Usage:**
```bash
# Development
docker compose -f docker-compose.dev.yml --env-file .env.dev up

# Staging (see PE-01-Server-Setup.md)
docker compose -f docker-compose.staging.yml --env-file .env.staging up

# Production (see PE-01-Server-Setup.md)
docker compose -f docker-compose.prod.yml --env-file .env.prod up
```

---

## 📊 Logging Configuration

### Docker Logging

All containers configured with JSON logging:
- **max-size:** 10m (development)
- **max-file:** 3 (development)

### Log Access

```bash
# View logs (development)
docker compose -f docker-compose.dev.yml --env-file .env.dev logs -f api
docker compose -f docker-compose.dev.yml --env-file .env.dev logs -f frontend

# Filter by time
docker compose -f docker-compose.dev.yml --env-file .env.dev logs --since 30m api
docker compose -f docker-compose.dev.yml --env-file .env.dev logs --tail=100 api
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

## 🚀 Local Deployment Script

### deploy_local Function

**Location:** `scripts/deploy.sh` (excerpt)

```bash
#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

#############################################
# Function: deploy_local
# Description: Local deployment for development
#############################################
deploy_local() {
    echo -e "${GREEN}🚀 Starting LOCAL deployment (development)...${NC}"

    # Load environment variables
    if [ -f ".env.dev" ]; then
        export $(cat ".env.dev" | grep -v '^#' | xargs)
    else
        echo -e "${RED}Error: .env.dev file not found${NC}"
        exit 1
    fi

    # Deploy locally
    echo -e "${YELLOW}🚢 Deploying containers locally...${NC}"
    docker compose -f docker-compose.dev.yml --env-file .env.dev down
    docker compose -f docker-compose.dev.yml --env-file .env.dev up -d

    # Health check (local HTTP, no retry needed for dev)
    echo -e "${YELLOW}🏥 Running health check...${NC}"
    sleep 10
    HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health)

    if [ "$HEALTH_STATUS" -eq 200 ]; then
        echo -e "${GREEN}✅ LOCAL deployment successful! API is healthy.${NC}"
    else
        echo -e "${RED}❌ Deployment failed! API health check returned $HEALTH_STATUS${NC}"
        exit 1
    fi
}

# Usage
deploy_local
```

**Usage:**
```bash
bash scripts/deploy.sh
```

---

## 🪟 Desenvolvimento no Windows

### Executando Scripts Bash no Windows

Este projeto usa **scripts Bash** (`deploy.sh`, `rollback.sh`, etc.) para automação. No Windows, existem duas formas de executar esses scripts:

**Opção 1: Git Bash (Recomendado)**
```bash
# Git Bash vem incluído no Git for Windows
bash ./scripts/deploy.sh
bash ./scripts/health-check.sh development
```

**Opção 2: WSL2**
```bash
# Docker Desktop usa WSL2 como backend, então você pode usar:
wsl bash ./scripts/deploy.sh
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

**Backups são importantes apenas em staging/production** (ver [PE-01-Server-Setup.md](./PE-01-Server-Setup.md)).

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
- [ ] `.env.dev` configurado (copiar de `.env.example` e ajustar)
- [ ] `docker compose -f docker-compose.dev.yml --env-file .env.dev up` funciona localmente
- [ ] API responde em `http://localhost:5000/health`
- [ ] Frontend carrega em `http://localhost:3000`
- [ ] Database conecta corretamente
- [ ] Hot reload funciona (alterar código e ver mudanças sem rebuild)

---

## 🚫 O Que NÃO Está Neste Guia

Este é um guia **mínimo** para desenvolvimento local. **NÃO incluímos:**

- ❌ Server setup remoto (veja [PE-01-Server-Setup.md](./PE-01-Server-Setup.md))
- ❌ Configuração Traefik (staging/production)
- ❌ Deploy scripts completos (remote deployment)
- ❌ Backup strategy (production)
- ❌ CI/CD integration
- ❌ Scaling strategy (veja [PE-02-Scaling-Strategy.md](./PE-02-Scaling-Strategy.md))

---

## 📚 Referências

### Documentação Relacionada
- **[PE-01-Server-Setup.md](./PE-01-Server-Setup.md)** - Setup de servidor remoto e deploy em staging/production
- **[PE-02-Scaling-Strategy.md](./PE-02-Scaling-Strategy.md)** - Estratégia de escalabilidade e crescimento

### Recursos do Projeto
- **Checklist PE:** `.agents/workflow/02-checklists/PE-checklist.yml`
- **Agent XML:** `.agents/30-PE - Platform Engineer.xml`
- **Workflow Guide:** `.agents/docs/00-Workflow-Guide.md`

---

**Template Version:** 4.0 (Quick Start)
**Last Updated:** 2025-10-29
**Split From:** PE-00-Environments-Setup.template.md v3.0
