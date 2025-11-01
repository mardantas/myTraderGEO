<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)  
- Use blank lines between sections for readability (content)  
- Validate in Markdown preview before committing  
-->

# SEC-00 - Security Baseline

**Agent:** SEC (Security Specialist)  
**Project:** [PROJECT_NAME]  
**Date:** [YYYY-MM-DD]  
**Phase:** Discovery (1x)  
**Scope:** Essential security baseline for small/medium projects  
**Version:** 3.0  
  
---  

## 📋 Metadata

- **Project Name:** [PROJECT_NAME]  
- **Created:** [DATE]  
- **Security Engineer:** [NAME]  
- **Target:** Small/Medium Projects  
- **Approach:** OWASP Top 3 + LGPD Minimum + Auth Strategy  

---

## 🎯 Objetivo

Definir baseline de segurança essencial para projetos small/medium: OWASP Top 3 mitigations, LGPD compliance mínimo, e estratégias de autenticação/autorização.

---

## 🔍 Threat Identification

### Main Threats per Bounded Context

| Bounded Context | Main Threats | Sensitive Data | Priority |
|-----------------|--------------|----------------|----------|
| **[BC_NAME_1]** | - Credential theft<br>- Unauthorized access | - User credentials<br>- Authentication tokens | High |
| **[BC_NAME_2]** | - Data breach<br>- Injection attacks | - Personal data (CPF, email)<br>- Financial data | High |
| **[BC_NAME_3]** | - Business logic bypass<br>- Privilege escalation | - Order data<br>- Transaction history | Medium |

### Threat Summary

**Critical Assets:**  
- [ ] User credentials (passwords, tokens)  
- [ ] Personal Identifiable Information (PII) - CPF, email, phone  
- [ ] Financial data (if applicable)  
- [ ] Business-critical data (orders, transactions, strategies)  

**Attack Vectors Identified:**  
- [ ] Web application vulnerabilities (OWASP Top 10)  
- [ ] API abuse (rate limiting, authentication bypass)  
- [ ] Database injection (SQL, NoSQL)  
- [ ] Broken access control (horizontal/vertical privilege escalation)  
- [ ] Cryptographic failures (weak passwords, plaintext secrets)  

---

## 🛡️ OWASP Top 3 Mitigations

### A01 - Broken Access Control

**Risk:** Users accessing data/functions they shouldn't (e.g., User A views User B's orders)  

**Mitigations:**  

1. **Domain-Level Authorization**
   ```csharp
   // Aggregates validate permissions
   public class Order : AggregateRoot
   {
       public void ChangeStatus(UserId requestingUserId, OrderStatus newStatus)
       {
           if (this.CustomerId != requestingUserId)
               throw new DomainException("User not authorized to modify this order");

           // Business logic...
       }
   }
   ```

2. **API-Level Authentication**
   - All API endpoints require JWT authentication (except public endpoints)  
   - Use `[Authorize]` attribute on controllers  
   - Default: deny access, explicit allow  

3. **Role-Based Access Control (RBAC)**
   ```
   Roles:
   - User (basic access)  
   - Admin (full access)  
   - [CustomRole] (specific permissions)  
   ```

