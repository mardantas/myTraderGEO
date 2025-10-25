# DE-01-EPIC-01-D-Market-Data-Integration-Domain-Model.md

**Projeto:** myTraderGEO
**Epico:** EPIC-01-D - Market Data Integration (segmento do EPIC-01)
**Data:** 2025-10-25
**Engineer:** DE Agent

---

## 🎯 Contexto do Sub-Epico

**Nome do Sub-Epico:** Market Data Integration

**Bounded Context:** Market Data

**Objetivo:**
Modelar o gerenciamento de contratos de opcoes da B3 e ativos subjacentes, incluindo sincronizacao de dados (batch), streaming de precos em tempo real (WebSocket/SignalR), calculo de Greeks (Black-Scholes para opcoes europeias), tratamento de ajustes de strike (dividendos/proventos) e validacao de regras B3 (Puts europeias, series semanais W1-W5).

**Aggregates Modelados:**
- OptionContract (Aggregate Root)
  - StrikeAdjustment (Child Entity)
- UnderlyingAsset (Aggregate Root)

**Domain Services:**
- IBlackScholesService (calculo de pricing, IV, Greeks para opcoes europeias)
- IWeeklySeriesCalculator (calculo de serie semanal W1-W5)
- IMarketDataStreamService (throttling, cache, validacao de mudancas significativas)

---

## 📋 Indice do Modelo de Dominio

### Market Data BC

#### [Aggregate: OptionContract](#1-optioncontract-aggregate-root)
**Responsabilidade:** Contratos de opcao da B3

**Entities:**
  - StrikeAdjustment

**Value Objects:**
  - OptionContractId, StrikeAdjustmentId, Ticker, OptionSeries
  - OptionType, ExerciseType, OptionStatus, OptionGreeks

**Domain Events:**
  - OptionContractCreated, OptionMarketPricesUpdated, OptionGreeksUpdated
  - OptionStrikeAdjusted, OptionExpired
  - OptionsDataSyncStarted, OptionsDataSyncCompleted, NewOptionContractsDiscovered
  - MarketDataStreamStarted, MarketDataStreamStopped, RealTimePriceReceived
  - UserSubscribedToSymbol, UserUnsubscribedFromSymbol

---

#### [Aggregate: UnderlyingAsset](#2-underlyingasset-aggregate-root)
**Responsabilidade:** Ativos subjacentes (PETR4, VALE3, etc.)

**Entities:**
  - (nenhuma child entity)

**Value Objects:**
  - UnderlyingAssetId, Ticker, AssetType

**Domain Events:**
  - UnderlyingAssetCreated, UnderlyingPriceUpdated
  - UnderlyingAssetSuspended, UnderlyingAssetActivated

---

## 🏗️ Modelo Tatico - Market Data BC

# Market Data

## Aggregates

## 1. OptionContract (Aggregate Root)

**Responsabilidade:** Gerenciar dados de contratos de opcoes da B3 (precos, Greeks, ajustes de strike)

**Invariantes (Business Rules):**
1. Symbol deve ser unico
2. Put options DEVEM ser European style (regra B3)
3. Call options podem ser American ou European
4. CurrentStrike deve ser > 0
5. OriginalStrike nunca muda (imutavel)
6. CurrentStrike pode ser ajustado por dividendos
7. ContractMultiplier deve ser > 0 (padrao: 100 para acoes, 1 para BOVA11)
8. BidPrice <= AskPrice (quando ambos presentes)
9. Expiration deve ser futura (para opcoes Active)
10. Series deve ser definida (W1-W5, onde W3 = mensal padrao na 3a segunda-feira do mes)

## Entities

```csharp
// Aggregate Root
public class OptionContract : Entity<OptionContractId>
{
    // ========================================
    // IDENTITY
    // ========================================
    public OptionContractId Id { get; private set; }
    public string Symbol { get; private set; }  // PETRH245 (codigo B3)

    // ========================================
    // CARACTERISTICAS DA OPCAO
    // ========================================
    public Ticker UnderlyingAsset { get; private set; }  // PETR4
    public OptionType Type { get; private set; }         // Call/Put
    public ExerciseType ExerciseType { get; private set; } // American/European
    public OptionSeries Series { get; private set; }     // W1-W5 (W3 = mensal padrao)

    // Strike
    public Money OriginalStrike { get; private set; }    // Strike na emissao
    public Money CurrentStrike { get; private set; }     // Strike atual (ajustado por dividendos)

    // Vencimento
    public DateTime Expiration { get; private set; }

    // Contrato
    public int ContractMultiplier { get; private set; }  // 100 (acoes), 1 (BOVA)

    // ========================================
    // PRECOS DE MERCADO (Snapshot Atual)
    // ========================================
    public Money? BidPrice { get; private set; }         // Maior compra
    public Money? AskPrice { get; private set; }         // Menor venda
    public Money? LastPrice { get; private set; }        // Ultimo negocio
    public DateTime? LastTradeTime { get; private set; } // Hora do ultimo negocio

    // Volume e Liquidez
    public int? Volume { get; private set; }             // Volume do dia
    public int? OpenInterest { get; private set; }       // Contratos em aberto

    // ========================================
    // VOLATILIDADE E GREEKS
    // ========================================
    public decimal? ImpliedVolatility { get; private set; }
    public OptionGreeks? Greeks { get; private set; }
    public DateTime? GreeksLastUpdated { get; private set; }

    // ========================================
    // STATUS E METADADOS
    // ========================================
    public OptionStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime LastUpdated { get; private set; }

    // ========================================
    // HISTORICO DE AJUSTES (Child Entities)
    // ========================================
    private readonly List<StrikeAdjustment> _strikeAdjustments = new();
    public IReadOnlyList<StrikeAdjustment> StrikeAdjustments => _strikeAdjustments.AsReadOnly();

    // ========================================
    // DOMAIN EVENTS
    // ========================================
    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    // ========================================
    // PRIVATE CONSTRUCTOR (EF Core)
    // ========================================
    private OptionContract() { }

    // ========================================
    // FACTORY METHOD
    // ========================================
    public static OptionContract Create(
        string symbol,
        Ticker underlyingAsset,
        OptionType type,
        ExerciseType exerciseType,
        OptionSeries series,
        Money strike,
        DateTime expiration,
        int contractMultiplier)
    {
        if (string.IsNullOrWhiteSpace(symbol))
            throw new DomainException("Symbol is required");

        if (expiration <= DateTime.UtcNow)
            throw new DomainException("Expiration must be in the future");

        if (contractMultiplier <= 0)
            throw new DomainException("Contract multiplier must be positive");

        // Regra da B3: Puts devem ser europeias
        if (type == OptionType.Put && exerciseType == ExerciseType.American)
            throw new DomainException("B3 rule violation: Put options must be European style");

        var option = new OptionContract
        {
            Id = OptionContractId.New(),
            Symbol = symbol,
            UnderlyingAsset = underlyingAsset,
            Type = type,
            ExerciseType = exerciseType,
            Series = series,
            OriginalStrike = strike,
            CurrentStrike = strike,
            Expiration = expiration,
            ContractMultiplier = contractMultiplier,
            Status = OptionStatus.Active,
            CreatedAt = DateTime.UtcNow,
            LastUpdated = DateTime.UtcNow
        };

        option._domainEvents.Add(new OptionContractCreated(
            option.Id,
            option.Symbol,
            option.UnderlyingAsset,
            option.Type,
            option.Series,
            option.CurrentStrike,
            option.Expiration,
            DateTime.UtcNow
        ));

        return option;
    }

    // ========================================
    // BUSINESS METHODS
    // ========================================

    /// <summary>
    /// Atualiza precos de mercado (bid/ask/last)
    /// </summary>
    public void UpdateMarketPrices(
        Money? bidPrice,
        Money? askPrice,
        Money? lastPrice,
        DateTime? lastTradeTime,
        int? volume,
        int? openInterest,
        DateTime timestamp)
    {
        // Validar spread
        if (bidPrice != null && askPrice != null && bidPrice.Amount > askPrice.Amount)
            throw new DomainException("Bid price cannot be greater than ask price");

        BidPrice = bidPrice;
        AskPrice = askPrice;
        LastPrice = lastPrice;
        LastTradeTime = lastTradeTime;
        Volume = volume;
        OpenInterest = openInterest;
        LastUpdated = timestamp;

        _domainEvents.Add(new OptionMarketPricesUpdated(
            Id,
            Symbol,
            bidPrice,
            askPrice,
            lastPrice,
            timestamp
        ));
    }

    /// <summary>
    /// Atualiza Greeks e IV
    /// </summary>
    public void UpdateGreeks(
        decimal impliedVolatility,
        OptionGreeks greeks,
        DateTime timestamp)
    {
        ImpliedVolatility = impliedVolatility;
        Greeks = greeks;
        GreeksLastUpdated = timestamp;
        LastUpdated = timestamp;

        _domainEvents.Add(new OptionGreeksUpdated(
            Id,
            Symbol,
            impliedVolatility,
            greeks,
            timestamp
        ));
    }

    /// <summary>
    /// Ajusta strike por dividendo
    /// </summary>
    public void AdjustStrikeForDividend(
        Money dividendAmount,
        DateTime exDividendDate,
        string reason,
        DateTime timestamp)
    {
        var oldStrike = CurrentStrike;
        var newStrike = Money.Brl(CurrentStrike.Amount - dividendAmount.Amount);

        if (newStrike.Amount <= 0)
            throw new DomainException("Adjusted strike cannot be negative or zero");

        CurrentStrike = newStrike;
        LastUpdated = timestamp;

        // Registrar ajuste
        var adjustment = StrikeAdjustment.Create(
            oldStrike,
            newStrike,
            dividendAmount,
            exDividendDate,
            reason,
            timestamp
        );

        _strikeAdjustments.Add(adjustment);

        _domainEvents.Add(new OptionStrikeAdjusted(
            Id,
            Symbol,
            oldStrike,
            newStrike,
            dividendAmount,
            exDividendDate,
            timestamp
        ));
    }

    /// <summary>
    /// Marca opcao como expirada
    /// </summary>
    public void Expire()
    {
        if (DateTime.UtcNow < Expiration)
            throw new DomainException("Cannot expire option before expiration date");

        if (Status == OptionStatus.Expired)
            throw new DomainException("Option is already expired");

        Status = OptionStatus.Expired;
        LastUpdated = DateTime.UtcNow;

        _domainEvents.Add(new OptionExpired(
            Id,
            Symbol,
            Expiration,
            DateTime.UtcNow
        ));
    }

    /// <summary>
    /// Calcula spread bid-ask
    /// </summary>
    public Money? GetSpread()
    {
        if (BidPrice == null || AskPrice == null)
            return null;

        return Money.Brl(AskPrice.Amount - BidPrice.Amount);
    }

    /// <summary>
    /// Calcula spread percentual
    /// </summary>
    public decimal? GetSpreadPercentage()
    {
        var spread = GetSpread();
        if (spread == null || LastPrice == null || LastPrice.Amount == 0)
            return null;

        return (spread.Amount / LastPrice.Amount) * 100;
    }

    /// <summary>
    /// Verifica se opcao esta liquida (spread < 5%)
    /// </summary>
    public bool IsLiquid()
    {
        var spreadPct = GetSpreadPercentage();
        return spreadPct.HasValue && spreadPct.Value < 5m;
    }

    /// <summary>
    /// Calcula valor nocional (strike * multiplier)
    /// </summary>
    public Money GetNotionalValue()
    {
        return Money.Brl(CurrentStrike.Amount * ContractMultiplier);
    }
}

// Child Entity
public class StrikeAdjustment : Entity<StrikeAdjustmentId>
{
    public StrikeAdjustmentId Id { get; private set; }
    public Money OldStrike { get; private set; }
    public Money NewStrike { get; private set; }
    public Money AdjustmentAmount { get; private set; }  // Valor do dividendo
    public DateTime EventDate { get; private set; }       // Data ex-dividendo
    public string Reason { get; private set; }            // "Dividend", "Split", etc
    public DateTime AdjustedAt { get; private set; }

    private StrikeAdjustment() { }

    public static StrikeAdjustment Create(
        Money oldStrike,
        Money newStrike,
        Money adjustmentAmount,
        DateTime eventDate,
        string reason,
        DateTime adjustedAt)
    {
        return new StrikeAdjustment
        {
            Id = StrikeAdjustmentId.New(),
            OldStrike = oldStrike,
            NewStrike = newStrike,
            AdjustmentAmount = adjustmentAmount,
            EventDate = eventDate,
            Reason = reason,
            AdjustedAt = adjustedAt
        };
    }
}
```

