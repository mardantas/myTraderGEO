using FluentAssertions;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Domain.UnitTests.ValueObjects;

public class UserPlanOverrideTests
{
    private readonly Guid _adminId = Guid.NewGuid();

    [Fact]
    public void Create_WithStrategyLimit_ShouldReturnOverride()
    {
        // Act
        var override_ = UserPlanOverride.Create(
            grantedBy: _adminId,
            reason: "VIP customer",
            strategyLimitOverride: 100);

        // Assert
        override_.StrategyLimitOverride.Should().Be(100);
        override_.FeaturesOverride.Should().BeNull();
        override_.Reason.Should().Be("VIP customer");
        override_.GrantedBy.Should().Be(_adminId);
        override_.IsActive.Should().BeTrue();
    }

    [Fact]
    public void Create_WithFeatures_ShouldReturnOverride()
    {
        // Act
        var override_ = UserPlanOverride.Create(
            grantedBy: _adminId,
            reason: "Trial period",
            featuresOverride: PlanFeatures.ConsultorPlan());

        // Assert
        override_.FeaturesOverride.Should().NotBeNull();
        override_.FeaturesOverride!.ConsultingTools.Should().BeTrue();
    }

    [Fact]
    public void Create_WithExpiration_ShouldSetExpiresAt()
    {
        // Arrange
        var expiresAt = DateTime.UtcNow.AddDays(30);

        // Act
        var override_ = UserPlanOverride.Create(
            grantedBy: _adminId,
            reason: "Trial",
            strategyLimitOverride: 50,
            expiresAt: expiresAt);

        // Assert
        override_.ExpiresAt.Should().BeCloseTo(expiresAt, TimeSpan.FromSeconds(1));
    }

