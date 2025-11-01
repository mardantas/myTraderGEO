<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)  
- Use blank lines between sections for readability (content)  
- Validate in Markdown preview before committing  
-->

# QAE-00-Test-Strategy.md

**Agent:** QAE (Quality Assurance Engineer)
**Project:** [PROJECT_NAME]
**Date:** [YYYY-MM-DD]
**Phase:** Discovery
**Scope:** Comprehensive testing strategy and quality standards
**Version:** 1.0

---

## 🎯 Objetivo

Definir estratégia abrangente de testes para o projeto, estabelecendo pirâmide de testes, cobertura mínima, e processos de qualidade.

---

## 🏗️ Test Pyramid

```
        /\
       /E2E\           Poucos (5-10%) - User journeys completos
      /------\
     /  INT   \        Moderados (20-30%) - APIs, BCs integration
    /----------\
   /    UNIT    \      Muitos (60-75%) - Domain logic, components
  /--------------\
```

**Distribuição Target:**  
- **Unit Tests:** 60-70% dos testes  
- **Integration Tests:** 20-30% dos testes  
- **E2E Tests:** 5-10% dos testes  

---

## 🧪 Tipos de Testes

### 1. Unit Tests

**Responsável Inicial:** DE (backend), FE (frontend)  
**QAE Expande Com:** Casos extremos, boundary conditions, error scenarios  

#### Backend (Domain Layer)

**O que testar:**  
- Aggregates: Business rules, invariantes  
- Value Objects: Validações, imutabilidade  
- Domain Events: Geração correta  
- Use Cases: Orquestração lógica  

**Framework:** xUnit, NUnit ou MSTest  
**Mocking:** Moq, NSubstitute  

**Exemplo:**  
```csharp
public class StrategyTests
{
    [Fact]
    public void AddLeg_WhenValid_ShouldAddLegToStrategy()
    {
        // Arrange
        var strategy = new Strategy(...);
        var leg = new StrategyLeg(...);

        // Act
        strategy.AddLeg(leg);

        // Assert
        Assert.Contains(leg, strategy.Legs);
    }

    [Fact]
    public void AddLeg_WhenExceedsMaxLegs_ShouldThrowException()
    {
        // Arrange
        var strategy = CreateStrategyWithMaxLegs();
        var leg = new StrategyLeg(...);

        // Act & Assert
        Assert.Throws<DomainException>(() => strategy.AddLeg(leg));
    }
}
```

#### Frontend (Components)

**O que testar:**  
- Componentes: Rendering, props, events  
- Hooks: State management logic  
- Utilities: Pure functions  

**Framework:** Jest, Vitest, Testing Library  

**Exemplo:**  
```typescript
describe('StrategyCard', () => {
  it('should render strategy name', () => {
    const strategy = { name: 'Bull Call Spread', ... };
    render(<StrategyCard strategy={strategy} />);
    expect(screen.getByText('Bull Call Spread')).toBeInTheDocument();
  });

  it('should call onEdit when edit button clicked', () => {
    const onEdit = jest.fn();
    render(<StrategyCard strategy={...} onEdit={onEdit} />);
    fireEvent.click(screen.getByRole('button', { name: /edit/i }));
    expect(onEdit).toHaveBeenCalledWith(strategy.id);
  });
});
```

**Coverage Target:** 70% line coverage mínimo  

---

### 2. Integration Tests

**Responsável:** QAE (full ownership)  

#### API Integration Tests

**O que testar:**  
- Controllers + Use Cases + Repositories  
- Database interactions (real DB ou in-memory)  
- Authentication/Authorization  
- Error handling end-to-end  

**Framework:** xUnit com WebApplicationFactory  
**Database:** TestContainers (Docker) ou In-Memory SQLite  

**Exemplo:**  
```csharp
public class StrategyApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    [Fact]
    public async Task POST_CreateStrategy_ReturnsCreated()
    {
        // Arrange
        var command = new CreateStrategyCommand { ... };

        // Act
        var response = await _client.PostAsJsonAsync("/api/strategies", command);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var strategy = await response.Content.ReadFromJsonAsync<StrategyDto>();
        Assert.NotNull(strategy);
        Assert.NotEqual(Guid.Empty, strategy.Id);
    }

    [Fact]
    public async Task GET_GetStrategy_WhenNotFound_Returns404()
    {
        // Act
        var response = await _client.GetAsync($"/api/strategies/{Guid.NewGuid()}");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
```

#### Cross-BC Integration Tests

**O que testar:**  
- Domain Events entre BCs  
- Eventual consistency  
- Saga/Process Managers  

