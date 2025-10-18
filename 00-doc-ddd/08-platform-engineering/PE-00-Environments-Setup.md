# PE-00 - Environments Setup

**Agent:** PE (Platform Engineer)
**Phase:** Discovery (1x)
**Scope:** Basic environments with Docker Compose and deploy scripts
**Version:** 1.0
**Date:** 2025-10-14

---

## 📋 Metadata

- **Project Name:** myTraderGEO
- **Created:** 2025-10-14
- **PE Engineer:** PE Agent
- **Target:** Small/Medium Trading Platform
- **Approach:** Docker Compose + Scripts (NOT full IaC)
- **Complexity:** Medium (3 Core Domains + Real-time requirements)

---

## 🎯 Objetivo

Configurar ambientes básicos (dev, staging, production) com Docker Compose e scripts de deploy simples para a plataforma de trading myTraderGEO.

**Filosofia:** Pragmatic infrastructure - essencial para começar desenvolvimento rapidamente e deploy incremental por épico.

---

## 📊 Stack Tecnológico Definido

### Backend: .NET 8 (C#)

**Justificativa:**
- ✅ **Performance:** Excelente para cálculos financeiros complexos (gregas, margem B3, P&L)
- ✅ **Precisão Financeira:** Tipo `decimal` nativo (128-bit) - essencial para dinheiro
- ✅ **DDD Support:** Entity Framework Core com suporte a Aggregates, Value Objects, Domain Events
- ✅ **Real-time:** SignalR para WebSocket (market data streaming, P&L updates)
- ✅ **Tipagem Forte:** C# para domínio rico com invariantes complexas
- ✅ **Async/Await:** Nativo para integrações externas (B3 API, Market Data)
- ✅ **Logging Estruturado:** Serilog para auditoria (LGPD compliance)
- ✅ **Ecosystem:** Maduro para aplicações financeiras

**Decisões Técnicas:**
- **Runtime:** .NET 8 LTS (suporte até 2026)
- **Web Framework:** ASP.NET Core Minimal APIs + Controllers
- **ORM:** Entity Framework Core 8 (Code-First, Migrations)
- **Real-time:** SignalR (WebSocket com fallback)
- **Logging:** Serilog (structured logging)
- **Testing:** xUnit + Moq + FluentAssertions (conforme QAE-00)

---

### Frontend: Vue 3 + TypeScript + Vite

**Justificativa:**
- ✅ **Reatividade Nativa:** Proxy-based reactivity IDEAL para trading (P&L, preços atualizando em tempo real)
- ✅ **Performance:** Virtual DOM otimizado + bundle size menor que React
- ✅ **TypeScript:** Suporte nativo via `<script setup lang="ts">` - segurança de tipos
- ✅ **Vite:** Build tool moderno (HMR instantâneo, build rápido)
- ✅ **Developer Experience:** Curva de aprendizado menor, sintaxe clara
- ✅ **Single File Components:** Organização clara (.vue files)
- ✅ **Design System:** Scoped CSS nativo, Tailwind CSS integration
- ✅ **Real-time:** Socket.io / SignalR client fácil integração

**Decisões Técnicas:**
- **Framework:** Vue 3.3+ (Composition API)
- **Build Tool:** Vite 5+
- **Language:** TypeScript 5+
- **State Management:** Pinia (oficial, successor do Vuex)
- **Router:** Vue Router 4
- **HTTP Client:** Axios
- **Real-time:** Socket.io-client / @microsoft/signalr
- **UI Components:** PrimeVue (enterprise-ready components)
- **Charts:** ECharts (gráficos financeiros avançados)
- **Testing:** Vitest + Vue Test Utils + Playwright (conforme QAE-00)

---

### Database: PostgreSQL 15

**Justificativa:**
- ✅ **ACID Completo:** Transações financeiras requerem consistência forte
- ✅ **JSON Support:** Flexibilidade para estratégias complexas (JSONB)
- ✅ **Performance:** Índices avançados (B-tree, GiST, GIN), particionamento
- ✅ **Auditoria:** Triggers, row-level security para LGPD
- ✅ **Open-source:** Sem lock-in, comunidade madura
- ✅ **Extensions:** pg_stat_statements (performance monitoring)
- ✅ **Backup/Recovery:** pg_dump, PITR (Point-in-Time Recovery)

**Decisões Técnicas:**
- **Versão:** PostgreSQL 15 (Alpine image para produção)
- **Connection Pooling:** PgBouncer (se necessário)
- **Backup Strategy:** pg_dump diário + WAL archiving
- **Migrations:** Entity Framework Core Migrations

---

## 🏗️ Environments Overview

### Environment Strategy

| Environment | Purpose | Infrastructure | Deploy Method | Database |
|-------------|---------|----------------|---------------|----------|
| **Development** | Local development | Docker Compose (localhost) | `docker compose up` | PostgreSQL container |
| **Staging** | Pre-production testing | VPS / Cloud | `./deploy.sh staging` | PostgreSQL managed/container |
| **Production** | Live users | VPS / Cloud | `./deploy.sh production` | PostgreSQL managed |

