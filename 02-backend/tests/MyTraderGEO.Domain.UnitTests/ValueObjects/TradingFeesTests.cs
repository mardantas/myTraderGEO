using FluentAssertions;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Domain.UnitTests.ValueObjects;

public class TradingFeesTests
{
    [Fact]
    public void Create_WithNoFees_ShouldReturnEmptyFees()
    {
        // Act
        var fees = TradingFees.Create();

        // Assert
        fees.BrokerCommissionRate.Should().BeNull();
        fees.B3EmolumentRate.Should().BeNull();
        fees.SettlementFeeRate.Should().BeNull();
        fees.IncomeTaxRate.Should().BeNull();
        fees.DayTradeIncomeTaxRate.Should().BeNull();
        fees.HasCustomFees.Should().BeFalse();
    }

    [Fact]
    public void Create_WithAllFees_ShouldReturnCorrectValues()
    {
        // Act
        var fees = TradingFees.Create(
            brokerCommissionRate: 0.001m,
            b3EmolumentRate: 0.0003m,
            settlementFeeRate: 0.0002m,
            incomeTaxRate: 0.15m,
            dayTradeIncomeTaxRate: 0.20m);

        // Assert
        fees.BrokerCommissionRate.Should().Be(0.001m);
        fees.B3EmolumentRate.Should().Be(0.0003m);
        fees.SettlementFeeRate.Should().Be(0.0002m);
        fees.IncomeTaxRate.Should().Be(0.15m);
        fees.DayTradeIncomeTaxRate.Should().Be(0.20m);
        fees.HasCustomFees.Should().BeTrue();
    }

    [Fact]
    public void Create_WithSingleFee_ShouldHaveCustomFees()
    {
        // Act
        var fees = TradingFees.Create(brokerCommissionRate: 0.001m);

        // Assert
        fees.HasCustomFees.Should().BeTrue();
    }

    [Theory]
    [InlineData(-0.01)]
    [InlineData(1.01)]
    public void Create_WithInvalidBrokerCommissionRate_ShouldThrow(decimal rate)
    {
        // Act
        var act = () => TradingFees.Create(brokerCommissionRate: rate);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*must be between 0 and 1*");
    }

    [Theory]
    [InlineData(-0.01)]
    [InlineData(1.01)]
    public void Create_WithInvalidB3EmolumentRate_ShouldThrow(decimal rate)
    {
        // Act
        var act = () => TradingFees.Create(b3EmolumentRate: rate);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*must be between 0 and 1*");
    }

    [Theory]
    [InlineData(-0.01)]
    [InlineData(1.01)]
    public void Create_WithInvalidSettlementFeeRate_ShouldThrow(decimal rate)
    {
        // Act
        var act = () => TradingFees.Create(settlementFeeRate: rate);

        // Assert
        act.Should().Throw<ArgumentException>();
    }

    [Theory]
    [InlineData(-0.01)]
    [InlineData(1.01)]
    public void Create_WithInvalidIncomeTaxRate_ShouldThrow(decimal rate)
    {
        // Act
        var act = () => TradingFees.Create(incomeTaxRate: rate);

        // Assert
        act.Should().Throw<ArgumentException>();
    }

    [Theory]
    [InlineData(-0.01)]
    [InlineData(1.01)]
    public void Create_WithInvalidDayTradeIncomeTaxRate_ShouldThrow(decimal rate)
    {
        // Act
        var act = () => TradingFees.Create(dayTradeIncomeTaxRate: rate);

        // Assert
        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void MergeWithDefaults_ShouldUseCustomWhenPresent()
    {
        // Arrange
        var customFees = TradingFees.Create(brokerCommissionRate: 0.002m);
        var defaults = TradingFees.Create(
            brokerCommissionRate: 0.001m,
            b3EmolumentRate: 0.0003m,
            settlementFeeRate: 0.0002m);

        // Act
        var merged = customFees.MergeWithDefaults(defaults);

        // Assert
        merged.BrokerCommissionRate.Should().Be(0.002m); // Custom
        merged.B3EmolumentRate.Should().Be(0.0003m); // Default
        merged.SettlementFeeRate.Should().Be(0.0002m); // Default
    }

    [Fact]
    public void MergeWithDefaults_ShouldUseDefaultWhenNotPresent()
    {
        // Arrange
        var customFees = TradingFees.Create();
        var defaults = TradingFees.Create(
            brokerCommissionRate: 0.001m,
            incomeTaxRate: 0.15m);

        // Act
        var merged = customFees.MergeWithDefaults(defaults);

        // Assert
        merged.BrokerCommissionRate.Should().Be(0.001m);
        merged.IncomeTaxRate.Should().Be(0.15m);
    }

    [Fact]
    public void Equals_WithSameFees_ShouldReturnTrue()
    {
        // Arrange
        var fees1 = TradingFees.Create(brokerCommissionRate: 0.001m);
        var fees2 = TradingFees.Create(brokerCommissionRate: 0.001m);

        // Assert
        fees1.Equals(fees2).Should().BeTrue();
        (fees1 == fees2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithDifferentFees_ShouldReturnFalse()
    {
        // Arrange
        var fees1 = TradingFees.Create(brokerCommissionRate: 0.001m);
        var fees2 = TradingFees.Create(brokerCommissionRate: 0.002m);

        // Assert
        fees1.Equals(fees2).Should().BeFalse();
        (fees1 != fees2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithNull_ShouldReturnFalse()
    {
        // Arrange
        var fees = TradingFees.Create();

        // Assert
        fees.Equals(null).Should().BeFalse();
    }

    [Fact]
    public void GetHashCode_ForEqualFees_ShouldBeEqual()
    {
        // Arrange
        var fees1 = TradingFees.Create(brokerCommissionRate: 0.001m);
        var fees2 = TradingFees.Create(brokerCommissionRate: 0.001m);

        // Assert
        fees1.GetHashCode().Should().Be(fees2.GetHashCode());
    }

    [Fact]
    public void ToString_ShouldFormatRates()
    {
        // Arrange
        var fees = TradingFees.Create(brokerCommissionRate: 0.001m);

        // Act
        var result = fees.ToString();

        // Assert
        result.Should().Contain("BrokerCommission");
        result.Should().Contain("default");
    }

    [Fact]
    public void EqualsObject_WithTradingFeesObject_ShouldReturnTrue()
    {
        // Arrange
        var fees1 = TradingFees.Create();
        object fees2 = TradingFees.Create();

        // Assert
        fees1.Equals(fees2).Should().BeTrue();
    }

    [Fact]
    public void EqualsObject_WithNonTradingFeesObject_ShouldReturnFalse()
    {
        // Arrange
        var fees = TradingFees.Create();

        // Assert
        fees.Equals("not a fees object").Should().BeFalse();
    }
}
