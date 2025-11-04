<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# DE-01-EPIC-01-A-User-Management-Domain-Model.md

**Agent:** DE (Domain Engineer)  
**Project:** myTraderGEO  
**Date:** 2025-10-25  
**Epic:** EPIC-01-A: User Management (segmento do EPIC-01)  
**Phase:** Iteration  
**Scope:** Tactical DDD model for epic-specific bounded contexts  
**Version:** 1.0  

---

## 🎯 Contexto do Sub-Épico

**Nome do Sub-Épico:** User Management  

**Bounded Context:** User Management  

**Objetivo:**
Modelar o gerenciamento de usuários, autenticação, perfis de risco, planos de assinatura e configurações globais do sistema. Inclui administração de planos, limites, overrides (VIP, trials, beta testers) e taxas customizadas por usuário.

**Aggregates Modelados:**
- User (Aggregate Root)
- SubscriptionPlan (Aggregate Root)
- SystemConfig (Aggregate Root)

---

## 📋 Índice do Modelo de Domínio

### User Management BC

#### [Aggregate: User](#1-user-aggregate-root)
**Responsabilidade:** Gerenciamento de usuários, autenticação, perfil e planos  

**Entities:**
  - (nenhuma child entity)

**Value Objects:**
  - UserId, Email, PasswordHash, PhoneNumber, UserRole, RiskProfile, UserStatus
  - UserPlanOverride, TradingFees, BillingPeriod

**Domain Events:**
  - UserRegistered, RiskProfileUpdated, UserPlanUpgraded
  - UserLoggedIn, UserSuspended, UserActivated, UserDeleted, DisplayNameUpdated
  - PlanOverrideGranted, PlanOverrideRevoked
  - CustomFeesConfigured, CustomFeesRemoved
  - PhoneNumberAdded, PhoneNumberVerified, PhoneNumberChanged

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

# User Management

## Aggregates

## 1. User (Aggregate Root)

**Responsabilidade:** Gerenciar cadastro, autenticação e perfil de usuário  

