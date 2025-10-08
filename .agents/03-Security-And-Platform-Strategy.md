# SECURITY-AND-PLATFORM-STRATEGY.md

**Versão:** 2.0
**Data:** 2025-10-06

---

## 🎯 Objetivo

Documentar como atividades de **Segurança** e **Performance/Plataforma** são distribuídas entre os 9 agents do processo DDD production-ready.

---

## 📋 Como Funciona

Responsabilidades de segurança e performance são **distribuídas** entre os agents especializados:

**Segurança (distribuída + coordenada):**
- **SEC:** Coordena estratégia de segurança (Threat Modeling, Pentest, Compliance, Incident Response)
- **DE:** Input validation, authorization, API security, async/await, N+1 prevention
- **DBA:** Encryption, access control, audit logging, query optimization
- **FE:** XSS prevention, CSRF protection, secure token storage
- **QAE:** Security testing (OWASP Top 10), vulnerability scanning
- **GM:** Dependabot, CodeQL, secret scanning, CI/CD security
- **PE:** Network security (VPC, firewall, WAF), secrets management (Vault)

**Performance/Plataforma (distribuída + coordenada):**
- **PE:** Coordena infraestrutura (IaC, Docker Swarm, Observability, DR, Auto-scaling)
- **DE:** Async/await, N+1 prevention, caching strategies
- **DBA:** Query optimization, indexes, database tuning
- **FE:** Code splitting, lazy loading, asset optimization
- **QAE:** Performance tests, load tests, stress tests

**Abordagem:** "Security & Performance by Design" - cada agente incorpora boas práticas, com PE e SEC coordenando estratégias transversais.

---

## 🔐 Estratégia de Segurança

### Princípio: Security by Design (Distribuído)

Segurança **NÃO é uma fase separada**, é **responsabilidade de cada agente** em suas entregas.

### Distribuição de Responsabilidades

#### 1. SDA (Strategic Domain Analyst)
**Fase:** Discovery
**Responsabilidades:**

- **Identificar dados sensíveis** no Event Storming
  - Credenciais de API (brokers)
  - Dados pessoais (se houver)
  - Configurações sensíveis

- **Documentar BCs que lidam com autenticação/autorização**
  - User Management BC (se houver)
  - Identity & Access Management

- **Definir políticas de acesso entre BCs**
  - Quem pode chamar quem
  - Autenticação inter-BC

**Deliverable:** `SDA-01-Event-Storming.md`
```markdown
## 🔐 Dados Sensíveis Identificados

| Dado | BC | Tipo | Proteção Necessária |
|------|-----|------|---------------------|
| API Key Broker | Market Data | Credential | Encrypt at rest + vault |
| User Password | User Management | PII | Hash (bcrypt) + salt |
| Strategy Config | Strategy Management | Business | Encrypt sensitive fields |
```

---

#### 2. DE (Domain Engineer)
**Fase:** Iteration (por épico)
**Responsabilidades:**

##### Backend Security

1. **Input Validation (Domain Layer)**
   ```csharp
   // Value Object com validação
   public record Strike
   {
       public decimal Value { get; init; }

       public Strike(decimal value)
       {
           if (value <= 0)
               throw new DomainException("Strike must be positive");

           if (value > 100000) // Previne valores absurdos
               throw new DomainException("Strike exceeds maximum");

           Value = value;
       }
   }
   ```

2. **Authorization Rules (Domain Layer)**
   ```csharp
   public class Strategy : AggregateRoot
   {
       public void Close(UserId requestingUser)
       {
           // Domain-level authorization
           if (this.OwnerId != requestingUser)
               throw new UnauthorizedException("Only owner can close strategy");

           // Business logic...
       }
   }
   ```

3. **Secrets Management (Infrastructure Layer)**
   ```csharp
   // appsettings.json (DEV apenas)
   {
       "BrokerApi": {
           "Endpoint": "https://api.broker.com",
           "ApiKey": "USE_ENVIRONMENT_VARIABLE" // Não commitar secrets
       }
   }

   // Program.cs
   builder.Configuration.AddEnvironmentVariables();
   builder.Configuration.AddUserSecrets<Program>(); // DEV
   // TODO: Produção usar Azure Key Vault ou AWS Secrets Manager
   ```

4. **SQL Injection Prevention (Repository Layer)**
   ```csharp
   // ✅ CORRETO: Usar EF parametrizado
   var strategies = await _context.Strategies
       .Where(s => s.Name == userInput) // Parametrizado automaticamente
       .ToListAsync();

   // ❌ ERRADO: Raw SQL sem parametrização
   // var sql = $"SELECT * FROM Strategies WHERE Name = '{userInput}'";
   ```

