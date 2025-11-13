using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
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

    public LoginCommandHandler(
        IUserRepository userRepository,
        IPasswordHasher passwordHasher,
        IJwtTokenGenerator jwtTokenGenerator)
    {
        _userRepository = userRepository;
        _passwordHasher = passwordHasher;
        _jwtTokenGenerator = jwtTokenGenerator;
    }

    public async Task<LoginCommandResult> Handle(
        LoginCommand request,
        CancellationToken cancellationToken)
    {
        // 1. Validate email format
        var email = Email.Create(request.Email);

        // 2. Find user by email
        var user = await _userRepository.GetByEmailAsync(email, cancellationToken);
        if (user == null)
            throw new UnauthorizedAccessException("Invalid email or password");

        // 3. Verify password
        var passwordValid = _passwordHasher.VerifyPassword(request.Password, user.PasswordHash);
        if (!passwordValid)
            throw new UnauthorizedAccessException("Invalid email or password");

        // 4. Check user status
        if (user.Status != UserStatus.Active)
            throw new UnauthorizedAccessException($"User account is {user.Status}");

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
            Message = "Login successful"
        };
    }
}
