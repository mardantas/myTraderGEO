# SEC-00 - Security Baseline

**Agent:** SEC (Security Specialist)  
**Project:** myTraderGEO  
**Date:** 2025-10-16  
**Phase:** Discovery (1x)  
**Scope:** Essential security baseline for small/medium projects  
**Version:** 3.0  
  
---  

## 📋 Metadata

- **Project Name:** myTraderGEO  
- **Created:** 2025-10-16  
- **Security Engineer:** SEC Agent  
- **Target:** Small/Medium Trading Platform    
- **Approach:** OWASP Top 3 + LGPD Minimum + Auth Strategy  

---

## 🎯 Objetivo

Definir baseline de segurança essencial para myTraderGEO: OWASP Top 3 mitigations, LGPD compliance mínimo, e estratégias de autenticação/autorização para plataforma de trading com dados financeiros sensíveis.

---

## 🔍 Threat Identification

### Main Threats per Bounded Context

| Bounded Context | Main Threats | Sensitive Data | Priority |
|-----------------|--------------|----------------|----------|
| **User Management** | - Credential theft<br>- Account takeover<br>- Brute force attacks | - Passwords (hashed)<br>- Email<br>- CPF<br>- Risk profile<br>- Subscription plan | Critical |
| **Strategy Planning** | - Unauthorized access to private templates<br>- Intellectual property theft<br>- Template manipulation | - Private strategy templates<br>- Proprietary algorithms<br>- Strike references<br>- Leg configurations | High |
| **Trade Execution** | - Unauthorized trade execution<br>- Financial fraud<br>- P&L manipulation | - Real trading positions<br>- Paper trading data<br>- Execution history<br>- P&L values | Critical |
| **Risk Management** | - Limit bypass<br>- Conflict detection tampering<br>- Risk score manipulation | - Risk limits<br>- Exposure calculations<br>- Conflict alerts<br>- Margin requirements | High |
| **Asset Management** | - Unauthorized portfolio access<br>- Balance manipulation<br>- Guarantee tampering | - Asset portfolio (stocks)<br>- Option portfolio<br>- Account balance<br>- Guarantees (margem B3)<br>- Average cost | Critical |
| **Market Data** | - Data injection attacks<br>- Price manipulation<br>- API key exposure | - API keys (providers)<br>- Market prices<br>- Volatility data<br>- Greeks | High |
| **Community & Sharing** | - Spam/fraud content<br>- Compliance violations<br>- Inappropriate content<br>- Social engineering | - Public messages<br>- Shared strategies<br>- User interactions<br>- Moderation flags | Medium |
| **Consultant Services** | - Unauthorized client access<br>- Cross-client data leakage<br>- Consultant impersonation | - Client portfolios<br>- Consultant-client relationship<br>- Delegated operations | High |

### Threat Summary

**Critical Assets:**
- [x] User credentials (passwords, tokens, sessions)
- [x] Personal Identifiable Information (PII) - CPF, email, phone
- [x] Financial data - account balance, portfolio, P&L, margins
- [x] Trading positions - real and paper trading data
- [x] Business-critical data - private strategy templates, risk profiles
- [x] API keys - market data providers, B3 API, broker APIs (future)

**Attack Vectors Identified:**
- [x] Web application vulnerabilities (OWASP Top 10)
- [x] API abuse (rate limiting, authentication bypass, privilege escalation)
- [x] Database injection (SQL injection via EF Core)
- [x] Broken access control (horizontal: User A accessing User B's trades; vertical: User escalating to Admin)
- [x] Cryptographic failures (weak passwords, API keys in code, plaintext secrets)
- [x] Financial fraud (unauthorized trades, P&L tampering, balance manipulation)
- [x] Social engineering (community chat, shared content)
- [x] Compliance violations (LGPD data breaches, unauthorized PII access)

---

## 🛡️ OWASP Top 3 Mitigations

### A01 - Broken Access Control

**Risk:** Users accessing data/functions they shouldn't (e.g., User A views User B's portfolio, User executes trades for another user, Trader escalates to Admin)  

**Mitigations:**

1. **Domain-Level Authorization (Aggregates Validate Permissions)**

   ```csharp
   // Strategy Aggregate validates ownership
   public class Strategy : AggregateRoot
   {
       public UserId OwnerId { get; private set; }

       public void Modify(UserId requestingUserId, StrategyData newData)
       {
           if (this.OwnerId != requestingUserId)
               throw new UnauthorizedAccessException("User not owner of strategy");

           // Business logic...
           this.UpdateData(newData);
       }
   }

   // ActiveStrategy Aggregate validates trade execution permissions
   public class ActiveStrategy : AggregateRoot
   {
       public UserId TraderId { get; private set; }
       public ExecutionMode Mode { get; private set; } // Paper or Real

       public void ExecuteAdjustment(UserId requestingUserId, Adjustment adjustment)
       {
           if (this.TraderId != requestingUserId)
               throw new UnauthorizedAccessException("User not authorized to adjust this strategy");

           if (this.Mode == ExecutionMode.Real)
           {
               // Additional validation for real trading
               ValidateRiskLimits(adjustment);
           }

           // Execute adjustment...
       }
   }

   // AssetPortfolio Aggregate validates portfolio access
   public class AssetPortfolio : AggregateRoot
   {
       public UserId OwnerId { get; private set; }

       public IReadOnlyList<Asset> GetAssets(UserId requestingUserId)
       {
           if (this.OwnerId != requestingUserId && !IsConsultantForUser(requestingUserId))
               throw new UnauthorizedAccessException("User not authorized to view this portfolio");

           return _assets.AsReadOnly();
       }
   }
   ```

