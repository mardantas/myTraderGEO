<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# SEC-02: Security Architecture Review

**Projeto:** [NOME-DO-PROJETO]
**Data:** [DATA]
**Security Specialist:** [NOME]
**Versão:** 1.0

---

## 🎯 Objetivo

Arquitetura de segurança completa usando **Zero-Trust** e **Defense in Depth** para proteger dados e sistemas.

---

## 🛡️ Security Architecture Principles

### Zero-Trust Architecture

```
"Never Trust, Always Verify"

┌─────────────────────────────────────┐
│  Princípios Zero-Trust              │
├─────────────────────────────────────┤
│ 1. Verify explicitly (authn+authz)  │
│ 2. Least privilege access           │
│ 3. Assume breach                    │
│ 4. Microsegmentation                │
│ 5. End-to-end encryption            │
└─────────────────────────────────────┘
```

### Defense in Depth (Camadas)

```
┌──────────────────────────────────┐
│ Layer 7: Application Security    │ ← Input validation, AuthN/AuthZ
├──────────────────────────────────┤
│ Layer 6: Data Security           │ ← Encryption, Masking, Tokenization
├──────────────────────────────────┤
│ Layer 5: Runtime Security        │ ← WAF, Rate Limiting, RASP
├──────────────────────────────────┤
│ Layer 4: Network Security        │ ← VPC, Security Groups, NSG
├──────────────────────────────────┤
│ Layer 3: Compute Security        │ ← Hardened OS, Patch Management
├──────────────────────────────────┤
│ Layer 2: Identity & Access       │ ← IAM, RBAC, MFA
├──────────────────────────────────┤
│ Layer 1: Physical Security       │ ← Cloud provider responsibility
└──────────────────────────────────┘
```

---

## 🔐 Security by Bounded Context

### BC: [Nome do Bounded Context]

#### Security Requirements

- [ ] **Confidentiality:** Dados protegidos contra acesso não autorizado
- [ ] **Integrity:** Dados protegidos contra modificação não autorizada
- [ ] **Availability:** Sistema disponível quando necessário (SLA 99.9%)
- [ ] **Non-repudiation:** Ações rastreáveis e auditáveis

#### Security Controls

| Control Type | Implementation | Status |
|--------------|----------------|--------|
| **Authentication** | JWT tokens (RS256), MFA obrigatório | ✅ |
| **Authorization** | Domain-level authorization (Aggregates) | ✅ |
| **Input Validation** | Value Objects, FluentValidation | ✅ |
| **Output Encoding** | React auto-escape, CSP headers | ✅ |
| **Encryption at Rest** | Database TDE, S3 encryption | ✅ |
| **Encryption in Transit** | TLS 1.3+, HSTS headers | ✅ |
| **Secrets Management** | AWS Secrets Manager / Vault | ✅ |
| **Audit Logging** | Immutable event store | ✅ |

#### Security Boundaries

```
┌───────────────────────────────────────┐
│  Frontend (React SPA)                 │
│  ├─ CSP headers                       │
│  ├─ XSS prevention (auto-escape)      │
│  └─ Secure token storage (httpOnly)   │
└───────────────────────────────────────┘
              ↓ HTTPS (TLS 1.3)
┌───────────────────────────────────────┐
│  API Gateway                          │
│  ├─ WAF (OWASP Top 10 rules)          │
│  ├─ Rate limiting (100 req/min)       │
│  ├─ JWT validation                    │
│  └─ Request sanitization              │
└───────────────────────────────────────┘
              ↓ Internal (VPC)
┌───────────────────────────────────────┐
│  Backend Services (BCs)               │
│  ├─ Domain authorization (Aggregates) │
│  ├─ Input validation (Value Objects)  │
│  ├─ Business rules enforcement        │
│  └─ Audit logging (Domain Events)     │
└───────────────────────────────────────┘
              ↓ Internal (VPC)
┌───────────────────────────────────────┐
│  Database                             │
│  ├─ TDE (Transparent Data Encryption) │
│  ├─ Network isolation (private subnet)│
│  ├─ Row-level security (RLS)          │
│  └─ Encrypted backups                 │
└───────────────────────────────────────┘
```

---

## 🔒 Authentication & Authorization

### Authentication Strategy

```csharp
// JWT Token Configuration
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = configuration["Jwt:Issuer"],
            ValidAudience = configuration["Jwt:Audience"],
            IssuerSigningKey = new RsaSecurityKey(rsaKey), // RS256 (asymmetric)
            ClockSkew = TimeSpan.Zero // No tolerance for expired tokens
        };
    });
```

**Token Expiry:**
- Access Token: 15 minutos
- Refresh Token: 7 dias
- Rotation obrigatória

**MFA:**
- [ ] TOTP (Google Authenticator, Authy)
- [ ] SMS backup (opcional)
- [ ] Recovery codes

### Authorization Strategy

**Domain-Level Authorization (Aggregates):**

```csharp
// OrderAggregate.cs
public class Order : AggregateRoot
{
    public void Cancel(UserId requestingUserId)
    {
        // Authorization rule: only owner or admin can cancel
        if (this.UserId != requestingUserId && !requestingUserId.IsAdmin())
        {
            throw new UnauthorizedException("Only order owner or admin can cancel");
        }

        // Business logic
        this.Status = OrderStatus.Cancelled;
        this.RaiseDomainEvent(new OrderCancelledEvent(this.Id));
    }
}
```

**API-Level Authorization (Policies):**