### Hosting Strategy

**Selected Approach:** Single VPS (inicialmente) com migração futura para Cloud

**Justificativa:**
- ✅ **Custo-benefício** para MVP e primeiros épicos
- ✅ **Simplicidade** de deploy (Docker Compose)
- ✅ **Escalabilidade** vertical suficiente para início
- 🔄 **Migração futura:** AWS ECS / Azure Container Instances quando necessário

**Providers Recomendados:**
- Contabo (Europa) - €7-15/mês
- DigitalOcean Droplet - $12-24/mês
- Hetzner (Europa) - €5-20/mês
- Linode - $12-24/mês

---

## 🏗️ Infraestrutura Física

**Todos os arquivos de configuração e scripts estão implementados em:** [`05-infra/`](../../05-infra/)

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
│       ├── Dockerfile                # Production (Vue build + Nginx)
│       ├── Dockerfile.dev            # Development (Vite dev server)
│       └── nginx.conf                # SPA routing + security headers
├── configs/
│   ├── traefik.yml                   # Traefik static configuration
│   └── .env.example                  # Environment variables template
├── scripts/
│   ├── deploy.sh                     # Deployment automation
│   ├── backup-database.sh            # Database backup (TODO - Epic 2+)
│   └── restore-database.sh           # Database restore (TODO - Epic 2+)
└── README.md                         # Infrastructure guide
```

### Arquivos de Configuração

| Arquivo | Descrição | Documentação |
|---------|-----------|--------------|
| [`05-infra/docker/docker-compose.yml`](../../05-infra/docker/docker-compose.yml) | Ambiente local (dev) com hot reload | Ver arquivo |
| [`05-infra/docker/docker-compose.staging.yml`](../../05-infra/docker/docker-compose.staging.yml) | Staging com Traefik + Let's Encrypt | Ver arquivo |
| [`05-infra/docker/docker-compose.production.yml`](../../05-infra/docker/docker-compose.production.yml) | Production com resource limits + Traefik | Ver arquivo |
| [`05-infra/configs/traefik.yml`](../../05-infra/configs/traefik.yml) | Reverse proxy + SSL automático | Ver arquivo |
| [`05-infra/configs/.env.example`](../../05-infra/configs/.env.example) | Template de variáveis de ambiente | Ver arquivo |
| [`05-infra/scripts/deploy.sh`](../../05-infra/scripts/deploy.sh) | Script de deployment bash | Ver arquivo |
| [`05-infra/README.md`](../../05-infra/README.md) | 📖 **Guia completo de uso** | Ver arquivo |

**📖 Para detalhes completos de configuração, consulte:** [`05-infra/README.md`](../../05-infra/README.md)

---

## 🚀 Quick Start

**Para instruções detalhadas de Getting Started, consulte:** [`05-infra/README.md#quick-start`](../../05-infra/README.md#quick-start)

### Desenvolvimento Local (Resumo)

```bash
# 1. Configurar environment
cp 05-infra/configs/.env.example 05-infra/configs/.env

# 2. Iniciar serviços
docker compose -f 05-infra/docker/docker-compose.yml up -d

# 3. Verificar saúde
docker compose -f 05-infra/docker/docker-compose.yml ps
```

**Acessos:**
- Frontend (Vue + Vite): http://localhost:5173
- Backend API (.NET): http://localhost:5000
- Database (PostgreSQL): localhost:5432

### Deploy para Staging/Production

```bash
# Deploy staging
./05-infra/scripts/deploy.sh staging

# Deploy production (com confirmação)
./05-infra/scripts/deploy.sh production v1.0.0
```

---

## 📊 Monitoring & Logging