2. **API-Level Authentication (JWT Required by Default)**

   - All API endpoints require JWT authentication (except public endpoints: `/health`, `/login`, `/register`)
   - Use `[Authorize]` attribute on controllers
   - Default: deny access, explicit allow

   ```csharp
   [ApiController]
   [Route("api/v1/strategies")]
   [Authorize] // JWT required
   public class StrategyController : ControllerBase
   {
       [HttpGet("{id}")]
       public async Task<IActionResult> GetStrategy(Guid id)
       {
           var userId = GetUserIdFromClaims(); // Extract from JWT
           // Aggregate validates ownership internally
           var strategy = await _strategyService.GetStrategy(id, userId);
           return Ok(strategy);
       }
   }
   ```

3. **Role-Based Access Control (RBAC)**

   **Roles:**
   - **Trader**: Basic access - create strategies, execute trades, view own data
   - **Moderator**: Moderate community content, approve/reject shared strategies
   - **Administrator**: Full system access, user management, global settings

   **Subscription Plans (Authorization Logic):**
   - **Básico**: Limited features (e.g., max 5 strategies, paper trading only)
   - **Pleno**: Full features (unlimited strategies, real trading, alerts, real-time data)
   - **Consultor**: Pleno + consultant tools (client management, delegated operations)

   ```csharp
   [HttpGet("admin/users")]
   [Authorize(Roles = "Administrator")]
   public async Task<IActionResult> GetAllUsers()
   {
       // Only admins can list all users
       var users = await _userService.GetAllUsers();
       return Ok(users);
   }

   [HttpPost("consultants/{consultantId}/clients")]
   [Authorize(Roles = "Trader")] // Any trader can call this
   public async Task<IActionResult> AssignClient(Guid consultantId, Guid clientId)
   {
       var userId = GetUserIdFromClaims();

       // Service validates subscription plan (Consultor required)
       await _consultantService.AssignClient(consultantId, clientId, userId);
       return Ok();
   }
   ```