## Value Objects

```csharp
public record OptionContractId(Guid Value)
{
    public static OptionContractId New() => new(Guid.NewGuid());
}

public record StrikeAdjustmentId(Guid Value)
{
    public static StrikeAdjustmentId New() => new(Guid.NewGuid());
}

public enum OptionType
{
    Call,
    Put
}

public enum ExerciseType
{
    American,   // Pode exercer a qualquer momento
    European    // So pode exercer no vencimento
}

public enum OptionStatus
{
    Active,      // Negociando normalmente
    Suspended,   // Suspenso pela B3
    Expired,     // Vencido
    Exercised    // Exercido (futuro - para tracking)
}

/// <summary>
/// Representa a serie semanal de uma opcao.
/// Nomenclatura unificada: W1-W5 (onde W3 = mensal padrao = 3a segunda-feira)
/// </summary>
public record OptionSeries
{
    public int WeekNumber { get; private init; }         // 1 a 5
    public bool IsMonthlyStandard { get; private init; } // true quando W3 = mensal

    private OptionSeries(int weekNumber, bool isMonthlyStandard)
    {
        if (weekNumber < 1 || weekNumber > 5)
            throw new ArgumentException("Week number must be between 1 and 5");

        WeekNumber = weekNumber;
        IsMonthlyStandard = isMonthlyStandard;
    }

    // Factory Methods
    public static OptionSeries Week1() => new(1, false);
    public static OptionSeries Week2() => new(2, false);
    public static OptionSeries MonthlyStandard() => new(3, true);  // W3 = 3a segunda-feira
    public static OptionSeries Week4() => new(4, false);
    public static OptionSeries Week5() => new(5, false);

    // Display Helpers
    public string GetUnifiedName() => $"W{WeekNumber}";

    public string GetTraditionalName() => IsMonthlyStandard
        ? "Mensal"
        : $"Semanal W{WeekNumber}";

    public override string ToString() => GetUnifiedName();
}

public record OptionGreeks(
    decimal Delta,      // 0.0 to 1.0 (call) or -1.0 to 0.0 (put)
    decimal Gamma,      // Rate of change of delta
    decimal Vega,       // Sensitivity to IV
    decimal Theta,      // Time decay per day
    decimal Rho         // Sensitivity to interest rate
)
{
    public OptionGreeks
    {
        if (Delta < -1 || Delta > 1)
            throw new ArgumentException("Delta must be between -1 and 1");
    }
}
```

## Domain Events

```csharp
public record OptionContractCreated(
    OptionContractId OptionId,
    string Symbol,
    Ticker UnderlyingAsset,
    OptionType Type,
    OptionSeries Series,
    Money Strike,
    DateTime Expiration,
    DateTime OccurredAt
) : IDomainEvent;

public record OptionMarketPricesUpdated(
    OptionContractId OptionId,
    string Symbol,
    Money? BidPrice,
    Money? AskPrice,
    Money? LastPrice,
    DateTime OccurredAt
) : IDomainEvent;

public record OptionGreeksUpdated(
    OptionContractId OptionId,
    string Symbol,
    decimal ImpliedVolatility,
    OptionGreeks Greeks,
    DateTime OccurredAt
) : IDomainEvent;

public record OptionStrikeAdjusted(
    OptionContractId OptionId,
    string Symbol,
    Money OldStrike,
    Money NewStrike,
    Money DividendAmount,
    DateTime ExDividendDate,
    DateTime OccurredAt
) : IDomainEvent;

public record OptionExpired(
    OptionContractId OptionId,
    string Symbol,
    DateTime Expiration,
    DateTime OccurredAt
) : IDomainEvent;

// Sync Events (Batch)
public record OptionsDataSyncStarted(
    DateTime StartedAt,
    string Source  // "B3_API", "Manual", etc.
) : IDomainEvent;

public record OptionsDataSyncCompleted(
    DateTime CompletedAt,
    string Source,
    int NewOptionsCreated,
    int OptionsUpdated,
    int OptionsExpired,
    TimeSpan Duration
) : IDomainEvent;

public record NewOptionContractsDiscovered(
    int Count,
    Ticker UnderlyingAsset,
    DateTime OccurredAt
) : IDomainEvent;

// Real-Time Streaming Events
public record MarketDataStreamStarted(
    DateTime StartedAt,
    int SymbolCount,  // Quantos simbolos estao sendo monitorados
    string FeedSource  // "B3_WEBSOCKET", "PROVIDER_API", etc.
) : IDomainEvent;

public record MarketDataStreamStopped(
    DateTime StoppedAt,
    string Reason,  // "MARKET_CLOSED", "ERROR", "MAINTENANCE", etc.
    TimeSpan UpTime
) : IDomainEvent;

public record RealTimePriceReceived(
    string Symbol,  // PETRH245 ou PETR4
    Money NewPrice,
    Money? OldPrice,
    decimal ChangePercentage,
    DateTime ReceivedAt,
    int SubscriberCount  // Quantos clientes estao recebendo este update
) : IDomainEvent;

public record UserSubscribedToSymbol(
    UserId UserId,
    string Symbol,
    DateTime SubscribedAt
) : IDomainEvent;

public record UserUnsubscribedFromSymbol(
    UserId UserId,
    string Symbol,
    DateTime UnsubscribedAt
) : IDomainEvent;
```

