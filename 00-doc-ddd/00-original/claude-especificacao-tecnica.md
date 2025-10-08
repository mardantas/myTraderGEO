# Especificação Técnica - myTraderGEO

## 1. Visão Geral do Sistema

### 1.1 Propósito
O myTraderGEO é uma plataforma web para gestão de estratégias de opções, oferecendo ferramentas para montagem, ajuste, desmonte e monitoramento de estratégias de investimento com integração ao mercado brasileiro.

### 1.2 Arquitetura Geral
- **Padrão**: Domain-Driven Design (DDD) com Clean Architecture
- **Estilo**: API RESTful
- **Frontend**: SPA (Single Page Application) com Vue.js
- **Backend**: .NET 8 com ASP.NET Core
- **Banco de Dados**: PostgreSQL com Entity Framework Core
- **Orquestração**: Docker Swarm para staging/produção
- **Proxy Reverso**: Traefik para load balancing e SSL

## 2. Arquitetura de Software

### 2.1 Estrutura de Domínios (DDD)

#### 2.1.1 Bounded Contexts
```
┌─────────────────────────────────────────────────────────────┐
│                    myTraderGEO System                       │
├─────────────────────────────────────────────────────────────┤
│  Identity & Access Management  │  Gestão de Estratégias       │
│  - Gestão de Usuários             │  - Strategy CRUD           │
│  - Authentication              │  - Strategy Execution      │
│  - Authorization               │  - Performance Tracking    │
│  - Subscription Plans          │                            │
├─────────────────────────────────────────────────────────────┤
│  Gestão de Portfólio          │  Dados de Mercado               │
│  - Asset Management            │  - Real-time Feeds         │
│  - Position Tracking           │  - Historical Data         │
│  - P&L Calculation             │  - Options Pricing         │
│  - Gestão de Risco             │  - Volatility Calculation  │
├─────────────────────────────────────────────────────────────┤
│  Order Management              │  Notification & Comunicação│
│  - Order Creation              │  - Alerts                  │
│  - Order Validation            │  - Chat System             │
│  - Execution Tracking          │  - Email/SMS               │
│  - Reconciliation              │  - Push Notifications      │
└─────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Agregados Principais

**Strategy Aggregate:**
```csharp
public class Strategy : AggregateRoot<StrategyId>
{
    public string Name { get; private set; }
    public string Description { get; private set; }
    public StrategyType Type { get; private set; }
    public StrategyStatus Status { get; private set; }
    public Money Investment { get; private set; }
    public Money CurrentValue { get; private set; }
    public decimal RequiredMargin { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? ExpirationDate { get; private set; }
    public List<StrategyLeg> Legs { get; private set; }
    public List<StrategyAdjustment> Adjustments { get; private set; }
    public ExitConditions ExitConditions { get; private set; }
}

public class StrategyLeg : Entity<StrategyLegId>
{
    public string OptionCode { get; private set; }
    public string UnderlyingAsset { get; private set; }
    public decimal Strike { get; private set; }
    public OptionType Type { get; private set; } // Call/Put
    public PositionType Position { get; private set; } // Long/Short
    public int Quantity { get; private set; }
    public Money Premium { get; private set; }
    public DateTime ExpirationDate { get; private set; }
    public ExerciseStyle ExerciseStyle { get; private set; }
}
```

**Portfolio Aggregate:**
```csharp
public class Portfolio : AggregateRoot<PortfolioId>
{
    public UserId UserId { get; private set; }
    public Money TotalEquity { get; private set; }
    public Money AvailableMargin { get; private set; }
    public Money UsedMargin { get; private set; }
    public List<Position> Positions { get; private set; }
    public List<Asset> FreeAssets { get; private set; }
    public List<Asset> CollateralAssets { get; private set; }
    public RiskProfile RiskProfile { get; private set; }
}
```

### 2.2 Camadas da Aplicação

#### 2.2.1 Estrutura de Projeto
```
src/
├── Domain/
│   ├── Entities/
│   ├── ValueObjects/
│   ├── Aggregates/
│   ├── DomainEvents/
│   ├── Repositories/
│   └── Services/
├── Application/
│   ├── Commands/
│   ├── Queries/
│   ├── Handlers/
│   ├── DTOs/
│   └── Services/
├── Infrastructure/
│   ├── Persistence/
│   ├── ExternalServices/
│   ├── Messaging/
│   └── Configuration/
└── Web/
    ├── Controllers/
    ├── Middleware/
    ├── Filters/
    └── Configuration/
```

#### 2.2.2 Padrões Implementados
- **CQRS**: Separação de comandos e queries
- **Mediator**: Para desacoplamento entre controllers e handlers
- **Repository**: Para abstração de acesso a dados
- **Unit of Work**: Para transações consistentes
- **Event Sourcing**: Para auditoria e histórico de mudanças

## 3. Especificação de APIs

### 3.1 Endpoints Principais

#### 3.1.1 Gestão de Estratégias API
```yaml
/api/v1/strategies:
  GET:
    summary: Listar estratégias do usuário
    parameters:
      - name: page
        in: query
        type: integer
      - name: pageSize
        in: query
        type: integer
      - name: status
        in: query
        type: string
        enum: [active, closed, simulated]
    responses:
      200:
        description: Lista paginada de estratégias
  
