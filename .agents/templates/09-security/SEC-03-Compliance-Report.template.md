<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# SEC-03: Compliance Report

**Projeto:** [NOME-DO-PROJETO]  
**Data:** [DATA]  
**Security Specialist:** [NOME]  
**Versão:** 1.0  

---

## 🎯 Objetivo

Garantir conformidade com regulações de segurança e privacidade: **LGPD**, **SOC2**, **PCI-DSS**, **CVM/SEC**.

---

## 📋 Compliance Overview

| Regulation | Applies? | Status | Last Audit |
|------------|----------|--------|------------|
| **LGPD** (Brasil - Lei Geral de Proteção de Dados) | ✅ Yes | ✅ Compliant | [DATA] |
| **SOC2 Type II** (Trust Services Criteria) | ✅ Yes | 🟡 In Progress | [DATA] |
| **PCI-DSS** (Payment Card Industry) | ⚠️ If payment data | N/A | N/A |
| **CVM/SEC** (Financial regulations) | ⚠️ If trading | N/A | N/A |

---

## 🇧🇷 LGPD (Lei Geral de Proteção de Dados)

### Scope

Lei nº 13.709/2018 - Proteção de dados pessoais de cidadãos brasileiros.

### Key Requirements

#### 1. Data Mapping (Art. 6º, III - Transparência)

| Data Type | Location | Purpose | Legal Basis | Retention |
|-----------|----------|---------|-------------|-----------|
| **Email** | Users table | Authentication, notifications | Consent (Art. 7º, I) | Until account deletion |
| **CPF** | Users table | Identity verification (KYC) | Legal obligation (Art. 7º, II) | 5 years (fiscal) |
| **Phone** | Users table | MFA, notifications | Consent (Art. 7º, I) | Until account deletion |
| **IP Address** | Audit logs | Security, fraud prevention | Legitimate interest (Art. 7º, IX) | 90 days |
| **Payment data** | Transactions table | Order processing | Contract execution (Art. 7º, V) | 5 years (fiscal) |

#### 2. Consent Management (Art. 8º)

```typescript
// Consent tracking implementation
interface Consent {
  userId: string;
  purpose: 'marketing' | 'analytics' | 'notifications';
  granted: boolean;
  grantedAt: Date;
  revokedAt?: Date;
  ipAddress: string;
  userAgent: string;
}

// Example: User consents to marketing emails
POST /api/v1/consent
{
  "purpose": "marketing",
  "granted": true
}

// Consent must be:
// ✅ Specific (por finalidade)
// ✅ Informed (usuário sabe o que está consentindo)
// ✅ Free (não pode ser obrigatório para usar o serviço)
// ✅ Revogável (usuário pode revogar a qualquer momento)
```

#### 3. Data Subject Rights (Titulares)

| Right | Implementation | API Endpoint | Status |
|-------|----------------|--------------|--------|
| **Access** (Art. 18, I) | Export all user data | `GET /api/v1/users/{id}/data-export` | ✅ |
| **Correction** (Art. 18, III) | Update personal data | `PATCH /api/v1/users/{id}` | ✅ |
| **Deletion** (Art. 18, VI) | Anonymize or delete | `DELETE /api/v1/users/{id}` | ✅ |
| **Portability** (Art. 18, V) | Export data in JSON | `GET /api/v1/users/{id}/data-export` | ✅ |
| **Revoke Consent** (Art. 18, IX) | Revoke specific consent | `DELETE /api/v1/consent/{id}` | ✅ |

**Right to Deletion Implementation:**  

```csharp
// UserService.cs
public async Task DeleteUser(UserId userId)
{
    var user = await _repository.GetByIdAsync(userId);

    // LGPD: Cannot delete data with legal retention obligation
    if (HasLegalRetentionObligation(user))
    {
        // Anonymize instead of delete
        user.Email = $"anonymized-{userId}@deleted.com";
        user.Name = "Anonymized User";
        user.Cpf = null;
        user.Phone = null;
        user.IsAnonymized = true;
    }
    else
    {
        // Hard delete
        await _repository.DeleteAsync(userId);
    }

    await _auditLog.LogAsync(new UserDeletedEvent(userId));
}
```

#### 4. Data Breach Notification (Art. 48)

