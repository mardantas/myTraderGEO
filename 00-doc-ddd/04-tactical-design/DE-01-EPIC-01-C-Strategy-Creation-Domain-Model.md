# DE-01-EPIC-01-C-Strategy-Creation-Domain-Model.md

**Projeto:** myTraderGEO  
**Épico:** EPIC-01-C - Strategy Creation (segmento do EPIC-01)  
**Data:** 2025-10-25  
**Engineer:** DE Agent  

---

## 🎯 Contexto do Sub-Épico

**Nome do Sub-Épico:** Strategy Creation  

**Bounded Context:** Strategy Planning  

**Objetivo:**
Modelar a criação e gestão de estratégias instanciadas com valores absolutos (strikes em R$, datas específicas), incluindo paper trading, tracking de P&L (histórico de snapshots), ajustes/manejo de posições ativas e validação de limites por plano de assinatura.

**Aggregates Modelados:**
- Strategy (Aggregate Root)
  - StrategyLeg (Child Entity)
  - PnLSnapshot (Child Entity)

---

## 📋 Índice do Modelo de Domínio

### Strategy Planning BC

#### [Aggregate: Strategy](#5-strategy-aggregate-root)
**Responsabilidade:** Estratégias instanciadas com valores absolutos, paper trading, P&L tracking e manejo  

**Entities:**
  - StrategyLeg, PnLSnapshot

**Value Objects:**
  - StrategyId, StrategyLegId, PnLSnapshotId, StrategyStatus, PnLType

**Domain Events:**
  - StrategyCreated, StrategyValidated
  - StrategyPaperTradingStarted, StrategyWentLive
  - StrategyPnLUpdated, PnLSnapshotCaptured
  - StrategyLegAdjusted, StrategyLegAddedToActive, StrategyLegRemoved
  - StrategyClosed

---

# Strategy Planning

## Aggregates

## 5. Strategy (Aggregate Root)

**Responsabilidade:** Gerenciar estratégia instanciada com valores absolutos (strikes em R$, datas específicas)  

**Invariantes (Business Rules):**
1. UserId deve existir e ser Trader
2. Deve respeitar StrategyLimit do SubscriptionPlan do usuário
3. Ticker deve ser válido (PETR4, VALE3, etc)
4. Deve ter ao menos 1 leg sempre (não pode remover última leg)
5. Strikes devem ser valores absolutos em R$
6. Expirations devem ser datas futuras
7. Apenas estratégias PaperTrading ou Live podem ter P&L atualizado
8. Apenas estratégias PaperTrading ou Live podem ser ajustadas (manejo)
9. P&L Snapshots são imutáveis após criação
10. Closing reason é obrigatório ao fechar estratégia
11. Paper trading pode ser convertido para Live (mantém histórico de P&L)
12. Validated pode ir direto para Live (sem paper trading)

## Entities

