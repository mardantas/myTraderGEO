# DE-01-EPIC-01-CreateStrategy-Domain-Model.md

**Projeto:** myTraderGEO
**Épico:** EPIC-01 - Criação e Análise de Estratégias + Admin Management
**Data:** 2025-10-21
**Engineer:** DE Agent

---

## 🎯 Contexto do Épico

**Nome do Épico:** Criação e Análise de Estratégias + Admin Management

**Bounded Contexts Envolvidos:**
- User Management (completo)
- Strategy Planning (completo)
- Market Data (completo - OptionContract, UnderlyingAsset)
- Risk Management (integração via eventos - futuro)

**Objetivo de Negócio:**
Entregar funcionalidade completa de criação de estratégias com templates (strikes relativos), gestão administrativa de planos/limites, e **gerenciamento de dados de mercado da B3 (opções e ativos subjacentes)**, permitindo traders instanciarem estratégias em opções reais com validação de disponibilidade, liquidez, Greeks, e IV, incluindo cálculo automático de margem e validação de limites por plano de assinatura.

---

## 📋 Índice do Modelo de Domínio

### User Management BC

#### [Aggregate: User](#1-user-aggregate-root)
**Responsabilidade:** Gerenciamento de usuários, autenticação, perfil e planos

**Entities:**
  - (nenhuma child entity)

**Value Objects:**
  - UserId, Email, PasswordHash, UserRole, RiskProfile, UserStatus
  - UserPlanOverride, TradingFees, BillingPeriod

**Domain Events:**
  - UserRegistered, RiskProfileUpdated, UserPlanUpgraded
  - UserLoggedIn, UserSuspended, UserActivated, UserDeleted, DisplayNameUpdated
  - PlanOverrideGranted, PlanOverrideRevoked
  - CustomFeesConfigured, CustomFeesRemoved

---

#### [Aggregate: SubscriptionPlan](#2-subscriptionplan-aggregate-root)
**Responsabilidade:** Planos de assinatura (Básico, Pleno, Consultor)

**Entities:**
  - (nenhuma child entity)

**Value Objects:**
  - SubscriptionPlanId, Money, PlanFeatures

**Domain Events:**
  - PlanConfigured, PlanPricingUpdated, PlanLimitsUpdated
  - PlanFeaturesUpdated, PlanDeactivated, PlanActivated

---

#### [Aggregate: SystemConfig](#3-systemconfig-aggregate-root)
**Responsabilidade:** Configurações globais (taxas, limites)

**Entities:**
  - (nenhuma child entity)

**Value Objects:**
  - SystemConfigId

**Domain Events:**
  - SystemConfigInitialized, SystemParametersUpdated

---

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

### Market Data BC

#### [Aggregate: OptionContract](#6-optioncontract-aggregate-root)
**Responsabilidade:** Contratos de opção da B3

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

#### [Aggregate: UnderlyingAsset](#7-underlyingasset-aggregate-root)
**Responsabilidade:** Ativos subjacentes (PETR4, VALE3, etc.)

**Entities:**
  - (nenhuma child entity)

**Value Objects:**
  - UnderlyingAssetId, Ticker, AssetType

**Domain Events:**
  - UnderlyingAssetRegistered, AssetPriceUpdated, AssetDeactivated

---

## 🏗️ Modelo Tático por Bounded Context

# User Management

## Aggregates

## 1. User (Aggregate Root)

**Responsabilidade:** Gerenciar cadastro, autenticação e perfil de usuário

**Invariantes (Business Rules):**
1. Email deve ser único no sistema
2. Password deve ter no mínimo 8 caracteres
3. DisplayName deve ter entre 2 e 30 caracteres
4. RiskProfile deve ser um dos valores: Conservador, Moderado, Agressivo
5. Role deve ser: Trader, Moderator, Administrator
6. Trader deve ter um SubscriptionPlan e BillingPeriod associados
7. Administrator e Moderator não precisam de SubscriptionPlan nem BillingPeriod
8. Apenas Traders podem ter PlanOverride
9. PlanOverride expirado deve ser ignorado nos cálculos de limites efetivos
10. BillingPeriod deve ser Monthly ou Annual
11. Apenas Traders podem configurar CustomFees
12. Todas as taxas em CustomFees devem estar entre 0 e 1 (se especificadas)

## Entities

```csharp
// Aggregate Root
public class User : Entity<UserId>
{
    // Properties
    public UserId Id { get; private set; }
    public Email Email { get; private set; }
    public PasswordHash Password { get; private set; }
    public string FullName { get; private set; }
    public string DisplayName { get; private set; }
    public UserRole Role { get; private set; }
    public RiskProfile? RiskProfile { get; private set; } // Nullable for Admin/Moderator
    public SubscriptionPlanId? SubscriptionPlanId { get; private set; } // Nullable for Admin/Moderator
    public BillingPeriod? BillingPeriod { get; private set; } // Nullable for Admin/Moderator
    public UserStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? LastLoginAt { get; private set; }

    // Plan Override (for VIP, Beta Testers, Trials, etc)
    public UserPlanOverride? PlanOverride { get; private set; }

    // Custom Trading Fees (for different brokers, VIP accounts, etc)
    public TradingFees? CustomFees { get; private set; } // null = usar SystemConfig

    // Domain Events
    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    // Private constructor for EF Core
    private User() { }

    // Factory Method - Trader
    public static User CreateTrader(
        Email email,
        PasswordHash password,
        string fullName,
        string displayName,
        RiskProfile riskProfile,
        SubscriptionPlanId planId,
        BillingPeriod billingPeriod)
    {
        if (string.IsNullOrWhiteSpace(fullName))
            throw new DomainException("Full name is required");

        if (string.IsNullOrWhiteSpace(displayName))
            throw new DomainException("Display name is required");

        if (displayName.Length < 2 || displayName.Length > 30)
            throw new DomainException("Display name must be between 2 and 30 characters");

        var user = new User
        {
            Id = UserId.New(),
            Email = email,
            Password = password,
            FullName = fullName,
            DisplayName = displayName,
            Role = UserRole.Trader,
            RiskProfile = riskProfile,
            SubscriptionPlanId = planId,
            BillingPeriod = billingPeriod,
            Status = UserStatus.Active,
            CreatedAt = DateTime.UtcNow
        };

        user._domainEvents.Add(new UserRegistered(
            user.Id,
            user.Email,
            user.Role,
            DateTime.UtcNow
        ));

        return user;
    }

    // Factory Method - Administrator
    public static User CreateAdministrator(
        Email email,
        PasswordHash password,
        string fullName,
        string displayName)
    {
        if (string.IsNullOrWhiteSpace(fullName))
            throw new DomainException("Full name is required");

        if (string.IsNullOrWhiteSpace(displayName))
            throw new DomainException("Display name is required");

        if (displayName.Length < 2 || displayName.Length > 30)
            throw new DomainException("Display name must be between 2 and 30 characters");

        var user = new User
        {
            Id = UserId.New(),
            Email = email,
            Password = password,
            FullName = fullName,
            DisplayName = displayName,
            Role = UserRole.Administrator,
            RiskProfile = null,
            SubscriptionPlanId = null,
            Status = UserStatus.Active,
            CreatedAt = DateTime.UtcNow
        };

        user._domainEvents.Add(new UserRegistered(
            user.Id,
            user.Email,
            user.Role,
            DateTime.UtcNow
        ));

        return user;
    }

    // Business Methods
    public void UpdateRiskProfile(RiskProfile newProfile)
    {
        if (Role != UserRole.Trader)
            throw new DomainException("Only traders can have risk profile");

        RiskProfile = newProfile;

        _domainEvents.Add(new RiskProfileUpdated(
            Id,
            newProfile,
            DateTime.UtcNow
        ));
    }

    public void UpgradeSubscriptionPlan(SubscriptionPlanId newPlanId, BillingPeriod newBillingPeriod)
    {
        if (Role != UserRole.Trader)
            throw new DomainException("Only traders have subscription plans");

        var oldPlanId = SubscriptionPlanId;
        var oldBillingPeriod = BillingPeriod;

        SubscriptionPlanId = newPlanId;
        BillingPeriod = newBillingPeriod;

        _domainEvents.Add(new UserPlanUpgraded(
            Id,
            oldPlanId!,
            newPlanId,
            oldBillingPeriod!.Value,
            newBillingPeriod,
            DateTime.UtcNow
        ));
    }

    public void RecordLogin()
    {
        LastLoginAt = DateTime.UtcNow;

        _domainEvents.Add(new UserLoggedIn(
            Id,
            DateTime.UtcNow
        ));
    }

    public void Suspend()
    {
        if (Status == UserStatus.Suspended)
            throw new DomainException("User is already suspended");

        Status = UserStatus.Suspended;

        _domainEvents.Add(new UserSuspended(
            Id,
            DateTime.UtcNow
        ));
    }

    public void Activate()
    {
        if (Status == UserStatus.Active)
            throw new DomainException("User is already active");

        Status = UserStatus.Active;

        _domainEvents.Add(new UserActivated(
            Id,
            DateTime.UtcNow
        ));
    }

    public void UpdateDisplayName(string newDisplayName)
    {
        if (string.IsNullOrWhiteSpace(newDisplayName))
            throw new DomainException("Display name is required");

        if (newDisplayName.Length < 2 || newDisplayName.Length > 30)
            throw new DomainException("Display name must be between 2 and 30 characters");

        DisplayName = newDisplayName;

        _domainEvents.Add(new UserDisplayNameUpdated(
            Id,
            newDisplayName,
            DateTime.UtcNow
        ));
    }

    // Plan Override Management
    public void GrantPlanOverride(
        int? strategyLimitOverride,
        PlanFeatures? featuresOverride,
        DateTime? expiresAt,
        string reason,
        UserId grantedBy)
    {
        if (Role != UserRole.Trader)
            throw new DomainException("Only traders can have plan overrides");

        if (string.IsNullOrWhiteSpace(reason))
            throw new DomainException("Reason is required for plan override");

        PlanOverride = new UserPlanOverride(
            strategyLimitOverride,
            featuresOverride,
            expiresAt,
            reason,
            grantedBy,
            DateTime.UtcNow
        );

        _domainEvents.Add(new PlanOverrideGranted(
            Id,
            strategyLimitOverride,
            featuresOverride,
            expiresAt,
            reason,
            grantedBy,
            DateTime.UtcNow
        ));
    }

    public void RevokePlanOverride(UserId revokedBy)
    {
        if (PlanOverride == null)
            throw new DomainException("No plan override to revoke");

        PlanOverride = null;

        _domainEvents.Add(new PlanOverrideRevoked(
            Id,
            revokedBy,
            DateTime.UtcNow
        ));
    }

    public int GetEffectiveStrategyLimit(SubscriptionPlan plan)
    {
        // Se tem override ativo, usar
        if (PlanOverride != null &&
            PlanOverride.IsActive() &&
            PlanOverride.StrategyLimitOverride.HasValue)
        {
            return PlanOverride.StrategyLimitOverride.Value;
        }

        // Senão, usar do plano
        return plan.StrategyLimit;
    }

    public PlanFeatures GetEffectiveFeatures(SubscriptionPlan plan)
    {
        if (PlanOverride != null &&
            PlanOverride.IsActive() &&
            PlanOverride.FeaturesOverride != null)
        {
            return PlanOverride.FeaturesOverride;
        }

        return plan.Features;
    }

    /// <summary>
    /// Verifica se usuário tem acesso a dados em tempo real
    /// Requer plano Pleno ou Consultor (ou override ativo)
    /// </summary>
    public bool HasRealtimeDataAccess()
    {
        if (SubscriptionPlanId == null)
            return false;

        // Se tem override ativo com RealtimeData = true
        if (PlanOverride != null &&
            PlanOverride.IsActive() &&
            PlanOverride.FeaturesOverride != null &&
            PlanOverride.FeaturesOverride.RealtimeData)
        {
            return true;
        }

        // Deve carregar SubscriptionPlan para verificar (via repository)
        // Por enquanto, este método assume que já tem o plano carregado
        // No uso real: var plan = await _planRepository.GetByIdAsync(SubscriptionPlanId);
        // return GetEffectiveFeatures(plan).RealtimeData;

        return false; // Placeholder - implementar verificação com plano carregado
    }

    // Custom Trading Fees Management
    public void ConfigureCustomFees(TradingFees customFees)
    {
        if (Role != UserRole.Trader)
            throw new DomainException("Only traders can configure custom fees");

        CustomFees = customFees;

        _domainEvents.Add(new CustomFeesConfigured(
            Id,
            customFees,
            DateTime.UtcNow
        ));
    }

    public void RemoveCustomFees()
    {
        if (CustomFees == null)
            throw new DomainException("No custom fees to remove");

        CustomFees = null;

        _domainEvents.Add(new CustomFeesRemoved(
            Id,
            DateTime.UtcNow
        ));
    }

    public TradingFees GetEffectiveTradingFees(SystemConfig systemConfig)
    {
        // Se tem custom fees, retorna (com fallback para SystemConfig nos valores null)
        if (CustomFees != null)
            return CustomFees;

        // Senão, criar TradingFees baseado no SystemConfig (todos os valores)
        return new TradingFees(
            systemConfig.BrokerCommissionRate,
            systemConfig.B3EmolumentRate,
            systemConfig.SettlementFeeRate,
            systemConfig.IncomeTaxRate,
            systemConfig.DayTradeIncomeTaxRate
        );
    }
}
```

