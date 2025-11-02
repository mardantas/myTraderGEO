<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)  
- Use blank lines between sections for readability (content)  
- Validate in Markdown preview before committing  
-->

# 05-infra - {PROJECT_NAME} Infrastructure

**Projeto:** {PROJECT_NAME}  
**Stack:** {BACKEND_STACK} + {FRONTEND_STACK} + PostgreSQL + Docker  
**Responsible Agent:** PE Agent  

---

## 📋 About This Document

This is a **quick reference guide** for executing infrastructure commands (Docker, deploy, environment setup). For strategic decisions, architecture details, and trade-offs, consult [PE-00-Environments-Setup.md](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md).

**Document Separation:**
- **This README:** Commands and checklists (HOW to execute)
- **PE-00-Environments-Setup.md:** Architecture decisions, justifications, and trade-offs (WHY and WHAT)

**Principle:** README is an INDEX/QUICK-REFERENCE to PE-00-Environments-Setup.md, not a duplicate.  

---

## 🎯 Technology Stack

- **Backend:** {BACKEND_STACK} (e.g., .NET 8 + ASP.NET Core + Entity Framework Core + SignalR)  
- **Frontend:** {FRONTEND_STACK} (e.g., Vue 3 + TypeScript + Vite + Pinia + PrimeVue)  
- **Database:** PostgreSQL 15+  
- **Containerization:** Docker + Docker Compose  
- **Web Server (Frontend):** Nginx (serves static Vue.js files in production)  
- **Reverse Proxy/Load Balancer:** Traefik v3.0 (HTTPS, automatic SSL, load balancing - staging/production)  

---

## 📁 Directory Structure

```
05-infra/
├── configs/
│   ├── .env.example          # Environment variables template
│   └── traefik.yml           # Traefik static configuration
├── docker/
│   ├── docker-compose.dev.yml            # Development
│   ├── docker-compose.staging.yml    # Staging + Traefik
│   └── docker-compose.prod.yml # Production + Traefik + Resource Limits
├── dockerfiles/
│   ├── backend/
│   │   ├── Dockerfile        # Backend production
│   │   └── Dockerfile.dev    # Backend development (hot reload)
│   └── frontend/
│       ├── Dockerfile        # Frontend production (Nginx)
│       ├── Dockerfile.dev    # Frontend development (Vite)
│       └── nginx.conf        # Nginx SPA configuration
└── scripts/
    ├── deploy.sh             # Deployment script
    ├── backup-database.sh    # Database backup (TODO)
    └── restore-database.sh   # Database restore (TODO)
```

---

## 🚀 Quick Start

### 1. Configure Environment Variables

```bash
# Copy template for development
cp 05-infra/configs/.env.example 05-infra/configs/.env.dev

# Edit .env.dev with your credentials
nano 05-infra/configs/.env.dev
```

### 2. Development - Start Local Environment

```bash
# Start all services
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up -d

# View logs
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev logs -f

# Stop services
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev down
```

**Access:**  
- Frontend ({FRONTEND_FRAMEWORK} + Vite): http://localhost:5173  
- Backend API ({BACKEND_FRAMEWORK}): http://localhost:5000  
- Database (PostgreSQL): localhost:5432  
- PgAdmin (optional): http://localhost:8080  
  - Email: `admin@{project}.local`  
  - Password: `admin123`  

### 3. Staging - Deploy to Staging

```bash
./05-infra/scripts/deploy.sh staging latest
```

### 4. Production - Deploy to Production

```bash
# With interactive confirmation
./05-infra/scripts/deploy.sh production v1.0.0
```

---

## 🔧 Common Docker Commands

### Development

```bash
# Start all services
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up -d

# Start specific service
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up -d database

# View logs (all services)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev logs -f

# View logs (specific service)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev logs -f api

# Restart service
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev restart api

# Stop all services
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev down

# Stop and remove volumes (⚠️ WARNING: deletes data!)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev down -v

# Rebuild image (after Dockerfile changes)
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev build api
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up -d api

# Execute command in running container
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec api bash
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U {project}_app -d {project}_dev
```

