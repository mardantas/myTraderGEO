<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)  
- Use blank lines between sections for readability (content)  
- Validate in Markdown preview before committing  
-->

# SEC-01: Threat Model

**Projeto:** [NOME-DO-PROJETO]  
**Data:** [DATA]  
**Security Specialist:** [NOME]  
**Versão:** 1.0  

---

## 🎯 Objetivo

Threat Modeling completo usando **STRIDE** para identificar ameaças e definir mitigações.

---

## 📋 STRIDE Framework

| Ameaça | Descrição | Exemplo |
|--------|-----------|---------|
| **S**poofing | Impersonar usuário/sistema | Fake JWT token |
| **T**ampering | Modificar dados não autorizado | SQL injection, XSS |
| **R**epudiation | Negar ação realizada | Falta de audit logs |
| **I**nformation Disclosure | Expor dados sensíveis | Senha em plaintext |
| **D**enial of Service | Indisponibilizar serviço | DDoS attack |
| **E**levation of Privilege | Ganhar acesso não autorizado | Admin sem autenticação |

---

## 🏗️ Threat Model por Bounded Context

### BC: [Nome do Bounded Context]

#### Assets (O que proteger?)
- [ ] User credentials (passwords, tokens)  
- [ ] Business data (orders, payments, etc)  
- [ ] API keys (third-party integrations)  
- [ ] PII (Personally Identifiable Information)  

#### Data Flow Diagram

```
[User] --HTTPS--> [Load Balancer] ---> [API Gateway]
                                           |
                                           v
                              [Bounded Context Services]
                                           |
                                           v
                                      [Database]
```

#### STRIDE Analysis

| Ameaça | Cenário | Impacto | Probabilidade | Mitigação |
|--------|---------|---------|---------------|-----------|
| **Spoofing** | Attacker forja JWT token | Alto | Média | JWT signature validation, short expiry |
| **Tampering** | SQL injection em query | Crítico | Média | Parameterized queries (EF Core) |
| **Repudiation** | User nega ter criado order | Médio | Baixa | Immutable audit logs |
| **Info Disclosure** | Password em logs | Alto | Alta | Never log sensitive data |
| **DoS** | Flood de requests | Alto | Alta | Rate limiting (100 req/min) |
| **Elevation** | User acessa admin endpoint | Crítico | Média | Authorization (Aggregates) |

---

## 🛡️ Mitigation Strategies

### Authentication & Authorization
- [ ] JWT tokens com assinatura (HS256/RS256)  
- [ ] Token expiry: 15 minutos (access), 7 dias (refresh)  
- [ ] Authorization em Aggregates (domain-level)  
- [ ] Principle of least privilege (RBAC)  

### Data Protection
- [ ] Encryption at rest (database TDE)  
- [ ] Encryption in transit (TLS 1.3+)  
- [ ] Secrets em Vault/Secrets Manager (NUNCA em código)  
- [ ] PII masking em logs  

### Input Validation
- [ ] Value Objects validam input (domain layer)  
- [ ] API input validation (FluentValidation)  
- [ ] SQL parametrizado (EF Core, sem raw SQL)  
- [ ] XSS prevention (React auto-escape, CSP headers)  

### DoS Prevention
- [ ] Rate limiting (100 req/min por user)  
- [ ] DDoS protection (CloudFlare, AWS Shield)  
- [ ] Circuit breaker para external APIs (Polly)  

### Audit & Monitoring
- [ ] Immutable audit logs (quem, o quê, quando)  
- [ ] SIEM integration (Splunk, Sumo Logic)  
- [ ] Alerting para atividades suspeitas  

---

## 🔍 Attack Trees (Ameaças Prioritárias)

### Attack Tree 1: Steal User Credentials

```
          [Goal: Steal Credentials]
                    |
        +-----------+-----------+
        |                       |
   [Phishing]            [Credential Stuffing]
        |                       |
    [Fake login page]     [Brute force login]
        |                       |
   Mitigation:            Mitigation:
   - Security training    - Rate limiting  
   - MFA required         - Account lockout  
```

---

## ✅ Definition of Done

- [ ] STRIDE analysis completo para TODOS BCs  
- [ ] Attack trees para funcionalidades críticas  
- [ ] Data flow diagrams com security annotations  
- [ ] Mitigation strategies documentadas  
- [ ] Threat prioritization (Impacto × Probabilidade)  
- [ ] SEC-checklist.yml completo  

---

**Próximos Passos:**  
1. SEC-02: Security Architecture Review
2. SEC-04: Executar Penetration Test
3. Implementar mitigações de ameaças CRÍTICAS