## Value Objects

```csharp
public record UserId(Guid Value)
{
    public static UserId New() => new(Guid.NewGuid());
}

public record Email(string Value)
{
    public Email
    {
        if (string.IsNullOrWhiteSpace(Value))
            throw new ArgumentException("Email cannot be empty");

        if (!Value.Contains("@"))
            throw new ArgumentException("Invalid email format");
    }
}

public record PasswordHash(string Value)
{
    public PasswordHash
    {
        if (string.IsNullOrWhiteSpace(Value))
            throw new ArgumentException("Password hash cannot be empty");
    }

    // Factory method for hashing
    public static PasswordHash FromPlainText(string plainPassword)
    {
        if (plainPassword.Length < 8)
            throw new ArgumentException("Password must be at least 8 characters");

        // TODO: Use BCrypt or similar
        var hashed = BCrypt.Net.BCrypt.HashPassword(plainPassword);
        return new PasswordHash(hashed);
    }

    public bool Verify(string plainPassword)
    {
        return BCrypt.Net.BCrypt.Verify(plainPassword, Value);
    }
}

public enum UserRole
{
    Trader,
    Moderator,
    Administrator
}

public enum RiskProfile
{
    Conservador,
    Moderado,
    Agressivo
}

public enum UserStatus
{
    Active,
    Suspended,
    Deleted
}

public record UserPlanOverride(
    int? StrategyLimitOverride,      // null = usar do plano base
    PlanFeatures? FeaturesOverride,  // null = usar do plano base
    DateTime? ExpiresAt,             // null = permanente
    string Reason,                   // "Beta Tester", "Partner", "Staff", "Trial Premium"
    UserId GrantedBy,                // Rastreabilidade - qual admin concedeu
    DateTime GrantedAt               // Timestamp da concessão
)
{
    public bool IsExpired() => ExpiresAt.HasValue && DateTime.UtcNow > ExpiresAt.Value;

    public bool IsActive() => !IsExpired();
}

public record TradingFees(
    decimal? BrokerCommissionRate,      // null = usar SystemConfig
    decimal? B3EmolumentRate,           // null = usar SystemConfig
    decimal? SettlementFeeRate,         // null = usar SystemConfig
    decimal? IncomeTaxRate,             // null = usar SystemConfig
    decimal? DayTradeIncomeTaxRate      // null = usar SystemConfig
)
{
    public TradingFees
    {
        // Validar taxas se especificadas
        if (BrokerCommissionRate.HasValue && (BrokerCommissionRate.Value < 0 || BrokerCommissionRate.Value > 1))
            throw new ArgumentException("Broker commission rate must be between 0 and 1");

        if (B3EmolumentRate.HasValue && (B3EmolumentRate.Value < 0 || B3EmolumentRate.Value > 1))
            throw new ArgumentException("B3 emolument rate must be between 0 and 1");

        if (SettlementFeeRate.HasValue && (SettlementFeeRate.Value < 0 || SettlementFeeRate.Value > 1))
            throw new ArgumentException("Settlement fee rate must be between 0 and 1");

        if (IncomeTaxRate.HasValue && (IncomeTaxRate.Value < 0 || IncomeTaxRate.Value > 1))
            throw new ArgumentException("Income tax rate must be between 0 and 1");

        if (DayTradeIncomeTaxRate.HasValue && (DayTradeIncomeTaxRate.Value < 0 || DayTradeIncomeTaxRate.Value > 1))
            throw new ArgumentException("Day-trade income tax rate must be between 0 and 1");
    }

    // Helper para pegar taxa efetiva com fallback
    public decimal GetEffectiveBrokerCommissionRate(SystemConfig config)
        => BrokerCommissionRate ?? config.BrokerCommissionRate;

    public decimal GetEffectiveB3EmolumentRate(SystemConfig config)
        => B3EmolumentRate ?? config.B3EmolumentRate;

    public decimal GetEffectiveSettlementFeeRate(SystemConfig config)
        => SettlementFeeRate ?? config.SettlementFeeRate;

    public decimal GetEffectiveIncomeTaxRate(SystemConfig config)
        => IncomeTaxRate ?? config.IncomeTaxRate;

    public decimal GetEffectiveDayTradeIncomeTaxRate(SystemConfig config)
        => DayTradeIncomeTaxRate ?? config.DayTradeIncomeTaxRate;
}
```

## Domain Events

```csharp
public record UserRegistered(
    UserId UserId,
    Email Email,
    UserRole Role,
    DateTime OccurredAt
) : IDomainEvent;

public record RiskProfileUpdated(
    UserId UserId,
    RiskProfile NewProfile,
    DateTime OccurredAt
) : IDomainEvent;

public record UserPlanUpgraded(
    UserId UserId,
    SubscriptionPlanId OldPlanId,
    SubscriptionPlanId NewPlanId,
    BillingPeriod OldBillingPeriod,
    BillingPeriod NewBillingPeriod,
    DateTime OccurredAt
) : IDomainEvent;

public record UserLoggedIn(
    UserId UserId,
    DateTime OccurredAt
) : IDomainEvent;

public record UserSuspended(
    UserId UserId,
    DateTime OccurredAt
) : IDomainEvent;

public record UserActivated(
    UserId UserId,
    DateTime OccurredAt
) : IDomainEvent;

public record UserDisplayNameUpdated(
    UserId UserId,
    string NewDisplayName,
    DateTime OccurredAt
) : IDomainEvent;

public record PlanOverrideGranted(
    UserId UserId,
    int? StrategyLimitOverride,
    PlanFeatures? FeaturesOverride,
    DateTime? ExpiresAt,
    string Reason,
    UserId GrantedBy,
    DateTime OccurredAt
) : IDomainEvent;

public record PlanOverrideRevoked(
    UserId UserId,
    UserId RevokedBy,
    DateTime OccurredAt
) : IDomainEvent;

public record CustomFeesConfigured(
    UserId UserId,
    TradingFees CustomFees,
    DateTime OccurredAt
) : IDomainEvent;

public record CustomFeesRemoved(
    UserId UserId,
    DateTime OccurredAt
) : IDomainEvent;
```

---

## 2. SubscriptionPlan (Aggregate Root)

**Responsabilidade:** Gerenciar planos de assinatura (Básico, Pleno, Consultor) e seus limites

