using FluentAssertions;
using MyTraderGEO.Domain.UserManagement.Aggregates;
using MyTraderGEO.Domain.UserManagement.Enums;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Domain.UnitTests.Aggregates;

public class UserTests
{
    private static readonly Email ValidEmail = Email.Create("test@example.com");
    private static readonly PasswordHash ValidHash = PasswordHash.FromHash("$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy");

    #region RegisterTrader Tests

    [Fact]
    public void RegisterTrader_WithValidData_ShouldCreateTrader()
    {
        // Act
        var user = User.RegisterTrader(
            ValidEmail,
            ValidHash,
            "João da Silva",
            "João",
            RiskProfile.Moderado,
            1,
            BillingPeriod.Monthly);

        // Assert
        user.Id.Should().NotBeEmpty();
        user.Email.Should().Be(ValidEmail);
        user.FullName.Should().Be("João da Silva");
        user.DisplayName.Should().Be("João");
        user.Role.Should().Be(UserRole.Trader);
        user.Status.Should().Be(UserStatus.Active);
        user.RiskProfile.Should().Be(RiskProfile.Moderado);
        user.SubscriptionPlanId.Should().Be(1);
        user.BillingPeriod.Should().Be(BillingPeriod.Monthly);
        user.IsPhoneVerified.Should().BeFalse();
        user.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public void RegisterTrader_WithEmptyFullName_ShouldThrow(string? fullName)
    {
        // Act
        var act = () => User.RegisterTrader(
            ValidEmail, ValidHash, fullName!, "João",
            RiskProfile.Moderado, 1, BillingPeriod.Monthly);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Full name cannot be empty*");
    }

    [Fact]
    public void RegisterTrader_WithLongFullName_ShouldThrow()
    {
        // Arrange
        var longName = new string('a', 256);

        // Act
        var act = () => User.RegisterTrader(
            ValidEmail, ValidHash, longName, "João",
            RiskProfile.Moderado, 1, BillingPeriod.Monthly);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*exceed 255 characters*");
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public void RegisterTrader_WithEmptyDisplayName_ShouldThrow(string? displayName)
    {
        // Act
        var act = () => User.RegisterTrader(
            ValidEmail, ValidHash, "João da Silva", displayName!,
            RiskProfile.Moderado, 1, BillingPeriod.Monthly);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Display name cannot be empty*");
    }

    [Theory]
    [InlineData("A")]
    [InlineData("ThisDisplayNameIsTooLongForTheLimit")]
    public void RegisterTrader_WithInvalidDisplayNameLength_ShouldThrow(string displayName)
    {
        // Act
        var act = () => User.RegisterTrader(
            ValidEmail, ValidHash, "João da Silva", displayName,
            RiskProfile.Moderado, 1, BillingPeriod.Monthly);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*between 2 and 30 characters*");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void RegisterTrader_WithInvalidPlanId_ShouldThrow(int planId)
    {
        // Act
        var act = () => User.RegisterTrader(
            ValidEmail, ValidHash, "João da Silva", "João",
            RiskProfile.Moderado, planId, BillingPeriod.Monthly);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Subscription plan is required*");
    }

    #endregion

    #region RegisterAdministrator Tests

    [Fact]
    public void RegisterAdministrator_WithValidData_ShouldCreateAdmin()
    {
        // Act
        var user = User.RegisterAdministrator(
            ValidEmail, ValidHash, "Admin User", "Admin");

        // Assert
        user.Role.Should().Be(UserRole.Administrator);
        user.Status.Should().Be(UserStatus.Active);
        user.SubscriptionPlanId.Should().BeNull();
        user.RiskProfile.Should().BeNull();
    }

    #endregion

    #region RegisterModerator Tests

    [Fact]
    public void RegisterModerator_WithValidData_ShouldCreateModerator()
    {
        // Act
        var user = User.RegisterModerator(
            ValidEmail, ValidHash, "Mod User", "Mod");

        // Assert
        user.Role.Should().Be(UserRole.Moderator);
        user.Status.Should().Be(UserStatus.Active);
    }

    #endregion

    #region UpdateProfile Tests

    [Fact]
    public void UpdateProfile_WithNewDisplayName_ShouldUpdate()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        user.UpdateProfile(displayName: "NewName");

        // Assert
        user.DisplayName.Should().Be("NewName");
    }

    [Fact]
    public void UpdateProfile_WithNewRiskProfile_ShouldUpdate()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        user.UpdateProfile(riskProfile: RiskProfile.Agressivo);

        // Assert
        user.RiskProfile.Should().Be(RiskProfile.Agressivo);
    }

    [Fact]
    public void UpdateProfile_RiskProfileForNonTrader_ShouldThrow()
    {
        // Arrange
        var user = User.RegisterAdministrator(ValidEmail, ValidHash, "Admin", "Admin");

        // Act
        var act = () => user.UpdateProfile(riskProfile: RiskProfile.Conservador);

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*Only traders can have a risk profile*");
    }

    #endregion

    #region Phone Tests

    [Fact]
    public void SetPhone_ShouldSetPhoneAndResetVerification()
    {
        // Arrange
        var user = CreateTrader();
        var phone = PhoneNumber.CreateBrazilian("11987654321");

        // Act
        user.SetPhone(phone);

        // Assert
        user.Phone.Should().Be(phone);
        user.IsPhoneVerified.Should().BeFalse();
        user.PhoneVerifiedAt.Should().BeNull();
    }

    [Fact]
    public void SetPhone_WithNull_ShouldThrow()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        var act = () => user.SetPhone(null!);

        // Assert
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void VerifyPhone_ShouldSetVerified()
    {
        // Arrange
        var user = CreateTrader();
        user.SetPhone(PhoneNumber.CreateBrazilian("11987654321"));

        // Act
        user.VerifyPhone();

        // Assert
        user.IsPhoneVerified.Should().BeTrue();
        user.PhoneVerifiedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
    }

    [Fact]
    public void VerifyPhone_WithoutPhone_ShouldThrow()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        var act = () => user.VerifyPhone();

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*no phone number set*");
    }