### Staging

```bash
# Deploy
./05-infra/scripts/deploy.sh staging latest

# View logs
docker compose -f 05-infra/docker/docker-compose.staging.yml --env-file 05-infra/configs/.env.staging logs -f

# Restart service
docker compose -f 05-infra/docker/docker-compose.staging.yml --env-file 05-infra/configs/.env.staging restart api

# Stop
docker compose -f 05-infra/docker/docker-compose.staging.yml --env-file 05-infra/configs/.env.staging down
```

### Production

```bash
# Deploy (with confirmation)
./05-infra/scripts/deploy.sh production v1.0.0

# View logs
docker compose -f 05-infra/docker/docker-compose.prod.yml --env-file 05-infra/configs/.env.prod logs -f

# Health check
curl https://{domain}/health

# Stop (with confirmation)
docker compose -f 05-infra/docker/docker-compose.prod.yml --env-file 05-infra/configs/.env.prod down
```

---

## 🌍 Environments

### Development

**Characteristics:**  
- Hot reload enabled (backend and frontend)  
- Mounted volumes for development  
- Detailed logs (Information level)  
- PgAdmin included for database management  
- JWT expiration: 60 minutes  
- No resource limits  

**Docker Compose:** `05-infra/docker/docker-compose.dev.yml`  

**Dockerfiles:**  
- Backend: `05-infra/dockerfiles/backend/Dockerfile.dev`  
- Frontend: `05-infra/dockerfiles/frontend/Dockerfile.dev`  

**Access:**  
- Frontend: http://localhost:5173 (Vite dev server)  
- Backend: http://localhost:5000  
- Database: localhost:5432  

---

### Staging