```csharp
// Aggregate Root
public class Strategy : Entity<StrategyId>
{
    // Properties
    public StrategyId Id { get; private set; }
    public UserId OwnerId { get; private set; }
    public string Name { get; private set; }
    public Ticker UnderlyingAsset { get; private set; } // PETR4, VALE3
    public StrategyTemplateId? TemplateId { get; private set; } // Null if created from scratch
    public StrategyStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? ClosedAt { get; private set; }
    public string? ClosingReason { get; private set; }

    // Calculated Values (Initial Estimates)
    public Money? EstimatedMargin { get; private set; }
    public decimal? EstimatedReturn { get; private set; }
    public RiskScore? RiskScore { get; private set; }

    // P&L Tracking
    public Money? CurrentPnL { get; private set; }              // P&L atual (não realizado)
    public decimal? CurrentPnLPercentage { get; private set; }  // % de retorno atual
    public DateTime? LastPnLUpdate { get; private set; }        // Última atualização de P&L

    // Legs (child entities)
    private readonly List<StrategyLeg> _legs = new();
    public IReadOnlyList<StrategyLeg> Legs => _legs.AsReadOnly();

    // P&L History (child entities)
    private readonly List<PnLSnapshot> _pnlHistory = new();
    public IReadOnlyList<PnLSnapshot> PnLHistory => _pnlHistory.AsReadOnly();

    // Domain Events
    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    // Private constructor for EF Core
    private Strategy() { }

    // Factory Method - From Template
    public static Strategy CreateFromTemplate(
        UserId ownerId,
        string name,
        Ticker underlyingAsset,
        StrategyTemplateId templateId,
        List<StrategyLeg> instantiatedLegs)
    {
        ValidateStrategy(name, instantiatedLegs);

        var strategy = new Strategy
        {
            Id = StrategyId.New(),
            OwnerId = ownerId,
            Name = name,
            UnderlyingAsset = underlyingAsset,
            TemplateId = templateId,
            Status = StrategyStatus.Draft,
            CreatedAt = DateTime.UtcNow,
            _legs = instantiatedLegs
        };

        strategy._domainEvents.Add(new StrategyInstantiated(
            strategy.Id,
            strategy.OwnerId,
            strategy.TemplateId.Value,
            strategy.UnderlyingAsset,
            strategy.Legs.Count,
            DateTime.UtcNow
        ));

        return strategy;
    }

    // Factory Method - From Scratch
    public static Strategy CreateFromScratch(
        UserId ownerId,
        string name,
        Ticker underlyingAsset,
        List<StrategyLeg> legs)
    {
        ValidateStrategy(name, legs);

        var strategy = new Strategy
        {
            Id = StrategyId.New(),
            OwnerId = ownerId,
            Name = name,
            UnderlyingAsset = underlyingAsset,
            TemplateId = null,
            Status = StrategyStatus.Draft,
            CreatedAt = DateTime.UtcNow,
            _legs = legs
        };

        strategy._domainEvents.Add(new StrategyCreated(
            strategy.Id,
            strategy.OwnerId,
            strategy.UnderlyingAsset,
            strategy.Legs.Count,
            DateTime.UtcNow
        ));

        return strategy;
    }

    private static void ValidateStrategy(string name, List<StrategyLeg> legs)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new DomainException("Strategy name is required");

        if (legs == null || legs.Count == 0)
            throw new DomainException("Strategy must have at least one leg");

        if (legs.Count > 10)
            throw new DomainException("Strategy cannot have more than 10 legs");
    }

    // Business Methods
    public void CalculateMargin(Money margin)
    {
        EstimatedMargin = margin;

        _domainEvents.Add(new MarginCalculated(
            Id,
            margin,
            DateTime.UtcNow
        ));
    }

    public void AssessRisk(RiskScore riskScore)
    {
        RiskScore = riskScore;

        _domainEvents.Add(new RiskAssessed(
            Id,
            riskScore,
            DateTime.UtcNow
        ));
    }

    public void Validate()
    {
        if (Status != StrategyStatus.Draft)
            throw new DomainException("Only draft strategies can be validated");

        Status = StrategyStatus.Validated;

        _domainEvents.Add(new StrategyValidated(
            Id,
            DateTime.UtcNow
        ));
    }

    // Paper Trading Methods
    public void StartPaperTrading()
    {
        if (Status != StrategyStatus.Validated)
            throw new DomainException("Only validated strategies can start paper trading");

        Status = StrategyStatus.PaperTrading;

        _domainEvents.Add(new StrategyPaperTradingStarted(
            Id,
            DateTime.UtcNow
        ));
    }

    public void GoLive()
    {
        if (Status != StrategyStatus.PaperTrading && Status != StrategyStatus.Validated)
            throw new DomainException("Only paper trading or validated strategies can go live");

        var wasPaperTrading = Status == StrategyStatus.PaperTrading;
        Status = StrategyStatus.Live;

        _domainEvents.Add(new StrategyWentLive(
            Id,
            wasPaperTrading,
            DateTime.UtcNow
        ));
    }

    // P&L Tracking Methods
    public void UpdatePnL(Money currentPnL, decimal currentPnLPercentage)
    {
        if (Status != StrategyStatus.PaperTrading && Status != StrategyStatus.Live)
            throw new DomainException("Only paper trading or live strategies can have P&L updated");

        CurrentPnL = currentPnL;
        CurrentPnLPercentage = currentPnLPercentage;
        LastPnLUpdate = DateTime.UtcNow;

        _domainEvents.Add(new StrategyPnLUpdated(
            Id,
            currentPnL,
            currentPnLPercentage,
            DateTime.UtcNow
        ));
    }

    public void CapturePnLSnapshot(Money pnlValue, decimal pnlPercentage, PnLType type)
    {
        if (Status != StrategyStatus.PaperTrading && Status != StrategyStatus.Live && type != PnLType.Closing)
            throw new DomainException("Only paper trading or live strategies can have P&L snapshots (except closing)");

        var snapshot = PnLSnapshot.Create(Id, pnlValue, pnlPercentage, type);
        _pnlHistory.Add(snapshot);

        _domainEvents.Add(new PnLSnapshotCaptured(
            Id,
            pnlValue,
            pnlPercentage,
            type,
            DateTime.UtcNow
        ));
    }

    // Strategy Management Methods (Manejo)
    public void AdjustLegQuantity(StrategyLegId legId, int newQuantity)
    {
        if (Status != StrategyStatus.PaperTrading && Status != StrategyStatus.Live)
            throw new DomainException("Only paper trading or live strategies can be adjusted");

        var leg = _legs.FirstOrDefault(l => l.Id == legId);
        if (leg == null)
            throw new DomainException("Leg not found");

        var oldQuantity = leg.Quantity;
        leg.UpdateQuantity(newQuantity);

        _domainEvents.Add(new StrategyLegAdjusted(
            Id,
            legId,
            oldQuantity,
            newQuantity,
            DateTime.UtcNow
        ));
    }

    public void AddLeg(StrategyLeg newLeg)
    {
        if (Status != StrategyStatus.PaperTrading && Status != StrategyStatus.Live)
            throw new DomainException("Only paper trading or live strategies can have legs added");

        if (newLeg == null)
            throw new DomainException("Leg cannot be null");

        _legs.Add(newLeg);

        _domainEvents.Add(new StrategyLegAddedToActive(
            Id,
            newLeg.Id,
            newLeg.Type,
            newLeg.Position,
            newLeg.Quantity,
            DateTime.UtcNow
        ));
    }

    public void RemoveLeg(StrategyLegId legId)
    {
        if (Status != StrategyStatus.PaperTrading && Status != StrategyStatus.Live)
            throw new DomainException("Only paper trading or live strategies can have legs removed");

        if (_legs.Count == 1)
            throw new DomainException("Cannot remove last leg - close strategy instead");

        var leg = _legs.FirstOrDefault(l => l.Id == legId);
        if (leg == null)
            throw new DomainException("Leg not found");

        _legs.Remove(leg);

        _domainEvents.Add(new StrategyLegRemoved(
            Id,
            legId,
            DateTime.UtcNow
        ));
    }

    public void Close(Money finalPnL, decimal finalPnLPercentage, string reason)
    {
        if (Status != StrategyStatus.PaperTrading && Status != StrategyStatus.Live)
            throw new DomainException("Only paper trading or live strategies can be closed");

        if (string.IsNullOrWhiteSpace(reason))
            throw new DomainException("Closing reason is required");

        // Capturar snapshot final
        CapturePnLSnapshot(finalPnL, finalPnLPercentage, PnLType.Closing);

        Status = StrategyStatus.Closed;
        CurrentPnL = finalPnL;
        CurrentPnLPercentage = finalPnLPercentage;
        ClosedAt = DateTime.UtcNow;
        ClosingReason = reason;

        _domainEvents.Add(new StrategyClosed(
            Id,
            finalPnL,
            finalPnLPercentage,
            reason,
            DateTime.UtcNow
        ));
    }
}

// Child Entity
public class StrategyLeg : Entity<StrategyLegId>
{
    public StrategyLegId Id { get; private set; }
    public LegType Type { get; private set; }
    public Position Position { get; private set; }
    public int Quantity { get; private set; }
    public Money? Strike { get; private set; } // Absolute value in BRL (null for Stock)
    public DateTime? Expiration { get; private set; } // Specific date (null for Stock)

    private StrategyLeg() { }

    // Factory Method - Stock
    public static StrategyLeg CreateStock(Position position, int quantity)
    {
        if (quantity <= 0)
            throw new DomainException("Quantity must be positive");

        return new StrategyLeg
        {
            Id = StrategyLegId.New(),
            Type = LegType.Stock,
            Position = position,
            Quantity = quantity,
            Strike = null,
            Expiration = null
        };
    }

    // Factory Method - Option
    public static StrategyLeg CreateOption(
        LegType type,
        Position position,
        int quantity,
        Money strike,
        DateTime expiration)
    {
        if (type == LegType.Stock)
            throw new DomainException("Use CreateStock for stock legs");

        if (quantity <= 0)
            throw new DomainException("Quantity must be positive");

        if (expiration <= DateTime.UtcNow)
            throw new DomainException("Expiration must be in the future");

        return new StrategyLeg
        {
            Id = StrategyLegId.New(),
            Type = type,
            Position = position,
            Quantity = quantity,
            Strike = strike,
            Expiration = expiration
        };
    }

    // Business Method - Ajustar quantidade (para manejo)
    public void UpdateQuantity(int newQuantity)
    {
        if (newQuantity <= 0)
            throw new DomainException("Quantity must be positive");

        Quantity = newQuantity;
    }
}

// Child Entity - P&L Snapshot
public class PnLSnapshot : Entity<PnLSnapshotId>
{
    public PnLSnapshotId Id { get; private set; }
    public StrategyId StrategyId { get; private set; }
    public Money PnLValue { get; private set; }
    public decimal PnLPercentage { get; private set; }
    public PnLType Type { get; private set; }
    public DateTime SnapshotAt { get; private set; }

    private PnLSnapshot() { }

    public static PnLSnapshot Create(
        StrategyId strategyId,
        Money pnlValue,
        decimal pnlPercentage,
        PnLType type)
    {
        return new PnLSnapshot
        {
            Id = PnLSnapshotId.New(),
            StrategyId = strategyId,
            PnLValue = pnlValue,
            PnLPercentage = pnlPercentage,
            Type = type,
            SnapshotAt = DateTime.UtcNow
        };
    }
}
```

