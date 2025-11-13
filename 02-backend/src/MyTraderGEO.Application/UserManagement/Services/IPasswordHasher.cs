using MyTraderGEO.Domain.UserManagement.ValueObjects;

namespace MyTraderGEO.Application.UserManagement.Services;

/// <summary>
/// Service interface for password hashing and verification
/// </summary>
public interface IPasswordHasher
{
    /// <summary>
    /// Hashes a plain text password using BCrypt
    /// </summary>
    PasswordHash HashPassword(string plainTextPassword);

    /// <summary>
    /// Verifies a plain text password against a BCrypt hash
    /// </summary>
    bool VerifyPassword(string plainTextPassword, PasswordHash passwordHash);
}
