<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)  
- Use blank lines between sections for readability (content)  
- Validate in Markdown preview before committing  
-->

# DE-01-EPIC-01-B-Strategy-Templates-Domain-Model.md

**Agent:** DE (Domain Engineer)  
**Project:** myTraderGEO  
**Date:** 2025-10-25  
**Epic:** EPIC-01-B: Strategy Templates (segmento do EPIC-01)  
**Phase:** Iteration  
**Scope:** Tactical DDD model for epic-specific bounded contexts  
**Version:** 1.0  

---

## 🎯 Contexto do Sub-Épico

**Nome do Sub-Épico:** Strategy Templates  

**Bounded Context:** Strategy Planning  

**Objetivo:**
Modelar o catálogo de templates de estratégias (globais do sistema + pessoais do trader) com strikes relativos, topologias, caracterizações (MarketView, Objective, RiskProfile) e orientações de defesa/ajuste. Templates definem estrutura/topologia com referências relativas (ATM, ATM±X%, vencimentos relativos).

**Aggregates Modelados:**
- StrategyTemplate (Aggregate Root)  
  - TemplateLeg (Child Entity)  

---

## 📋 Índice do Modelo de Domínio

### Strategy Planning BC

#### [Aggregate: StrategyTemplate](#4-strategytemplate-aggregate-root)
**Responsabilidade:** Templates com strikes relativos + caracterização e orientações  

**Entities:**
  - TemplateLeg  

**Value Objects:**
  - StrategyTemplateId, TemplateLegId, RelativeStrike, StrikeReference, OptionType, LegType  
  - MarketView, StrategyObjective, StrategyRiskProfile, PriceRangeIdeal, DefenseGuidelines  

**Domain Events:**
  - TemplateCreated, TemplateNameUpdated, TemplateDescriptionUpdated  
  - TemplateLegAdded, TemplateLegUpdated, TemplateLegRemoved  

---

# Strategy Planning

## Aggregates

## 4. StrategyTemplate (Aggregate Root)

**Responsabilidade:** Gerenciar templates de estratégias com strikes relativos e topologia  

**Invariantes (Business Rules):**
1. Name deve ser único para o usuário (templates pessoais) ou global (templates do sistema)
2. Deve ter ao menos 1 leg (perna)
3. Strikes relativos devem ser válidos (ATM, ATM+X%, ATM-X%, etc)
4. Vencimentos relativos devem ser válidos
5. Template global (Visibility = Global) só pode ser criado por Administrator
6. Template pessoal (Visibility = Personal) pertence a um UserId

## Entities

