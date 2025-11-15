<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# FEEDBACK-011-FE-SE-Backend-Integration-Fixes.md

> **Objetivo:** Resolver problemas críticos do backend C# que bloqueiam integração com frontend Vue 3.

---

**Data Abertura:** 2025-11-15
**Data Resolução:** _Aguardando implementação_
**Solicitante:** FE Agent (Frontend Engineer)
**Destinatário:** SE Agent (Software Engineer)
**Status:** 🔴 Aberto

**Tipo:**
- [x] Correção (deliverable já entregue precisa ajuste)
- [ ] Melhoria (sugestão de enhancement)
- [ ] Dúvida (esclarecimento necessário)
- [ ] Novo Requisito (mudança de escopo)

**Urgência:** 🔴 Alta (Bloqueia integração frontend-backend)

**Deliverable(s) Afetado(s):**
- `02-backend/src/MyTraderGEO.Infrastructure/Persistence/Repositories/UserRepository.cs` (JSONB deserialization TODO)
- `02-backend/src/MyTraderGEO.WebAPI/Program.cs` (Error handling middleware)
- `02-backend/src/MyTraderGEO.Application/UserManagement/Commands/*` (Input validation)
- `02-backend/src/MyTraderGEO.WebAPI/Controllers/AuthController.cs` (Error responses)

---

## 📋 Descrição

Durante análise do backend C# para preparar integração com frontend Vue 3, foram identificados **4 problemas críticos** que impedem o funcionamento correto dos endpoints de autenticação e gerenciamento de usuários.

O backend possui arquitetura sólida (Clean Architecture + DDD + CQRS), mas existem TODOs críticos comentados no código e falta de tratamento de erros centralizado.

### Contexto

**Frontend Vue 3** implementado (EPIC-01-A User Management):
- 5 páginas completas (Login, Signup, Dashboard, Profile, Subscription)
- Pinia store com auth management
- Mock login funcionando localmente
- Pronto para conectar ao backend real

**Backend C# Status Atual** (70-80% pronto):
- ✅ Domain models com validação rica
- ✅ JWT authentication configurado
- ✅ Repository pattern implementado
- ✅ MediatR + CQRS pattern
- ✅ Swagger/OpenAPI documentation
- ✅ PostgreSQL database em container Docker
- ❌ JSONB deserialization não implementada (TODO comentado)
- ❌ Error handling middleware ausente
- ❌ Input validation ausente (FluentValidation)
- ❌ Respostas de erro inconsistentes

### Problemas Identificados

#### 1. JSONB Deserialization (CRÍTICO)
**Arquivo:** `02-backend/src/MyTraderGEO.Infrastructure/Persistence/Repositories/UserRepository.cs`
**Linha:** 149
**Código atual:**
```csharp
// TODO: Deserialize PlanOverride and CustomFees from JSONB
// domain.PlanOverride = dataModel.PlanOverride != null
//     ? JsonSerializer.Deserialize<UserPlanOverride>(dataModel.PlanOverride)
//     : null;
```

**Problema:**
- `PlanOverride` e `CustomFees` são JSONB no PostgreSQL
- Não são deserializados ao recuperar usuário do banco
- `GET /api/users/me` retorna `null` para esses campos mesmo quando existem dados
- Frontend não consegue exibir planos VIP, trial, beta, staff overrides

**Impacto:**
- Usuários com plan override não veem suas permissões especiais
- Custom fees não aplicadas (usuários VIP pagam preço padrão)

---

#### 2. Error Handling Middleware (CRÍTICO)
**Arquivo:** `02-backend/src/MyTraderGEO.WebAPI/Program.cs`
**Problema:** Não existe middleware centralizado para tratamento de exceções

**Código atual (Controllers):**
```csharp
try
{
    var result = await _mediator.Send(command);
    return Ok(result);
}
catch (Exception ex)
{
    return BadRequest(new { error = ex.Message });
}
```

