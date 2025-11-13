using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyTraderGEO.Application.UserManagement.Commands;
using MyTraderGEO.Domain.UserManagement.Interfaces;

namespace MyTraderGEO.WebAPI.Controllers;

/// <summary>
/// System configuration endpoints for administrators
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SystemController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ISystemConfigRepository _systemConfigRepository;

    public SystemController(IMediator mediator, ISystemConfigRepository systemConfigRepository)
    {
        _mediator = mediator;
        _systemConfigRepository = systemConfigRepository;
    }

    /// <summary>
    /// Get current system configuration (fees and limits)
    /// </summary>
    /// <remarks>
    /// Accessible by Administrators and Moderators
    /// </remarks>
    [HttpGet("config")]
    [Authorize(Policy = "RequireModerator")]
    public async Task<IActionResult> GetSystemConfig()
    {
        var systemConfig = await _systemConfigRepository.GetAsync(HttpContext.RequestAborted);

        if (systemConfig == null)
        {
            return NotFound(new { message = "System configuration not found. Please initialize the system first." });
        }

        return Ok(new
        {
            id = systemConfig.Id,
            fees = new
            {
                brokerCommissionRate = systemConfig.Fees.BrokerCommissionRate,
                b3EmolumentRate = systemConfig.Fees.B3EmolumentRate,
                settlementFeeRate = systemConfig.Fees.SettlementFeeRate,
                incomeTaxRate = systemConfig.Fees.IncomeTaxRate,
                dayTradeIncomeTaxRate = systemConfig.Fees.DayTradeIncomeTaxRate
            },
            maxOpenStrategiesPerUser = systemConfig.MaxOpenStrategiesPerUser,
            maxStrategiesInTemplate = systemConfig.MaxStrategiesInTemplate,
            updatedAt = systemConfig.UpdatedAt,
            updatedBy = systemConfig.UpdatedBy
        });
    }

    /// <summary>
    /// Update system parameters (fees and/or limits)
    /// </summary>
    /// <remarks>
    /// Only Administrators can update system configuration.
    /// All fields are optional - only provided values will be updated.
    /// </remarks>
    [HttpPut("config")]
    [Authorize(Policy = "RequireAdministrator")]
    public async Task<IActionResult> UpdateSystemConfig([FromBody] UpdateSystemConfigRequest request)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var administratorId))
        {
            return Unauthorized(new { message = "Invalid or missing user ID in token" });
        }

        var command = new UpdateSystemParametersCommand
        {
            AdministratorId = administratorId,
            BrokerCommissionRate = request.BrokerCommissionRate,
            B3EmolumentRate = request.B3EmolumentRate,
            SettlementFeeRate = request.SettlementFeeRate,
            IncomeTaxRate = request.IncomeTaxRate,
            DayTradeIncomeTaxRate = request.DayTradeIncomeTaxRate,
            MaxOpenStrategiesPerUser = request.MaxOpenStrategiesPerUser,
            MaxStrategiesInTemplate = request.MaxStrategiesInTemplate
        };

        var result = await _mediator.Send(command);
        return Ok(result);
    }
}

/// <summary>
/// Request model for updating system configuration
/// </summary>
public sealed record UpdateSystemConfigRequest
{
    /// <summary>
    /// Broker commission rate (e.g., 0.0003 for 0.03%)
    /// </summary>
    public decimal? BrokerCommissionRate { get; init; }

    /// <summary>
    /// B3 emolument rate (e.g., 0.000325 for 0.0325%)
    /// </summary>
    public decimal? B3EmolumentRate { get; init; }

    /// <summary>
    /// Settlement fee rate (e.g., 0.000025 for 0.0025%)
    /// </summary>
    public decimal? SettlementFeeRate { get; init; }

    /// <summary>
    /// Income tax rate for normal operations (e.g., 0.15 for 15%)
    /// </summary>
    public decimal? IncomeTaxRate { get; init; }

    /// <summary>
    /// Income tax rate for day trade operations (e.g., 0.20 for 20%)
    /// </summary>
    public decimal? DayTradeIncomeTaxRate { get; init; }

    /// <summary>
    /// Maximum number of open strategies per user
    /// </summary>
    public int? MaxOpenStrategiesPerUser { get; init; }

    /// <summary>
    /// Maximum number of strategies allowed in a template
    /// </summary>
    public int? MaxStrategiesInTemplate { get; init; }
}
