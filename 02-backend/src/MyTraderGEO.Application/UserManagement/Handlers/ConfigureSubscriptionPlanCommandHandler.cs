using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using MyTraderGEO.Application.UserManagement.Commands;
using MyTraderGEO.Domain.UserManagement.Aggregates;
using MyTraderGEO.Domain.UserManagement.Interfaces;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Application.UserManagement.Handlers;

/// <summary>
/// Handler: Configure (Create/Update) Subscription Plan
/// UC-Admin-01: ConfigureSubscriptionPlan
/// </summary>
public sealed class ConfigureSubscriptionPlanCommandHandler
    : IRequestHandler<ConfigureSubscriptionPlanCommand, ConfigureSubscriptionPlanCommandResult>
{
    private readonly ISubscriptionPlanRepository _planRepository;

    public ConfigureSubscriptionPlanCommandHandler(ISubscriptionPlanRepository planRepository)
    {
        _planRepository = planRepository;
    }

    public async Task<ConfigureSubscriptionPlanCommandResult> Handle(
        ConfigureSubscriptionPlanCommand request,
        CancellationToken cancellationToken)
    {
        if (request.PlanId.HasValue)
        {
            // UPDATE existing plan
            var plan = await _planRepository.GetByIdAsync(request.PlanId.Value, cancellationToken);
            if (plan == null)
                throw new InvalidOperationException($"Subscription plan {request.PlanId.Value} not found");

            // Update pricing
            var monthlyPrice = Money.BRL(request.PriceMonthlyAmount);
            var annualPrice = Money.BRL(request.PriceAnnualAmount);
            plan.UpdatePricing(monthlyPrice, annualPrice, request.AnnualDiscountPercent);

            // Update strategy limit
            plan.UpdateStrategyLimit(request.StrategyLimit);

            // Update features
            var features = PlanFeatures.Create(
                request.FeatureRealtimeData,
                request.FeatureAdvancedAlerts,
                request.FeatureConsultingTools,
                request.FeatureCommunityAccess);
            plan.UpdateFeatures(features);

            await _planRepository.UpdateAsync(plan, cancellationToken);
            await _planRepository.SaveChangesAsync(cancellationToken);

            return new ConfigureSubscriptionPlanCommandResult
            {
                PlanId = plan.Id,
                Name = plan.Name,
                Message = $"Subscription plan '{plan.Name}' updated successfully"
            };
        }
        else
        {
            // CREATE new plan
            // Check if name already exists
            var existingPlan = await _planRepository.GetByNameAsync(request.Name, cancellationToken);
            if (existingPlan != null)
                throw new InvalidOperationException($"Subscription plan with name '{request.Name}' already exists");

            var monthlyPrice = Money.BRL(request.PriceMonthlyAmount);
            var annualPrice = Money.BRL(request.PriceAnnualAmount);
            var features = PlanFeatures.Create(
                request.FeatureRealtimeData,
                request.FeatureAdvancedAlerts,
                request.FeatureConsultingTools,
                request.FeatureCommunityAccess);

            var plan = SubscriptionPlan.Create(
                request.Name,
                monthlyPrice,
                annualPrice,
                request.AnnualDiscountPercent,
                request.StrategyLimit,
                features);

            await _planRepository.AddAsync(plan, cancellationToken);
            await _planRepository.SaveChangesAsync(cancellationToken);

            return new ConfigureSubscriptionPlanCommandResult
            {
                PlanId = plan.Id,
                Name = plan.Name,
                Message = $"Subscription plan '{plan.Name}' created successfully"
            };
        }
    }
}