## Value Objects

```csharp
public record StrategyId(Guid Value)
{
    public static StrategyId New() => new(Guid.NewGuid());
}

public record StrategyLegId(Guid Value)
{
    public static StrategyLegId New() => new(Guid.NewGuid());
}

public record PnLSnapshotId(Guid Value)
{
    public static PnLSnapshotId New() => new(Guid.NewGuid());
}

public record Ticker(string Value)
{
    public Ticker
    {
        if (string.IsNullOrWhiteSpace(Value))
            throw new ArgumentException("Ticker cannot be empty");

        // Validate B3 ticker format (PETR4, VALE3, etc)
        if (!System.Text.RegularExpressions.Regex.IsMatch(Value, @"^[A-Z]{4}\d{1,2}$"))
            throw new ArgumentException("Invalid ticker format");
    }
}

public enum StrategyStatus
{
    Draft,          // Apenas criada (rascunho)
    Validated,      // Validada, pronta para ativar
    PaperTrading,   // Paper trading - simulação com dados reais (sem capital)
    Live,           // Live trading - ativa com capital real
    Closed          // Encerrada
}

public enum PnLType
{
    Daily,      // Snapshot diário automático
    OnDemand,   // Trader solicitou atualização manual
    Closing     // Snapshot final no fechamento da estratégia
}

public record RiskScore(
    decimal Value, // 0.0 to 1.0
    RiskLevel Level
)
{
    public RiskScore
    {
        if (Value < 0 || Value > 1)
            throw new ArgumentException("Risk score must be between 0 and 1");
    }
}

public enum RiskLevel
{
    Low,
    Medium,
    High,
    Critical
}
```

## Domain Events

```csharp
public record StrategyInstantiated(
    StrategyId StrategyId,
    UserId OwnerId,
    StrategyTemplateId TemplateId,
    Ticker UnderlyingAsset,
    int LegCount,
    DateTime OccurredAt
) : IDomainEvent;

public record StrategyCreated(
    StrategyId StrategyId,
    UserId OwnerId,
    Ticker UnderlyingAsset,
    int LegCount,
    DateTime OccurredAt
) : IDomainEvent;

public record MarginCalculated(
    StrategyId StrategyId,
    Money Margin,
    DateTime OccurredAt
) : IDomainEvent;

public record RiskAssessed(
    StrategyId StrategyId,
    RiskScore RiskScore,
    DateTime OccurredAt
) : IDomainEvent;

public record StrategyValidated(
    StrategyId StrategyId,
    DateTime OccurredAt
) : IDomainEvent;

public record StrategyPaperTradingStarted(
    StrategyId StrategyId,
    DateTime OccurredAt
) : IDomainEvent;

public record StrategyWentLive(
    StrategyId StrategyId,
    bool WasPaperTrading,  // true = converteu de paper trading, false = direto de validated
    DateTime OccurredAt
) : IDomainEvent;

public record StrategyPnLUpdated(
    StrategyId StrategyId,
    Money CurrentPnL,
    decimal CurrentPnLPercentage,
    DateTime OccurredAt
) : IDomainEvent;

public record PnLSnapshotCaptured(
    StrategyId StrategyId,
    Money PnLValue,
    decimal PnLPercentage,
    PnLType SnapshotType,
    DateTime OccurredAt
) : IDomainEvent;

public record StrategyLegAdjusted(
    StrategyId StrategyId,
    StrategyLegId LegId,
    int OldQuantity,
    int NewQuantity,
    DateTime OccurredAt
) : IDomainEvent;

public record StrategyLegAddedToActive(
    StrategyId StrategyId,
    StrategyLegId LegId,
    LegType LegType,
    Position Position,
    int Quantity,
    DateTime OccurredAt
) : IDomainEvent;

public record StrategyLegRemoved(
    StrategyId StrategyId,
    StrategyLegId LegId,
    DateTime OccurredAt
) : IDomainEvent;

public record StrategyClosed(
    StrategyId StrategyId,
    Money FinalPnL,
    decimal FinalPnLPercentage,
    string Reason,
    DateTime OccurredAt
) : IDomainEvent;
```