    [Fact]
    public void VerifyPhone_AlreadyVerified_ShouldThrow()
    {
        // Arrange
        var user = CreateTrader();
        user.SetPhone(PhoneNumber.CreateBrazilian("11987654321"));
        user.VerifyPhone();

        // Act
        var act = () => user.VerifyPhone();

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*already verified*");
    }

    #endregion

    #region Password Tests

    [Fact]
    public void ChangePassword_ShouldUpdateHash()
    {
        // Arrange
        var user = CreateTrader();
        var newHash = PasswordHash.FromHash("$2a$11$CU7P9krXbKiJNhFlXbVlNeJj0XiAMQ3f9uMKl0X6Zzf0wjBvXA8Sy");

        // Act
        user.ChangePassword(newHash);

        // Assert
        user.PasswordHash.Should().Be(newHash);
    }

    [Fact]
    public void ChangePassword_WithNull_ShouldThrow()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        var act = () => user.ChangePassword(null!);

        // Assert
        act.Should().Throw<ArgumentNullException>();
    }

    #endregion

    #region Subscription Tests

    [Fact]
    public void UpdateSubscription_ShouldUpdatePlanAndPeriod()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        user.UpdateSubscription(2, BillingPeriod.Annual);

        // Assert
        user.SubscriptionPlanId.Should().Be(2);
        user.BillingPeriod.Should().Be(BillingPeriod.Annual);
    }

    [Fact]
    public void UpdateSubscription_ForNonTrader_ShouldThrow()
    {
        // Arrange
        var user = User.RegisterAdministrator(ValidEmail, ValidHash, "Admin", "Admin");

        // Act
        var act = () => user.UpdateSubscription(1, BillingPeriod.Monthly);

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*Only traders can have subscriptions*");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void UpdateSubscription_WithInvalidPlanId_ShouldThrow(int planId)
    {
        // Arrange
        var user = CreateTrader();

        // Act
        var act = () => user.UpdateSubscription(planId, BillingPeriod.Monthly);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*cannot be empty*");
    }

    #endregion

    #region PlanOverride Tests

    [Fact]
    public void GrantPlanOverride_ShouldSetOverride()
    {
        // Arrange
        var user = CreateTrader();
        var adminId = Guid.NewGuid();
        var override_ = UserPlanOverride.CreateVip(adminId, "VIP customer");

        // Act
        user.GrantPlanOverride(override_);

        // Assert
        user.PlanOverride.Should().Be(override_);
    }

    [Fact]
    public void GrantPlanOverride_ForNonTrader_ShouldThrow()
    {
        // Arrange
        var user = User.RegisterAdministrator(ValidEmail, ValidHash, "Admin", "Admin");
        var override_ = UserPlanOverride.CreateVip(Guid.NewGuid(), "VIP");

        // Act
        var act = () => user.GrantPlanOverride(override_);

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*Only traders can receive plan overrides*");
    }

    [Fact]
    public void GrantPlanOverride_WithNull_ShouldThrow()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        var act = () => user.GrantPlanOverride(null!);

        // Assert
        act.Should().Throw<ArgumentNullException>();
    }

    [Fact]
    public void RevokePlanOverride_ShouldClearOverride()
    {
        // Arrange
        var user = CreateTrader();
        user.GrantPlanOverride(UserPlanOverride.CreateVip(Guid.NewGuid(), "VIP"));

        // Act
        user.RevokePlanOverride();

        // Assert
        user.PlanOverride.Should().BeNull();
    }

    [Fact]
    public void RevokePlanOverride_WhenNone_ShouldThrow()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        var act = () => user.RevokePlanOverride();

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*No plan override to revoke*");
    }

    #endregion

    #region CustomFees Tests

    [Fact]
    public void SetCustomFees_ShouldSetFees()
    {
        // Arrange
        var user = CreateTrader();
        var fees = TradingFees.Create(brokerCommissionRate: 0.001m);

        // Act
        user.SetCustomFees(fees);

        // Assert
        user.CustomFees.Should().Be(fees);
    }

    [Fact]
    public void SetCustomFees_WithNull_ShouldClearFees()
    {
        // Arrange
        var user = CreateTrader();
        user.SetCustomFees(TradingFees.Create(brokerCommissionRate: 0.001m));

        // Act
        user.SetCustomFees(null);

        // Assert
        user.CustomFees.Should().BeNull();
    }

    #endregion

    #region EffectiveLimit Tests

    [Fact]
    public void GetEffectiveStrategyLimit_WithOverride_ShouldReturnOverride()
    {
        // Arrange
        var user = CreateTrader();
        user.GrantPlanOverride(UserPlanOverride.CreateVip(Guid.NewGuid(), "VIP"));

        // Act
        var limit = user.GetEffectiveStrategyLimit(10);

        // Assert
        limit.Should().Be(9999); // VIP limit
    }

    [Fact]
    public void GetEffectiveStrategyLimit_WithoutOverride_ShouldReturnPlanLimit()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        var limit = user.GetEffectiveStrategyLimit(10);

        // Assert
        limit.Should().Be(10);
    }

    [Fact]
    public void GetEffectiveFeatures_WithOverride_ShouldReturnOverride()
    {
        // Arrange
        var user = CreateTrader();
        user.GrantPlanOverride(UserPlanOverride.CreateVip(Guid.NewGuid(), "VIP"));
        var basicFeatures = PlanFeatures.BasicPlan();

        // Act
        var features = user.GetEffectiveFeatures(basicFeatures);

        // Assert
        features.ConsultingTools.Should().BeTrue(); // VIP has Consultor features
    }

    [Fact]
    public void GetEffectiveFeatures_WithoutOverride_ShouldReturnPlanFeatures()
    {
        // Arrange
        var user = CreateTrader();
        var basicFeatures = PlanFeatures.BasicPlan();

        // Act
        var features = user.GetEffectiveFeatures(basicFeatures);

        // Assert
        features.ConsultingTools.Should().BeFalse();
    }

    #endregion

    #region RecordLogin Tests

    [Fact]
    public void RecordLogin_ShouldUpdateLastLoginAt()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        user.RecordLogin();

        // Assert
        user.LastLoginAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
    }

    #endregion

    #region Status Tests

    [Fact]
    public void Suspend_ShouldSetStatusToSuspended()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        user.Suspend();

        // Assert
        user.Status.Should().Be(UserStatus.Suspended);
    }

    [Fact]
    public void Suspend_AlreadySuspended_ShouldThrow()
    {
        // Arrange
        var user = CreateTrader();
        user.Suspend();

        // Act
        var act = () => user.Suspend();

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*already suspended*");
    }

    [Fact]
    public void Suspend_DeletedUser_ShouldThrow()
    {
        // Arrange
        var user = CreateTrader();
        user.Delete();

        // Act
        var act = () => user.Suspend();

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*Cannot suspend a deleted user*");
    }

    [Fact]
    public void Reactivate_ShouldSetStatusToActive()
    {
        // Arrange
        var user = CreateTrader();
        user.Suspend();

        // Act
        user.Reactivate();

        // Assert
        user.Status.Should().Be(UserStatus.Active);
    }

    [Fact]
    public void Reactivate_AlreadyActive_ShouldThrow()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        var act = () => user.Reactivate();

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*already active*");
    }

    [Fact]
    public void Reactivate_DeletedUser_ShouldThrow()
    {
        // Arrange
        var user = CreateTrader();
        user.Delete();

        // Act
        var act = () => user.Reactivate();

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*Cannot reactivate a deleted user*");
    }

    [Fact]
    public void Delete_ShouldSetStatusToDeleted()
    {
        // Arrange
        var user = CreateTrader();

        // Act
        user.Delete();

        // Assert
        user.Status.Should().Be(UserStatus.Deleted);
    }

    [Fact]
    public void Delete_AlreadyDeleted_ShouldThrow()
    {
        // Arrange
        var user = CreateTrader();
        user.Delete();

        // Act
        var act = () => user.Delete();

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*already deleted*");
    }

    #endregion

    #region Helper Methods

    private static User CreateTrader()
    {
        return User.RegisterTrader(
            ValidEmail,
            ValidHash,
            "Test User",
            "Tester",
            RiskProfile.Moderado,
            1,
            BillingPeriod.Monthly);
    }

    #endregion
}