**Invariantes (Business Rules):**
1. Name deve ser único
2. PriceMonthly deve ser >= 0 (plano Básico é gratuito)
3. PriceAnnual deve ser >= 0
4. Se PriceMonthly > 0, então PriceAnnual deve aplicar desconto (PriceAnnual < PriceMonthly * 12)
5. AnnualDiscountPercent deve estar entre 0 e 1 (0% a 100%)
6. StrategyLimit deve ser > 0
7. Plano Básico deve ter StrategyLimit = 1
8. Planos pagos (Pleno, Consultor) devem ter StrategyLimit ilimitado (ou alto, ex: 999)
9. Apenas Administrator pode configurar planos

## Entities

```csharp
// Aggregate Root
public class SubscriptionPlan : Entity<SubscriptionPlanId>
{
    // Properties
    public SubscriptionPlanId Id { get; private set; }
    public string Name { get; private set; } // Básico, Pleno, Consultor
    public Money PriceMonthly { get; private set; }
    public Money PriceAnnual { get; private set; }
    public decimal AnnualDiscountPercent { get; private set; } // ex: 0.20 = 20% desconto
    public int StrategyLimit { get; private set; }
    public PlanFeatures Features { get; private set; }
    public bool IsActive { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? UpdatedAt { get; private set; }

    // Domain Events
    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    // Private constructor for EF Core
    private SubscriptionPlan() { }

    // Factory Method
    public static SubscriptionPlan Create(
        string name,
        Money priceMonthly,
        Money priceAnnual,
        decimal annualDiscountPercent,
        int strategyLimit,
        PlanFeatures features)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new DomainException("Plan name is required");

        if (strategyLimit <= 0)
            throw new DomainException("Strategy limit must be positive");

        if (annualDiscountPercent < 0 || annualDiscountPercent > 1)
            throw new DomainException("Annual discount percent must be between 0 and 1");

        // Validar que preço anual tem desconto em relação ao mensal
        if (priceMonthly.Amount > 0)
        {
            var expectedMaxAnnual = priceMonthly.Amount * 12;
            if (priceAnnual.Amount >= expectedMaxAnnual)
                throw new DomainException("Annual price must be less than monthly price * 12");
        }

        var plan = new SubscriptionPlan
        {
            Id = SubscriptionPlanId.New(),
            Name = name,
            PriceMonthly = priceMonthly,
            PriceAnnual = priceAnnual,
            AnnualDiscountPercent = annualDiscountPercent,
            StrategyLimit = strategyLimit,
            Features = features,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        plan._domainEvents.Add(new PlanConfigured(
            plan.Id,
            plan.Name,
            plan.PriceMonthly,
            plan.PriceAnnual,
            plan.AnnualDiscountPercent,
            plan.StrategyLimit,
            DateTime.UtcNow
        ));

        return plan;
    }

    // Business Methods
    public void UpdatePricing(Money newPriceMonthly, Money newPriceAnnual, decimal newAnnualDiscountPercent)
    {
        if (newAnnualDiscountPercent < 0 || newAnnualDiscountPercent > 1)
            throw new DomainException("Annual discount percent must be between 0 and 1");

        // Validar que preço anual tem desconto em relação ao mensal
        if (newPriceMonthly.Amount > 0)
        {
            var expectedMaxAnnual = newPriceMonthly.Amount * 12;
            if (newPriceAnnual.Amount >= expectedMaxAnnual)
                throw new DomainException("Annual price must be less than monthly price * 12");
        }

        PriceMonthly = newPriceMonthly;
        PriceAnnual = newPriceAnnual;
        AnnualDiscountPercent = newAnnualDiscountPercent;
        UpdatedAt = DateTime.UtcNow;

        _domainEvents.Add(new PlanPricingUpdated(
            Id,
            newPriceMonthly,
            newPriceAnnual,
            newAnnualDiscountPercent,
            DateTime.UtcNow
        ));
    }

    public void UpdateStrategyLimit(int newLimit)
    {
        if (newLimit <= 0)
            throw new DomainException("Strategy limit must be positive");

        StrategyLimit = newLimit;
        UpdatedAt = DateTime.UtcNow;

        _domainEvents.Add(new PlanLimitsUpdated(
            Id,
            newLimit,
            DateTime.UtcNow
        ));
    }

    public void UpdateFeatures(PlanFeatures newFeatures)
    {
        Features = newFeatures;
        UpdatedAt = DateTime.UtcNow;

        _domainEvents.Add(new PlanFeaturesUpdated(
            Id,
            newFeatures,
            DateTime.UtcNow
        ));
    }

    public void Deactivate()
    {
        IsActive = false;
        UpdatedAt = DateTime.UtcNow;

        _domainEvents.Add(new PlanDeactivated(
            Id,
            DateTime.UtcNow
        ));
    }

    public void Activate()
    {
        IsActive = true;
        UpdatedAt = DateTime.UtcNow;

        _domainEvents.Add(new PlanActivated(
            Id,
            DateTime.UtcNow
        ));
    }
}
```

## Value Objects

```csharp
public record SubscriptionPlanId(Guid Value)
{
    public static SubscriptionPlanId New() => new(Guid.NewGuid());
}

public record Money(decimal Amount, string Currency)
{
    public Money
    {
        if (Amount < 0)
            throw new ArgumentException("Amount cannot be negative");

        if (string.IsNullOrWhiteSpace(Currency))
            throw new ArgumentException("Currency is required");
    }

    public static Money Brl(decimal amount) => new(amount, "BRL");
    public static Money Zero() => new(0, "BRL");
}

public enum BillingPeriod
{
    Monthly = 1,
    Annual = 12
}

public record PlanFeatures(
    bool RealtimeData,
    bool AdvancedAlerts,
    bool ConsultingTools,
    bool CommunityAccess
)
{
    // Factory methods for standard plans
    public static PlanFeatures Basico() => new(
        RealtimeData: false,
        AdvancedAlerts: false,
        ConsultingTools: false,
        CommunityAccess: true
    );

    public static PlanFeatures Pleno() => new(
        RealtimeData: true,
        AdvancedAlerts: true,
        ConsultingTools: false,
        CommunityAccess: true
    );

    public static PlanFeatures Consultor() => new(
        RealtimeData: true,
        AdvancedAlerts: true,
        ConsultingTools: true,
        CommunityAccess: true
    );
}
```

## Domain Events

```csharp
public record PlanConfigured(
    SubscriptionPlanId PlanId,
    string Name,
    Money PriceMonthly,
    Money PriceAnnual,
    decimal AnnualDiscountPercent,
    int StrategyLimit,
    DateTime OccurredAt
) : IDomainEvent;

public record PlanPricingUpdated(
    SubscriptionPlanId PlanId,
    Money NewPriceMonthly,
    Money NewPriceAnnual,
    decimal NewAnnualDiscountPercent,
    DateTime OccurredAt
) : IDomainEvent;

public record PlanLimitsUpdated(
    SubscriptionPlanId PlanId,
    int NewStrategyLimit,
    DateTime OccurredAt
) : IDomainEvent;

public record PlanFeaturesUpdated(
    SubscriptionPlanId PlanId,
    PlanFeatures NewFeatures,
    DateTime OccurredAt
) : IDomainEvent;

public record PlanDeactivated(
    SubscriptionPlanId PlanId,
    DateTime OccurredAt
) : IDomainEvent;

public record PlanActivated(
    SubscriptionPlanId PlanId,
    DateTime OccurredAt
) : IDomainEvent;
```

---

## 3. SystemConfig (Aggregate Root)

**Responsabilidade:** Gerenciar configurações globais do sistema (taxas, limites, parâmetros)

**Invariantes (Business Rules):**
1. BrokerCommissionRate deve estar entre 0 e 1 (0% a 100%)
2. B3EmolumentRate deve estar entre 0 e 1
3. SettlementFeeRate deve estar entre 0 e 1
4. IssRate deve estar entre 0 e 1
5. IncomeTaxRate deve estar entre 0 e 1
6. DayTradeIncomeTaxRate deve estar entre 0 e 1
7. MaxOpenStrategiesPerUser deve ser > 0
8. MaxStrategiesInTemplate deve ser > 0
9. Apenas Administrator pode modificar

## Entities

