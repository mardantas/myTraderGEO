using System;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Domain.UserManagement.Aggregates;

/// <summary>
/// Aggregate Root: SubscriptionPlan
/// Represents a subscription plan (Básico, Pleno, Consultor)
/// </summary>
public class SubscriptionPlan
{
    public Guid Id { get; private set; }

    // Core Properties
    public string Name { get; private set; }
    public Money PriceMonthly { get; private set; }
    public Money PriceAnnual { get; private set; }
    public decimal AnnualDiscountPercent { get; private set; }

    // Limits
    public int StrategyLimit { get; private set; }

    // Features
    public PlanFeatures Features { get; private set; }

    // Status
    public bool IsActive { get; private set; }

    // Audit
    public DateTime CreatedAt { get; private set; }
    public DateTime? UpdatedAt { get; private set; }

    // EF Core constructor
    private SubscriptionPlan() { }

    private SubscriptionPlan(
        string name,
        Money priceMonthly,
        Money priceAnnual,
        decimal annualDiscountPercent,
        int strategyLimit,
        PlanFeatures features)
    {
        Id = Guid.NewGuid();
        Name = name;
        PriceMonthly = priceMonthly;
        PriceAnnual = priceAnnual;
        AnnualDiscountPercent = annualDiscountPercent;
        StrategyLimit = strategyLimit;
        Features = features;
        IsActive = true;
        CreatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Creates a new subscription plan
    /// </summary>
    public static SubscriptionPlan Create(
        string name,
        Money priceMonthly,
        Money priceAnnual,
        decimal annualDiscountPercent,
        int strategyLimit,
        PlanFeatures features)
    {
        // Validate name
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Plan name cannot be empty", nameof(name));

        if (name.Length > 50)
            throw new ArgumentException("Plan name cannot exceed 50 characters", nameof(name));

        // Validate prices
        if (priceMonthly.Currency != "BRL" || priceAnnual.Currency != "BRL")
            throw new ArgumentException("Plan prices must be in BRL");

        // Validate annual discount
        if (annualDiscountPercent < 0 || annualDiscountPercent > 1)
            throw new ArgumentException("Annual discount must be between 0 and 1", nameof(annualDiscountPercent));

        // Validate that annual price is actually discounted
        if (priceMonthly.Amount > 0)
        {
            var monthlyTotal = priceMonthly.Amount * 12;
            if (priceAnnual.Amount >= monthlyTotal)
                throw new ArgumentException("Annual price must be less than 12 monthly payments");
        }

        // Validate strategy limit
        if (strategyLimit <= 0)
            throw new ArgumentException("Strategy limit must be positive", nameof(strategyLimit));

        return new SubscriptionPlan(
            name.Trim(),
            priceMonthly,
            priceAnnual,
            annualDiscountPercent,
            strategyLimit,
            features);
    }

    /// <summary>
    /// Factory: Create Básico plan (Free)
    /// </summary>
    public static SubscriptionPlan CreateBasicoPlan()
    {
        return Create(
            name: "Básico",
            priceMonthly: Money.Zero("BRL"),
            priceAnnual: Money.Zero("BRL"),
            annualDiscountPercent: 0,
            strategyLimit: 3,
            features: PlanFeatures.BasicPlan());
    }

    /// <summary>
    /// Factory: Create Pleno plan (R$ 99.90/month)
    /// </summary>
    public static SubscriptionPlan CreatePlenoPlan()
    {
        var monthlyPrice = Money.BRL(99.90m);
        var annualPrice = Money.BRL(959.04m); // 20% discount

        return Create(
            name: "Pleno",
            priceMonthly: monthlyPrice,
            priceAnnual: annualPrice,
            annualDiscountPercent: 0.20m,
            strategyLimit: 10,
            features: PlanFeatures.PlenoPlan());
    }

    /// <summary>
    /// Factory: Create Consultor plan (R$ 299/month)
    /// </summary>
    public static SubscriptionPlan CreateConsultorPlan()
    {
        var monthlyPrice = Money.BRL(299.00m);
        var annualPrice = Money.BRL(2870.40m); // 20% discount

        return Create(
            name: "Consultor",
            priceMonthly: monthlyPrice,
            priceAnnual: annualPrice,
            annualDiscountPercent: 0.20m,
            strategyLimit: 50,
            features: PlanFeatures.ConsultorPlan());
    }

    /// <summary>
    /// Updates plan pricing
    /// </summary>
    public void UpdatePricing(
        Money priceMonthly,
        Money priceAnnual,
        decimal annualDiscountPercent)
    {
        if (priceMonthly.Currency != "BRL" || priceAnnual.Currency != "BRL")
            throw new ArgumentException("Plan prices must be in BRL");

        if (annualDiscountPercent < 0 || annualDiscountPercent > 1)
            throw new ArgumentException("Annual discount must be between 0 and 1");

        if (priceMonthly.Amount > 0)
        {
            var monthlyTotal = priceMonthly.Amount * 12;
            if (priceAnnual.Amount >= monthlyTotal)
                throw new ArgumentException("Annual price must be less than 12 monthly payments");
        }

        PriceMonthly = priceMonthly;
        PriceAnnual = priceAnnual;
        AnnualDiscountPercent = annualDiscountPercent;
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Updates strategy limit
    /// </summary>
    public void UpdateStrategyLimit(int newLimit)
    {
        if (newLimit <= 0)
            throw new ArgumentException("Strategy limit must be positive", nameof(newLimit));

        StrategyLimit = newLimit;
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Updates plan features
    /// </summary>
    public void UpdateFeatures(PlanFeatures newFeatures)
    {
        Features = newFeatures ?? throw new ArgumentNullException(nameof(newFeatures));
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Activates the plan
    /// </summary>
    public void Activate()
    {
        if (IsActive) return;

        IsActive = true;
        UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Deactivates the plan
    /// </summary>
    public void Deactivate()
    {
        if (!IsActive) return;

        IsActive = false;
        UpdatedAt = DateTime.UtcNow;
    }
}