---

## Repository Interface

```csharp
public interface IStrategyRepository
{
    Task<Strategy> GetByIdAsync(StrategyId id, CancellationToken ct);
    Task<IEnumerable<Strategy>> GetByOwnerAsync(UserId ownerId, CancellationToken ct);
    Task<IEnumerable<Strategy>> GetActiveByOwnerAsync(UserId ownerId, CancellationToken ct);
    Task<int> CountActiveStrategiesByOwnerAsync(UserId ownerId, CancellationToken ct);
    Task AddAsync(Strategy strategy, CancellationToken ct);
    Task UpdateAsync(Strategy strategy, CancellationToken ct);
}
```

**Queries Esperadas pelo DBA:**
1. `Strategy.GetByOwnerAsync` → Index em OwnerId
2. `Strategy.GetActiveByOwnerAsync` → Composite Index em (OwnerId, Status)
3. `Strategy.CountActiveStrategiesByOwnerAsync` → Composite Index em (OwnerId, Status)

---

## 🔄 Integração Entre Bounded Contexts

### User Management → Strategy Planning Integration

**Mecanismo:** API de leitura (queries) + validação síncrona  

**Fluxo de Validação de Limite:**
```
[Strategy Planning]
    → CreateStrategy command
    → Query User.SubscriptionPlan
    → Query SubscriptionPlan.StrategyLimit
    → Count current active strategies
    → If count < limit: Create strategy
    → Else: Throw DomainException("Strategy limit exceeded")
```

**Eventos Publicados por User Management:**
- `UserPlanUpgraded` → Strategy Planning pode reagir (notificar usuário)

---

### Strategy Planning → Market Data Integration

**Mecanismo:** Queries diretas (read-only) via repositories  

**Fluxo de Instanciação de Template (ATUALIZADO):**
```
[Strategy Planning]
    → InstantiateTemplate(templateId, ticker)
    → Query Market Data: GetUnderlyingAsset(ticker)
    → Query Market Data: GetAvailableOptions(ticker, filters)

    Para cada leg do template:
        1. Se leg é Stock:
           → Usar preço do UnderlyingAsset

        2. Se leg é Option:
           → Calcular strike absoluto:
              • ATM → currentPrice
              • ATM+5% → currentPrice * 1.05
           → Calcular vencimento absoluto
           → FindClosestOption(availableOptions, targetStrike, targetExpiration)
           → Validar:
              • Opção existe?
              • IV disponível?
              • Liquidez adequada? (spread < 5%)
           → Usar strike REAL e vencimento REAL da opção encontrada

    → Create Strategy com strikes/vencimentos reais
```

**APIs do Market Data BC usadas por Strategy Planning:**

```csharp
public interface IMarketDataService // ACL para Strategy Planning
{
    // Underlying Asset
    Task<UnderlyingAssetDto> GetAssetAsync(
        Ticker ticker,
        CancellationToken ct);

    // Opções Disponíveis
    Task<IEnumerable<OptionContractDto>> GetAvailableOptionsAsync(
        Ticker underlyingAsset,
        OptionType? typeFilter = null,
        DateTime? expirationFrom = null,
        DateTime? expirationTo = null,
        CancellationToken ct = default);

    // Opção Específica por Symbol
    Task<OptionContractDto?> GetOptionBySymbolAsync(
        string symbol,
        CancellationToken ct);
}

public record UnderlyingAssetDto(
    Ticker Symbol,
    string Name,
    Money CurrentPrice,
    DateTime LastUpdated
);

public record OptionContractDto(
    string Symbol,
    Ticker UnderlyingAsset,
    OptionType Type,
    ExerciseType ExerciseType,
    Money Strike,
    DateTime Expiration,
    int ContractMultiplier,
    Money? BidPrice,
    Money? AskPrice,
    Money? LastPrice,
    decimal? ImpliedVolatility,
    OptionGreeks? Greeks
);
```

**Eventos Publicados por Market Data:**
- `OptionStrikeAdjusted` → Strategy Planning pode alertar usuários com estratégias afetadas
- `OptionExpired` → Strategy Planning pode marcar estratégias como fechadas
- `OptionsDataSyncCompleted` → Pode notificar administradores sobre sync
- `NewOptionContractsDiscovered` → Pode notificar traders sobre novas opções

---

### Market Data → B3 API Integration (External Service)

**Mecanismo:** Anti-Corruption Layer (ACL) via IB3ApiClient  

**Interface Externa (Infrastructure Layer):**

