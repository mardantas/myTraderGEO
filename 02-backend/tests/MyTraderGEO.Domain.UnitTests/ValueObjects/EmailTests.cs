using FluentAssertions;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Domain.UnitTests.ValueObjects;

public class EmailTests
{
    [Fact]
    public void Create_WithValidEmail_ShouldReturnEmail()
    {
        // Arrange
        var emailString = "test@example.com";

        // Act
        var email = Email.Create(emailString);

        // Assert
        email.Value.Should().Be("test@example.com");
    }

    [Fact]
    public void Create_ShouldNormalizeToLowerCase()
    {
        // Arrange
        var emailString = "TEST@EXAMPLE.COM";

        // Act
        var email = Email.Create(emailString);

        // Assert
        email.Value.Should().Be("test@example.com");
    }

    [Fact]
    public void Create_ShouldTrimWhitespace()
    {
        // Arrange
        var emailString = "  test@example.com  ";

        // Act
        var email = Email.Create(emailString);

        // Assert
        email.Value.Should().Be("test@example.com");
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public void Create_WithEmptyOrNull_ShouldThrowArgumentException(string? emailString)
    {
        // Act
        var act = () => Email.Create(emailString!);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*cannot be empty*");
    }

    [Theory]
    [InlineData("invalid")]
    [InlineData("invalid@")]
    [InlineData("@example.com")]
    [InlineData("test@.com")]
    [InlineData("test@example")]
    public void Create_WithInvalidFormat_ShouldThrowArgumentException(string emailString)
    {
        // Act
        var act = () => Email.Create(emailString);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Invalid email format*");
    }

    [Fact]
    public void Create_WithExceeding255Characters_ShouldThrowArgumentException()
    {
        // Arrange
        var longEmail = new string('a', 250) + "@example.com";

        // Act
        var act = () => Email.Create(longEmail);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*exceed 255 characters*");
    }

    [Fact]
    public void ImplicitConversion_ShouldReturnValue()
    {
        // Arrange
        var email = Email.Create("test@example.com");

        // Act
        string result = email;

        // Assert
        result.Should().Be("test@example.com");
    }

    [Fact]
    public void Equals_WithSameEmail_ShouldReturnTrue()
    {
        // Arrange
        var email1 = Email.Create("test@example.com");
        var email2 = Email.Create("TEST@EXAMPLE.COM");

        // Act & Assert
        email1.Equals(email2).Should().BeTrue();
        (email1 == email2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithDifferentEmail_ShouldReturnFalse()
    {
        // Arrange
        var email1 = Email.Create("test1@example.com");
        var email2 = Email.Create("test2@example.com");

        // Act & Assert
        email1.Equals(email2).Should().BeFalse();
        (email1 != email2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithNull_ShouldReturnFalse()
    {
        // Arrange
        var email = Email.Create("test@example.com");

        // Act & Assert
        email.Equals(null).Should().BeFalse();
    }

    [Fact]
    public void GetHashCode_ForEqualEmails_ShouldBeEqual()
    {
        // Arrange
        var email1 = Email.Create("test@example.com");
        var email2 = Email.Create("TEST@EXAMPLE.COM");

        // Act & Assert
        email1.GetHashCode().Should().Be(email2.GetHashCode());
    }

    [Fact]
    public void ToString_ShouldReturnValue()
    {
        // Arrange
        var email = Email.Create("test@example.com");

        // Act & Assert
        email.ToString().Should().Be("test@example.com");
    }

    [Fact]
    public void EqualsObject_WithEmailObject_ShouldReturnTrue()
    {
        // Arrange
        var email1 = Email.Create("test@example.com");
        object email2 = Email.Create("test@example.com");

        // Act & Assert
        email1.Equals(email2).Should().BeTrue();
    }

    [Fact]
    public void EqualsObject_WithNonEmailObject_ShouldReturnFalse()
    {
        // Arrange
        var email = Email.Create("test@example.com");

        // Act & Assert
        email.Equals("not an email object").Should().BeFalse();
    }
}
