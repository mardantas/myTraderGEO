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
| **Staging** | Pre-production testing | VPS / Cloud | `./deploy.sh staging` | PostgreSQL container |
| **Production** | Live users | VPS / Cloud | `./deploy.sh production` | PostgreSQL container* |

> \*PostgreSQL roda em container via Docker Compose para MVP. Migrar para managed database (AWS RDS / Azure Database / Cloud SQL) quando escalar para Managed Cloud (>10k usuários, conforme seção "Estratégia de Escalabilidade").

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

## 🌐 Network Architecture & Deployment

### Isolated Environments: Separate Servers

**Staging and Production run on SEPARATE servers/IPs:**

```
┌─────────────────────────────────────┐
│   Staging Server (IP: 203.0.113.10) │
├─────────────────────────────────────┤
│ • staging.{DOMAIN}                   │ → Frontend
│ • api.staging.{DOMAIN}               │ → Backend API
│ • traefik.staging.{DOMAIN}           │ → Traefik Dashboard
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Production Server (IP: 203.0.113.20) │
├─────────────────────────────────────┤
│ • {DOMAIN}                            │ → Frontend
│ • api.{DOMAIN}                        │ → Backend API
│ • traefik.{DOMAIN}                    │ → Traefik Dashboard
└─────────────────────────────────────┘
```

### DNS Configuration Required

Point each subdomain to its respective server IP:

**Staging (IP: 203.0.113.10):**
```
staging.mytrader.com          A    203.0.113.10
api.staging.mytrader.com      A    203.0.113.10
traefik.staging.mytrader.com  A    203.0.113.10
```

**Production (IP: 203.0.113.20):**
```
mytrader.com                  A    203.0.113.20
www.mytrader.com              A    203.0.113.20
api.mytrader.com              A    203.0.113.20
traefik.mytrader.com          A    203.0.113.20
```

### Why Separate Servers?

- ✅ **Isolation:** Staging issues don't affect production
- ✅ **Security:** Breach containment (critical for financial apps)
- ✅ **Performance:** Dedicated resources per environment
- ✅ **Compliance:** Separate audit trails and access control
- ✅ **Testing:** Can test deploy process without risk

### Infrastructure Options

**Option 1: Separate VPS (Recommended)**
- Staging: Small VPS ($5-10/month) - DigitalOcean, Hetzner, Vultr
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
- Not suitable for financial/trading applications

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

### Estrutura no Servidor Remoto (Staging/Production)

**Convenção de Diretórios no VPS:**

Os arquivos de configuração e deploy ficam em um diretório dedicado no servidor remoto, separado do código-fonte e com ownership do user `mytrader`.

```
/home/mytrader/mytrader-app/
├── app/                       # Deploy artifacts (docker-compose + configs)
│   ├── docker-compose.yml     # Copiado de 05-infra/docker/docker-compose.{env}.yml
│   ├── .env                   # Secrets (criado manualmente, NÃO versionado no Git)
│   └── configs/
│       └── traefik.yml        # Copiado de 05-infra/configs/traefik.yml
│
├── backups/                   # Database backups (gerados por scripts)
│   └── postgres/
│       ├── 2025-10-28.sql.gz
│       └── 2025-10-27.sql.gz
│
├── scripts/                   # Helper scripts (backup, restore, monitoring)
│   ├── backup-db.sh
│   ├── restore-db.sh
│   └── health-check.sh
│
└── logs/                      # Aggregated logs (opcional, se não usar Docker logs)
    ├── deploy-history.log
    └── app/
```

**Justificativa da Estrutura:**

- ✅ **User dedicado `mytrader`:** Isolamento de segurança (não root, não deploy genérico)
- ✅ **Ownership automático:** Tudo pertence ao user `mytrader:docker`, sem necessidade de `sudo`
- ✅ **Pasta projeto `mytrader-app/`:** Isola tudo do projeto myTraderGEO em uma pasta
- ✅ **Subpasta `app/`:** Contém apenas arquivos de deploy (compose, env, configs)
- ✅ **Escalável:** Permite adicionar `mytrader-monitoring/`, `mytrader-analytics/` no futuro
- ✅ **Named volumes:** PostgreSQL data fica em Docker volumes gerenciados (`/var/lib/docker/volumes/`)