**Exemplo:**  
```csharp
[Fact]
public async Task WhenStrategyCreated_RiskBCShouldCreateRiskProfile()
{
    // Arrange - Strategy BC
    var strategy = await CreateStrategy(...);

    // Act - Wait for domain event propagation
    await Task.Delay(500); // Or use polling

    // Assert - Risk BC
    var riskProfile = await _riskClient.GetRiskProfileAsync(strategy.Id);
    Assert.NotNull(riskProfile);
    Assert.Equal(strategy.Id, riskProfile.StrategyId);
}
```

---

### 3. E2E Tests (End-to-End)

**Responsável:** QAE (full ownership)  

**O que testar:**  
- User journeys completas  
- Fluxos críticos de negócio  
- Integração frontend + backend + database  

**Framework:** Playwright, Cypress, Selenium  

**User Journeys:**  

1. **Happy Path: Criar Estratégia Completa**
   - Login → Dashboard → Criar Estratégia → Configurar Legs → Salvar → Ver Greeks  

2. **Error Handling: Criar Estratégia Inválida**
   - Tentar criar estratégia sem legs → Ver erro → Corrigir → Sucesso  

3. **Cross-BC Flow: Estratégia → Risco**
   - Criar estratégia → Ver alerta de risco → Ajustar → Risco OK  

**Exemplo (Playwright):**  
```typescript
test('should create bull call spread strategy', async ({ page }) => {
  // Login
  await page.goto('/login');
  await page.fill('[name="email"]', 'user@test.com');
  await page.fill('[name="password"]', 'password');
  await page.click('button[type="submit"]');

  // Navigate to strategies
  await page.click('text=Estratégias');
  await page.click('text=Nova Estratégia');

  // Create strategy
  await page.fill('[name="name"]', 'My Bull Call');
  await page.selectOption('[name="type"]', 'BullCallSpread');

  // Add legs
  await page.click('text=Adicionar Perna');
  await page.fill('[name="strike1"]', '100');
  await page.fill('[name="strike2"]', '110');

  // Save
  await page.click('button:has-text("Salvar")');

  // Assert success
  await expect(page.locator('.success-message')).toBeVisible();
  await expect(page.locator('.strategy-card')).toContainText('My Bull Call');
});
```

**Coverage Target:** 100% de user journeys críticos  

---

### 4. Performance Tests

**Responsável:** QAE (colaboração com PE se disponível)  

**O que testar:**  
- Response time de APIs críticas  
- Database query performance  
- Frontend rendering performance  
- Load testing (concurrent users)  

**Tools:** k6, Artillery, JMeter  

**Benchmarks:**  

| Endpoint | Max Response Time | Throughput |
|----------|------------------|------------|
| GET /api/strategies | < 200ms | 100 req/s |
| POST /api/strategies | < 500ms | 50 req/s |
| GET /api/strategies/{id}/greeks | < 300ms | 200 req/s |

**Exemplo (k6):**  
```javascript
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  vus: 50, // 50 virtual users
  duration: '30s',
};

export default function () {
  let response = http.get('http://api.test/strategies');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });
}
```

---

### 5. Security Tests

**Responsável:** QAE (colaboração com SEC se disponível)  

**O que testar:**  
- Authentication/Authorization  
- SQL Injection  
- XSS (Cross-Site Scripting)  
- CSRF (Cross-Site Request Forgery)  
- OWASP Top 10  

**Tools:** OWASP ZAP, Burp Suite (manual), Dependabot (dependencies)  

**Checklist:**  

- [ ] Authentication required para endpoints protegidos  
- [ ] Authorization: Users só vêem seus próprios dados  
- [ ] Input validation: Rejeita SQL injection attempts  
- [ ] XSS protection: Outputs são sanitizados  
- [ ] CSRF tokens em formulários  
- [ ] HTTPS obrigatório  
- [ ] Secrets não expostos em código  

---

## 📊 Coverage Targets

| Layer | Coverage Target | Critical Paths |
|-------|----------------|----------------|
| **Domain Layer** | 80%+ | 100% business rules |
| **Application Layer** | 70%+ | 100% use cases principais |
| **API Controllers** | 60%+ | 100% endpoints críticos |
| **Frontend Components** | 70%+ | 100% componentes principais |
| **Integration** | N/A | 100% APIs públicas |
| **E2E** | N/A | 100% user journeys críticos |

---

## 🔄 CI/CD Integration

### Test Execution no Pipeline

```yaml
# .github/workflows/ci.yml

stages:
  - unit-tests:  
      run: dotnet test --filter Category=Unit
      fail-fast: true

  - integration-tests:  
      run: dotnet test --filter Category=Integration
      requires: [unit-tests]

  - e2e-tests:  
      run: npm run test:e2e
      requires: [integration-tests]
      only: [main, develop]

  - quality-gates:  
      coverage: 70%
      fails-if-below: true
```

### Quality Gates

