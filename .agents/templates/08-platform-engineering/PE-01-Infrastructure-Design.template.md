# PE-01: Infrastructure Design

**Projeto:** [NOME-DO-PROJETO]
**Data:** [DATA]
**Platform Engineer:** [NOME]
**Versão:** 1.0

---

## 🎯 Objetivo

Documentar o design completo da infraestrutura cloud/on-prem, incluindo IaC, networking, compute, storage e auto-scaling.

---

## 📋 Stack Tecnológica

### Cloud Provider / Hosting
- [ ] **Contabo VPS** (✅ RECOMENDADO - €14.99/mês, 8 vCPU, 30GB RAM, 400GB SSD NVMe)
- [ ] **Hetzner** (alternativa europeia similar)
- [ ] **DigitalOcean** (Droplets - mais caro, mas boa UX)
- [ ] **AWS** (EC2 - mais caro, ideal para enterprise)
- [ ] **Azure** (VMs - mais caro, ideal para enterprise)
- [ ] **On-Premise** (Self-hosted)

### Infrastructure as Code
- [ ] **Terraform** (✅ RECOMENDADO - funciona com qualquer provider)
- [ ] **Docker Compose** (para setup inicial simples em 1 servidor)
- [ ] **Ansible** (alternativa para provisionamento)

### Container Orchestration
- [ ] **Docker Swarm** (✅ RECOMENDADO - começa com 1 servidor, escala conforme necessário)
- [ ] **Kubernetes** (opcional - só se projeto crescer muito >20 serviços)

### Backend
- [ ] **.NET 8+** (✅ RECOMENDADO - performance, EF Core, MediatR para DDD)
- [ ] **Node.js** (alternativa)
- [ ] **Java/Spring** (alternativa enterprise)

### Frontend
- [ ] **Vue 3** (✅ RECOMENDADO - Composition API, Pinia, Vite)
- [ ] **React** (alternativa)
- [ ] **Angular** (alternativa enterprise)

---

## 🏗️ Arquitetura de Infraestrutura

### Diagrama de Alto Nível (1 Servidor Inicial)

```
┌─────────────────────────────────────────────┐
│              INTERNET                       │
│         (CloudFlare Free CDN + DDoS)        │
└──────────────────┬──────────────────────────┘
                   │ HTTPS
                   │
┌──────────────────▼──────────────────────────┐
│     Contabo VPS L (8 vCPU, 30GB RAM)       │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ Nginx (Reverse Proxy + SSL)         │   │
│  └─────────┬───────────────────────────┘   │
│            │                                │
│  ┌─────────┴──────────┐                    │
│  │                    │                    │
│  ▼                    ▼                    │
│ ┌──────────┐   ┌──────────────┐           │
│ │ Frontend │   │  Backend API │           │
│ │ (Vue)    │   │  (.NET 8)    │           │
│ │ Nginx    │   │  Container   │           │
│ └──────────┘   └──────┬───────┘           │
│                       │                    │
│           ┌───────────┴──────────┐         │
│           │                      │         │
│     ┌─────▼──────┐      ┌───────▼──────┐  │
│     │ PostgreSQL │      │ Redis        │  │
│     │ Container  │      │ Container    │  │
│     └────────────┘      └──────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ Monitoring: Prometheus + Grafana     │  │
│  └──────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘

Tudo roda em Docker (single-node Swarm ou Compose)
```

### Ambientes

| Ambiente | Propósito | URL | Infra |
|----------|-----------|-----|-------|
| **Development** | Dev local | http://localhost:5173 (Vue) + :5000 (.NET) | Docker Compose |
| **Production** | Produção | https://app.[YOUR-DOMAIN] | Contabo VPS (1 servidor inicial) |

**Evolução futura:**
- 2 servidores: 1 manager + 1 worker (HA)
- 3+ servidores: 1 manager + 2+ workers (scale horizontal)

---

## 🌐 Networking

### Contabo VPS Network (1 Servidor)