```csharp
// Aggregate Root
public class StrategyTemplate : Entity<StrategyTemplateId>
{
    // ========================================
    // IDENTITY & BASIC INFO
    // ========================================
    public StrategyTemplateId Id { get; private set; }
    public string Name { get; private set; }
    public string Description { get; private set; }
    public TemplateVisibility Visibility { get; private set; }
    public UserId? OwnerId { get; private set; } // Null for global templates
    public DateTime CreatedAt { get; private set; }

    // ========================================
    // STRATEGY CHARACTERISTICS
    // ========================================
    public MarketView MarketView { get; private set; }              // Alta, Baixa, Lateral, Volátil
    public StrategyObjective Objective { get; private set; }        // Income, Proteção, Especulação, Hedge
    public StrategyRiskProfile RiskProfile { get; private set; }    // Conservador, Moderado, Agressivo

    // ========================================
    // GUIDANCE & RECOMMENDATIONS
    // ========================================
    public PriceRangeIdeal IdealPriceRange { get; private set; }    // Faixa ideal de preço do ativo
    public DefenseGuidelines DefenseGuidelines { get; private set; } // Orientações de defesa/ajuste

    // ========================================
    // LEGS (Child Entities)
    // ========================================
    private readonly List<TemplateLeg> _legs = new();
    public IReadOnlyList<TemplateLeg> Legs => _legs.AsReadOnly();

    // ========================================
    // DOMAIN EVENTS
    // ========================================
    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    // Private constructor for EF Core
    private StrategyTemplate() { }

    // Factory Method - Global Template
    public static StrategyTemplate CreateGlobal(
        string name,
        string description,
        MarketView marketView,
        StrategyObjective objective,
        StrategyRiskProfile riskProfile,
        PriceRangeIdeal idealPriceRange,
        DefenseGuidelines defenseGuidelines,
        List<TemplateLeg> legs)
    {
        ValidateTemplate(name, legs);

        var template = new StrategyTemplate
        {
            Id = StrategyTemplateId.New(),
            Name = name,
            Description = description,
            Visibility = TemplateVisibility.Global,
            OwnerId = null,
            MarketView = marketView,
            Objective = objective,
            RiskProfile = riskProfile,
            IdealPriceRange = idealPriceRange,
            DefenseGuidelines = defenseGuidelines,
            CreatedAt = DateTime.UtcNow,
            _legs = legs
        };

        template._domainEvents.Add(new TemplateCreated(
            template.Id,
            template.Name,
            template.Visibility,
            template.Legs.Count,
            DateTime.UtcNow
        ));

        return template;
    }

    // Factory Method - Personal Template
    public static StrategyTemplate CreatePersonal(
        string name,
        string description,
        UserId ownerId,
        MarketView marketView,
        StrategyObjective objective,
        StrategyRiskProfile riskProfile,
        PriceRangeIdeal idealPriceRange,
        DefenseGuidelines defenseGuidelines,
        List<TemplateLeg> legs)
    {
        ValidateTemplate(name, legs);

        var template = new StrategyTemplate
        {
            Id = StrategyTemplateId.New(),
            Name = name,
            Description = description,
            Visibility = TemplateVisibility.Personal,
            OwnerId = ownerId,
            MarketView = marketView,
            Objective = objective,
            RiskProfile = riskProfile,
            IdealPriceRange = idealPriceRange,
            DefenseGuidelines = defenseGuidelines,
            CreatedAt = DateTime.UtcNow,
            _legs = legs
        };

        template._domainEvents.Add(new TemplateCreated(
            template.Id,
            template.Name,
            template.Visibility,
            template.Legs.Count,
            DateTime.UtcNow
        ));

        return template;
    }

    private static void ValidateTemplate(string name, List<TemplateLeg> legs)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new DomainException("Template name is required");

        if (legs == null || legs.Count == 0)
            throw new DomainException("Template must have at least one leg");

        if (legs.Count > 10)
            throw new DomainException("Template cannot have more than 10 legs");
    }

    // Business Methods
    public void AddLeg(TemplateLeg leg)
    {
        if (_legs.Count >= 10)
            throw new DomainException("Template cannot have more than 10 legs");

        _legs.Add(leg);

        _domainEvents.Add(new TemplateLegAdded(
            Id,
            leg.Id,
            DateTime.UtcNow
        ));
    }

    public void RemoveLeg(TemplateLegId legId)
    {
        var leg = _legs.FirstOrDefault(l => l.Id == legId);
        if (leg == null)
            throw new DomainException("Leg not found");

        if (_legs.Count == 1)
            throw new DomainException("Template must have at least one leg");

        _legs.Remove(leg);

        _domainEvents.Add(new TemplateLegRemoved(
            Id,
            legId,
            DateTime.UtcNow
        ));
    }
}

// Child Entity
public class TemplateLeg : Entity<TemplateLegId>
{
    public TemplateLegId Id { get; private set; }
    public LegType Type { get; private set; } // Stock, CallOption, PutOption
    public Position Position { get; private set; } // Long, Short
    public int Quantity { get; private set; }
    public RelativeStrike? Strike { get; private set; } // Null for Stock
    public RelativeExpiration? Expiration { get; private set; } // Null for Stock

    private TemplateLeg() { }

    // Factory Method - Stock
    public static TemplateLeg CreateStock(Position position, int quantity)
    {
        if (quantity <= 0)
            throw new DomainException("Quantity must be positive");

        return new TemplateLeg
        {
            Id = TemplateLegId.New(),
            Type = LegType.Stock,
            Position = position,
            Quantity = quantity,
            Strike = null,
            Expiration = null
        };
    }

    // Factory Method - Option
    public static TemplateLeg CreateOption(
        LegType type,
        Position position,
        int quantity,
        RelativeStrike strike,
        RelativeExpiration expiration)
    {
        if (type == LegType.Stock)
            throw new DomainException("Use CreateStock for stock legs");

        if (quantity <= 0)
            throw new DomainException("Quantity must be positive");

        return new TemplateLeg
        {
            Id = TemplateLegId.New(),
            Type = type,
            Position = position,
            Quantity = quantity,
            Strike = strike,
            Expiration = expiration
        };
    }
}
```