```csharp
/// <summary>
/// Cliente HTTP para integração com APIs de dados da B3 / provedores de market data
/// Implementado na camada de Infrastructure com retry policies (Polly)
/// </summary>
public interface IB3ApiClient
{
    /// <summary>
    /// Busca todas as opções listadas de um ativo subjacente
    /// </summary>
    Task<IEnumerable<B3OptionData>> GetOptionsForUnderlyingAsync(
        string ticker,
        CancellationToken ct);

    /// <summary>
    /// Busca todas as opções listadas (para sync completo)
    /// </summary>
    Task<IEnumerable<B3OptionData>> GetAllListedOptionsAsync(
        CancellationToken ct);

    /// <summary>
    /// Busca dados atualizados de uma opção específica
    /// </summary>
    Task<B3OptionData?> GetOptionBySymbolAsync(
        string symbol,
        CancellationToken ct);

    /// <summary>
    /// Busca preço atual de um ativo subjacente
    /// </summary>
    Task<B3AssetPrice?> GetAssetPriceAsync(
        string ticker,
        CancellationToken ct);
}

/// <summary>
/// DTO de resposta da API B3 (raw data)
/// Mapeado para OptionContract pela camada de Application
/// </summary>
public record B3OptionData(
    string Symbol,              // PETRH245
    string UnderlyingTicker,    // PETR4
    string OptionType,          // "CALL" | "PUT"
    string ExerciseType,        // "AMERICAN" | "EUROPEAN"
    decimal StrikePrice,
    DateTime ExpirationDate,
    int ContractSize,           // 100, 1, etc
    decimal? BidPrice,
    decimal? AskPrice,
    decimal? LastPrice,
    DateTime? LastTradeTime,
    int? Volume,
    int? OpenInterest,
    decimal? ImpliedVolatility,
    B3Greeks? Greeks
);

public record B3Greeks(
    decimal Delta,
    decimal Gamma,
    decimal Vega,
    decimal Theta,
    decimal Rho
);

public record B3AssetPrice(
    string Ticker,
    string Name,
    decimal CurrentPrice,
    DateTime Timestamp
);

/// <summary>
/// Cliente WebSocket para feed de preços em tempo real da B3
/// Implementado na camada de Infrastructure com reconexão automática
/// </summary>
public interface IMarketDataFeedClient
{
    /// <summary>
    /// Conecta ao feed WebSocket da B3
    /// </summary>
    Task ConnectAsync(CancellationToken ct);

    /// <summary>
    /// Desconecta do feed
    /// </summary>
    Task DisconnectAsync();

    /// <summary>
    /// Subscreve para receber updates de preço de símbolos específicos
    /// </summary>
    Task SubscribeToSymbolsAsync(IEnumerable<string> symbols, CancellationToken ct);

    /// <summary>
    /// Remove subscrição de símbolos
    /// </summary>
    Task UnsubscribeFromSymbolsAsync(IEnumerable<string> symbols, CancellationToken ct);

    /// <summary>
    /// Evento disparado quando novo preço é recebido do feed
    /// </summary>
    event EventHandler<MarketDataUpdate> OnPriceUpdate;

    /// <summary>
    /// Evento disparado quando conexão é perdida
    /// </summary>
    event EventHandler<string> OnDisconnected;

    /// <summary>
    /// Evento disparado quando reconectado
    /// </summary>
    event EventHandler OnReconnected;

    /// <summary>
    /// Status da conexão
    /// </summary>
    bool IsConnected { get; }

    /// <summary>
    /// Símbolos atualmente subscritos
    /// </summary>
    IReadOnlySet<string> SubscribedSymbols { get; }
}

/// <summary>
/// Update de preço recebido do feed em tempo real
/// </summary>
public record MarketDataUpdate(
    string Symbol,
    decimal BidPrice,
    decimal AskPrice,
    decimal LastPrice,
    int Volume,
    DateTime Timestamp
);
```

**Exemplo de Uso no Application Layer:**

```csharp
// UC-MarketData-01: SyncOptionsHandler usa IB3ApiClient
var b3Options = await _b3ApiClient.GetAllListedOptionsAsync(ct);

foreach (var b3Option in b3Options)
{
    // Calcular série semanal usando Domain Service
    var series = _weeklySeriesCalculator.CalculateSeries(b3Option.ExpirationDate);

    // Verificar se já existe
    var existing = await _optionRepository.GetBySymbolAsync(b3Option.Symbol, ct);

    if (existing == null)
    {
        // Criar novo OptionContract
        var option = OptionContract.Create(
            b3Option.Symbol,
            Ticker.From(b3Option.UnderlyingTicker),
            MapOptionType(b3Option.OptionType),
            MapExerciseType(b3Option.ExerciseType),
            series,  // <-- Série calculada aqui
            Money.Brl(b3Option.StrikePrice),
            b3Option.ExpirationDate,
            b3Option.ContractSize
        );

        // Atualizar preços
        option.UpdateMarketPrices(
            Money.Brl(b3Option.BidPrice ?? 0),
            Money.Brl(b3Option.AskPrice ?? 0),
            Money.Brl(b3Option.LastPrice ?? 0),
            b3Option.LastTradeTime,
            b3Option.Volume,
            b3Option.OpenInterest,
            DateTime.UtcNow
        );

        await _optionRepository.AddAsync(option, ct);
        newCount++;
    }
    else
    {
        // Atualizar preços existente
        existing.UpdateMarketPrices(...);
        updatedCount++;
    }
}
```

---

### Strategy Planning → Risk Management Integration

**Mecanismo:** Domain Events  

**Eventos Publicados por Strategy Planning:**
- `StrategyCreated` → Risk Management calcula risk score
- `StrategyValidated` → Risk Management valida limites do perfil de risco

**Fluxo:**
```
[Strategy Planning]
    → raises StrategyCreated
    → Event Bus
    → [Risk Management: StrategyCreatedHandler]
    → Calculate risk score
    → raises RiskAssessed
    → [Strategy Planning: RiskAssessedHandler]
    → Strategy.AssessRisk(riskScore)
```