5. **API Security (Application Layer)**
   ```csharp
   [Authorize] // Requer autenticação
   [ApiController]
   [Route("api/strategies")]
   public class StrategiesController : ControllerBase
   {
       [HttpPost]
       [ValidateAntiForgeryToken] // CSRF protection
       public async Task<IActionResult> Create(
           [FromBody] CreateStrategyRequest request)
       {
           // Rate limiting (via middleware)
           // Input validation (via FluentValidation)
           // Authorization (via policies)
       }
   }
   ```

**Deliverable:** `DE-01-[EpicName]-Tactical-Model.md`
```markdown
## 🔐 Security Considerations

### Input Validation
- All Value Objects validate invariants
- API requests validated via FluentValidation
- Max string lengths enforced

### Authorization
- Strategy.Close() validates ownership
- Strategy.AddLeg() validates user permissions

### Secrets
- Broker API key via environment variable
- No secrets in appsettings.json or code
```

---

#### 3. DBA (Database Administrator)
**Fase:** Iteration (por épico)
**Responsabilidades:**

1. **Encrypt Sensitive Columns**
   ```sql
   -- Review de migration criada por DE
   CREATE TABLE Strategies (
       Id UNIQUEIDENTIFIER PRIMARY KEY,
       Name NVARCHAR(200) NOT NULL,
       Configuration VARBINARY(MAX) NOT NULL -- Encrypted at application layer
   );
   ```

2. **Row-Level Security (RLS) - se necessário**
   ```sql
   -- Para multi-tenant
   CREATE SECURITY POLICY StrategyFilter
   ADD FILTER PREDICATE dbo.fn_securitypredicate(OwnerId)
   ON dbo.Strategies
   WITH (STATE = ON);
   ```

3. **Audit Logging**
   ```sql
   -- Tabela de auditoria
   CREATE TABLE AuditLog (
       Id BIGINT IDENTITY PRIMARY KEY,
       Timestamp DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
       UserId UNIQUEIDENTIFIER NOT NULL,
       Action NVARCHAR(50) NOT NULL, -- CREATE, UPDATE, DELETE
       EntityType NVARCHAR(100) NOT NULL,
       EntityId NVARCHAR(100) NOT NULL,
       Changes NVARCHAR(MAX) -- JSON diff
   );
   ```

4. **Access Control Review**
   - Database user com **least privilege**
   - Application usa user sem permissões de DDL
   - DBA user separado para migrations

**Deliverable:** `DBA-01-[EpicName]-Schema-Review.md`
```markdown
## 🔐 Security Review

### Encryption
- [x] Sensitive columns identified
- [x] Application-level encryption for Configuration
- [ ] TDE (Transparent Data Encryption) - PRODUÇÃO

### Access Control
- [x] Application user: SELECT, INSERT, UPDATE, DELETE apenas
- [x] DBA user: Full DDL (migrations)
- [ ] Read-only user para analytics - FUTURO

### Audit
- [x] AuditLog table created
- [x] Trigger para auditar Strategy changes
```

---

#### 4. FE (Frontend Engineer)
**Fase:** Iteration (por épico)
**Responsabilidades:**

1. **XSS Prevention**
   ```tsx
   // ✅ CORRETO: React escapa automaticamente
   function StrategyCard({ strategy }) {
       return <div>{strategy.name}</div>; // Safe
   }

   // ❌ ERRADO: dangerouslySetInnerHTML com user input
   // <div dangerouslySetInnerHTML={{ __html: userInput }} />
   ```

2. **CSRF Protection**
   ```tsx
   // Usar CSRF token em forms
   const createStrategy = async (data) => {
       const csrfToken = getCsrfToken(); // De meta tag ou cookie

       await fetch('/api/strategies', {
           method: 'POST',
           headers: {
               'Content-Type': 'application/json',
               'X-CSRF-Token': csrfToken
           },
           body: JSON.stringify(data)
       });
   };
   ```

3. **Secrets Management**
   ```tsx
   // ✅ CORRETO: API keys no backend
   // Frontend apenas chama backend, não tem API keys

   // ❌ ERRADO: API key no código frontend
   // const BROKER_API_KEY = "abc123"; // NUNCA!
   ```

