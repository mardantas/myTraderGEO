using System;
using MyTraderGEO.Domain.UserManagement.Aggregates;

namespace MyTraderGEO.Application.UserManagement.Services;

/// <summary>
/// Service interface for JWT token generation
/// </summary>
public interface IJwtTokenGenerator
{
    /// <summary>
    /// Generates a JWT token for a user
    /// </summary>
    string GenerateToken(User user);
}
