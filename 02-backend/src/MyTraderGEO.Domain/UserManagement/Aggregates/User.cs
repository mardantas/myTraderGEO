using System;
using MyTraderGEO.Domain.UserManagement.Enums;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Domain.UserManagement.Aggregates;

/// <summary>
/// Aggregate Root: User
/// Represents a user with authentication, profile, subscription, and permissions
/// </summary>
public class User
{
    public Guid Id { get; private set; }

    // Authentication
    public Email Email { get; private set; } = null!;
    public PasswordHash PasswordHash { get; private set; } = null!;

    // Profile
    public string FullName { get; private set; } = null!;
    public string DisplayName { get; private set; } = null!;

    // Phone (for WhatsApp, 2FA, recovery)
    public PhoneNumber? Phone { get; private set; }
    public bool IsPhoneVerified { get; private set; }
    public DateTime? PhoneVerifiedAt { get; private set; }

    // Role & Status
    public UserRole Role { get; private set; }
    public UserStatus Status { get; private set; }

    // Risk Profile (for Traders only)
    public RiskProfile? RiskProfile { get; private set; }

    // Subscription (for Traders only)
    public int? SubscriptionPlanId { get; private set; }
    public BillingPeriod? BillingPeriod { get; private set; }

    // Plan Override (VIP, trial, beta, staff)
    public UserPlanOverride? PlanOverride { get; private set; }

    // Custom Trading Fees
    public TradingFees? CustomFees { get; private set; }

    // Audit
    public DateTime CreatedAt { get; private set; }
    public DateTime? LastLoginAt { get; private set; }

    // EF Core constructor
    private User() { }

    private User(
        Email email,
        PasswordHash passwordHash,
        string fullName,
        string displayName,
        UserRole role)
    {
        Id = Guid.NewGuid();
        Email = email;
        PasswordHash = passwordHash;
        FullName = fullName;
        DisplayName = displayName;
        Role = role;
        Status = UserStatus.Active;
        IsPhoneVerified = false;
        CreatedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Registers a new Trader
    /// </summary>
    public static User RegisterTrader(
        Email email,
        PasswordHash passwordHash,
        string fullName,
        string displayName,
        RiskProfile riskProfile,
        int subscriptionPlanId,
        BillingPeriod billingPeriod)
    {
        ValidateFullName(fullName);
        ValidateDisplayName(displayName);

        if (subscriptionPlanId <= 0)
            throw new ArgumentException("Subscription plan is required for Traders", nameof(subscriptionPlanId));

        var user = new User(email, passwordHash, fullName.Trim(), displayName.Trim(), UserRole.Trader)
        {
            RiskProfile = riskProfile,
            SubscriptionPlanId = subscriptionPlanId,
            BillingPeriod = billingPeriod
        };

        return user;
    }

    /// <summary>
    /// Registers a new Administrator
    /// </summary>
    public static User RegisterAdministrator(
        Email email,
        PasswordHash passwordHash,
        string fullName,
        string displayName)
    {
        ValidateFullName(fullName);
        ValidateDisplayName(displayName);

        return new User(email, passwordHash, fullName.Trim(), displayName.Trim(), UserRole.Administrator);
    }

    /// <summary>
    /// Registers a new Moderator
    /// </summary>
    public static User RegisterModerator(
        Email email,
        PasswordHash passwordHash,
        string fullName,
        string displayName)
    {
        ValidateFullName(fullName);
        ValidateDisplayName(displayName);

        return new User(email, passwordHash, fullName.Trim(), displayName.Trim(), UserRole.Moderator);
    }

    // Validation helpers
    private static void ValidateFullName(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName))
            throw new ArgumentException("Full name cannot be empty", nameof(fullName));

