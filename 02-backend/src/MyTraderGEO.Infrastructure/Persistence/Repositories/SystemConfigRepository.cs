using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MyTraderGEO.Domain.UserManagement.Aggregates;
using MyTraderGEO.Domain.UserManagement.Interfaces;
using MyTraderGEO.Domain.UserManagement.ValueObjects;
using MyTraderGEO.Infrastructure.Data;

namespace MyTraderGEO.Infrastructure.Persistence.Repositories;

/// <summary>
/// Repository: SystemConfig (Singleton)
/// Maps between Domain.SystemConfig and Infrastructure.Data.Models.SystemConfig
/// </summary>
public sealed class SystemConfigRepository : ISystemConfigRepository
{
    private readonly ApplicationDbContext _context;

    public SystemConfigRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<SystemConfig?> GetAsync(CancellationToken cancellationToken = default)
    {
        var dataModel = await _context.SystemConfigs
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == SystemConfig.SingletonId, cancellationToken);

        return dataModel != null ? MapToDomain(dataModel) : null;
    }

    public async Task UpsertAsync(SystemConfig config, CancellationToken cancellationToken = default)
    {
        var dataModel = MapToDataModel(config);

        var existing = await _context.SystemConfigs
            .FirstOrDefaultAsync(c => c.Id == SystemConfig.SingletonId, cancellationToken);

        if (existing != null)
        {
            _context.Entry(existing).CurrentValues.SetValues(dataModel);
        }
        else
        {
            await _context.SystemConfigs.AddAsync(dataModel, cancellationToken);
        }
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    // Mapping: Domain -> Data Model
    private static Data.Models.SystemConfig MapToDataModel(SystemConfig domain)
    {
        return new Data.Models.SystemConfig
        {
            Id = domain.Id,
            BrokerCommissionRate = domain.Fees.BrokerCommissionRate ?? 0,
            B3EmolumentRate = domain.Fees.B3EmolumentRate ?? 0,
            SettlementFeeRate = domain.Fees.SettlementFeeRate ?? 0,
            IssRate = 0.05m, // 5% ISS (hardcoded for now)
            IncomeTaxRate = domain.Fees.IncomeTaxRate ?? 0,
            DayTradeIncomeTaxRate = domain.Fees.DayTradeIncomeTaxRate ?? 0,
            MaxOpenStrategiesPerUser = domain.MaxOpenStrategiesPerUser,
            MaxStrategiesInTemplate = domain.MaxStrategiesInTemplate,
            UpdatedAt = domain.UpdatedAt,
            UpdatedBy = domain.UpdatedBy
        };
    }

    // Mapping: Data Model -> Domain
    private static SystemConfig MapToDomain(Data.Models.SystemConfig dataModel)
    {
        var fees = TradingFees.Create(
            dataModel.BrokerCommissionRate,
            dataModel.B3EmolumentRate,
            dataModel.SettlementFeeRate,
            dataModel.IncomeTaxRate,
            dataModel.DayTradeIncomeTaxRate);

        var config = SystemConfig.CreateDefault(dataModel.UpdatedBy);

        // Set private fields using reflection
        SetPrivateField(config, "Id", dataModel.Id);
        SetPrivateField(config, "Fees", fees);
        SetPrivateField(config, "MaxOpenStrategiesPerUser", dataModel.MaxOpenStrategiesPerUser);
        SetPrivateField(config, "MaxStrategiesInTemplate", dataModel.MaxStrategiesInTemplate);
        SetPrivateField(config, "UpdatedAt", dataModel.UpdatedAt);
        SetPrivateField(config, "UpdatedBy", dataModel.UpdatedBy);

        return config;
    }

    private static void SetPrivateField(object obj, string fieldName, object? value)
    {
        var field = obj.GetType().GetField($"<{fieldName}>k__BackingField",
            System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
        field?.SetValue(obj, value);
    }
}