**Problemas:**
- Exceções não tratadas expõem stack traces em produção
- Respostas de erro inconsistentes entre controllers
- Sem logging estruturado de erros
- Frontend não consegue identificar tipo de erro (400? 401? 500?)

**Exemplo de erro atual:**
```json
{
  "error": "Email already exists"
}
```

**Exemplo esperado (RFC 7807 - Problem Details):**
```json
{
  "type": "https://api.mytrader.com/errors/email-already-exists",
  "title": "Email Already Exists",
  "status": 400,
  "detail": "The email 'joao@email.com' is already registered.",
  "traceId": "00-abc123..."
}
```

**Impacto:**
- Frontend não pode mostrar mensagens de erro amigáveis
- Debugging difícil (sem traceId correlacionado)
- Segurança comprometida (stack traces expostos)

---

#### 3. FluentValidation (MÉDIA PRIORIDADE)
**Arquivos:**
- `02-backend/src/MyTraderGEO.Application/UserManagement/Commands/RegisterTraderCommand.cs`
- `02-backend/src/MyTraderGEO.Application/UserManagement/Commands/LoginCommand.cs`

**Problema:** Validações estão dispersas entre Commands, Handlers e Domain

**Código atual (RegisterTraderCommandHandler):**
```csharp
// Validation inline no handler
if (await _userRepository.ExistsByEmailAsync(email))
{
    throw new InvalidOperationException("Email already exists");
}

if (!await _planRepository.ExistsAsync(command.SubscriptionPlanId))
{
    throw new InvalidOperationException("Subscription plan not found");
}
```

**Problemas:**
- Validação business logic misturada com orquestração
- Sem validação de input antes de processar (ex: email format)
- Mensagens de erro genéricas
- Violação do Single Responsibility Principle

**Solução esperada (FluentValidation):**
```csharp
public class RegisterTraderCommandValidator : AbstractValidator<RegisterTraderCommand>
{
    public RegisterTraderCommandValidator(IUserRepository userRepository, ISubscriptionPlanRepository planRepository)
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email é obrigatório")
            .EmailAddress().WithMessage("Email inválido")
            .MustAsync(async (email, ct) => !await userRepository.ExistsByEmailAsync(Email.Create(email), ct))
                .WithMessage("Email já cadastrado");

        RuleFor(x => x.SubscriptionPlanId)
            .MustAsync(async (id, ct) => await planRepository.ExistsAsync(id, ct))
                .WithMessage("Plano de assinatura inválido");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Senha é obrigatória")
            .MinimumLength(8).WithMessage("Senha deve ter no mínimo 8 caracteres");
    }
}
```

**Impacto:**
- Frontend recebe erros genéricos (não sabe qual campo está errado)
- UX ruim (usuário não sabe o que corrigir)
- Código backend menos manutenível

---

#### 4. Teste Manual via Swagger (VALIDAÇÃO)
**Problema:** Endpoints não foram testados manualmente

**Testes necessários:**
1. `POST /api/auth/register` - Criar usuário com plano Básico (id: 1)
2. `POST /api/auth/login` - Login com credenciais criadas
3. `GET /api/users/me` - Recuperar usuário autenticado (testar JWT)
4. `GET /api/plans` - Listar planos disponíveis

**Validações esperadas:**
- ✅ Registro com email único sucesso (201 Created)
- ❌ Registro com email duplicado falha (400 Bad Request)
- ✅ Login com credenciais corretas retorna JWT (200 OK)
- ❌ Login com senha errada falha (401 Unauthorized)
- ✅ GET /users/me com JWT válido retorna usuário (200 OK)
- ❌ GET /users/me sem JWT falha (401 Unauthorized)

**Impacto:**
- Sem testes manuais, não sabemos se endpoints funcionam corretamente
- Bloqueador para integração frontend

---

## 💥 Impacto Estimado