**Blocking (PR não pode mergear):**  
- ❌ Unit tests falhando  
- ❌ Integration tests críticos falhando  
- ❌ Coverage < 70%  

**Warning (PR pode mergear mas avisa):**  
- ⚠️ E2E tests falhando (flaky tests)  
- ⚠️ Performance degradation > 20%  

---

## 🐛 Bug Testing & Regression

### Processo de Bug Fix

1. **QAE cria test que reproduz bug**
2. **DE/FE fixa o bug**
3. **Test passa (regression prevention)**
4. **Deploy**

**Exemplo:**  
```csharp
// Regression test para Bug #123
[Fact]
public void Bug123_WhenStrategyHasNoLegs_ShouldNotCalculateGreeks()
{
    // Arrange - reproduz cenário do bug
    var strategy = new Strategy { Legs = [] };

    // Act
    var greeks = strategy.CalculateGreeks();

    // Assert - comportamento correto
    Assert.Null(greeks);
}
```

---

## 📅 Testing Schedule

### Por Épico

| Fase | Responsável | Atividade | Quando |
|------|-------------|-----------|--------|
| **Development** | DE/FE | Unit tests básicos | Durante implementação |
| **Integration** | QAE | Integration tests | Após DE/FE concluir |
| **E2E** | QAE | E2E tests | Após integration |
| **Performance** | QAE | Load tests | Antes de deploy staging |
| **Security** | QAE | Security scan | Antes de deploy prod |

### Continuous

- **Daily:** Unit tests (CI)  
- **Per PR:** Unit + Integration tests  
- **Nightly:** E2E tests completos  
- **Weekly:** Performance tests  
- **Monthly:** Security audits  

---

## 🔧 Tools & Frameworks

### Backend (.NET)

| Tool | Purpose | Status |
|------|---------|--------|
| **xUnit** | Unit testing framework | ✅ Primary |
| **Moq** | Mocking framework | ✅ Primary |
| **FluentAssertions** | Assertion library | ✅ Recommended |
| **WebApplicationFactory** | Integration testing | ✅ Primary |
| **TestContainers** | Database testing | ⚠️ Considerar |
| **Bogus** | Fake data generation | ✅ Recommended |

### Frontend (React/TypeScript)

| Tool | Purpose | Status |
|------|---------|--------|
| **Vitest** | Unit testing framework | ✅ Primary |
| **Testing Library** | Component testing | ✅ Primary |
| **MSW** | API mocking | ✅ Recommended |
| **Playwright** | E2E testing | ✅ Primary |

### Performance & Security

| Tool | Purpose |
|------|---------|
| **k6** | Load testing |
| **OWASP ZAP** | Security scanning |
| **Lighthouse** | Frontend performance |

---

## ✅ Definition of Done - Testing

**Uma feature só está DONE quando:**  

- [ ] Unit tests escritos (DE/FE) e expandidos (QAE)  
- [ ] Integration tests criados (QAE)  
- [ ] E2E test do happy path criado (QAE)  
- [ ] Coverage >= 70% para código modificado  
- [ ] Todos os testes passando no CI  
- [ ] Performance benchmarks não degradados  
- [ ] Security checklist verificado  

---

## 📈 Métricas de Qualidade

**Tracking:**  

| Métrica | Target | Atual | Trend |
|---------|--------|-------|-------|
| **Unit Test Coverage** | 70% | [%] | [↗↘→] |
| **Integration Test Coverage** | 100% APIs críticas | [%] | [↗↘→] |
| **E2E Test Coverage** | 100% journeys críticos | [%] | [↗↘→] |
| **Test Execution Time** | < 5min (unit+int) | [min] | [↗↘→] |
| **Flaky Tests** | < 5% | [%] | [↗↘→] |
| **Bugs in Production** | < 2/month | [n] | [↗↘→] |

---

## 📝 Test Data Management

### Test Data Strategy

**Unit Tests:** In-memory fake data (Bogus library)  
**Integration Tests:** Database seeding per test  
**E2E Tests:** Dedicated test environment com data fixtures  

**Exemplo (Bogus):**  
```csharp
public class StrategyFaker : Faker<Strategy>
{
    public StrategyFaker()
    {
        RuleFor(s => s.Id, f => Guid.NewGuid());
        RuleFor(s => s.Name, f => f.Finance.StockName());
        RuleFor(s => s.Status, f => f.PickRandom<StrategyStatus>());
        RuleFor(s => s.CreatedAt, f => f.Date.Past());
    }
}
```

---

## 🔗 Referências

- **DE Tactical Model:** Para entender domain logic a testar  
- **FE Components:** Para entender UI a testar  
- **API Specs:** Para integration test cases  
- **User Flows (UXD):** Para E2E test scenarios  

---

**Test Strategy Version:** 1.0  
**Status:** Living Document (atualizar conforme projeto evolui)  
