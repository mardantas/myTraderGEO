using System;
using MediatR;

namespace MyTraderGEO.Application.UserManagement.Commands;

/// <summary>
/// Command: Update System Parameters (Fees and Limits)
/// UC-Admin-02: UpdateSystemParameters
/// </summary>
public sealed record UpdateSystemParametersCommand : IRequest<UpdateSystemParametersCommandResult>
{
    public Guid AdministratorId { get; init; }

    // Trading Fees
    public decimal? BrokerCommissionRate { get; init; }
    public decimal? B3EmolumentRate { get; init; }
    public decimal? SettlementFeeRate { get; init; }
    public decimal? IncomeTaxRate { get; init; }
    public decimal? DayTradeIncomeTaxRate { get; init; }

    // Global Limits
    public int? MaxOpenStrategiesPerUser { get; init; }
    public int? MaxStrategiesInTemplate { get; init; }
}

public sealed record UpdateSystemParametersCommandResult
{
    public string Message { get; init; } = "System parameters updated successfully";
}