```csharp
// Aggregate Root
public class SystemConfig : Entity<SystemConfigId>
{
    // Properties
    public SystemConfigId Id { get; private set; }

    // Taxas Operacionais
    public decimal BrokerCommissionRate { get; private set; }     // 0.0 = 0% (maioria das corretoras)
    public decimal B3EmolumentRate { get; private set; }          // 0.000325 = 0.0325% (taxa B3)
    public decimal SettlementFeeRate { get; private set; }        // 0.000275 = 0.0275% (liquidação)
    public decimal IssRate { get; private set; }                  // 0.05 = 5% (sobre emolumentos)

    // Impostos
    public decimal IncomeTaxRate { get; private set; }            // 0.15 = 15% (IR sobre lucro swing-trade)
    public decimal DayTradeIncomeTaxRate { get; private set; }    // 0.20 = 20% (IR sobre lucro day-trade)

    // Limites do Sistema
    public int MaxOpenStrategiesPerUser { get; private set; }
    public int MaxStrategiesInTemplate { get; private set; }

    // Auditoria
    public DateTime UpdatedAt { get; private set; }
    public UserId UpdatedBy { get; private set; }

    // Domain Events
    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    // Singleton pattern (only one SystemConfig exists)
    private static readonly SystemConfigId SingletonId = new(Guid.Parse("00000000-0000-0000-0000-000000000001"));

    // Private constructor for EF Core
    private SystemConfig() { }

    // Factory Method
    public static SystemConfig CreateDefault()
    {
        var config = new SystemConfig
        {
            Id = SingletonId,

            // Taxas Operacionais (valores típicos do mercado brasileiro)
            BrokerCommissionRate = 0.0m,        // 0% - maioria das corretoras tem corretagem zero
            B3EmolumentRate = 0.000325m,        // 0.0325% - taxa B3
            SettlementFeeRate = 0.000275m,      // 0.0275% - taxa de liquidação
            IssRate = 0.05m,                    // 5% sobre emolumentos - ISS

            // Impostos (legislação brasileira)
            IncomeTaxRate = 0.15m,              // 15% - IR sobre lucro em swing-trade
            DayTradeIncomeTaxRate = 0.20m,      // 20% - IR sobre lucro em day-trade

            // Limites do Sistema
            MaxOpenStrategiesPerUser = 100,
            MaxStrategiesInTemplate = 10,

            // Auditoria
            UpdatedAt = DateTime.UtcNow,
            UpdatedBy = UserId.New() // System
        };

        config._domainEvents.Add(new SystemConfigInitialized(
            config.Id,
            DateTime.UtcNow
        ));

        return config;
    }

    // Business Methods - Atualização de Taxas Operacionais
    public void UpdateBrokerCommissionRate(decimal newRate, UserId adminId)
    {
        if (newRate < 0 || newRate > 1)
            throw new DomainException("Broker commission rate must be between 0 and 1");

        BrokerCommissionRate = newRate;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = adminId;

        _domainEvents.Add(new SystemParametersUpdated(
            Id,
            nameof(BrokerCommissionRate),
            newRate.ToString(),
            adminId,
            DateTime.UtcNow
        ));
    }

    public void UpdateB3EmolumentRate(decimal newRate, UserId adminId)
    {
        if (newRate < 0 || newRate > 1)
            throw new DomainException("B3 emolument rate must be between 0 and 1");

        B3EmolumentRate = newRate;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = adminId;

        _domainEvents.Add(new SystemParametersUpdated(
            Id,
            nameof(B3EmolumentRate),
            newRate.ToString(),
            adminId,
            DateTime.UtcNow
        ));
    }

    public void UpdateSettlementFeeRate(decimal newRate, UserId adminId)
    {
        if (newRate < 0 || newRate > 1)
            throw new DomainException("Settlement fee rate must be between 0 and 1");

        SettlementFeeRate = newRate;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = adminId;

        _domainEvents.Add(new SystemParametersUpdated(
            Id,
            nameof(SettlementFeeRate),
            newRate.ToString(),
            adminId,
            DateTime.UtcNow
        ));
    }

    public void UpdateIssRate(decimal newRate, UserId adminId)
    {
        if (newRate < 0 || newRate > 1)
            throw new DomainException("ISS rate must be between 0 and 1");

        IssRate = newRate;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = adminId;

        _domainEvents.Add(new SystemParametersUpdated(
            Id,
            nameof(IssRate),
            newRate.ToString(),
            adminId,
            DateTime.UtcNow
        ));
    }

    // Business Methods - Atualização de Impostos
    public void UpdateIncomeTaxRate(decimal newRate, UserId adminId)
    {
        if (newRate < 0 || newRate > 1)
            throw new DomainException("Income tax rate must be between 0 and 1");

        IncomeTaxRate = newRate;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = adminId;

        _domainEvents.Add(new SystemParametersUpdated(
            Id,
            nameof(IncomeTaxRate),
            newRate.ToString(),
            adminId,
            DateTime.UtcNow
        ));
    }

    public void UpdateDayTradeIncomeTaxRate(decimal newRate, UserId adminId)
    {
        if (newRate < 0 || newRate > 1)
            throw new DomainException("Day-trade income tax rate must be between 0 and 1");

        DayTradeIncomeTaxRate = newRate;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = adminId;

        _domainEvents.Add(new SystemParametersUpdated(
            Id,
            nameof(DayTradeIncomeTaxRate),
            newRate.ToString(),
            adminId,
            DateTime.UtcNow
        ));
    }

    // Business Methods - Atualização de Limites
    public void UpdateMaxOpenStrategies(int newMax, UserId adminId)
    {
        if (newMax <= 0)
            throw new DomainException("Max open strategies must be positive");

        MaxOpenStrategiesPerUser = newMax;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = adminId;

        _domainEvents.Add(new SystemParametersUpdated(
            Id,
            nameof(MaxOpenStrategiesPerUser),
            newMax.ToString(),
            adminId,
            DateTime.UtcNow
        ));
    }

    public void UpdateMaxStrategiesInTemplate(int newMax, UserId adminId)
    {
        if (newMax <= 0)
            throw new DomainException("Max strategies in template must be positive");

        MaxStrategiesInTemplate = newMax;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = adminId;

        _domainEvents.Add(new SystemParametersUpdated(
            Id,
            nameof(MaxStrategiesInTemplate),
            newMax.ToString(),
            adminId,
            DateTime.UtcNow
        ));
    }
}
```

## Value Objects

```csharp
public record SystemConfigId(Guid Value);
```

## Domain Events

```csharp
public record SystemConfigInitialized(
    SystemConfigId ConfigId,
    DateTime OccurredAt
) : IDomainEvent;

public record SystemParametersUpdated(
    SystemConfigId ConfigId,
    string ParameterName,
    string NewValue,
    UserId UpdatedBy,
    DateTime OccurredAt
) : IDomainEvent;
```

---

#### Repository Interface

```csharp
public interface IUserRepository
{
    Task<User> GetByIdAsync(UserId id, CancellationToken ct);
    Task<User?> GetByEmailAsync(Email email, CancellationToken ct);
    Task<IEnumerable<User>> GetByRoleAsync(UserRole role, CancellationToken ct);
    Task AddAsync(User user, CancellationToken ct);
    Task UpdateAsync(User user, CancellationToken ct);
}

public interface ISubscriptionPlanRepository
{
    Task<SubscriptionPlan> GetByIdAsync(SubscriptionPlanId id, CancellationToken ct);
    Task<SubscriptionPlan?> GetByNameAsync(string name, CancellationToken ct);
    Task<IEnumerable<SubscriptionPlan>> GetActiveAsync(CancellationToken ct);
    Task AddAsync(SubscriptionPlan plan, CancellationToken ct);
    Task UpdateAsync(SubscriptionPlan plan, CancellationToken ct);
}

public interface ISystemConfigRepository
{
    Task<SystemConfig> GetAsync(CancellationToken ct);
    Task UpdateAsync(SystemConfig config, CancellationToken ct);
}
```

**Queries Esperadas pelo DBA:**
1. `User.GetByEmailAsync` → Unique Index em Email
2. `User.GetByRoleAsync` → Index em Role
3. `SubscriptionPlan.GetByNameAsync` → Unique Index em Name
4. `SubscriptionPlan.GetActiveAsync` → Index em IsActive
5. `SystemConfig.GetAsync` → PK em Id (singleton)

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

#### Repository Interface

```csharp
public interface IStrategyTemplateRepository
{
    Task<StrategyTemplate> GetByIdAsync(StrategyTemplateId id, CancellationToken ct);
    Task<IEnumerable<StrategyTemplate>> GetGlobalTemplatesAsync(CancellationToken ct);
    Task<IEnumerable<StrategyTemplate>> GetPersonalTemplatesAsync(UserId ownerId, CancellationToken ct);
    Task AddAsync(StrategyTemplate template, CancellationToken ct);
    Task UpdateAsync(StrategyTemplate template, CancellationToken ct);
}

public interface IStrategyRepository
{
    Task<Strategy> GetByIdAsync(StrategyId id, CancellationToken ct);
    Task<IEnumerable<Strategy>> GetByOwnerAsync(UserId ownerId, CancellationToken ct);
    Task<int> CountActiveByOwnerAsync(UserId ownerId, CancellationToken ct);
    Task AddAsync(Strategy strategy, CancellationToken ct);
    Task UpdateAsync(Strategy strategy, CancellationToken ct);
}
```

**Queries Esperadas pelo DBA:**
1. `StrategyTemplate.GetGlobalTemplatesAsync` → Index em Visibility
2. `StrategyTemplate.GetPersonalTemplatesAsync` → Composite Index em (OwnerId, Visibility)
3. `Strategy.GetByOwnerAsync` → Index em OwnerId
4. `Strategy.CountActiveByOwnerAsync` → Composite Index em (OwnerId, Status)

---

# Market Data

## Aggregates

## 6. OptionContract (Aggregate Root)

**Responsabilidade:** Gerenciar dados de contratos de opções da B3 (preços, Greeks, ajustes de strike)

**Invariantes (Business Rules):**
1. Symbol deve ser único
2. Put options DEVEM ser European style (regra B3)
3. Call options podem ser American ou European
4. CurrentStrike deve ser > 0
5. OriginalStrike nunca muda (imutável)
6. CurrentStrike pode ser ajustado por dividendos
7. ContractMultiplier deve ser > 0 (padrão: 100 para ações, 1 para BOVA11)
8. BidPrice <= AskPrice (quando ambos presentes)
9. Expiration deve ser futura (para opções Active)
10. Series deve ser definida (W1-W5, onde W3 = mensal padrão na 3ª segunda-feira do mês)

## Entities