  POST:
    summary: Criar nova estratégia
    requestBody:
      required: true
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/CreateStrategyRequest'
    responses:
      201:
        description: Estratégia criada com sucesso

/api/v1/strategies/{id}:
  GET:
    summary: Obter detalhes da estratégia
  PUT:
    summary: Atualizar estratégia
  DELETE:
    summary: Encerrar estratégia

/api/v1/strategies/{id}/adjustments:
  POST:
    summary: Realizar ajuste na estratégia
    requestBody:
      required: true
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/AdjustStrategyRequest'
```

#### 3.1.2 Dados de Mercado API
```yaml
/api/v1/market-data/options:
  GET:
    summary: Obter dados de opções
    parameters:
      - name: underlying
        in: query
        type: string
        required: true
      - name: expiration
        in: query
        type: string
        format: date
    responses:
      200:
        description: Dados de opções disponíveis

/api/v1/market-data/real-time/{symbol}:
  GET:
    summary: Obter cotação em tempo real
  
/api/v1/market-data/historical/{symbol}:
  GET:
    summary: Obter dados históricos
    parameters:
      - name: from
        in: query
        type: string
        format: date-time
      - name: to
        in: query
        type: string
        format: date-time
```

### 3.2 Schemas de Dados

#### 3.2.1 Request/Response Models
```typescript
interface CreateStrategyRequest {
  name: string;
  description: string;
  type: StrategyType;
  legs: StrategyLegRequest[];
  exitConditions: ExitConditionsRequest;
  isSimulated: boolean;
}

interface StrategyLegRequest {
  optionCode: string;
  underlyingAsset: string;
  strike: number;
  type: 'call' | 'put';
  position: 'long' | 'short';
  quantity: number;
  premium: number;
  expirationDate: string;
}

interface StrategyResponse {
  id: string;
  name: string;
  description: string;
  type: StrategyType;
  status: StrategyStatus;
  currentValue: number;
  investedValue: number;
  profitLoss: number;
  profitLossPercentage: number;
  requiredMargin: number;
  createdAt: string;
  legs: StrategyLegResponse[];
  performance: PerformanceMetrics;
}
```

## 4. Modelo de Dados

### 4.1 Diagrama ER Conceitual
```sql
-- Usuários e Autenticação
CREATE TABLE Users (
    Id UUID PRIMARY KEY,
    Email VARCHAR(255) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    SubscriptionPlan VARCHAR(50) NOT NULL,
    CreatedAt TIMESTAMP NOT NULL,
    UpdatedAt TIMESTAMP NOT NULL,
    IsActive BOOLEAN DEFAULT TRUE
);

-- Estratégias
CREATE TABLE Strategies (
    Id UUID PRIMARY KEY,
    UserId UUID NOT NULL REFERENCES Users(Id),
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    Type VARCHAR(50) NOT NULL,
    Status VARCHAR(50) NOT NULL,
    Investment DECIMAL(18,2) NOT NULL,
    CurrentValue DECIMAL(18,2) NOT NULL,
    RequiredMargin DECIMAL(18,2) NOT NULL,
    IsSimulated BOOLEAN DEFAULT FALSE,
    CreatedAt TIMESTAMP NOT NULL,
    UpdatedAt TIMESTAMP NOT NULL,
    ExpirationDate TIMESTAMP,
    ExitConditions JSONB
);

-- Pernas da Estratégia
CREATE TABLE StrategyLegs (
    Id UUID PRIMARY KEY,
    StrategyId UUID NOT NULL REFERENCES Strategies(Id),
    OptionCode VARCHAR(50) NOT NULL,
    UnderlyingAsset VARCHAR(20) NOT NULL,
    Strike DECIMAL(10,2) NOT NULL,
    Type VARCHAR(10) NOT NULL, -- 'call' ou 'put'
    Position VARCHAR(10) NOT NULL, -- 'long' ou 'short'
    Quantity INTEGER NOT NULL,
    Premium DECIMAL(18,2) NOT NULL,
    ExpirationDate TIMESTAMP NOT NULL,
    ExerciseStyle VARCHAR(20) NOT NULL,
    CreatedAt TIMESTAMP NOT NULL
);

-- Ajustes de Estratégia
CREATE TABLE StrategyAdjustments (
    Id UUID PRIMARY KEY,
    StrategyId UUID NOT NULL REFERENCES Strategies(Id),
    Type VARCHAR(50) NOT NULL, -- 'roll', 'hedge', 'rebalance'
    Description TEXT,
    ExecutedAt TIMESTAMP NOT NULL,
    Cost DECIMAL(18,2) NOT NULL,
    Details JSONB
);

-- Portfólio
CREATE TABLE Portfolios (
    Id UUID PRIMARY KEY,
    UserId UUID NOT NULL REFERENCES Users(Id),
    TotalEquity DECIMAL(18,2) NOT NULL,
    AvailableMargin DECIMAL(18,2) NOT NULL,
    UsedMargin DECIMAL(18,2) NOT NULL,
    UpdatedAt TIMESTAMP NOT NULL
);

-- Posições
CREATE TABLE Positions (
    Id UUID PRIMARY KEY,
    PortfolioId UUID NOT NULL REFERENCES Portfolios(Id),
    StrategyId UUID REFERENCES Strategies(Id),
    AssetCode VARCHAR(50) NOT NULL,
    Quantity INTEGER NOT NULL,
    AveragePrice DECIMAL(18,2) NOT NULL,
    CurrentPrice DECIMAL(18,2) NOT NULL,
    Status VARCHAR(50) NOT NULL, -- 'free', 'allocated', 'collateral'
    UpdatedAt TIMESTAMP NOT NULL
);

-- Dados de Mercado (Cache)
CREATE TABLE MarketData (
    Id UUID PRIMARY KEY,
    Symbol VARCHAR(50) NOT NULL,
    Price DECIMAL(18,2) NOT NULL,
    Volume BIGINT NOT NULL,
    Timestamp TIMESTAMP NOT NULL,
    DataSource VARCHAR(50) NOT NULL,
    UNIQUE(Symbol, Timestamp, DataSource)
);

-- Índices para Performance
CREATE INDEX idx_strategies_userid_status ON Strategies(UserId, Status);
CREATE INDEX idx_strategylegss_strategyid ON StrategyLegs(StrategyId);
CREATE INDEX idx_positions_portfolioid ON Positions(PortfolioId);
CREATE INDEX idx_marketdata_symbol_timestamp ON MarketData(Symbol, Timestamp DESC);
```

## 5. Integrações Externas

### 5.1 Provedores de Dados de Mercado

#### 5.1.1 Configuração Multi-Provider
```csharp
public interface IMarketDataProvider
{
    Task<MarketData> GetRealTimeDataAsync(string symbol);
    Task<IEnumerable<MarketData>> GetHistoricalDataAsync(string symbol, DateTime from, DateTime to);
    Task<IEnumerable<OptionData>> GetOptionsDataAsync(string underlying);
    Task<VolatilityData> GetVolatilityDataAsync(string symbol);
}

public class MarketDataService
{
    private readonly IEnumerable<IMarketDataProvider> _providers;
    private readonly IConfiguration _configuration;

