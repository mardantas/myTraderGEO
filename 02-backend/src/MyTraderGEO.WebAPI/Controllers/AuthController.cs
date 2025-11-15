using MediatR;
using Microsoft.AspNetCore.Mvc;
using MyTraderGEO.Application.UserManagement.Commands;

namespace MyTraderGEO.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IMediator mediator, ILogger<AuthController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    /// <summary>
    /// Register a new trader
    /// </summary>
    [HttpPost("register")]
    [ProducesResponseType(typeof(RegisterTraderCommandResult), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register([FromBody] RegisterTraderCommand command)
    {
        var result = await _mediator.Send(command);
        _logger.LogInformation("Trader registered: {UserId} - {Email}", result.UserId, result.Email);
        return CreatedAtAction(nameof(Register), new { id = result.UserId }, result);
    }

    /// <summary>
    /// User login
    /// </summary>
    [HttpPost("login")]
    [ProducesResponseType(typeof(LoginCommandResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginCommand command)
    {
        var result = await _mediator.Send(command);
        _logger.LogInformation("User logged in: {Email}", result.Email);
        return Ok(result);
    }
}
