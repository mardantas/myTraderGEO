using FluentAssertions;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Domain.UnitTests.ValueObjects;

public class PlanFeaturesTests
{
    [Fact]
    public void Create_WithDefaults_ShouldReturnCorrectFeatures()
    {
        // Act
        var features = PlanFeatures.Create();

        // Assert
        features.RealtimeData.Should().BeFalse();
        features.AdvancedAlerts.Should().BeFalse();
        features.ConsultingTools.Should().BeFalse();
        features.CommunityAccess.Should().BeTrue(); // Default is true
    }

    [Fact]
    public void Create_WithAllFeatures_ShouldReturnCorrectFeatures()
    {
        // Act
        var features = PlanFeatures.Create(
            realtimeData: true,
            advancedAlerts: true,
            consultingTools: true,
            communityAccess: true);

        // Assert
        features.RealtimeData.Should().BeTrue();
        features.AdvancedAlerts.Should().BeTrue();
        features.ConsultingTools.Should().BeTrue();
        features.CommunityAccess.Should().BeTrue();
    }

    [Fact]
    public void BasicPlan_ShouldHaveCorrectFeatures()
    {
        // Act
        var features = PlanFeatures.BasicPlan();

        // Assert
        features.RealtimeData.Should().BeFalse();
        features.AdvancedAlerts.Should().BeFalse();
        features.ConsultingTools.Should().BeFalse();
        features.CommunityAccess.Should().BeTrue();
    }

    [Fact]
    public void PlenoPlan_ShouldHaveCorrectFeatures()
    {
        // Act
        var features = PlanFeatures.PlenoPlan();

        // Assert
        features.RealtimeData.Should().BeTrue();
        features.AdvancedAlerts.Should().BeTrue();
        features.ConsultingTools.Should().BeFalse();
        features.CommunityAccess.Should().BeTrue();
    }

    [Fact]
    public void ConsultorPlan_ShouldHaveAllFeatures()
    {
        // Act
        var features = PlanFeatures.ConsultorPlan();

        // Assert
        features.RealtimeData.Should().BeTrue();
        features.AdvancedAlerts.Should().BeTrue();
        features.ConsultingTools.Should().BeTrue();
        features.CommunityAccess.Should().BeTrue();
    }

    [Fact]
    public void Equals_WithSameFeatures_ShouldReturnTrue()
    {
        // Arrange
        var features1 = PlanFeatures.PlenoPlan();
        var features2 = PlanFeatures.PlenoPlan();

        // Assert
        features1.Equals(features2).Should().BeTrue();
        (features1 == features2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithDifferentFeatures_ShouldReturnFalse()
    {
        // Arrange
        var features1 = PlanFeatures.BasicPlan();
        var features2 = PlanFeatures.PlenoPlan();

        // Assert
        features1.Equals(features2).Should().BeFalse();
        (features1 != features2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithNull_ShouldReturnFalse()
    {
        // Arrange
        var features = PlanFeatures.BasicPlan();

        // Assert
        features.Equals(null).Should().BeFalse();
    }

    [Fact]
    public void GetHashCode_ForEqualFeatures_ShouldBeEqual()
    {
        // Arrange
        var features1 = PlanFeatures.ConsultorPlan();
        var features2 = PlanFeatures.ConsultorPlan();

        // Assert
        features1.GetHashCode().Should().Be(features2.GetHashCode());
    }

    [Fact]
    public void ToString_ShouldListEnabledFeatures()
    {
        // Arrange
        var features = PlanFeatures.ConsultorPlan();

        // Act
        var result = features.ToString();

        // Assert
        result.Should().Contain("Realtime Data");
        result.Should().Contain("Advanced Alerts");
        result.Should().Contain("Consulting Tools");
        result.Should().Contain("Community Access");
    }

    [Fact]
    public void ToString_WithNoFeatures_ShouldReturnEmpty()
    {
        // Arrange
        var features = PlanFeatures.Create(
            realtimeData: false,
            advancedAlerts: false,
            consultingTools: false,
            communityAccess: false);

        // Act
        var result = features.ToString();

        // Assert
        result.Should().BeEmpty();
    }

    [Fact]
    public void EqualsObject_WithPlanFeaturesObject_ShouldReturnTrue()
    {
        // Arrange
        var features1 = PlanFeatures.BasicPlan();
        object features2 = PlanFeatures.BasicPlan();

        // Assert
        features1.Equals(features2).Should().BeTrue();
    }

    [Fact]
    public void EqualsObject_WithNonPlanFeaturesObject_ShouldReturnFalse()
    {
        // Arrange
        var features = PlanFeatures.BasicPlan();

        // Assert
        features.Equals("not a features object").Should().BeFalse();
    }
}