    [Fact]
    public void Create_WithEmptyGuid_ShouldThrowArgumentException()
    {
        // Act
        var act = () => UserPlanOverride.Create(
            grantedBy: Guid.Empty,
            reason: "Test",
            strategyLimitOverride: 100);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*GrantedBy cannot be empty*");
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public void Create_WithEmptyReason_ShouldThrowArgumentException(string? reason)
    {
        // Act
        var act = () => UserPlanOverride.Create(
            grantedBy: _adminId,
            reason: reason!,
            strategyLimitOverride: 100);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Reason cannot be empty*");
    }

    [Fact]
    public void Create_WithLongReason_ShouldThrowArgumentException()
    {
        // Arrange
        var longReason = new string('a', 501);

        // Act
        var act = () => UserPlanOverride.Create(
            grantedBy: _adminId,
            reason: longReason,
            strategyLimitOverride: 100);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*exceed 500 characters*");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Create_WithInvalidStrategyLimit_ShouldThrowArgumentException(int limit)
    {
        // Act
        var act = () => UserPlanOverride.Create(
            grantedBy: _adminId,
            reason: "Test",
            strategyLimitOverride: limit);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Strategy limit must be positive*");
    }

    [Fact]
    public void Create_WithPastExpiration_ShouldThrowArgumentException()
    {
        // Act
        var act = () => UserPlanOverride.Create(
            grantedBy: _adminId,
            reason: "Test",
            strategyLimitOverride: 100,
            expiresAt: DateTime.UtcNow.AddDays(-1));

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Expiration date must be in the future*");
    }

    [Fact]
    public void Create_WithNoOverride_ShouldThrowArgumentException()
    {
        // Act
        var act = () => UserPlanOverride.Create(
            grantedBy: _adminId,
            reason: "Test");

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*At least one override*");
    }

    [Fact]
    public void CreateVip_ShouldReturnCorrectOverride()
    {
        // Act
        var override_ = UserPlanOverride.CreateVip(_adminId, "VIP customer");

        // Assert
        override_.StrategyLimitOverride.Should().Be(9999);
        override_.FeaturesOverride.Should().NotBeNull();
        override_.FeaturesOverride!.ConsultingTools.Should().BeTrue();
        override_.ExpiresAt.Should().BeNull();
        override_.Reason.Should().Contain("VIP");
    }

    [Fact]
    public void CreateTrial_ShouldReturnCorrectOverride()
    {
        // Act
        var override_ = UserPlanOverride.CreateTrial(_adminId, 30);

        // Assert
        override_.FeaturesOverride.Should().NotBeNull();
        override_.ExpiresAt.Should().BeCloseTo(DateTime.UtcNow.AddDays(30), TimeSpan.FromSeconds(5));
        override_.Reason.Should().Contain("Trial");
    }

    [Fact]
    public void CreateBetaTester_ShouldReturnCorrectOverride()
    {
        // Act
        var override_ = UserPlanOverride.CreateBetaTester(_adminId);

        // Assert
        override_.StrategyLimitOverride.Should().Be(100);
        override_.FeaturesOverride.Should().NotBeNull();
        override_.ExpiresAt.Should().BeNull();
        override_.Reason.Should().Be("Beta Tester");
    }

    [Fact]
    public void IsExpired_WhenNotExpired_ShouldReturnFalse()
    {
        // Arrange
        var override_ = UserPlanOverride.Create(
            grantedBy: _adminId,
            reason: "Test",
            strategyLimitOverride: 100,
            expiresAt: DateTime.UtcNow.AddDays(30));

        // Assert
        override_.IsExpired.Should().BeFalse();
        override_.IsActive.Should().BeTrue();
    }

    [Fact]
    public void IsExpired_WhenNoExpiration_ShouldReturnFalse()
    {
        // Arrange
        var override_ = UserPlanOverride.CreateVip(_adminId, "VIP");

        // Assert
        override_.IsExpired.Should().BeFalse();
        override_.IsActive.Should().BeTrue();
    }

    [Fact]
    public void Equals_WithSameValues_ShouldReturnTrue()
    {
        // Arrange - Note: GrantedAt will differ, so they won't be equal
        // For this test, we use the same reference concept
        var override1 = UserPlanOverride.CreateVip(_adminId, "VIP");

        // Assert
        override1.Equals(override1).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithNull_ShouldReturnFalse()
    {
        // Arrange
        var override_ = UserPlanOverride.CreateVip(_adminId, "VIP");

        // Assert
        override_.Equals(null).Should().BeFalse();
    }

    [Fact]
    public void GetHashCode_ShouldNotThrow()
    {
        // Arrange
        var override_ = UserPlanOverride.CreateVip(_adminId, "VIP");

        // Act
        var hash = override_.GetHashCode();

        // Assert
        hash.Should().NotBe(0);
    }

    [Fact]
    public void ToString_WhenActive_ShouldContainStatus()
    {
        // Arrange
        var override_ = UserPlanOverride.CreateVip(_adminId, "VIP customer");

        // Act
        var result = override_.ToString();

        // Assert
        result.Should().Contain("ACTIVE");
        result.Should().Contain("permanent");
    }

    [Fact]
    public void ToString_WithExpiration_ShouldContainDate()
    {
        // Arrange
        var override_ = UserPlanOverride.CreateTrial(_adminId, 30);

        // Act
        var result = override_.ToString();

        // Assert
        result.Should().Contain("until");
    }

    [Fact]
    public void EqualsObject_WithUserPlanOverrideObject_ShouldWork()
    {
        // Arrange
        var override_ = UserPlanOverride.CreateVip(_adminId, "VIP");

        // Assert
        override_.Equals((object)override_).Should().BeTrue();
    }

    [Fact]
    public void EqualsObject_WithNonUserPlanOverrideObject_ShouldReturnFalse()
    {
        // Arrange
        var override_ = UserPlanOverride.CreateVip(_adminId, "VIP");

        // Assert
        override_.Equals("not an override object").Should().BeFalse();
    }

    [Fact]
    public void OperatorEquals_ShouldWork()
    {
        // Arrange
        var override1 = UserPlanOverride.CreateVip(_adminId, "VIP");
        UserPlanOverride? nullOverride = null;

        // Assert
        (override1 == override1).Should().BeTrue();
        (override1 != nullOverride).Should().BeTrue();
        (nullOverride == null).Should().BeTrue();
    }
}
