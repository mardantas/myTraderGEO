# 05-infra - myTraderGEO Infrastructure

Configuração completa de infraestrutura Docker para os ambientes Development, Staging e Production do myTraderGEO.

## Stack Tecnológico

- **Backend:** .NET 8 (C#) + ASP.NET Core + Entity Framework Core + SignalR
- **Frontend:** Vue 3 + TypeScript + Vite + Pinia + PrimeVue
- **Database:** PostgreSQL 15
- **Containerização:** Docker + Docker Compose
- **Web Server (Frontend):** Nginx (serve arquivos estáticos Vue.js em production)
- **Reverse Proxy/Load Balancer:** Traefik v3.0 (HTTPS, SSL automático, load balancing - staging/production)

## Estrutura de Pastas

```
05-infra/
├── configs/
│   ├── .env.example          # Template de variáveis de ambiente
│   └── traefik.yml           # Traefik static configuration
├── docker/
│   ├── docker-compose.yml            # Development
│   ├── docker-compose.staging.yml    # Staging + Traefik
│   └── docker-compose.production.yml # Production + Traefik + Resource Limits
├── dockerfiles/
│   ├── backend/
│   │   ├── Dockerfile        # Backend production
│   │   └── Dockerfile.dev    # Backend development (hot reload)
│   └── frontend/
│       ├── Dockerfile        # Frontend production (Nginx)
│       ├── Dockerfile.dev    # Frontend development (Vite)
│       └── nginx.conf        # Nginx SPA configuration
└── scripts/
    ├── deploy.sh             # Script de deployment
    ├── backup-database.sh    # Backup do banco (TODO)
    └── restore-database.sh   # Restore do banco (TODO)
```

## Quick Start

### 1. Configurar Variáveis de Ambiente

```bash
# Copiar template
cp 05-infra/configs/.env.example 05-infra/configs/.env

# Editar .env com suas credenciais
nano 05-infra/configs/.env
```

### 2. Development - Iniciar Ambiente Local

```bash
# Subir todos os serviços
docker compose -f 05-infra/docker/docker-compose.yml up -d

# Verificar logs
docker compose -f 05-infra/docker/docker-compose.yml logs -f

# Parar serviços
docker compose -f 05-infra/docker/docker-compose.yml down
```

**Acessar:**
- Frontend (Vue + Vite): http://localhost:5173
- Backend API (.NET): http://localhost:5000
- Database (PostgreSQL): localhost:5432
- PgAdmin (opcional): http://localhost:8080
  - Email: `admin@mytrader.local`
  - Senha: `admin123`

### 3. Staging - Deploy para Staging

```bash
./05-infra/scripts/deploy.sh staging latest
```

### 4. Production - Deploy para Production

```bash
# Com confirmação interativa
./05-infra/scripts/deploy.sh production v1.0.0
```

## Ambientes

### Development

**Características:**
- Hot reload habilitado (backend e frontend)
- Volumes montados para desenvolvimento
- Logs detalhados (Information level)
- PgAdmin incluído para gestão do banco
- JWT expiration: 60 minutos
- Sem resource limits

**Docker Compose:** `05-infra/docker/docker-compose.yml`

**Dockerfiles:**
- Backend: `05-infra/dockerfiles/backend/Dockerfile.dev`
- Frontend: `05-infra/dockerfiles/frontend/Dockerfile.dev`

### Staging

**Características:**
- Imagens pré-buildadas do registry
- Logging moderado (Information level)
- JWT expiration: 60 minutos
- Restart policy: `unless-stopped`
- Environment: `ASPNETCORE_ENVIRONMENT=Staging`

**Docker Compose:** `05-infra/docker/docker-compose.staging.yml`

**Registry:** `ghcr.io/seu-usuario/mytrader-*:staging`

### Production

**Características:**
- Imagens pré-buildadas e versionadas
- Logging mínimo (Warning/Error level)
- JWT expiration: 15 minutos (segurança)
- Restart policy: `always`
- Resource limits configurados (CPU/Memory)
- Health checks rigorosos
- Backup automático configurado
- Environment: `ASPNETCORE_ENVIRONMENT=Production`

**Docker Compose:** `05-infra/docker/docker-compose.production.yml`

**Registry:** `ghcr.io/seu-usuario/mytrader-*:${VERSION}`

**Resource Limits:**
- API: 2 CPU / 2GB RAM (limit), 1 CPU / 1GB RAM (reservation)
- Frontend: 1 CPU / 512MB RAM (limit)
- Database: 2 CPU / 2GB RAM (limit), 1 CPU / 1GB RAM (reservation)

## Scripts de Deployment

### deploy.sh

Script principal de deployment com verificações de segurança.

**Uso:**
```bash
./05-infra/scripts/deploy.sh [environment] [version]
```

**Funcionalidades:**
- ✅ Validação de pré-requisitos (Docker, Docker Compose)
- ✅ Carregamento de variáveis de ambiente
- ✅ Backup automático do banco (staging/production)
- ✅ Pull de imagens atualizadas
- ✅ Deploy dos serviços
- ✅ Health checks pós-deploy
- ✅ Confirmação obrigatória para production

**Exemplos:**
```bash
# Development
./05-infra/scripts/deploy.sh development

# Staging
./05-infra/scripts/deploy.sh staging latest

# Production (com confirmação)
./05-infra/scripts/deploy.sh production v1.2.0
```

### backup-database.sh (TODO - Epic 2+)

Script para backup automatizado do PostgreSQL.

**Funcionalidades Planejadas:**
- Export completo do banco
- Compressão automática
- Upload para S3 (AWS)
- Rotação de backups (retention policy)

### restore-database.sh (TODO - Epic 2+)

Script para restore de backups do PostgreSQL.

**Funcionalidades Planejadas:**
- Download de backup do S3
- Validação de integridade
- Restore com confirmação
- Rollback support

## Docker Images

### Backend (.NET 8)

**Development (Dockerfile.dev):**
- Base: `mcr.microsoft.com/dotnet/sdk:8.0`
- Hot reload: `dotnet watch run`
- Port: 8080

**Production (Dockerfile):**
- Multi-stage build (build → publish → runtime)
- Base runtime: `mcr.microsoft.com/dotnet/aspnet:8.0`
- Non-root user (`appuser`)
- Health check integrado
- Entry point: `dotnet myTraderGEO.Api.dll`

### Frontend (Vue 3)

**Development (Dockerfile.dev):**
- Base: `node:20-alpine`
- Hot reload: Vite dev server
- Port: 5173
- Host: 0.0.0.0 (Docker networking)

**Production (Dockerfile):**
- Multi-stage build (build → nginx)
- Base: `nginx:1.25-alpine`
- Non-root user (`appuser`)
- Gzip compression habilitado
- SPA routing configurado
- API proxy (/api, /hubs)
- Security headers incluídos

### Database (PostgreSQL 15)

**Image:** `postgres:15-alpine`

**Features:**
- Health checks configurados
- Volumes persistentes
- Init scripts support (`04-database/init-scripts/`)
- Encoding: UTF-8
- Locale: pt_BR.UTF-8

## Variáveis de Ambiente

Todas as variáveis estão documentadas em `05-infra/configs/.env.example`.

**Principais:**

```bash
# Database
DB_USER=postgres
DB_PASSWORD=your_secure_password
DATABASE_URL_PRODUCTION=Host=database;Port=5432;...

# JWT
JWT_SECRET=your-secret-key-minimum-32-chars
JWT_EXPIRATION_MINUTES_PRODUCTION=15

# Docker
DOCKER_REGISTRY=ghcr.io/seu-usuario
VERSION=v1.0.0

# URLs
API_URL_PRODUCTION=https://api.mytrader.com
WS_URL_PRODUCTION=wss://api.mytrader.com/hubs/market
```

## Networking

Todos os ambientes usam a rede bridge `mytrader-network`.

**Comunicação Interna:**
- Frontend → API: `http://api:8080`
- API → Database: `postgres://database:5432`
- SignalR WebSocket: `/hubs/market`

**Portas Expostas:**

| Serviço  | Development | Staging/Production |
|----------|-------------|--------------------|
| API      | 5000        | 5000               |
| Frontend | 5173        | 3000               |
| Database | 5432        | 5432 (internal)    |
| PgAdmin  | 8080        | N/A                |

## Health Checks

### API (.NET)

```yaml
test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
interval: 30s
timeout: 10s
retries: 3-5 (depends on environment)
start_period: 40s
```

### Database (PostgreSQL)

```yaml
test: ["CMD-SHELL", "pg_isready -U postgres"]
interval: 10s
timeout: 5s
retries: 5
```

### Frontend (Nginx - Production)

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/
```

## Logging

### Development
- Level: `Information`
- Output: Console
- Volume: Não persiste

### Staging
- Level: `Information`
- Driver: `json-file`
- Max size: 10MB
- Max files: 3

### Production
- Level: `Warning` (API), `Error` (ASP.NET Core)
- Driver: `json-file`
- Max size: 10MB
- Max files: 5
- File logging: Serilog → `/app/logs/log-.txt` (daily rotation)
- Volume: `../../logs/api:/app/logs`

**Ver logs:**
```bash
# Development
docker compose -f 05-infra/docker/docker-compose.yml logs -f api

# Production
docker compose -f 05-infra/docker/docker-compose.production.yml logs -f api
```

## Segurança

### Docker

- ✅ Non-root users em todos os containers production
- ✅ Multi-stage builds (image size reduzido)
- ✅ Health checks obrigatórios
- ✅ Resource limits configurados
- ✅ Secrets via environment variables (não hardcoded)
- ✅ `.env` no `.gitignore`

### Nginx (Frontend Production)

```nginx
# Security headers
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

### API (.NET)

- JWT authentication com secret configurável
- HTTPS obrigatório em production
- CORS configurado por ambiente
- Logging de segurança (Serilog)

## Troubleshooting

### Container não inicia

```bash
# Verificar logs
docker compose -f 05-infra/docker/docker-compose.yml logs api

# Verificar health
docker compose -f 05-infra/docker/docker-compose.yml ps
```

### Database connection failed

```bash
# Verificar se database está healthy
docker compose -f 05-infra/docker/docker-compose.yml ps database

# Testar conexão manual
docker compose -f 05-infra/docker/docker-compose.yml exec database psql -U postgres -d mytrader_dev
```

### Hot reload não funciona

**Backend (.NET):**
- Verificar volume mount: `../../02-backend:/app`
- Verificar que `/app/bin` e `/app/obj` estão excluídos

**Frontend (Vue):**
- Verificar volume mount: `../../01-frontend:/app`
- Verificar que `/app/node_modules` está excluído
- Vite dev server deve estar com `--host 0.0.0.0`

### Port already in use

```bash
# Parar serviços conflitantes
docker compose -f 05-infra/docker/docker-compose.yml down

# Ou alterar porta no docker-compose.yml
ports:
  - "5001:8080"  # Usar 5001 ao invés de 5000
```

## CI/CD Integration

### GitHub Actions (GM-00)

O script `deploy.sh` será integrado no workflow de CI/CD:

```yaml
# Exemplo (definido pelo GM)
- name: Deploy to Production
  run: |
    ./05-infra/scripts/deploy.sh production ${{ github.ref_name }}
```

### Docker Registry (GitHub Container Registry)

```bash
# Login
echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin

# Build e Push
docker build -t ghcr.io/seu-usuario/mytrader-api:v1.0.0 -f 05-infra/dockerfiles/backend/Dockerfile .
docker push ghcr.io/seu-usuario/mytrader-api:v1.0.0
```

## Roadmap

### Epic 1 (Concluído - Discovery)
- [x] Docker Compose para todos os ambientes
- [x] Dockerfiles (dev e production)
- [x] Script de deploy básico
- [x] Health checks
- [x] Logging strategy
- [x] Traefik reverse proxy (staging + production)
- [x] HTTPS com Let's Encrypt automático
- [x] Nginx web server (frontend production)

### Epic 2 (Planning)
- [ ] Scripts de backup/restore automatizados
- [ ] Migrations automáticas no deploy
- [ ] S3 integration para backups
- [ ] Monitoring básico (Prometheus/Grafana)
- [ ] Alerting (Alertmanager)

### Epic 3+ (Future - Scalability)
- [ ] Kubernetes migration
- [ ] Auto-scaling (horizontal pod autoscaling)
- [ ] Multi-region deployment
- [ ] Disaster recovery procedures
- [ ] CDN integration (Cloudflare + S3)

## Documentação Relacionada

- **PE-00-Environments-Setup.md:** Estratégia completa de infraestrutura
- **GM-00 (TODO):** CI/CD workflows
- **SEC-00 (TODO):** Security baseline e compliance
- **SDA-02-Context-Map.md:** Arquitetura de Bounded Contexts

## Suporte

Para questões sobre infraestrutura, consultar:
- **PE (Platform Engineer):** Responsável pela definição de stack e ambientes
- **SEC (Security Engineer):** Para questões de segurança
- **GM (Git Master):** Para integração CI/CD

---

**Última atualização:** 2025-10-14
**Fase:** Discovery (Epic 1)
**Status:** ✅ Infraestrutura base definida