---

## 2. UnderlyingAsset (Aggregate Root)

**Responsabilidade:** Gerenciar dados do ativo subjacente (acao-objeto da opcao)

**Invariantes (Business Rules):**
1. Symbol (Ticker) deve ser unico
2. Name nao pode ser vazio
3. CurrentPrice deve ser > 0
4. LastUpdated deve ser recente (< 1 dia para Active)

## Entities

```csharp
// Aggregate Root
public class UnderlyingAsset : Entity<UnderlyingAssetId>
{
    public UnderlyingAssetId Id { get; private set; }
    public Ticker Symbol { get; private set; }  // PETR4
    public string Name { get; private set; }     // Petrobras PN
    public Money CurrentPrice { get; private set; }
    public DateTime LastUpdated { get; private set; }
    public AssetStatus Status { get; private set; }

    // Domain Events
    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    private UnderlyingAsset() { }

    // Factory Method
    public static UnderlyingAsset Create(
        Ticker symbol,
        string name,
        Money initialPrice)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new DomainException("Asset name is required");

        if (initialPrice.Amount <= 0)
            throw new DomainException("Initial price must be positive");

        var asset = new UnderlyingAsset
        {
            Id = UnderlyingAssetId.New(),
            Symbol = symbol,
            Name = name,
            CurrentPrice = initialPrice,
            LastUpdated = DateTime.UtcNow,
            Status = AssetStatus.Active
        };

        asset._domainEvents.Add(new UnderlyingAssetCreated(
            asset.Id,
            asset.Symbol,
            asset.Name,
            DateTime.UtcNow
        ));

        return asset;
    }

    // Business Methods
    public void UpdatePrice(Money newPrice, DateTime timestamp)
    {
        if (newPrice.Amount <= 0)
            throw new DomainException("Price must be positive");

        CurrentPrice = newPrice;
        LastUpdated = timestamp;

        _domainEvents.Add(new UnderlyingPriceUpdated(
            Id,
            Symbol,
            newPrice,
            timestamp
        ));
    }

    public void Suspend()
    {
        Status = AssetStatus.Suspended;

        _domainEvents.Add(new UnderlyingAssetSuspended(
            Id,
            Symbol,
            DateTime.UtcNow
        ));
    }

    public void Activate()
    {
        Status = AssetStatus.Active;

        _domainEvents.Add(new UnderlyingAssetActivated(
            Id,
            Symbol,
            DateTime.UtcNow
        ));
    }
}
```

## Value Objects

```csharp
public record UnderlyingAssetId(Guid Value)
{
    public static UnderlyingAssetId New() => new(Guid.NewGuid());
}

public enum AssetStatus
{
    Active,
    Suspended,
    Delisted
}
```

## Domain Events

```csharp
public record UnderlyingAssetCreated(
    UnderlyingAssetId AssetId,
    Ticker Symbol,
    string Name,
    DateTime OccurredAt
) : IDomainEvent;

public record UnderlyingPriceUpdated(
    UnderlyingAssetId AssetId,
    Ticker Symbol,
    Money NewPrice,
    DateTime OccurredAt
) : IDomainEvent;

public record UnderlyingAssetSuspended(
    UnderlyingAssetId AssetId,
    Ticker Symbol,
    DateTime OccurredAt
) : IDomainEvent;

public record UnderlyingAssetActivated(
    UnderlyingAssetId AssetId,
    Ticker Symbol,
    DateTime OccurredAt
) : IDomainEvent;
```

---

## Domain Services

```csharp
/// <summary>
/// Black-Scholes pricing model para opcoes europeias
/// NOTA: Para opcoes americanas (algumas calls), usar modelo binomial (EPIC-02)
/// </summary>
public interface IBlackScholesService
{
    /// <summary>
    /// Calcula preco teorico de opcao europeia
    /// </summary>
    Money CalculateTheoreticalPrice(
        Money spot,
        Money strike,
        decimal timeToExpiration, // em anos
        decimal riskFreeRate,
        decimal impliedVolatility,
        OptionType type);

    /// <summary>
    /// Calcula IV por inversao numerica (Newton-Raphson)
    /// </summary>
    decimal CalculateImpliedVolatility(
        Money marketPrice,
        Money spot,
        Money strike,
        decimal timeToExpiration,
        decimal riskFreeRate,
        OptionType type,
        decimal initialGuess = 0.3m,
        decimal tolerance = 0.0001m);

    /// <summary>
    /// Calcula Greeks para opcao europeia
    /// </summary>
    OptionGreeks CalculateGreeks(
        Money spot,
        Money strike,
        decimal timeToExpiration,
        decimal riskFreeRate,
        decimal impliedVolatility,
        OptionType type);

    /// <summary>
    /// Wrapper inteligente que escolhe o modelo certo
    /// </summary>
    Money CalculatePrice(
        OptionContract option,
        Money spotPrice,
        decimal riskFreeRate);
}

/// <summary>
/// Domain Service para calcular a serie semanal (W1-W5) de uma opcao baseado na data de vencimento
/// </summary>
public interface IWeeklySeriesCalculator
{
    /// <summary>
    /// Calcula a serie semanal baseado na data de vencimento
    /// W1 = 1a segunda-feira do mes
    /// W2 = 2a segunda-feira do mes
    /// W3 = 3a segunda-feira do mes (MENSAL PADRAO)
    /// W4 = 4a segunda-feira do mes
    /// W5 = 5a segunda-feira do mes (quando existe)
    /// </summary>
    OptionSeries CalculateSeries(DateTime expirationDate);

    /// <summary>
    /// Verifica se uma data e a 3a segunda-feira do mes (mensal padrao da B3)
    /// </summary>
    bool IsMonthlyStandard(DateTime date);

    /// <summary>
    /// Calcula qual a N-esima segunda-feira do mes (1-5)
    /// </summary>
    int GetMondayWeekOfMonth(DateTime date);
}

/// <summary>
/// Domain Service para gerenciar throttling e cache de updates de precos em tempo real
/// Evita sobrecarga de updates e garante performance
/// </summary>
public interface IMarketDataStreamService
{
    /// <summary>
    /// Verifica se deve processar um update de preco (throttling)
    /// Regra: maximo 1 update por simbolo a cada N segundos
    /// </summary>
    bool ShouldProcessPriceUpdate(string symbol, DateTime updateTime);

    /// <summary>
    /// Registra que um update foi processado (para throttling)
    /// </summary>
    void RecordPriceUpdate(string symbol, DateTime updateTime);

    /// <summary>
    /// Obtem ultimo preco conhecido do cache (para evitar updates desnecessarios)
    /// </summary>
    Money? GetCachedPrice(string symbol);

    /// <summary>
    /// Atualiza cache de preco
    /// </summary>
    void UpdateCachedPrice(string symbol, Money price);

    /// <summary>
    /// Verifica se mudanca de preco e significativa (> threshold)
    /// Evita broadcast de mudancas insignificantes (< 0.1%)
    /// </summary>
    bool IsPriceChangeSignificant(Money oldPrice, Money newPrice, decimal thresholdPercentage = 0.1m);
}
```

---

## Repository Interfaces

