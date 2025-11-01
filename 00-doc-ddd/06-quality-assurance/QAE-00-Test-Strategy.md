# QAE-00-Test-Strategy.md

**Agent:** QAE (Quality Assurance Engineer)  
**Project:** myTraderGEO  
**Date:** 2025-10-15  
**Phase:** Discovery  
**Scope:** Testing strategy, coverage targets, quality gates  
**Version:** 1.0  
  
---  

## 📋 Metadata

- **Project Name:** myTraderGEO  
- **Created:** 2025-10-15  
- **QA Engineer:** QAE Agent  
- **Complexity:** Alta - Plataforma financeira com cálculos críticos  
- **Stack:** Definido pelo PE-00 (.NET 8 + Vue 3 + PostgreSQL 15)  

---

## 🎯 Objetivo

Definir estratégia de testes para myTraderGEO, garantindo qualidade e confiabilidade em uma plataforma de trading financeiro com requisitos críticos de precisão.

**Contexto:**
- **Domínio:** Trading de opções/ações (B3)
- **Criticidade:** Alta - Impacto monetário direto
- **Bounded Contexts:** 9 BCs (3 Core, 4 Supporting, 2 Generic)
- **Compliance:** LGPD, auditoria financeira
- **Real-time:** Market data streaming, P&L updates

---

## 🏗️ Test Pyramid - Trading Platform

```
         /\
        /E2E\        10% - Fluxos críticos end-to-end
       /------\
      /  INT   \     30% - APIs, BCs, integrações B3
     /----------\
    /    UNIT    \   60% - Domain logic, cálculos financeiros
   /--------------\
```

**Distribuição Target:**
- **Unit:** 60% - Regras de negócio, cálculos (margem, gregas, P&L)
- **Integration:** 30% - APIs, cross-BC, integrações externas
- **E2E:** 10% - Fluxos completos (criar → executar → monitorar estratégias)

**Justificativa:**
- Cálculos financeiros complexos exigem alta cobertura unitária
- Múltiplas integrações externas (B3, market data) requerem testes de integração robustos
- E2E focado em fluxos de alto valor (menor quantidade, alta criticidade)

---

## 🧪 Testing Stack

**Definido pelo PE-00:** [`PE-00-Environments-Setup.md`](../08-platform-engineering/PE-00-Environments-Setup.md)  

| Layer | Stack | Ferramentas |
|-------|-------|-------------|
| Backend (.NET 8) | C# | xUnit, Moq, FluentAssertions, Bogus |
| Frontend (Vue 3) | TypeScript | Vitest, Vue Test Utils, Testing Library |
| E2E | Cross-stack | Playwright |
| API Contract | REST/WebSocket | Pact (opcional - Epic 2+) |
| Performance | Load testing | k6 (Epic 3+) |
| Security | SAST/DAST | OWASP ZAP, Snyk (Epic 2+) |

**Referência completa:** Ver PE-00 seção "Stack Tecnológico"  

---

## 📊 Coverage Targets por BC

### Core Domains (Prioridade Máxima)

| Bounded Context | Unit | Integration | E2E | Justificativa |
|-----------------|------|-------------|-----|---------------|
| **Strategy Planning** | 85% | 40% | 15% | Cálculos críticos (margem, gregas) |
| **Trade Execution** | 80% | 50% | 20% | Paper vs Real trading, promoção |
| **Risk Management** | 85% | 40% | 10% | Detecção de conflitos, limites |

### Supporting Domains

| Bounded Context | Unit | Integration | E2E |
|-----------------|------|-------------|-----|
| Market Data Integration | 70% | 60% | 5% |
| Portfolio Tracking | 75% | 30% | 10% |
| User Management | 70% | 30% | 10% |
| Notification | 60% | 40% | 5% |

### Generic Domains

| Bounded Context | Unit | Integration | E2E |
|-----------------|------|-------------|-----|
| Shared Kernel | 80% | 20% | - |
| Authentication (ACL) | 70% | 40% | 10% |

**Cobertura Mínima Global:** 70% (bloqueio de PR se < 70%)  

