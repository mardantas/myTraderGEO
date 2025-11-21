using FluentAssertions;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Domain.UnitTests.ValueObjects;

public class PhoneNumberTests
{
    [Fact]
    public void Create_WithValidPhone_ShouldReturnPhoneNumber()
    {
        // Act
        var phone = PhoneNumber.Create("+55", "11987654321");

        // Assert
        phone.CountryCode.Should().Be("+55");
        phone.Number.Should().Be("11987654321");
    }

    [Fact]
    public void Create_ShouldNormalizeCountryCode()
    {
        // Act
        var phone = PhoneNumber.Create("55", "11987654321");

        // Assert
        phone.CountryCode.Should().Be("+55");
    }

    [Fact]
    public void Create_ShouldRemoveNonDigitsFromNumber()
    {
        // Act
        var phone = PhoneNumber.Create("+55", "(11) 98765-4321");

        // Assert
        phone.Number.Should().Be("11987654321");
    }

    [Fact]
    public void CreateBrazilian_ShouldUse55CountryCode()
    {
        // Act
        var phone = PhoneNumber.CreateBrazilian("11987654321");

        // Assert
        phone.CountryCode.Should().Be("+55");
        phone.Number.Should().Be("11987654321");
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public void Create_WithEmptyCountryCode_ShouldThrowArgumentException(string? countryCode)
    {
        // Act
        var act = () => PhoneNumber.Create(countryCode!, "11987654321");

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Country code cannot be empty*");
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public void Create_WithEmptyNumber_ShouldThrowArgumentException(string? number)
    {
        // Act
        var act = () => PhoneNumber.Create("+55", number!);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Phone number cannot be empty*");
    }

    [Theory]
    [InlineData("+")]
    [InlineData("+12345")]
    [InlineData("++55")]
    public void Create_WithInvalidCountryCode_ShouldThrowArgumentException(string countryCode)
    {
        // Act
        var act = () => PhoneNumber.Create(countryCode, "11987654321");

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Invalid country code format*");
    }

    [Theory]
    [InlineData("1234567")]     // Too short (7 digits)
    [InlineData("1234567890123456")] // Too long (16 digits)
    public void Create_WithInvalidNumberLength_ShouldThrowArgumentException(string number)
    {
        // Act
        var act = () => PhoneNumber.Create("+55", number);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Must contain 8-15 digits*");
    }

    [Fact]
    public void ToInternationalFormat_ForBrazilianMobile_ShouldFormatCorrectly()
    {
        // Arrange
        var phone = PhoneNumber.CreateBrazilian("11987654321");

        // Act
        var result = phone.ToInternationalFormat();

        // Assert
        result.Should().Be("+55 11 98765-4321");
    }

    [Fact]
    public void ToInternationalFormat_ForNonBrazilian_ShouldUseGenericFormat()
    {
        // Arrange
        var phone = PhoneNumber.Create("+1", "5551234567");

        // Act
        var result = phone.ToInternationalFormat();

        // Assert
        result.Should().Be("+1 5551234567");
    }

    [Fact]
    public void ToWhatsAppFormat_ShouldReturnConcatenated()
    {
        // Arrange
        var phone = PhoneNumber.CreateBrazilian("11987654321");

        // Act
        var result = phone.ToWhatsAppFormat();

        // Assert
        result.Should().Be("+5511987654321");
    }

    [Fact]
    public void ToString_ShouldReturnInternationalFormat()
    {
        // Arrange
        var phone = PhoneNumber.CreateBrazilian("11987654321");

        // Act
        var result = phone.ToString();

        // Assert
        result.Should().Be("+55 11 98765-4321");
    }

    [Fact]
    public void Equals_WithSamePhone_ShouldReturnTrue()
    {
        // Arrange
        var phone1 = PhoneNumber.CreateBrazilian("11987654321");
        var phone2 = PhoneNumber.CreateBrazilian("11987654321");

        // Assert
        phone1.Equals(phone2).Should().BeTrue();
        (phone1 == phone2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithDifferentNumber_ShouldReturnFalse()
    {
        // Arrange
        var phone1 = PhoneNumber.CreateBrazilian("11987654321");
        var phone2 = PhoneNumber.CreateBrazilian("11987654322");

        // Assert
        phone1.Equals(phone2).Should().BeFalse();
        (phone1 != phone2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithDifferentCountryCode_ShouldReturnFalse()
    {
        // Arrange
        var phone1 = PhoneNumber.Create("+55", "987654321");
        var phone2 = PhoneNumber.Create("+1", "987654321");

        // Assert
        phone1.Equals(phone2).Should().BeFalse();
    }

    [Fact]
    public void Equals_WithNull_ShouldReturnFalse()
    {
        // Arrange
        var phone = PhoneNumber.CreateBrazilian("11987654321");

        // Assert
        phone.Equals(null).Should().BeFalse();
    }

    [Fact]
    public void GetHashCode_ForEqualPhones_ShouldBeEqual()
    {
        // Arrange
        var phone1 = PhoneNumber.CreateBrazilian("11987654321");
        var phone2 = PhoneNumber.CreateBrazilian("11987654321");

        // Assert
        phone1.GetHashCode().Should().Be(phone2.GetHashCode());
    }

    [Fact]
    public void EqualsObject_WithPhoneNumberObject_ShouldReturnTrue()
    {
        // Arrange
        var phone1 = PhoneNumber.CreateBrazilian("11987654321");
        object phone2 = PhoneNumber.CreateBrazilian("11987654321");

        // Assert
        phone1.Equals(phone2).Should().BeTrue();
    }

    [Fact]
    public void EqualsObject_WithNonPhoneNumberObject_ShouldReturnFalse()
    {
        // Arrange
        var phone = PhoneNumber.CreateBrazilian("11987654321");

        // Assert
        phone.Equals("not a phone object").Should().BeFalse();
    }
}