```csharp
// Aggregate Root
public class OptionContract : Entity<OptionContractId>
{
    // ========================================
    // IDENTITY
    // ========================================
    public OptionContractId Id { get; private set; }
    public string Symbol { get; private set; }  // PETRH245 (código B3)

    // ========================================
    // CARACTERÍSTICAS DA OPÇÃO
    // ========================================
    public Ticker UnderlyingAsset { get; private set; }  // PETR4
    public OptionType Type { get; private set; }         // Call/Put
    public ExerciseType ExerciseType { get; private set; } // American/European
    public OptionSeries Series { get; private set; }     // W1-W5 (W3 = mensal padrão)

    // Strike
    public Money OriginalStrike { get; private set; }    // Strike na emissão
    public Money CurrentStrike { get; private set; }     // Strike atual (ajustado por dividendos)

    // Vencimento
    public DateTime Expiration { get; private set; }

    // Contrato
    public int ContractMultiplier { get; private set; }  // 100 (ações), 1 (BOVA)

    // ========================================
    // PREÇOS DE MERCADO (Snapshot Atual)
    // ========================================
    public Money? BidPrice { get; private set; }         // Maior compra
    public Money? AskPrice { get; private set; }         // Menor venda
    public Money? LastPrice { get; private set; }        // Último negócio
    public DateTime? LastTradeTime { get; private set; } // Hora do último negócio

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
    // HISTÓRICO DE AJUSTES (Child Entities)
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

        // Regra da B3: Puts devem ser européias
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
    /// Atualiza preços de mercado (bid/ask/last)
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
    /// Marca opção como expirada
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
    /// Verifica se opção está líquida (spread < 5%)
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
    European    // Só pode exercer no vencimento
}

public enum OptionStatus
{
    Active,      // Negociando normalmente
    Suspended,   // Suspenso pela B3
    Expired,     // Vencido
    Exercised    // Exercido (futuro - para tracking)
}

/// <summary>
/// Representa a série semanal de uma opção.
/// Nomenclatura unificada: W1-W5 (onde W3 = mensal padrão = 3ª segunda-feira)
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
    public static OptionSeries MonthlyStandard() => new(3, true);  // W3 = 3ª segunda-feira
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
    int SymbolCount,  // Quantos símbolos estão sendo monitorados
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
    int SubscriberCount  // Quantos clientes estão recebendo este update
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

## 7. UnderlyingAsset (Aggregate Root)

**Responsabilidade:** Gerenciar dados do ativo subjacente (ação-objeto da opção)

**Invariantes (Business Rules):**
1. Symbol (Ticker) deve ser único
2. Name não pode ser vazio
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

#### Domain Services

```csharp
/// <summary>
/// Black-Scholes pricing model para opções europeias
/// NOTA: Para opções americanas (algumas calls), usar modelo binomial (EPIC-02)
/// </summary>
public interface IBlackScholesService
{
    /// <summary>
    /// Calcula preço teórico de opção europeia
    /// </summary>
    Money CalculateTheoreticalPrice(
        Money spot,
        Money strike,
        decimal timeToExpiration, // em anos
        decimal riskFreeRate,
        decimal impliedVolatility,
        OptionType type);

    /// <summary>
    /// Calcula IV por inversão numérica (Newton-Raphson)
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
    /// Calcula Greeks para opção europeia
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
/// Domain Service para calcular a série semanal (W1-W5) de uma opção baseado na data de vencimento
/// </summary>
public interface IWeeklySeriesCalculator
{
    /// <summary>
    /// Calcula a série semanal baseado na data de vencimento
    /// W1 = 1ª segunda-feira do mês
    /// W2 = 2ª segunda-feira do mês
    /// W3 = 3ª segunda-feira do mês (MENSAL PADRÃO)
    /// W4 = 4ª segunda-feira do mês
    /// W5 = 5ª segunda-feira do mês (quando existe)
    /// </summary>
    OptionSeries CalculateSeries(DateTime expirationDate);

    /// <summary>
    /// Verifica se uma data é a 3ª segunda-feira do mês (mensal padrão da B3)
    /// </summary>
    bool IsMonthlyStandard(DateTime date);

    /// <summary>
    /// Calcula qual a N-ésima segunda-feira do mês (1-5)
    /// </summary>
    int GetMondayWeekOfMonth(DateTime date);
}

/// <summary>
/// Domain Service para gerenciar throttling e cache de updates de preços em tempo real
/// Evita sobrecarga de updates e garante performance
/// </summary>
public interface IMarketDataStreamService
{
    /// <summary>
    /// Verifica se deve processar um update de preço (throttling)
    /// Regra: máximo 1 update por símbolo a cada N segundos
    /// </summary>
    bool ShouldProcessPriceUpdate(string symbol, DateTime updateTime);

    /// <summary>
    /// Registra que um update foi processado (para throttling)
    /// </summary>
    void RecordPriceUpdate(string symbol, DateTime updateTime);

    /// <summary>
    /// Obtém último preço conhecido do cache (para evitar updates desnecessários)
    /// </summary>
    Money? GetCachedPrice(string symbol);

    /// <summary>
    /// Atualiza cache de preço
    /// </summary>
    void UpdateCachedPrice(string symbol, Money price);

    /// <summary>
    /// Verifica se mudança de preço é significativa (> threshold)
    /// Evita broadcast de mudanças insignificantes (< 0.1%)
    /// </summary>
    bool IsPriceChangeSignificant(Money oldPrice, Money newPrice, decimal thresholdPercentage = 0.1m);
}
```

---

#### Repository Interface

```csharp
public interface IOptionContractRepository
{
    Task<OptionContract> GetByIdAsync(OptionContractId id, CancellationToken ct);
    Task<OptionContract?> GetBySymbolAsync(string symbol, CancellationToken ct);