4. **Checklist:**
   - [ ] All API endpoints require authentication by default  
   - [ ] Authorization checks in Aggregates (domain-level)  
   - [ ] Horizontal access control (User A cannot access User B's data)  
   - [ ] Vertical access control (User cannot escalate to Admin)  
   - [ ] Direct object references validated (no predictable IDs in URLs)  

---

### A02 - Cryptographic Failures

**Risk:** Sensitive data exposed (plaintext passwords, unencrypted traffic, secrets in code)  

**Mitigations:**  

1. **HTTPS/TLS 1.3 for All Connections**
   - All API traffic over HTTPS  
   - Enforce TLS 1.3 minimum  
   - HTTP automatically redirects to HTTPS  

2. **Password Hashing (NEVER Plaintext)**
   ```csharp
   // Use bcrypt, Argon2, or ASP.NET PasswordHasher
   var hasher = new PasswordHasher<User>();
   string hashedPassword = hasher.HashPassword(user, plainPassword);

   // Verify
   var result = hasher.VerifyHashedPassword(user, hashedPassword, providedPassword);
   ```

3. **Secrets Management**
   - Secrets in `.env` files (NEVER in code or appsettings.json)  
   - `.env` added to `.gitignore`  
   - Production secrets in environment variables (server)  

4. **JWT Secrets**
   - JWT signing key in environment variable  
   - Use RS256 (asymmetric) for production (recommended)  
   - HS256 acceptable for small projects (symmetric, min 32 chars)  

5. **Checklist:**
   - [ ] HTTPS/TLS 1.3 enforced for all connections  
   - [ ] Passwords hashed with bcrypt/Argon2 (NEVER plaintext)  
   - [ ] Database passwords in `.env` (NEVER in code)  
   - [ ] API keys in `.env` (NEVER in code)  
   - [ ] JWT secret min 32 characters, environment variable  
   - [ ] `.env` in `.gitignore`  

---

### A03 - Injection

**Risk:** SQL injection, NoSQL injection, command injection  

**Mitigations:**  

1. **SQL Parametrizado (ORM Usage)**
   ```csharp
   // ✅ SAFE - EF Core LINQ
   var orders = await context.Orders
       .Where(o => o.CustomerId == userId)
       .ToListAsync();

   // ❌ UNSAFE - Raw SQL vulnerable
   var orders = await context.Orders
       .FromSqlRaw($"SELECT * FROM Orders WHERE CustomerId = {userId}")
       .ToListAsync();

   // ✅ SAFE - Parameterized raw SQL (if needed)
   var orders = await context.Orders
       .FromSqlRaw("SELECT * FROM Orders WHERE CustomerId = {0}", userId)
       .ToListAsync();
   ```

2. **Input Validation (Value Objects)**
   ```csharp
   public class Email : ValueObject
   {
       public string Value { get; }

       public Email(string email)
       {
           if (string.IsNullOrWhiteSpace(email))
               throw new DomainException("Email cannot be empty");

           if (!Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$"))
               throw new DomainException("Invalid email format");

           Value = email;
       }
   }
   ```

3. **API Validation (FluentValidation)**
   ```csharp
   public class CreateOrderCommandValidator : AbstractValidator<CreateOrderCommand>
   {
       public CreateOrderCommandValidator()
       {
           RuleFor(x => x.Quantity).GreaterThan(0);
           RuleFor(x => x.Symbol).NotEmpty().MaximumLength(10);
       }
   }
   ```

4. **NoSQL Injection Prevention**
   - Use ORM/ODM queries (avoid string concatenation)  
   - Validate input types (no direct user input in queries)  

5. **Checklist:**
   - [ ] EF Core LINQ queries used (no raw SQL vulnerable)  
   - [ ] Value Objects validate domain rules (Email, CPF, etc.)  
   - [ ] FluentValidation in API controllers  
   - [ ] No string concatenation in database queries  
   - [ ] Input sanitized before storage/display  

---

## 🇧🇷 LGPD Minimum Compliance

### Personal Data Mapping

| Data Type | Location | Purpose | Legal Basis | Retention Period |
|-----------|----------|---------|-------------|------------------|
| **CPF** | Users table | User identification | Contract execution | Account lifetime + 5 years |
| **Email** | Users table | Communication, authentication | Contract execution | Account lifetime + 1 year |
| **Phone** | Users table | Communication | Consent | Until consent revoked |
| **Name** | Users table | User identification | Contract execution | Account lifetime + 5 years |
| **IP Address** | Logs | Security, fraud prevention | Legitimate interest | 90 days |
| **[Other]** | [Table/Service] | [Purpose] | [Basis] | [Period] |

### Data Subject Rights

**Implemented Rights:**  

1. **Right to Access (Art. 18, I, II)**
   - Endpoint: `GET /api/v1/users/{id}/data-export`  
   - Returns: All user data in JSON format  
   - Timeline: Respond within 15 days  

2. **Right to Deletion (Art. 18, VI)**
   - Endpoint: `DELETE /api/v1/users/{id}`  
   - Strategy: [Choose one]  
     - [ ] Hard delete (permanent removal)  
     - [ ] Soft delete (mark as deleted, anonymize after retention period)  
     - [ ] Anonymization (replace PII with random data)  
   - Timeline: Execute within 30 days  

3. **Right to Correction (Art. 18, III)**
   - Endpoint: `PUT /api/v1/users/{id}`  
   - User can update: Name, Email, Phone  
   - Immutable fields: CPF, Registration Date  

4. **Right to Portability (Art. 18, V)**
   - Format: JSON (structured data)  
   - Included: User data, Orders, Transactions  
   - Endpoint: `GET /api/v1/users/{id}/data-export`  

### Privacy Policy

**Status:** [Choose one]  
- [ ] Published at [URL]  
- [ ] Draft ready for review  
- [ ] Pending creation  

**Minimum Sections Required:**  
1. Data collected (what)
2. Purpose of collection (why)
3. Data retention periods (how long)
4. User rights (access, deletion, correction, portability)
5. DPO contact (email)
6. Cookie policy (if applicable)
7. Third-party sharing (if applicable)

**DPO (Data Protection Officer):**  
- **Name:** [DPO_NAME or "TBD"]  
- **Email:** dpo@[DOMAIN] or [CONTACT_EMAIL]  
- **Required:** Yes (LGPD Art. 41) - can be outsourced for small companies  

### Checklist LGPD

- [ ] Personal data mapped (table above completed)  
- [ ] Data deletion strategy defined (hard/soft/anonymization)  
- [ ] API endpoints for data access (`GET /users/{id}/data-export`)  
- [ ] API endpoints for data deletion (`DELETE /users/{id}`)  
- [ ] Privacy Policy published (minimum sections included)  
- [ ] DPO appointed (name + email)  
- [ ] Consent management (if collecting sensitive data - Art. 11)  
- [ ] Cookie banner (if using analytics cookies)  

---

## 🔐 Authentication & Authorization Strategy

### Authentication

**Method:** JWT (JSON Web Tokens)  

**Algorithm:** [Choose one]  
- [ ] **RS256** (Asymmetric - recommended for production)  
  - Public key for verification  
  - Private key for signing (kept secret)  
  - More secure, supports key rotation  
- [ ] **HS256** (Symmetric - acceptable for small projects)  
  - Single secret key (min 32 characters)  
  - Simpler implementation  

**Token Structure:**  
```json
{
  "sub": "user-id-123",
  "email": "user@example.com",
  "role": "User",
  "exp": 1672531200,
  "iat": 1672527600
}
```

**Token Expiration:**  
- **Access Token:** 15-60 minutes  
- **Refresh Token:** 7-30 days (optional for v1.0)  

**Implementation Checklist:**  
- [ ] JWT library integrated (e.g., `System.IdentityModel.Tokens.Jwt`)  
- [ ] Token expiration configured (15-60 min)  
- [ ] Secret key in environment variable (min 32 chars)  
- [ ] Token validation on every API request  
- [ ] Refresh token strategy (optional - implement if needed)  

### Authorization

**Strategy:** Domain-Level Authorization (Aggregates validate permissions)  

**Pattern:**  
```csharp
// Aggregate validates authorization
public class Strategy : AggregateRoot
{
    public void Modify(UserId requestingUserId, StrategyData newData)
    {
        // Authorization check
        if (this.OwnerId != requestingUserId)
            throw new UnauthorizedAccessException("User not owner of strategy");

        // Business logic
        this.Update(newData);
    }
}
```

**RBAC (Role-Based Access Control):**  

| Role | Permissions |
|------|-------------|
| **User** | - Create own strategies<br>- View own data<br>- Modify own profile |
| **Admin** | - All User permissions<br>- View all users<br>- Manage system settings |

**Checklist:**  
- [ ] Aggregates validate user ownership (domain-level authz)  
- [ ] Authorization failures throw `DomainException` or `UnauthorizedAccessException`  
- [ ] API controllers extract user ID from JWT claims  
- [ ] RBAC roles defined (User, Admin, etc.)  
- [ ] Admin endpoints protected with `[Authorize(Roles = "Admin")]`  

---

## 🔒 Secure Development Practices

### Input Validation

**Layers:**  
1. **Value Objects** (domain layer)
   - Validate format, length, business rules  
   - Example: Email, CPF, CNPJ, Symbol, Quantity  

2. **FluentValidation** (API layer)
   - Validate request structure  
   - Complement Value Object validation  

**Checklist:**  
- [ ] Value Objects validate all domain inputs  
- [ ] FluentValidation in API controllers  
- [ ] Invalid input returns `400 Bad Request` with clear message  
- [ ] No unvalidated user input reaches database  

### Password Security

**Requirements:**  
- Minimum length: 8 characters (12+ recommended)  
- Complexity: At least 1 uppercase, 1 lowercase, 1 number, 1 special char  
- No common passwords (validate against top 10k list - optional)  

**Hashing:**  
```csharp
// ASP.NET Core Identity PasswordHasher
var hasher = new PasswordHasher<User>();
string hash = hasher.HashPassword(user, password);

// Or bcrypt
string hash = BCrypt.Net.BCrypt.HashPassword(password);
```

**Checklist:**  
- [ ] Passwords hashed with bcrypt/Argon2 (NEVER plaintext)  
- [ ] Password complexity rules enforced  
- [ ] Password reset via email (time-limited token)  
- [ ] Account lockout after 5 failed login attempts (optional)  

### Secrets Management

**Approach:** Environment Variables (v1.0 Simplified)  

**What goes in `.env`:**  
- Database connection strings  
- JWT signing key  
- Third-party API keys (Stripe, SendGrid, etc.)  
- Encryption keys  

**What NEVER goes in code:**  
- Passwords  
- API keys  
- Connection strings with credentials  
- JWT secrets  

**Checklist:**  
- [ ] All secrets in `.env` files  
- [ ] `.env` in `.gitignore`  
- [ ] No secrets committed to git (check git history)  
- [ ] Production secrets different from dev/staging  
- [ ] `grep -r "password" codebase` returns zero hardcoded passwords  

---

## 📊 Security Monitoring

### Security Events to Log

**Critical Events:**  
1. **Failed Login Attempts**
   - Log: userId, IP, timestamp  
   - Alert: 5+ failures in 5 minutes  

2. **Unauthorized Access Attempts**
   - Log: userId, resource, timestamp  
   - Alert: Multiple 403 responses from same user  

3. **Data Export Events**
   - Log: userId, data exported, timestamp  
   - Alert: >1000 rows exported in single request  

4. **Permission Changes**
   - Log: adminId, targetUserId, old role, new role, timestamp  

5. **Password Changes**
   - Log: userId, timestamp  
   - Notify: Email to user confirming password change  

### Logging Implementation

**Structured Logging:**  
```csharp
_logger.LogWarning("Failed login attempt",
    new { UserId = userId, IpAddress = ipAddress, Timestamp = DateTime.UtcNow });

_logger.LogWarning("Unauthorized access attempt",
    new { UserId = userId, Resource = resource, Timestamp = DateTime.UtcNow });
```

**Log Storage:**  
- Development: Console + File  
- Staging/Production: Docker logs (JSON format)  

### Security Alerts (Optional for v1.0)

**Recommended Alerts:**  
- [ ] HighFailedLoginRate (5+ failures in 5 min) → Email/Slack  
- [ ] UnauthorizedAccessSpike (>10 403s in 5 min) → Email/Slack  
- [ ] SuspiciousDataExport (>1000 rows) → Email to Admin  

**Implementation:** Can be added post-launch when monitoring infrastructure is in place.  

---

## 🚫 Out of Scope for v1.0

To maintain simplicity for small/medium projects, v1.0 **DOES NOT include**:

- ❌ **Full STRIDE Analysis** (5 documents)  
- ❌ **Penetration Testing** (OWASP ZAP, manual pentest)  
- ❌ **Incident Response Plan** (formal playbooks)  
- ❌ **SIEM Integration** (Splunk, Sumo Logic)  
- ❌ **WAF** (Web Application Firewall)  
- ❌ **DDoS Protection** (CloudFlare, AWS Shield)  
- ❌ **Security Scanning in CI/CD** (SAST, DAST)  
- ❌ **SOC2 Compliance** (enterprise customers only)  
- ❌ **PCI-DSS Compliance** (unless handling credit cards directly)  

**When to add:** When scaling to enterprise, handling >100k users, or enterprise customers require SOC2.  

---

## ✅ Security Baseline Checklist

### OWASP Top 3
- [ ] **A01 - Broken Access Control**  
  - [ ] Domain-level authorization in Aggregates  
  - [ ] All APIs require authentication  
  - [ ] RBAC roles defined  
- [ ] **A02 - Cryptographic Failures**  
  - [ ] HTTPS/TLS 1.3 enforced  
  - [ ] Passwords hashed (bcrypt/Argon2)  
  - [ ] Secrets in environment variables  
- [ ] **A03 - Injection**  
  - [ ] SQL parametrizado (EF Core)  
  - [ ] Value Objects validate inputs  
  - [ ] FluentValidation in APIs  

### LGPD Compliance
- [ ] Personal data mapped  
- [ ] Data deletion strategy defined  
- [ ] API endpoints for access/deletion  
- [ ] Privacy Policy published  
- [ ] DPO appointed  

### Authentication & Authorization
- [ ] JWT authentication configured  
- [ ] Token expiration set (15-60 min)  
- [ ] Aggregates validate permissions  
- [ ] RBAC roles implemented  

### Secure Development
- [ ] Input validation (Value Objects + FluentValidation)  
- [ ] Passwords hashed (NEVER plaintext)  
- [ ] Secrets in `.env` (NEVER in code)  

### Security Monitoring
- [ ] Security events logged (failed logins, unauthorized access)  
- [ ] Structured logging implemented  

---

## 📚 References

- **OWASP Top 10 2021:** https://owasp.org/Top10/  
- **LGPD (Lei 13.709/2018):** https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm  
- **Checklist SEC:** `.agents/workflow/02-checklists/SEC-checklist.yml`  
- **Agent XML:** `.agents/35-SEC - Security Specialist.xml`  
- **Workflow Guide:** `.agents/00-Workflow-Guide.md`  

---

**Template Version:** 3.0  
**Last Updated:** 2025-10-08  
**Focus:** Pragmatic security baseline for small/medium projects  
