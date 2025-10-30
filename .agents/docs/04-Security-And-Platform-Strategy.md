# Security and Platform Strategy

**Objetivo:** Visão geral de como segurança e performance são distribuídas entre os agentes do workflow DDD.

**Versão:** 1.0 (Simplified)
**Data:** 2025-10-09

---

## 🎯 Princípio Fundamental

**Segurança e Performance NÃO são fases separadas** - são responsabilidades distribuídas entre todos os agentes, com PE e SEC coordenando estratégias transversais.

**Abordagem:** "Security & Performance by Design"

---

## 🔐 Distribuição de Responsabilidades - Segurança

| Agente | Fase | Responsabilidades Principais |
|--------|------|------------------------------|
| **SDA** | Discovery | Identificar dados sensíveis no Event Storming, BCs com autenticação |
| **SEC** | Discovery | Security baseline (OWASP Top 3, LGPD mínimo, estratégia auth) |
| **DE** | Per Epic | Input validation (Value Objects), Authorization (Aggregates), Secrets management |
| **SE** | Per Epic | Implementar validações do DE, API security, parameterized queries |
| **DBA** | Per Epic | Encryption at rest, access control, audit logging, **multi-env passwords** |
| **FE** | Per Epic | XSS prevention, CSRF protection, secure token storage |
| **QAE** | Per Epic | Security testing (OWASP checklist), vulnerability scanning |
| **GM** | Setup | Dependabot, branch protection, secret scanning |
| **PE** | Setup | Network security (firewall), secrets management (env vars), **server hardening** |

### Checklist Mínimo de Segurança

**Discovery:**
- [ ] SDA identificou dados sensíveis (credentials, PII)
- [ ] SEC definiu baseline (OWASP Top 3, LGPD, JWT auth)
- [ ] PE: Server hardening complete (UFW, fail2ban, SSH keys)
- [ ] PE: Multi-environment .env strategy documented

**Por Épico:**
- [ ] DE: Input validation em Value Objects
- [ ] DE: Authorization em Aggregates
- [ ] SE: Secrets via environment variables (não hardcoded)
- [ ] DBA: Sensitive columns identificadas
- [ ] DBA: Multi-environment passwords configured (ALTER USER migration)
- [ ] DBA: Password rotation procedure documented
- [ ] FE: XSS auto-escaped, CSRF token em forms
- [ ] QAE: Testes OWASP Top 3 (Access Control, Injection, Auth)

**GitHub:**
- [ ] GM: Dependabot enabled
- [ ] GM: Branch protection (main/master)
- [ ] GM: Secret scanning enabled

---

## ⚡ Distribuição de Responsabilidades - Performance

| Agente | Fase | Responsabilidades Principais |
|--------|------|------------------------------|
| **SDA** | Discovery | Identificar BCs com alta carga, definir eventual consistency |
| **PE** | Discovery | Infraestrutura (Docker Compose, observability, deploy scripts) |
| **DE** | Per Epic | Async/await, evitar N+1 queries, caching strategy |
| **SE** | Per Epic | Implementar async do DE, query optimization |
| **DBA** | Per Epic | Indexing strategy, query performance analysis |
| **FE** | Per Epic | Code splitting, lazy loading, memoization |
| **QAE** | Per Epic | Load tests, performance benchmarks |

### Checklist Mínimo de Performance

**Discovery:**
- [ ] SDA identificou BCs com alta carga
- [ ] PE configurou observability básica (logs, health checks)

**Por Épico:**
- [ ] DE: Async/await correto (sem .Result/.Wait)
- [ ] DE: Cache de dados frequentes (Redis/In-Memory)
- [ ] SE: N+1 queries eliminadas (use Include)
- [ ] DBA: PK + FK indexes criados
- [ ] DBA: Queries principais <100ms
- [ ] FE: Code splitting de rotas
- [ ] QAE: Load test básico (50 users, p95<500ms)

---

## 🔑 Multi-Environment Credentials Strategy

### Princípio
**NEVER hardcode passwords in Git** (even in SQL scripts or config files)

### Strategy by Environment

| Environment | Password Strength | Storage | Rotation Frequency |
|-------------|-------------------|---------|-------------------|
| **Development** | Simple OK (`dev_password_123`) | Committed in `.env.dev` | Never |
| **Staging** | Strong (16+ chars, complex) | Server only (NOT in Git) | Semi-annual |
| **Prod** | Very Strong (20+ chars, complex) | Server only (NOT in Git) | Quarterly |

### Implementation Pattern

**1. Init Scripts (Development defaults):**
```sql
-- 001_init.sql (committed to Git)
CREATE USER app_user WITH PASSWORD 'dev_password_123';  -- Simple OK for dev
```

