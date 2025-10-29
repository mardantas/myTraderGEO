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

## 🖥️ Server Setup Documentation

### Overview

This section documents the **8-step process** for setting up staging and production servers from scratch.

**Target:** Linux server (Ubuntu 22.04 LTS or Debian 12)
**Time:** ~30 minutes per server
**Security Focus:** UFW firewall, fail2ban, SSH key-based auth, NTP time sync

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

**Why:** Clear identification of servers in logs and monitoring.

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

**Expected output:**
```
Status: active

To                         Action      From
--                         ------      ----
[ 1] 22/tcp                ALLOW IN    Anywhere
[ 2] 80/tcp                ALLOW IN    Anywhere
[ 3] 443/tcp               ALLOW IN    Anywhere
```

### Step 4: Install and Configure fail2ban (SSH Protection)

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

**Why:** Protects against SSH brute-force attacks (OWASP, CIS benchmarks).

### Step 5: Create Dedicated User and Group

```bash
# Create group and user (NOT root for least privilege)
sudo groupadd [project]_app
sudo useradd -m -s /bin/bash -g [project]_app -G docker [project]_app

# Verify user
id [project]_app
# Expected: uid=1001([project]_app) gid=1001([project]_app) groups=1001([project]_app),999(docker)

# Set up SSH key for user
sudo mkdir -p /home/[project]_app/.ssh
sudo tee /home/[project]_app/.ssh/authorized_keys <<EOF
[PASTE YOUR PUBLIC SSH KEY HERE]
EOF
sudo chmod 700 /home/[project]_app/.ssh
sudo chmod 600 /home/[project]_app/.ssh/authorized_keys
sudo chown -R [project]_app:[project]_app /home/[project]_app/.ssh
```

**Security Rationale:**
- ✅ **Least Privilege**: User has minimal permissions
- ✅ **Defense in Depth**: Even if app is compromised, user can't access other services
- ✅ **Docker Access**: Secondary group `docker` allows container management
- ❌ **NOT root**: Limits damage if account is compromised

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

# Check chrony sources
chronyc sources -v
```

**Why:** Accurate time is critical for:
- ✅ Audit logs (compliance: LGPD Art. 46, SOC2, ISO 27001)
- ✅ TLS certificate validation
- ✅ Database timestamps and distributed systems

### Step 8: Create Project Directory Structure

```bash
# Switch to dedicated user
sudo su - [project]_app

# Create directory structure
mkdir -p ~/[project]/
mkdir -p ~/[project]/configs
mkdir -p ~/[project]/logs
mkdir -p ~/[project]/backups

# Clone repository (or SCP files from CI/CD)
cd ~/[project]
git clone https://github.com/[YOUR_ORG]/[project].git .

# Create .env files (DO NOT commit to Git!)
cp .env.example .env.staging   # For staging server
cp .env.example .env.production # For production server

