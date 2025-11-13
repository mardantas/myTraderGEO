using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyTraderGEO.Application.UserManagement.Commands;
using MyTraderGEO.Domain.UserManagement.Interfaces;

namespace MyTraderGEO.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PlansController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ISubscriptionPlanRepository _planRepository;
    private readonly ILogger<PlansController> _logger;

    public PlansController(
        IMediator mediator,
        ISubscriptionPlanRepository planRepository,
        ILogger<PlansController> logger)
    {
        _mediator = mediator;
        _planRepository = planRepository;
        _logger = logger;
    }

    /// <summary>
    /// Get all active subscription plans
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetActivePlans()
    {
        var plans = await _planRepository.GetAllActiveAsync();
        return Ok(plans);
    }

    /// <summary>
    /// Get subscription plan by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPlanById(Guid id)
    {
        var plan = await _planRepository.GetByIdAsync(id);
        if (plan == null)
            return NotFound(new { error = "Subscription plan not found" });

        return Ok(plan);
    }

    /// <summary>
    /// Create or update a subscription plan (Admin only)
    /// </summary>
    [HttpPost]
    [Authorize(Policy = "RequireAdministrator")]
    [ProducesResponseType(typeof(ConfigureSubscriptionPlanCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> ConfigurePlan([FromBody] ConfigureSubscriptionPlanCommand command)
    {
        try
        {
            var result = await _mediator.Send(command);
            _logger.LogInformation("Subscription plan configured: {PlanId} - {Name}", result.PlanId, result.Name);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error configuring subscription plan");
            return BadRequest(new { error = ex.Message });
        }
    }
}
