using System;

namespace MyTraderGEO.Infrastructure.Data.Models;

/// <summary>
/// EF Core entity for SubscriptionPlan aggregate
/// Auto-generated placeholder - will be replaced by EF scaffold when database is ready
/// </summary>
public partial class SubscriptionPlan
{
    public Guid Id { get; set; }

    // Core Properties
    public string Name { get; set; } = null!;
    public decimal PriceMonthlyAmount { get; set; }
    public string PriceMonthlyCurrency { get; set; } = "BRL";
    public decimal PriceAnnualAmount { get; set; }
    public string PriceAnnualCurrency { get; set; } = "BRL";
    public decimal AnnualDiscountPercent { get; set; }

    // Limits
    public int StrategyLimit { get; set; }

    // Features
    public bool FeatureRealtimeData { get; set; }
    public bool FeatureAdvancedAlerts { get; set; }
    public bool FeatureConsultingTools { get; set; }
    public bool FeatureCommunityAccess { get; set; }

    // Status
    public bool IsActive { get; set; }

    // Audit
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    // Navigation Properties
    public virtual ICollection<User> Users { get; set; } = new List<User>();
}