**Obrigação:** Notificar ANPD e titulares em até **72 horas** após incidente.  

```yaml
# Incident Response Plan
data_breach_detected:
  - step: 1
    action: Contain breach (isolate affected systems)
    responsible: Security Team
    deadline: Immediate

  - step: 2
    action: Assess impact (quantos usuários afetados?)
    responsible: Security Team
    deadline: 24 hours

  - step: 3
    action: Notify ANPD (Autoridade Nacional de Proteção de Dados)
    responsible: DPO (Data Protection Officer)
    deadline: 72 hours
    template: breach-notification-anpd.md

  - step: 4
    action: Notify affected users (email + dashboard alert)
    responsible: DPO
    deadline: 72 hours
    template: breach-notification-users.md

  - step: 5
    action: Post-mortem and remediation
    responsible: Security Team
    deadline: 7 days
```

#### 5. Data Protection Officer (DPO)

- [ ] DPO nomeado: [NOME]
- [ ] Email de contato público: dpo@[SEU-DOMINIO]
- [ ] DPO mencionado em Privacy Policy
- [ ] Canal de comunicação com ANPD estabelecido

---

## 🏢 SOC2 Type II (Trust Services Criteria)

### Scope

Auditoria de controles de segurança para SaaS/Cloud providers.

### Trust Services Criteria (TSC)

#### CC1: Security (Common Criteria)

| Control | Implementation | Evidence | Status |
|---------|----------------|----------|--------|
| **CC6.1** - Logical access controls | JWT authentication, RBAC | IAM policies, audit logs | ✅ |
| **CC6.2** - New users provisioning | Admin approval workflow | User creation logs | ✅ |
| **CC6.3** - Access modifications | Automated deprovisioning on termination | HR integration logs | ✅ |
| **CC6.6** - Encryption | TLS 1.3, TDE, encrypted backups | SSL Labs report, DB config | ✅ |
| **CC6.7** - Transmission security | HTTPS only, HSTS headers | Security headers scan | ✅ |

#### CC2: Availability

| Control | Implementation | Evidence | Status |
|---------|----------------|----------|--------|
| **A1.1** - SLA commitment | 99.9% uptime SLA | Uptime monitoring (Pingdom) | ✅ |
| **A1.2** - Backup & recovery | Daily full backup, 15-min incremental | DR drill reports | ✅ |
| **A1.3** - DDoS protection | CloudFlare, rate limiting | WAF logs | ✅ |

#### CC3: Confidentiality

| Control | Implementation | Evidence | Status |
|---------|----------------|----------|--------|
| **C1.1** - Data classification | PII tagged in DB schema | Data mapping doc | ✅ |
| **C1.2** - Encryption at rest | Database TDE, S3 encryption | Infrastructure config | ✅ |
| **C1.3** - Secrets management | AWS Secrets Manager | Vault audit logs | ✅ |

#### CC4: Privacy

| Control | Implementation | Evidence | Status |
|---------|----------------|----------|--------|
| **P3.1** - Consent management | Opt-in consent workflow | Consent records | ✅ |
| **P3.2** - Data retention | Auto-delete after retention period | Retention policy doc | ✅ |
| **P4.1** - Right to access | Self-service data export | API logs | ✅ |
| **P4.2** - Right to deletion | User-initiated deletion | Deletion audit logs | ✅ |

### Audit Evidence Collection

```bash
# Collect audit evidence for SOC2
evidence/
├── access-logs/
│   ├── user-access-review-2025-Q1.csv      # CC6.1
│   └── privileged-access-review-2025-Q1.csv
├── change-management/
│   ├── code-review-approval-logs.csv        # CC8.1
│   └── production-deployment-logs.csv
├── backup-recovery/
│   ├── backup-success-logs.csv              # A1.2
│   └── dr-drill-report-2025-01.pdf
├── encryption/
│   ├── ssl-labs-report.pdf                  # CC6.6
│   └── database-tde-config.json
└── incident-response/
    └── security-incident-log-2025.csv       # CC7.3
```

---

## 💳 PCI-DSS (Payment Card Industry Data Security Standard)

**Applies if:** Processing, storing, or transmitting cardholder data (credit/debit cards).  

### Compliance Level