4. **Input Sanitization**
   ```tsx
   import { z } from 'zod';

   const strategySchema = z.object({
       name: z.string().min(3).max(100),
       type: z.enum(['BULL_CALL', 'BEAR_PUT']),
       legs: z.array(legSchema).max(4)
   });

   // Validar antes de enviar ao backend
   const validated = strategySchema.parse(formData);
   ```

5. **Authentication State**
   ```tsx
   // Usar context/provider para auth state
   const { user, isAuthenticated, logout } = useAuth();

   if (!isAuthenticated) {
       return <Navigate to="/login" />;
   }
   ```

**Output:** Código frontend seguro (sem deliverable específico)

---

#### 5. QAE (Quality Assurance Engineer)
**Fase:** Iteration (por épico)
**Responsabilidades:**

##### Security Tests

1. **OWASP Top 10 Checklist**
   ```markdown
   ## 🔐 Security Testing Checklist (OWASP Top 10)

   ### A01: Broken Access Control
   - [ ] Testar acesso a estratégia de outro usuário (deve falhar)
   - [ ] Testar modificar estratégia sem autenticação (deve falhar)
   - [ ] Testar escalar privilégios (user → admin)

   ### A02: Cryptographic Failures
   - [ ] Verificar senha armazenada hasheada (não plaintext)
   - [ ] Verificar HTTPS em produção
   - [ ] Verificar API key não exposta em logs

   ### A03: Injection
   - [ ] Testar SQL injection em filtros (deve ser parametrizado)
   - [ ] Testar XSS em campos de texto (deve ser escaped)
   - [ ] Testar command injection em inputs

   ### A04: Insecure Design
   - [ ] Verificar rate limiting em login
   - [ ] Verificar lockout após 5 tentativas falhas

   ### A05: Security Misconfiguration
   - [ ] Verificar stack trace não exposto em produção
   - [ ] Verificar CORS configurado corretamente
   - [ ] Verificar headers de segurança (CSP, X-Frame-Options)

   ### A07: Authentication Failures
   - [ ] Testar força de senha (mínimo 8 chars, complexidade)
   - [ ] Verificar session timeout
   - [ ] Verificar logout invalida token
   ```

2. **Testes de Autorização**
   ```csharp
   [Fact]
   public async Task CloseStrategy_WhenNotOwner_ShouldReturn403()
   {
       // Arrange
       var strategy = new Strategy(ownerId: "user-123");
       var requestingUser = "user-456"; // Outro usuário

       // Act
       var result = await _controller.Close(strategy.Id, requestingUser);

       // Assert
       Assert.IsType<ForbidResult>(result);
   }
   ```

3. **Testes de Input Validation**
   ```csharp
   [Theory]
   [InlineData(-100)] // Negativo
   [InlineData(0)]    // Zero
   [InlineData(1000000)] // Muito grande
   public void Strike_WhenInvalid_ShouldThrowException(decimal value)
   {
       Assert.Throws<DomainException>(() => new Strike(value));
   }
   ```

**Deliverable:** `QAE-01-Test-Strategy.md`
```markdown
## 🔐 Security Testing

### OWASP Top 10 Coverage
- [x] A01: Access Control (15 tests)
- [x] A02: Cryptographic Failures (8 tests)
- [x] A03: Injection (12 tests)
- [ ] A04-A10: Não aplicável para projetos iniciais

### Tools
- OWASP ZAP (scan automático)
- Snyk (dependency vulnerabilities)
- SonarQube (code security issues)
```

---

#### 6. GM (GitHub Manager)
**Fase:** Discovery + Iteration
**Responsabilidades:**

1. **Branch Protection Rules**
   ```bash
   gh api repos/OWNER/REPO/branches/main/protection \
     --method PUT \
     --field required_status_checks='{"strict":true,"contexts":["security-scan"]}' \
     --field enforce_admins=true \
     --field required_pull_request_reviews='{"required_approving_review_count":1}'
   ```

2. **Dependabot (Vulnerability Alerts)**
   ```yaml
   # .github/dependabot.yml
   version: 2
   updates:
     - package-ecosystem: "nuget"
       directory: "/02-backend"
       schedule:
         interval: "weekly"
       open-pull-requests-limit: 10

     - package-ecosystem: "npm"
       directory: "/01-frontend"
       schedule:
         interval: "weekly"
   ```

3. **Security Scan no CI/CD**
   ```yaml
   # .github/workflows/security.yml
   name: Security Scan

   on: [push, pull_request]

   jobs:
     security:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3

         - name: Run Snyk
           uses: snyk/actions/dotnet@master
           env:
             SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

         - name: OWASP Dependency Check
           uses: dependency-check/Dependency-Check_Action@main
   ```