### Outros deliverables afetados:
- ❌ **Frontend Vue 3** - Bloqueado para integração (não pode conectar ao backend)
- ❌ **Phase 2 Features** - Upgrade Plan, Phone Management (dependem de backend funcionando)
- ⚠️ **API Documentation** - Swagger está correto, mas respostas de erro não documentadas

**Esforço estimado:** 4-6 horas (SE Agent)
**Risco:** 🔴 Alto (bloqueia progresso de EPIC-01-A)

**Justificativa do risco:**
- Frontend Vue 3 completo e aguardando backend funcional
- Usuário final aguardando signup/login funcionando end-to-end
- Phase 2 (upgrade plan, phone management) depende de integração funcionando
- Database já está em container Docker (apenas código backend precisa ajuste)

---

## 💡 Proposta de Solução

### Priorização

| Problema | Prioridade | Tempo Estimado | Bloqueante? |
|----------|------------|----------------|-------------|
| 1. JSONB Deserialization | 🔴 Alta | 30 min | ✅ Sim |
| 2. Error Handling Middleware | 🔴 Alta | 1 hora | ✅ Sim |
| 3. FluentValidation | 🟡 Média | 2 horas | ⚠️ Parcial |
| 4. Testes via Swagger | 🔴 Alta | 1 hora | ✅ Sim (validação) |

**Total estimado:** 4-5 horas

---

### Solução 1: JSONB Deserialization

**Arquivo:** `02-backend/src/MyTraderGEO.Infrastructure/Persistence/Repositories/UserRepository.cs`
**Linha:** 149-158

**Código atual:**
```csharp
// TODO: Deserialize PlanOverride and CustomFees from JSONB
// domain.PlanOverride = dataModel.PlanOverride != null
//     ? JsonSerializer.Deserialize<UserPlanOverride>(dataModel.PlanOverride)
//     : null;
```

**Código proposto:**
```csharp
// Deserialize PlanOverride from JSONB
if (!string.IsNullOrEmpty(dataModel.PlanOverride))
{
    try
    {
        var planOverrideData = JsonSerializer.Deserialize<Dictionary<string, object>>(dataModel.PlanOverride);
        if (planOverrideData != null)
        {
            var overrideType = planOverrideData["OverrideType"]?.ToString();
            var expiresAt = planOverrideData.ContainsKey("ExpiresAt") && planOverrideData["ExpiresAt"] != null
                ? DateTime.Parse(planOverrideData["ExpiresAt"].ToString())
                : (DateTime?)null;

            SetPrivateField(domain, "_planOverride", new UserPlanOverride(overrideType, expiresAt));
        }
    }
    catch (JsonException ex)
    {
        // Log warning but don't fail - backwards compatibility
        Console.WriteLine($"Warning: Failed to deserialize PlanOverride for user {dataModel.Id}: {ex.Message}");
    }
}

// Deserialize CustomFees from JSONB
if (!string.IsNullOrEmpty(dataModel.CustomFees))
{
    try
    {
        var feesData = JsonSerializer.Deserialize<Dictionary<string, decimal>>(dataModel.CustomFees);
        if (feesData != null)
        {
            var fees = new TradingFees(
                brokerCommissionRate: feesData.GetValueOrDefault("BrokerCommissionRate", 0),
                b3EmolumentRate: feesData.GetValueOrDefault("B3EmolumentRate", 0),
                settlementFeeRate: feesData.GetValueOrDefault("SettlementFeeRate", 0),
                issRate: feesData.GetValueOrDefault("IssRate", 0),
                incomeTaxRate: feesData.GetValueOrDefault("IncomeTaxRate", 0),
                dayTradeIncomeTaxRate: feesData.GetValueOrDefault("DayTradeIncomeTaxRate", 0)
            );
            SetPrivateField(domain, "_customFees", fees);
        }
    }
    catch (JsonException ex)
    {
        // Log warning but don't fail - backwards compatibility
        Console.WriteLine($"Warning: Failed to deserialize CustomFees for user {dataModel.Id}: {ex.Message}");
    }
}
```