---

## 📖 Use Cases

### UC-Strategy-02: Instantiate Template

**Actor:** Trader  
**Trigger:** Usuário instancia template em ativo específico  
**Bounded Context:** Strategy Planning  

**Fluxo:**

```csharp
public class InstantiateTemplateHandler : IRequestHandler<InstantiateTemplateCommand, Result<StrategyId>>
{
    private readonly IStrategyTemplateRepository _templateRepository;
    private readonly IStrategyRepository _strategyRepository;
    private readonly IUserRepository _userRepository;
    private readonly ISubscriptionPlanRepository _planRepository;
    private readonly IMarketDataService _marketData; // ACL to Market Data BC
    private readonly IDomainEventDispatcher _eventDispatcher;

    public async Task<Result<StrategyId>> Handle(InstantiateTemplateCommand command, CancellationToken ct)
    {
        // 1. Buscar template
        var template = await _templateRepository.GetByIdAsync(command.TemplateId, ct);

        // 2. Buscar usuário e plano
        var user = await _userRepository.GetByIdAsync(command.UserId, ct);
        var plan = await _planRepository.GetByIdAsync(user.SubscriptionPlanId!.Value, ct);

        // 3. Validar limite de estratégias (considera override se existir)
        var currentCount = await _strategyRepository.CountActiveByOwnerAsync(command.UserId, ct);
        var effectiveLimit = user.GetEffectiveStrategyLimit(plan);
        if (currentCount >= effectiveLimit)
            throw new DomainException($"Strategy limit exceeded ({effectiveLimit})");

        // 4. Obter preço atual do ativo via Market Data
        var currentPrice = await _marketData.GetCurrentPriceAsync(command.Ticker, ct);

        // 5. Converter legs de template para strategy (relative → absolute)
        var instantiatedLegs = template.Legs.Select(leg => InstantiateLeg(leg, currentPrice)).ToList();

        // 6. Criar estratégia
        var strategy = Strategy.CreateFromTemplate(
            command.UserId,
            command.Name,
            command.Ticker,
            command.TemplateId,
            instantiatedLegs
        );

        // 7. Persistir
        await _strategyRepository.AddAsync(strategy, ct);

        // 8. Dispatch domain events
        foreach (var @event in strategy.DomainEvents)
        {
            await _eventDispatcher.DispatchAsync(@event, ct);
        }

        // 9. Retornar resultado
        return Result<StrategyId>.Success(strategy.Id);
    }

    private StrategyLeg InstantiateLeg(TemplateLeg templateLeg, Money currentPrice)
    {
        if (templateLeg.Type == LegType.Stock)
            return StrategyLeg.CreateStock(templateLeg.Position, templateLeg.Quantity);

        // Convert relative strike to absolute
        var absoluteStrike = CalculateAbsoluteStrike(templateLeg.Strike!, currentPrice);

        // Convert relative expiration to absolute date
        var absoluteExpiration = CalculateAbsoluteExpiration(templateLeg.Expiration!);

        return StrategyLeg.CreateOption(
            templateLeg.Type,
            templateLeg.Position,
            templateLeg.Quantity,
            absoluteStrike,
            absoluteExpiration
        );
    }

    private Money CalculateAbsoluteStrike(RelativeStrike relativeStrike, Money currentPrice)
    {
        if (relativeStrike.Reference == StrikeReference.ATM)
        {
            if (relativeStrike.PercentageOffset == null)
                return currentPrice; // ATM

            // ATM + 5% or ATM - 10%
            var offset = 1 + relativeStrike.PercentageOffset.Value;
            return Money.Brl(currentPrice.Amount * offset);
        }

        return currentPrice;
    }

    private DateTime CalculateAbsoluteExpiration(RelativeExpiration relativeExpiration)
    {
        if (relativeExpiration.Reference == ExpirationReference.MonthsOffset)
        {
            return DateTime.UtcNow.AddMonths(relativeExpiration.MonthOffset!.Value);
        }

        // TODO: Handle named months (Janeiro, Fevereiro, etc)
        return DateTime.UtcNow.AddMonths(1);
    }
}

public record InstantiateTemplateCommand(
    UserId UserId,
    StrategyTemplateId TemplateId,
    string Name,
    Ticker Ticker
) : IRequest<Result<StrategyId>>;
```

**Aggregates Envolvidos:**
- StrategyTemplate (read-only - source)
- User (read-only - validar owner)
- SubscriptionPlan (read-only - validar limite)
- Strategy (modify - criar instância)

**Domain Events Gerados:**
- `StrategyInstantiated`

**Integration:**
- Market Data (via ACL) - obter preço atual

---

### UC-Strategy-03: Create Strategy From Scratch

**Actor:** Trader  
**Trigger:** Usuário cria estratégia sem template  
**Bounded Context:** Strategy Planning  

**Fluxo:**