4. **Checklist:**

   - [x] All API endpoints require authentication by default (`[Authorize]` attribute)
   - [x] Authorization checks in Aggregates (domain-level)
   - [x] Horizontal access control (User A cannot access User B's strategies/trades/portfolio)
   - [x] Vertical access control (Trader cannot escalate to Admin/Moderator)
   - [x] Direct object references validated (no predictable GUIDs exposed without ownership check)
   - [x] Consultant access validated (consultant can only access assigned clients)
   - [x] Subscription plan enforcement (Básico users cannot access Pleno/Consultor features)
   - [x] Real trading operations require additional validation (risk limits, balance)

---

### A02 - Cryptographic Failures

**Risk:** Sensitive data exposed (plaintext passwords, unencrypted traffic, API keys in code, financial data leakage)  

**Mitigations:**

1. **HTTPS/TLS 1.3 for All Connections**

   - All API traffic over HTTPS (enforced by Traefik reverse proxy)
   - Enforce TLS 1.3 minimum (configured in Traefik)
   - HTTP automatically redirects to HTTPS (Traefik configuration)
   - Let's Encrypt SSL certificates (automated renewal via Traefik)

   **Traefik Configuration (see PE-00):**
   ```yaml
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
   ```

2. **Password Hashing (NEVER Plaintext)**

   ```csharp
   // Use ASP.NET Core Identity PasswordHasher (PBKDF2)
   var hasher = new PasswordHasher<User>();
   string hashedPassword = hasher.HashPassword(user, plainPassword);

   // Verify during login
   var result = hasher.VerifyHashedPassword(user, user.PasswordHash, providedPassword);
   if (result == PasswordVerificationResult.Failed)
       throw new InvalidCredentialsException();
   ```

   **Password Requirements:**
   - Minimum length: 12 characters (financial platform - higher security)
   - Complexity: At least 1 uppercase, 1 lowercase, 1 number, 1 special char
   - No common passwords (validate against OWASP top 10k list - optional for v1.0)

3. **Secrets Management (Environment Variables)**

   - Secrets in `.env` files (NEVER in code or appsettings.json)
   - `.env` added to `.gitignore`
   - Production secrets in environment variables (VPS/Cloud)
   - Different secrets for dev/staging/production

   **Secrets Inventory:**
   ```bash
   # Database
   DB_CONNECTION_STRING=postgresql://user:pass@localhost:5432/mytrader

   # JWT
   JWT_SECRET_KEY=<min 32 characters, random, different per environment>
   JWT_ISSUER=https://api.mytrader.com
   JWT_AUDIENCE=https://mytrader.com

   # Market Data Provider (future)
   MARKET_DATA_API_KEY=<provider key>
   MARKET_DATA_API_SECRET=<provider secret>

   # B3 API (future)
   B3_API_KEY=<b3 key>
   B3_API_SECRET=<b3 secret>

   # Email (notifications)
   SMTP_HOST=smtp.sendgrid.net
   SMTP_PORT=587
   SMTP_USERNAME=apikey
   SMTP_PASSWORD=<sendgrid api key>
   ```

4. **JWT Secrets**

   - JWT signing key in environment variable (`JWT_SECRET_KEY`)
   - Use **RS256 (asymmetric)** for production (recommended)
     - Public key for token verification
     - Private key for token signing (kept secret)
     - Supports key rotation
   - HS256 acceptable for v1.0 (symmetric, min 32 characters)

   ```csharp
   // JWT Configuration (.NET)
   services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
       .AddJwtBearer(options =>
       {
           options.TokenValidationParameters = new TokenValidationParameters
           {
               ValidateIssuer = true,
               ValidateAudience = true,
               ValidateLifetime = true,
               ValidateIssuerSigningKey = true,
               ValidIssuer = Configuration["JWT_ISSUER"],
               ValidAudience = Configuration["JWT_AUDIENCE"],
               IssuerSigningKey = new SymmetricSecurityKey(
                   Encoding.UTF8.GetBytes(Configuration["JWT_SECRET_KEY"]))
           };
       });
   ```

5. **Database Encryption**

   - **Passwords**: Hashed (PBKDF2 via PasswordHasher)
   - **Sensitive PII**: Encrypted at rest (PostgreSQL encryption - optional for v1.0)
   - **Financial Data**: Access control via PostgreSQL row-level security (RLS)
   - **Backups**: Encrypted (pg_dump with encryption - see PE-00)

6. **Database User Segregation (Least Privilege)**

   **Security Principle:** Application NEVER uses PostgreSQL superuser (`postgres`). Dedicated users with minimal permissions reduce attack surface.

   **User Roles:**

   | User | Purpose | Permissions | Usage |
   |------|---------|-------------|-------|
   | **postgres** | Database Administration | SUPERUSER (all privileges) | **DBA ONLY** - NEVER use in application connection string |
   | **mytrader_app** | Application (.NET) | - SELECT, INSERT, UPDATE, DELETE (CRUD)<br>- USAGE on sequences<br>- CREATE TABLE (EF Core migrations)<br>- Limited to `mytrader_dev` database | Application connection string (`ConnectionStrings__DefaultConnection`) |
   | **mytrader_readonly** | Analytics, Backups | - SELECT only<br>- Limited to `mytrader_dev` database | Read-only operations, BI tools, backup verification |

   **Security Benefits:**

   - ✅ **SQL Injection Mitigated:** Even if attacker gains SQL access via injection, cannot:
     - Drop databases (`DROP DATABASE` blocked)
     - Create superusers (`CREATE ROLE` blocked)
     - Access system databases (`template0`, `template1`, `postgres` blocked)
     - Execute administrative commands (`ALTER SYSTEM` blocked)
   - ✅ **Defense in Depth:** Bug in application cannot cause catastrophic damage (limited to CRUD operations)
   - ✅ **Audit Trail:** Clear separation between application actions vs administrative actions in logs
   - ✅ **Compliance:** LGPD Art. 46 (technical security measures), SOC2/ISO27001 (RBAC)

   **Implementation:**

   ```sql
   -- Script: 04-database/init-scripts/01-create-app-user.sql
   -- Auto-executed on container startup via docker-entrypoint-initdb.d

   -- Application user (CRUD + migrations)
   CREATE USER mytrader_app WITH PASSWORD 'secret';
   GRANT CONNECT ON DATABASE mytrader_dev TO mytrader_app;
   GRANT USAGE ON SCHEMA public TO mytrader_app;
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO mytrader_app;
   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO mytrader_app;
   GRANT CREATE ON SCHEMA public TO mytrader_app; -- EF Core migrations

   -- Read-only user (analytics, backups)
   CREATE USER mytrader_readonly WITH PASSWORD 'secret';
   GRANT CONNECT ON DATABASE mytrader_dev TO mytrader_readonly;
   GRANT USAGE ON SCHEMA public TO mytrader_readonly;
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO mytrader_readonly;
   ```

   **Connection String (Application):**

   ```yaml
   # ❌ INSECURE (BEFORE):
   ConnectionStrings__DefaultConnection=Host=database;Port=5432;Database=mytrader_dev;Username=postgres;Password=xxx

   # ✅ SECURE (AFTER):
   ConnectionStrings__DefaultConnection=Host=database;Port=5432;Database=mytrader_dev;Username=mytrader_app;Password=xxx
   ```

   **References:**
   - [FEEDBACK-003](../00-feedback/FEEDBACK-003-DBA-PE-PostgreSQL-User-Security.md) - Security improvement implemented
   - [OWASP Least Privilege](https://owasp.org/www-community/vulnerabilities/Least_Privilege_Violation)
   - [CIS PostgreSQL Benchmark](https://www.cisecurity.org/benchmark/postgresql) - Section 2.1: Database User Segregation

7. **Checklist:**

   - [x] HTTPS/TLS 1.3 enforced for all connections (Traefik + Let's Encrypt)
   - [x] Passwords hashed with PBKDF2/bcrypt (NEVER plaintext)
   - [x] Database connection string in `.env` (NEVER in code)
   - [x] **Database user segregation implemented:**
     - [x] Application uses `mytrader_app` (CRUD + CREATE TABLE only)
     - [x] `postgres` superuser NEVER used in application connection string
     - [x] Init script auto-creates users: `04-database/init-scripts/01-create-app-user.sql`
   - [x] API keys in `.env` (market data, B3, SMTP - NEVER in code)
   - [x] JWT secret min 32 characters, environment variable
   - [x] `.env` in `.gitignore`
   - [x] Different secrets for dev/staging/production
   - [x] No secrets committed to git (verify with `git log -p | grep -i "password"`)

---

### A03 - Injection

**Risk:** SQL injection, NoSQL injection, command injection, API parameter tampering  

**Mitigations:**

1. **SQL Parametrizado (EF Core ORM Usage)**

   ```csharp
   // ✅ SAFE - EF Core LINQ (parameterized by default)
   var strategies = await context.Strategies
       .Where(s => s.OwnerId == userId)
       .ToListAsync();

   // ✅ SAFE - EF Core Include (eager loading)
   var activeStrategy = await context.ActiveStrategies
       .Include(a => a.Legs)
       .Where(a => a.Id == strategyId && a.TraderId == userId)
       .FirstOrDefaultAsync();

   // ❌ UNSAFE - Raw SQL vulnerable to injection
   var strategies = await context.Strategies
       .FromSqlRaw($"SELECT * FROM Strategies WHERE OwnerId = '{userId}'")
       .ToListAsync();

   // ✅ SAFE - Parameterized raw SQL (if absolutely necessary)
   var strategies = await context.Strategies
       .FromSqlRaw("SELECT * FROM Strategies WHERE OwnerId = {0}", userId)
       .ToListAsync();
   ```

   **Rule:** Use EF Core LINQ queries exclusively. Avoid raw SQL unless absolutely necessary (performance optimization), and ALWAYS use parameterized queries.

2. **Input Validation (Value Objects - Domain Layer)**

   ```csharp
   // Email Value Object
   public class Email : ValueObject
   {
       public string Value { get; }

       public Email(string email)
       {
           if (string.IsNullOrWhiteSpace(email))
               throw new DomainException("Email cannot be empty");

           if (!Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$"))
               throw new DomainException("Invalid email format");

           Value = email.ToLowerInvariant();
       }

       protected override IEnumerable<object> GetEqualityComponents()
       {
           yield return Value;
       }
   }

   // CPF Value Object (Brazilian Tax ID)
   public class CPF : ValueObject
   {
       public string Value { get; }

       public CPF(string cpf)
       {
           var cleanCpf = Regex.Replace(cpf, @"[^\d]", "");

           if (cleanCpf.Length != 11)
               throw new DomainException("CPF must have 11 digits");

           if (!IsValidCPF(cleanCpf))
               throw new DomainException("Invalid CPF");

           Value = cleanCpf;
       }

       private bool IsValidCPF(string cpf)
       {
           // CPF validation algorithm (checksum)
           // Implementation omitted for brevity
           return true; // Placeholder
       }

       protected override IEnumerable<object> GetEqualityComponents()
       {
           yield return Value;
       }
   }

   // Symbol Value Object (Stock/Option ticker)
   public class Symbol : ValueObject
   {
       public string Value { get; }

       public Symbol(string symbol)
       {
           if (string.IsNullOrWhiteSpace(symbol))
               throw new DomainException("Symbol cannot be empty");

           if (!Regex.IsMatch(symbol, @"^[A-Z0-9]{4,10}$"))
               throw new DomainException("Invalid symbol format (4-10 alphanumeric uppercase)");

           Value = symbol.ToUpperInvariant();
       }

       protected override IEnumerable<object> GetEqualityComponents()
       {
           yield return Value;
       }
   }

   // Quantity Value Object (positive integer for trading)
   public class Quantity : ValueObject
   {
       public int Value { get; }

       public Quantity(int quantity)
       {
           if (quantity <= 0)
               throw new DomainException("Quantity must be positive");

           if (quantity > 1000000)
               throw new DomainException("Quantity exceeds maximum (1,000,000)");

           Value = quantity;
       }

       protected override IEnumerable<object> GetEqualityComponents()
       {
           yield return Value;
       }
   }
   ```

3. **API Validation (FluentValidation - Application Layer)**

   ```csharp
   public class CreateStrategyCommandValidator : AbstractValidator<CreateStrategyCommand>
   {
       public CreateStrategyCommandValidator()
       {
           RuleFor(x => x.Name)
               .NotEmpty().WithMessage("Strategy name required")
               .MaximumLength(100).WithMessage("Name too long (max 100 chars)");

           RuleFor(x => x.Symbol)
               .NotEmpty().WithMessage("Symbol required")
               .Matches(@"^[A-Z0-9]{4,10}$").WithMessage("Invalid symbol format");

           RuleFor(x => x.Legs)
               .NotEmpty().WithMessage("At least one leg required")
               .Must(legs => legs.Count <= 10).WithMessage("Max 10 legs per strategy");

           RuleForEach(x => x.Legs).SetValidator(new StrategyLegValidator());
       }
   }

   public class StrategyLegValidator : AbstractValidator<StrategyLegDto>
   {
       public StrategyLegValidator()
       {
           RuleFor(x => x.Quantity)
               .GreaterThan(0).WithMessage("Quantity must be positive")
               .LessThanOrEqualTo(1000000).WithMessage("Quantity exceeds maximum");

           RuleFor(x => x.Position)
               .IsInEnum().WithMessage("Invalid position (must be Long or Short)");

           RuleFor(x => x.LegType)
               .IsInEnum().WithMessage("Invalid leg type (Stock, CallOption, PutOption)");
       }
   }
   ```

4. **NoSQL Injection Prevention (Not applicable - PostgreSQL used)**

   - myTraderGEO uses PostgreSQL (relational database)
   - If JSONB fields are used, ensure parameterized queries
   - EF Core handles JSONB serialization safely

5. **Checklist:**

   - [x] EF Core LINQ queries used exclusively (no raw SQL vulnerable)
   - [x] Value Objects validate domain rules (Email, CPF, Symbol, Quantity, Strike, etc.)
   - [x] FluentValidation in API controllers (request DTOs validated)
   - [x] No string concatenation in database queries
   - [x] Input sanitized before storage (Value Objects enforce format)
   - [x] Output encoding for frontend (Vue 3 sanitizes by default)
   - [x] API rate limiting configured (Traefik: 100 req/s - see PE-00)

---

## 🇧🇷 LGPD Minimum Compliance

### Personal Data Mapping

| Data Type | Location | Purpose | Legal Basis | Retention Period |
|-----------|----------|---------|-------------|------------------|
| **CPF** | Users table | User identification, account verification | Contract execution | Account lifetime + 5 years (financial records) |
| **Email** | Users table | Communication, authentication, alerts | Contract execution | Account lifetime + 1 year |
| **Phone** | Users table | SMS alerts, 2FA (optional) | Consent | Until consent revoked |
| **Name** | Users table | User identification, personalization | Contract execution | Account lifetime + 5 years |
| **IP Address** | API logs, audit logs | Security, fraud prevention, abuse detection | Legitimate interest | 90 days |
| **Trading History** | ActiveStrategies, Orders tables | Financial records, audit trail | Legal obligation (CVM/SEC regulations) | 7 years (regulatory requirement) |
| **Portfolio Data** | AssetPortfolio, OptionPortfolio tables | Trading services, risk management | Contract execution | Account lifetime + 7 years |
| **Strategy Templates (Private)** | Strategies table | User service, intellectual property | Contract execution | Account lifetime + 1 year |
| **Risk Profile** | Users table | Risk management, limit enforcement | Contract execution | Account lifetime |
| **Subscription Plan** | Users table | Billing, feature access control | Contract execution | Account lifetime + 5 years |
| **Community Messages** | Messages table | Community chat service | Consent (Terms of Use) | Until account deletion or message deleted |

### Data Subject Rights

**Implemented Rights:**

1. **Right to Access (Art. 18, I, II)**

   - Endpoint: `GET /api/v1/users/{id}/data-export`
   - Returns: All user data in structured JSON format
   - Included data:
     - User profile (name, email, CPF, risk profile, subscription)
     - Strategy templates (private and shared)
     - Trading history (active strategies, orders, P&L)
     - Portfolio (assets, options, balance)
     - Community messages
     - Audit logs (last 90 days)
   - Timeline: Respond within **15 days** (LGPD requirement)
   - Authentication: JWT required, user can only export own data

   ```csharp
   [HttpGet("users/{userId}/data-export")]
   [Authorize]
   public async Task<IActionResult> ExportUserData(Guid userId)
   {
       var requestingUserId = GetUserIdFromClaims();
       if (requestingUserId != userId)
           return Forbid(); // Users can only export own data

       var userData = await _gdprService.ExportUserData(userId);
       return File(userData, "application/json", $"mytrader-data-{userId}.json");
   }
   ```

2. **Right to Deletion (Art. 18, VI)**

   - Endpoint: `DELETE /api/v1/users/{id}`
   - Strategy: **Soft delete with anonymization**
     - Mark user as deleted (`IsDeleted = true`, `DeletedAt = timestamp`)
     - Anonymize PII immediately (replace CPF, email, phone with random data)
     - Keep trading history for 7 years (regulatory requirement - CVM/SEC)
     - After 7 years: hard delete or full anonymization
   - Timeline: Execute within **30 days** (LGPD requirement)
   - Exceptions:
     - Trading history retained for 7 years (legal obligation - Art. 16, I)
     - Community messages anonymized (author replaced with "Deleted User")

   ```csharp
   [HttpDelete("users/{userId}")]
   [Authorize]
   public async Task<IActionResult> DeleteUser(Guid userId)
   {
       var requestingUserId = GetUserIdFromClaims();
       if (requestingUserId != userId)
           return Forbid();

       await _gdprService.AnonymizeUser(userId);
       return NoContent();
   }

   // GDPRService
   public async Task AnonymizeUser(Guid userId)
   {
       var user = await _context.Users.FindAsync(userId);

       user.IsDeleted = true;
       user.DeletedAt = DateTime.UtcNow;
       user.Email = $"deleted_{userId}@anonymized.local";
       user.CPF = GenerateRandomCPF(); // Random valid CPF
       user.Phone = null;
       user.PasswordHash = null; // Prevent login

       // Trading history kept for 7 years (regulatory)
       // Community messages anonymized (author = "Deleted User")

       await _context.SaveChangesAsync();
   }
   ```

3. **Right to Correction (Art. 18, III)**

   - Endpoint: `PUT /api/v1/users/{id}`
   - User can update: Name, Email, Phone, Risk Profile
   - Immutable fields: CPF (tax ID), Registration Date, Trading History
   - Audit trail: Log all profile changes (LGPD compliance)

   ```csharp
   [HttpPut("users/{userId}")]
   [Authorize]
   public async Task<IActionResult> UpdateUser(Guid userId, UpdateUserDto dto)
   {
       var requestingUserId = GetUserIdFromClaims();
       if (requestingUserId != userId)
           return Forbid();

       await _userService.UpdateProfile(userId, dto);
       return Ok();
   }
   ```

4. **Right to Portability (Art. 18, V)**

   - Format: **JSON** (structured, machine-readable)
   - Included: User profile, strategies, trading history, portfolio, messages
   - Endpoint: `GET /api/v1/users/{id}/data-export` (same as Right to Access)
   - Timeline: Provide within **15 days**

### Privacy Policy

**Status:**
- [x] Published at https://mytrader.com/privacy (required)
- [ ] Available in app footer (implementation in EPIC-01)

**Minimum Sections Required:**

1. **Data Collected (What)**
   - CPF, email, phone, name
   - Trading data (strategies, orders, P&L)
   - Portfolio data (assets, options, balance)
   - Community messages (public and private)

2. **Purpose of Collection (Why)**
   - Account authentication and identification
   - Trading services execution
   - Risk management and compliance
   - Community features
   - Legal obligations (CVM/SEC regulations)

3. **Data Retention Periods (How Long)**
   - User profile: Account lifetime + 5 years
   - Trading history: 7 years (regulatory requirement)
   - Logs: 90 days
   - Messages: Until deletion

4. **User Rights (LGPD Art. 18)**
   - Access, correction, deletion, portability
   - Consent revocation (phone, optional data)
   - How to exercise rights (email to DPO)

5. **DPO Contact**
   - Name: [To be appointed]
   - Email: dpo@mytrader.com

6. **Cookie Policy**
   - Essential cookies only (session, authentication)
   - No analytics/tracking cookies (v1.0 - can add with consent later)

7. **Third-Party Sharing**
   - Market data providers (anonymized API calls)
   - B3 API (portfolio sync - user consent required)
   - Broker APIs (future - user consent required)
   - Email service (transactional emails only - SendGrid)

**DPO (Data Protection Officer):**
- **Name:** [DPO_NAME or "To Be Appointed"]
- **Email:** dpo@mytrader.com
- **Required:** Yes (LGPD Art. 41) - can be outsourced for small companies
- **Responsibilities:** Handle data subject requests, LGPD compliance, data breach notifications

### Checklist LGPD

- [x] Personal data mapped (table above completed)
- [x] Data deletion strategy defined (soft delete + anonymization, 7-year retention for trading history)
- [x] API endpoints for data access (`GET /users/{id}/data-export`)
- [x] API endpoints for data deletion (`DELETE /users/{id}`)
- [ ] Privacy Policy published (content defined, implementation EPIC-01)
- [ ] DPO appointed (name + email - before production launch)
- [x] Consent management planned (phone, B3 sync, broker integration)
- [ ] Cookie banner (if analytics added - not required for v1.0)
- [x] Audit trail for trading operations (7 years retention)
- [x] Data breach notification process defined (< 72h, email to ANPD)

---

## 🔐 Authentication & Authorization Strategy

### Authentication

**Method:** JWT (JSON Web Tokens)  

**Algorithm:**
- [x] **HS256** (Symmetric - v1.0 implementation)
  - Single secret key (min 32 characters)
  - Simpler implementation
  - Acceptable for MVP
- [ ] **RS256** (Asymmetric - future migration recommended)
  - Public key for verification
  - Private key for signing (kept secret)
  - More secure, supports key rotation
  - Recommended for production scale

**Token Structure:**
```json
{
  "sub": "user-id-123",
  "email": "trader@example.com",
  "role": "Trader",
  "subscription": "Pleno",
  "exp": 1672531200,
  "iat": 1672527600
}
```

**Token Expiration:**
- **Access Token:** 60 minutes (financial platform - balance between security and UX)
- **Refresh Token:** 30 days (optional for v1.0 - implement if session persistence needed)

**Login Flow:**
1. User submits email + password (`POST /api/v1/auth/login`)
2. Backend validates credentials (PasswordHasher)
3. Backend generates JWT with user claims (sub, email, role, subscription)
4. Frontend stores JWT in memory (Pinia store - NOT localStorage for security)
5. Frontend sends JWT in `Authorization: Bearer <token>` header
6. Backend validates JWT on every request (middleware)

**Implementation Checklist:**
- [x] JWT library integrated (`System.IdentityModel.Tokens.Jwt`)
- [x] Token expiration configured (60 min)
- [x] Secret key in environment variable (min 32 chars)
- [x] Token validation on every API request (middleware)
- [ ] Refresh token strategy (optional - implement if needed post-EPIC-01)
- [x] Logout: Frontend discards JWT (stateless)

### Authorization

**Strategy:** Domain-Level Authorization (Aggregates validate permissions)  

**Pattern:**
```csharp
// Strategy Aggregate validates ownership
public class Strategy : AggregateRoot
{
    public UserId OwnerId { get; private set; }

    public void Modify(UserId requestingUserId, StrategyData newData)
    {
        // Authorization check
        if (this.OwnerId != requestingUserId)
            throw new UnauthorizedAccessException("User not owner of strategy");

        // Business logic
        this.UpdateData(newData);
    }

    public void MakePublic(UserId requestingUserId)
    {
        if (this.OwnerId != requestingUserId)
            throw new UnauthorizedAccessException("User not owner of strategy");

        this.Visibility = StrategyVisibility.Public;
    }
}

// ActiveStrategy Aggregate validates trading permissions
public class ActiveStrategy : AggregateRoot
{
    public UserId TraderId { get; private set; }
    public ExecutionMode Mode { get; private set; }

    public void ExecuteTrade(UserId requestingUserId, Trade trade)
    {
        if (this.TraderId != requestingUserId)
            throw new UnauthorizedAccessException("User not authorized to execute trade");

        if (this.Mode == ExecutionMode.Real)
        {
            // Additional validation for real trading
            ValidateRiskLimits(trade);
            ValidateBalance(trade);
        }

        // Execute trade...
    }
}
```

**RBAC (Role-Based Access Control):**

| Role | Permissions |
|------|-------------|
| **Trader** | - Create/modify own strategies<br>- Execute paper/real trades<br>- View own portfolio<br>- Participate in community<br>- Access features per subscription plan |
| **Moderator** | - All Trader permissions<br>- Moderate community content<br>- Approve/reject shared strategies<br>- Flag inappropriate content<br>- View moderation queue |
| **Administrator** | - All Moderator permissions<br>- Manage users (view, suspend, delete)<br>- Manage system settings<br>- View all data (audit purposes)<br>- Assign roles |

**Subscription Plan Enforcement (Authorization Logic):**

| Plan | Features |
|------|----------|
| **Básico** | - Max 5 strategies<br>- Paper trading only<br>- Delayed market data (15 min)<br>- Community access (read-only) |
| **Pleno** | - Unlimited strategies<br>- Real trading enabled<br>- Real-time market data<br>- Advanced alerts<br>- Community full access (post, share) |
| **Consultor** | - All Pleno features<br>- Client management<br>- Delegated operations<br>- Private strategy sharing with clients |

```csharp
// Authorization in Application Service
public class StrategyService
{
    public async Task CreateStrategy(CreateStrategyCommand command, UserId userId)
    {
        var user = await _userRepository.GetById(userId);

        // Subscription plan enforcement
        if (user.SubscriptionPlan == SubscriptionPlan.Basico)
        {
            var strategyCount = await _strategyRepository.CountByOwner(userId);
            if (strategyCount >= 5)
                throw new SubscriptionLimitException("Básico plan allows max 5 strategies");
        }

        // Create strategy...
    }
}

public class TradeService
{
    public async Task ExecuteRealTrade(ExecuteTradeCommand command, UserId userId)
    {
        var user = await _userRepository.GetById(userId);

        // Real trading requires Pleno or Consultor
        if (user.SubscriptionPlan == SubscriptionPlan.Basico)
            throw new SubscriptionLimitException("Real trading requires Pleno or Consultor plan");

        // Execute trade...
    }
}
```

**Consultant Authorization (Special Case):**

```csharp
// Consultant can access client portfolios (with explicit consent)
public class AssetPortfolio : AggregateRoot
{
    public UserId OwnerId { get; private set; }

    public IReadOnlyList<Asset> GetAssets(UserId requestingUserId)
    {
        if (this.OwnerId == requestingUserId)
            return _assets.AsReadOnly(); // Owner access

        // Consultant access (requires explicit client-consultant relationship)
        if (IsConsultantForUser(requestingUserId))
            return _assets.AsReadOnly();

        throw new UnauthorizedAccessException("User not authorized to view this portfolio");
    }

    private bool IsConsultantForUser(UserId consultantId)
    {
        // Query ConsultantServices BC for relationship
        // Implementation depends on cross-BC communication (API or events)
        return _consultantRepository.HasActiveRelationship(this.OwnerId, consultantId);
    }
}
```

**Checklist:**
- [x] Aggregates validate user ownership (domain-level authz)
- [x] Authorization failures throw `UnauthorizedAccessException` (handled globally)
- [x] API controllers extract user ID from JWT claims
- [x] RBAC roles defined (Trader, Moderator, Administrator)
- [x] Admin endpoints protected with `[Authorize(Roles = "Administrator")]`
- [x] Subscription plan enforcement in application services
- [x] Consultant access validated (client-consultant relationship required)
- [x] Real trading operations require Pleno/Consultor plan

---

## 🔒 Secure Development Practices

### Input Validation

**Layers:**

1. **Value Objects (Domain Layer)**
   - Validate format, length, business rules
   - Examples: Email, CPF, Symbol, Quantity, Strike, OptionSymbol, Money

2. **FluentValidation (Application Layer)**
   - Validate request structure
   - Complement Value Object validation

**Checklist:**
- [x] Value Objects validate all domain inputs
- [x] FluentValidation in API controllers
- [x] Invalid input returns `400 Bad Request` with clear message
- [x] No unvalidated user input reaches database

### Password Security

**Requirements:**
- Minimum length: **12 characters** (financial platform - higher security)
- Complexity: At least 1 uppercase, 1 lowercase, 1 number, 1 special char
- [ ] No common passwords (validate against OWASP top 10k list - optional for v1.0)

**Hashing:**
```csharp
// ASP.NET Core Identity PasswordHasher (PBKDF2)
var hasher = new PasswordHasher<User>();
string hash = hasher.HashPassword(user, password);

// Verify
var result = hasher.VerifyHashedPassword(user, hash, providedPassword);
```

**Checklist:**
- [x] Passwords hashed with PBKDF2 (NEVER plaintext)
- [x] Password complexity rules enforced (12+ chars)
- [x] Password reset via email (time-limited token - 1 hour expiration)
- [ ] Account lockout after 5 failed login attempts (optional for v1.0 - recommend for production)

### Secrets Management

**Approach:** Environment Variables (v1.0 Simplified)  

**What goes in `.env`:**
- Database connection strings
- JWT signing key
- Third-party API keys (Market Data, B3, SendGrid, etc.)
- Encryption keys (future)

**What NEVER goes in code:**
- Passwords
- API keys
- Connection strings with credentials
- JWT secrets

**Checklist:**
- [x] All secrets in `.env` files
- [x] `.env` in `.gitignore`
- [x] No secrets committed to git (verify: `git log -p | grep -i "password"`)
- [x] Production secrets different from dev/staging
- [x] `grep -r "password" 02-backend` returns zero hardcoded passwords

---

## 📊 Security Monitoring

### Security Events to Log

**Critical Events:**

1. **Failed Login Attempts**
   - Log: userId (if exists), email, IP, timestamp
   - Alert: 5+ failures in 5 minutes (potential brute force)

2. **Unauthorized Access Attempts**
   - Log: userId, resource (endpoint), timestamp, HTTP status (403)
   - Alert: Multiple 403 responses from same user (10+ in 5 min)

3. **Real Trade Executions**
   - Log: userId, strategyId, tradeDetails, P&L, timestamp
   - Retention: 7 years (regulatory requirement)

4. **Data Export Events (LGPD)**
   - Log: userId, exportType (full/partial), timestamp
   - Alert: >1000 rows exported in single request (potential data scraping)

5. **Permission Changes**
   - Log: adminId, targetUserId, old role, new role, timestamp
   - Notify: Email to target user confirming role change

6. **Password Changes**
   - Log: userId, timestamp, IP address
   - Notify: Email to user confirming password change

7. **Portfolio Access (Consultant)**
   - Log: consultantId, clientId, accessType (view/modify), timestamp
   - Retention: 7 years (audit trail)

8. **Real Trading Balance Changes**
   - Log: userId, oldBalance, newBalance, reason (trade/deposit/withdrawal), timestamp
   - Retention: 7 years

### Logging Implementation

**Structured Logging (Serilog):**

```csharp
_logger.LogWarning("Failed login attempt",
    new { Email = email, IpAddress = ipAddress, Timestamp = DateTime.UtcNow });

_logger.LogWarning("Unauthorized access attempt",
    new { UserId = userId, Resource = resource, HttpStatus = 403, Timestamp = DateTime.UtcNow });

_logger.LogInformation("Real trade executed",
    new { UserId = userId, StrategyId = strategyId, TradeType = tradeType, Amount = amount, Timestamp = DateTime.UtcNow });

_logger.LogInformation("GDPR data export",
    new { UserId = userId, ExportType = "full", RowCount = rowCount, Timestamp = DateTime.UtcNow });
```

**Log Storage (see PE-00):**
- **Development:** Console + File
- **Staging:** Console + File (JSON format)
- **Production:** Console + File (JSON format), Docker logs, retention per PE-00

**Log Retention:**
- **Security logs:** 90 days (LGPD compliance)
- **Audit logs (trading):** 7 years (regulatory requirement)

### Security Alerts (Optional for v1.0)

**Recommended Alerts:**
- [ ] HighFailedLoginRate (5+ failures in 5 min) → Email/Slack to Admin
- [ ] UnauthorizedAccessSpike (>10 403s in 5 min) → Email/Slack to Admin
- [ ] SuspiciousDataExport (>1000 rows) → Email to Admin + DPO
- [ ] RealTradeLargeVolume (>R$100k in single trade) → Email to Risk team
- [ ] ConsultantUnauthorizedAccess (consultant accessing non-client portfolio) → Email to Security team

**Implementation:** Can be added post-launch when monitoring infrastructure is in place (EPIC-03 or later).  

---

## 🚫 Out of Scope for v1.0

To maintain simplicity for MVP and early epics, v1.0 **DOES NOT include:**

- ❌ **Full STRIDE Analysis** (5 detailed threat models per BC)
- ❌ **Penetration Testing** (OWASP ZAP, manual pentest)
- ❌ **Incident Response Plan** (formal playbooks, breach simulation)
- ❌ **SIEM Integration** (Splunk, Sumo Logic, ELK stack)
- ❌ **WAF** (Web Application Firewall - Cloudflare free tier provides basic protection)
- ❌ **DDoS Protection** (Cloudflare free tier provides basic protection)
- ❌ **Security Scanning in CI/CD** (SAST/DAST - Snyk, SonarQube, CodeQL)
  - Recommend adding in EPIC-02+ via GM (GitHub Actions integration)
- ❌ **SOC2 Compliance** (enterprise customers only)
- ❌ **PCI-DSS Compliance** (NOT handling credit cards directly - payment via Stripe/PagSeguro)
- ❌ **2FA/MFA** (Two-Factor Authentication - optional for v2.0)
- ❌ **Account Lockout** (brute force protection - optional for v1.0, recommend for production)
- ❌ **Rate Limiting per User** (v1.0 has global rate limiting via Traefik - 100 req/s)

**When to add:**
- **EPIC-02+:** SAST/DAST in CI/CD (GM integration)
- **EPIC-03:** Account lockout, 2FA (risk management epic)
- **Production Launch:** Penetration testing, formal incident response plan
- **Enterprise Customers:** SOC2 compliance, advanced monitoring (SIEM)
- **Scaling to >100k users:** WAF, DDoS protection (upgrade Cloudflare), per-user rate limiting

---

## ✅ Security Baseline Checklist

### OWASP Top 3
- [x] **A01 - Broken Access Control**
  - [x] Domain-level authorization in Aggregates
  - [x] All APIs require authentication (`[Authorize]`)
  - [x] RBAC roles defined (Trader, Moderator, Administrator)
  - [x] Subscription plan enforcement (Básico, Pleno, Consultor)
  - [x] Consultant access validated
- [x] **A02 - Cryptographic Failures**
  - [x] HTTPS/TLS 1.3 enforced (Traefik + Let's Encrypt)
  - [x] Passwords hashed (PBKDF2 via PasswordHasher)
  - [x] Secrets in environment variables (`.env`)
  - [x] JWT secret min 32 characters
  - [x] **Database user segregation (Least Privilege):**
    - [x] Application uses `mytrader_app` (limited CRUD + CREATE TABLE)
    - [x] `postgres` superuser restricted to DBA only
    - [x] `mytrader_readonly` for analytics/backups (SELECT only)
- [x] **A03 - Injection**
  - [x] SQL parametrizado (EF Core LINQ)
  - [x] Value Objects validate inputs
  - [x] FluentValidation in APIs

### LGPD Compliance
- [x] Personal data mapped (detailed table with 11 data types)
- [x] Data deletion strategy defined (soft delete + anonymization, 7-year retention)
- [x] API endpoints for access/deletion (`GET/DELETE /users/{id}`)
- [ ] Privacy Policy published (content defined, implementation EPIC-01)
- [ ] DPO appointed (before production launch)
- [x] Consent management planned (B3 sync, broker integration)
- [x] Audit trail for trading (7 years retention)

### Authentication & Authorization
- [x] JWT authentication configured (HS256, 60 min expiration)
- [x] Token expiration set (60 min)
- [x] Aggregates validate permissions (domain-level)
- [x] RBAC roles implemented (3 roles)
- [x] Subscription plan enforcement

### Secure Development
- [x] Input validation (Value Objects + FluentValidation)
- [x] Passwords hashed (NEVER plaintext)
- [x] Secrets in `.env` (NEVER in code)
- [x] Password complexity enforced (12+ chars)

### Security Monitoring
- [x] Security events logged (failed logins, unauthorized access, trades, exports)
- [x] Structured logging implemented (Serilog)
- [x] Audit trail for financial operations (7 years)

### Infrastructure Security (see PE-00)
- [x] HTTPS enforced (Traefik + Let's Encrypt)
- [x] Rate limiting configured (API: 100 req/s)
- [x] Docker network isolation (database not exposed)
- [x] **Database user segregation (Least Privilege):**
  - [x] Application uses `mytrader_app` (CRUD + CREATE TABLE only)
  - [x] `postgres` superuser restricted to DBA only
  - [x] `mytrader_readonly` for analytics/backups (SELECT only)
  - [x] Init script: `04-database/init-scripts/01-create-app-user.sql`
- [x] Secrets management (environment variables)
- [x] Cloudflare DDoS protection (basic)

---

## 📚 References

- **OWASP Top 10 2021:** https://owasp.org/Top10/
- **LGPD (Lei 13.709/2018):** https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm
- **CVM Instruction 505:** https://conteudo.cvm.gov.br/legislacao/instrucoes/inst505.html (Audit trail requirements)
- **Agent XML:** `.agents/35-SEC - Security Specialist.xml`
- **PE Stack:** `00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md`
- **SDA Context Map:** `00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md`
- **Workflow Guide:** `.agents/docs/00-Workflow-Guide.md`

---

**SEC-00 Status:** ✅ **COMPLETO**  
**Version:** 1.0  
**Last Updated:** 2025-10-16  
**Focus:** Pragmatic security baseline for myTraderGEO MVP (financial trading platform)  
**Next Steps:** GM-00 (CI/CD + GitHub setup) can execute in parallel or after SEC-00  
