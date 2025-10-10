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
| **DBA** | Per Epic | Encryption at rest, access control, audit logging |
| **FE** | Per Epic | XSS prevention, CSRF protection, secure token storage |
| **QAE** | Per Epic | Security testing (OWASP checklist), vulnerability scanning |
| **GM** | Setup | Dependabot, branch protection, secret scanning |
| **PE** | Setup | Network security (firewall), secrets management (env vars) |

### Checklist Mínimo de Segurança

**Discovery:**
- [ ] SDA identificou dados sensíveis (credentials, PII)
- [ ] SEC definiu baseline (OWASP Top 3, LGPD, JWT auth)

**Por Épico:**
- [ ] DE: Input validation em Value Objects
- [ ] DE: Authorization em Aggregates
- [ ] SE: Secrets via environment variables (não hardcoded)
- [ ] DBA: Sensitive columns identificadas
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