**Validação:** Testar `GET /api/users/me` com usuário que tem PlanOverride no banco.

---

### Solução 2: Error Handling Middleware

**Passo 1:** Criar `GlobalExceptionHandlerMiddleware.cs`

**Arquivo novo:** `02-backend/src/MyTraderGEO.WebAPI/Middleware/GlobalExceptionHandlerMiddleware.cs`

```csharp
using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Text.Json;

namespace MyTraderGEO.WebAPI.Middleware;

public class GlobalExceptionHandlerMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlerMiddleware> _logger;

    public GlobalExceptionHandlerMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionHandlerMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var problemDetails = exception switch
        {
            InvalidOperationException => new ProblemDetails
            {
                Type = "https://api.mytrader.com/errors/business-rule-violation",
                Title = "Business Rule Violation",
                Status = (int)HttpStatusCode.BadRequest,
                Detail = exception.Message,
            },
            UnauthorizedAccessException => new ProblemDetails
            {
                Type = "https://api.mytrader.com/errors/unauthorized",
                Title = "Unauthorized",
                Status = (int)HttpStatusCode.Unauthorized,
                Detail = exception.Message,
            },
            _ => new ProblemDetails
            {
                Type = "https://api.mytrader.com/errors/internal-server-error",
                Title = "Internal Server Error",
                Status = (int)HttpStatusCode.InternalServerError,
                Detail = "An unexpected error occurred. Please try again later.",
            }
        };

        // Add traceId for debugging
        problemDetails.Extensions["traceId"] = context.TraceIdentifier;

        context.Response.ContentType = "application/problem+json";
        context.Response.StatusCode = problemDetails.Status ?? 500;

        var options = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        await context.Response.WriteAsync(JsonSerializer.Serialize(problemDetails, options));
    }
}
```

**Passo 2:** Registrar middleware em `Program.cs`

**Arquivo:** `02-backend/src/MyTraderGEO.WebAPI/Program.cs`
**Localização:** Após `app.UseHttpsRedirection()` (linha ~90)

```csharp
// Error Handling Middleware (MUST be before UseAuthentication)
app.UseMiddleware<GlobalExceptionHandlerMiddleware>();

app.UseAuthentication();
app.UseAuthorization();
```

**Passo 3:** Remover try-catch dos Controllers

**Arquivo:** `02-backend/src/MyTraderGEO.WebAPI/Controllers/AuthController.cs`

**ANTES:**
```csharp
try
{
    var result = await _mediator.Send(command);
    return Ok(result);
}
catch (Exception ex)
{
    return BadRequest(new { error = ex.Message });
}
```

**DEPOIS:**
```csharp
var result = await _mediator.Send(command);
return Ok(result);
```

**Validação:** Testar erro de "email já existe" e verificar resposta RFC 7807.

---

### Solução 3: FluentValidation

**Passo 1:** Adicionar NuGet package

**Arquivo:** `02-backend/src/MyTraderGEO.Application/MyTraderGEO.Application.csproj`

```xml
<PackageReference Include="FluentValidation" Version="11.9.0" />
<PackageReference Include="FluentValidation.DependencyInjectionExtensions" Version="11.9.0" />
```

**Passo 2:** Criar validator para `RegisterTraderCommand`

**Arquivo novo:** `02-backend/src/MyTraderGEO.Application/UserManagement/Commands/RegisterTraderCommandValidator.cs`