**Para detalhes completos, consulte:** [`05-infra/README.md#logging`](../../05-infra/README.md#logging)

### Logging Strategy (Resumo)

| Environment | Level | Output | Retention |
|-------------|-------|--------|-----------|
| Development | Information | Console (stdout) | N/A |
| Staging | Information | Console + File | 3 files x 10MB |
| Production | Warning | Console + File | 5 files x 10MB |

### Health Checks

- **Backend:** `GET /health` → JSON status (database, services)
- **Frontend:** `GET /health` → "healthy" (Nginx)
- **Traefik:** Dashboard em `https://traefik.${DOMAIN}`

---

## 🔒 HTTPS & SSL

### Arquitetura de Rede (Production)

```
Internet
   ↓
Cloudflare (DNS + DDoS Protection + CDN)
   ↓ HTTPS (Full/Strict SSL mode)
Contabo VPS / Cloud Server
   ↓
Traefik v3.0 (Reverse Proxy + Let's Encrypt)
   ↓
   ├─→ Frontend Container (Nginx:80 interno)
   ├─→ API Container (.NET 8:8080 interno)
   └─→ Database Container (PostgreSQL:5432 - apenas rede interna)
```

### Traefik + Let's Encrypt (Automático)

**Implementado:** `05-infra/configs/traefik.yml` + Docker Compose labels

**Funcionalidades:**
- ✅ HTTP → HTTPS redirect automático
- ✅ Let's Encrypt SSL certificates (renovação automática)
- ✅ Service discovery via Docker labels
- ✅ Rate limiting configurado (API: 100 req/s)
- ✅ Dashboard protegido com Basic Auth
- ✅ WebSocket support (SignalR)

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

**DNS Records (apontar para IP do servidor Contabo):**

| Type | Name | Target | Proxy |
|------|------|--------|-------|
| A | @ | IP_SERVIDOR | ✅ Proxied |
| A | api | IP_SERVIDOR | ✅ Proxied |
| A | staging | IP_SERVIDOR | ✅ Proxied |
| A | api.staging | IP_SERVIDOR | ✅ Proxied |
| A | traefik | IP_SERVIDOR | ⚠️ DNS Only |

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

**Acesso:** `https://traefik.${DOMAIN}` (exemplo: traefik.mytrader.com)

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

## ✅ PE Definition of Done Checklist

### Infrastructure
- [x] Stack tecnológico definido (.NET 8 + Vue 3 + PostgreSQL 15)
- [x] Docker Compose criado para dev/staging/production
- [x] Dockerfiles criados (backend dev/prod, frontend dev/prod)
- [x] Database configurado (PostgreSQL 15 container)
- [x] Nginx configurado (frontend production - interno ao container)
- [x] Traefik configurado (reverse proxy + SSL automático)

### Deployment
- [x] Deploy script criado (`05-infra/scripts/deploy.sh`)
- [x] Backup script documentado (implementação Epic 2+)
- [x] Restore script documentado (implementação Epic 2+)
- [x] `.env.example` criado com todas variáveis (incluindo Traefik)

### Networking & Security
- [x] Traefik v3.0 integrado (production + staging)
- [x] Let's Encrypt SSL automático configurado
- [x] Cloudflare + Traefik architecture documentado
- [x] Rate limiting configurado (API: 100 req/s)
- [x] Dashboard protegido (Basic Auth)
- [x] Secrets management configurado (environment variables)
- [x] Health checks configurados (backend + frontend)

### Logging & Monitoring
- [x] Logging básico documentado (Serilog + Docker logs)
- [x] Health checks endpoints documentados
- [x] Traefik logs configurados

### Documentation
- [x] PE-00-Environments-Setup.md criado
- [x] Deploy process documentado
- [x] Traefik architecture documentado
- [x] Cloudflare configuration documentado
- [x] Getting started guide documentado
- [x] Stack tecnológico justificado
- [x] 05-infra/README.md criado

### Physical Files Created
- [x] `05-infra/docker/docker-compose.yml` (development)
- [x] `05-infra/docker/docker-compose.staging.yml` (staging + Traefik)
- [x] `05-infra/docker/docker-compose.production.yml` (production + Traefik)
- [x] `05-infra/dockerfiles/backend/Dockerfile.dev`
- [x] `05-infra/dockerfiles/backend/Dockerfile`
- [x] `05-infra/dockerfiles/frontend/Dockerfile.dev`
- [x] `05-infra/dockerfiles/frontend/Dockerfile`
- [x] `05-infra/dockerfiles/frontend/nginx.conf`
- [x] `05-infra/configs/traefik.yml`
- [x] `05-infra/configs/.env.example`
- [x] `05-infra/scripts/deploy.sh`
- [x] `05-infra/README.md`
- [x] `.gitignore`

### Validation (Pending Implementation Phase)
- [ ] DE/FE podem começar desenvolvimento (environments prontos)
- [ ] Deploy de "Hello World" testado em staging
- [ ] Database connection testada
- [ ] Health checks funcionando
- [ ] Traefik SSL certificates gerados

---

## 🎯 Próximos Passos (Após PE-00)

**Agora que o stack está definido, os próximos agentes podem executar:**

1. ✅ **GM (GitHub Manager)** - Configurar CI/CD baseado em:
   - Backend: .NET 8 (dotnet build, dotnet test, dotnet publish)
   - Frontend: Vue 3 (npm run build, npm run test)
   - Docker build para staging/production

2. ✅ **SEC (Security Specialist)** - Escolher ferramentas compatíveis:
   - .NET: Snyk, SonarQube, OWASP Dependency Check
   - Vue: npm audit, Snyk
   - OWASP ZAP para testes de segurança

3. ✅ **QAE (Quality Assurance Engineer)** - Definir ferramentas de teste:
   - Backend: xUnit + Moq + FluentAssertions
   - Frontend: Vitest + Vue Test Utils + Playwright
   - Integration: TestContainers (PostgreSQL)

---

**PE-00 Status:** ✅ **COMPLETO**
**Stack Definido:** .NET 8 + Vue 3 + TypeScript + PostgreSQL 15
**Ambientes:** Docker Compose (dev/staging/production)
**Deploy:** Scripts bash (semi-automatizado)
**Próximo:** GM-00, SEC-00, QAE-00 podem executar em paralelo