## Value Objects

```csharp
public record StrategyTemplateId(Guid Value)
{
    public static StrategyTemplateId New() => new(Guid.NewGuid());
}

public record TemplateLegId(Guid Value)
{
    public static TemplateLegId New() => new(Guid.NewGuid());
}

public enum TemplateVisibility
{
    Global,    // Visible to all users
    Personal   // Visible only to owner
}

/// <summary>
/// Visão de mercado para a qual a estratégia foi desenhada
/// </summary>
public enum MarketView
{
    Bullish,    // Alta - espera-se valorização do ativo
    Bearish,    // Baixa - espera-se desvalorização do ativo
    Neutral,    // Lateral - espera-se pouca movimentação
    Volatile    // Volátil - espera-se grande movimentação (qualquer direção)
}

/// <summary>
/// Objetivo principal da estratégia
/// </summary>
public enum StrategyObjective
{
    Income,         // Geração de renda (ex: venda de calls cobertas)
    Protection,     // Proteção de posição (ex: put protetora, collar)
    Speculation,    // Especulação direcional (ex: compra de calls/puts)
    Hedge,          // Hedge de outra estratégia ou portfólio
    Arbitrage       // Arbitragem (ex: spreads, butterflies)
}

/// <summary>
/// Perfil de risco da estratégia (independente do perfil do trader)
/// </summary>
public enum StrategyRiskProfile
{
    Conservative,   // Baixo risco, baixo retorno (ex: collar, covered call)
    Moderate,       // Risco médio, retorno médio (ex: spreads)
    Aggressive      // Alto risco, alto retorno (ex: naked options, long options)
}

public enum LegType
{
    Stock,
    CallOption,
    PutOption
}

public enum Position
{
    Long,   // Buy
    Short   // Sell
}

// Relative Strike (ATM, ATM+5%, ATM-10%, etc)
public record RelativeStrike(
    StrikeReference Reference,
    decimal? PercentageOffset // +5% = 0.05, -10% = -0.10
)
{
    public static RelativeStrike ATM() => new(StrikeReference.ATM, null);
    public static RelativeStrike ATMPlusPercent(decimal percent) => new(StrikeReference.ATM, percent / 100);
    public static RelativeStrike ATMMinusPercent(decimal percent) => new(StrikeReference.ATM, -percent / 100);
}

public enum StrikeReference
{
    ATM,          // At The Money
    CurrentPrice  // Current stock price
}

// Relative Expiration ("janeiro próximo", "+6 meses", etc)
public record RelativeExpiration(
    ExpirationReference Reference,
    int? MonthOffset // +6 = 6 months ahead
)
{
    public static RelativeExpiration NextMonth(string monthName) => new(ExpirationReference.NamedMonth, null);
    public static RelativeExpiration MonthsAhead(int months) => new(ExpirationReference.MonthsOffset, months);
}

public enum ExpirationReference
{
    NamedMonth,    // "janeiro", "fevereiro"
    MonthsOffset   // +1, +6, +12
}

/// <summary>
/// Faixa ideal de preço do ativo para aplicar a estratégia
/// Ex: Collar funciona melhor com ativo entre R$20-R$30
/// </summary>
public record PriceRangeIdeal(
    decimal? MinPrice,     // null = sem limite inferior
    decimal? MaxPrice,     // null = sem limite superior
    string? Description    // Descrição opcional (ex: "Funciona melhor com ações de alta liquidez acima de R$20")
)
{
    public static PriceRangeIdeal Any() => new(null, null, "Qualquer faixa de preço");

    public static PriceRangeIdeal Between(decimal min, decimal max, string? description = null)
        => new(min, max, description);

    public static PriceRangeIdeal Above(decimal min, string? description = null)
        => new(min, null, description);

    public bool IsInRange(decimal price)
    {
        if (MinPrice.HasValue && price < MinPrice.Value)
            return false;

        if (MaxPrice.HasValue && price > MaxPrice.Value)
            return false;

        return true;
    }
}

/// <summary>
/// Orientações de defesa e ajuste quando mercado vai contra a expectativa
/// </summary>
public record DefenseGuidelines(
    string? WhenMarketRises,        // O que fazer se mercado sobe (quando esperava baixa/lateral)
    string? WhenMarketFalls,        // O que fazer se mercado cai (quando esperava alta/lateral)
    string? WhenVolatilityIncreases, // O que fazer se volatilidade aumenta
    string? WhenVolatilityDecreases, // O que fazer se volatilidade diminui
    string? GeneralAdvice,          // Conselhos gerais de ajuste
    StrategyTemplateId? HedgeTemplateId  // Template de hedge sugerido (opcional)
)
{
    public static DefenseGuidelines None() => new(null, null, null, null, null, null);

    public static DefenseGuidelines Create(
        string? whenRises = null,
        string? whenFalls = null,
        string? whenVolUp = null,
        string? whenVolDown = null,
        string? general = null,
        StrategyTemplateId? hedgeTemplate = null)
        => new(whenRises, whenFalls, whenVolUp, whenVolDown, general, hedgeTemplate);
}
```

