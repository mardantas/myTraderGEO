using FluentAssertions;
using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Domain.UnitTests.ValueObjects;

public class PasswordHashTests
{
    // Valid BCrypt hash for testing (must be exactly 60 chars)
    private const string ValidBcryptHash = "$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy";

    [Fact]
    public void FromHash_WithValidBcryptHash_ShouldReturnPasswordHash()
    {
        // Act
        var hash = PasswordHash.FromHash(ValidBcryptHash);

        // Assert
        hash.Value.Should().Be(ValidBcryptHash);
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public void FromHash_WithEmptyOrNull_ShouldThrowArgumentException(string? hash)
    {
        // Act
        var act = () => PasswordHash.FromHash(hash!);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*cannot be empty*");
    }

    [Theory]
    [InlineData("invalid")]
    [InlineData("$1a$11$K3GeLAGOHe4l3hK8PjNZxO6X6X6X6X6X6X6X6X6X6X6X6X6X6X6X6u")]
    [InlineData("$2a$11$short")]
    public void FromHash_WithInvalidFormat_ShouldThrowArgumentException(string hash)
    {
        // Act
        var act = () => PasswordHash.FromHash(hash);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*Invalid BCrypt hash format*");
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public void Create_WithEmptyPassword_ShouldThrowArgumentException(string? password)
    {
        // Act
        var act = () => PasswordHash.Create(password!);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*cannot be empty*");
    }

    [Fact]
    public void Create_WithShortPassword_ShouldThrowArgumentException()
    {
        // Act
        var act = () => PasswordHash.Create("short");

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*at least 8 characters*");
    }

    [Fact]
    public void Create_WithLongPassword_ShouldThrowArgumentException()
    {
        // Arrange
        var longPassword = new string('a', 129);

        // Act
        var act = () => PasswordHash.Create(longPassword);

        // Assert
        act.Should().Throw<ArgumentException>()
            .WithMessage("*exceed 128 characters*");
    }

    [Fact]
    public void Create_WithValidPassword_ShouldThrowNotImplementedException()
    {
        // This is expected because hashing should be done in Infrastructure layer
        // Act
        var act = () => PasswordHash.Create("validpassword123");

        // Assert
        act.Should().Throw<NotImplementedException>();
    }

    [Fact]
    public void ImplicitConversion_ShouldReturnValue()
    {
        // Arrange
        var hash = PasswordHash.FromHash(ValidBcryptHash);

        // Act
        string result = hash;

        // Assert
        result.Should().Be(ValidBcryptHash);
    }

    [Fact]
    public void ToString_ShouldReturnRedacted()
    {
        // Arrange
        var hash = PasswordHash.FromHash(ValidBcryptHash);

        // Act
        var result = hash.ToString();

        // Assert
        result.Should().Be("***REDACTED***");
        result.Should().NotContain(ValidBcryptHash);
    }

    [Fact]
    public void Equals_WithSameHash_ShouldReturnTrue()
    {
        // Arrange
        var hash1 = PasswordHash.FromHash(ValidBcryptHash);
        var hash2 = PasswordHash.FromHash(ValidBcryptHash);

        // Assert
        hash1.Equals(hash2).Should().BeTrue();
        (hash1 == hash2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithDifferentHash_ShouldReturnFalse()
    {
        // Arrange
        var hash1 = PasswordHash.FromHash(ValidBcryptHash);
        var hash2 = PasswordHash.FromHash("$2a$11$CU7P9krXbKiJNhFlXbVlNeJj0XiAMQ3f9uMKl0X6Zzf0wjBvXA8Sy");

        // Assert
        hash1.Equals(hash2).Should().BeFalse();
        (hash1 != hash2).Should().BeTrue();
    }

    [Fact]
    public void Equals_WithNull_ShouldReturnFalse()
    {
        // Arrange
        var hash = PasswordHash.FromHash(ValidBcryptHash);

        // Assert
        hash.Equals(null).Should().BeFalse();
    }

    [Fact]
    public void GetHashCode_ForEqualHashes_ShouldBeEqual()
    {
        // Arrange
        var hash1 = PasswordHash.FromHash(ValidBcryptHash);
        var hash2 = PasswordHash.FromHash(ValidBcryptHash);

        // Assert
        hash1.GetHashCode().Should().Be(hash2.GetHashCode());
    }

    [Fact]
    public void EqualsObject_WithPasswordHashObject_ShouldReturnTrue()
    {
        // Arrange
        var hash1 = PasswordHash.FromHash(ValidBcryptHash);
        object hash2 = PasswordHash.FromHash(ValidBcryptHash);

        // Assert
        hash1.Equals(hash2).Should().BeTrue();
    }

    [Fact]
    public void EqualsObject_WithNonPasswordHashObject_ShouldReturnFalse()
    {
        // Arrange
        var hash = PasswordHash.FromHash(ValidBcryptHash);

        // Assert
        hash.Equals("not a hash object").Should().BeFalse();
    }
}