4. **Secret Scanning**
   ```bash
   # Habilitar GitHub secret scanning
   gh api repos/OWNER/REPO \
     --method PATCH \
     --field security_and_analysis='{"secret_scanning":{"status":"enabled"}}'
   ```

**Deliverable:** `GM-01-GitHub-Setup.md`
```markdown
## 🔐 Security Configuration

### Branch Protection
- [x] main: Require PR reviews
- [x] main: Require status checks (security-scan)
- [x] main: No force push

### Automated Scans
- [x] Dependabot enabled
- [x] Secret scanning enabled
- [x] CodeQL analysis enabled
```

---

## 🚀 Estratégia de Performance

### Princípio: Performance by Design (Distribuído)

Performance **NÃO é uma otimização tardia**, é **considerada desde o design**.

### Distribuição de Responsabilidades

#### 1. SDA (Strategic Domain Analyst)
**Fase:** Discovery
**Responsabilidades:**

- **Identificar BCs com alta carga**
  - Market Data BC (alta frequência de updates)
  - Portfolio BC (cálculos intensivos)

- **Definir estratégias de escalabilidade**
  - Eventual consistency entre BCs
  - Event-driven para processos assíncronos

**Deliverable:** `SDA-02-Context-Map.md`
```markdown
## ⚡ Performance Considerations

### High-Load BCs
- **Market Data BC:** Real-time price updates (WebSocket)
- **Portfolio BC:** Greeks calculation (CPU-intensive)

### Scalability Strategy
- Market Data: Cache prices (Redis, TTL 1s)
- Portfolio: Async calculation via domain events
- Event Bus: RabbitMQ para comunicação assíncrona
```

---

#### 2. DE (Domain Engineer)
**Fase:** Iteration (por épico)
**Responsabilidades:**

1. **Lazy Loading de Relacionamentos**
   ```csharp
   public class Strategy : AggregateRoot
   {
       public StrategyId Id { get; private set; }

       // Eager load apenas quando necessário
       private readonly List<StrategyLeg> _legs = new();
       public IReadOnlyCollection<StrategyLeg> Legs => _legs.AsReadOnly();

       // Não carregar Greeks automaticamente (pode ser calculado on-demand)
       public Greeks? Greeks { get; private set; } // Nullable
   }
   ```

2. **Evitar N+1 Queries**
   ```csharp
   // ✅ CORRETO: Include
   var strategies = await _context.Strategies
       .Include(s => s.Legs)
       .Where(s => s.OwnerId == userId)
       .ToListAsync();

   // ❌ ERRADO: N+1
   // var strategies = await _context.Strategies.ToListAsync();
   // foreach (var s in strategies) {
   //     var legs = await _context.StrategyLegs.Where(l => l.StrategyId == s.Id).ToListAsync();
   // }
   ```

3. **Caching de Dados Imutáveis**
   ```csharp
   // Preços de mercado (cache curto)
   public async Task<Price> GetPrice(string symbol)
   {
       var cacheKey = $"price:{symbol}";

       if (_cache.TryGetValue(cacheKey, out Price cachedPrice))
           return cachedPrice;

       var price = await _marketDataApi.GetPrice(symbol);
       _cache.Set(cacheKey, price, TimeSpan.FromSeconds(1));

       return price;
   }
   ```

4. **Async/Await Correto**
   ```csharp
   // ✅ CORRETO: Async all the way
   public async Task<Strategy> CreateStrategy(CreateStrategyCommand cmd)
   {
       var strategy = new Strategy(...);
       await _repository.AddAsync(strategy);
       await _unitOfWork.CommitAsync();
       return strategy;
   }

   // ❌ ERRADO: .Result ou .Wait() (deadlock risk)
   // var strategy = _repository.AddAsync(strategy).Result;
   ```

**Deliverable:** `DE-01-[EpicName]-Tactical-Model.md`
```markdown
## ⚡ Performance Considerations

### Caching Strategy
- Market prices: Redis cache, TTL 1s
- User strategies: In-memory cache, invalidate on update

### Async Operations
- Greeks calculation: Fire domain event, process async
- Portfolio valuation: Background job (Hangfire)

### Query Optimization
- Include() for related entities (avoid N+1)
- Projection for DTOs (Select only needed fields)
```

---

#### 3. DBA (Database Administrator)
**Fase:** Iteration (por épico)
**Responsabilidades:**