## Domain Events

```csharp
public record TemplateCreated(
    StrategyTemplateId TemplateId,
    string Name,
    TemplateVisibility Visibility,
    int LegCount,
    DateTime OccurredAt
) : IDomainEvent;

public record TemplateLegAdded(
    StrategyTemplateId TemplateId,
    TemplateLegId LegId,
    DateTime OccurredAt
) : IDomainEvent;

public record TemplateLegRemoved(
    StrategyTemplateId TemplateId,
    TemplateLegId LegId,
    DateTime OccurredAt
) : IDomainEvent;
```

---

### Repository Interface

```csharp
public interface IStrategyTemplateRepository
{
    /// <summary>
    /// Busca template por ID
    /// </summary>
    Task<StrategyTemplate?> GetByIdAsync(StrategyTemplateId id, CancellationToken ct);

    /// <summary>
    /// Busca template por nome (global ou do usuário)
    /// </summary>
    Task<StrategyTemplate?> GetByNameAsync(string name, UserId? ownerId, CancellationToken ct);

    /// <summary>
    /// Busca todos os templates globais
    /// </summary>
    Task<IEnumerable<StrategyTemplate>> GetGlobalTemplatesAsync(CancellationToken ct);

    /// <summary>
    /// Busca templates pessoais de um usuário
    /// </summary>
    Task<IEnumerable<StrategyTemplate>> GetPersonalTemplatesAsync(UserId ownerId, CancellationToken ct);

    /// <summary>
    /// Busca templates por Market View
    /// </summary>
    Task<IEnumerable<StrategyTemplate>> GetByMarketViewAsync(MarketView marketView, UserId? ownerId, CancellationToken ct);

    /// <summary>
    /// Busca templates por Objective
    /// </summary>
    Task<IEnumerable<StrategyTemplate>> GetByObjectiveAsync(StrategyObjective objective, UserId? ownerId, CancellationToken ct);

    /// <summary>
    /// Busca templates por Risk Profile
    /// </summary>
    Task<IEnumerable<StrategyTemplate>> GetByRiskProfileAsync(StrategyRiskProfile riskProfile, UserId? ownerId, CancellationToken ct);

    /// <summary>
    /// Adiciona novo template
    /// </summary>
    Task AddAsync(StrategyTemplate template, CancellationToken ct);

    /// <summary>
    /// Atualiza template existente
    /// </summary>
    Task UpdateAsync(StrategyTemplate template, CancellationToken ct);

    /// <summary>
    /// Remove template (soft delete ou hard delete conforme regras de negócio)
    /// </summary>
    Task DeleteAsync(StrategyTemplateId id, CancellationToken ct);
}
```

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

