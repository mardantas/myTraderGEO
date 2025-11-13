using System.Threading;
using System.Threading.Tasks;
using MyTraderGEO.Domain.UserManagement.Aggregates;

namespace MyTraderGEO.Domain.UserManagement.Interfaces;

/// <summary>
/// Repository interface for SystemConfig aggregate (Singleton)
/// </summary>
public interface ISystemConfigRepository
{
    /// <summary>
    /// Gets the singleton system configuration
    /// </summary>
    Task<SystemConfig?> GetAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Creates or updates the system configuration
    /// </summary>
    Task UpsertAsync(SystemConfig config, CancellationToken cancellationToken = default);

    /// <summary>
    /// Saves changes to the database
    /// </summary>
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