**Mapeamento Repositório → Servidor:**

| Arquivo no Repositório Git | Destino no Servidor | Criado por |
|----------------------------|---------------------|------------|
| `05-infra/docker/docker-compose.staging.yml` | `/home/mytrader/mytrader-app/app/docker-compose.yml` | `deploy.sh` (scp) |
| `05-infra/docker/docker-compose.production.yml` | `/home/mytrader/mytrader-app/app/docker-compose.yml` | `deploy.sh` (scp) |
| `05-infra/configs/traefik.yml` | `/home/mytrader/mytrader-app/app/configs/traefik.yml` | `deploy.sh` (scp) |
| `05-infra/configs/.env.example` | `/home/mytrader/mytrader-app/app/.env` | **Manual** (primeira vez) |
| `05-infra/scripts/backup-database.sh` | `/home/mytrader/mytrader-app/scripts/backup-db.sh` | Manual ou `deploy.sh` |
| `05-infra/scripts/restore-database.sh` | `/home/mytrader/mytrader-app/scripts/restore-db.sh` | Manual ou `deploy.sh` |

**Setup Inicial do Servidor (Primeira Vez):**

Execute estes comandos **uma vez** em cada servidor (staging e production) para preparar a infraestrutura:

```bash
# ===== EXECUTAR NO SERVIDOR VIA SSH (root ou sudo) =====

# 1. Criar user mytrader e adicionar ao grupo docker
sudo useradd -m -s /bin/bash -G docker mytrader
sudo passwd mytrader  # Definir senha forte

# 2. Configurar SSH key para deploy automatizado (CI/CD ou dev machine)
sudo su - mytrader
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Copiar public key (exemplo com ssh-ed25519)
# Opção A: Gerar key no servidor (se não tiver)
# ssh-keygen -t ed25519 -C "deploy@mytrader" -f ~/.ssh/id_ed25519
# Opção B: Copiar public key existente do CI/CD
echo "ssh-ed25519 AAAAC3Nza... deploy@mytrader" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit

# 3. Login como mytrader e criar estrutura de diretórios
sudo su - mytrader
mkdir -p ~/mytrader-app/app/configs
mkdir -p ~/mytrader-app/backups/postgres
mkdir -p ~/mytrader-app/scripts
mkdir -p ~/mytrader-app/logs

# 4. Criar .env inicial (EDITAR COM SECRETS REAIS!)
cat > ~/mytrader-app/app/.env << 'EOF'
# Environment: staging (ou production)
DOMAIN=staging.mytrader.com  # Ajustar conforme ambiente
ACME_EMAIL=admin@mytrader.com

# PostgreSQL (MUDAR SENHA!)
POSTGRES_DB=mytrader
POSTGRES_USER=mytrader
POSTGRES_PASSWORD=CHANGE_ME_STRONG_PASSWORD_HERE

# Traefik Dashboard (gerar com: htpasswd -nb admin password)
TRAEFIK_DASHBOARD_AUTH=admin:$apr1$xyz...
EOF

chmod 600 ~/mytrader-app/app/.env  # Proteger secrets (read-only para owner)

# 5. Verificar estrutura criada
tree ~/mytrader-app/ -L 3
# /home/mytrader/mytrader-app/
# ├── app/
# │   ├── .env
# │   └── configs/
# ├── backups/
# │   └── postgres/
# ├── scripts/
# └── logs/

# 6. Verificar permissions
ls -la ~/mytrader-app/
# drwxr-xr-x mytrader docker mytrader-app/
# drwx------ mytrader docker app/  (apenas owner pode acessar)

exit
```

**Gerar Senha para Traefik Dashboard:**

```bash
# No servidor (ou localmente)
htpasswd -nb admin your_strong_password

# Resultado (copiar para .env):
# admin:$apr1$xyz123abc...
# Adicionar ao .env:
# TRAEFIK_DASHBOARD_AUTH=admin:$apr1$xyz123abc...
```

**Named Volumes (Gerenciados pelo Docker):**

Os dados persistentes (PostgreSQL, SSL certificates) ficam em **Docker named volumes**, gerenciados automaticamente:

```bash
# Localização real no servidor:
/var/lib/docker/volumes/
├── mytrader_postgres_data/    # PostgreSQL database files
├── mytrader_letsencrypt/      # Traefik SSL certificates (acme.json)
└── mytrader_logs/             # Application logs (se configurado)

# Comandos úteis:
docker volume ls                              # Listar todos os volumes
docker volume inspect mytrader_postgres_data  # Ver path real e metadata
docker volume prune                           # Remover volumes não usados (CUIDADO!)
```

**Benefícios desta Convenção:**

1. ✅ **Clareza:** Qualquer desenvolvedor sabe onde estão os arquivos (`~/mytrader-app/app/`)
2. ✅ **Consistência:** Staging e production seguem exatamente a mesma estrutura
3. ✅ **Troubleshooting:** Fácil localizar logs, configs, backups
4. ✅ **Automation:** Scripts de deploy/backup conhecem paths exatos
5. ✅ **Onboarding:** Novos membros do time entendem estrutura rapidamente
6. ✅ **Disaster Recovery:** Backup sabe quais diretórios incluir
7. ✅ **Segurança:** Isolamento por user + permissions Unix padrão

**Deploy Workflow (Resumo):**

```bash
# Local (dev machine):
./05-infra/scripts/deploy.sh staging
# ↓
# Script copia arquivos via SCP:
#   docker-compose.staging.yml → /home/mytrader/mytrader-app/app/docker-compose.yml
#   traefik.yml → /home/mytrader/mytrader-app/app/configs/traefik.yml
# ↓
# Script executa via SSH:
#   cd ~/mytrader-app/app
#   docker compose pull
#   docker compose up -d
```

---

## 🚀 Quick Start