```csharp
public interface IOptionContractRepository
{
    Task<OptionContract> GetByIdAsync(OptionContractId id, CancellationToken ct);
    Task<OptionContract?> GetBySymbolAsync(string symbol, CancellationToken ct);

    // Lista de opcoes disponiveis (CRITICAL para UI)
    Task<IEnumerable<OptionContract>> GetAvailableOptionsAsync(
        Ticker underlyingAsset,
        OptionType? typeFilter = null,           // Call/Put
        ExerciseType? exerciseTypeFilter = null, // American/European
        int[]? weekNumbers = null,               // W1-W5 filter (null = todas)
        bool? monthlyStandardOnly = null,        // true = apenas W3 mensal, false = apenas semanais nao-mensais, null = todas
        DateTime? expirationFrom = null,
        DateTime? expirationTo = null,
        Money? strikeFrom = null,
        Money? strikeTo = null,
        bool activeOnly = true,
        CancellationToken ct = default);

    // Buscar por vencimento
    Task<IEnumerable<OptionContract>> GetByExpirationAsync(
        DateTime expiration,
        CancellationToken ct);

    // Buscar opcoes proximas do vencimento
    Task<IEnumerable<OptionContract>> GetExpiringOptionsAsync(
        int daysUntilExpiration,
        CancellationToken ct);

    // Buscar opcoes liquidas
    Task<IEnumerable<OptionContract>> GetLiquidOptionsAsync(
        Ticker underlyingAsset,
        decimal maxSpreadPercentage = 5m,
        CancellationToken ct = default);

    // Buscar opcoes que deveriam estar expiradas (para sync job)
    Task<IEnumerable<OptionContract>> GetExpiredActiveOptionsAsync(
        DateTime referenceDate,
        CancellationToken ct);

    Task AddAsync(OptionContract option, CancellationToken ct);
    Task UpdateAsync(OptionContract option, CancellationToken ct);

    // Bulk upsert para performance em sync jobs (cria se nao existe, atualiza se existe)
    Task BulkUpsertAsync(IEnumerable<OptionContract> options, CancellationToken ct);

    Task<int> CountActiveAsync(Ticker underlyingAsset, CancellationToken ct);
}

public interface IUnderlyingAssetRepository
{
    Task<UnderlyingAsset> GetByIdAsync(UnderlyingAssetId id, CancellationToken ct);
    Task<UnderlyingAsset?> GetBySymbolAsync(Ticker symbol, CancellationToken ct);
    Task<IEnumerable<UnderlyingAsset>> GetActiveAsync(CancellationToken ct);
    Task AddAsync(UnderlyingAsset asset, CancellationToken ct);
    Task UpdateAsync(UnderlyingAsset asset, CancellationToken ct);
}
```

**Queries Esperadas pelo DBA:**
1. `OptionContract.GetBySymbolAsync` → Unique Index em Symbol
2. `OptionContract.GetAvailableOptionsAsync` → Composite Index em (UnderlyingAsset, Status, Expiration, Series.WeekNumber)
3. `OptionContract.GetExpiringOptionsAsync` → Index em (Status, Expiration)
4. `OptionContract.GetLiquidOptionsAsync` → Index em (UnderlyingAsset, Status) + calculo de spread
5. `UnderlyingAsset.GetBySymbolAsync` → Unique Index em Symbol

**Exemplos de Filtros de Opcoes Semanais:**
```csharp
// Buscar apenas opcoes mensais (W3)
var monthlyOptions = await repo.GetAvailableOptionsAsync(
    ticker, monthlyStandardOnly: true);

// Buscar apenas semanais nao-mensais (W1, W2, W4, W5)
var weeklyOptions = await repo.GetAvailableOptionsAsync(
    ticker, monthlyStandardOnly: false);

// Buscar W1 e W2 especificamente
var earlyWeekOptions = await repo.GetAvailableOptionsAsync(
    ticker, weekNumbers: new[] { 1, 2 });

// Buscar todas (mensal + semanais)
var allOptions = await repo.GetAvailableOptionsAsync(ticker);
```

---

## 🔄 Integracao Entre Bounded Contexts

### Strategy Planning → Market Data Integration

**Mecanismo:** Queries diretas (read-only) via repositories

**Fluxo de Instanciacao de Template:**
```
[Strategy Planning]
    → InstantiateTemplate(templateId, ticker)
    → Query Market Data: GetUnderlyingAsset(ticker)
    → Query Market Data: GetAvailableOptions(ticker, filters)

    Para cada leg do template:
        1. Se leg e Stock:
           → Usar preco do UnderlyingAsset

        2. Se leg e Option:
           → Calcular strike absoluto:
              • ATM → currentPrice
              • ATM+5% → currentPrice * 1.05
           → Calcular vencimento absoluto
           → FindClosestOption(availableOptions, targetStrike, targetExpiration)
           → Validar:
              • Opcao existe?
              • IV disponivel?
              • Liquidez adequada? (spread < 5%)
           → Usar strike REAL e vencimento REAL da opcao encontrada

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

    // Opcoes Disponiveis
    Task<IEnumerable<OptionContractDto>> GetAvailableOptionsAsync(
        Ticker underlyingAsset,
        OptionType? typeFilter = null,
        DateTime? expirationFrom = null,
        DateTime? expirationTo = null,
        CancellationToken ct = default);

    // Opcao Especifica por Symbol
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
- `OptionStrikeAdjusted` → Strategy Planning pode alertar usuarios com estrategias afetadas
- `OptionExpired` → Strategy Planning pode marcar estrategias como fechadas
- `OptionsDataSyncCompleted` → Pode notificar administradores sobre sync
- `NewOptionContractsDiscovered` → Pode notificar traders sobre novas opcoes

---

### Market Data → B3 API Integration (External Service)

**Mecanismo:** Anti-Corruption Layer (ACL) via IB3ApiClient

**Interface Externa (Infrastructure Layer):**

```csharp
/// <summary>
/// Cliente HTTP para integracao com APIs de dados da B3 / provedores de market data
/// Implementado na camada de Infrastructure com retry policies (Polly)
/// </summary>
public interface IB3ApiClient
{
    /// <summary>
    /// Busca todas as opcoes listadas de um ativo subjacente
    /// </summary>
    Task<IEnumerable<B3OptionData>> GetOptionsForUnderlyingAsync(
        string ticker,
        CancellationToken ct);

    /// <summary>
    /// Busca todas as opcoes listadas (para sync completo)
    /// </summary>
    Task<IEnumerable<B3OptionData>> GetAllListedOptionsAsync(
        CancellationToken ct);

    /// <summary>
    /// Busca dados atualizados de uma opcao especifica
    /// </summary>
    Task<B3OptionData?> GetOptionBySymbolAsync(
        string symbol,
        CancellationToken ct);

    /// <summary>
    /// Busca preco atual de um ativo subjacente
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
/// Cliente WebSocket para feed de precos em tempo real da B3
/// Implementado na camada de Infrastructure com reconexao automatica
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
    /// Subscreve para receber updates de preco de simbolos especificos
    /// </summary>
    Task SubscribeToSymbolsAsync(IEnumerable<string> symbols, CancellationToken ct);

    /// <summary>
    /// Remove subscricao de simbolos
    /// </summary>
    Task UnsubscribeFromSymbolsAsync(IEnumerable<string> symbols, CancellationToken ct);

    /// <summary>
    /// Evento disparado quando novo preco e recebido do feed
    /// </summary>
    event EventHandler<MarketDataUpdate> OnPriceUpdate;

    /// <summary>
    /// Evento disparado quando conexao e perdida
    /// </summary>
    event EventHandler<string> OnDisconnected;

    /// <summary>
    /// Evento disparado quando reconectado
    /// </summary>
    event EventHandler OnReconnected;

    /// <summary>
    /// Status da conexao
    /// </summary>
    bool IsConnected { get; }

    /// <summary>
    /// Simbolos atualmente subscritos
    /// </summary>
    IReadOnlySet<string> SubscribedSymbols { get; }
}

/// <summary>
/// Update de preco recebido do feed em tempo real
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
    // Calcular serie semanal usando Domain Service
    var series = _weeklySeriesCalculator.CalculateSeries(b3Option.ExpirationDate);

    // Verificar se ja existe
    var existing = await _optionRepository.GetBySymbolAsync(b3Option.Symbol, ct);

    if (existing == null)
    {
        // Criar novo OptionContract
        var option = OptionContract.Create(
            b3Option.Symbol,
            Ticker.From(b3Option.UnderlyingTicker),
            MapOptionType(b3Option.OptionType),
            MapExerciseType(b3Option.ExerciseType),
            series,  // <-- Serie calculada aqui
            Money.Brl(b3Option.StrikePrice),
            b3Option.ExpirationDate,
            b3Option.ContractSize
        );

        // Atualizar precos
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
        // Atualizar precos existente
        existing.UpdateMarketPrices(...);
        updatedCount++;
    }
}
```

---

## 📋 Use Cases (Application Layer)

### UC-MarketData-01: Sync Options from B3

**Actor:** System (Background Job / Scheduled Task)
**Trigger:** Scheduled task (daily at 19h30 after market closes) ou trigger manual por admin
**Bounded Context:** Market Data

**Objetivo:** Sincronizar lista de opcoes da B3, identificando novas series (incluindo semanais W1-W5), atualizando precos/Greeks de existentes, e marcando expiradas automaticamente.

**Fluxo:**

```csharp
public class SyncOptionsHandler : IRequestHandler<SyncOptionsCommand, Result<SyncStatistics>>
{
    private readonly IB3ApiClient _b3ApiClient;
    private readonly IOptionContractRepository _optionRepository;
    private readonly IUnderlyingAssetRepository _assetRepository;
    private readonly IWeeklySeriesCalculator _weeklySeriesCalculator;
    private readonly IDomainEventDispatcher _eventDispatcher;
    private readonly ILogger<SyncOptionsHandler> _logger;