1. **Indexing Strategy**
   ```sql
   -- Índices críticos
   CREATE NONCLUSTERED INDEX IX_Strategies_OwnerId_Status
   ON Strategies(OwnerId, Status)
   INCLUDE (Name, CreatedAt);

   -- Índice para queries frequentes
   CREATE NONCLUSTERED INDEX IX_StrategyLegs_StrategyId
   ON StrategyLegs(StrategyId)
   INCLUDE (OptionType, Strike, Expiration);
   ```

2. **Query Performance Analysis**
   ```sql
   -- Estimar custo de queries
   SET STATISTICS IO ON;
   SET STATISTICS TIME ON;

   -- Query de exemplo
   SELECT s.Id, s.Name, COUNT(l.Id) as LegCount
   FROM Strategies s
   LEFT JOIN StrategyLegs l ON s.Id = l.StrategyId
   WHERE s.OwnerId = @userId
   GROUP BY s.Id, s.Name;

   -- Analisar execution plan
   ```

3. **Partitioning (para escala futura)**
   ```sql
   -- Particionar por data (se volume alto)
   CREATE PARTITION FUNCTION PF_ByMonth (DATE)
   AS RANGE RIGHT FOR VALUES ('2025-01-01', '2025-02-01', ...);

   CREATE PARTITION SCHEME PS_AuditLog
   AS PARTITION PF_ByMonth TO (FG1, FG2, FG3, ...);
   ```

**Deliverable:** `DBA-01-[EpicName]-Schema-Review.md`
```markdown
## ⚡ Performance Analysis

### Indexing
- [x] PK on all tables (clustered)
- [x] FK indexes (Strategies.OwnerId, StrategyLegs.StrategyId)
- [x] Query-specific indexes (Status, CreatedAt)

### Query Performance
- Estimated reads: 50 logical reads (acceptable)
- Execution time: <10ms (good)

### Recommendations
- [ ] Consider partitioning AuditLog after 1M rows
- [ ] Add filtered index for active strategies
```

---

#### 4. FE (Frontend Engineer)
**Fase:** Iteration (por épico)
**Responsabilidades:**

1. **Code Splitting**
   ```tsx
   // Lazy load de rotas
   const StrategyPage = lazy(() => import('./pages/StrategyPage'));
   const PortfolioPage = lazy(() => import('./pages/PortfolioPage'));

   <Suspense fallback={<Loading />}>
       <Routes>
           <Route path="/strategies" element={<StrategyPage />} />
           <Route path="/portfolio" element={<PortfolioPage />} />
       </Routes>
   </Suspense>
   ```

2. **Memoization**
   ```tsx
   // Evitar re-renders desnecessários
   const StrategyCard = memo(({ strategy }) => {
       const greeks = useMemo(
           () => calculateGreeks(strategy),
           [strategy.legs] // Recalcula só se legs mudarem
       );

       return <div>{greeks.delta}</div>;
   });
   ```

3. **Virtual Scrolling (listas grandes)**
   ```tsx
   import { FixedSizeList } from 'react-window';

   function StrategyList({ strategies }) {
       return (
           <FixedSizeList
               height={600}
               itemCount={strategies.length}
               itemSize={80}
           >
               {({ index, style }) => (
                   <div style={style}>
                       <StrategyCard strategy={strategies[index]} />
                   </div>
               )}
           </FixedSizeList>
       );
   }
   ```

4. **API Request Optimization**
   ```tsx
   // Debounce em search
   const debouncedSearch = useDebounce(searchTerm, 300);

   useEffect(() => {
       if (debouncedSearch) {
           fetchStrategies(debouncedSearch);
       }
   }, [debouncedSearch]);
   ```

**Output:** Código frontend otimizado

---

#### 5. QAE (Quality Assurance Engineer)
**Fase:** Iteration (por épico)
**Responsabilidades:**

1. **Performance Tests (k6)**
   ```javascript
   // k6 load test
   import http from 'k6/http';
   import { check, sleep } from 'k6';

   export const options = {
       stages: [
           { duration: '1m', target: 50 },   // Ramp up
           { duration: '3m', target: 50 },   // Stay at 50 users
           { duration: '1m', target: 0 },    // Ramp down
       ],
       thresholds: {
           http_req_duration: ['p(95)<500'], // 95% requests < 500ms
       },
   };

   export default function () {
       const res = http.get('https://api.[YOUR-DOMAIN]/orders');

       check(res, {
           'status is 200': (r) => r.status === 200,
           'response time < 500ms': (r) => r.timings.duration < 500,
       });

       sleep(1);
   }
   ```

