using System;
using MediatR;

namespace MyTraderGEO.Application.UserManagement.Commands;

/// <summary>
/// Command: Configure (Create/Update) Subscription Plan
/// UC-Admin-01: ConfigureSubscriptionPlan
/// </summary>
public sealed record ConfigureSubscriptionPlanCommand : IRequest<ConfigureSubscriptionPlanCommandResult>
{
    public int? PlanId { get; init; } // Null = Create, Not Null = Update
    public string Name { get; init; } = string.Empty;
    public decimal PriceMonthlyAmount { get; init; }
    public decimal PriceAnnualAmount { get; init; }
    public decimal AnnualDiscountPercent { get; init; }
    public int StrategyLimit { get; init; }

    // Features
    public bool FeatureRealtimeData { get; init; }
    public bool FeatureAdvancedAlerts { get; init; }
    public bool FeatureConsultingTools { get; init; }
    public bool FeatureCommunityAccess { get; init; }
}

public sealed record ConfigureSubscriptionPlanCommandResult
{
    public int PlanId { get; init; }
    public string Name { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}
