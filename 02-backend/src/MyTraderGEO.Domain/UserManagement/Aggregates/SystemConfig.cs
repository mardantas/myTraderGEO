using System;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Domain.UserManagement.Aggregates;

/// <summary>
/// Aggregate Root: SystemConfig (Singleton)
/// Global system configuration for trading fees and limits
/// </summary>
public class SystemConfig
{
    // Singleton ID
    public const int SingletonId = 1;

    public int Id { get; private set; }

    // Trading Fees
    public TradingFees Fees { get; private set; } = null!;

    // Global Limits
    public int MaxOpenStrategiesPerUser { get; private set; }
    public int MaxStrategiesInTemplate { get; private set; }

    // Audit
    public DateTime UpdatedAt { get; private set; }
    public Guid UpdatedBy { get; private set; }

    // EF Core constructor
    private SystemConfig() { }

    private SystemConfig(
        TradingFees fees,
        int maxOpenStrategiesPerUser,
        int maxStrategiesInTemplate,
        Guid updatedBy)
    {
        Id = SingletonId;
        Fees = fees;
        MaxOpenStrategiesPerUser = maxOpenStrategiesPerUser;
        MaxStrategiesInTemplate = maxStrategiesInTemplate;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = updatedBy;
    }

    /// <summary>
    /// Creates the singleton system configuration (first-time setup)
    /// </summary>
    public static SystemConfig CreateDefault(Guid administratorId)
    {
        if (administratorId == Guid.Empty)
            throw new ArgumentException("Administrator ID cannot be empty", nameof(administratorId));

        // Default Brazilian trading fees
        var defaultFees = TradingFees.Create(
            brokerCommissionRate: 0.0m,          // Most brokers are zero commission
            b3EmolumentRate: 0.000325m,          // 0.0325%
            settlementFeeRate: 0.000275m,        // 0.0275%
            incomeTaxRate: 0.15m,                // 15% for swing-trade
            dayTradeIncomeTaxRate: 0.20m);       // 20% for day-trade

        return new SystemConfig(
            fees: defaultFees,
            maxOpenStrategiesPerUser: 100,
            maxStrategiesInTemplate: 20,
            updatedBy: administratorId);
    }

    /// <summary>
    /// Updates trading fees
    /// </summary>
    public void UpdateFees(
        decimal? brokerCommissionRate,
        decimal? b3EmolumentRate,
        decimal? settlementFeeRate,
        decimal? incomeTaxRate,
        decimal? dayTradeIncomeTaxRate,
        Guid updatedBy)
    {
        if (updatedBy == Guid.Empty)
            throw new ArgumentException("UpdatedBy cannot be empty", nameof(updatedBy));

        Fees = TradingFees.Create(
            brokerCommissionRate,
            b3EmolumentRate,
            settlementFeeRate,
            incomeTaxRate,
            dayTradeIncomeTaxRate);

        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = updatedBy;
    }

    /// <summary>
    /// Updates global limits
    /// </summary>
    public void UpdateLimits(
        int maxOpenStrategiesPerUser,
        int maxStrategiesInTemplate,
        Guid updatedBy)
    {
        if (maxOpenStrategiesPerUser <= 0)
            throw new ArgumentException("Max open strategies must be positive", nameof(maxOpenStrategiesPerUser));

        if (maxStrategiesInTemplate <= 0)
            throw new ArgumentException("Max strategies in template must be positive", nameof(maxStrategiesInTemplate));

        if (updatedBy == Guid.Empty)
            throw new ArgumentException("UpdatedBy cannot be empty", nameof(updatedBy));

        MaxOpenStrategiesPerUser = maxOpenStrategiesPerUser;
        MaxStrategiesInTemplate = maxStrategiesInTemplate;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = updatedBy;
    }

    /// <summary>
    /// Gets effective fees for a user (merge user custom fees with system defaults)
    /// </summary>
    public TradingFees GetEffectiveFees(TradingFees? userCustomFees)
    {
        if (userCustomFees == null || !userCustomFees.HasCustomFees)
            return Fees;

        return userCustomFees.MergeWithDefaults(Fees);
    }
}