# Edit .env with real secrets
nano .env.staging   # or .env.production
```

**Expected structure:**
```
/home/[project]_app/[project]/
├── .env.staging (or .env.production)
├── .env.example
├── docker-compose.staging.yml (or docker-compose.production.yml)
├── 05-infra/configs/traefik.yml
├── configs/
├── logs/
└── backups/
```

### Step 9: Verify Server Setup

```bash
# Checklist
echo "1. Hostname: $(hostname)"
echo "2. Docker: $(docker --version)"
echo "3. Docker Compose: $(docker compose version)"
echo "4. UFW Status: $(sudo ufw status | grep Status)"
echo "5. fail2ban Status: $(sudo systemctl is-active fail2ban)"
echo "6. User: $(id [project]_app)"
echo "7. SSH Key: $(test -f ~/.ssh/authorized_keys && echo 'OK' || echo 'MISSING')"
echo "8. NTP Sync: $(timedatectl | grep 'System clock synchronized' | awk '{print $4}')"
echo "9. Directory: $(test -d ~/[project] && echo 'OK' || echo 'MISSING')"
echo "10. .env file: $(test -f ~/[project]/.env.staging && echo 'OK' || echo 'MISSING')"
```

**Expected output:**
```
1. Hostname: [project]-stage (or [project]-prod)
2. Docker: Docker version 24.0.7
3. Docker Compose: Docker Compose version v2.23.0
4. UFW Status: Status: active
5. fail2ban Status: active
6. User: uid=1001([project]_app) gid=1001([project]_app) groups=1001([project]_app),999(docker)
7. SSH Key: OK
8. NTP Sync: yes
9. Directory: OK
10. .env file: OK
```

### Server Setup Complete!

✅ Server is now hardened and ready for remote deployment via `deploy.sh` script.

---

## 📈 Scaling Strategy

### Decision Matrix

**When to scale?** Use this matrix to decide when to move from simple Docker Compose to more complex infrastructure.

| Users | Uptime SLA | Cost Budget | Infrastructure Recommendation |
|-------|-----------|-------------|-------------------------------|
| <1k | 95% | Low ($50-200/mo) | **Single VPS + Docker Compose** (current setup) |
| 1k-10k | 99% | Medium ($200-1k/mo) | **Managed Cloud (AWS ECS, Azure Container Instances)** |
| 10k-50k | 99.9% | High ($1k-5k/mo) | **Kubernetes (EKS, AKS, GKE)** |
| >50k | 99.95%+ | Very High (>$5k/mo) | **Full Enterprise Stack (K8s + Multi-Region + CDN)** |

### Migration Path 1: Managed Cloud (RECOMMENDED for 1k-10k users)

**Target:** AWS ECS Fargate, Azure Container Instances, or Google Cloud Run
**Timeline:** 1-2 weeks
**Complexity:** Low

**Migration Steps:**

1. **Containerize** (already done via Docker Compose)
2. **Push images to cloud registry** (AWS ECR, Azure ACR, Google Container Registry)
3. **Create managed database** (AWS RDS, Azure Database for PostgreSQL, Google Cloud SQL)
4. **Deploy containers to managed service**:
   - AWS: ECS Fargate with Application Load Balancer
   - Azure: Container Instances with Application Gateway
   - GCP: Cloud Run with Cloud Load Balancing
5. **Configure auto-scaling** (CPU/memory-based)
6. **Set up CloudWatch/Azure Monitor/Cloud Logging**

**Benefits:**
- ✅ No server management (fully managed)
- ✅ Auto-scaling out of the box
- ✅ Built-in load balancing
- ✅ Pay-per-use pricing
- ✅ 99.9% SLA guaranteed

**Example: AWS ECS Fargate**

```yaml
# ecs-task-definition.json (simplified)
{
  "family": "[project]-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "api",
      "image": "[AWS_ACCOUNT_ID].dkr.ecr.[REGION].amazonaws.com/[project]-api:latest",
      "portMappings": [{"containerPort": 5000, "protocol": "tcp"}],
      "environment": [
        {"name": "ASPNETCORE_ENVIRONMENT", "value": "Production"},
        {"name": "DATABASE_URL", "value": "postgresql://..."}
      ]
    }
  ]
}
```

### Migration Path 2: Docker Swarm (SKIP - Not Recommended)

**Status:** ❌ **Skip this option**

**Why?**
- Docker Swarm has limited adoption and ecosystem
- Managed cloud services (ECS, AKS) provide better features and support
- Kubernetes is the industry standard for container orchestration

**When to use Swarm?**
- Only if you have specific constraints (e.g., air-gapped environment, government restrictions on cloud providers)

### Migration Path 3: Kubernetes (For Enterprise Scale)

**Target:** AWS EKS, Azure AKS, Google GKE
**Timeline:** 4-8 weeks
**Complexity:** High

**When to migrate?**
- ✅ >10k active users
- ✅ Need for multi-region deployment
- ✅ Complex microservices architecture (5+ services)
- ✅ Enterprise SLA requirements (99.9%+)
- ✅ Team has K8s expertise (or budget to hire)

**Migration Steps:**

1. **Set up K8s cluster** (EKS, AKS, GKE with managed node pools)
2. **Create Helm charts** for application deployment
3. **Migrate database to managed service** (AWS RDS, Azure Database, Cloud SQL)
4. **Set up Ingress controller** (NGINX, Traefik, AWS ALB)
5. **Configure autoscaling** (HPA for pods, Cluster Autoscaler for nodes)
6. **Implement observability** (Prometheus, Grafana, Jaeger, Loki)
7. **Set up CI/CD** (ArgoCD for GitOps, Flux)
8. **Configure Disaster Recovery** (Velero for backups, multi-region replication)

**Benefits:**
- ✅ Industry standard (massive ecosystem)
- ✅ Multi-cloud portability
- ✅ Advanced deployment strategies (blue-green, canary)
- ✅ Horizontal pod autoscaling
- ✅ Service mesh support (Istio, Linkerd)

**Example: Kubernetes Deployment**

```yaml
# k8s/api-deployment.yaml (simplified)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: [REGISTRY]/[project]-api:latest
        ports:
        - containerPort: 5000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Cost Comparison