```yaml
Servidor:
  IP Público: [SEU-IP-PUBLICO] (fornecido pela Contabo)
  IP Privado: 10.0.0.1 (Docker bridge network)

Firewall (ufw):
  Portas abertas:
    - 22 (SSH - APENAS seu IP)
    - 80 (HTTP - redirect para HTTPS)
    - 443 (HTTPS)
    - 2377 (Docker Swarm - quando adicionar nodes)

Docker Networks:
  - bridge (default - dev local)
  - app-network (overlay - para Swarm)
  - monitoring-network (overlay - Prometheus/Grafana)

CloudFlare (Free):
  - DNS: app.[YOUR-DOMAIN] → [SEU-IP-PUBLICO]
  - CDN: Cache assets estáticos (Vue build)
  - DDoS Protection: Automatic
  - SSL: Full (strict) - certificado Certbot no servidor
```

### Firewall Setup (ufw)

```bash
# Instalar firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Regras
sudo ufw allow from [SEU-IP-CASA] to any port 22  # SSH apenas do seu IP
sudo ufw allow 80/tcp                               # HTTP
sudo ufw allow 443/tcp                              # HTTPS
# sudo ufw allow 2377/tcp                           # Docker Swarm (quando adicionar nodes)

sudo ufw enable
```

---

## 💻 Compute Resources

### Contabo VPS Provisioning (1 Servidor)

```bash
# 1. Criar VPS na Contabo (manual via painel web)
# - Plano: VPS L (€14.99/mês)
# - OS: Ubuntu 22.04 LTS
# - Datacenter: Nuremberg (Europa)
# - SSH Key: Upload sua chave pública

# 2. Conectar via SSH
ssh root@[SEU-IP-PUBLICO]

# 3. Setup inicial
apt update && apt upgrade -y
apt install -y curl git ufw fail2ban

# 4. Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
docker --version

# 5. Inicializar Swarm (single-node)
docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')

# 6. Verificar
docker node ls
# ID      HOSTNAME   STATUS   AVAILABILITY   MANAGER STATUS
# xxx     vpsXXX     Ready    Active         Leader
```

**Spec do Servidor:**
- **CPU:** 8 vCPU (AMD Ryzen)
- **RAM:** 30GB DDR4
- **Storage:** 400GB NVMe SSD
- **Network:** 1 Gbit/s
- **Custo:** €14.99/mês (~R$90/mês)

### Deployments (Docker Compose - Single Node)

```yaml
# docker-compose.yml (produção single-node)
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - frontend-build:/usr/share/nginx/html:ro
    depends_on:
      - backend
    networks:
      - app-network

  frontend:
    image: [YOUR-REGISTRY]/frontend:latest
    build:
      context: ./frontend
      dockerfile: Dockerfile
    volumes:
      - frontend-build:/app/dist
    command: echo "Build complete"

  backend:
    image: [YOUR-REGISTRY]/backend:latest
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=Host=db;Database=myapp;Username=postgres;Password=${DB_PASSWORD}
      - Redis__ConnectionString=redis:6379
    depends_on:
      - db
      - redis
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - app-network
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network
    deploy:
      resources:
        limits:
          memory: 2G

  redis:
    image: redis:7-alpine
    networks:
      - app-network
    deploy:
      resources:
        limits:
          memory: 512M

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    networks:
      - app-network

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - app-network

volumes:
  postgres-data:
  frontend-build:
  prometheus-data:
  grafana-data:

networks:
  app-network:
    driver: bridge
```

**Deploy:**
```bash
# 1. Clone repo no servidor
git clone [YOUR-REPO] /app
cd /app

# 2. Criar arquivo .env
cat > .env <<EOF
DB_PASSWORD=$(openssl rand -base64 32)
GRAFANA_PASSWORD=$(openssl rand -base64 16)
EOF

# 3. Deploy
docker compose up -d

# 4. Verificar
docker compose ps
docker compose logs -f backend
```

**Quando evoluir para Swarm (2+ servidores):**
```bash
# Converter para stack
docker stack deploy -c docker-compose.yml myapp
```

---

## 🗄️ Storage & Database

### Database (PostgreSQL Container)

| Resource | Type | Storage | Backup | HA |
|----------|------|---------|--------|-----|
| **Production DB** | PostgreSQL 15 (Docker) | 50GB volume (Contabo VPS) | Daily full backup | Single-node (evoluir para replica) |
| **Redis Cache** | Redis 7 (Docker) | 2GB volume | AOF persistence | Single-node |

**Backup Strategy:**
```bash
# Backup diário automatizado (cron)
0 2 * * * docker exec postgres pg_dump -U postgres myapp | gzip > /backups/db-$(date +\%Y\%m\%d).sql.gz

# Retenção: 30 dias local + upload para S3/B2
# Custo S3: ~$0.50/mês (10GB backups)
```

