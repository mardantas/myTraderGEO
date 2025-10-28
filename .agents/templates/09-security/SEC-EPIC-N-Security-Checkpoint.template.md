<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# SEC-EPIC-[N]-[EpicName]-Security-Checkpoint

**Epic:** [Epic Number and Name]  
**Reviewer:** SEC (Security Specialist)  
**Date:** [YYYY-MM-DD]  
**Duration:** 15-30 min  
**Status:** ✅ Approved / ⚠️ Issues Found / 🔴 Critical Issues  

---

## 🎯 Checkpoint Scope

**Triggered by:**  
- [ ] Epic handles sensitive data (PII, credentials, financial)
- [ ] Authentication/authorization logic introduced
- [ ] Epic 4+ (post-MVP stability)
- [ ] Other: [specify]

---

## ✅ Security Checklist

### 1. OWASP Top 3 Compliance

#### 🔒 Broken Access Control

| Check | Status | Notes |
|-------|--------|-------|
| Authorization checks in aggregates | ✅ / ⚠️ / 🔴 | [Files checked] |
| User can only access own resources | ✅ / ⚠️ / 🔴 | [Details] |
| Admin roles properly enforced | ✅ / ⚠️ / 🔴 | [Details] |
| API endpoints have [Authorize] | ✅ / ⚠️ / 🔴 | [Missing authorization if any] |

**Issues Found:**  
```
[List files and line numbers]
Example: StrategyController.cs:45 - Missing [Authorize] attribute
Example: Strategy.cs:78 - No ownership check in Close() method
```

#### 🔐 Cryptographic Failures

| Check | Status | Notes |
|-------|--------|-------|
| Sensitive data encrypted at rest | ✅ / ⚠️ / 🔴 / N/A | [What's encrypted] |
| HTTPS enforced (TLS 1.2+) | ✅ / ⚠️ / 🔴 | [Configuration checked] |
| Passwords hashed (BCrypt/Argon2) | ✅ / ⚠️ / 🔴 / N/A | [Hashing algorithm] |
| Secrets in env vars (not code) | ✅ / ⚠️ / 🔴 | [Details] |

**Sensitive Data Identified:**  
```
- User email/phone: [Encryption status]
- API keys: [Storage method]
- Payment info: [Encryption status]
```

#### 💉 Injection

| Check | Status | Notes |
|-------|--------|-------|
| Parameterized queries (EF Core) | ✅ / ⚠️ / 🔴 | [Raw SQL checked] |
| No SQL string concatenation | ✅ / ⚠️ / 🔴 | [Details] |
| Input validation in Value Objects | ✅ / ⚠️ / 🔴 | [VOs validated] |
| DTOs have validation attributes | ✅ / ⚠️ / 🔴 | [FluentValidation checked] |

**Injection Risks Found:**  
```
[List files with raw SQL or string concatenation]
Example: StrategyRepository.cs:120 - Raw SQL with string interpolation
```

---

### 2. Input Validation

| Check | Status | Notes |
|-------|--------|-------|
| Value Objects validate input | ✅ / ⚠️ / 🔴 | [VOs: Strike, Greeks, etc] |
| DTOs have [Required], [MaxLength] | ✅ / ⚠️ / 🔴 | [DTOs checked] |
| Business rule validation in aggregates | ✅ / ⚠️ / 🔴 | [Invariants checked] |
| Frontend: XSS prevention | ✅ / ⚠️ / 🔴 / N/A | [React auto-escapes] |

**Validation Gaps:**  
```
[List missing validations]
Example: CreateStrategyRequest.Name - Missing [MaxLength(100)]
Example: Strike Value Object - No validation for negative values
```

---

### 3. Authentication & Authorization

| Check | Status | Notes |
|-------|--------|-------|
| JWT token validated on every request | ✅ / ⚠️ / 🔴 / N/A | [Middleware checked] |
| Token expiration configured | ✅ / ⚠️ / 🔴 / N/A | [Expiry time] |
| Domain-level authorization | ✅ / ⚠️ / 🔴 | [Aggregate methods checked] |
| Sensitive operations require re-auth | ✅ / ⚠️ / 🔴 / N/A | [Details] |
| CORS properly configured | ✅ / ⚠️ / 🔴 | [AllowOrigins checked] |

**Authentication Issues:**  
```
[List files with auth issues]
Example: Startup.cs - CORS allows all origins (security risk)
Example: Strategy.Close() - No user validation
```

---

### 4. Secrets Management

| Check | Status | Notes |
|-------|--------|-------|
| No hardcoded secrets in code | ✅ / ⚠️ / 🔴 | [Checked files] |
| Environment variables used | ✅ / ⚠️ / 🔴 | [.env.example exists] |
| .env in .gitignore | ✅ / ⚠️ / 🔴 | [Verified] |
| Connection strings in appsettings | ✅ / ⚠️ / 🔴 | [Checked] |

**Secrets Exposed:**  
```
[List hardcoded secrets if found]
Example: appsettings.json - Database password hardcoded (should be env var)
```

---

## 🔍 Code Review Samples

### Files Reviewed:
```
- [x] Controllers: [List]
- [x] Aggregates: [List]
- [x] Value Objects: [List]
- [x] Application Services: [List]
- [x] Frontend Components: [List if applicable]
```

---

## 📊 Security Metrics

| Metric | Status | Notes |
|--------|--------|-------|
| OWASP Top 3 Coverage | [X%] | [Details] |
| Input validation coverage | [X%] | [VOs + DTOs validated] |
| Authorization checks | [X/Y endpoints] | [Missing if any] |
| Secrets properly managed | ✅ / ⚠️ / 🔴 | [Details] |

---

## 🔄 Feedback Created

**Critical Issues → FEEDBACK to SE/DE/FE:**  
- [ ] FEEDBACK-[NNN]-SEC-SE-[issue-title].md
- [ ] FEEDBACK-[NNN]-SEC-DE-[issue-title].md
- [ ] FEEDBACK-[NNN]-SEC-FE-[issue-title].md

**Blocking Deploy:** ☐ Yes ☑ No  

---

## ⚠️ Threats Identified (if new)

| Threat | Impact | Probability | Mitigation | Owner |
|--------|--------|-------------|------------|-------|
| [Threat description] | High/Medium/Low | High/Medium/Low | [Mitigation] | SE/DE/FE |

**Example:**  
| Threat | Impact | Probability | Mitigation | Owner |
|--------|--------|-------------|------------|-------|
| User can delete other users' strategies | High | Medium | Add ownership check in Strategy.Delete() | DE |

---

## ✅ Final Verdict

- **✅ Approved:** No critical security issues, epic can proceed to QAE
- **⚠️ Issues Found:** Non-blocking issues, feedback created for SE/DE/FE
- **🔴 Critical Issues:** Blocking issues, must fix before QAE testing

**Summary:** [Brief summary of checkpoint result]  

**Security Score:** [0-100] based on OWASP Top 3 coverage  

---

## 📋 Remediation Actions

**Immediate (Before QAE):**  
- [ ] [Action 1]
- [ ] [Action 2]

**Short-term (Epic N+1):**  
- [ ] [Action 1]
- [ ] [Action 2]

**Long-term (Production):**  
- [ ] [Action 1]
- [ ] [Action 2]

---

**Next Steps:**  
- [ ] SE/DE/FE addresses feedback (if any)
- [ ] Security issues resolved
- [ ] Epic proceeds to QAE Quality Gate

---

**Template Version:** 1.0  
**Last Updated:** 2025-10-10  
