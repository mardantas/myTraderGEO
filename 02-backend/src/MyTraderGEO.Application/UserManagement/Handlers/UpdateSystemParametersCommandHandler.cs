using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using MyTraderGEO.Application.UserManagement.Commands;
using MyTraderGEO.Domain.UserManagement.Interfaces;

namespace MyTraderGEO.Application.UserManagement.Handlers;

/// <summary>
/// Handler: Update System Parameters (Fees and Limits)
/// UC-Admin-02: UpdateSystemParameters
/// </summary>
public sealed class UpdateSystemParametersCommandHandler
    : IRequestHandler<UpdateSystemParametersCommand, UpdateSystemParametersCommandResult>
{
    private readonly ISystemConfigRepository _systemConfigRepository;

    public UpdateSystemParametersCommandHandler(ISystemConfigRepository systemConfigRepository)
    {
        _systemConfigRepository = systemConfigRepository;
    }

    public async Task<UpdateSystemParametersCommandResult> Handle(
        UpdateSystemParametersCommand request,
        CancellationToken cancellationToken)
    {
        // Get system config (singleton)
        var systemConfig = await _systemConfigRepository.GetAsync(cancellationToken);
        if (systemConfig == null)
            throw new InvalidOperationException("System configuration not found. Please initialize the system first.");

        // Update fees if provided
        if (request.BrokerCommissionRate.HasValue
            || request.B3EmolumentRate.HasValue
            || request.SettlementFeeRate.HasValue
            || request.IncomeTaxRate.HasValue
            || request.DayTradeIncomeTaxRate.HasValue)
        {
            systemConfig.UpdateFees(
                request.BrokerCommissionRate,
                request.B3EmolumentRate,
                request.SettlementFeeRate,
                request.IncomeTaxRate,
                request.DayTradeIncomeTaxRate,
                request.AdministratorId);
        }

        // Update limits if provided
        if (request.MaxOpenStrategiesPerUser.HasValue || request.MaxStrategiesInTemplate.HasValue)
        {
            systemConfig.UpdateLimits(
                request.MaxOpenStrategiesPerUser ?? systemConfig.MaxOpenStrategiesPerUser,
                request.MaxStrategiesInTemplate ?? systemConfig.MaxStrategiesInTemplate,
                request.AdministratorId);
        }

        await _systemConfigRepository.UpsertAsync(systemConfig, cancellationToken);
        await _systemConfigRepository.SaveChangesAsync(cancellationToken);

        return new UpdateSystemParametersCommandResult
        {
            Message = "System parameters updated successfully"
        };
    }
}