---

## 🎯 O Que Testar - Por Tipo

### 1. Unit Tests - Domain Logic

**Foco:** Regras de negócio isoladas, cálculos, validações  

**Strategy Planning BC:**
- ✅ Transformações template → strategy (strikes relativos → absolutos)
- ✅ Cálculo de margem B3 (cenários complexos, limites)
- ✅ Cálculo de gregas (Black-Scholes: delta, gamma, theta, vega)
- ✅ Cálculo de rentabilidade máxima/mínima
- ✅ Validações de legs (tipos, quantidades, vencimentos)

**Trade Execution BC:**
- ✅ Modos de execução (paper vs real)
- ✅ Cálculo de P&L (simulado e real)
- ✅ Lógica de promoção paper → real
- ✅ Validações de margem disponível

**Risk Management BC:**
- ✅ Detecção de conflitos entre estratégias
- ✅ Validação de limites (por ativo, por usuário)
- ✅ Cálculo de exposição agregada
- ✅ Regras de stop-loss/take-profit

**Frontend (Vue 3):**
- ✅ Componentes isolados (lógica de UI)
- ✅ Composables (state management, formatação)
- ✅ Validações de formulários (criar estratégia)
- ✅ Cálculos client-side (preview de P&L)

### 2. Integration Tests - APIs & Cross-BC

**Foco:** Comunicação entre componentes, integrações externas  

**Backend Integration:**
- ✅ API endpoints (HTTP status, payloads, validações)
- ✅ Cross-BC communication (Strategy Planning → Risk Management)
- ✅ Database integration (Entity Framework, queries complexas)
- ✅ SignalR hubs (WebSocket real-time updates)

**External Integrations (ACLs):**
- ✅ B3 Market Data API (mocked - contrato testado)
- ✅ Authentication provider (OAuth/OIDC)
- ⏭️ Broker APIs (Epic 3+ - quando implementado)

**Frontend Integration:**
- ✅ API client calls (Axios, error handling)
- ✅ Router navigation (Vue Router)
- ✅ State management (Pinia stores)
- ✅ WebSocket client (SignalR connection)

### 3. E2E Tests - User Journeys

**Foco:** Fluxos completos de alto valor  

**Fluxos Críticos (Obrigatórios):**
1. ✅ **Criar e ativar estratégia (paper trading)**
   - Login → Criar template butterfly → Instanciar → Ativar paper → Ver P&L simulado
2. ✅ **Promover estratégia para real trading**
   - Paper strategy → Verificar margem → Promover → Confirmar ordens → Ver P&L real
3. ✅ **Monitorar riscos e conflitos**
   - Múltiplas estratégias ativas → Detectar conflito → Receber alerta → Ajustar limites
4. ✅ **Encerrar estratégia antecipadamente**
   - Estratégia ativa → Stop-loss atingido → Encerrar → Calcular P&L final

**Fluxos Secundários (Épicos futuros):**
- Importar estratégia de arquivo
- Compartilhar template com comunidade
- Gerar relatório de performance mensal

---

## ⚙️ Quality Gates

### Pre-Commit (Local)

```bash
# Backend (.NET 8)
dotnet test --collect:"XPlat Code Coverage"
dotnet build --no-restore --warnings-as-errors

# Frontend (Vue 3)
npm run test:unit
npm run lint
npm run type-check
```

### Pull Request (CI/CD - definido pelo GM-00)

**Bloqueios Obrigatórios:**
- ❌ Coverage < 70% (global)
- ❌ Testes falhando (qualquer tipo)
- ❌ Build errors
- ❌ Lint errors (críticos)
- ❌ Security vulnerabilities (high/critical)

**Warnings (não bloqueiam, mas exigem justificativa):**
- ⚠️ Coverage drop > 5% (em relação à main)
- ⚠️ Mutation score < 60% (se mutation testing ativo)
- ⚠️ Performance degradation (benchmarks - Epic 3+)

### Pre-Deploy (Staging)

- ✅ E2E tests passando (smoke tests mínimos)
- ✅ Integration tests com database real
- ✅ Health checks endpoints respondendo