    public async Task<Result<SyncStatistics>> Handle(SyncOptionsCommand command, CancellationToken ct)
    {
        var startTime = DateTime.UtcNow;
        var stats = new SyncStatistics();

        _logger.LogInformation("Starting options sync from {Source}", command.Source);

        // 1. Publicar evento de inicio
        await _eventDispatcher.DispatchAsync(
            new OptionsDataSyncStarted(startTime, command.Source), ct);

        try
        {
            // 2. Buscar todas as opcoes da B3 API
            var b3Options = await _b3ApiClient.GetAllListedOptionsAsync(ct);
            _logger.LogInformation("Fetched {Count} options from B3 API", b3Options.Count());

            // 3. Processar cada opcao da B3
            foreach (var b3Option in b3Options)
            {
                try
                {
                    // Calcular serie semanal (W1-W5) usando Domain Service
                    var series = _weeklySeriesCalculator.CalculateSeries(b3Option.ExpirationDate);

                    // Verificar se opcao ja existe no banco
                    var existing = await _optionRepository.GetBySymbolAsync(b3Option.Symbol, ct);

                    if (existing == null)
                    {
                        // CRIAR NOVA OPCAO
                        var option = OptionContract.Create(
                            b3Option.Symbol,
                            Ticker.From(b3Option.UnderlyingTicker),
                            MapOptionType(b3Option.OptionType),
                            MapExerciseType(b3Option.ExerciseType),
                            series,  // <-- Serie W1-W5 calculada
                            Money.Brl(b3Option.StrikePrice),
                            b3Option.ExpirationDate,
                            b3Option.ContractSize
                        );

                        // Atualizar precos de mercado
                        if (b3Option.BidPrice.HasValue || b3Option.AskPrice.HasValue)
                        {
                            option.UpdateMarketPrices(
                                b3Option.BidPrice.HasValue ? Money.Brl(b3Option.BidPrice.Value) : null,
                                b3Option.AskPrice.HasValue ? Money.Brl(b3Option.AskPrice.Value) : null,
                                b3Option.LastPrice.HasValue ? Money.Brl(b3Option.LastPrice.Value) : null,
                                b3Option.LastTradeTime,
                                b3Option.Volume,
                                b3Option.OpenInterest,
                                DateTime.UtcNow
                            );
                        }

                        // Atualizar Greeks se disponiveis
                        if (b3Option.Greeks != null && b3Option.ImpliedVolatility.HasValue)
                        {
                            var greeks = new OptionGreeks(
                                b3Option.Greeks.Delta,
                                b3Option.Greeks.Gamma,
                                b3Option.Greeks.Vega,
                                b3Option.Greeks.Theta,
                                b3Option.Greeks.Rho
                            );
                            option.UpdateGreeks(b3Option.ImpliedVolatility.Value, greeks, DateTime.UtcNow);
                        }

                        await _optionRepository.AddAsync(option, ct);
                        stats.NewOptionsCreated++;

                        _logger.LogDebug("Created new option: {Symbol} ({Series})",
                            b3Option.Symbol, series.GetUnifiedName());
                    }
                    else
                    {
                        // ATUALIZAR OPCAO EXISTENTE
                        if (b3Option.BidPrice.HasValue || b3Option.AskPrice.HasValue)
                        {
                            existing.UpdateMarketPrices(
                                b3Option.BidPrice.HasValue ? Money.Brl(b3Option.BidPrice.Value) : null,
                                b3Option.AskPrice.HasValue ? Money.Brl(b3Option.AskPrice.Value) : null,
                                b3Option.LastPrice.HasValue ? Money.Brl(b3Option.LastPrice.Value) : null,
                                b3Option.LastTradeTime,
                                b3Option.Volume,
                                b3Option.OpenInterest,
                                DateTime.UtcNow
                            );
                        }

                        if (b3Option.Greeks != null && b3Option.ImpliedVolatility.HasValue)
                        {
                            var greeks = new OptionGreeks(
                                b3Option.Greeks.Delta,
                                b3Option.Greeks.Gamma,
                                b3Option.Greeks.Vega,
                                b3Option.Greeks.Theta,
                                b3Option.Greeks.Rho
                            );
                            existing.UpdateGreeks(b3Option.ImpliedVolatility.Value, greeks, DateTime.UtcNow);
                        }

                        await _optionRepository.UpdateAsync(existing, ct);
                        stats.OptionsUpdated++;
                    }

                    // Dispatch events para novas opcoes criadas
                    foreach (var domainEvent in (existing ?? option).DomainEvents)
                    {
                        await _eventDispatcher.DispatchAsync(domainEvent, ct);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing option {Symbol}", b3Option.Symbol);
                    // Continuar processando outras opcoes
                }
            }

            // 4. Marcar opcoes expiradas
            var expiredOptions = await _optionRepository.GetExpiredActiveOptionsAsync(
                DateTime.UtcNow, ct);

            foreach (var expired in expiredOptions)
            {
                expired.Expire();
                await _optionRepository.UpdateAsync(expired, ct);
                stats.OptionsExpired++;

                foreach (var domainEvent in expired.DomainEvents)
                {
                    await _eventDispatcher.DispatchAsync(domainEvent, ct);
                }
            }

            // 5. Publicar evento de conclusao
            var duration = DateTime.UtcNow - startTime;
            await _eventDispatcher.DispatchAsync(
                new OptionsDataSyncCompleted(
                    DateTime.UtcNow,
                    command.Source,
                    stats.NewOptionsCreated,
                    stats.OptionsUpdated,
                    stats.OptionsExpired,
                    duration
                ), ct);

            _logger.LogInformation(
                "Options sync completed: {New} new, {Updated} updated, {Expired} expired in {Duration}",
                stats.NewOptionsCreated, stats.OptionsUpdated, stats.OptionsExpired, duration);

            return Result<SyncStatistics>.Success(stats);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Options sync failed");
            return Result<SyncStatistics>.Failure($"Sync failed: {ex.Message}");
        }
    }

    private OptionType MapOptionType(string b3Type)
        => b3Type.ToUpper() == "CALL" ? OptionType.Call : OptionType.Put;

    private ExerciseType MapExerciseType(string b3Type)
        => b3Type.ToUpper() == "AMERICAN" ? ExerciseType.American : ExerciseType.European;
}

public record SyncOptionsCommand(
    string Source = "B3_API"  // "B3_API", "MANUAL", etc.
) : IRequest<Result<SyncStatistics>>;

public record SyncStatistics(
    int NewOptionsCreated = 0,
    int OptionsUpdated = 0,
    int OptionsExpired = 0
);
```

**Aggregates Envolvidos:**
- OptionContract (create/modify - novas opcoes, atualizar precos/Greeks, expirar)
- UnderlyingAsset (read-only - validar ticker)

**Domain Events Gerados:**
- `OptionsDataSyncStarted` - inicio do processo
- `OptionContractCreated` - para cada nova opcao descoberta
- `OptionMarketPricesUpdated` - para cada opcao atualizada
- `OptionGreeksUpdated` - quando Greeks atualizados
- `OptionExpired` - para cada opcao expirada automaticamente
- `OptionsDataSyncCompleted` - conclusao com estatisticas

**Domain Services Utilizados:**
- `IWeeklySeriesCalculator` - calcular W1-W5 baseado na data de vencimento

**External Services:**
- `IB3ApiClient` - buscar dados da B3 API (Infrastructure Layer)

**Scheduled Job Configuration:**
```csharp
// Infrastructure/Jobs/OptionsSyncJob.cs
public class OptionsSyncJob : IHostedService
{
    private readonly IMediator _mediator;
    private readonly ILogger<OptionsSyncJob> _logger;
    private Timer? _timer;