        if (fullName.Length > 255)
            throw new ArgumentException("Full name cannot exceed 255 characters", nameof(fullName));
    }

    private static void ValidateDisplayName(string displayName)
    {
        if (string.IsNullOrWhiteSpace(displayName))
            throw new ArgumentException("Display name cannot be empty", nameof(displayName));

        if (displayName.Length < 2 || displayName.Length > 30)
            throw new ArgumentException("Display name must be between 2 and 30 characters", nameof(displayName));
    }

    /// <summary>
    /// Updates user profile
    /// </summary>
    public void UpdateProfile(string? displayName = null, RiskProfile? riskProfile = null)
    {
        if (displayName != null)
        {
            ValidateDisplayName(displayName);
            DisplayName = displayName.Trim();
        }

        if (riskProfile.HasValue)
        {
            if (Role != UserRole.Trader)
                throw new InvalidOperationException("Only traders can have a risk profile");

            RiskProfile = riskProfile.Value;
        }
    }

    /// <summary>
    /// Adds or updates phone number
    /// </summary>
    public void SetPhone(PhoneNumber phone)
    {
        Phone = phone ?? throw new ArgumentNullException(nameof(phone));
        IsPhoneVerified = false;
        PhoneVerifiedAt = null;
    }

    /// <summary>
    /// Verifies phone number
    /// </summary>
    public void VerifyPhone()
    {
        if (Phone == null)
            throw new InvalidOperationException("Cannot verify phone: no phone number set");

        if (IsPhoneVerified)
            throw new InvalidOperationException("Phone is already verified");

        IsPhoneVerified = true;
        PhoneVerifiedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Changes user password
    /// </summary>
    public void ChangePassword(PasswordHash newPasswordHash)
    {
        PasswordHash = newPasswordHash ?? throw new ArgumentNullException(nameof(newPasswordHash));
    }

    /// <summary>
    /// Updates subscription plan
    /// </summary>
    public void UpdateSubscription(int subscriptionPlanId, BillingPeriod billingPeriod)
    {
        if (Role != UserRole.Trader)
            throw new InvalidOperationException("Only traders can have subscriptions");

        if (subscriptionPlanId <= 0)
            throw new ArgumentException("Subscription plan cannot be empty", nameof(subscriptionPlanId));

        SubscriptionPlanId = subscriptionPlanId;
        BillingPeriod = billingPeriod;
    }

    /// <summary>
    /// Grants plan override (VIP, trial, beta, staff)
    /// </summary>
    public void GrantPlanOverride(UserPlanOverride planOverride)
    {
        if (Role != UserRole.Trader)
            throw new InvalidOperationException("Only traders can receive plan overrides");

        PlanOverride = planOverride ?? throw new ArgumentNullException(nameof(planOverride));
    }

    /// <summary>
    /// Revokes plan override
    /// </summary>
    public void RevokePlanOverride()
    {
        if (PlanOverride == null)
            throw new InvalidOperationException("No plan override to revoke");

        PlanOverride = null;
    }

    /// <summary>
    /// Sets custom trading fees
    /// </summary>
    public void SetCustomFees(TradingFees? customFees)
    {
        CustomFees = customFees;
    }

    /// <summary>
    /// Gets effective strategy limit (considers plan override)
    /// </summary>
    public int GetEffectiveStrategyLimit(int planLimit)
    {
        if (PlanOverride?.IsActive == true && PlanOverride.StrategyLimitOverride.HasValue)
            return PlanOverride.StrategyLimitOverride.Value;

        return planLimit;
    }

    /// <summary>
    /// Gets effective plan features (considers plan override)
    /// </summary>
    public PlanFeatures GetEffectiveFeatures(PlanFeatures planFeatures)
    {
        if (PlanOverride?.IsActive == true && PlanOverride.FeaturesOverride != null)
            return PlanOverride.FeaturesOverride;

        return planFeatures;
    }

    /// <summary>
    /// Records user login
    /// </summary>
    public void RecordLogin()
    {
        LastLoginAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Suspends user account
    /// </summary>
    public void Suspend()
    {
        if (Status == UserStatus.Suspended)
            throw new InvalidOperationException("User is already suspended");

        if (Status == UserStatus.Deleted)
            throw new InvalidOperationException("Cannot suspend a deleted user");

        Status = UserStatus.Suspended;
    }

    /// <summary>
    /// Reactivates user account
    /// </summary>
    public void Reactivate()
    {
        if (Status == UserStatus.Active)
            throw new InvalidOperationException("User is already active");

        if (Status == UserStatus.Deleted)
            throw new InvalidOperationException("Cannot reactivate a deleted user");

        Status = UserStatus.Active;
    }

    /// <summary>
    /// Soft deletes user account
    /// </summary>
    public void Delete()
    {
        if (Status == UserStatus.Deleted)
            throw new InvalidOperationException("User is already deleted");

        Status = UserStatus.Deleted;
    }
}