### Pre-Deploy (Production)

- ✅ Todos os testes (unit + integration + E2E)
- ✅ Smoke tests em staging (últimas 24h)
- ✅ Manual approval (product owner)

---

## 📅 Testing Schedule - Epic 1 (Discovery)

### Week 1-2 (Planning Phase)

- [x] QAE-00 definido (este documento)
- [ ] Test infrastructure setup (CI/CD - GM-00)
- [ ] Coverage tool configurado (Coverlet .NET, Vitest coverage)

### Week 3-4 (Implementation Phase)

**Backend (DE + QAE):**
- [ ] Unit tests para Strategy Planning BC (margem, gregas, transformações)
- [ ] Unit tests para Trade Execution BC (paper/real, promoção)
- [ ] Integration tests para APIs principais

**Frontend (FE + QAE):**
- [ ] Unit tests para componentes críticos (StrategyForm, PositionCard)
- [ ] Unit tests para composables (useStrategy, useMarketData)
- [ ] Integration tests para Pinia stores

**E2E (QAE):**
- [ ] Setup Playwright + base page objects
- [ ] E2E test: Criar e ativar estratégia (paper)
- [ ] E2E test: Monitorar P&L em tempo real

### Week 5-6 (Validation Phase)

- [ ] Code review focado em testabilidade
- [ ] Mutation testing experiment (opcional)
- [ ] Coverage report review (70%+ atingido?)

---

## 🧩 Test Data Strategy

### Factories & Builders

**Backend (.NET + Bogus):**
```csharp
// Strategy Planning BC
public class StrategyFaker : Faker<Strategy>
{
    public StrategyFaker()
    {
        RuleFor(s => s.UnderlyingAsset, f => f.PickRandom("PETR4", "VALE3", "ITUB4"));
        RuleFor(s => s.Legs, f => new LegFaker().Generate(f.Random.Int(1, 4)));
    }
}
```

**Frontend (Vue 3 + Testing Library):**
```typescript
// Test factory
export const createMockStrategy = (overrides?: Partial<Strategy>): Strategy => ({
  id: faker.string.uuid(),
  underlyingAsset: 'PETR4',
  legs: [createMockLeg()],
  ...overrides
})
```

### Database Seeding (Integration Tests)

- ✅ In-memory database (SQLite) para testes rápidos
- ✅ Docker PostgreSQL container para testes realistas (CI/CD)
- ✅ Seed scripts com cenários conhecidos (DbContext.SeedTestData())

### Mocking Strategy

**Mock Externo (ACLs):**
- ✅ B3 Market Data API → WireMock / Moq
- ✅ Authentication → JWT fake tokens
- ⏭️ Broker API → Mocked (Epic 3+)

**Mock Interno (Cross-BC):**
- ✅ Use mocks para dependências entre BCs em unit tests
- ✅ Use real implementations em integration tests

---

## 🔒 Testing LGPD Compliance

**Dados Sensíveis a Proteger nos Testes:**
- ❌ CPF/Email reais em factories (usar fakes)
- ❌ Senhas reais (usar bcrypt hashes fake)
- ❌ Tokens de produção (usar mock tokens)
- ❌ Market data real em commits (usar data sintética)

**Boas Práticas:**
- ✅ Bogus/Faker para geração de dados fake
- ✅ .gitignore para arquivos de test data local
- ✅ Anonymização de dados em database dumps

---

## 📈 Metrics & Reporting

### Coverage Dashboard (CI/CD)

**Ferramentas:**
- Backend: Coverlet → ReportGenerator → HTML report
- Frontend: Vitest coverage → Istanbul/c8 → HTML report
- Agregação: SonarQube (opcional - Epic 2+)

