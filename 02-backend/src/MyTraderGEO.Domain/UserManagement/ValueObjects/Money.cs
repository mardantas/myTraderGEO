using System;

namespace MyTraderGEO.Domain.UserManagement.ValueObjects;

/// <summary>
/// Value Object: Money (Currency + Amount)
/// Ensures currency consistency and proper decimal handling
/// </summary>
public sealed class Money : IEquatable<Money>, IComparable<Money>
{
    public decimal Amount { get; }
    public string Currency { get; }

    private Money(decimal amount, string currency)
    {
        Amount = amount;
        Currency = currency;
    }

    public static Money Create(decimal amount, string currency = "BRL")
    {
        if (string.IsNullOrWhiteSpace(currency))
            throw new ArgumentException("Currency cannot be empty", nameof(currency));

        if (currency.Length != 3)
            throw new ArgumentException("Currency must be 3 characters (ISO 4217)", nameof(currency));

        if (amount < 0)
            throw new ArgumentException("Amount cannot be negative", nameof(amount));

        // Validate decimal precision (max 2 decimal places for BRL)
        if (currency == "BRL" && decimal.Round(amount, 2) != amount)
            throw new ArgumentException("BRL amount can have at most 2 decimal places", nameof(amount));

        return new Money(amount, currency.ToUpperInvariant());
    }

    public static Money Zero(string currency = "BRL") => new Money(0, currency);

    public static Money BRL(decimal amount) => Create(amount, "BRL");

    public Money Add(Money other)
    {
        if (Currency != other.Currency)
            throw new InvalidOperationException($"Cannot add {other.Currency} to {Currency}");

        return new Money(Amount + other.Amount, Currency);
    }

    public Money Subtract(Money other)
    {
        if (Currency != other.Currency)
            throw new InvalidOperationException($"Cannot subtract {other.Currency} from {Currency}");

        return new Money(Amount - other.Amount, Currency);
    }

    public Money Multiply(decimal multiplier)
    {
        return new Money(Amount * multiplier, Currency);
    }

    public Money Divide(decimal divisor)
    {
        if (divisor == 0)
            throw new DivideByZeroException("Cannot divide money by zero");

        return new Money(Amount / divisor, Currency);
    }

    public bool Equals(Money? other)
    {
        if (other is null) return false;
        return Amount == other.Amount && Currency == other.Currency;
    }

    public override bool Equals(object? obj) => obj is Money other && Equals(other);

    public override int GetHashCode() => HashCode.Combine(Amount, Currency);

    public int CompareTo(Money? other)
    {
        if (other is null) return 1;
        if (Currency != other.Currency)
            throw new InvalidOperationException($"Cannot compare {Currency} with {other.Currency}");

        return Amount.CompareTo(other.Amount);
    }

    public override string ToString()
    {
        return Currency switch
        {
            "BRL" => $"R$ {Amount:N2}",
            "USD" => $"$ {Amount:N2}",
            "EUR" => $"€ {Amount:N2}",
            _ => $"{Amount:N2} {Currency}"
        };
    }

    public static bool operator ==(Money? left, Money? right) =>
        left is null ? right is null : left.Equals(right);

    public static bool operator !=(Money? left, Money? right) => !(left == right);

    public static bool operator >(Money left, Money right) => left.CompareTo(right) > 0;

    public static bool operator <(Money left, Money right) => left.CompareTo(right) < 0;

    public static bool operator >=(Money left, Money right) => left.CompareTo(right) >= 0;

    public static bool operator <=(Money left, Money right) => left.CompareTo(right) <= 0;

    public static Money operator +(Money left, Money right) => left.Add(right);

    public static Money operator -(Money left, Money right) => left.Subtract(right);

    public static Money operator *(Money money, decimal multiplier) => money.Multiply(multiplier);

    public static Money operator /(Money money, decimal divisor) => money.Divide(divisor);
}
