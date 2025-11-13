using MediatR;

namespace MyTraderGEO.Application.UserManagement.Commands;

/// <summary>
/// Command: User Login
/// UC-User-02: Login
/// </summary>
public sealed record LoginCommand : IRequest<LoginCommandResult>
{
    public string Email { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
}

public sealed record LoginCommandResult
{
    public string Token { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public string Message { get; init; } = "Login successful";
}
