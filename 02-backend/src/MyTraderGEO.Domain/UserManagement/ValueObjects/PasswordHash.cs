using System;
using System.Text.RegularExpressions;

namespace MyTraderGEO.Domain.UserManagement.ValueObjects;

/// <summary>
/// Value Object: Password Hash (BCrypt)
/// Stores BCrypt hash and provides verification
/// </summary>
public sealed class PasswordHash : IEquatable<PasswordHash>
{
    private static readonly Regex BcryptHashRegex = new(
        @"^\$2[ayb]\$\d{2}\$[./A-Za-z0-9]{53}$",
        RegexOptions.Compiled);

    public string Value { get; }

    private PasswordHash(string value)
    {
        Value = value;
    }

    /// <summary>
    /// Creates a PasswordHash from an existing BCrypt hash
    /// </summary>
    public static PasswordHash FromHash(string hash)
    {
        if (string.IsNullOrWhiteSpace(hash))
            throw new ArgumentException("Password hash cannot be empty", nameof(hash));

        if (!BcryptHashRegex.IsMatch(hash))
            throw new ArgumentException("Invalid BCrypt hash format", nameof(hash));

        return new PasswordHash(hash);
    }

    /// <summary>
    /// Creates a PasswordHash by hashing a plain text password
    /// Note: This method is typically used in the Application/Infrastructure layer
    /// </summary>
    public static PasswordHash Create(string plainTextPassword, int workFactor = 11)
    {
        if (string.IsNullOrWhiteSpace(plainTextPassword))
            throw new ArgumentException("Password cannot be empty", nameof(plainTextPassword));

        if (plainTextPassword.Length < 8)
            throw new ArgumentException("Password must be at least 8 characters", nameof(plainTextPassword));

        if (plainTextPassword.Length > 128)
            throw new ArgumentException("Password cannot exceed 128 characters", nameof(plainTextPassword));

        // This will be implemented using BCrypt.Net in Infrastructure layer
        // For now, we'll throw - this is a placeholder for domain validation
        throw new NotImplementedException("Password hashing should be done in Infrastructure layer using BCrypt");
    }

    public static implicit operator string(PasswordHash hash) => hash.Value;

    public bool Equals(PasswordHash? other)
    {
        if (other is null) return false;
        return Value == other.Value;
    }

    public override bool Equals(object? obj) => obj is PasswordHash other && Equals(other);

    public override int GetHashCode() => Value.GetHashCode();

    public override string ToString() => "***REDACTED***"; // Never expose password hash

    public static bool operator ==(PasswordHash? left, PasswordHash? right) =>
        left is null ? right is null : left.Equals(right);

    public static bool operator !=(PasswordHash? left, PasswordHash? right) => !(left == right);
}