## 📋 Use Cases (Application Layer)

### UC-Strategy-01: Create Template

**Actor:** Trader ou Administrator  
**Trigger:** Usuário cria template de estratégia  
**Bounded Context:** Strategy Planning  

**Fluxo:**

```csharp
public class CreateTemplateHandler : IRequestHandler<CreateTemplateCommand, Result<StrategyTemplateId>>
{
    private readonly IStrategyTemplateRepository _templateRepository;
    private readonly IUserRepository _userRepository;
    private readonly IDomainEventDispatcher _eventDispatcher;

    public async Task<Result<StrategyTemplateId>> Handle(CreateTemplateCommand command, CancellationToken ct)
    {
        // 1. Buscar usuário
        var user = await _userRepository.GetByIdAsync(command.UserId, ct);

        // 2. Validar permissões
        if (command.Visibility == TemplateVisibility.Global && user.Role != UserRole.Administrator)
            throw new UnauthorizedException("Only administrators can create global templates");

        // 3. Converter legs
        var legs = command.Legs.Select(l => ConvertLeg(l)).ToList();

        // 4. Criar template
        StrategyTemplate template;
        if (command.Visibility == TemplateVisibility.Global)
        {
            template = StrategyTemplate.CreateGlobal(
                command.Name,
                command.Description,
                command.MarketView,
                command.Objective,
                command.RiskProfile,
                command.IdealPriceRange,
                command.DefenseGuidelines,
                legs
            );
        }
        else
        {
            template = StrategyTemplate.CreatePersonal(
                command.Name,
                command.Description,
                command.UserId,
                command.MarketView,
                command.Objective,
                command.RiskProfile,
                command.IdealPriceRange,
                command.DefenseGuidelines,
                legs
            );
        }

        // 5. Persistir
        await _templateRepository.AddAsync(template, ct);

        // 6. Dispatch domain events
        foreach (var @event in template.DomainEvents)
        {
            await _eventDispatcher.DispatchAsync(@event, ct);
        }

        // 7. Retornar resultado
        return Result<StrategyTemplateId>.Success(template.Id);
    }

    private TemplateLeg ConvertLeg(TemplateLegDto dto)
    {
        if (dto.Type == LegType.Stock)
            return TemplateLeg.CreateStock(dto.Position, dto.Quantity);

        return TemplateLeg.CreateOption(
            dto.Type,
            dto.Position,
            dto.Quantity,
            dto.Strike!,
            dto.Expiration!
        );
    }
}

public record CreateTemplateCommand(
    UserId UserId,
    string Name,
    string Description,
    TemplateVisibility Visibility,
    MarketView MarketView,
    StrategyObjective Objective,
    StrategyRiskProfile RiskProfile,
    PriceRangeIdeal IdealPriceRange,
    DefenseGuidelines DefenseGuidelines,
    List<TemplateLegDto> Legs
) : IRequest<Result<StrategyTemplateId>>;

public record TemplateLegDto(
    LegType Type,
    Position Position,
    int Quantity,
    RelativeStrike? Strike,
    RelativeExpiration? Expiration
);
```

**Aggregates Envolvidos:**
- User (read-only - validar permissões)  
- StrategyTemplate (modify - criar template)  

**Domain Events Gerados:**
- `TemplateCreated`  

---

## 📊 Complexidade e Estimativas

| Bounded Context | Aggregates | Entities | Value Objects | Repositories | Complexity |
|-----------------|------------|----------|---------------|--------------|------------|
| Strategy Planning (StrategyTemplate apenas) | 1 (StrategyTemplate) | 2 (StrategyTemplate + TemplateLeg) | 12 | 1 | Média |