### Object Storage (Opcional)

**Início:** Usar volume do Contabo (400GB disponível)

**Quando crescer:** Migrar para object storage:
- **Backblaze B2** ($0.005/GB/mês) - mais barato
- **AWS S3** ($0.023/GB/mês)
- **Contabo Object Storage** (€2.49/mês 250GB)

---

## 📈 Auto-Scaling

### Docker Swarm Service Scaling

**Manual Scaling:**
```bash
# Scale service up/down
docker service scale myapp_backend-api=10

# Update replicas in stack file, then:
docker stack deploy -c docker-stack.yml myapp
```

**Auto-Scaling (via monitoring alerts):**
```bash
# Script: auto-scale.sh (triggered by Prometheus AlertManager)
#!/bin/bash

SERVICE="myapp_backend-api"
CURRENT=$(docker service ls --filter name=$SERVICE --format "{{.Replicas}}" | cut -d'/' -f1)
MAX_REPLICAS=20
MIN_REPLICAS=3

if [ "$1" == "scale-up" ] && [ $CURRENT -lt $MAX_REPLICAS ]; then
  NEW=$((CURRENT + 2))
  docker service scale $SERVICE=$NEW
  echo "Scaled up to $NEW replicas"
elif [ "$1" == "scale-down" ] && [ $CURRENT -gt $MIN_REPLICAS ]; then
  NEW=$((CURRENT - 1))
  docker service scale $SERVICE=$NEW
  echo "Scaled down to $NEW replicas"
fi
```

**Prometheus Alert Example:**
```yaml
# prometheus/alerts.yml
- alert: HighCPUUsage
  expr: avg(rate(container_cpu_usage_seconds_total[5m])) > 0.75
  for: 5m
  annotations:
    summary: "High CPU usage detected"
  # Webhook triggers auto-scale.sh via AlertManager
```

**NOTA:** Para projetos maiores que precisem de auto-scaling automático nativo, considere **Kubernetes** (HPA, VPA, Cluster Autoscaler). Docker Swarm é ideal para scaling manual ou script-based (suficiente para 80% dos casos).

---

## 🔐 Secrets Management

### HashiCorp Vault / AWS Secrets Manager / Azure Key Vault

```hcl
# terraform/secrets.tf
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "[project]-production-db-credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "app_user"
    password = random_password.db_password.result
    host     = aws_db_instance.main.endpoint
  })
}
```

### External Secrets Operator (Kubernetes)

```yaml
# kubernetes/external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: production
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: db-credentials
  data:
  - secretKey: url
    remoteRef:
      key: [project]-production-db-credentials
      property: url
```

---

## 🔄 CI/CD Integration

### GitHub Actions CD Pipeline

```yaml
# .github/workflows/cd-production.yml
name: Deploy to Production

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
        aws-region: us-east-1

    - name: Update kubeconfig
      run: aws eks update-kubeconfig --name [project]-production

    - name: Deploy to Kubernetes (Blue-Green)
      run: |
        kubectl apply -f kubernetes/backend-deployment-green.yaml
        kubectl rollout status deployment/backend-api-green
        kubectl patch service backend-api -p '{"spec":{"selector":{"version":"green"}}}'
```

---

## ✅ Definition of Done

### Infrastructure
- [ ] IaC completo (Terraform/Bicep) versionado no git
- [ ] Ambientes criados (dev, staging, production)
- [ ] Networking configurado (VPC, subnets, security groups)
- [ ] Compute resources provisionados (Kubernetes/ECS)

### Security
- [ ] Secrets management configurado (Vault/Secrets Manager)
- [ ] Network security (WAF, Security Groups)
- [ ] Encryption at rest e in transit

### Scalability
- [ ] HPA configurado (CPU, Memory, custom metrics)
- [ ] Cluster autoscaler habilitado
- [ ] Load balancer com health checks

### Validation
- [ ] Terraform plan executado sem erros
- [ ] Infra provisionada com sucesso
- [ ] Health checks passando
- [ ] PE-checklist.yml completo

---

**Próximos Passos:**
1. PE-02: Configurar Observability (Prometheus, Grafana)
2. PE-03: Implementar DR Plan (Backup/Restore)
3. PE-04: Configurar Production Deployment (Blue-Green)
