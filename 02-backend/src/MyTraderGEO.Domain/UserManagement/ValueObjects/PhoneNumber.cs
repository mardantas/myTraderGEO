using System;
using System.Text.RegularExpressions;

namespace MyTraderGEO.Domain.UserManagement.ValueObjects;

/// <summary>
/// Value Object: Phone Number (International format)
/// Stores country code and number separately for WhatsApp, 2FA, etc.
/// </summary>
public sealed class PhoneNumber : IEquatable<PhoneNumber>
{
    private static readonly Regex CountryCodeRegex = new(@"^\+\d{1,4}$", RegexOptions.Compiled);
    private static readonly Regex PhoneDigitsRegex = new(@"^\d{8,15}$", RegexOptions.Compiled);

    public string CountryCode { get; }  // e.g., "+55" for Brazil
    public string Number { get; }        // e.g., "11987654321" (digits only)

    private PhoneNumber(string countryCode, string number)
    {
        CountryCode = countryCode;
        Number = number;
    }

    public static PhoneNumber Create(string countryCode, string number)
    {
        if (string.IsNullOrWhiteSpace(countryCode))
            throw new ArgumentException("Country code cannot be empty", nameof(countryCode));

        if (string.IsNullOrWhiteSpace(number))
            throw new ArgumentException("Phone number cannot be empty", nameof(number));

        // Normalize country code (add + if missing)
        var normalizedCountryCode = countryCode.Trim();
        if (!normalizedCountryCode.StartsWith("+"))
            normalizedCountryCode = "+" + normalizedCountryCode;

        if (!CountryCodeRegex.IsMatch(normalizedCountryCode))
            throw new ArgumentException($"Invalid country code format: {countryCode}", nameof(countryCode));

        // Normalize number (remove all non-digits)
        var normalizedNumber = Regex.Replace(number, @"[^\d]", "");

        if (!PhoneDigitsRegex.IsMatch(normalizedNumber))
            throw new ArgumentException($"Invalid phone number format: {number}. Must contain 8-15 digits.", nameof(number));

        return new PhoneNumber(normalizedCountryCode, normalizedNumber);
    }

    /// <summary>
    /// Creates a Brazilian phone number (shortcut for +55)
    /// </summary>
    public static PhoneNumber CreateBrazilian(string number)
    {
        return Create("+55", number);
    }

    /// <summary>
    /// Returns full international format: +55 11 98765-4321
    /// </summary>
    public string ToInternationalFormat()
    {
        // Brazilian format: +55 11 98765-4321
        if (CountryCode == "+55" && Number.Length == 11)
        {
            return $"{CountryCode} {Number.Substring(0, 2)} {Number.Substring(2, 5)}-{Number.Substring(7)}";
        }

        // Generic format: +XX XXXXXXXXXX
        return $"{CountryCode} {Number}";
    }

    /// <summary>
    /// Returns WhatsApp format: +5511987654321
    /// </summary>
    public string ToWhatsAppFormat()
    {
        return $"{CountryCode}{Number}";
    }

    public bool Equals(PhoneNumber? other)
    {
        if (other is null) return false;
        return CountryCode == other.CountryCode && Number == other.Number;
    }

    public override bool Equals(object? obj) => obj is PhoneNumber other && Equals(other);

    public override int GetHashCode() => HashCode.Combine(CountryCode, Number);

    public override string ToString() => ToInternationalFormat();

    public static bool operator ==(PhoneNumber? left, PhoneNumber? right) =>
        left is null ? right is null : left.Equals(right);

    public static bool operator !=(PhoneNumber? left, PhoneNumber? right) => !(left == right);
}