```csharp
// Program.cs
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("OrderOwner", policy =>
        policy.RequireAssertion(context =>
            context.User.HasClaim("sub", orderId) || context.User.IsInRole("Admin")
        ));
});

// Controller
[Authorize(Policy = "AdminOnly")]
[HttpDelete("/api/v1/users/{id}")]
public async Task<IActionResult> DeleteUser(Guid id) { ... }
```

---

## 🌐 Network Security

### VPC Architecture (AWS Example)

```
┌───────────────────────────────────────────────┐
│  VPC: [project]-vpc (10.0.0.0/16)             │
│                                               │
│  ┌─────────────────────────────────────────┐ │
│  │ Public Subnet (10.0.1.0/24)             │ │
│  │ ├─ NAT Gateway                          │ │
│  │ ├─ Load Balancer                        │ │
│  │ └─ Bastion Host (jump box)              │ │
│  └─────────────────────────────────────────┘ │
│                                               │
│  ┌─────────────────────────────────────────┐ │
│  │ Private Subnet (10.0.2.0/24)            │ │
│  │ ├─ EKS Nodes (backend services)         │ │
│  │ ├─ Application Load Balancer (internal) │ │
│  │ └─ Security Group: allow port 8080      │ │
│  └─────────────────────────────────────────┘ │
│                                               │
│  ┌─────────────────────────────────────────┐ │
│  │ Private Subnet (10.0.3.0/24)            │ │
│  │ ├─ RDS Database (PostgreSQL)            │ │
│  │ ├─ ElastiCache (Redis)                  │ │
│  │ └─ Security Group: allow port 5432      │ │
│  └─────────────────────────────────────────┘ │
│                                               │
└───────────────────────────────────────────────┘
```

### Security Groups (Firewall Rules)

```terraform
# Load Balancer Security Group
resource "aws_security_group" "alb" {
  name = "[project]-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Public HTTPS
  }

  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_app.cidr_block] # Only to app subnet
  }
}

# Application Security Group
resource "aws_security_group" "app" {
  name = "[project]-app-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id] # Only from ALB
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_db.cidr_block] # Only to DB subnet
  }
}

# Database Security Group
resource "aws_security_group" "db" {
  name = "[project]-db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.app.id] # Only from app
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Deny all outbound
  }
}
```

### WAF (Web Application Firewall)

```terraform
resource "aws_wafv2_web_acl" "main" {
  name  = "[project]-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # OWASP Top 10 Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  # Rate limiting (DDoS protection)
  rule {
    name     = "RateLimitRule"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000 # 2000 requests per 5 minutes per IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "RateLimitRuleMetric"
      sampled_requests_enabled  = true
    }
  }
}
```

---

## 🔑 Secrets Management

### HashiCorp Vault (Recommended)

```bash
# Store secret in Vault
vault kv put secret/[project]/production/database \
  connection_string="Server=db.example.com;Database=app;..." \
  password="[GENERATED-PASSWORD]"

# Application retrieves secret
vault kv get -field=connection_string secret/[project]/production/database
```

### AWS Secrets Manager (Alternative)

```csharp
// Program.cs
var secretsManager = new AmazonSecretsManagerClient(RegionEndpoint.USEast1);
var secretRequest = new GetSecretValueRequest
{
    SecretId = "[project]/production/database"
};
var secretResponse = await secretsManager.GetSecretValueAsync(secretRequest);
var connectionString = JObject.Parse(secretResponse.SecretString)["connection_string"].ToString();

builder.Configuration["ConnectionStrings:Default"] = connectionString;
```

**Secrets Rotation:**
- [ ] Database passwords: rotação a cada 90 dias
- [ ] API keys: rotação a cada 180 dias
- [ ] JWT signing keys: rotação a cada 30 dias

---

## 📊 Security Monitoring

### SIEM Integration

```yaml
# Splunk/Sumo Logic configuration
logs:
  - source: application-logs
    filter: level >= WARN
    index: security-events

  - source: audit-logs
    filter: event_type IN (Login, AccessDenied, DataExport)
    index: audit-trail

  - source: waf-logs
    filter: action = BLOCK
    index: security-events
```

### Security Alerts

| Alert Type | Trigger | Severity | Action |
|------------|---------|----------|--------|
| **Failed Login Attempts** | 5+ failed logins in 5 min | High | Lock account, notify admin |
| **Privilege Escalation** | User role changed to Admin | Critical | Immediate investigation |
| **Data Exfiltration** | Large data export (>10k rows) | High | Require approval |
| **WAF Block** | 10+ blocked requests from IP | Medium | Blacklist IP for 1 hour |
| **Unauthorized API Access** | 401/403 responses spike | Medium | Rate limit user |

---

## ✅ Definition of Done

- [ ] Zero-Trust architecture documentado (verify explicitly, least privilege)
- [ ] Defense in Depth em 7 camadas implementado
- [ ] Security boundaries entre BCs definidas
- [ ] Network security configurado (VPC, Security Groups, WAF)
- [ ] Authentication & Authorization implementados (JWT, domain authz)
- [ ] Secrets management configurado (Vault/Secrets Manager)
- [ ] Encryption at rest e in transit habilitado
- [ ] Security monitoring ativo (SIEM, alerts)
- [ ] SEC-checklist.yml completo

---

**Próximos Passos:**
1. SEC-03: Compliance Report (LGPD, SOC2, PCI-DSS)
2. SEC-04: Executar Penetration Test
3. SEC-05: Incident Response Plan