```csharp
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
            .MustAsync(ExistPlan).WithMessage("Plano de assinatura não encontrado");

        RuleFor(x => x.RiskProfile)
            .NotEmpty().WithMessage("Perfil de risco é obrigatório")
            .Must(BeValidRiskProfile).WithMessage("Perfil de risco inválido (opções: Conservador, Moderado, Agressivo)");

        RuleFor(x => x.BillingPeriod)
            .GreaterThan(0).WithMessage("Período de cobrança inválido")
            .Must(x => x == 1 || x == 12).WithMessage("Período de cobrança deve ser 1 (mensal) ou 12 (anual)");
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
            return false; // Email inválido (será capturado por .EmailAddress())
        }
    }

    private async Task<bool> ExistPlan(int planId, CancellationToken cancellationToken)
    {
        return await _planRepository.ExistsAsync(planId, cancellationToken);
    }

    private bool BeValidRiskProfile(string riskProfile)
    {
        var valid = new[] { "Conservador", "Moderado", "Agressivo" };
        return valid.Contains(riskProfile);
    }
}
```

**Passo 3:** Criar validator para `LoginCommand`

**Arquivo novo:** `02-backend/src/MyTraderGEO.Application/UserManagement/Commands/LoginCommandValidator.cs`

```csharp
using FluentValidation;

namespace MyTraderGEO.Application.UserManagement.Commands;

public class LoginCommandValidator : AbstractValidator<LoginCommand>
{
    public LoginCommandValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email é obrigatório")
            .EmailAddress().WithMessage("Email inválido");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Senha é obrigatória");
    }
}
```

**Passo 4:** Registrar validators no DI container

**Arquivo:** `02-backend/src/MyTraderGEO.WebAPI/Program.cs`
**Localização:** Após registrar MediatR (linha ~30)

```csharp
using FluentValidation;

// MediatR (já existente)
builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(applicationAssembly));

// FluentValidation (NOVO)
builder.Services.AddValidatorsFromAssembly(applicationAssembly);
builder.Services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
```

**Passo 5:** Criar `ValidationBehavior` (MediatR Pipeline)

**Arquivo novo:** `02-backend/src/MyTraderGEO.Application/Common/Behaviors/ValidationBehavior.cs`

```csharp
using FluentValidation;
using MediatR;

namespace MyTraderGEO.Application.Common.Behaviors;

public class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
    {
        _validators = validators;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        if (!_validators.Any())
        {
            return await next();
        }

        var context = new ValidationContext<TRequest>(request);

        var validationResults = await Task.WhenAll(
            _validators.Select(v => v.ValidateAsync(context, cancellationToken)));

        var failures = validationResults
            .Where(r => !r.IsValid)
            .SelectMany(r => r.Errors)
            .ToList();

        if (failures.Any())
        {
            throw new ValidationException(failures);
        }

        return await next();
    }
}
```

**Passo 6:** Atualizar `GlobalExceptionHandlerMiddleware` para capturar `ValidationException`

**Arquivo:** `02-backend/src/MyTraderGEO.WebAPI/Middleware/GlobalExceptionHandlerMiddleware.cs`

```csharp
using FluentValidation;

private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
{
    var problemDetails = exception switch
    {
        ValidationException validationException => new ProblemDetails
        {
            Type = "https://api.mytrader.com/errors/validation-error",
            Title = "Validation Error",
            Status = (int)HttpStatusCode.BadRequest,
            Detail = "One or more validation errors occurred.",
            Extensions =
            {
                ["errors"] = validationException.Errors
                    .GroupBy(e => e.PropertyName)
                    .ToDictionary(
                        g => g.Key,
                        g => g.Select(e => e.ErrorMessage).ToArray())
            }
        },
        InvalidOperationException => new ProblemDetails
        {
            // ... código existente
        },
        // ... resto do código
    };

    // ... resto do código
}
```

**Validação:** Testar registro com email inválido e verificar resposta com campo específico.

---

### Solução 4: Testes via Swagger

**Checklist de Testes Manuais:**

1. **Teste: Listar Planos Disponíveis**
   - Endpoint: `GET /api/plans`
   - Esperado: Lista com 3 planos (Básico, Pleno, Consultor)
   - Status: 200 OK

