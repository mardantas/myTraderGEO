using System;
using System.Text.RegularExpressions;

namespace MyTraderGEO.Domain.UserManagement.ValueObjects;

/// <summary>
/// Value Object: Email Address
/// Ensures email is valid and normalized
/// </summary>
public sealed class Email : IEquatable<Email>
{
    private static readonly Regex EmailRegex = new(
        @"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);

    public string Value { get; }

    private Email(string value)
    {
        Value = value;
    }

    public static Email Create(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            throw new ArgumentException("Email cannot be empty", nameof(email));

        // Normalize: trim and lowercase
        var normalized = email.Trim().ToLowerInvariant();

        if (normalized.Length > 255)
            throw new ArgumentException("Email cannot exceed 255 characters", nameof(email));

        if (!EmailRegex.IsMatch(normalized))
            throw new ArgumentException($"Invalid email format: {email}", nameof(email));

        return new Email(normalized);
    }

    public static implicit operator string(Email email) => email.Value;

    public bool Equals(Email? other)
    {
        if (other is null) return false;
        return Value.Equals(other.Value, StringComparison.OrdinalIgnoreCase);
    }

    public override bool Equals(object? obj) => obj is Email other && Equals(other);

    public override int GetHashCode() => Value.GetHashCode(StringComparison.OrdinalIgnoreCase);

    public override string ToString() => Value;

    public static bool operator ==(Email? left, Email? right) =>
        left is null ? right is null : left.Equals(right);

    public static bool operator !=(Email? left, Email? right) => !(left == right);
}