2. **Benchmarks de Cálculos**
   ```csharp
   [Fact]
   public async Task CalculateGreeks_Performance_ShouldBeFast()
   {
       // Arrange
       var strategy = CreateComplexStrategy(); // 4 legs
       var stopwatch = Stopwatch.StartNew();

       // Act
       for (int i = 0; i < 1000; i++)
       {
           var greeks = strategy.CalculateGreeks();
       }
       stopwatch.Stop();

       // Assert
       var avgMs = stopwatch.ElapsedMilliseconds / 1000.0;
       Assert.True(avgMs < 10, $"Avg time {avgMs}ms exceeds 10ms threshold");
   }
   ```

3. **Memory Leak Detection**
   ```csharp
   [Fact]
   public void Repository_ShouldNotLeakMemory()
   {
       var initialMemory = GC.GetTotalMemory(true);

       for (int i = 0; i < 10000; i++)
       {
           var strategy = _repository.GetById(testId);
           // Use strategy...
       }

       GC.Collect();
       GC.WaitForPendingFinalizers();

       var finalMemory = GC.GetTotalMemory(true);
       var leaked = finalMemory - initialMemory;

       Assert.True(leaked < 10_000_000, $"Leaked {leaked} bytes");
   }
   ```

**Deliverable:** `QAE-01-Test-Strategy.md`
```markdown
## ⚡ Performance Testing

### Load Tests (k6)
- Target: 100 concurrent users
- Threshold: p95 < 500ms
- Test: GET /api/strategies

### Benchmarks
- Greeks calculation: <10ms per strategy
- Portfolio valuation: <100ms for 50 strategies

### Tools
- k6 (load testing)
- BenchmarkDotNet (C# benchmarks)
- Chrome DevTools (frontend profiling)
```

---

## 📊 Quando Adicionar Agentes Dedicados?

### Triggers para SEC (Agente)

Adicionar **Security Engineer dedicado** quando:

1. **Compliance obrigatória:**
   - SOC 2, ISO 27001, PCI-DSS
   - Regulamentação financeira (CVM, SEC)

2. **Dinheiro real envolvido:**
   - Trading com fundos reais
   - Integração com brokers reais

3. **Dados sensíveis em escala:**
   - >10k usuários
   - PII (Personally Identifiable Information)

4. **Incidentes de segurança:**
   - Breach ocorreu
   - Vulnerabilidades críticas frequentes

### Triggers para PE (Agente)

Adicionar **Performance Engineer dedicado** quando:

1. **Escala crítica:**
   - >1M requests/dia
   - >100k usuários ativos

2. **Problemas de performance:**
   - p95 latency >1s
   - Downtime por sobrecarga

3. **Requisitos SLA:**
   - 99.9% uptime contratual
   - <100ms latency garantida

4. **Infraestrutura complexa:**
   - Multi-region deployment
   - Microservices com >10 serviços

---

## ✅ Checklist: Security & Performance

### Security (Mínimo Viável)

- [ ] **SDA:** Dados sensíveis identificados
- [ ] **DE:** Input validation em Value Objects
- [ ] **DE:** Authorization em Aggregates
- [ ] **DE:** Secrets via environment variables
- [ ] **DBA:** Sensitive columns identificadas
- [ ] **FE:** XSS prevention (React auto-escape)
- [ ] **FE:** CSRF token em forms
- [ ] **QAE:** OWASP Top 3 testados (Access Control, Injection, Auth)
- [ ] **GM:** Dependabot habilitado
- [ ] **GM:** Branch protection em main

### Performance (Mínimo Viável)

- [ ] **SDA:** High-load BCs identificados
- [ ] **DE:** Async/await correto
- [ ] **DE:** Cache de dados frequentes (Redis)
- [ ] **DBA:** PK + FK indexes criados
- [ ] **DBA:** Query performance <100ms
- [ ] **FE:** Code splitting de rotas
- [ ] **FE:** Lazy load de componentes pesados
- [ ] **QAE:** Load test básico (50 users, p95<500ms)

---

## 🔗 Referências

- **OWASP Top 10:** https://owasp.org/www-project-top-ten/
- **OWASP ASVS:** https://owasp.org/www-project-application-security-verification-standard/
- **k6 Load Testing:** https://k6.io/docs/
- **BenchmarkDotNet:** https://benchmarkdotnet.org/

---

**Strategy Version:** 1.0
**Status:** Living Document
**Next Review:** Quando atingir triggers para agents dedicados