```csharp
public class CreateStrategyHandler : IRequestHandler<CreateStrategyCommand, Result<StrategyId>>
{
    private readonly IStrategyRepository _strategyRepository;
    private readonly IUserRepository _userRepository;
    private readonly ISubscriptionPlanRepository _planRepository;
    private readonly IDomainEventDispatcher _eventDispatcher;

    public async Task<Result<StrategyId>> Handle(CreateStrategyCommand command, CancellationToken ct)
    {
        // 1. Buscar usuário e plano
        var user = await _userRepository.GetByIdAsync(command.UserId, ct);
        var plan = await _planRepository.GetByIdAsync(user.SubscriptionPlanId!.Value, ct);

        // 2. Validar limite de estratégias
        var currentCount = await _strategyRepository.CountActiveByOwnerAsync(command.UserId, ct);
        if (currentCount >= plan.StrategyLimit)
            throw new DomainException($"Strategy limit exceeded ({plan.StrategyLimit})");

        // 3. Converter legs
        var legs = command.Legs.Select(l => ConvertLeg(l)).ToList();

        // 4. Criar estratégia
        var strategy = Strategy.CreateFromScratch(
            command.UserId,
            command.Name,
            command.Ticker,
            legs
        );

        // 5. Persistir
        await _strategyRepository.AddAsync(strategy, ct);

        // 6. Dispatch domain events
        foreach (var @event in strategy.DomainEvents)
        {
            await _eventDispatcher.DispatchAsync(@event, ct);
        }

        // 7. Retornar resultado
        return Result<StrategyId>.Success(strategy.Id);
    }

    private StrategyLeg ConvertLeg(StrategyLegDto dto)
    {
        if (dto.Type == LegType.Stock)
            return StrategyLeg.CreateStock(dto.Position, dto.Quantity);

        return StrategyLeg.CreateOption(
            dto.Type,
            dto.Position,
            dto.Quantity,
            dto.Strike!,
            dto.Expiration!.Value
        );
    }
}

public record CreateStrategyCommand(
    UserId UserId,
    string Name,
    Ticker Ticker,
    List<StrategyLegDto> Legs
) : IRequest<Result<StrategyId>>;

public record StrategyLegDto(
    LegType Type,
    Position Position,
    int Quantity,
    Money? Strike,
    DateTime? Expiration
);
```

**Aggregates Envolvidos:**
- User (read-only - validar owner)
- SubscriptionPlan (read-only - validar limite)
- Strategy (modify - criar)

**Domain Events Gerados:**
- `StrategyCreated`

---

### UC-Strategy-04: Calculate Margin

**Actor:** System (background job) ou Trader (on-demand)  
**Trigger:** Estratégia criada ou usuário solicita recálculo  
**Bounded Context:** Strategy Planning  

**Fluxo:**

```csharp
public class CalculateMarginHandler : IRequestHandler<CalculateMarginCommand, Result<Money>>
{
    private readonly IStrategyRepository _strategyRepository;
    private readonly IMarginCalculationService _marginService; // Domain Service
    private readonly IDomainEventDispatcher _eventDispatcher;

    public async Task<Result<Money>> Handle(CalculateMarginCommand command, CancellationToken ct)
    {
        // 1. Buscar estratégia
        var strategy = await _strategyRepository.GetByIdAsync(command.StrategyId, ct);

        // 2. Calcular margem (Domain Service)
        var margin = await _marginService.CalculateAsync(strategy, ct);

        // 3. Atualizar estratégia
        strategy.CalculateMargin(margin);

        // 4. Persistir
        await _strategyRepository.UpdateAsync(strategy, ct);

        // 5. Dispatch domain events
        foreach (var @event in strategy.DomainEvents)
        {
            await _eventDispatcher.DispatchAsync(@event, ct);
        }

        // 6. Retornar resultado
        return Result<Money>.Success(margin);
    }
}

public record CalculateMarginCommand(
    StrategyId StrategyId
) : IRequest<Result<Money>>;
```

**Aggregates Envolvidos:**
- Strategy (modify - armazenar margem calculada)

**Domain Events Gerados:**
- `MarginCalculated`

**Integration:**
- Market Data (via domain service) - preços para cálculo

---

### UC-Strategy-05: Validate Risk Limits

**Actor:** System (via domain event handler)  
**Trigger:** StrategyCreated event  
**Bounded Context:** Risk Management (consuming Strategy Planning events)  

**Fluxo:**

```csharp
public class StrategyCreatedEventHandler : INotificationHandler<StrategyCreated>
{
    private readonly IStrategyRepository _strategyRepository;
    private readonly IUserRepository _userRepository;
    private readonly IRiskAssessmentService _riskService;
    private readonly IDomainEventDispatcher _eventDispatcher;

    public async Task Handle(StrategyCreated notification, CancellationToken ct)
    {
        // 1. Buscar estratégia
        var strategy = await _strategyRepository.GetByIdAsync(notification.StrategyId, ct);

        // 2. Buscar usuário e perfil de risco
        var user = await _userRepository.GetByIdAsync(notification.OwnerId, ct);

        // 3. Avaliar risco (Domain Service)
        var riskScore = await _riskService.AssessAsync(strategy, user.RiskProfile!.Value, ct);

        // 4. Atualizar estratégia
        strategy.AssessRisk(riskScore);

        // 5. Persistir
        await _strategyRepository.UpdateAsync(strategy, ct);

        // 6. Dispatch domain events
        foreach (var @event in strategy.DomainEvents)
        {
            await _eventDispatcher.DispatchAsync(@event, ct);
        }
    }
}
```

**Aggregates Envolvidos:**
- Strategy (modify - armazenar risk score)
- User (read-only - obter perfil de risco)

**Domain Events Gerados:**
- `RiskAssessed`

---

## 📊 Complexidade e Estimativas

| Bounded Context | Aggregates | Entities | Value Objects | Repositories | Complexity |
|-----------------|------------|----------|---------------|--------------|------------|
| Strategy Planning | 1 (Strategy apenas) | 3 (Strategy + child entities) | 6 | 1 | Média-Alta |

**Estimativa de Implementação:**
- **Strategy Aggregate: ~2 dias (DBA: 0.5 dia, SE: 1.5 dias)**
  - Day 1: Strategy aggregate + StrategyLeg + PnLSnapshot entities
  - Day 1.5: Use cases (UC-Strategy-02, UC-Strategy-03, UC-Strategy-04, UC-Strategy-05)
  - Day 2: Paper trading methods, P&L tracking, manejo (adjustments) + Testing

