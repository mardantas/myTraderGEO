using System;

namespace MyTraderGEO.Infrastructure.Data.Models;

/// <summary>
/// EF Core entity for User aggregate
/// Auto-generated placeholder - will be replaced by EF scaffold when database is ready
/// </summary>
public partial class User
{
    public Guid Id { get; set; }

    // Authentication
    public string Email { get; set; } = null!;
    public string PasswordHash { get; set; } = null!;

    // Profile
    public string FullName { get; set; } = null!;
    public string DisplayName { get; set; } = null!;

    // Phone (for WhatsApp, 2FA, recovery)
    public string? PhoneCountryCode { get; set; }
    public string? PhoneNumber { get; set; }
    public bool IsPhoneVerified { get; set; }
    public DateTime? PhoneVerifiedAt { get; set; }

    // Role & Status
    public string Role { get; set; } = null!;
    public string Status { get; set; } = "Active";

    // Risk Profile
    public string? RiskProfile { get; set; }

    // Subscription
    public int? SubscriptionPlanId { get; set; }
    public int? BillingPeriod { get; set; }

    // Plan Override (JSONB)
    public string? PlanOverride { get; set; }

    // Custom Trading Fees (JSONB)
    public string? CustomFees { get; set; }

    // Audit
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }

    // Navigation Properties
    public virtual SubscriptionPlan? SubscriptionPlan { get; set; }
    public virtual ICollection<SystemConfig> SystemConfigsUpdated { get; set; } = new List<SystemConfig>();
}