| Infrastructure | Monthly Cost | Users Supported | SLA | Management Overhead |
|----------------|-------------|-----------------|-----|---------------------|
| **Single VPS (current)** | $50-200 | <1k | 95% | Low (1-2 hrs/week) |
| **Managed Cloud (ECS/AKS)** | $200-1k | 1k-10k | 99.9% | Very Low (<1 hr/week) |
| **Kubernetes (EKS/AKS/GKE)** | $1k-5k | 10k-50k | 99.95% | Medium (4-8 hrs/week) |

### Recommendation

**For most small/medium projects:**

1. **Start with Docker Compose on VPS** (v1.0 - current setup)
   - Get to market fast
   - Validate product-market fit
   - Keep costs low (<$200/mo)

2. **Scale to Managed Cloud when you hit 1k users**
   - AWS ECS Fargate (recommended for .NET apps)
   - Azure Container Instances (if already on Azure)
   - Google Cloud Run (best for serverless workloads)

3. **Only move to Kubernetes if you reach 10k+ users AND have team expertise**
   - Don't migrate prematurely (YAGNI principle)
   - K8s adds significant complexity

**Skip Docker Swarm entirely** - go straight from Compose to Managed Cloud or K8s.

---

## 📜 Remote Deployment Architecture

### Overview

This section documents the **remote deployment strategy** using SSH/SCP for file transfer and remote command execution.

**Key Concept:** Deploy script detects environment automatically:
- **Development:** Local deployment (docker-compose up)
- **Staging/Production:** Remote deployment (SSH/SCP to [project]-stage or [project]-prod servers)

### Remote Deployment Flow

```
┌─────────────────┐
│  Local Machine  │
│  (CI/CD or Dev) │
└────────┬────────┘
         │
         │ 1. check_ssh_connection()
         ├──────────────────────────────┐
         │                              ▼
         │                     ┌─────────────────┐
         │                     │  Remote Server  │
         │                     │  [project]-stage│
         │                     └─────────────────┘
         │
         │ 2. SCP files to remote
         ├──────────────────────────────▶
         │
         │ 3. SSH: docker-compose up -d
         ├──────────────────────────────▶
         │
         │ 4. remote_health_check() (HTTPS with retry 30x5s)
         ├──────────────────────────────▶
         │                              │
         │ 5. log_deployment_history()  │
         ◀──────────────────────────────┘
```

### Deploy Script Functions

**6 main functions:**

1. **check_ssh_connection()** - Validates SSH connectivity before remote deploy
2. **remote_backup_database()** - Placeholder for remote database backup
3. **remote_health_check()** - HTTPS health check with retry logic (30 attempts, 5s interval)
4. **log_deployment_history()** - Logs deployment to local file
5. **deploy_remote()** - Main remote deployment function (SSH/SCP)
6. **main()** - Detects environment (development=local, staging/production=remote)

### deploy.sh (Complete with Remote Deployment)

**Location:** Project root

