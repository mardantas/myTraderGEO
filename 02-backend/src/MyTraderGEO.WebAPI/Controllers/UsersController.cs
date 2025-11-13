using System.Security.Claims;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyTraderGEO.Application.UserManagement.Commands;
using MyTraderGEO.Domain.UserManagement.Interfaces;

namespace MyTraderGEO.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<UsersController> _logger;

    public UsersController(
        IMediator mediator,
        IUserRepository userRepository,
        ILogger<UsersController> logger)
    {
        _mediator = mediator;
        _userRepository = userRepository;
        _logger = logger;
    }

    /// <summary>
    /// Get current user profile
    /// </summary>
    [HttpGet("me")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCurrentUser()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
            return Unauthorized(new { error = "Invalid user ID in token" });

        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null)
            return NotFound(new { error = "User not found" });

        return Ok(new
        {
            id = user.Id,
            email = user.Email.ToString(),
            fullName = user.FullName,
            displayName = user.DisplayName,
            role = user.Role.ToString(),
            status = user.Status.ToString(),
            riskProfile = user.RiskProfile?.ToString(),
            subscriptionPlanId = user.SubscriptionPlanId,
            billingPeriod = user.BillingPeriod?.ToString(),
            createdAt = user.CreatedAt,
            lastLoginAt = user.LastLoginAt
        });
    }

    /// <summary>
    /// Grant plan override to a user (Admin only)
    /// </summary>
    [HttpPost("{id:guid}/plan-override")]
    [Authorize(Policy = "RequireAdministrator")]
    [ProducesResponseType(typeof(GrantPlanOverrideCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GrantPlanOverride(
        Guid id,
        [FromBody] GrantPlanOverrideRequest request)
    {
        try
        {
            var adminIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(adminIdClaim) || !Guid.TryParse(adminIdClaim, out var adminId))
                return Unauthorized(new { error = "Invalid admin ID in token" });

            var command = new GrantPlanOverrideCommand
            {
                UserId = id,
                AdministratorId = adminId,
                Reason = request.Reason,
                StrategyLimitOverride = request.StrategyLimitOverride,
                FeatureRealtimeDataOverride = request.FeatureRealtimeDataOverride,
                FeatureAdvancedAlertsOverride = request.FeatureAdvancedAlertsOverride,
                FeatureConsultingToolsOverride = request.FeatureConsultingToolsOverride,
                FeatureCommunityAccessOverride = request.FeatureCommunityAccessOverride,
                ExpiresAt = request.ExpiresAt
            };

            var result = await _mediator.Send(command);
            _logger.LogInformation("Plan override granted to user {UserId} by admin {AdminId}", id, adminId);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error granting plan override to user {UserId}", id);
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Revoke plan override from a user (Admin only)
    /// </summary>
    [HttpDelete("{id:guid}/plan-override")]
    [Authorize(Policy = "RequireAdministrator")]
    [ProducesResponseType(typeof(RevokePlanOverrideCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> RevokePlanOverride(Guid id)
    {
        try
        {
            var command = new RevokePlanOverrideCommand { UserId = id };
            var result = await _mediator.Send(command);
            _logger.LogInformation("Plan override revoked from user {UserId}", id);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error revoking plan override from user {UserId}", id);
            return BadRequest(new { error = ex.Message });
        }
    }
}

public record GrantPlanOverrideRequest(
    string Reason,
    int? StrategyLimitOverride = null,
    bool? FeatureRealtimeDataOverride = null,
    bool? FeatureAdvancedAlertsOverride = null,
    bool? FeatureConsultingToolsOverride = null,
    bool? FeatureCommunityAccessOverride = null,
    DateTime? ExpiresAt = null
);