2. **Teste: Registro com Sucesso**
   - Endpoint: `POST /api/auth/register`
   - Body:
     ```json
     {
       "fullName": "João da Silva",
       "displayName": "João",
       "email": "joao.teste@email.com",
       "password": "Senha@123",
       "subscriptionPlanId": 1,
       "riskProfile": "Moderado",
       "billingPeriod": 1,
       "phoneCountryCode": "+55",
       "phoneNumber": "11987654321"
     }
     ```
   - Esperado: Status 201 Created com dados do usuário

3. **Teste: Registro com Email Duplicado**
   - Endpoint: `POST /api/auth/register`
   - Body: (mesmo email do teste anterior)
   - Esperado: Status 400 Bad Request
   - Response:
     ```json
     {
       "type": "https://api.mytrader.com/errors/validation-error",
       "title": "Validation Error",
       "status": 400,
       "detail": "One or more validation errors occurred.",
       "errors": {
         "Email": ["Email já cadastrado"]
       },
       "traceId": "..."
     }
     ```

4. **Teste: Login com Sucesso**
   - Endpoint: `POST /api/auth/login`
   - Body:
     ```json
     {
       "email": "joao.teste@email.com",
       "password": "Senha@123"
     }
     ```
   - Esperado: Status 200 OK com JWT token
   - Response:
     ```json
     {
       "token": "eyJhbGciOiJIUzI1NiIs...",
       "user": {
         "id": "...",
         "fullName": "João da Silva",
         "email": "joao.teste@email.com",
         ...
       }
     }
     ```

5. **Teste: Login com Senha Incorreta**
   - Endpoint: `POST /api/auth/login`
   - Body: (email correto, senha errada)
   - Esperado: Status 401 Unauthorized
   - Response:
     ```json
     {
       "type": "https://api.mytrader.com/errors/unauthorized",
       "title": "Unauthorized",
       "status": 401,
       "detail": "Invalid credentials",
       "traceId": "..."
     }
     ```

6. **Teste: Obter Usuário Atual (Autenticado)**
   - Endpoint: `GET /api/users/me`
   - Headers: `Authorization: Bearer {token do teste 4}`
   - Esperado: Status 200 OK com dados completos do usuário
   - **Validar:** `planOverride` e `customFees` não são `null` se existirem no banco

7. **Teste: Obter Usuário Atual (Não Autenticado)**
   - Endpoint: `GET /api/users/me`
   - Headers: (sem Authorization)
   - Esperado: Status 401 Unauthorized

**Documentação:** Criar arquivo `02-backend/docs/API-Testing-Checklist.md` com esses testes.

---

## 📋 Checklist de Implementação

### SE Agent:

- [ ] **JSONB Deserialization (30 min)**
  - [ ] Descomentar e implementar deserialization de `PlanOverride`
  - [ ] Descomentar e implementar deserialization de `CustomFees`
  - [ ] Adicionar try-catch para backwards compatibility
  - [ ] Testar com usuário que tem PlanOverride no banco

- [ ] **Error Handling Middleware (1 hora)**
  - [ ] Criar `GlobalExceptionHandlerMiddleware.cs`
  - [ ] Implementar RFC 7807 Problem Details
  - [ ] Registrar middleware em `Program.cs`
  - [ ] Remover try-catch dos Controllers
  - [ ] Testar resposta de erro padronizada

- [ ] **FluentValidation (2 horas)**
  - [ ] Adicionar NuGet packages (FluentValidation + DI Extensions)
  - [ ] Criar `RegisterTraderCommandValidator`
  - [ ] Criar `LoginCommandValidator`
  - [ ] Criar `ValidationBehavior` (MediatR pipeline)
  - [ ] Registrar validators no DI container
  - [ ] Atualizar `GlobalExceptionHandlerMiddleware` para `ValidationException`
  - [ ] Remover validações inline dos Handlers
  - [ ] Testar validação com input inválido