```bash
#!/bin/bash

# deploy.sh - Deployment script with local/remote detection
# Usage: ./deploy.sh [development|staging|production] [version]
#
# Examples:
#   ./deploy.sh development           # Local deployment
#   ./deploy.sh staging latest        # Remote deployment to staging
#   ./deploy.sh production v1.2.3     # Remote deployment to production

set -e

ENVIRONMENT=$1
VERSION=${2:-"latest"}
DEPLOY_LOG="deployments.log"

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#############################################
# Function: check_ssh_connection
# Description: Validates SSH connectivity before remote deploy
#############################################
check_ssh_connection() {
    local SERVER_HOST=$1
    local SSH_USER=$2

    echo -e "${YELLOW}🔑 Checking SSH connection to $SERVER_HOST...${NC}"

    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$SSH_USER@$SERVER_HOST" "exit" 2>/dev/null; then
        echo -e "${GREEN}✅ SSH connection successful${NC}"
        return 0
    else
        echo -e "${RED}❌ SSH connection failed to $SSH_USER@$SERVER_HOST${NC}"
        echo -e "${RED}Please ensure SSH keys are configured and server is reachable${NC}"
        return 1
    fi
}

#############################################
# Function: remote_backup_database
# Description: Placeholder for remote database backup
#############################################
remote_backup_database() {
    local SERVER_HOST=$1
    local SSH_USER=$2
    local ENV=$3

    echo -e "${YELLOW}💾 Backing up remote database on $SERVER_HOST...${NC}"

    ssh "$SSH_USER@$SERVER_HOST" << 'EOF'
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_DIR="~/[project]/backups"
        mkdir -p "$BACKUP_DIR"

        # Backup database (adjust based on your setup)
        docker compose -f ~/[project]/docker-compose.$ENV.yml \
            --env-file ~/[project]/.env.$ENV \
            exec -T database pg_dump -U $DB_USER $DB_NAME > "$BACKUP_DIR/db_${TIMESTAMP}.sql"

        echo "✅ Backup saved to $BACKUP_DIR/db_${TIMESTAMP}.sql"

        # Keep only last 7 backups
        ls -t "$BACKUP_DIR"/db_*.sql | tail -n +8 | xargs rm -f
EOF

    echo -e "${GREEN}✅ Database backup completed${NC}"
}

#############################################
# Function: remote_health_check
# Description: HTTPS health check with retry logic (30 attempts, 5s interval)
#############################################
remote_health_check() {
    local HEALTH_URL=$1
    local MAX_ATTEMPTS=30
    local SLEEP_INTERVAL=5

    echo -e "${YELLOW}🏥 Running health checks on $HEALTH_URL...${NC}"

    for ((i=1; i<=MAX_ATTEMPTS; i++)); do
        HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$HEALTH_URL" 2>/dev/null || echo "000")

        if [ "$HEALTH_STATUS" -eq 200 ]; then
            echo -e "${GREEN}✅ Health check passed (HTTP $HEALTH_STATUS) after $i attempts${NC}"
            return 0
        else
            echo -e "${YELLOW}⏳ Attempt $i/$MAX_ATTEMPTS: Health check returned HTTP $HEALTH_STATUS. Retrying in ${SLEEP_INTERVAL}s...${NC}"
            sleep "$SLEEP_INTERVAL"
        fi
    done

    echo -e "${RED}❌ Health check failed after $MAX_ATTEMPTS attempts${NC}"
    return 1
}

#############################################
# Function: log_deployment_history
# Description: Logs deployment to local file
#############################################
log_deployment_history() {
    local ENV=$1
    local VER=$2
    local STATUS=$3
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$TIMESTAMP | Environment: $ENV | Version: $VER | Status: $STATUS" >> "$DEPLOY_LOG"
    echo -e "${GREEN}📝 Deployment logged to $DEPLOY_LOG${NC}"
}

#############################################
# Function: deploy_remote
# Description: Main remote deployment function (SSH/SCP)
#############################################
deploy_remote() {
    local ENV=$1
    local VER=$2

    # Server configuration (adjust hostnames based on your setup)
    if [ "$ENV" = "staging" ]; then
        SERVER_HOST="[project]-stage"
    elif [ "$ENV" = "production" ]; then
        SERVER_HOST="[project]-prod"
    else
        echo -e "${RED}❌ Invalid environment for remote deploy: $ENV${NC}"
        exit 1
    fi

    SSH_USER="[project]_app"
    REMOTE_DIR="/home/$SSH_USER/[project]"

    echo -e "${GREEN}🚀 Starting REMOTE deployment to $ENV ($SERVER_HOST)...${NC}"

    # Step 1: Check SSH connectivity
    if ! check_ssh_connection "$SERVER_HOST" "$SSH_USER"; then
        log_deployment_history "$ENV" "$VER" "FAILED_SSH"
        exit 1
    fi

    # Step 2: Optional - Backup database before deploy
    # Uncomment if you want automatic backups before each deployment
    # remote_backup_database "$SERVER_HOST" "$SSH_USER" "$ENV"

    # Step 3: Copy files to remote server
    echo -e "${YELLOW}📦 Copying files to $SERVER_HOST...${NC}"

    # Copy docker-compose file
    scp "docker-compose.$ENV.yml" "$SSH_USER@$SERVER_HOST:$REMOTE_DIR/docker-compose.$ENV.yml"

    # Copy configs (if any changes)
    scp -r "05-infra/configs/" "$SSH_USER@$SERVER_HOST:$REMOTE_DIR/05-infra/"

    # Copy .env file (if needed - CAREFUL with secrets!)
    # scp ".env.$ENV" "$SSH_USER@$SERVER_HOST:$REMOTE_DIR/.env.$ENV"

    echo -e "${GREEN}✅ Files copied successfully${NC}"

    # Step 4: Execute deployment on remote server
    echo -e "${YELLOW}🚢 Deploying containers on $SERVER_HOST...${NC}"

    ssh "$SSH_USER@$SERVER_HOST" << EOF
        cd "$REMOTE_DIR"

        # Pull latest images (if using registry)
        # docker compose -f docker-compose.$ENV.yml --env-file .env.$ENV pull

        # Stop containers
        docker compose -f docker-compose.$ENV.yml --env-file .env.$ENV down

        # Start containers with new version
        docker compose -f docker-compose.$ENV.yml --env-file .env.$ENV up -d

        # Run migrations (adjust based on your tech stack)
        # docker compose -f docker-compose.$ENV.yml --env-file .env.$ENV exec -T api dotnet ef database update

        echo "✅ Containers started successfully"
EOF

    # Step 5: Health check with retry
    if [ "$ENV" = "staging" ]; then
        HEALTH_URL="https://api-staging.{DOMAIN}/health"
    elif [ "$ENV" = "production" ]; then
        HEALTH_URL="https://api.{DOMAIN}/health"
    fi

    if remote_health_check "$HEALTH_URL"; then
        log_deployment_history "$ENV" "$VER" "SUCCESS"
        echo -e "${GREEN}🎉 REMOTE deployment to $ENV completed successfully!${NC}"
    else
        log_deployment_history "$ENV" "$VER" "FAILED_HEALTH_CHECK"
        echo -e "${RED}❌ Deployment failed health check${NC}"
        exit 1
    fi
}

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
    docker compose -f docker-compose.yml --env-file .env.dev down
    docker compose -f docker-compose.yml --env-file .env.dev up -d

    # Health check (local HTTP, no retry needed for dev)
    echo -e "${YELLOW}🏥 Running health check...${NC}"
    sleep 10
    HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health)

    if [ "$HEALTH_STATUS" -eq 200 ]; then
        log_deployment_history "development" "local" "SUCCESS"
        echo -e "${GREEN}✅ LOCAL deployment successful! API is healthy.${NC}"
    else
        log_deployment_history "development" "local" "FAILED_HEALTH_CHECK"
        echo -e "${RED}❌ Deployment failed! API health check returned $HEALTH_STATUS${NC}"
        exit 1
    fi
}

#############################################
# Main Function: Detects environment and routes to local/remote
#############################################
main() {
    if [ -z "$ENVIRONMENT" ]; then
        echo "Usage: ./deploy.sh [development|staging|production] [version]"
        exit 1
    fi

    case "$ENVIRONMENT" in
        development)
            deploy_local
            ;;
        staging|production)
            deploy_remote "$ENVIRONMENT" "$VERSION"
            ;;
        *)
            echo -e "${RED}Error: Environment must be 'development', 'staging', or 'production'${NC}"
            exit 1
            ;;
    esac
}

# Execute main function
main
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
