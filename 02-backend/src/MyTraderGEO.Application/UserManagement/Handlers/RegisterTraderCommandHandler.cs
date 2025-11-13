using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using MyTraderGEO.Application.UserManagement.Commands;
using MyTraderGEO.Application.UserManagement.Services;
using MyTraderGEO.Domain.UserManagement.Aggregates;
using MyTraderGEO.Domain.UserManagement.Interfaces;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Application.UserManagement.Handlers;

/// <summary>
/// Handler: Register a new Trader
/// UC-User-01: RegisterTrader
/// </summary>
public sealed class RegisterTraderCommandHandler
    : IRequestHandler<RegisterTraderCommand, RegisterTraderCommandResult>
{
    private readonly IUserRepository _userRepository;
    private readonly ISubscriptionPlanRepository _planRepository;
    private readonly IPasswordHasher _passwordHasher;

    public RegisterTraderCommandHandler(
        IUserRepository userRepository,
        ISubscriptionPlanRepository planRepository,
        IPasswordHasher passwordHasher)
    {
        _userRepository = userRepository;
        _planRepository = planRepository;
        _passwordHasher = passwordHasher;
    }

    public async Task<RegisterTraderCommandResult> Handle(
        RegisterTraderCommand request,
        CancellationToken cancellationToken)
    {
        // 1. Validate email format
        var email = Email.Create(request.Email);

        // 2. Check if email already exists
        var emailExists = await _userRepository.ExistsByEmailAsync(email, cancellationToken);
        if (emailExists)
            throw new InvalidOperationException($"Email {request.Email} is already registered");

        // 3. Validate subscription plan exists
        var plan = await _planRepository.GetByIdAsync(request.SubscriptionPlanId, cancellationToken);
        if (plan == null)
            throw new InvalidOperationException($"Subscription plan {request.SubscriptionPlanId} not found");

        if (!plan.IsActive)
            throw new InvalidOperationException($"Subscription plan {plan.Name} is not active");

        // 4. Hash password
        var passwordHash = _passwordHasher.HashPassword(request.Password);

        // 5. Create user aggregate
        var user = User.RegisterTrader(
            email,
            passwordHash,
            request.FullName,
            request.DisplayName,
            request.RiskProfile,
            request.SubscriptionPlanId,
            request.BillingPeriod);

        // 6. Save user
        await _userRepository.AddAsync(user, cancellationToken);
        await _userRepository.SaveChangesAsync(cancellationToken);

        // 7. Return result
        return new RegisterTraderCommandResult
        {
            UserId = user.Id,
            Email = user.Email,
            Message = "Trader registered successfully"
        };
    }
}
