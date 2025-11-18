using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MyTraderGEO.Domain.UserManagement.Aggregates;
using MyTraderGEO.Domain.UserManagement.Interfaces;
using MyTraderGEO.Domain.UserManagement.ValueObjects;
using MyTraderGEO.Infrastructure.Data;

namespace MyTraderGEO.Infrastructure.Persistence.Repositories;

/// <summary>
/// Repository: User
/// Maps between Domain.User and Infrastructure.Data.Models.User
/// </summary>
public sealed class UserRepository : IUserRepository
{
    private readonly ApplicationDbContext _context;

    public UserRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var dataModel = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);

        return dataModel != null ? MapToDomain(dataModel) : null;
    }

    public async Task<User?> GetByEmailAsync(Email email, CancellationToken cancellationToken = default)
    {
        var emailValue = email.Value.ToLowerInvariant();
        var dataModel = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Email.ToLower() == emailValue, cancellationToken);

        return dataModel != null ? MapToDomain(dataModel) : null;
    }

    public async Task<bool> ExistsByEmailAsync(Email email, CancellationToken cancellationToken = default)
    {
        var emailValue = email.Value.ToLowerInvariant();
        return await _context.Users
            .AnyAsync(u => u.Email.ToLower() == emailValue, cancellationToken);
    }

    public async Task AddAsync(User user, CancellationToken cancellationToken = default)
    {
        var dataModel = MapToDataModel(user);
        await _context.Users.AddAsync(dataModel, cancellationToken);
    }

    public Task UpdateAsync(User user, CancellationToken cancellationToken = default)
    {
        var dataModel = MapToDataModel(user);
        _context.Users.Update(dataModel);
        return Task.CompletedTask;
    }

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    // Mapping: Domain -> Data Model
    private static Data.Models.User MapToDataModel(User domain)
    {
        return new Data.Models.User
        {
            Id = domain.Id,
            Email = domain.Email,
            PasswordHash = domain.PasswordHash,
            FullName = domain.FullName,
            DisplayName = domain.DisplayName,
            PhoneCountryCode = domain.Phone?.CountryCode,
            PhoneNumber = domain.Phone?.Number,
            IsPhoneVerified = domain.IsPhoneVerified,
            PhoneVerifiedAt = domain.PhoneVerifiedAt,
            Role = domain.Role.ToString(),
            Status = domain.Status.ToString(),
            RiskProfile = domain.RiskProfile?.ToString(),
            SubscriptionPlanId = domain.SubscriptionPlanId,
            BillingPeriod = (int?)domain.BillingPeriod,
            PlanOverride = domain.PlanOverride != null ? SerializePlanOverride(domain.PlanOverride) : null,
            CustomFees = domain.CustomFees != null ? SerializeCustomFees(domain.CustomFees) : null,
            CreatedAt = domain.CreatedAt,
            LastLoginAt = domain.LastLoginAt
        };
    }

    // Mapping: Data Model -> Domain (using reflection to set private fields)
    private static User MapToDomain(Data.Models.User dataModel)
    {
        // Create email
        var email = Email.Create(dataModel.Email);
        var passwordHash = PasswordHash.FromHash(dataModel.PasswordHash);

        // Parse enums
        var role = Enum.Parse<Domain.UserManagement.Enums.UserRole>(dataModel.Role);
        var status = Enum.Parse<Domain.UserManagement.Enums.UserStatus>(dataModel.Status);
        var riskProfile = dataModel.RiskProfile != null
            ? Enum.Parse<Domain.UserManagement.Enums.RiskProfile>(dataModel.RiskProfile)
            : (Domain.UserManagement.Enums.RiskProfile?)null;
        var billingPeriod = dataModel.BillingPeriod.HasValue
            ? (Domain.UserManagement.Enums.BillingPeriod)dataModel.BillingPeriod.Value
            : (Domain.UserManagement.Enums.BillingPeriod?)null;

        // Create user based on role
        User user;
        if (role == Domain.UserManagement.Enums.UserRole.Trader)
        {
            user = User.RegisterTrader(
                email,
                passwordHash,
                dataModel.FullName,
                dataModel.DisplayName,
                riskProfile!.Value,
                dataModel.SubscriptionPlanId!.Value,
                billingPeriod!.Value);
        }
        else if (role == Domain.UserManagement.Enums.UserRole.Administrator)
        {
            user = User.RegisterAdministrator(email, passwordHash, dataModel.FullName, dataModel.DisplayName);
        }
        else
        {
            user = User.RegisterModerator(email, passwordHash, dataModel.FullName, dataModel.DisplayName);
        }

        // Set private fields using reflection
        SetPrivateField(user, "Id", dataModel.Id);
        SetPrivateField(user, "Status", status);
        SetPrivateField(user, "CreatedAt", DateTime.SpecifyKind(dataModel.CreatedAt, DateTimeKind.Utc));
        SetPrivateField(user, "LastLoginAt", dataModel.LastLoginAt.HasValue
            ? DateTime.SpecifyKind(dataModel.LastLoginAt.Value, DateTimeKind.Utc)
            : (DateTime?)null);

        // Phone
        if (dataModel.PhoneCountryCode != null && dataModel.PhoneNumber != null)
        {
            var phone = PhoneNumber.Create(dataModel.PhoneCountryCode, dataModel.PhoneNumber);
            SetPrivateField(user, "Phone", phone);
            SetPrivateField(user, "IsPhoneVerified", dataModel.IsPhoneVerified);
            SetPrivateField(user, "PhoneVerifiedAt", dataModel.PhoneVerifiedAt.HasValue
                ? DateTime.SpecifyKind(dataModel.PhoneVerifiedAt.Value, DateTimeKind.Utc)
                : (DateTime?)null);
        }

        // Deserialize PlanOverride from JSONB
        if (!string.IsNullOrEmpty(dataModel.PlanOverride))
        {
            try
            {
                var planOverrideData = System.Text.Json.JsonSerializer.Deserialize<System.Text.Json.JsonElement>(dataModel.PlanOverride);

                var strategyLimit = planOverrideData.TryGetProperty("strategyLimitOverride", out var slProp) && slProp.ValueKind != System.Text.Json.JsonValueKind.Null
                    ? slProp.GetInt32() : (int?)null;

                var expiresAt = planOverrideData.TryGetProperty("expiresAt", out var expProp) && expProp.ValueKind != System.Text.Json.JsonValueKind.Null
                    ? DateTime.SpecifyKind(expProp.GetDateTime(), DateTimeKind.Utc) : (DateTime?)null;

                var reason = planOverrideData.TryGetProperty("reason", out var reasonProp) ? reasonProp.GetString() : string.Empty;
                var grantedBy = planOverrideData.TryGetProperty("grantedBy", out var grantedByProp) ? grantedByProp.GetGuid() : Guid.Empty;
                var grantedAt = planOverrideData.TryGetProperty("grantedAt", out var grantedAtProp)
                    ? DateTime.SpecifyKind(grantedAtProp.GetDateTime(), DateTimeKind.Utc)
                    : DateTime.UtcNow;

                if (!string.IsNullOrEmpty(reason) && grantedBy != Guid.Empty)
                {
                    // Use reflection to create UserPlanOverride (constructor is private)
                    var planOverride = typeof(UserPlanOverride)
                        .GetConstructor(
                            System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance,
                            null,
                            new[] { typeof(int?), typeof(PlanFeatures), typeof(DateTime?), typeof(string), typeof(Guid), typeof(DateTime) },
                            null)
                        ?.Invoke(new object?[] { strategyLimit, null, expiresAt, reason, grantedBy, grantedAt }) as UserPlanOverride;

                    if (planOverride != null)
                    {
                        SetPrivateField(user, "PlanOverride", planOverride);
                    }
                }
            }
            catch (System.Text.Json.JsonException ex)
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
                var feesData = System.Text.Json.JsonSerializer.Deserialize<System.Text.Json.JsonElement>(dataModel.CustomFees);

                var brokerCommissionRate = feesData.TryGetProperty("brokerCommissionRate", out var bcProp) && bcProp.ValueKind != System.Text.Json.JsonValueKind.Null
                    ? bcProp.GetDecimal() : (decimal?)null;

                var b3EmolumentRate = feesData.TryGetProperty("b3EmolumentRate", out var b3Prop) && b3Prop.ValueKind != System.Text.Json.JsonValueKind.Null
                    ? b3Prop.GetDecimal() : (decimal?)null;

                var settlementFeeRate = feesData.TryGetProperty("settlementFeeRate", out var sfProp) && sfProp.ValueKind != System.Text.Json.JsonValueKind.Null
                    ? sfProp.GetDecimal() : (decimal?)null;

                var incomeTaxRate = feesData.TryGetProperty("incomeTaxRate", out var itProp) && itProp.ValueKind != System.Text.Json.JsonValueKind.Null
                    ? itProp.GetDecimal() : (decimal?)null;

                var dayTradeIncomeTaxRate = feesData.TryGetProperty("dayTradeIncomeTaxRate", out var dtProp) && dtProp.ValueKind != System.Text.Json.JsonValueKind.Null
                    ? dtProp.GetDecimal() : (decimal?)null;

                var customFees = TradingFees.Create(
                    brokerCommissionRate: brokerCommissionRate,
                    b3EmolumentRate: b3EmolumentRate,
                    settlementFeeRate: settlementFeeRate,
                    incomeTaxRate: incomeTaxRate,
                    dayTradeIncomeTaxRate: dayTradeIncomeTaxRate);

                if (customFees.HasCustomFees)
                {
                    SetPrivateField(user, "CustomFees", customFees);
                }
            }
            catch (System.Text.Json.JsonException ex)
            {
                // Log warning but don't fail - backwards compatibility
                Console.WriteLine($"Warning: Failed to deserialize CustomFees for user {dataModel.Id}: {ex.Message}");
            }
        }

        return user;
    }

    private static void SetPrivateField(object obj, string fieldName, object? value)
    {
        var field = obj.GetType().GetField($"<{fieldName}>k__BackingField",
            System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
        field?.SetValue(obj, value);
    }

    private static string? SerializePlanOverride(UserPlanOverride planOverride)
    {
        // TODO: Serialize to JSON
        return System.Text.Json.JsonSerializer.Serialize(new
        {
            strategyLimitOverride = planOverride.StrategyLimitOverride,
            expiresAt = planOverride.ExpiresAt,
            reason = planOverride.Reason,
            grantedBy = planOverride.GrantedBy,
            grantedAt = planOverride.GrantedAt
        });
    }

    private static string? SerializeCustomFees(TradingFees fees)
    {
        // TODO: Serialize to JSON
        return System.Text.Json.JsonSerializer.Serialize(new
        {
            brokerCommissionRate = fees.BrokerCommissionRate,
            b3EmolumentRate = fees.B3EmolumentRate,
            settlementFeeRate = fees.SettlementFeeRate,
            incomeTaxRate = fees.IncomeTaxRate,
            dayTradeIncomeTaxRate = fees.DayTradeIncomeTaxRate
        });
    }
}