**Para instruções detalhadas de Getting Started, consulte:** [`05-infra/README.md#quick-start`](../../05-infra/README.md#quick-start)  

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
- **Solução:** Manter projeto dentro do filesystem WSL2 (`\\wsl$\Ubuntu\home\user\projects\`)
- **Alternativa:** Se precisar manter em `C:\`, usar named volumes para databases (já configurado)

**Problema: Scripts Bash não executam**
- **Verificar:** Docker Desktop → Settings → General → "Use the WSL 2 based engine"
- **Verificar:** Git Bash instalado (`git --version`)

---

## 🚀 Estratégia de Escalabilidade e Orquestração

### Abordagem Atual: Docker Compose Standalone

**Why Docker Compose (not Swarm/K8s for MVP)?**

- ✅ **Simplicidade:** Comandos simples (`docker compose up`), debugging direto, logs centralizados
- ✅ **Custo:** Um único servidor por ambiente ($30-60/mês total) vs cluster ($150+/mês)
- ✅ **Desenvolvimento Rápido:** Deploy manual aceitável para MVP, sem overhead de orquestração
- ✅ **Adequado para Scale Inicial:** Suporta até 10-50k usuários simultâneos com escalabilidade vertical
- ✅ **Menor Complexidade Operacional:** Time pequeno (1-3 pessoas) consegue gerenciar sem SRE dedicado
- ✅ **Pragmatismo:** YAGNI (You Aren't Gonna Need It) - implementar HA/auto-scaling prematuramente é over-engineering

**Adequado para:**

- 👍 MVP e validação de mercado (primeiros 6-12 meses)
- 👍 Até 10-50k usuários simultâneos (dependendo da carga por requisição)
- 👍 SLA informal de 95-98% (downtime aceitável de alguns minutos para deploys)
- 👍 Orçamento limitado (startup/projeto pessoal)
- 👍 Time pequeno sem experiência em orquestração

**Limitações:**

- ⚠️ **Single-host:** Se servidor cai, aplicação fica indisponível (mitigado com 2 servidores: staging + production separados)
- ⚠️ **Escalabilidade Horizontal Limitada:** Difícil adicionar réplicas de API (possível mas manual)
- ⚠️ **Zero-downtime Deploy:** Difícil implementar (requires blue-green ou rolling deploys manuais)
- ⚠️ **Auto-healing Básico:** Depende apenas de `restart: unless-stopped` (não reconstrói nodes falhados)
- ⚠️ **Load Balancing Manual:** Traefik faz LB entre containers no mesmo host, mas não cross-host

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

---

### Caminhos de Migração

#### Caminho 1: Serviços de Nuvem Gerenciada (Recomendado se houver crescimento)

**Quando:** 10k-50k usuários, SLA 99%+, $10k-100k MRR

**Opções:**

| Provider | Service | Custo | Vantagens | Desvantagens |
|----------|---------|-------|-----------|---------------|
| **AWS** | ECS Fargate | $100-300/mês | Managed, integração AWS, sem nodes | Vendor lock-in, complexidade IAM |
| **Azure** | Container Instances | $80-250/mês | Integração Azure, .NET nativo | Menos features que ECS |
| **Google Cloud** | Cloud Run | $50-200/mês | Mais simples, pay-per-use | Limitações de runtime |
| **DigitalOcean** | App Platform | $60-150/mês | Mais simples, bom custo/benefício | Menos features enterprise |

**Esforço de Migração:** 2-4 semanas (setup, testes, migração de dados, DNS cutover)

**Mudanças Necessárias:**

- ✅ Docker Compose files praticamente idênticos (mínimas adaptações)
- ✅ CI/CD ajustado (deploy via AWS CLI / gcloud / az)
- ✅ Secrets management (AWS Secrets Manager / Azure Key Vault)
- ✅ Database migrado para managed (RDS / Azure Database / Cloud SQL)
- ⚠️ Custos aumentam mas SLA e operação melhoram significativamente

**Benefícios:**

- ✅ Auto-scaling automático (horizontal pod autoscaling)
- ✅ Load balancing nativo
- ✅ Health checks e auto-healing
- ✅ Managed control plane (sem gestão de cluster)
- ✅ Integração nativa com monitoramento (CloudWatch, Azure Monitor, Stackdriver)

---

#### Caminho 2: Docker Swarm (Opcional - Menos Recomendado)

**Quando:** Crescimento moderado mas quer manter self-hosted, team tem experiência Docker

**Requisitos:**

- Cluster mínimo: 3 manager nodes + 2 worker nodes (5 VPS = $100-150/mês)
- Setup: Docker Swarm init + overlay network + shared storage (NFS/GlusterFS)

**Esforço de Migração:** 1-2 semanas (setup cluster, converter compose files, testes)

**Mudanças Necessárias nos Compose Files:**

```yaml
# ❌ Docker Compose (atual)
services:
  api:
    restart: unless-stopped
    container_name: mytrader-api
    depends_on:
      database:
        condition: service_healthy

# ✅ Docker Swarm
services:
  api:
    deploy:
      mode: replicated
      replicas: 3
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      update_config:
        parallelism: 1
        delay: 10s
        order: stop-first
      placement:
        constraints:
          - node.labels.env == production
    # Remove: container_name (Swarm gerencia nomes)
    # Simplify: depends_on (sem conditions)
```

**Principais Incompatibilidades Atuais:**

1. **`restart: unless-stopped`** → Substituir por `deploy.restart_policy`
2. **`container_name:`** → Remover (Swarm gerencia nomes automaticamente)
3. **`depends_on: { condition: service_healthy }`** → Simplificar (Swarm não suporta conditions)
4. **Labels** → Mover de `labels:` para `deploy.labels:` (para Traefik)
5. **Bind mounts relativos** (`../configs/traefik.yml`) → Converter para `configs:` nativo do Swarm ou NFS volume

**Vantagens:**

- ✅ Multi-host nativo do Docker (sem aprender Kubernetes)
- ✅ Rolling updates automáticos (`docker service update`)
- ✅ Service discovery e load balancing nativo
- ✅ Secrets management (`docker secret`)

**Desvantagens:**

- ❌ Comunidade menor que Kubernetes
- ❌ Menos tooling e integrações (vs K8s)
- ❌ Complexidade operacional (gestão de cluster manual)
- ❌ **NÃO recomendado:** Se for orquestração, melhor ir direto para managed cloud ou K8s

**Decisão:** ⚠️ **Swarm é "meio-termo" não recomendado** - se crescer, pular direto para Managed Cloud (Path 1)

---

#### Caminho 3: Kubernetes (Escala Enterprise)

**Quando:** >50k usuários, SLA 99.9%+, $100k+ MRR, multi-região necessária

**Opções:**

| Provider | Service | Custo | Recomendação |
|----------|---------|-------|--------------|
| **AWS** | EKS | $500-2000/mês | Melhor integração AWS, maduro |
| **Azure** | AKS | $400-1800/mês | Melhor integração Azure, .NET nativo |
| **Google Cloud** | GKE | $400-1500/mês | Melhor Kubernetes experience, Google expertise |
| **DigitalOcean** | DOKS | $300-1000/mês | Mais simples, menor custo |

**Esforço de Migração:** 2-3 meses (conversão para Helm charts, CI/CD, observability, treinamento)

**Mudanças Necessárias:**

- 🔄 Converter Docker Compose para Kubernetes manifests (YAML) ou Helm charts
- 🔄 Implementar Ingress Controller (Traefik/Nginx Ingress/Istio)
- 🔄 ConfigMaps e Secrets para configuração
- 🔄 Persistent Volumes para databases (ou migrar para managed DB)
- 🔄 HPA (Horizontal Pod Autoscaler) para auto-scaling
- 🔄 Service Mesh (Istio/Linkerd) para observability avançada

**Benefícios:**

- ✅ Auto-scaling avançado (HPA, VPA, Cluster Autoscaler)
- ✅ Multi-região e multi-cloud nativo
- ✅ Ecosystem rico (Helm, Operators, Service Mesh)
- ✅ Rolling updates zero-downtime nativos
- ✅ Self-healing robusto
- ✅ GitOps (ArgoCD, Flux) para declarative deployments

**Desvantagens:**

- ❌ **Complexidade extrema** (curva de aprendizado íngreme)
- ❌ **Requer SRE team** (gestão de cluster, troubleshooting, upgrades)
- ❌ **Custo alto** (nodes + control plane + tooling)

**Decisão:** ✅ **Kubernetes é a escolha para scale enterprise** (mas apenas quando realmente necessário)

---

### Resumo da Recomendação

**Estratégia Recomendada (Phased Approach):**

```
Phase 1: MVP (Atual)
├─ Docker Compose standalone
├─ 2 VPS (staging + production)
├─ $30-60/mês
└─ ✅ MANTER até 10k usuários

Phase 2: Growth (Se crescer)
├─ AWS ECS / Cloud Run / Azure Container Instances
├─ Managed services (RDS, CloudWatch, Secrets Manager)
├─ $100-300/mês
└─ ✅ MIGRAR quando: >10k usuários OU SLA 99%+ necessário

Phase 3: Scale (Se explodir)
├─ Kubernetes (EKS/GKE/AKS)
├─ Multi-região, service mesh, GitOps
├─ $500+/mês + SRE team
└─ ✅ MIGRAR quando: >50k usuários OU $100k+ MRR
```

**Princípio:** **Start simple, scale when needed** (não fazer over-engineering prematuro)

---

### Referência de Compatibilidade: Docker Compose → Swarm

**Se no futuro decidir migrar para Swarm, estas são as incompatibilidades atuais:**

| Docker Compose (Atual) | Docker Swarm | Esforço |
|------------------------|--------------|---------|
| `restart: unless-stopped` | `deploy.restart_policy.condition: on-failure` | Fácil (buscar/substituir) |
| `container_name: foo` | ❌ Remover (Swarm gerencia) | Fácil |
| `depends_on: { condition: ... }` | Simplificar ou remover | Médio |
| `labels: [...]` | `deploy.labels: [...]` (Traefik) | Fácil |
| Bind mounts relativos | `configs:` ou NFS volume | Médio |
| `version: '3.8'` | `version: '3.8'` (compatível) | N/A |

**Tempo estimado para conversão:** 4-8 horas (assumindo conhecimento de Swarm)
**Tempo estimado para setup cluster:** 1-2 dias (3 managers + 2 workers + NFS + testes)

**Referência:** [Docker Compose → Swarm migration guide](https://docs.docker.com/engine/swarm/stack-deploy/)

---

**Decisão Final (FEEDBACK-007):** ✅ **MANTER Docker Compose** para MVP, documentar path de migração futuro conforme thresholds atingidos

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