    public async Task<MarketData> GetRealTimeDataAsync(string symbol)
    {
        var primaryProvider = _providers.First(p => p.GetType().Name == _configuration["MarketData:Primary"]);
        
        try
        {
            return await primaryProvider.GetRealTimeDataAsync(symbol);
        }
        catch (Exception ex)
        {
            // Fallback para provider secundário
            var fallbackProvider = _providers.Skip(1).First();
            return await fallbackProvider.GetRealTimeDataAsync(symbol);
        }
    }
}
```

#### 5.1.2 Providers Suportados
- **Primário**: Bloomberg API ou TradingView
- **Secundário**: Yahoo Finance ou Alpha Vantage
- **B3**: Integração direta para dados oficiais (futuro)

### 5.2 Integração com Brokers

#### 5.2.1 Arquitetura de Integração
```csharp
public interface IBrokerIntegration
{
    Task<OrderResult> PlaceOrderAsync(OrderRequest order);
    Task<OrderStatus> GetOrderStatusAsync(string orderId);
    Task<IEnumerable<Position>> GetPositionsAsync(string accountId);
    Task<AccountInfo> GetAccountInfoAsync(string accountId);
}

public class OrderRequest
{
    public string Symbol { get; set; }
    public OrderType Type { get; set; } // Market, Limit, Stop
    public OrderSide Side { get; set; } // Buy, Sell
    public decimal Quantity { get; set; }
    public decimal? Price { get; set; }
    public DateTime? ExpirationDate { get; set; }
}
```

#### 5.2.2 Brokers Suportados (Roadmap)
- **Nelogica**: Via API REST
- **Cedro**: Via API REST
- **B3**: Integração direta (Drop Copy)

## 6. Segurança

### 6.1 Autenticação e Autorização

#### 6.1.1 JWT Authentication
```csharp
public class JwtTokenService
{
    public string GenerateToken(User user)
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim("subscription_plan", user.SubscriptionPlan.ToString()),
            new Claim("permissions", string.Join(",", user.Permissions))
        };

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
```

#### 6.1.2 Role-Based Access Control
```csharp
public enum Permission
{
    ReadStrategies,
    WriteStrategies,
    DeleteStrategies,
    ExecuteOrders,
    AccessRealTimeData,
    AccessHistoricalData,
    ManageUsers,
    ViewReports
}

public class AuthorizationService
{
    public bool HasPermission(User user, Permission permission)
    {
        return user.SubscriptionPlan switch
        {
            SubscriptionPlan.Basic => BasicPermissions.Contains(permission),
            SubscriptionPlan.Premium => PremiumPermissions.Contains(permission),
            SubscriptionPlan.Consultant => ConsultantPermissions.Contains(permission),
            _ => false
        };
    }
}
```

### 6.2 Proteção de Dados

#### 6.2.1 Criptografia
- **Em trânsito**: TLS 1.3 para todas as comunicações
- **Em repouso**: AES-256 para dados sensíveis
- **Chaves**: Azure Key Vault ou AWS KMS para gerenciamento

#### 6.2.2 Compliance
- **LGPD**: Consentimento explícito, direito ao esquecimento
- **Auditoria**: Log de todas as operações críticas
- **Backup**: Criptografado com retenção de 7 anos

## 7. Performance e Escalabilidade

### 7.1 Estratégias de Cache

#### 7.1.1 Redis Cache
```csharp
public class CacheService
{
    private readonly IDistributedCache _cache;
    