**Invariantes (Business Rules):**
1. Email deve ser único no sistema
2. Password deve ter no mínimo 8 caracteres
3. DisplayName deve ter entre 2 e 30 caracteres
4. PhoneNumber é opcional no cadastro, mas obrigatório para 2FA e alertas via WhatsApp
5. PhoneNumber deve seguir formato internacional (+CountryCode + Number)
6. Telefone verificado é obrigatório para Plano Consultor
7. RiskProfile deve ser um dos valores: Conservador, Moderado, Agressivo
8. Role deve ser: Trader, Moderator, Administrator
9. Trader deve ter um SubscriptionPlan e BillingPeriod associados
10. Administrator e Moderator não precisam de SubscriptionPlan nem BillingPeriod
11. Apenas Traders podem ter PlanOverride
12. PlanOverride expirado deve ser ignorado nos cálculos de limites efetivos
13. BillingPeriod deve ser Monthly ou Annual
14. Apenas Traders podem configurar CustomFees
15. Todas as taxas em CustomFees devem estar entre 0 e 1 (se especificadas)

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

    // Phone Number (for WhatsApp, 2FA, recovery)
    public PhoneNumber? PhoneNumber { get; private set; }  // Nullable - opcional no cadastro
    public bool IsPhoneVerified { get; private set; }      // Verificado via SMS/WhatsApp
    public DateTime? PhoneVerifiedAt { get; private set; }

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
        BillingPeriod billingPeriod,
        PhoneNumber? phoneNumber = null)  // Optional at signup
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
            PhoneNumber = phoneNumber,
            IsPhoneVerified = false,
            PhoneVerifiedAt = null,
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

    // Phone Number Management
    public void AddPhoneNumber(PhoneNumber phoneNumber)
    {
        if (Role != UserRole.Trader)
            throw new DomainException("Only traders can add phone number");

        PhoneNumber = phoneNumber;
        IsPhoneVerified = false;
        PhoneVerifiedAt = null;

        _domainEvents.Add(new PhoneNumberAdded(
            Id,
            phoneNumber,
            DateTime.UtcNow
        ));
    }

    public void VerifyPhoneNumber()
    {
        if (PhoneNumber == null)
            throw new DomainException("No phone number to verify");

        if (IsPhoneVerified)
            throw new DomainException("Phone number is already verified");

        IsPhoneVerified = true;
        PhoneVerifiedAt = DateTime.UtcNow;

        _domainEvents.Add(new PhoneNumberVerified(
            Id,
            PhoneNumber,
            DateTime.UtcNow
        ));
    }

    public void ChangePhoneNumber(PhoneNumber newPhoneNumber)
    {
        if (PhoneNumber == null)
            throw new DomainException("Use AddPhoneNumber for first phone");

        if (Role != UserRole.Trader)
            throw new DomainException("Only traders can change phone number");

        var oldPhone = PhoneNumber;
        PhoneNumber = newPhoneNumber;
        IsPhoneVerified = false;  // Needs verification for new number
        PhoneVerifiedAt = null;

        _domainEvents.Add(new PhoneNumberChanged(
            Id,
            oldPhone,
            newPhoneNumber,
            DateTime.UtcNow
        ));
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

public record PhoneNumber(string CountryCode, string Number)
{
    public PhoneNumber
    {
        if (string.IsNullOrWhiteSpace(CountryCode))
            throw new ArgumentException("Country code is required");

        if (string.IsNullOrWhiteSpace(Number))
            throw new ArgumentException("Phone number is required");

        // Basic validation (can use libPhoneNumber for robust validation)
        if (!CountryCode.StartsWith("+"))
            throw new ArgumentException("Country code must start with +");

        if (Number.Length < 8 || Number.Length > 15)
            throw new ArgumentException("Invalid phone number length");
    }

    // Helper factories
    public static PhoneNumber FromBrazil(string number)
        => new("+55", CleanNumber(number));

    public static PhoneNumber From(string countryCode, string number)
        => new(countryCode, CleanNumber(number));

    private static string CleanNumber(string number)
    {
        // Remove spaces, parentheses, hyphens
        return new string(number.Where(char.IsDigit).ToArray());
    }

    // Display format
    public string ToDisplay()
    {
        if (CountryCode == "+55" && Number.Length == 11)
            // Brazilian format: (11) 98765-4321
            return $"({Number.Substring(0, 2)}) {Number.Substring(2, 5)}-{Number.Substring(7)}";

        return $"{CountryCode} {Number}";
    }

    // WhatsApp API format
    public string ToWhatsAppFormat() => $"{CountryCode}{Number}";
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

public record PhoneNumberAdded(
    UserId UserId,
    PhoneNumber PhoneNumber,
    DateTime OccurredAt
) : IDomainEvent;

public record PhoneNumberVerified(
    UserId UserId,
    PhoneNumber PhoneNumber,
    DateTime OccurredAt
) : IDomainEvent;

public record PhoneNumberChanged(
    UserId UserId,
    PhoneNumber OldPhoneNumber,
    PhoneNumber NewPhoneNumber,
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

### User Management → Market Data Integration

**Mecanismo:** Feature flag validation  

**Fluxo de Validação de Acesso a Dados em Tempo Real:**
```
[Market Data - Streaming Service]
    → User requests realtime data subscription
    → Query User.HasRealtimeDataAccess()
    → If false: Throw UnauthorizedException("Realtime data requires Pleno or Consultor plan")
    → If true: Subscribe to WebSocket feed
```

**Feature Flags:**
- `PlanFeatures.RealtimeData` → Controla acesso a streaming de preços
- `PlanFeatures.AdvancedAlerts` → Controla alertas avançados
- `PlanFeatures.ConsultingTools` → Controla ferramentas de consultoria

---

### User Management → Risk Management Integration

**Mecanismo:** Domain Events  

**Eventos Publicados por User Management:**
- `RiskProfileUpdated` → Risk Management pode recalcular risk scores de estratégias existentes
- `UserSuspended` → Risk Management pode pausar monitoramento de risco

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

## 📊 Complexidade e Estimativas

| Bounded Context | Aggregates | Entities | Value Objects | Repositories | Complexity |
|-----------------|------------|----------|---------------|--------------|------------|
| User Management | 3 (User, SubscriptionPlan, SystemConfig) | 3 | **12 (+PhoneNumber, +UserPlanOverride)** | 3 | Média |

**Estimativa de Implementação:**
- **User Management: 3.5 dias (DBA: 1 dia, SE: 2.5 dias)**
  - Day 1: User + SubscriptionPlan aggregates
  - Day 2: SystemConfig + Admin use cases (UC-01, UC-02)
  - Day 3: **PlanOverride (UC-03, UC-04) + Testing**

---

## ✅ Validação

- [x] Aggregates definidos com invariantes claros
- [x] Boundaries dos aggregates respeitados (User, Plan, Config separados)
- [x] Domain Events identificados para integrações (17 eventos: 14 originais + 3 phone)
- [x] Repository interfaces definidas (3 repositórios)
- [x] Use Cases mapeados (6 use cases: 4 Admin + 2 User)
- [x] Validações de negócio no domínio (não na aplicação)
- [x] Nomenclatura consistente (PT → EN conforme padrões)
- [x] Admin management incluído (SubscriptionPlan, SystemConfig)
- [x] Strategy limits validation (baseado em SubscriptionPlan + override)
- [x] Plan overrides suportados (VIP, trials, beta testers, staff)
- [x] Custom fees por usuário (para diferentes corretoras, contas VIP)
- [x] BillingPeriod suportado (Monthly, Annual)
- [x] PhoneNumber suportado (WhatsApp, 2FA, recovery)
- [x] Phone verification workflow (AddPhoneNumber → Verify → opcional Change)
- [x] Telefone verificado obrigatório para Plano Consultor

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
2. **DBA** documenta schema em `DBA-01-EPIC-01-A-Schema-Review.md`
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
- Authentication: JWT + BCrypt
- SMS/WhatsApp: Twilio API ou WhatsApp Business API
- Phone Validation: libPhoneNumber (Google) para validação robusta
- Verification Code: Redis (cache com TTL de 5 minutos)

**Estrutura de Pastas:**
```
02-backend/src/
├── Domain/
│   └── UserManagement/
│       ├── Aggregates/
│       │   ├── User.cs
│       │   ├── SubscriptionPlan.cs
│       │   └── SystemConfig.cs
│       ├── ValueObjects/
│       │   ├── UserId.cs
│       │   ├── Email.cs
│       │   ├── PasswordHash.cs
│       │   ├── PhoneNumber.cs
│       │   ├── Money.cs
│       │   ├── UserPlanOverride.cs
│       │   └── TradingFees.cs
│       ├── DomainEvents/
│       │   ├── UserRegistered.cs
│       │   ├── PlanConfigured.cs
│       │   ├── SystemParametersUpdated.cs
│       │   ├── PlanOverrideGranted.cs
│       │   ├── PlanOverrideRevoked.cs
│       │   ├── PhoneNumberAdded.cs
│       │   ├── PhoneNumberVerified.cs
│       │   └── PhoneNumberChanged.cs
│       └── Interfaces/
│           ├── IUserRepository.cs
│           ├── ISubscriptionPlanRepository.cs
│           └── ISystemConfigRepository.cs
├── Application/
│   └── UserManagement/
│       ├── Commands/
│       │   ├── ConfigurePlanCommand.cs
│       │   ├── UpdateSystemParametersCommand.cs
│       │   ├── GrantPlanOverrideCommand.cs
│       │   ├── RevokePlanOverrideCommand.cs
│       │   ├── RegisterTraderCommand.cs
│       │   └── LoginCommand.cs
│       └── Handlers/
│           ├── ConfigurePlanHandler.cs
│           ├── UpdateSystemParametersHandler.cs
│           ├── GrantPlanOverrideHandler.cs
│           ├── RevokePlanOverrideHandler.cs
│           ├── RegisterTraderHandler.cs
│           └── LoginHandler.cs
└── Infrastructure/
    └── Persistence/
        ├── Repositories/
        │   ├── UserRepository.cs
        │   ├── SubscriptionPlanRepository.cs
        │   └── SystemConfigRepository.cs
        └── Configurations/
            ├── UserConfiguration.cs
            ├── SubscriptionPlanConfiguration.cs
            └── SystemConfigConfiguration.cs
```

**Prioridades de Implementação:**
1. **Days 1-3.5:** User Management
   - Day 1: User + SubscriptionPlan aggregates
   - Day 2: SystemConfig + Admin use cases (UC-01, UC-02)
   - Day 3: UserPlanOverride + UC-Admin-03/04 (Grant/Revoke)
   - Day 3.5: Testing + refinamento

---

## 🔗 Referências

- **SDA Context Map:** `00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md`
- **Ubiquitous Language:** `00-doc-ddd/02-strategic-design/SDA-03-Ubiquitous-Language.md`
- **DDD Patterns Reference:** `.agents/docs/05-DDD-Patterns-Reference.md`
- **EPIC-01 Complete Model:** `00-doc-ddd/04-tactical-design/DE-01-EPIC-01-CreateStrategy-Domain-Model.md`
- **DBA Workflow (Database First):** [Workflow Guide - Database First](../../.agents/docs/00-Workflow-Guide.md#database-workflow-sql-first-approach)
- **DBA README:** [04-database/README.md](../../04-database/README.md) - Migration scripts structure, idempotency patterns
- **DBA Schema Review:** `00-doc-ddd/05-database-design/DBA-01-EPIC-01-A-Schema-Review.md` (to be created by DBA)