**Visualização:**
- PR comments com diff de coverage
- Badge no README: ![Coverage](https://img.shields.io/badge/coverage-75%25-green)

### Test Execution Reports

**Por Tipo:**
- Unit: Tempo total < 30s
- Integration: Tempo total < 2min
- E2E: Tempo total < 5min

**Flaky Tests:**
- Tracking de testes instáveis (> 1 falha em 10 runs)
- Automatic retry (max 2x) para E2E
- Quarantine de testes flaky críticos

---

## 🚀 Testing Anti-Patterns (Evitar)

### ❌ Ice Cream Cone (Anti-Pattern)

```
  /--------\   Muitos E2E (lento, frágil)
 /----\      Poucos Integration
/--\         Pouquíssimos Unit
```

**Problema:** E2E são lentos e frágeis. Priorizar unit tests.  

### ❌ Testing Implementation Details

```typescript
// ❌ BAD: Testando detalhes de implementação Vue
expect(wrapper.vm.internalState).toBe('loading')

// ✅ GOOD: Testando comportamento do usuário
expect(screen.getByText('Carregando...')).toBeInTheDocument()
```

### ❌ Flaky Tests sem Tratamento

```csharp
// ❌ BAD: Sleep hardcoded
await Task.Delay(1000); // Pode falhar se lento

// ✅ GOOD: Wait for condition
await WaitUntil(() => position.Status == "Active", timeout: 5000);
```

### ❌ Testes sem Assertions

```csharp
// ❌ BAD: Teste só verifica que não lança exception
[Fact]
public void Calculate_ShouldNotThrow()
{
    calculator.Calculate(strategy);
}

// ✅ GOOD: Verifica resultado esperado
[Fact]
public void Calculate_ShouldReturnCorrectMargin()
{
    var result = calculator.Calculate(strategy);
    Assert.Equal(400.00m, result.Amount, precision: 2);
}
```

---

## ✅ QAE Definition of Done Checklist

### Strategy
- [x] Test pyramid definido para trading platform
- [x] Coverage targets estabelecidos por BC
- [x] Testing stack alinhado com PE-00
- [x] Quality gates documentados (PR, deploy)

### Documentation
- [x] QAE-00-Test-Strategy.md criado (versão simplificada)
- [x] O QUE testar documentado por BC
- [x] Princípio DRY aplicado (referência PE-00)
- [x] Anti-patterns documentados

### Tooling (GM-00 implementará)
- [ ] xUnit + Moq configurado (backend)
- [ ] Vitest + Testing Library configurado (frontend)
- [ ] Playwright setup (E2E)
- [ ] Coverage tools configurados (CI/CD)

### Implementation (Epic 1 - Implementation Phase)
- [ ] Primeiros unit tests escritos (Strategy Planning BC)
- [ ] Primeiro E2E test funcional (criar estratégia paper)
- [ ] Coverage > 70% alcançado

---

## 🎯 Próximos Passos

**Após QAE-00:**
1. **GM-00** configura CI/CD com test automation
2. **SEC-00** adiciona security testing (SAST/DAST)
3. **DE/FE** implementam testes durante development (TDD recomendado)

**Epic 2+ (Expansão):**
- Mutation testing (Stryker.NET, Stryker4s)
- Contract testing (Pact)
- Performance testing (k6, BenchmarkDotNet)
- Visual regression testing (Percy, Chromatic)

---

## 📚 Referências

- **PE-00:** Stack tecnológico e ferramentas → [`PE-00-Environments-Setup.md`](../08-platform-engineering/PE-00-Environments-Setup.md)
- **SDA-02:** Context Map (BCs prioritários) → [`SDA-02-Context-Map.md`](../02-strategic-ddd/SDA-02-Context-Map.md)
- **SDA-03:** Ubiquitous Language → [`SDA-03-Ubiquitous-Language.md`](../02-strategic-ddd/SDA-03-Ubiquitous-Language.md)

**External Resources:**
- Martin Fowler - Test Pyramid: https://martinfowler.com/articles/practical-test-pyramid.html
- xUnit Best Practices: https://xunit.net/docs/comparisons
- Vue Testing Library: https://testing-library.com/docs/vue-testing-library/intro
- Playwright Documentation: https://playwright.dev/

---

**Última atualização:** 2025-10-15  
**Fase:** Discovery (Epic 1)  
**Status:** ✅ Estratégia definida, pronta para implementação  
