using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MyTraderGEO.Domain.UserManagement.Aggregates;
using MyTraderGEO.Domain.UserManagement.Interfaces;
using MyTraderGEO.Domain.UserManagement.ValueObjects;
using MyTraderGEO.Infrastructure.Data;

namespace MyTraderGEO.Infrastructure.Persistence.Repositories;

/// <summary>
/// Repository: SubscriptionPlan
/// Maps between Domain.SubscriptionPlan and Infrastructure.Data.Models.SubscriptionPlan
/// </summary>
public sealed class SubscriptionPlanRepository : ISubscriptionPlanRepository
{
    private readonly ApplicationDbContext _context;

    public SubscriptionPlanRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<SubscriptionPlan?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var dataModel = await _context.SubscriptionPlans
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

        return dataModel != null ? MapToDomain(dataModel) : null;
    }

    public async Task<SubscriptionPlan?> GetByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        var dataModel = await _context.SubscriptionPlans
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Name == name, cancellationToken);

        return dataModel != null ? MapToDomain(dataModel) : null;
    }

    public async Task<IReadOnlyList<SubscriptionPlan>> GetAllActiveAsync(CancellationToken cancellationToken = default)
    {
        var dataModels = await _context.SubscriptionPlans
            .AsNoTracking()
            .Where(p => p.IsActive)
            .OrderBy(p => p.PriceMonthlyAmount)
            .ToListAsync(cancellationToken);

        return dataModels.Select(MapToDomain).ToList();
    }

    public async Task<bool> ExistsByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        return await _context.SubscriptionPlans
            .AnyAsync(p => p.Name == name, cancellationToken);
    }

    public async Task AddAsync(SubscriptionPlan plan, CancellationToken cancellationToken = default)
    {
        var dataModel = MapToDataModel(plan);
        await _context.SubscriptionPlans.AddAsync(dataModel, cancellationToken);
    }

    public Task UpdateAsync(SubscriptionPlan plan, CancellationToken cancellationToken = default)
    {
        var dataModel = MapToDataModel(plan);
        _context.SubscriptionPlans.Update(dataModel);
        return Task.CompletedTask;
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    // Mapping: Domain -> Data Model
    private static Data.Models.SubscriptionPlan MapToDataModel(SubscriptionPlan domain)
    {
        return new Data.Models.SubscriptionPlan
        {
            Id = domain.Id,
            Name = domain.Name,
            PriceMonthlyAmount = domain.PriceMonthly.Amount,
            PriceMonthlyCurrency = domain.PriceMonthly.Currency,
            PriceAnnualAmount = domain.PriceAnnual.Amount,
            PriceAnnualCurrency = domain.PriceAnnual.Currency,
            AnnualDiscountPercent = domain.AnnualDiscountPercent,
            StrategyLimit = domain.StrategyLimit,
            FeatureRealtimeData = domain.Features.RealtimeData,
            FeatureAdvancedAlerts = domain.Features.AdvancedAlerts,
            FeatureConsultingTools = domain.Features.ConsultingTools,
            FeatureCommunityAccess = domain.Features.CommunityAccess,
            IsActive = domain.IsActive,
            CreatedAt = domain.CreatedAt,
            UpdatedAt = domain.UpdatedAt
        };
    }

    // Mapping: Data Model -> Domain
    private static SubscriptionPlan MapToDomain(Data.Models.SubscriptionPlan dataModel)
    {
        var priceMonthly = Money.Create(dataModel.PriceMonthlyAmount, dataModel.PriceMonthlyCurrency);
        var priceAnnual = Money.Create(dataModel.PriceAnnualAmount, dataModel.PriceAnnualCurrency);
        var features = PlanFeatures.Create(
            dataModel.FeatureRealtimeData,
            dataModel.FeatureAdvancedAlerts,
            dataModel.FeatureConsultingTools,
            dataModel.FeatureCommunityAccess);

        var plan = SubscriptionPlan.Create(
            dataModel.Name,
            priceMonthly,
            priceAnnual,
            dataModel.AnnualDiscountPercent,
            dataModel.StrategyLimit,
            features);

        // Set private fields using reflection
        SetPrivateField(plan, "Id", dataModel.Id);
        SetPrivateField(plan, "IsActive", dataModel.IsActive);
        SetPrivateField(plan, "CreatedAt", dataModel.CreatedAt);
        SetPrivateField(plan, "UpdatedAt", dataModel.UpdatedAt);

        return plan;
    }

    private static void SetPrivateField(object obj, string fieldName, object? value)
    {
        var field = obj.GetType().GetField($"<{fieldName}>k__BackingField",
            System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
        field?.SetValue(obj, value);
    }
}
