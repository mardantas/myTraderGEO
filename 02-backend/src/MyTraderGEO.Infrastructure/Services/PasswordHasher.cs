using MyTraderGEO.Application.UserManagement.Services;
using MyTraderGEO.Domain.UserManagement.ValueObjects;
using BCrypt.Net;

namespace MyTraderGEO.Infrastructure.Services;

/// <summary>
/// Service: Password Hashing using BCrypt
/// </summary>
public sealed class PasswordHasher : IPasswordHasher
{
    private const int WorkFactor = 11; // BCrypt work factor (2^11 iterations)

    public PasswordHash HashPassword(string plainTextPassword)
    {
        if (string.IsNullOrWhiteSpace(plainTextPassword))
            throw new ArgumentException("Password cannot be empty", nameof(plainTextPassword));

        if (plainTextPassword.Length < 8)
            throw new ArgumentException("Password must be at least 8 characters", nameof(plainTextPassword));

        if (plainTextPassword.Length > 128)
            throw new ArgumentException("Password cannot exceed 128 characters", nameof(plainTextPassword));

        // Hash password with BCrypt
        var hash = BCrypt.Net.BCrypt.HashPassword(plainTextPassword, WorkFactor);

        return PasswordHash.FromHash(hash);
    }

    public bool VerifyPassword(string plainTextPassword, PasswordHash passwordHash)
    {
        if (string.IsNullOrWhiteSpace(plainTextPassword))
            return false;

        if (passwordHash == null)
            return false;

        try
        {
            return BCrypt.Net.BCrypt.Verify(plainTextPassword, passwordHash.Value);
        }
        catch
        {
            return false;
        }
    }
}