**Characteristics:**  
- Production build (optimized)  
- Traefik reverse proxy (HTTPS with Let's Encrypt staging)  
- Automated SSL certificates (staging CA)  
- Resource limits (moderate)  
- Logs: Warning level  
- JWT expiration: 30 minutes  

**Docker Compose:** `05-infra/docker/docker-compose.staging.yml`  

**Dockerfiles:**  
- Backend: `05-infra/dockerfiles/backend/Dockerfile`  
- Frontend: `05-infra/dockerfiles/frontend/Dockerfile` (Nginx)  

**Access:**
- Frontend: https://staging.{domain}  
- Backend API: https://api-staging.{domain}  
- Traefik Dashboard: https://traefik-staging.{domain}  
  - User: `admin`  
  - Password: `change_me` (change in `.env.staging`)  

**Note:** All traffic is routed through Traefik (automatic HTTPS with Let's Encrypt staging CA).  

---

### Production

**Characteristics:**
- Production build (fully optimized)  
- Traefik reverse proxy (HTTPS with Let's Encrypt production)  
- Automated SSL certificates (trusted CA)  
- Strict resource limits (CPU, memory)  
- Logs: Error level only  
- JWT expiration: 15 minutes  
- Health checks configured  
- Auto-restart policies  

**Docker Compose:** `05-infra/docker/docker-compose.prod.yml`  

**Dockerfiles:**
- Backend: `05-infra/dockerfiles/backend/Dockerfile`  
- Frontend: `05-infra/dockerfiles/frontend/Dockerfile` (Nginx)  

**Access:**
- Frontend: https://{domain}  
- Backend API: https://api.{domain}  
- Traefik Dashboard: https://traefik.{domain}  
  - User: `admin`  
  - Password: configured in `.env.prod`  
  - **IP Whitelist:** Configure `YOUR_IP_ADDRESS` in `.env.prod` for security  

**Note:** All traffic is routed through Traefik (automatic HTTPS with Let's Encrypt trusted CA).  

---

## 🔐 Secrets Management

### Development

**File:** `05-infra/configs/.env.dev` (local, gitignored)  

**Required Variables:**
```bash
# Database
DB_HOST=database
DB_PORT=5432
DB_NAME={project}_dev
DB_USER={project}_app
DB_PASSWORD=dev_password_123

# JWT
JWT_SECRET=dev_jwt_secret_min_32_characters_long
JWT_EXPIRATION_MINUTES=60

# Email (optional for dev)
SMTP_HOST=smtp.mailtrap.io
SMTP_PORT=587
SMTP_USER=your_mailtrap_user
SMTP_PASSWORD=your_mailtrap_password
```

### Staging/Production

**Storage:** GitHub Secrets (Settings → Secrets and variables → Actions)  

**Required Secrets:**
- `DB_PASSWORD_STAGING` / `DB_PASSWORD_PRODUCTION`  
- `JWT_SECRET_STAGING` / `JWT_SECRET_PRODUCTION`  
- `SMTP_PASSWORD_STAGING` / `SMTP_PASSWORD_PRODUCTION`  
- `LETSENCRYPT_EMAIL` - Email for Let's Encrypt SSL certificates  
- `DOMAIN` - Your domain (e.g., `example.com`)  
- `YOUR_IP_ADDRESS` - Your IP for Traefik Dashboard whitelist (production only)  

**Deployment:** Secrets injected via GitHub Actions workflow or manual `docker compose` with `--env-file`  

---

## 📊 Resource Limits

### Development

No limits (use full available resources for fast development)

### Staging

```yaml
api:
  deploy:
    resources:
      limits:
        cpus: '1.0'
        memory: 1G
      reservations:
        cpus: '0.5'
        memory: 512M
```

### Production

```yaml
api:
  deploy:
    resources:
      limits:
        cpus: '2.0'
        memory: 2G
      reservations:
        cpus: '1.0'
        memory: 1G
```

---

## 🔗 Related Artifacts

This section connects operational README with strategic documentation.

| Artifact | Purpose | When to Consult |
|----------|---------|------------------|
| **[PE-00-Environments-Setup.md](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md)** | Strategic infrastructure decisions (Docker architecture, Traefik config, resource planning, scaling strategy, trade-offs) | To understand **WHY** infrastructure is designed this way, evaluate alternatives, modify architecture |
| **[FEEDBACK-XXX-PE-{Topic}.md](../00-doc-ddd/00-feedback/FEEDBACK-XXX-PE-{Topic}.md)** | Resolutions: {Feedback topic summary} | To understand infrastructure improvements, security enhancements |
| **[SEC-00-Security-Baseline.md](../00-doc-ddd/09-security/SEC-00-Security-Baseline.md)** | Security baseline (Infrastructure Security section) | To understand security benefits, HTTPS enforcement, secrets management |
| **[DBA-01-{EpicName}-Database-Design-Decisions.md](../00-doc-ddd/05-database-design/DBA-01-{EpicName}-Database-Design-Decisions.md)** | Database design decisions | To understand database schema, migrations, connection strings |

---

## 📚 References

### Internal Documentation

- **Platform Engineering Setup:** [00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md)  
  - Docker architecture decisions  
  - Traefik configuration details  
  - Resource planning and trade-offs  

- **Security Baseline:** [00-doc-ddd/09-security/SEC-00-Security-Baseline.md](../00-doc-ddd/09-security/SEC-00-Security-Baseline.md)  
  - Infrastructure security section  
  - HTTPS/TLS enforcement  
  - Secrets management strategy  

- **Database Setup:** [04-database/README.md](../../04-database/README.md)  
  - Database users and permissions  
  - Migration execution  

### External Documentation

- **Docker Compose Documentation:** https://docs.docker.com/compose/  
- **Traefik Documentation:** https://doc.traefik.io/traefik/  
- **Nginx Documentation:** https://nginx.org/en/docs/  
- **Let's Encrypt:** https://letsencrypt.org/docs/  

---

## 🛠️ Troubleshooting

### Problem: Container fails to start

**Symptom:** `docker compose up` fails with error  

**Common Causes & Solutions:**  

1. **Port already in use:**
   ```bash
   # Check what's using port
   netstat -ano | findstr :5000  # Windows
   lsof -i :5000                 # Linux/Mac

   # Kill process or change port in .env
   ```

2. **Missing .env file:**
   ```bash
   # Copy example for development
   cp 05-infra/configs/.env.example 05-infra/configs/.env.dev
   ```

3. **Docker daemon not running:**
   ```bash
   # Start Docker Desktop (Windows/Mac)
   # Or: sudo systemctl start docker (Linux)
   ```

### Problem: Database connection refused

**Symptom:** Application cannot connect to database  

**Solution:**  
```bash
# 1. Check if database container is running
docker compose ps

# 2. Check database logs
docker compose logs database

# 3. Verify connection string in .env.dev
cat 05-infra/configs/.env.dev | grep DB_

# 4. Test connection manually
docker compose exec database psql -U {project}_app -d {project}_dev -c "SELECT 1;"

# 5. If init-scripts failed, recreate volume
docker compose down -v
docker compose up -d
```

### Problem: Traefik SSL certificate not issued

**Symptom:** HTTPS not working, browser shows insecure warning  

**Solution:**  
```bash
# 1. Check Traefik logs
docker compose logs traefik

# 2. Verify DNS points to server
nslookup {domain}

# 3. Check if port 80/443 are open
curl -I http://{domain}

# 4. Verify email in traefik.yml (for Let's Encrypt)
cat 05-infra/configs/traefik.yml | grep email

# 5. Staging: Check if using Let's Encrypt staging CA
# Production: Ensure using production CA
```

### Problem: Hot reload not working (development)

**Symptom:** Code changes not reflected in running application  

**Solution:**  

**Backend:**  
```bash
# 1. Verify volume mount in docker-compose.dev.yml
docker compose config | grep -A 5 "api:"

# 2. Check if watch is enabled (depends on framework)
docker compose logs api | grep -i "watch\|reload"

# 3. Restart container
docker compose restart api
```

**Frontend:**  
```bash
# 1. Verify volume mount
docker compose config | grep -A 5 "web:"

# 2. Check Vite/framework dev server
docker compose logs web

# 3. Clear browser cache (Ctrl+Shift+R)

# 4. Restart container
docker compose restart web
```

---

## 🪟 Windows Development

### Prerequisites

- **Docker Desktop for Windows** (WSL2 backend enabled)  
- **Git for Windows** (includes Git Bash)  
- **Windows 10/11** with WSL2 configured  

### Running Bash Scripts

All deployment and operational scripts use Bash. On Windows, use one of these options:

**Option 1: Git Bash (Recommended)**
```bash
bash ./05-infra/scripts/deploy.sh staging
bash ./05-infra/scripts/backup-database.sh staging
```

**Option 2: WSL2**
```bash
wsl bash ./05-infra/scripts/deploy.sh staging
```

### Named Volumes Storage

Docker Desktop stores named volumes in WSL2 filesystem:
```
\\wsl$\docker-desktop-data\data\docker\volumes\
```

**Benefits:**  
- Optimized performance (60x faster than bind mounts for databases)  
- Works identically across Windows/Linux/Mac  
- Automatically managed by Docker (no manual intervention needed)  

### Development Notes

- **Hot reload works** via bind mounts (WSL2 file watching)  
- **No backups needed** in development (recreate with migrations + seeds)  
- **Reset database:** `docker compose down -v && docker compose up -d`  

For detailed Windows configuration and troubleshooting, see [PE-00-Environments-Setup.md](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md#-desenvolvimento-no-windows).

---

**PE Agent** - {PROJECT_NAME} Platform Engineering
**Last Updated:** {YYYY-MM-DD}  
**Status:** ⏳ {Status}  
