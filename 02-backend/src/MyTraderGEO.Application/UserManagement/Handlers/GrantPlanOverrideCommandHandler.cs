using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using MyTraderGEO.Application.UserManagement.Commands;
using MyTraderGEO.Domain.UserManagement.Interfaces;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Application.UserManagement.Handlers;

/// <summary>
/// Handler: Grant Plan Override to User
/// UC-Admin-03: GrantPlanOverride
/// </summary>
public sealed class GrantPlanOverrideCommandHandler
    : IRequestHandler<GrantPlanOverrideCommand, GrantPlanOverrideCommandResult>
{
    private readonly IUserRepository _userRepository;

    public GrantPlanOverrideCommandHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<GrantPlanOverrideCommandResult> Handle(
        GrantPlanOverrideCommand request,
        CancellationToken cancellationToken)
    {
        // 1. Get user
        var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
        if (user == null)
            throw new InvalidOperationException($"Usuário {request.UserId} não encontrado");

        // 2. Create feature override if any features specified
        PlanFeatures? featuresOverride = null;
        if (request.FeatureRealtimeDataOverride.HasValue
            || request.FeatureAdvancedAlertsOverride.HasValue
            || request.FeatureConsultingToolsOverride.HasValue
            || request.FeatureCommunityAccessOverride.HasValue)
        {
            featuresOverride = PlanFeatures.Create(
                request.FeatureRealtimeDataOverride ?? false,
                request.FeatureAdvancedAlertsOverride ?? false,
                request.FeatureConsultingToolsOverride ?? false,
                request.FeatureCommunityAccessOverride ?? true);
        }

        // 3. Create plan override
        var planOverride = UserPlanOverride.Create(
            request.AdministratorId,
            request.Reason,
            request.StrategyLimitOverride,
            featuresOverride,
            request.ExpiresAt);

        // 4. Grant override to user
        user.GrantPlanOverride(planOverride);

        // 5. Save changes
        await _userRepository.UpdateAsync(user, cancellationToken);
        await _userRepository.SaveChangesAsync(cancellationToken);

        return new GrantPlanOverrideCommandResult
        {
            UserId = user.Id,
            Message = $"Override de plano concedido com sucesso. Motivo: {request.Reason}"
        };
    }
}
