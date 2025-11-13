using System;
using MediatR;

namespace MyTraderGEO.Application.UserManagement.Commands;

/// <summary>
/// Command: Revoke Plan Override from User
/// UC-Admin-04: RevokePlanOverride
/// </summary>
public sealed record RevokePlanOverrideCommand : IRequest<RevokePlanOverrideCommandResult>
{
    public Guid UserId { get; init; }
}

public sealed record RevokePlanOverrideCommandResult
{
    public Guid UserId { get; init; }
    public string Message { get; init; } = "Plan override revoked successfully";
}