**Nota:** Strategy aggregate será modelado em EPIC-01-C  

**Estimativa de Implementação:**
- **StrategyTemplate: ~1 dia (DBA: 0.5 dia, SE: 0.5 dia)**  
  - Aggregate + Repository: 0.5 dia  
  - Use Case (UC-Strategy-01): 0.5 dia  
  - Testing: incluído  

**Dependências:**
- User Management BC (para validação de permissões)  
- Integração com Market Data BC (para instanciação de templates - será implementada em EPIC-01-C)  

---

## ✅ Validação

- [x] StrategyTemplate aggregate definido com invariantes claros  
- [x] Boundaries do aggregate respeitados (StrategyTemplate separado de Strategy)  
- [x] Domain Events identificados para integrações (TemplateCreated, TemplateLegAdded, TemplateLegRemoved)  
- [x] Repository interface definida (IStrategyTemplateRepository)  
- [x] Use Case mapeado (UC-Strategy-01: Create Template)  
- [x] Validações de negócio no domínio (não na aplicação)  
- [x] Nomenclatura consistente (PT → EN conforme padrões)  
- [x] Templates enriquecidos com MarketView, Objective, RiskProfile  
- [x] DefenseGuidelines para orientações de ajuste quando mercado inverte  
- [x] PriceRangeIdeal para indicar faixa ideal de preço do ativo  
- [x] Suporte a templates de hedge (HedgeTemplateId em DefenseGuidelines)  
- [x] Strikes relativos (ATM, ATM±X%) modelados com RelativeStrike  
- [x] Vencimentos relativos modelados com RelativeExpiration  
- [x] Suporte a templates globais (sistema) e pessoais (trader)  
- [x] Validação de permissões (apenas Administrator pode criar templates globais)  

---

## 🗄️ Database First Workflow

**⚠️ IMPORTANTE: Abordagem SQL-First neste Projeto**

Este projeto usa **Database First** onde o fluxo de trabalho é:

### Ordem de Execução

```
DE (Domain Model) → DBA (SQL Migrations) → SE (EF Models Scaffolded)
```

**1. DE cria Domain Model (este documento)**
   - Define Aggregates, Entities, Value Objects  
   - Especifica invariantes e regras de negócio  
   - **NÃO define schema SQL** - apenas modelo conceitual de domínio  

