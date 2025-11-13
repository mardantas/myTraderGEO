using System;
using MediatR;

namespace MyTraderGEO.Application.UserManagement.Commands;

/// <summary>
/// Command: Grant Plan Override to User
/// UC-Admin-03: GrantPlanOverride
/// </summary>
public sealed record GrantPlanOverrideCommand : IRequest<GrantPlanOverrideCommandResult>
{
    public Guid UserId { get; init; }
    public Guid AdministratorId { get; init; }
    public string Reason { get; init; } = string.Empty;

    // Override values
    public int? StrategyLimitOverride { get; init; }
    public bool? FeatureRealtimeDataOverride { get; init; }
    public bool? FeatureAdvancedAlertsOverride { get; init; }
    public bool? FeatureConsultingToolsOverride { get; init; }
    public bool? FeatureCommunityAccessOverride { get; init; }

    public DateTime? ExpiresAt { get; init; }
}

public sealed record GrantPlanOverrideCommandResult
{
    public Guid UserId { get; init; }
    public string Message { get; init; } = "Plan override granted successfully";
}
