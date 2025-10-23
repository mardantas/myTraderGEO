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

## 🏗️ Modelo Tático por Bounded Context

### User Management

#### Aggregates

#### 1. User (Aggregate Root)

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

**Entities:**

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
}
```

**Value Objects:**

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
```

**Domain Events:**

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
```

---

#### 2. SubscriptionPlan (Aggregate Root)

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

**Entities:**

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

**Value Objects:**

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

**Domain Events:**

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

#### 3. SystemConfig (Aggregate Root)

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

**Entities:**

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

**Value Objects:**

```csharp
public record SystemConfigId(Guid Value);
```

**Domain Events:**

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

### Strategy Planning

#### Aggregates

#### 4. StrategyTemplate (Aggregate Root)

**Responsabilidade:** Gerenciar templates de estratégias com strikes relativos e topologia

**Invariantes (Business Rules):**
1. Name deve ser único para o usuário (templates pessoais) ou global (templates do sistema)
2. Deve ter ao menos 1 leg (perna)
3. Strikes relativos devem ser válidos (ATM, ATM+X%, ATM-X%, etc)
4. Vencimentos relativos devem ser válidos
5. Template global (Visibility = Global) só pode ser criado por Administrator
6. Template pessoal (Visibility = Personal) pertence a um UserId

**Entities:**

```csharp
// Aggregate Root
public class StrategyTemplate : Entity<StrategyTemplateId>
{
    // Properties
    public StrategyTemplateId Id { get; private set; }
    public string Name { get; private set; }
    public string Description { get; private set; }
    public TemplateVisibility Visibility { get; private set; }
    public UserId? OwnerId { get; private set; } // Null for global templates
    public DateTime CreatedAt { get; private set; }

    // Legs (child entities)
    private readonly List<TemplateLeg> _legs = new();
    public IReadOnlyList<TemplateLeg> Legs => _legs.AsReadOnly();

    // Domain Events
    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    // Private constructor for EF Core
    private StrategyTemplate() { }

    // Factory Method - Global Template
    public static StrategyTemplate CreateGlobal(
        string name,
        string description,
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

**Value Objects:**

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
```

**Domain Events:**

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

#### 5. Strategy (Aggregate Root)

**Responsabilidade:** Gerenciar estratégia instanciada com valores absolutos (strikes em R$, datas específicas)

**Invariantes (Business Rules):**
1. UserId deve existir e ser Trader
2. Deve respeitar StrategyLimit do SubscriptionPlan do usuário
3. Ticker deve ser válido (PETR4, VALE3, etc)
4. Deve ter ao menos 1 leg
5. Strikes devem ser valores absolutos em R$
6. Expirations devem ser datas futuras

**Entities:**

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

    // Calculated Values
    public Money? EstimatedMargin { get; private set; }
    public decimal? EstimatedReturn { get; private set; }
    public RiskScore? RiskScore { get; private set; }

    // Legs (child entities)
    private readonly List<StrategyLeg> _legs = new();
    public IReadOnlyList<StrategyLeg> Legs => _legs.AsReadOnly();

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

    public void Activate()
    {
        if (Status != StrategyStatus.Validated)
            throw new DomainException("Only validated strategies can be activated");

        Status = StrategyStatus.Active;

        _domainEvents.Add(new StrategyActivated(
            Id,
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
}
```

**Value Objects:**

```csharp
public record StrategyId(Guid Value)
{
    public static StrategyId New() => new(Guid.NewGuid());
}

public record StrategyLegId(Guid Value)
{
    public static StrategyLegId New() => new(Guid.NewGuid());
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
    Draft,      // Just created
    Validated,  // Passed validation
    Active,     // Currently active
    Closed      // Finalized
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

**Domain Events:**

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

public record StrategyActivated(
    StrategyId StrategyId,
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

### Market Data

#### Aggregates

#### 6. OptionContract (Aggregate Root)

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

**Entities:**

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

**Value Objects:**

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

**Domain Events:**

```csharp
public record OptionContractCreated(
    OptionContractId OptionId,
    string Symbol,
    Ticker UnderlyingAsset,
    OptionType Type,
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
```

---

#### 7. UnderlyingAsset (Aggregate Root)

**Responsabilidade:** Gerenciar dados do ativo subjacente (ação-objeto da opção)

**Invariantes (Business Rules):**
1. Symbol (Ticker) deve ser único
2. Name não pode ser vazio
3. CurrentPrice deve ser > 0
4. LastUpdated deve ser recente (< 1 dia para Active)

**Entities:**

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

**Value Objects:**

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

**Domain Events:**

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

    Task AddAsync(OptionContract option, CancellationToken ct);
    Task UpdateAsync(OptionContract option, CancellationToken ct);
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
2. `OptionContract.GetAvailableOptionsAsync` → Composite Index em (UnderlyingAsset, Status, Expiration)
3. `OptionContract.GetExpiringOptionsAsync` → Index em (Status, Expiration)
4. `OptionContract.GetLiquidOptionsAsync` → Index em (UnderlyingAsset, Status) + cálculo de spread
5. `UnderlyingAsset.GetBySymbolAsync` → Unique Index em Symbol

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
                legs
            );
        }
        else
        {
            template = StrategyTemplate.CreatePersonal(
                command.Name,
                command.Description,
                command.UserId,
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
- [x] Domain Events identificados para integrações (**25+ eventos**)
- [x] Repository interfaces definidas (7 repositórios)
- [x] Use Cases mapeados (**11 use cases: 5 Admin + 6 Strategy/User**)
- [x] Validações de negócio no domínio (não na aplicação)
- [x] Nomenclatura consistente (PT → EN conforme padrões)
- [x] Admin management incluído (SubscriptionPlan, SystemConfig)
- [x] Strategy limits validation (baseado em SubscriptionPlan **+ override**)
- [x] **Plan overrides suportados (VIP, trials, beta testers, staff)**
- [x] **Market Data BC modelado (OptionContract, UnderlyingAsset)**
- [x] **Regras da B3 validadas (Puts europeias, ajustes de strike)**
- [x] **Black-Scholes service definido (apenas europeias no EPIC-01)**
- [x] **Integração Strategy Planning ↔ Market Data mapeada**

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