| Transaction Volume | Level | Requirements |
|-------------------|-------|--------------|
| < 20k/year | Level 4 | Self-assessment questionnaire (SAQ) |
| 20k - 1M/year | Level 3 | SAQ + quarterly network scan |
| 1M - 6M/year | Level 2 | Annual on-site audit |
| > 6M/year | Level 1 | Annual on-site audit + quarterly scans |

### 12 Requirements (Overview)

#### Requirement 1-2: Secure Network

- [ ] **1.1** - Firewall configuration (AWS Security Groups)
- [ ] **2.1** - Change default passwords (no defaults em produção)
- [ ] **2.2** - Harden systems (remove unused services)

#### Requirement 3-4: Protect Cardholder Data

- [ ] **3.4** - Encrypt cardholder data at rest (AES-256)
- [ ] **3.5** - Never store CVV/CVC (prohibited!)
- [ ] **4.1** - Encrypt data in transit (TLS 1.2+)

**RECOMMENDED:** Use payment gateway (Stripe, PayPal) instead of storing card data.  

```javascript
// NEVER store card data directly
// ❌ BAD
const order = {
  userId: 123,
  cardNumber: "4111111111111111", // PROHIBITED!
  cvv: "123"                      // PROHIBITED!
};

// ✅ GOOD - Use tokenization
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const paymentIntent = await stripe.paymentIntents.create({
  amount: 2000,
  currency: 'brl',
  payment_method: 'pm_card_visa', // Stripe token (NOT raw card)
});
```

#### Requirement 5-6: Maintain Secure Systems

- [ ] **5.1** - Antivirus on all systems
- [ ] **6.2** - Patch critical vulnerabilities within 30 days
- [ ] **6.5** - Secure coding practices (OWASP Top 10)

#### Requirement 7-9: Access Control

- [ ] **7.1** - Least privilege access
- [ ] **8.3** - MFA for remote access
- [ ] **9.1** - Physical access control (cloud provider)

#### Requirement 10-12: Monitoring & Policies

- [ ] **10.1** - Audit trails (who, what, when, where)
- [ ] **11.2** - Quarterly vulnerability scans
- [ ] **12.1** - Security policy established

---

## 📈 CVM/SEC (Financial Regulations - Brazil/US)

**Applies if:** Offering investment products, trading, or financial advisory.  

### CVM (Comissão de Valores Mobiliários) - Brazil

#### Key Requirements

- [ ] **Instrução CVM 301** - Information security policy
- [ ] **Instrução CVM 555** - Investor protection (transparency)
- [ ] **Instrução CVM 505** - Audit trails for trades

**Example: Audit trail for trades**

```csharp
// TradeAggregate.cs
public class Trade : AggregateRoot
{
    public void Execute(UserId userId, decimal quantity, decimal price)
    {
        // Business logic
        this.Status = TradeStatus.Executed;
        this.ExecutedAt = DateTime.UtcNow;

        // CVM 505: Immutable audit trail
        this.RaiseDomainEvent(new TradeExecutedEvent
        {
            TradeId = this.Id,
            UserId = userId,
            Quantity = quantity,
            Price = price,
            ExecutedAt = this.ExecutedAt,
            IpAddress = HttpContext.Connection.RemoteIpAddress.ToString(),
            UserAgent = HttpContext.Request.Headers["User-Agent"].ToString()
        });
    }
}
```

### SEC (Securities and Exchange Commission) - US

**Applies if:** Offering securities to US investors.  

- [ ] **Regulation S-P** - Privacy of consumer financial information
- [ ] **Regulation SCI** - Systems compliance and integrity
- [ ] **Rule 17a-4** - Record retention (6 years for trade confirmations)

---

## ✅ Definition of Done

- [ ] LGPD compliance 100% (data mapping, consent, rights)
- [ ] SOC2 controls implementados (CC1-CC4)
- [ ] PCI-DSS compliant (se aplicável) ou gateway terceiro
- [ ] CVM/SEC compliant (se aplicável)
- [ ] DPO nomeado e Privacy Policy publicada
- [ ] Audit evidence coletada e organizada
- [ ] Compliance audit agendado (anual)
- [ ] SEC-checklist.yml completo

---

**Próximos Passos:**  
1. SEC-04: Executar Penetration Test
2. SEC-05: Incident Response Plan
3. Agendar compliance audit externo (SOC2)