    public Task StartAsync(CancellationToken ct)
    {
        _logger.LogInformation("Options Sync Job started");

        // Executar diariamente as 19h30 (30min apos fechamento do mercado as 19h)
        _timer = new Timer(DoWork, null, TimeSpan.Zero, TimeSpan.FromHours(24));

        return Task.CompletedTask;
    }

    private async void DoWork(object? state)
    {
        try
        {
            _logger.LogInformation("Triggering scheduled options sync");
            var result = await _mediator.Send(new SyncOptionsCommand("SCHEDULED_DAILY"));

            if (result.IsSuccess)
            {
                _logger.LogInformation("Scheduled sync completed successfully");
            }
            else
            {
                _logger.LogError("Scheduled sync failed: {Error}", result.Error);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Scheduled sync threw exception");
        }
    }

    public Task StopAsync(CancellationToken ct)
    {
        _logger.LogInformation("Options Sync Job stopping");
        _timer?.Change(Timeout.Infinite, 0);
        _timer?.Dispose();
        return Task.CompletedTask;
    }
}
```

**Retry Policy (Polly):**
```csharp
// Infrastructure/ExternalServices/B3Api/B3ApiClient.cs
public class B3ApiClient : IB3ApiClient
{
    private readonly HttpClient _httpClient;
    private readonly IAsyncPolicy<HttpResponseMessage> _retryPolicy;

    public B3ApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;

        // Retry 3x com backoff exponencial
        _retryPolicy = Policy
            .HandleResult<HttpResponseMessage>(r => !r.IsSuccessStatusCode)
            .Or<HttpRequestException>()
            .WaitAndRetryAsync(3, retryAttempt =>
                TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)));
    }

    public async Task<IEnumerable<B3OptionData>> GetAllListedOptionsAsync(CancellationToken ct)
    {
        var response = await _retryPolicy.ExecuteAsync(async () =>
            await _httpClient.GetAsync("/api/options/all", ct));

        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync(ct);
        return JsonSerializer.Deserialize<List<B3OptionData>>(content) ?? new List<B3OptionData>();
    }

    // Outros metodos...
}
```

---

### UC-MarketData-02: Stream Real-Time Market Data

**Actor:** System (Background Service) + Trader (via SignalR client)
**Trigger:** Trader conecta ao SignalR Hub e subscreve simbolos de interesse
**Bounded Context:** Market Data

**Objetivo:** Fornecer precos em tempo real de opcoes e ativos subjacentes para traders com plano Pleno/Consultor, usando WebSocket/SignalR para baixa latencia.

**Pre-requisitos:**
- User deve ter `RealtimeData: true` no plano (Pleno ou Consultor)
- Market Data Feed Service deve estar conectado a B3
- Horario de mercado (9h-18h em dias uteis)

**Fluxo:**

```csharp
// ============================================
// SIGNALR HUB (Frontend conecta aqui)
// ============================================

/// <summary>
/// SignalR Hub para distribuicao de precos em tempo real
/// Clientes se conectam via WebSocket e subscrevem simbolos
/// </summary>
public class MarketDataHub : Hub
{
    private readonly IUserRepository _userRepository;
    private readonly IMarketDataStreamService _streamService;
    private readonly IDomainEventDispatcher _eventDispatcher;
    private readonly ILogger<MarketDataHub> _logger;

    // Grupos SignalR por simbolo (ex: grupo "PETRH245" contem todos os traders subscrevendo esta opcao)
    private const string SymbolGroupPrefix = "symbol_";

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst("sub")?.Value;
        _logger.LogInformation("User {UserId} connected to MarketDataHub", userId);

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.User?.FindFirst("sub")?.Value;
        _logger.LogInformation("User {UserId} disconnected from MarketDataHub", userId);

        // Cleanup: remover de todos os grupos
        // SignalR faz isso automaticamente

        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Cliente subscreve para receber updates de um simbolo
    /// </summary>
    public async Task<SubscribeResult> SubscribeToSymbol(string symbol)
    {
        var userId = Context.User?.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(userId))
            return SubscribeResult.Unauthorized("User not authenticated");

        try
        {
            // 1. Validar plano do usuario
            var user = await _userRepository.GetByIdAsync(UserId.From(userId), CancellationToken.None);
            if (user == null)
                return SubscribeResult.Unauthorized("User not found");

            var hasRealtimeAccess = user.HasRealtimeDataAccess(); // verifica SubscriptionPlan.Features.RealtimeData
            if (!hasRealtimeAccess)
                return SubscribeResult.Forbidden("Your plan does not include real-time data. Upgrade to Pleno or Consultor.");

            // 2. Adicionar ao grupo SignalR do simbolo
            await Groups.AddToGroupAsync(Context.ConnectionId, GetSymbolGroup(symbol));

            // 3. Publicar evento de domain
            await _eventDispatcher.DispatchAsync(
                new UserSubscribedToSymbol(user.Id, symbol, DateTime.UtcNow),
                CancellationToken.None);

            // 4. Enviar ultimo preco conhecido (cache) imediatamente
            var cachedPrice = _streamService.GetCachedPrice(symbol);
            if (cachedPrice != null)
            {
                await Clients.Caller.SendAsync("PriceUpdate", new PriceUpdateDto(
                    symbol,
                    cachedPrice.Amount,
                    0, // changePercentage desconhecido no cache
                    DateTime.UtcNow
                ));
            }

            _logger.LogInformation("User {UserId} subscribed to {Symbol}", userId, symbol);

            return SubscribeResult.Success($"Subscribed to {symbol}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error subscribing user {UserId} to {Symbol}", userId, symbol);
            return SubscribeResult.Error($"Failed to subscribe: {ex.Message}");
        }
    }

    /// <summary>
    /// Cliente remove subscricao de um simbolo
    /// </summary>
    public async Task<UnsubscribeResult> UnsubscribeFromSymbol(string symbol)
    {
        var userId = Context.User?.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(userId))
            return UnsubscribeResult.Unauthorized("User not authenticated");

        try
        {
            // Remover do grupo SignalR
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, GetSymbolGroup(symbol));

            // Publicar evento
            var user = await _userRepository.GetByIdAsync(UserId.From(userId), CancellationToken.None);
            if (user != null)
            {
                await _eventDispatcher.DispatchAsync(
                    new UserUnsubscribedFromSymbol(user.Id, symbol, DateTime.UtcNow),
                    CancellationToken.None);
            }

            _logger.LogInformation("User {UserId} unsubscribed from {Symbol}", userId, symbol);

            return UnsubscribeResult.Success($"Unsubscribed from {symbol}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error unsubscribing user {UserId} from {Symbol}", userId, symbol);
            return UnsubscribeResult.Error($"Failed to unsubscribe: {ex.Message}");
        }
    }

    private static string GetSymbolGroup(string symbol) => $"{SymbolGroupPrefix}{symbol}";
}

// DTOs
public record PriceUpdateDto(
    string Symbol,
    decimal Price,
    decimal ChangePercentage,
    DateTime Timestamp
);

public record SubscribeResult(bool IsSuccess, string Message, string? ErrorCode = null)
{
    public static SubscribeResult Success(string message) => new(true, message);
    public static SubscribeResult Unauthorized(string message) => new(false, message, "UNAUTHORIZED");
    public static SubscribeResult Forbidden(string message) => new(false, message, "FORBIDDEN");
    public static SubscribeResult Error(string message) => new(false, message, "ERROR");
}

public record UnsubscribeResult(bool IsSuccess, string Message)
{
    public static UnsubscribeResult Success(string message) => new(true, message);
    public static UnsubscribeResult Unauthorized(string message) => new(false, message);
    public static UnsubscribeResult Error(string message) => new(false, message);
}

// ============================================
// BACKGROUND SERVICE (Consome B3 WebSocket e distribui via SignalR)
// ============================================

/// <summary>
/// Background Service que consome feed WebSocket da B3 e distribui
/// precos em tempo real via SignalR para traders conectados
/// </summary>
public class MarketDataStreamService : BackgroundService
{
    private readonly IMarketDataFeedClient _feedClient;
    private readonly IHubContext<MarketDataHub> _hubContext;
    private readonly IMarketDataStreamService _streamService; // Domain Service (throttling)
    private readonly IOptionContractRepository _optionRepository;
    private readonly IUnderlyingAssetRepository _assetRepository;
    private readonly IDomainEventDispatcher _eventDispatcher;
    private readonly ILogger<MarketDataStreamService> _logger;

    private DateTime _streamStartTime;
    private readonly HashSet<string> _subscribedSymbols = new();

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Market Data Stream Service starting...");

