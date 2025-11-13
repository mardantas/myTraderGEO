using System;

namespace MyTraderGEO.Domain.UserManagement.ValueObjects;

/// <summary>
/// Value Object: User Plan Override
/// Allows temporary override of plan limits and features (VIP, trial, beta, staff)
/// </summary>
public sealed class UserPlanOverride : IEquatable<UserPlanOverride>
{
    public int? StrategyLimitOverride { get; }
    public PlanFeatures? FeaturesOverride { get; }
    public DateTime? ExpiresAt { get; }
    public string Reason { get; }
    public Guid GrantedBy { get; }
    public DateTime GrantedAt { get; }

    private UserPlanOverride(
        int? strategyLimitOverride,
        PlanFeatures? featuresOverride,
        DateTime? expiresAt,
        string reason,
        Guid grantedBy,
        DateTime grantedAt)
    {
        StrategyLimitOverride = strategyLimitOverride;
        FeaturesOverride = featuresOverride;
        ExpiresAt = expiresAt;
        Reason = reason;
        GrantedBy = grantedBy;
        GrantedAt = grantedAt;
    }

    public static UserPlanOverride Create(
        Guid grantedBy,
        string reason,
        int? strategyLimitOverride = null,
        PlanFeatures? featuresOverride = null,
        DateTime? expiresAt = null)
    {
        if (grantedBy == Guid.Empty)
            throw new ArgumentException("GrantedBy cannot be empty", nameof(grantedBy));

        if (string.IsNullOrWhiteSpace(reason))
            throw new ArgumentException("Reason cannot be empty", nameof(reason));

        if (reason.Length > 500)
            throw new ArgumentException("Reason cannot exceed 500 characters", nameof(reason));

        if (strategyLimitOverride.HasValue && strategyLimitOverride.Value <= 0)
            throw new ArgumentException("Strategy limit must be positive", nameof(strategyLimitOverride));

        if (expiresAt.HasValue && expiresAt.Value <= DateTime.UtcNow)
            throw new ArgumentException("Expiration date must be in the future", nameof(expiresAt));

        // At least one override must be specified
        if (!strategyLimitOverride.HasValue && featuresOverride == null)
            throw new ArgumentException("At least one override (strategy limit or features) must be specified");

        return new UserPlanOverride(
            strategyLimitOverride,
            featuresOverride,
            expiresAt,
            reason.Trim(),
            grantedBy,
            DateTime.UtcNow);
    }

    /// <summary>
    /// Creates a VIP override (unlimited strategies + all features, no expiration)
    /// </summary>
    public static UserPlanOverride CreateVip(Guid grantedBy, string reason)
    {
        return Create(
            grantedBy,
            $"VIP: {reason}",
            strategyLimitOverride: 9999,
            featuresOverride: PlanFeatures.ConsultorPlan(),
            expiresAt: null);
    }

    /// <summary>
    /// Creates a trial override (30 days of Consultor features)
    /// </summary>
    public static UserPlanOverride CreateTrial(Guid grantedBy, int durationDays = 30)
    {
        return Create(
            grantedBy,
            $"Trial: {durationDays} days",
            strategyLimitOverride: null,
            featuresOverride: PlanFeatures.ConsultorPlan(),
            expiresAt: DateTime.UtcNow.AddDays(durationDays));
    }

    /// <summary>
    /// Creates a beta tester override
    /// </summary>
    public static UserPlanOverride CreateBetaTester(Guid grantedBy)
    {
        return Create(
            grantedBy,
            "Beta Tester",
            strategyLimitOverride: 100,
            featuresOverride: PlanFeatures.ConsultorPlan(),
            expiresAt: null);
    }

    /// <summary>
    /// Checks if the override has expired
    /// </summary>
    public bool IsExpired => ExpiresAt.HasValue && ExpiresAt.Value <= DateTime.UtcNow;

    /// <summary>
    /// Checks if the override is currently active
    /// </summary>
    public bool IsActive => !IsExpired;

    public bool Equals(UserPlanOverride? other)
    {
        if (other is null) return false;
        return StrategyLimitOverride == other.StrategyLimitOverride
               && Equals(FeaturesOverride, other.FeaturesOverride)
               && ExpiresAt == other.ExpiresAt
               && Reason == other.Reason
               && GrantedBy == other.GrantedBy
               && GrantedAt == other.GrantedAt;
    }

    public override bool Equals(object? obj) => obj is UserPlanOverride other && Equals(other);

    public override int GetHashCode() => HashCode.Combine(
        StrategyLimitOverride,
        FeaturesOverride,
        ExpiresAt,
        Reason,
        GrantedBy,
        GrantedAt);

    public override string ToString()
    {
        var status = IsExpired ? "EXPIRED" : "ACTIVE";
        var expiry = ExpiresAt.HasValue ? $"until {ExpiresAt.Value:yyyy-MM-dd}" : "permanent";
        return $"[{status}] {Reason} ({expiry})";
    }

    public static bool operator ==(UserPlanOverride? left, UserPlanOverride? right) =>
        left is null ? right is null : left.Equals(right);

    public static bool operator !=(UserPlanOverride? left, UserPlanOverride? right) => !(left == right);
}