**2. DBA cria SQL Migrations**
   - Lê este documento DE-01 para entender o domínio  
   - Cria scripts SQL idempotentes em `04-database/migrations/`  
   - Define tabelas, índices, constraints, tipos  
   - Documenta em `DBA-01-[EpicName]-Schema-Review.md`  
   - **Referência:** [Workflow Guide - Database First](../../.agents/docs/00-Workflow-Guide.md#database-workflow-sql-first-approach)  

**3. SE scaffolds EF Core models do database**
   - Executa migrations SQL do DBA  
   - Usa `dotnet ef dbcontext scaffold` para gerar classes C#  
   - Ajusta models para manter encapsulamento do domínio  
   - Implementa Repository interfaces usando EF Core  
   - **NÃO cria schema via Code-First migrations**  

### Benefícios Database First

- ✅ **DBA controla performance** - índices, particionamento, otimizações SQL  
- ✅ **Schema validado** - DBA revisa antes de implementação  
- ✅ **Auditoria** - Mudanças de schema em SQL versionado (git)  
- ✅ **Flexibilidade** - Schema pode divergir do modelo OO quando necessário  
- ✅ **Testing realista** - Integration tests usam schema SQL real (não in-memory)  

### Próximos Passos (After DE-01)

1. **DBA** cria migrations SQL baseado neste modelo
2. **DBA** documenta schema em `DBA-01-EPIC-01-B-Schema-Review.md`
3. **SE** scaffolds models e implementa repositories
4. **QAE** executa testes de integração com PostgreSQL real

**Referências Database First:**
- **DBA README:** [04-database/README.md](../../04-database/README.md) - Migration scripts, idempotency patterns  
- **QAE-00:** [QAE-00-Test-Strategy.md](../06-quality-assurance/QAE-00-Test-Strategy.md) - Integration tests with PostgreSQL  
- **GM-00:** [GM-00-GitHub-Setup.md](../07-github-management/GM-00-GitHub-Setup.md) - CI/CD database migrations  

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
│       │   └── StrategyTemplate.cs
│       ├── Entities/
│       │   └── TemplateLeg.cs
│       ├── ValueObjects/
│       │   ├── StrategyTemplateId.cs
│       │   ├── TemplateLegId.cs
│       │   ├── RelativeStrike.cs
│       │   ├── RelativeExpiration.cs
│       │   ├── MarketView.cs
│       │   ├── StrategyObjective.cs
│       │   ├── StrategyRiskProfile.cs
│       │   ├── PriceRangeIdeal.cs
│       │   ├── DefenseGuidelines.cs
│       │   ├── LegType.cs
│       │   └── Position.cs
│       ├── DomainEvents/
│       │   ├── TemplateCreated.cs
│       │   ├── TemplateLegAdded.cs
│       │   └── TemplateLegRemoved.cs
│       └── Interfaces/
│           └── IStrategyTemplateRepository.cs
├── Application/
│   └── StrategyPlanning/
│       ├── Commands/
│       │   └── CreateTemplateCommand.cs
│       └── Handlers/
│           └── CreateTemplateHandler.cs
└── Infrastructure/
    └── Persistence/
        ├── Repositories/
        │   └── StrategyTemplateRepository.cs
        └── Configurations/
            └── StrategyTemplateConfiguration.cs
```

**Prioridades de Implementação:**
1. **Day 1 (Morning):** StrategyTemplate aggregate + Value Objects
   - StrategyTemplate entity  
   - TemplateLeg entity  
   - Value Objects (StrategyTemplateId, MarketView, StrategyObjective, etc)  
   - RelativeStrike e RelativeExpiration  
   - PriceRangeIdeal e DefenseGuidelines  

2. **Day 1 (Afternoon):** Repository + Use Case + Tests
   - IStrategyTemplateRepository interface  
   - StrategyTemplateRepository implementation  
   - EF Core configuration  
   - Database migration  
   - CreateTemplateHandler (UC-Strategy-01)  
   - Unit tests + Integration tests  

**Pontos de Atenção:**
- Templates globais só podem ser criados por Administrator  
- Templates pessoais pertencem a um UserId específico  
- RelativeStrike permite offsets percentuais (ATM+5%, ATM-10%)  
- DefenseGuidelines pode referenciar outro template de hedge  
- PriceRangeIdeal valida faixa ideal de preço do ativo  

**Integração com User Management:**
- Query User.Role para validar permissões (global vs personal templates)  
- UserId deve existir e ser válido  

**Eventos de Domínio:**
- TemplateCreated: publicado ao criar template (usado para notificações)  
- TemplateLegAdded: publicado ao adicionar leg  
- TemplateLegRemoved: publicado ao remover leg  

---

## 🔗 Referências

- **EPIC-01 Completo:** `DE-01-EPIC-01-CreateStrategy-Domain-Model.md`  
- **SDA Context Map:** `00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md`  
- **Ubiquitous Language:** `00-doc-ddd/02-strategic-design/SDA-03-Ubiquitous-Language.md`  
- **DDD Patterns Reference:** `.agents/docs/05-DDD-Patterns-Reference.md`  
- **DBA Workflow (Database First):** [Workflow Guide - Database First](../../.agents/docs/00-Workflow-Guide.md#database-workflow-sql-first-approach)  
- **DBA README:** [04-database/README.md](../../04-database/README.md) - Migration scripts structure, idempotency patterns  
- **DBA Schema Review:** `00-doc-ddd/05-database-design/DBA-01-EPIC-01-B-Schema-Review.md` (to be created by DBA)  
