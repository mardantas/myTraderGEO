using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using MyTraderGEO.Application.UserManagement.Commands;
using MyTraderGEO.Domain.UserManagement.Interfaces;

namespace MyTraderGEO.Application.UserManagement.Handlers;

/// <summary>
/// Handler: Revoke Plan Override from User
/// UC-Admin-04: RevokePlanOverride
/// </summary>
public sealed class RevokePlanOverrideCommandHandler
    : IRequestHandler<RevokePlanOverrideCommand, RevokePlanOverrideCommandResult>
{
    private readonly IUserRepository _userRepository;

    public RevokePlanOverrideCommandHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<RevokePlanOverrideCommandResult> Handle(
        RevokePlanOverrideCommand request,
        CancellationToken cancellationToken)
    {
        // 1. Get user
        var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
        if (user == null)
            throw new InvalidOperationException($"Usuário {request.UserId} não encontrado");

        // 2. Revoke plan override
        user.RevokePlanOverride();

        // 3. Save changes
        await _userRepository.UpdateAsync(user, cancellationToken);
        await _userRepository.SaveChangesAsync(cancellationToken);

        return new RevokePlanOverrideCommandResult
        {
            UserId = user.Id,
            Message = "Override de plano revogado com sucesso"
        };
    }
}
