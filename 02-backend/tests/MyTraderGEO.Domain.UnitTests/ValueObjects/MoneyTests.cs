using FluentAssertions;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Domain.UnitTests.ValueObjects;

public class MoneyTests
{
    [Fact]
    public void Create_WithValidAmount_ShouldReturnMoney()
    {
        // Act
        var money = Money.Create(100.50m, "BRL");

        // Assert
        money.Amount.Should().Be(100.50m);
        money.Currency.Should().Be("BRL");
    }

    [Fact]
    public void Create_ShouldNormalizeCurrencyToUpperCase()
    {
        // Act
        var money = Money.Create(100m, "brl");

        // Assert
        money.Currency.Should().Be("BRL");
    }

    [Fact]
    public void BRL_ShouldCreateBRLMoney()
    {
        // Act
        var money = Money.BRL(50.25m);

        // Assert
        money.Amount.Should().Be(50.25m);
        money.Currency.Should().Be("BRL");
    }

    [Fact]
    public void Zero_ShouldCreateZeroMoney()
    {
        // Act
        var money = Money.Zero("USD");

        // Assert
        money.Amount.Should().Be(0);
        money.Currency.Should().Be("USD");
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public void Create_WithEmptyCurrency_ShouldThrowArgumentException(string? currency)
    {
        // Act
        var act = () => Money.Create(100m, currency!);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Currency cannot be empty*");
    }

    [Theory]
    [InlineData("BR")]
    [InlineData("BRLX")]
    public void Create_WithInvalidCurrencyLength_ShouldThrowArgumentException(string currency)
    {
        // Act
        var act = () => Money.Create(100m, currency);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Currency must be 3 characters*");
    }

    [Fact]
    public void Create_WithNegativeAmount_ShouldThrowArgumentException()
    {
        // Act
        var act = () => Money.Create(-100m, "BRL");

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Amount cannot be negative*");
    }

    [Fact]
    public void Create_BRLWithMoreThan2DecimalPlaces_ShouldThrowArgumentException()
    {
        // Act
        var act = () => Money.Create(100.123m, "BRL");

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*BRL amount can have at most 2 decimal places*");
    }

    [Fact]
    public void Add_WithSameCurrency_ShouldReturnSum()
    {
        // Arrange
        var money1 = Money.BRL(100m);
        var money2 = Money.BRL(50m);

        // Act
        var result = money1.Add(money2);

        // Assert
        result.Amount.Should().Be(150m);
        result.Currency.Should().Be("BRL");
    }

    [Fact]
    public void Add_WithDifferentCurrency_ShouldThrowInvalidOperationException()
    {
        // Arrange
        var money1 = Money.Create(100m, "BRL");
        var money2 = Money.Create(50m, "USD");

        // Act
        var act = () => money1.Add(money2);

        // Assert
        act.Should().Throw<InvalidOperationException>()
            .WithMessage("*Cannot add USD to BRL*");
    }

    [Fact]
    public void Subtract_WithSameCurrency_ShouldReturnDifference()
    {
        // Arrange
        var money1 = Money.BRL(100m);
        var money2 = Money.BRL(30m);

        // Act
        var result = money1.Subtract(money2);

        // Assert
        result.Amount.Should().Be(70m);
    }

    [Fact]
    public void Subtract_WithDifferentCurrency_ShouldThrowInvalidOperationException()
    {
        // Arrange
        var money1 = Money.Create(100m, "BRL");
        var money2 = Money.Create(50m, "USD");

        // Act
        var act = () => money1.Subtract(money2);

        // Assert
        act.Should().Throw<InvalidOperationException>();
    }

    [Fact]
    public void Multiply_ShouldReturnProduct()
    {
        // Arrange
        var money = Money.BRL(100m);

        // Act
        var result = money.Multiply(2.5m);

        // Assert
        result.Amount.Should().Be(250m);
    }

    [Fact]
    public void Divide_ShouldReturnQuotient()
    {
        // Arrange
        var money = Money.BRL(100m);

        // Act
        var result = money.Divide(4m);

        // Assert
        result.Amount.Should().Be(25m);
    }

    [Fact]
    public void Divide_ByZero_ShouldThrowDivideByZeroException()
    {
        // Arrange
        var money = Money.BRL(100m);

        // Act
        var act = () => money.Divide(0);

        // Assert
        act.Should().Throw<DivideByZeroException>();
    }

    [Fact]
    public void Operators_ShouldWork()
    {
        // Arrange
        var money1 = Money.BRL(100m);
        var money2 = Money.BRL(50m);

        // Assert
        (money1 + money2).Amount.Should().Be(150m);
        (money1 - money2).Amount.Should().Be(50m);
        (money1 * 2).Amount.Should().Be(200m);
        (money1 / 2).Amount.Should().Be(50m);
    }

    [Fact]
    public void CompareTo_ShouldCompareCorrectly()
    {
        // Arrange
        var money1 = Money.BRL(100m);
        var money2 = Money.BRL(50m);
        var money3 = Money.BRL(100m);

        // Assert
        money1.CompareTo(money2).Should().BePositive();
        money2.CompareTo(money1).Should().BeNegative();
        money1.CompareTo(money3).Should().Be(0);
    }

    [Fact]
    public void CompareTo_WithDifferentCurrency_ShouldThrow()
    {
        // Arrange
        var money1 = Money.Create(100m, "BRL");
        var money2 = Money.Create(100m, "USD");

        // Act
        var act = () => money1.CompareTo(money2);

        // Assert
        act.Should().Throw<InvalidOperationException>();
    }

    [Fact]
    public void CompareTo_WithNull_ShouldReturn1()
    {
        // Arrange
        var money = Money.BRL(100m);

        // Act & Assert
        money.CompareTo(null).Should().Be(1);
    }

    [Fact]
    public void ComparisonOperators_ShouldWork()
    {
        // Arrange
        var money1 = Money.BRL(100m);
        var money2 = Money.BRL(50m);

        // Assert
        (money1 > money2).Should().BeTrue();
        (money2 < money1).Should().BeTrue();
        (money1 >= money2).Should().BeTrue();
        (money2 <= money1).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithSameValues_ShouldReturnTrue()
    {
        // Arrange
        var money1 = Money.BRL(100m);
        var money2 = Money.BRL(100m);

        // Assert
        money1.Equals(money2).Should().BeTrue();
        (money1 == money2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithDifferentAmount_ShouldReturnFalse()
    {
        // Arrange
        var money1 = Money.BRL(100m);
        var money2 = Money.BRL(50m);

        // Assert
        money1.Equals(money2).Should().BeFalse();
        (money1 != money2).Should().BeTrue();
    }

    [Fact]
    public void ToString_ForBRL_ShouldFormatCorrectly()
    {
        // Arrange
        var money = Money.BRL(1234.56m);

        // Act
        var result = money.ToString();

        // Assert
        result.Should().Contain("R$");
    }

    [Fact]
    public void ToString_ForUSD_ShouldFormatCorrectly()
    {
        // Arrange
        var money = Money.Create(1234.56m, "USD");

        // Act
        var result = money.ToString();

        // Assert
        result.Should().Contain("$");
    }

    [Fact]
    public void ToString_ForEUR_ShouldFormatCorrectly()
    {
        // Arrange
        var money = Money.Create(1234.56m, "EUR");

        // Act
        var result = money.ToString();

        // Assert
        (result.Contains("EUR") || result.Contains("€")).Should().BeTrue();
    }

    [Fact]
    public void GetHashCode_ForEqualMoney_ShouldBeEqual()
    {
        // Arrange
        var money1 = Money.BRL(100m);
        var money2 = Money.BRL(100m);

        // Assert
        money1.GetHashCode().Should().Be(money2.GetHashCode());
    }

    [Fact]
    public void EqualsObject_WithMoneyObject_ShouldReturnTrue()
    {
        // Arrange
        var money1 = Money.BRL(100m);
        object money2 = Money.BRL(100m);

        // Assert
        money1.Equals(money2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithNull_ShouldReturnFalse()
    {
        // Arrange
        var money = Money.BRL(100m);

        // Assert
        money.Equals(null).Should().BeFalse();
    }
}