        // Aguardar mercado abrir (9h)
        await WaitForMarketOpenAsync(stoppingToken);

        try
        {
            // 1. Conectar ao feed da B3
            await _feedClient.ConnectAsync(stoppingToken);
            _streamStartTime = DateTime.UtcNow;

            // 2. Registrar event handlers
            _feedClient.OnPriceUpdate += HandlePriceUpdate;
            _feedClient.OnDisconnected += HandleDisconnected;
            _feedClient.OnReconnected += HandleReconnected;

            // 3. Subscrever simbolos de estrategias ativas
            var activeSymbols = await GetActiveStrategySymbolsAsync(stoppingToken);
            await _feedClient.SubscribeToSymbolsAsync(activeSymbols, stoppingToken);
            _subscribedSymbols.UnionWith(activeSymbols);

            _logger.LogInformation("Subscribed to {Count} symbols", activeSymbols.Count);

            // Publicar evento de inicio
            await _eventDispatcher.DispatchAsync(
                new MarketDataStreamStarted(
                    DateTime.UtcNow,
                    _subscribedSymbols.Count,
                    "B3_WEBSOCKET"
                ),
                stoppingToken);

            // 4. Manter servico rodando ate fechamento do mercado (18h) ou cancelamento
            while (!stoppingToken.IsCancellationRequested && IsMarketOpen())
            {
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Market Data Stream Service failed");
        }
        finally
        {
            // Cleanup
            _feedClient.OnPriceUpdate -= HandlePriceUpdate;
            _feedClient.OnDisconnected -= HandleDisconnected;
            _feedClient.OnReconnected -= HandleReconnected;

            await _feedClient.DisconnectAsync();

            var upTime = DateTime.UtcNow - _streamStartTime;
            await _eventDispatcher.DispatchAsync(
                new MarketDataStreamStopped(
                    DateTime.UtcNow,
                    stoppingToken.IsCancellationRequested ? "STOPPED" : "MARKET_CLOSED",
                    upTime
                ),
                CancellationToken.None);

            _logger.LogInformation("Market Data Stream Service stopped. UpTime: {UpTime}", upTime);
        }
    }

    private async void HandlePriceUpdate(object? sender, MarketDataUpdate update)
    {
        try
        {
            // 1. Aplicar throttling (max 1 update/segundo por simbolo)
            if (!_streamService.ShouldProcessPriceUpdate(update.Symbol, update.Timestamp))
            {
                _logger.LogTrace("Throttled price update for {Symbol}", update.Symbol);
                return;
            }

            // 2. Verificar se mudanca e significativa (> 0.1%)
            var cachedPrice = _streamService.GetCachedPrice(update.Symbol);
            var newPrice = Money.Brl(update.LastPrice);

            if (cachedPrice != null &&
                !_streamService.IsPriceChangeSignificant(cachedPrice, newPrice, 0.1m))
            {
                _logger.LogTrace("Price change not significant for {Symbol}", update.Symbol);
                return;
            }

            // 3. Atualizar cache
            _streamService.UpdateCachedPrice(update.Symbol, newPrice);
            _streamService.RecordPriceUpdate(update.Symbol, update.Timestamp);

            // 4. Atualizar banco de dados (async fire-and-forget)
            _ = Task.Run(async () =>
            {
                var option = await _optionRepository.GetBySymbolAsync(update.Symbol, CancellationToken.None);
                if (option != null)
                {
                    option.UpdateMarketPrices(
                        Money.Brl(update.BidPrice),
                        Money.Brl(update.AskPrice),
                        Money.Brl(update.LastPrice),
                        update.Timestamp,
                        update.Volume,
                        null,
                        update.Timestamp
                    );
                    await _optionRepository.UpdateAsync(option, CancellationToken.None);
                }
            });

            // 5. Broadcast via SignalR para grupo do simbolo
            var changePercentage = cachedPrice != null
                ? ((newPrice.Amount - cachedPrice.Amount) / cachedPrice.Amount) * 100
                : 0;

            var subscriberCount = GetSubscriberCount(update.Symbol); // implementar contagem de conexoes no grupo

            await _hubContext.Clients
                .Group($"symbol_{update.Symbol}")
                .SendAsync("PriceUpdate", new PriceUpdateDto(
                    update.Symbol,
                    update.LastPrice,
                    changePercentage,
                    update.Timestamp
                ));

            // 6. Publicar evento de domain
            await _eventDispatcher.DispatchAsync(
                new RealTimePriceReceived(
                    update.Symbol,
                    newPrice,
                    cachedPrice,
                    changePercentage,
                    update.Timestamp,
                    subscriberCount
                ),
                CancellationToken.None);

            _logger.LogDebug("Broadcasted price update for {Symbol}: {Price} ({Change:F2}%)",
                update.Symbol, update.LastPrice, changePercentage);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error handling price update for {Symbol}", update.Symbol);
        }
    }

    private void HandleDisconnected(object? sender, string reason)
    {
        _logger.LogWarning("Market data feed disconnected: {Reason}", reason);
        // IMarketDataFeedClient deve ter reconexao automatica
    }

    private void HandleReconnected(object? sender, EventArgs e)
    {
        _logger.LogInformation("Market data feed reconnected");

        // Re-subscrever simbolos
        Task.Run(async () =>
        {
            await _feedClient.SubscribeToSymbolsAsync(_subscribedSymbols, CancellationToken.None);
        });
    }

    private async Task<List<string>> GetActiveStrategySymbolsAsync(CancellationToken ct)
    {
        // Buscar todas estrategias ativas (PaperTrading + Live)
        // Extrair simbolos de opcoes + ativos subjacentes
        // Retornar lista unica

        // Implementacao simplificada (deve usar repository query)
        var symbols = new List<string> { "PETR4", "VALE3", "PETRH245", "VALEH205" };
        return symbols;
    }

    private bool IsMarketOpen()
    {
        var now = DateTime.Now;

        // Verificar se e dia util (segunda a sexta)
        if (now.DayOfWeek == DayOfWeek.Saturday || now.DayOfWeek == DayOfWeek.Sunday)
            return false;

        // Verificar horario (9h as 18h)
        var marketOpen = new TimeSpan(9, 0, 0);
        var marketClose = new TimeSpan(18, 0, 0);

        return now.TimeOfDay >= marketOpen && now.TimeOfDay <= marketClose;
    }

    private async Task WaitForMarketOpenAsync(CancellationToken ct)
    {
        while (!IsMarketOpen() && !ct.IsCancellationRequested)
        {
            _logger.LogInformation("Market is closed. Waiting...");
            await Task.Delay(TimeSpan.FromMinutes(15), ct);
        }
    }

    private int GetSubscriberCount(string symbol)
    {
        // Implementar usando IHubContext para contar conexoes no grupo
        // Por enquanto, retornar 0
        return 0;
    }
}
```

**Aggregates Envolvidos:**
- User (read-only - validar RealtimeData feature flag)
- OptionContract (modify - atualizar precos em tempo real)
- UnderlyingAsset (modify - atualizar precos em tempo real)

**Domain Events Gerados:**
- `MarketDataStreamStarted` - quando background service conecta ao feed
- `MarketDataStreamStopped` - quando servico para (mercado fecha ou erro)
- `UserSubscribedToSymbol` - quando trader subscreve via SignalR
- `UserUnsubscribedFromSymbol` - quando trader remove subscricao
- `RealTimePriceReceived` - para cada update de preco significativo (> 0.1%)
- `OptionMarketPricesUpdated` - quando banco de dados e atualizado

**Domain Services Utilizados:**
- `IMarketDataStreamService` - throttling, cache, e validacao de mudancas significativas

**External Services:**
- `IMarketDataFeedClient` - WebSocket para feed da B3

**Infrastructure:**
- SignalR Hub (WebSocket para frontend)
- Background Service (IHostedService)
- Redis (cache distribuido de precos - opcional mas recomendado)

**Rate Limiting:**
- Throttling: max 1 update/segundo por simbolo
- Mudanca minima: 0.1% (evita spam de updates insignificantes)
- Validacao de plano: apenas Pleno/Consultor

**Client Usage (Frontend - JavaScript/TypeScript):**

```typescript
// Conectar ao SignalR Hub
const connection = new signalR.HubConnectionBuilder()
    .withUrl("/hubs/marketdata", { accessTokenFactory: () => getAuthToken() })
    .withAutomaticReconnect()
    .build();

