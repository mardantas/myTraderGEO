using FluentValidation;
using MyTraderGEO.Domain.UserManagement.Interfaces;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Application.UserManagement.Commands;

public class RegisterTraderCommandValidator : AbstractValidator<RegisterTraderCommand>
{
    private readonly IUserRepository _userRepository;
    private readonly ISubscriptionPlanRepository _planRepository;

    public RegisterTraderCommandValidator(
        IUserRepository userRepository,
        ISubscriptionPlanRepository planRepository)
    {
        _userRepository = userRepository;
        _planRepository = planRepository;

        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Nome completo é obrigatório")
            .MaximumLength(200).WithMessage("Nome completo deve ter no máximo 200 caracteres");

        RuleFor(x => x.DisplayName)
            .NotEmpty().WithMessage("Nome de exibição é obrigatório")
            .MaximumLength(100).WithMessage("Nome de exibição deve ter no máximo 100 caracteres");

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email é obrigatório")
            .EmailAddress().WithMessage("Email inválido")
            .MustAsync(BeUniqueEmail).WithMessage("Email já cadastrado");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Senha é obrigatória")
            .MinimumLength(8).WithMessage("Senha deve ter no mínimo 8 caracteres")
            .MaximumLength(128).WithMessage("Senha deve ter no máximo 128 caracteres");

        RuleFor(x => x.SubscriptionPlanId)
            .GreaterThan(0).WithMessage("Plano de assinatura inválido")
            .MustAsync(ExistsPlan).WithMessage("Plano de assinatura não encontrado");

        RuleFor(x => x.RiskProfile)
            .IsInEnum().WithMessage("Perfil de risco inválido");

        RuleFor(x => x.BillingPeriod)
            .IsInEnum().WithMessage("Período de cobrança inválido");
    }

    private async Task<bool> BeUniqueEmail(string email, CancellationToken cancellationToken)
    {
        try
        {
            var emailVO = Email.Create(email);
            return !await _userRepository.ExistsByEmailAsync(emailVO, cancellationToken);
        }
        catch
        {
            // Email format invalid (will be caught by .EmailAddress() rule)
            return false;
        }
    }

    private async Task<bool> ExistsPlan(int planId, CancellationToken cancellationToken)
    {
        var plan = await _planRepository.GetByIdAsync(planId, cancellationToken);
        return plan != null;
    }
}