- [ ] **Testes Manuais via Swagger (1 hora)**
  - [ ] Executar checklist de 7 testes documentado acima
  - [ ] Validar respostas de sucesso (200, 201)
  - [ ] Validar respostas de erro (400, 401)
  - [ ] Validar JWT authentication funcionando
  - [ ] Validar JSONB deserialization (planOverride, customFees)
  - [ ] Documentar resultados em `02-backend/docs/API-Testing-Checklist.md`

- [ ] **Validação Final**
  - [ ] Todos os 7 testes manuais passando ✅
  - [ ] Respostas de erro seguem RFC 7807 ✅
  - [ ] JSONB fields deserializando corretamente ✅
  - [ ] Validações retornam campos específicos ✅
  - [ ] Notificar FE Agent que backend está pronto para integração

---

## ✅ Resolução

> _Seção preenchida pelo agent destinatário após resolver_

**Data Resolução:** _Aguardando implementação_
**Resolvido por:** SE Agent

**Ação Tomada:**
_Pendente_

**Deliverables Atualizados:**
- [ ] `02-backend/src/MyTraderGEO.Infrastructure/Persistence/Repositories/UserRepository.cs`
- [ ] `02-backend/src/MyTraderGEO.WebAPI/Middleware/GlobalExceptionHandlerMiddleware.cs`
- [ ] `02-backend/src/MyTraderGEO.WebAPI/Program.cs`
- [ ] `02-backend/src/MyTraderGEO.Application/UserManagement/Commands/RegisterTraderCommandValidator.cs`
- [ ] `02-backend/src/MyTraderGEO.Application/UserManagement/Commands/LoginCommandValidator.cs`
- [ ] `02-backend/src/MyTraderGEO.Application/Common/Behaviors/ValidationBehavior.cs`
- [ ] `02-backend/docs/API-Testing-Checklist.md`

**Referência Git Commit:** _Pendente_

---

**Status Atual:** 🔴 Aberto (Aguardando implementação do SE Agent)

---

## 📝 Histórico

| Data | Mudança | Autor |
|------|---------|-------|
| 2025-11-15 | Criado (após análise completa do backend C# para integração com frontend Vue 3) | FE Agent |

---

## 📚 Referências Técnicas

### RFC 7807 - Problem Details for HTTP APIs
- [RFC 7807 Specification](https://datatracker.ietf.org/doc/html/rfc7807)
- Exemplo Microsoft: [ASP.NET Core Problem Details](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.mvc.problemdetails)

### FluentValidation
- [FluentValidation Documentation](https://docs.fluentvalidation.net/)
- [ASP.NET Core Integration](https://docs.fluentvalidation.net/en/latest/aspnet.html)
- [MediatR Pipeline Behavior](https://github.com/jbogard/MediatR/wiki/Behaviors)

### PostgreSQL JSONB
- [PostgreSQL JSONB Type](https://www.postgresql.org/docs/current/datatype-json.html)
- [System.Text.Json Deserialization](https://learn.microsoft.com/en-us/dotnet/standard/serialization/system-text-json/how-to)

### Código de Referência (Backend Atual)
- User Repository: `02-backend/src/MyTraderGEO.Infrastructure/Persistence/Repositories/UserRepository.cs` (linhas 149-158)
- Auth Controller: `02-backend/src/MyTraderGEO.WebAPI/Controllers/AuthController.cs`
- Register Handler: `02-backend/src/MyTraderGEO.Application/UserManagement/Handlers/RegisterTraderCommandHandler.cs`
- Login Handler: `02-backend/src/MyTraderGEO.Application/UserManagement/Handlers/LoginCommandHandler.cs`
- Program.cs: `02-backend/src/MyTraderGEO.WebAPI/Program.cs`

### Próximos Passos (Após Resolução)
- FE Agent: Criar API Service Layer (`src/services/api.ts`, `src/services/auth.service.ts`)
- FE Agent: Atualizar authStore para usar backend real
- FE Agent: Configurar variáveis de ambiente (.env.local)
- FE Agent: Implementar Phase 2 (Upgrade Plan, Phone Management)