// Handler para updates de preco
connection.on("PriceUpdate", (update: PriceUpdateDto) => {
    console.log(`${update.symbol}: ${update.price} (${update.changePercentage}%)`);

    // Atualizar UI
    updatePriceDisplay(update.symbol, update.price, update.changePercentage);
});

// Conectar
await connection.start();

// Subscrever opcao
const result = await connection.invoke("SubscribeToSymbol", "PETRH245");
if (!result.isSuccess) {
    if (result.errorCode === "FORBIDDEN") {
        showUpgradePrompt(); // Mostrar mensagem para upgrade de plano
    }
}

// Desconectar ao sair
await connection.invoke("UnsubscribeFromSymbol", "PETRH245");
await connection.stop();
```

---

## 📊 Complexidade e Estimativas

| Bounded Context | Aggregates | Entities | Value Objects | Repositories | Complexity |
|-----------------|------------|----------|---------------|--------------|------------|
| **Market Data** | **2 (OptionContract, UnderlyingAsset)** | **3 (+ StrikeAdjustment)** | **8** | **2** | **Alta** |

**Estimativa de Implementacao:**
- **Market Data BC: 5-6 dias (DBA: 1 dia, SE: 4-5 dias)**
  - Aggregates + Repos: 2 dias
  - Black-Scholes Service (europeias): 2 dias
  - Sync Job B3 + APIs: 1-2 dias

**Breakdown Market Data:**
- Day 1: OptionContract aggregate + repository + migrations
- Day 2: UnderlyingAsset aggregate + sync job skeleton
- Day 3-4: Black-Scholes service (pricing + IV + Greeks)
- Day 5: Sync job B3 API integration + retry policies (Polly)
- Day 6: Validacao e testes de integracao + streaming (SignalR/WebSocket)

---

## ✅ Validacao

- [x] Aggregates definidos com invariantes claros
- [x] Boundaries dos aggregates respeitados (Option, UnderlyingAsset separados)
- [x] Domain Events identificados para integracoes (**14 eventos**)
- [x] Repository interfaces definidas (2 repositorios)
- [x] Use Cases mapeados (**2 use cases: UC-MarketData-01 Sync + UC-MarketData-02 Streaming**)
- [x] Validacoes de negocio no dominio (nao na aplicacao)
- [x] Nomenclatura consistente (PT → EN conforme padroes)
- [x] **Market Data BC modelado (OptionContract, UnderlyingAsset)**
- [x] **Regras da B3 validadas (Puts europeias, ajustes de strike)**
- [x] **Black-Scholes service definido (apenas europeias no EPIC-01)**
- [x] **Integracao Strategy Planning ↔ Market Data mapeada**
- [x] **Opcoes semanais suportadas (W1-W5, W3 = mensal padrao)**
- [x] **B3 API integration documentada (IB3ApiClient + sync job)**
- [x] **UC-MarketData-01: Sincronizacao diaria de opcoes da B3 (batch)**
- [x] **UC-MarketData-02: Streaming de precos em tempo real (SignalR/WebSocket)**
- [x] **Real-time data validado por plano (RealtimeData feature flag)**
- [x] **Throttling e caching para performance de streaming**
- [x] **Domain Services completos (IBlackScholesService, IWeeklySeriesCalculator, IMarketDataStreamService)**

---

## 📝 Notas de Implementacao para SE

**Tecnologias:**
- Framework: .NET 8
- ORM: EF Core 8
- Event Bus: MediatR (in-process) + RabbitMQ (future)
- **Black-Scholes: Math.NET Numerics (para calculos avancados)**
- **B3 API: HTTP Client + retry policies (Polly)**
- **Real-time: SignalR (WebSocket)**
- **Cache: Redis (opcional mas recomendado para streaming)**

**Estrutura de Pastas:**
```
02-backend/src/
├── Domain/
│   └── MarketData/
│       ├── Aggregates/
│       │   ├── OptionContract.cs
│       │   └── UnderlyingAsset.cs
│       ├── Entities/
│       │   └── StrikeAdjustment.cs
│       ├── ValueObjects/
│       │   ├── OptionContractId.cs
│       │   ├── OptionType.cs
│       │   ├── ExerciseType.cs
│       │   ├── OptionGreeks.cs
│       │   ├── OptionSeries.cs
│       │   └── OptionStatus.cs
│       ├── DomainEvents/
│       │   ├── OptionContractCreated.cs
│       │   ├── OptionMarketPricesUpdated.cs
│       │   ├── OptionGreeksUpdated.cs
│       │   ├── OptionStrikeAdjusted.cs
│       │   ├── OptionExpired.cs
│       │   ├── OptionsDataSyncStarted.cs
│       │   ├── OptionsDataSyncCompleted.cs
│       │   ├── NewOptionContractsDiscovered.cs
│       │   ├── MarketDataStreamStarted.cs
│       │   ├── MarketDataStreamStopped.cs
│       │   ├── RealTimePriceReceived.cs
│       │   ├── UserSubscribedToSymbol.cs
│       │   └── UserUnsubscribedFromSymbol.cs
│       ├── Services/
│       │   ├── IBlackScholesService.cs
│       │   ├── IWeeklySeriesCalculator.cs
│       │   └── IMarketDataStreamService.cs
│       └── Interfaces/
│           ├── IOptionContractRepository.cs
│           └── IUnderlyingAssetRepository.cs
├── Application/
│   └── MarketData/
│       ├── Commands/
│       │   ├── SyncOptionsCommand.cs
│       │   └── AdjustStrikeForDividendCommand.cs
│       ├── Handlers/
│       │   ├── SyncOptionsHandler.cs
│       │   └── AdjustStrikeForDividendHandler.cs
│       ├── Queries/
│       │   ├── GetAvailableOptionsQuery.cs
│       │   └── GetOptionBySymbolQuery.cs
│       └── Services/
│           ├── IMarketDataService.cs (ACL para Strategy Planning)
│           └── BlackScholesService.cs
└── Infrastructure/
    ├── Persistence/
    │   ├── Repositories/
    │   │   ├── OptionContractRepository.cs
    │   │   └── UnderlyingAssetRepository.cs
    │   └── Configurations/
    │       ├── OptionContractConfiguration.cs
    │       └── UnderlyingAssetConfiguration.cs
    ├── ExternalServices/
    │   └── B3Api/
    │       ├── IB3ApiClient.cs
    │       ├── B3ApiClient.cs
    │       ├── IMarketDataFeedClient.cs
    │       ├── MarketDataFeedClient.cs
    │       └── B3ApiModels.cs (DTOs)
    ├── BackgroundServices/
    │   ├── OptionsSyncJob.cs (Scheduled daily sync)
    │   └── MarketDataStreamService.cs (WebSocket consumer)
    └── Hubs/
        └── MarketDataHub.cs (SignalR)
```

**Prioridades de Implementacao:**
1. **Day 1:** OptionContract aggregate + repository + migrations
2. **Day 2:** UnderlyingAsset aggregate + sync job skeleton
3. **Day 3-4:** Black-Scholes service (pricing, IV, Greeks) usando Math.NET Numerics
4. **Day 5:** B3 API integration + sync job + retry policies (Polly)
5. **Day 6:** Streaming (SignalR Hub + Background Service) + testing + validacao

**Notas Importantes:**
- **Black-Scholes:** Usar Math.NET Numerics para distribuicao normal (CDF) e calculos numericos
- **Opcoes Europeias:** Black-Scholes e exato para europeias; opcoes americanas (algumas calls) precisarao modelo binomial (EPIC-02)
- **Series Semanais:** IWeeklySeriesCalculator deve calcular W1-W5 baseado em calendario B3 (3a segunda-feira = W3 = mensal)
- **Ajustes de Strike:** StrikeAdjustment child entity registra historico de ajustes por dividendos
- **B3 API:** Implementar retry policies (Polly) para resiliencia
- **Streaming:** SignalR + Background Service + throttling (1 update/seg) + cache (Redis recomendado)
- **Validacao de Plano:** Apenas Pleno/Consultor tem acesso a dados em tempo real
- **Indexes:** Criar indices compostos para queries de busca de opcoes (underlying + status + expiration + series)

---

## 🔗 Referencias

- **SDA Context Map:** `00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md`
- **Ubiquitous Language:** `00-doc-ddd/02-strategic-design/SDA-03-Ubiquitous-Language.md`
- **DDD Patterns Reference:** `.agents/docs/05-DDD-Patterns-Reference.md`
- **Documento Original (EPIC-01 Completo):** `00-doc-ddd/04-tactical-design/DE-01-EPIC-01-CreateStrategy-Domain-Model.md`

---
