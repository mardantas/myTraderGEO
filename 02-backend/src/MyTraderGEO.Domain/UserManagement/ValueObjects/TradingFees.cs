using System;

namespace MyTraderGEO.Domain.UserManagement.ValueObjects;

/// <summary>
/// Value Object: Trading Fees
/// Custom trading fees per user (nullable fields fallback to SystemConfig)
/// </summary>
public sealed class TradingFees : IEquatable<TradingFees>
{
    public decimal? BrokerCommissionRate { get; }
    public decimal? B3EmolumentRate { get; }
    public decimal? SettlementFeeRate { get; }
    public decimal? IncomeTaxRate { get; }
    public decimal? DayTradeIncomeTaxRate { get; }

    private TradingFees(
        decimal? brokerCommissionRate,
        decimal? b3EmolumentRate,
        decimal? settlementFeeRate,
        decimal? incomeTaxRate,
        decimal? dayTradeIncomeTaxRate)
    {
        BrokerCommissionRate = brokerCommissionRate;
        B3EmolumentRate = b3EmolumentRate;
        SettlementFeeRate = settlementFeeRate;
        IncomeTaxRate = incomeTaxRate;
        DayTradeIncomeTaxRate = dayTradeIncomeTaxRate;
    }

    public static TradingFees Create(
        decimal? brokerCommissionRate = null,
        decimal? b3EmolumentRate = null,
        decimal? settlementFeeRate = null,
        decimal? incomeTaxRate = null,
        decimal? dayTradeIncomeTaxRate = null)
    {
        // Validate rates are between 0 and 1 (0% to 100%)
        ValidateRate(brokerCommissionRate, nameof(brokerCommissionRate));
        ValidateRate(b3EmolumentRate, nameof(b3EmolumentRate));
        ValidateRate(settlementFeeRate, nameof(settlementFeeRate));
        ValidateRate(incomeTaxRate, nameof(incomeTaxRate));
        ValidateRate(dayTradeIncomeTaxRate, nameof(dayTradeIncomeTaxRate));

        return new TradingFees(
            brokerCommissionRate,
            b3EmolumentRate,
            settlementFeeRate,
            incomeTaxRate,
            dayTradeIncomeTaxRate);
    }

    private static void ValidateRate(decimal? rate, string paramName)
    {
        if (rate.HasValue && (rate.Value < 0 || rate.Value > 1))
            throw new ArgumentException($"{paramName} must be between 0 and 1 (0% to 100%)", paramName);
    }

    /// <summary>
    /// Checks if any custom fee is set
    /// </summary>
    public bool HasCustomFees =>
        BrokerCommissionRate.HasValue
        || B3EmolumentRate.HasValue
        || SettlementFeeRate.HasValue
        || IncomeTaxRate.HasValue
        || DayTradeIncomeTaxRate.HasValue;

    /// <summary>
    /// Returns effective fee rates by merging with system defaults
    /// </summary>
    public TradingFees MergeWithDefaults(TradingFees systemDefaults)
    {
        return new TradingFees(
            BrokerCommissionRate ?? systemDefaults.BrokerCommissionRate,
            B3EmolumentRate ?? systemDefaults.B3EmolumentRate,
            SettlementFeeRate ?? systemDefaults.SettlementFeeRate,
            IncomeTaxRate ?? systemDefaults.IncomeTaxRate,
            DayTradeIncomeTaxRate ?? systemDefaults.DayTradeIncomeTaxRate);
    }

    public bool Equals(TradingFees? other)
    {
        if (other is null) return false;
        return BrokerCommissionRate == other.BrokerCommissionRate
               && B3EmolumentRate == other.B3EmolumentRate
               && SettlementFeeRate == other.SettlementFeeRate
               && IncomeTaxRate == other.IncomeTaxRate
               && DayTradeIncomeTaxRate == other.DayTradeIncomeTaxRate;
    }

    public override bool Equals(object? obj) => obj is TradingFees other && Equals(other);

    public override int GetHashCode() => HashCode.Combine(
        BrokerCommissionRate,
        B3EmolumentRate,
        SettlementFeeRate,
        IncomeTaxRate,
        DayTradeIncomeTaxRate);

    public override string ToString()
    {
        return $"BrokerCommission: {FormatRate(BrokerCommissionRate)}, " +
               $"B3Emolument: {FormatRate(B3EmolumentRate)}, " +
               $"Settlement: {FormatRate(SettlementFeeRate)}, " +
               $"IncomeTax: {FormatRate(IncomeTaxRate)}, " +
               $"DayTradeTax: {FormatRate(DayTradeIncomeTaxRate)}";
    }

    private static string FormatRate(decimal? rate) =>
        rate.HasValue ? $"{rate.Value:P4}" : "default";

    public static bool operator ==(TradingFees? left, TradingFees? right) =>
        left is null ? right is null : left.Equals(right);

    public static bool operator !=(TradingFees? left, TradingFees? right) => !(left == right);
}
