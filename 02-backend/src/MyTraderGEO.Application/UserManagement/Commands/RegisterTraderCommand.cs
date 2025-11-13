using System;
using MediatR;
using MyTraderGEO.Domain.UserManagement.Enums;

namespace MyTraderGEO.Application.UserManagement.Commands;

/// <summary>
/// Command: Register a new Trader
/// UC-User-01: RegisterTrader
/// </summary>
public sealed record RegisterTraderCommand : IRequest<RegisterTraderCommandResult>
{
    public string Email { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string DisplayName { get; init; } = string.Empty;
    public RiskProfile RiskProfile { get; init; }
    public Guid SubscriptionPlanId { get; init; }
    public BillingPeriod BillingPeriod { get; init; }
}

public sealed record RegisterTraderCommandResult
{
    public Guid UserId { get; init; }
    public string Email { get; init; } = string.Empty;
    public string Message { get; init; } = "Trader registered successfully";
}