    // Lista de opções disponíveis (CRITICAL para UI)
    Task<IEnumerable<OptionContract>> GetAvailableOptionsAsync(
        Ticker underlyingAsset,
        OptionType? typeFilter = null,           // Call/Put
        ExerciseType? exerciseTypeFilter = null, // American/European
        int[]? weekNumbers = null,               // W1-W5 filter (null = todas)
        bool? monthlyStandardOnly = null,        // true = apenas W3 mensal, false = apenas semanais não-mensais, null = todas
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

    // Buscar opções próximas do vencimento
    Task<IEnumerable<OptionContract>> GetExpiringOptionsAsync(
        int daysUntilExpiration,
        CancellationToken ct);

    // Buscar opções líquidas
    Task<IEnumerable<OptionContract>> GetLiquidOptionsAsync(
        Ticker underlyingAsset,
        decimal maxSpreadPercentage = 5m,
        CancellationToken ct = default);

    // Buscar opções que deveriam estar expiradas (para sync job)
    Task<IEnumerable<OptionContract>> GetExpiredActiveOptionsAsync(
        DateTime referenceDate,
        CancellationToken ct);

    Task AddAsync(OptionContract option, CancellationToken ct);
    Task UpdateAsync(OptionContract option, CancellationToken ct);

    // Bulk upsert para performance em sync jobs (cria se não existe, atualiza se existe)
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
4. `OptionContract.GetLiquidOptionsAsync` → Index em (UnderlyingAsset, Status) + cálculo de spread
5. `UnderlyingAsset.GetBySymbolAsync` → Unique Index em Symbol

**Exemplos de Filtros de Opções Semanais:**
```csharp
// Buscar apenas opções mensais (W3)
var monthlyOptions = await repo.GetAvailableOptionsAsync(
    ticker, monthlyStandardOnly: true);

// Buscar apenas semanais não-mensais (W1, W2, W4, W5)
var weeklyOptions = await repo.GetAvailableOptionsAsync(
    ticker, monthlyStandardOnly: false);

// Buscar W1 e W2 especificamente
var earlyWeekOptions = await repo.GetAvailableOptionsAsync(
    ticker, weekNumbers: new[] { 1, 2 });

// Buscar todas (mensal + semanais)
var allOptions = await repo.GetAvailableOptionsAsync(ticker);
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

### UC-Admin-01: Configure Subscription Plan

**Actor:** Administrator
**Trigger:** Admin acessa painel de configuração de planos
**Bounded Context:** User Management

**Fluxo:**

```csharp
public class ConfigurePlanHandler : IRequestHandler<ConfigurePlanCommand, Result<SubscriptionPlanId>>
{
    private readonly ISubscriptionPlanRepository _planRepository;
    private readonly IUserRepository _userRepository;
    private readonly IDomainEventDispatcher _eventDispatcher;

    public async Task<Result<SubscriptionPlanId>> Handle(ConfigurePlanCommand command, CancellationToken ct)
    {
        // 1. Validar que usuário é Administrator
        var admin = await _userRepository.GetByIdAsync(command.AdminId, ct);
        if (admin.Role != UserRole.Administrator)
            throw new UnauthorizedException("Only administrators can configure plans");

        // 2. Validar que plano com mesmo nome não existe
        var existing = await _planRepository.GetByNameAsync(command.Name, ct);
        if (existing != null)
            throw new DomainException("Plan with this name already exists");

        // 3. Criar plano
        var plan = SubscriptionPlan.Create(
            command.Name,
            Money.Brl(command.PriceMonthly),
            command.StrategyLimit,
            command.Features
        );

        // 4. Persistir
        await _planRepository.AddAsync(plan, ct);

        // 5. Dispatch domain events
        foreach (var @event in plan.DomainEvents)
        {
            await _eventDispatcher.DispatchAsync(@event, ct);
        }

        // 6. Retornar resultado
        return Result<SubscriptionPlanId>.Success(plan.Id);
    }
}

public record ConfigurePlanCommand(
    UserId AdminId,
    string Name,
    decimal PriceMonthly,
    int StrategyLimit,
    PlanFeatures Features
) : IRequest<Result<SubscriptionPlanId>>;
```

**Aggregates Envolvidos:**
- User (read-only - verificar admin)
- SubscriptionPlan (modify - criar plano)

**Domain Events Gerados:**
- `PlanConfigured`

---

### UC-Admin-02: Update System Parameters

**Actor:** Administrator
**Trigger:** Admin atualiza taxas ou limites globais
**Bounded Context:** User Management

**Fluxo:**

```csharp
public class UpdateSystemParametersHandler : IRequestHandler<UpdateSystemParametersCommand, Result>
{
    private readonly ISystemConfigRepository _configRepository;
    private readonly IUserRepository _userRepository;
    private readonly IDomainEventDispatcher _eventDispatcher;

    public async Task<Result> Handle(UpdateSystemParametersCommand command, CancellationToken ct)
    {
        // 1. Validar que usuário é Administrator
        var admin = await _userRepository.GetByIdAsync(command.AdminId, ct);
        if (admin.Role != UserRole.Administrator)
            throw new UnauthorizedException("Only administrators can update system parameters");

        // 2. Carregar configuração (singleton)
        var config = await _configRepository.GetAsync(ct);

        // 3. Atualizar parâmetros conforme solicitado
        if (command.CommissionRate.HasValue)
            config.UpdateCommissionRate(command.CommissionRate.Value, command.AdminId);

        if (command.TaxRate.HasValue)
            config.UpdateTaxRate(command.TaxRate.Value, command.AdminId);

        if (command.MaxOpenStrategies.HasValue)
            config.UpdateMaxOpenStrategies(command.MaxOpenStrategies.Value, command.AdminId);

        // 4. Persistir
        await _configRepository.UpdateAsync(config, ct);

        // 5. Dispatch domain events
        foreach (var @event in config.DomainEvents)
        {
            await _eventDispatcher.DispatchAsync(@event, ct);
        }

        // 6. Retornar resultado
        return Result.Success();
    }
}

public record UpdateSystemParametersCommand(
    UserId AdminId,
    decimal? CommissionRate,
    decimal? TaxRate,
    int? MaxOpenStrategies
) : IRequest<Result>;
```

**Aggregates Envolvidos:**
- User (read-only - verificar admin)
- SystemConfig (modify - atualizar parâmetros)

**Domain Events Gerados:**
- `SystemParametersUpdated`

---

### UC-Admin-03: Grant Plan Override

**Actor:** Administrator
**Trigger:** Admin concede acesso especial (VIP, trial, beta tester, etc.)
**Bounded Context:** User Management

**Fluxo:**

```csharp
public class GrantPlanOverrideHandler : IRequestHandler<GrantPlanOverrideCommand, Result>
{
    private readonly IUserRepository _userRepository;
    private readonly IDomainEventDispatcher _eventDispatcher;

    public async Task<Result> Handle(GrantPlanOverrideCommand command, CancellationToken ct)
    {
        // 1. Validar que quem está concedendo é admin
        var admin = await _userRepository.GetByIdAsync(command.AdminId, ct);
        if (admin.Role != UserRole.Administrator)
            throw new UnauthorizedException("Only administrators can grant plan overrides");

        // 2. Buscar trader
        var trader = await _userRepository.GetByIdAsync(command.TraderId, ct);
        if (trader == null)
            throw new DomainException("Trader not found");

        // 3. Conceder override
        trader.GrantPlanOverride(
            command.StrategyLimitOverride,
            command.FeaturesOverride,
            command.ExpiresAt,
            command.Reason,
            command.AdminId
        );

        // 4. Persistir
        await _userRepository.UpdateAsync(trader, ct);

        // 5. Dispatch domain events
        foreach (var @event in trader.DomainEvents)
        {
            await _eventDispatcher.DispatchAsync(@event, ct);
        }

        // 6. Retornar resultado
        return Result.Success();
    }
}

public record GrantPlanOverrideCommand(
    UserId AdminId,
    UserId TraderId,
    int? StrategyLimitOverride,
    PlanFeatures? FeaturesOverride,
    DateTime? ExpiresAt,
    string Reason
) : IRequest<Result>;
```

**Aggregates Envolvidos:**
- User (read-only - verificar admin)
- User (modify - aplicar override no trader)

**Domain Events Gerados:**
- `PlanOverrideGranted`

**Exemplos de Uso:**
- Beta Tester: 30 dias com limite de 50 estratégias
- Influencer: Permanente com todas as features
- Trial Premium: 15 dias com features do plano Consultor
- Staff: Permanente com limite ilimitado

---

### UC-Admin-04: Revoke Plan Override

**Actor:** Administrator
**Trigger:** Admin revoga acesso especial (trial expirado, violação de termos, etc.)
**Bounded Context:** User Management

**Fluxo:**

```csharp
public class RevokePlanOverrideHandler : IRequestHandler<RevokePlanOverrideCommand, Result>
{
    private readonly IUserRepository _userRepository;
    private readonly IDomainEventDispatcher _eventDispatcher;

    public async Task<Result> Handle(RevokePlanOverrideCommand command, CancellationToken ct)
    {
        // 1. Validar que quem está revogando é admin
        var admin = await _userRepository.GetByIdAsync(command.AdminId, ct);
        if (admin.Role != UserRole.Administrator)
            throw new UnauthorizedException("Only administrators can revoke plan overrides");

        // 2. Buscar trader
        var trader = await _userRepository.GetByIdAsync(command.TraderId, ct);
        if (trader == null)
            throw new DomainException("Trader not found");

        // 3. Revogar override
        trader.RevokePlanOverride(command.AdminId);

        // 4. Persistir
        await _userRepository.UpdateAsync(trader, ct);

        // 5. Dispatch domain events
        foreach (var @event in trader.DomainEvents)
        {
            await _eventDispatcher.DispatchAsync(@event, ct);
        }

        // 6. Retornar resultado
        return Result.Success();
    }
}

public record RevokePlanOverrideCommand(
    UserId AdminId,
    UserId TraderId
) : IRequest<Result>;
```

**Aggregates Envolvidos:**
- User (read-only - verificar admin)
- User (modify - remover override do trader)

**Domain Events Gerados:**
- `PlanOverrideRevoked`

---

### UC-User-01: Register Trader

**Actor:** Trader (novo usuário)
**Trigger:** Usuário acessa página de cadastro
**Bounded Context:** User Management

**Fluxo:**

```csharp
public class RegisterTraderHandler : IRequestHandler<RegisterTraderCommand, Result<UserId>>
{
    private readonly IUserRepository _userRepository;
    private readonly ISubscriptionPlanRepository _planRepository;
    private readonly IDomainEventDispatcher _eventDispatcher;

    public async Task<Result<UserId>> Handle(RegisterTraderCommand command, CancellationToken ct)
    {
        // 1. Validar que email não existe
        var email = new Email(command.Email);
        var existing = await _userRepository.GetByEmailAsync(email, ct);
        if (existing != null)
            throw new DomainException("Email already registered");

        // 2. Validar que plano existe
        var plan = await _planRepository.GetByIdAsync(command.PlanId, ct);
        if (plan == null)
            throw new DomainException("Invalid subscription plan");

        // 3. Criar usuário
        var password = PasswordHash.FromPlainText(command.Password);
        var user = User.CreateTrader(
            email,
            password,
            command.FullName,
            command.DisplayName,
            command.RiskProfile,
            command.PlanId
        );

        // 4. Persistir
        await _userRepository.AddAsync(user, ct);

        // 5. Dispatch domain events
        foreach (var @event in user.DomainEvents)
        {
            await _eventDispatcher.DispatchAsync(@event, ct);
        }

        // 6. Retornar resultado
        return Result<UserId>.Success(user.Id);
    }
}

public record RegisterTraderCommand(
    string Email,
    string Password,
    string FullName,
    string DisplayName,
    RiskProfile RiskProfile,
    SubscriptionPlanId PlanId
) : IRequest<Result<UserId>>;
```

**Aggregates Envolvidos:**
- User (modify - criar trader)
- SubscriptionPlan (read-only - validar plano existe)

**Domain Events Gerados:**
- `UserRegistered`

---

### UC-User-02: Login

**Actor:** User (Trader, Admin, Moderator)
**Trigger:** Usuário acessa página de login
**Bounded Context:** User Management

**Fluxo:**

```csharp
public class LoginHandler : IRequestHandler<LoginCommand, Result<LoginResult>>
{
    private readonly IUserRepository _userRepository;
    private readonly IJwtTokenGenerator _tokenGenerator;
    private readonly IDomainEventDispatcher _eventDispatcher;

    public async Task<Result<LoginResult>> Handle(LoginCommand command, CancellationToken ct)
    {
        // 1. Buscar usuário por email
        var email = new Email(command.Email);
        var user = await _userRepository.GetByEmailAsync(email, ct);
        if (user == null)
            throw new UnauthorizedException("Invalid credentials");

        // 2. Verificar senha
        if (!user.Password.Verify(command.Password))
            throw new UnauthorizedException("Invalid credentials");

        // 3. Verificar status
        if (user.Status != UserStatus.Active)
            throw new UnauthorizedException("User account is not active");

        // 4. Registrar login
        user.RecordLogin();
        await _userRepository.UpdateAsync(user, ct);

        // 5. Gerar JWT token
        var token = _tokenGenerator.Generate(user.Id, user.Email, user.Role);

        // 6. Dispatch domain events
        foreach (var @event in user.DomainEvents)
        {
            await _eventDispatcher.DispatchAsync(@event, ct);
        }

        // 7. Retornar resultado
        return Result<LoginResult>.Success(new LoginResult(
            user.Id,
            user.Email.Value,
            user.FullName,
            user.Role,
            token
        ));
    }
}

public record LoginCommand(
    string Email,
    string Password
) : IRequest<Result<LoginResult>>;

public record LoginResult(
    UserId UserId,
    string Email,
    string FullName,
    UserRole Role,
    string Token
);
```

**Aggregates Envolvidos:**
- User (modify - record login)

**Domain Events Gerados:**
- `UserLoggedIn`

---

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

### UC-MarketData-01: Sync Options from B3

**Actor:** System (Background Job / Scheduled Task)
**Trigger:** Scheduled task (daily at 19h30 after market closes) ou trigger manual por admin
**Bounded Context:** Market Data

**Objetivo:** Sincronizar lista de opções da B3, identificando novas séries (incluindo semanais W1-W5), atualizando preços/Greeks de existentes, e marcando expiradas automaticamente.

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

        // 1. Publicar evento de início
        await _eventDispatcher.DispatchAsync(
            new OptionsDataSyncStarted(startTime, command.Source), ct);

        try
        {
            // 2. Buscar todas as opções da B3 API
            var b3Options = await _b3ApiClient.GetAllListedOptionsAsync(ct);
            _logger.LogInformation("Fetched {Count} options from B3 API", b3Options.Count());

            // 3. Processar cada opção da B3
            foreach (var b3Option in b3Options)
            {
                try
                {
                    // Calcular série semanal (W1-W5) usando Domain Service
                    var series = _weeklySeriesCalculator.CalculateSeries(b3Option.ExpirationDate);

                    // Verificar se opção já existe no banco
                    var existing = await _optionRepository.GetBySymbolAsync(b3Option.Symbol, ct);

                    if (existing == null)
                    {
                        // CRIAR NOVA OPÇÃO
                        var option = OptionContract.Create(
                            b3Option.Symbol,
                            Ticker.From(b3Option.UnderlyingTicker),
                            MapOptionType(b3Option.OptionType),
                            MapExerciseType(b3Option.ExerciseType),
                            series,  // <-- Série W1-W5 calculada
                            Money.Brl(b3Option.StrikePrice),
                            b3Option.ExpirationDate,
                            b3Option.ContractSize
                        );

                        // Atualizar preços de mercado
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

                        // Atualizar Greeks se disponíveis
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
                        // ATUALIZAR OPÇÃO EXISTENTE
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

                    // Dispatch events para novas opções criadas
                    foreach (var domainEvent in (existing ?? option).DomainEvents)
                    {
                        await _eventDispatcher.DispatchAsync(domainEvent, ct);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing option {Symbol}", b3Option.Symbol);
                    // Continuar processando outras opções
                }
            }

            // 4. Marcar opções expiradas
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

            // 5. Publicar evento de conclusão
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
- OptionContract (create/modify - novas opções, atualizar preços/Greeks, expirar)
- UnderlyingAsset (read-only - validar ticker)

**Domain Events Gerados:**
- `OptionsDataSyncStarted` - início do processo
- `OptionContractCreated` - para cada nova opção descoberta
- `OptionMarketPricesUpdated` - para cada opção atualizada
- `OptionGreeksUpdated` - quando Greeks atualizados
- `OptionExpired` - para cada opção expirada automaticamente
- `OptionsDataSyncCompleted` - conclusão com estatísticas

**Domain Services Utilizados:**
- `IWeeklySeriesCalculator` - calcular W1-W5 baseado na data de vencimento

**External Services:**
- `IB3ApiClient` - buscar dados da B3 API (Infrastructure Layer)

**Scheduled Job Configuration:**
```csharp
// Infrastructure/Jobs/OptionsSync Job.cs
public class OptionsSyncJob : IHostedService
{
    private readonly IMediator _mediator;
    private readonly ILogger<OptionsSyncJob> _logger;
    private Timer? _timer;

    public Task StartAsync(CancellationToken ct)
    {
        _logger.LogInformation("Options Sync Job started");

        // Executar diariamente às 19h30 (30min após fechamento do mercado às 19h)
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

    // Outros métodos...
}
```

---

### UC-MarketData-02: Stream Real-Time Market Data

**Actor:** System (Background Service) + Trader (via SignalR client)
**Trigger:** Trader conecta ao SignalR Hub e subscreve símbolos de interesse
**Bounded Context:** Market Data

**Objetivo:** Fornecer preços em tempo real de opções e ativos subjacentes para traders com plano Pleno/Consultor, usando WebSocket/SignalR para baixa latência.

**Pré-requisitos:**
- User deve ter `RealtimeData: true` no plano (Pleno ou Consultor)
- Market Data Feed Service deve estar conectado à B3
- Horário de mercado (9h-18h em dias úteis)

**Fluxo:**

```csharp
// ============================================
// SIGNALR HUB (Frontend conecta aqui)
// ============================================

/// <summary>
/// SignalR Hub para distribuição de preços em tempo real
/// Clientes se conectam via WebSocket e subscrevem símbolos
/// </summary>
public class MarketDataHub : Hub
{
    private readonly IUserRepository _userRepository;
    private readonly IMarketDataStreamService _streamService;
    private readonly IDomainEventDispatcher _eventDispatcher;
    private readonly ILogger<MarketDataHub> _logger;

    // Grupos SignalR por símbolo (ex: grupo "PETRH245" contém todos os traders subscrevendo esta opção)
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
    /// Cliente subscreve para receber updates de um símbolo
    /// </summary>
    public async Task<SubscribeResult> SubscribeToSymbol(string symbol)
    {
        var userId = Context.User?.FindFirst("sub")?.Value;
        if (string.IsNullOrEmpty(userId))
            return SubscribeResult.Unauthorized("User not authenticated");

        try
        {
            // 1. Validar plano do usuário
            var user = await _userRepository.GetByIdAsync(UserId.From(userId), CancellationToken.None);
            if (user == null)
                return SubscribeResult.Unauthorized("User not found");

            var hasRealtimeAccess = user.HasRealtimeDataAccess(); // verifica SubscriptionPlan.Features.RealtimeData
            if (!hasRealtimeAccess)
                return SubscribeResult.Forbidden("Your plan does not include real-time data. Upgrade to Pleno or Consultor.");

            // 2. Adicionar ao grupo SignalR do símbolo
            await Groups.AddToGroupAsync(Context.ConnectionId, GetSymbolGroup(symbol));

            // 3. Publicar evento de domain
            await _eventDispatcher.DispatchAsync(
                new UserSubscribedToSymbol(user.Id, symbol, DateTime.UtcNow),
                CancellationToken.None);

            // 4. Enviar último preço conhecido (cache) imediatamente
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
    /// Cliente remove subscrição de um símbolo
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
/// preços em tempo real via SignalR para traders conectados
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

            // 3. Subscrever símbolos de estratégias ativas
            var activeSymbols = await GetActiveStrategySymbolsAsync(stoppingToken);
            await _feedClient.SubscribeToSymbolsAsync(activeSymbols, stoppingToken);
            _subscribedSymbols.UnionWith(activeSymbols);

            _logger.LogInformation("Subscribed to {Count} symbols", activeSymbols.Count);

            // Publicar evento de início
            await _eventDispatcher.DispatchAsync(
                new MarketDataStreamStarted(
                    DateTime.UtcNow,
                    _subscribedSymbols.Count,
                    "B3_WEBSOCKET"
                ),
                stoppingToken);

            // 4. Manter serviço rodando até fechamento do mercado (18h) ou cancelamento
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
            // 1. Aplicar throttling (max 1 update/segundo por símbolo)
            if (!_streamService.ShouldProcessPriceUpdate(update.Symbol, update.Timestamp))
            {
                _logger.LogTrace("Throttled price update for {Symbol}", update.Symbol);
                return;
            }

            // 2. Verificar se mudança é significativa (> 0.1%)
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

            // 5. Broadcast via SignalR para grupo do símbolo
            var changePercentage = cachedPrice != null
                ? ((newPrice.Amount - cachedPrice.Amount) / cachedPrice.Amount) * 100
                : 0;

            var subscriberCount = GetSubscriberCount(update.Symbol); // implementar contagem de conexões no grupo

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
        // IMarketDataFeedClient deve ter reconexão automática
    }

    private void HandleReconnected(object? sender, EventArgs e)
    {
        _logger.LogInformation("Market data feed reconnected");

        // Re-subscrever símbolos
        Task.Run(async () =>
        {
            await _feedClient.SubscribeToSymbolsAsync(_subscribedSymbols, CancellationToken.None);
        });
    }

    private async Task<List<string>> GetActiveStrategySymbolsAsync(CancellationToken ct)
    {
        // Buscar todas estratégias ativas (PaperTrading + Live)
        // Extrair símbolos de opções + ativos subjacentes
        // Retornar lista única

        // Implementação simplificada (deve usar repository query)
        var symbols = new List<string> { "PETR4", "VALE3", "PETRH245", "VALEH205" };
        return symbols;
    }

    private bool IsMarketOpen()
    {
        var now = DateTime.Now;

        // Verificar se é dia útil (segunda a sexta)
        if (now.DayOfWeek == DayOfWeek.Saturday || now.DayOfWeek == DayOfWeek.Sunday)
            return false;

        // Verificar horário (9h às 18h)
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
        // Implementar usando IHubContext para contar conexões no grupo
        // Por enquanto, retornar 0
        return 0;
    }
}
```

**Aggregates Envolvidos:**
- User (read-only - validar RealtimeData feature flag)
- OptionContract (modify - atualizar preços em tempo real)
- UnderlyingAsset (modify - atualizar preços em tempo real)

**Domain Events Gerados:**
- `MarketDataStreamStarted` - quando background service conecta ao feed
- `MarketDataStreamStopped` - quando serviço para (mercado fecha ou erro)
- `UserSubscribedToSymbol` - quando trader subscreve via SignalR
- `UserUnsubscribedFromSymbol` - quando trader remove subscrição
- `RealTimePriceReceived` - para cada update de preço significativo (> 0.1%)
- `OptionMarketPricesUpdated` - quando banco de dados é atualizado

**Domain Services Utilizados:**
- `IMarketDataStreamService` - throttling, cache, e validação de mudanças significativas

**External Services:**
- `IMarketDataFeedClient` - WebSocket para feed da B3

**Infrastructure:**
- SignalR Hub (WebSocket para frontend)
- Background Service (IHostedService)
- Redis (cache distribuído de preços - opcional mas recomendado)

**Rate Limiting:**
- Throttling: max 1 update/segundo por símbolo
- Mudança mínima: 0.1% (evita spam de updates insignificantes)
- Validação de plano: apenas Pleno/Consultor

**Client Usage (Frontend - JavaScript/TypeScript):**

```typescript
// Conectar ao SignalR Hub
const connection = new signalR.HubConnectionBuilder()
    .withUrl("/hubs/marketdata", { accessTokenFactory: () => getAuthToken() })
    .withAutomaticReconnect()
    .build();

// Handler para updates de preço
connection.on("PriceUpdate", (update: PriceUpdateDto) => {
    console.log(`${update.symbol}: ${update.price} (${update.changePercentage}%)`);

    // Atualizar UI
    updatePriceDisplay(update.symbol, update.price, update.changePercentage);
});

// Conectar
await connection.start();

// Subscrever opção
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
| User Management | 3 (User, SubscriptionPlan, SystemConfig) | 3 | **11 (+UserPlanOverride)** | 3 | Média |
| Strategy Planning | 2 (StrategyTemplate, Strategy) | 4 (+ child entities) | 12 | 2 | Alta |
| **Market Data** | **2 (OptionContract, UnderlyingAsset)** | **3 (+ StrikeAdjustment)** | **8** | **2** | **Alta** |
| **Total** | **7** | **10** | **31** | **7** | **-** |

**Estimativa de Implementação:**
- **User Management: 3.5 dias (DBA: 1 dia, SE: 2.5 dias)**
  - Day 1: User + SubscriptionPlan aggregates
  - Day 2: SystemConfig + Admin use cases (UC-01, UC-02)
  - Day 3: **PlanOverride (UC-03, UC-04) + Testing**
- Strategy Planning: 4 dias (DBA: 1 dia, SE: 3 dias)
- **Market Data BC: 5-6 dias (DBA: 1 dia, SE: 4-5 dias)**
  - Aggregates + Repos: 2 dias
  - Black-Scholes Service (europeias): 2 dias
  - Sync Job B3 + APIs: 1-2 dias
- Integration: 1-2 dias
- **Total: 13.5-15.5 dias** (sem UX/Frontend)

**Breakdown Market Data:**
- Day 1: OptionContract aggregate + repository + migrations
- Day 2: UnderlyingAsset aggregate + sync job skeleton
- Day 3-4: Black-Scholes service (pricing + IV + Greeks)
- Day 5: Sync job B3 API integration
- Day 6: Validação e testes de integração

---

## ✅ Validação

- [x] Aggregates definidos com invariantes claros
- [x] Boundaries dos aggregates respeitados (User, Plan, Config, Template, Strategy, Option, UnderlyingAsset separados)
- [x] Domain Events identificados para integrações (**33+ eventos**)
- [x] Repository interfaces definidas (7 repositórios)
- [x] Use Cases mapeados (**13 use cases: 4 Admin + 7 Strategy/User + 2 MarketData**)
- [x] Validações de negócio no domínio (não na aplicação)
- [x] Nomenclatura consistente (PT → EN conforme padrões)
- [x] Admin management incluído (SubscriptionPlan, SystemConfig)
- [x] Strategy limits validation (baseado em SubscriptionPlan **+ override**)
- [x] **Plan overrides suportados (VIP, trials, beta testers, staff)**
- [x] **Market Data BC modelado (OptionContract, UnderlyingAsset)**
- [x] **Regras da B3 validadas (Puts europeias, ajustes de strike)**
- [x] **Black-Scholes service definido (apenas europeias no EPIC-01)**
- [x] **Integração Strategy Planning ↔ Market Data mapeada**
- [x] **Opções semanais suportadas (W1-W5, W3 = mensal padrão)**
- [x] **B3 API integration documentada (IB3ApiClient + sync job)**
- [x] **UC-MarketData-01: Sincronização diária de opções da B3 (batch)**
- [x] **UC-MarketData-02: Streaming de preços em tempo real (SignalR/WebSocket)**
- [x] **Real-time data validado por plano (RealtimeData feature flag)**
- [x] **Throttling e caching para performance de streaming**
- [x] **Templates enriquecidos com MarketView, Objective, RiskProfile**
- [x] **DefenseGuidelines para orientações de ajuste quando mercado inverte**
- [x] **PriceRangeIdeal para indicar faixa ideal de preço do ativo**
- [x] **Suporte a templates de hedge (HedgeTemplateId em DefenseGuidelines)**

---

## 📝 Notas de Implementação para SE

**Tecnologias:**
- Framework: .NET 8
- ORM: EF Core 8
- Event Bus: MediatR (in-process) + RabbitMQ (future)
- Authentication: JWT + BCrypt
- **Black-Scholes: Math.NET Numerics (para cálculos avançados)**
- **B3 API: HTTP Client + retry policies (Polly)**

**Estrutura de Pastas:**
```
02-backend/src/
├── Domain/
│   ├── UserManagement/
│   │   ├── Aggregates/
│   │   │   ├── User.cs
│   │   │   ├── SubscriptionPlan.cs
│   │   │   └── SystemConfig.cs
│   │   ├── ValueObjects/
│   │   │   ├── UserId.cs
│   │   │   ├── Email.cs
│   │   │   ├── PasswordHash.cs
│   │   │   └── Money.cs
│   │   ├── DomainEvents/
│   │   │   ├── UserRegistered.cs
│   │   │   ├── PlanConfigured.cs
│   │   │   └── SystemParametersUpdated.cs
│   │   └── Interfaces/
│   │       ├── IUserRepository.cs
│   │       ├── ISubscriptionPlanRepository.cs
│   │       └── ISystemConfigRepository.cs
│   ├── StrategyPlanning/
│   │   ├── Aggregates/
│   │   │   ├── StrategyTemplate.cs
│   │   │   └── Strategy.cs
│   │   ├── Entities/
│   │   │   ├── TemplateLeg.cs
│   │   │   └── StrategyLeg.cs
│   │   ├── ValueObjects/
│   │   │   ├── StrategyId.cs
│   │   │   ├── Ticker.cs
│   │   │   ├── RelativeStrike.cs
│   │   │   └── RiskScore.cs
│   │   ├── DomainEvents/
│   │   │   ├── TemplateCreated.cs
│   │   │   ├── StrategyCreated.cs
│   │   │   └── MarginCalculated.cs
│   │   └── Interfaces/
│   │       ├── IStrategyTemplateRepository.cs
│   │       └── IStrategyRepository.cs
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
│       │   └── OptionStatus.cs
│       ├── DomainEvents/
│       │   ├── OptionContractCreated.cs
│       │   ├── OptionMarketPricesUpdated.cs
│       │   ├── OptionGreeksUpdated.cs
│       │   ├── OptionStrikeAdjusted.cs
│       │   └── OptionExpired.cs
│       ├── Services/
│       │   └── IBlackScholesService.cs
│       └── Interfaces/
│           ├── IOptionContractRepository.cs
│           └── IUnderlyingAssetRepository.cs
├── Application/
│   ├── UserManagement/
│   │   ├── Commands/
│   │   │   ├── ConfigurePlanCommand.cs
│   │   │   ├── UpdateSystemParametersCommand.cs
│   │   │   ├── RegisterTraderCommand.cs
│   │   │   └── LoginCommand.cs
│   │   └── Handlers/
│   │       ├── ConfigurePlanHandler.cs
│   │       ├── UpdateSystemParametersHandler.cs
│   │       ├── RegisterTraderHandler.cs
│   │       └── LoginHandler.cs
│   ├── StrategyPlanning/
│   │   ├── Commands/
│   │   │   ├── CreateTemplateCommand.cs
│   │   │   ├── InstantiateTemplateCommand.cs
│   │   │   └── CreateStrategyCommand.cs
│   │   ├── Handlers/
│   │   │   ├── CreateTemplateHandler.cs
│   │   │   ├── InstantiateTemplateHandler.cs
│   │   │   └── CreateStrategyHandler.cs
│   │   └── Services/
│   │       ├── MarginCalculationService.cs
│   │       └── RiskAssessmentService.cs
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
    │   │   ├── UserRepository.cs
    │   │   ├── SubscriptionPlanRepository.cs
    │   │   ├── SystemConfigRepository.cs
    │   │   ├── StrategyTemplateRepository.cs
    │   │   ├── StrategyRepository.cs
    │   │   ├── OptionContractRepository.cs
    │   │   └── UnderlyingAssetRepository.cs
    │   └── Configurations/
    │       ├── UserConfiguration.cs
    │       ├── SubscriptionPlanConfiguration.cs
    │       ├── StrategyTemplateConfiguration.cs
    │       ├── StrategyConfiguration.cs
    │       ├── OptionContractConfiguration.cs
    │       └── UnderlyingAssetConfiguration.cs
    └── ExternalServices/
        └── B3Api/
            ├── IB3ApiClient.cs
            ├── B3ApiClient.cs
            └── B3ApiModels.cs (DTOs)
```

**Prioridades de Implementação (ATUALIZADO):**
1. **Days 1-3.5:** User Management
   - Day 1: User + SubscriptionPlan aggregates
   - Day 2: SystemConfig + Admin use cases (UC-01, UC-02)
   - Day 3: **UserPlanOverride + UC-Admin-03/04 (Grant/Revoke)**
   - Day 3.5: Testing + refinamento

2. **Days 4-7.5:** Strategy Planning
   - Day 4.5: StrategyTemplate aggregate
   - Day 5.5: Strategy aggregate (+ atualizar para usar GetEffectiveStrategyLimit)
   - Day 6.5-7.5: Use cases + testing

3. **Days 8-13.5:** Market Data BC
   - Day 8.5: OptionContract aggregate + repository + migrations
   - Day 9.5: UnderlyingAsset aggregate + sync job skeleton
   - Day 10.5-11.5: Black-Scholes service (pricing, IV, Greeks)
   - Day 12.5: B3 API integration + sync job
   - Day 13.5: Testing + validação

4. **Days 14-15.5:** Integration & Testing
   - Day 14.5: Strategy ↔ Market Data integration
   - Day 15.5: Testes end-to-end + refinamento

**Total: 15.5 dias** (backend completo, sem UX/Frontend)

---

## 🔗 Referências

- **SDA Context Map:** `00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md`
- **Ubiquitous Language:** `00-doc-ddd/02-strategic-design/SDA-03-Ubiquitous-Language.md`
- **DDD Patterns Reference:** `.agents/docs/05-DDD-Patterns-Reference.md`