**Breakdown:**
- Strategy aggregate core: 4 horas
- StrategyLeg entity: 2 horas
- PnLSnapshot entity: 2 horas
- Repository + migrations: 2 horas
- Use cases (4 use cases): 6 horas
- Testing e refinamento: 4 horas

**Nota:** StrategyTemplate (EPIC-01-B) não está incluído neste documento.  

---

## ✅ Validação

- [x] Strategy aggregate definido com invariantes claros
- [x] Boundaries do aggregate respeitados (Strategy é aggregate root separado)
- [x] Domain Events identificados (12 eventos de Strategy)
- [x] Repository interface definido (IStrategyRepository)
- [x] Use Cases mapeados (4 use cases: Instantiate, Create, Calculate Margin, Validate Risk)
- [x] Validações de negócio no domínio (não na aplicação)
- [x] Nomenclatura consistente (PT → EN conforme padrões)
- [x] Strategy limits validation (baseado em SubscriptionPlan + override)
- [x] Paper trading e Live trading suportados
- [x] P&L tracking com snapshots históricos
- [x] Manejo (adjustments) de estratégias ativas
- [x] Integração com Market Data documentada
- [x] Integração com User Management documentada

---

## 📝 Notas de Implementação para SE

**Tecnologias:**
- Framework: .NET 8
- ORM: EF Core 8
- Event Bus: MediatR (in-process) + RabbitMQ (future)

**Estrutura de Pastas:**
```
02-backend/src/
├── Domain/
│   └── StrategyPlanning/
│       ├── Aggregates/
│       │   └── Strategy.cs
│       ├── Entities/
│       │   ├── StrategyLeg.cs
│       │   └── PnLSnapshot.cs
│       ├── ValueObjects/
│       │   ├── StrategyId.cs
│       │   ├── StrategyLegId.cs
│       │   ├── PnLSnapshotId.cs
│       │   ├── StrategyStatus.cs
│       │   ├── PnLType.cs
│       │   ├── RiskScore.cs
│       │   └── Ticker.cs
│       ├── DomainEvents/
│       │   ├── StrategyInstantiated.cs
│       │   ├── StrategyCreated.cs
│       │   ├── StrategyValidated.cs
│       │   ├── StrategyPaperTradingStarted.cs
│       │   ├── StrategyWentLive.cs
│       │   ├── StrategyPnLUpdated.cs
│       │   ├── PnLSnapshotCaptured.cs
│       │   ├── StrategyLegAdjusted.cs
│       │   ├── StrategyLegAddedToActive.cs
│       │   ├── StrategyLegRemoved.cs
│       │   ├── StrategyClosed.cs
│       │   ├── MarginCalculated.cs
│       │   └── RiskAssessed.cs
│       └── Interfaces/
│           └── IStrategyRepository.cs
├── Application/
│   └── StrategyPlanning/
│       ├── Commands/
│       │   ├── InstantiateTemplateCommand.cs
│       │   ├── CreateStrategyCommand.cs
│       │   ├── CalculateMarginCommand.cs
│       │   ├── StartPaperTradingCommand.cs
│       │   ├── GoLiveCommand.cs
│       │   ├── UpdatePnLCommand.cs
│       │   ├── AdjustLegCommand.cs
│       │   ├── AddLegCommand.cs
│       │   ├── RemoveLegCommand.cs
│       │   └── CloseStrategyCommand.cs
│       ├── Handlers/
│       │   ├── InstantiateTemplateHandler.cs
│       │   ├── CreateStrategyHandler.cs
│       │   ├── CalculateMarginHandler.cs
│       │   ├── StartPaperTradingHandler.cs
│       │   ├── GoLiveHandler.cs
│       │   ├── UpdatePnLHandler.cs
│       │   ├── AdjustLegHandler.cs
│       │   ├── AddLegHandler.cs
│       │   ├── RemoveLegHandler.cs
│       │   ├── CloseStrategyHandler.cs
│       │   └── StrategyCreatedEventHandler.cs
│       └── Services/
│           ├── MarginCalculationService.cs
│           └── RiskAssessmentService.cs
└── Infrastructure/
    └── Persistence/
        ├── Repositories/
        │   └── StrategyRepository.cs
        └── Configurations/
            ├── StrategyConfiguration.cs
            ├── StrategyLegConfiguration.cs
            └── PnLSnapshotConfiguration.cs
```

**Prioridades de Implementação:**
1. **Day 1:** Strategy aggregate + entities (Strategy, StrategyLeg, PnLSnapshot)
2. **Day 1.5:** Repository + migrations + basic use cases
3. **Day 2:** Paper trading, P&L tracking, manejo methods + Testing

**Considerações Importantes:**
- Strategy tem dois factory methods: `CreateFromTemplate` (UC-Strategy-02) e `CreateFromScratch` (UC-Strategy-03)
- P&L snapshots são imutáveis após criação (child entity)
- Apenas estratégias PaperTrading ou Live podem ter P&L atualizado
- Apenas estratégias PaperTrading ou Live podem ser ajustadas (manejo)
- Closing reason é obrigatório ao fechar estratégia
- Paper trading pode ser convertido para Live (mantém histórico de P&L)
- Strategy não pode ter última leg removida (deve fechar estratégia)

---

## 🔗 Referências

- **SDA Context Map:** `00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md`
- **Ubiquitous Language:** `00-doc-ddd/02-strategic-design/SDA-03-Ubiquitous-Language.md`
- **DDD Patterns Reference:** `.agents/docs/05-DDD-Patterns-Reference.md`
- **EPIC-01 Complete Model:** `00-doc-ddd/04-tactical-design/DE-01-EPIC-01-CreateStrategy-Domain-Model.md`
- **EPIC-01-B (StrategyTemplate):** `00-doc-ddd/04-tactical-design/DE-01-EPIC-01-B-Template-Definition-Domain-Model.md`
