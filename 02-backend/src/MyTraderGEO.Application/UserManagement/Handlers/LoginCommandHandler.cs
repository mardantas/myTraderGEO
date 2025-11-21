using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using MyTraderGEO.Application.UserManagement.Commands;
using MyTraderGEO.Application.UserManagement.Services;
using MyTraderGEO.Domain.UserManagement.Enums;
using MyTraderGEO.Domain.UserManagement.Interfaces;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Application.UserManagement.Handlers;

/// <summary>
/// Handler: User Login
/// UC-User-02: Login
/// </summary>
public sealed class LoginCommandHandler
    : IRequestHandler<LoginCommand, LoginCommandResult>
{
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenGenerator _jwtTokenGenerator;
    private readonly ILogger<LoginCommandHandler> _logger;

    public LoginCommandHandler(
        IUserRepository userRepository,
        IPasswordHasher passwordHasher,
        IJwtTokenGenerator jwtTokenGenerator,
        ILogger<LoginCommandHandler> logger)
    {
        _userRepository = userRepository;
        _passwordHasher = passwordHasher;
        _jwtTokenGenerator = jwtTokenGenerator;
        _logger = logger;
    }

    public async Task<LoginCommandResult> Handle(
        LoginCommand request,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation("🔍 [DEBUG] Login attempt for email: {Email}", request.Email);

        // 1. Validate email format
        var email = Email.Create(request.Email);
        _logger.LogInformation("🔍 [DEBUG] Email validated: {Email}", email.Value);

        // 2. Find user by email
        var user = await _userRepository.GetByEmailAsync(email, cancellationToken);
        if (user == null)
        {
            _logger.LogWarning("❌ [DEBUG] User not found for email: {Email}", email.Value);
            throw new UnauthorizedAccessException("Email ou senha inválidos");
        }

        _logger.LogInformation("✅ [DEBUG] User found: {Email}, Role: {Role}, Status: {Status}",
            user.Email.Value, user.Role, user.Status);

        // 3. Verify password
        _logger.LogInformation("🔍 [DEBUG] Verifying password... Hash starts with: {HashPrefix}",
            user.PasswordHash.Value.Substring(0, Math.Min(20, user.PasswordHash.Value.Length)));

        var passwordValid = _passwordHasher.VerifyPassword(request.Password, user.PasswordHash);

        _logger.LogInformation("🔍 [DEBUG] Password verification result: {IsValid}", passwordValid);

        if (!passwordValid)
        {
            _logger.LogWarning("❌ [DEBUG] Password verification failed for: {Email}", email.Value);
            throw new UnauthorizedAccessException("Email ou senha inválidos");
        }

        // 4. Check user status
        if (user.Status != UserStatus.Active)
            throw new UnauthorizedAccessException($"Conta de usuário está {user.Status}");

        // 5. Record login
        user.RecordLogin();
        await _userRepository.UpdateAsync(user, cancellationToken);
        await _userRepository.SaveChangesAsync(cancellationToken);

        // 6. Generate JWT token
        var token = _jwtTokenGenerator.GenerateToken(user);

        // 7. Return result
        return new LoginCommandResult
        {
            Token = token,
            Email = user.Email,
            Role = user.Role.ToString(),
            Message = "Login realizado com sucesso"
        };
    }
}