**2. ALTER USER Migration (Staging/Prod):**
```sql
-- 002_update_prod_passwords.sql (committed to Git - no real passwords!)
-- Execute manually with variables (passwords never committed)

ALTER USER app_user WITH PASSWORD :'app_password';  -- Password via psql -v
```

**3. Execution (Staging/Prod):**
```bash
# Passwords passed via environment variables (not in Git, not in bash history)
export DB_APP_PASSWORD="St@g!ng_SecureP@ss2025!#"
psql -U postgres -d mydb \
  -v app_password="$DB_APP_PASSWORD" \
  -f 002_update_prod_passwords.sql
```

### Password Requirements

**Development:**
- ✅ Simple passwords OK (`dev_password_123`)
- ✅ Can be committed to Git (`.env.dev`)

**Staging:**
- ✅ 16+ characters
- ✅ Mix: uppercase, lowercase, numbers, symbols
- ❌ NEVER commit to Git
- ✅ Rotate semi-annually

**Prod:**
- ✅ 20+ characters
- ✅ High complexity
- ❌ NEVER commit to Git
- ✅ Rotate quarterly
- ✅ Use password manager (1Password, Bitwarden)

### Compliance

**LGPD (Art. 46):**
> "Os agentes de tratamento devem adotar medidas de segurança, técnicas e administrativas aptas a proteger os dados pessoais"

**SOC 2 / ISO 27001:**
- Require role-based access control (RBAC)
- Require password rotation policies
- Require audit trails

---

## 🛡️ Server Security Hardening

### Checklist (PE Responsibility - Discovery)

**Network Security:**
- [ ] UFW firewall configured (allow 22, 80, 443 only)
- [ ] SSH port secured (key-based auth, disable password auth)
- [ ] fail2ban configured (SSH brute-force protection)

**System Security:**
- [ ] NTP time sync (chrony) - accurate logs for audit
- [ ] Dedicated user with minimal privileges (not root)
- [ ] Docker group membership (secondary group, not primary)

**Application Security:**
- [ ] Traefik HTTPS enforced (redirect HTTP → HTTPS)
- [ ] Let's Encrypt certificates (staging CA for staging, prod CA for prod)
- [ ] htpasswd for Traefik dashboard (not exposed publicly)

### UFW Firewall Configuration

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

# Enable
sudo ufw --force enable
sudo ufw status numbered
```

### SSH Hardening

```bash
# Disable password authentication (key-based only)
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH
sudo systemctl restart sshd
```

### fail2ban Configuration

```bash
# Install
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

# Restart
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

### User & Group Security

```bash
# Create dedicated user (NOT root)
sudo groupadd myproject_app
sudo useradd -m -s /bin/bash -g myproject_app -G docker myproject_app

# Verify
id myproject_app
# Expected: uid=1001(myproject_app) gid=1001(myproject_app) groups=1001(myproject_app),999(docker)
```

**Security Rationale:**
- ✅ **Least Privilege**: User has minimal permissions
- ✅ **Defense in Depth**: Even if app is compromised, user can't access other services
- ✅ **Docker Access**: Secondary group `docker` allows container management
- ❌ **NOT root**: Limits damage if account is compromised

---

## 📋 Exemplos Rápidos

### Input Validation (DE/SE)
```csharp
// Value Object com validação
public record Strike(decimal Value)
{
    public Strike
    {
        if (Value <= 0 || Value > 100000)
            throw new DomainException("Invalid strike");
    }
}
```

### Authorization (DE/SE)
```csharp
public void Close(UserId requestingUser)
{
    if (this.OwnerId != requestingUser)
        throw new UnauthorizedException("Only owner can close");
}
```

### Query Optimization (SE/DBA)
```csharp
// ✅ CORRETO: Include
var strategies = await _context.Strategies
    .Include(s => s.Legs)
    .ToListAsync();

// ❌ ERRADO: N+1
```

### XSS Prevention (FE)
```tsx
// ✅ React escapa automaticamente
<div>{strategy.name}</div>

// ❌ NUNCA usar dangerouslySetInnerHTML com user input
```

### Async/Await (SE)
```csharp
// ✅ CORRETO
public async Task<Strategy> CreateAsync(...)
{
    await _repository.AddAsync(strategy);
    await _unitOfWork.CommitAsync();
}

// ❌ ERRADO: .Result ou .Wait() (deadlock risk)
```

---

## 🔗 Referências Detalhadas

Para implementação detalhada de cada padrão, consulte:

- **Segurança:** OWASP Top 10 (https://owasp.org/www-project-top-ten/)
- **DDD Patterns:** [04-DDD-Patterns-Reference.md](04-DDD-Patterns-Reference.md)
- **API Standards:** [05-API-Standards.md](05-API-Standards.md)
- **Performance:** k6 Load Testing (https://k6.io/docs/)

---

**Versão:** 1.0 (Simplified for Small/Medium Projects)
**Status:** Living Document
**Filosofia:** Security & Performance by Design, não como fase separada