    public async Task<T> GetOrSetAsync<T>(string key, Func<Task<T>> factory, TimeSpan expiration)
    {
        var cached = await _cache.GetStringAsync(key);
        if (cached != null)
            return JsonSerializer.Deserialize<T>(cached);

        var result = await factory();
        await _cache.SetStringAsync(key, JsonSerializer.Serialize(result), 
            new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = expiration });
        
        return result;
    }
}
```

#### 7.1.2 Estratégias de Cache por Tipo
- **Dados de Mercado**: 5 segundos (real-time), 1 hora (histórico)
- **Estratégias**: 30 segundos
- **Portfólio**: 15 segundos
- **Configurações**: 1 hora

### 7.2 Otimizações de Banco de Dados

#### 7.2.1 Índices Estratégicos
```sql
-- Consultas mais frequentes
CREATE INDEX CONCURRENTLY idx_strategies_user_status_created 
    ON Strategies(UserId, Status, CreatedAt DESC);

-- Particionamento por data
CREATE TABLE MarketData_2024 PARTITION OF MarketData
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

#### 7.2.2 Read Replicas
- **Master**: Escritas e leituras críticas
- **Replica**: Relatórios e consultas analíticas
- **Balanceamento**: Automático baseado em carga

## 8. Monitoramento e Observabilidade

### 8.1 Métricas Principais
- **Latência**: P50, P95, P99 por endpoint
- **Throughput**: RPS por serviço
- **Error Rate**: Taxa de erro por operação
- **Disponibilidade**: SLA de 99.9%

### 8.2 Health Checks
```csharp
public class HealthCheckExtensions
{
    public static IServiceCollection AddCustomHealthChecks(this IServiceCollection services)
    {
        services.AddHealthChecks()
            .AddNpgSql(connectionString)
            .AddRedis(redisConnectionString)
            .AddCheck<MarketDataHealthCheck>("market-data")
            .AddCheck<BrokerHealthCheck>("broker-integration");
        
        return services;
    }
}
```

## 9. Deployment e DevOps

### 9.1 Pipeline CI/CD
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: dotnet test --configuration Release
      
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Build Docker Image
        run: |
          docker build -t mytrader-geo-api:${{ github.sha }} .
          docker push mytrader-geo-api:${{ github.sha }}
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Docker Swarm
        run: |
          docker service update --image mytrader-geo-api:${{ github.sha }} mytrader-geo-api
```

### 9.2 Ambiente de Produção
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    command:
      - "--providers.docker.swarmMode=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - traefik-certificates:/certificates
    networks:
      - traefik-network
    deploy:
      mode: global
      placement:
        constraints: [node.role == manager]

  api:
    image: mytrader-geo-api:latest
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=Server=db;Database=mytrader;User Id=mytrader-p;Password=${DB_PASSWORD}
      - Redis__ConnectionString=redis:6379
    networks:
      - traefik-network
      - backend-network
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.api.rule=Host(`api.geo.mytrader.net`)"
        - "traefik.http.routers.api.tls.certresolver=myresolver"
        - "traefik.http.services.api.loadbalancer.server.port=80"

  frontend:
    image: mytrader-geo-frontend:latest
    networks:
      - traefik-network
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.frontend.rule=Host(`geo.mytrader.net`)"
        - "traefik.http.routers.frontend.tls.certresolver=myresolver"

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=mytrader
      - POSTGRES_USER=mytrader-p
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - backend-network
    deploy:
      replicas: 1
      placement:
        constraints: [node.role == manager]

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    networks:
      - backend-network
    deploy:
      replicas: 1
      placement:
        constraints: [node.role == manager]

volumes:
  postgres-data:
  redis-data:
  traefik-certificates:

networks:
  traefik-network:
    external: true
  backend-network:
    driver: overlay
```

## 10. Considerações Finais

### 10.1 Requisitos Não Funcionais
- **Performance**: Tempo de resposta < 200ms para 95% das requisições
- **Disponibilidade**: 99.9% uptime (8.77 horas de downtime por ano)
- **Escalabilidade**: Suporte para 10.000 usuários simultâneos
- **Segurança**: Conformidade com LGPD e melhores práticas de segurança

### 10.2 Tecnologias e Versões
- **.NET**: 8.0 LTS
- **Vue.js**: 3.4
- **PostgreSQL**: 15
- **Redis**: 7
- **Docker**: 24.0
- **Traefik**: 2.10

### 10.3 Métricas de Sucesso
- **Adoção**: 1.000 usuários ativos nos primeiros 6 meses
- **Engagement**: 70% dos usuários utilizando pelo menos 3 funcionalidades
- **Performance**: 95% das operações concluídas em menos de 2 segundos
- **Satisfação**: NPS > 50 nos primeiros 12 meses