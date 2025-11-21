using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MyTraderGEO.Domain.UserManagement.Aggregates;

namespace MyTraderGEO.Domain.UserManagement.Interfaces;

/// <summary>
/// Repository interface for SubscriptionPlan aggregate
/// </summary>
public interface ISubscriptionPlanRepository
{
    /// <summary>
    /// Gets a subscription plan by ID
    /// </summary>
    Task<SubscriptionPlan?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets a subscription plan by name
    /// </summary>
    Task<SubscriptionPlan?> GetByNameAsync(string name, CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets all active subscription plans
    /// </summary>
    Task<IReadOnlyList<SubscriptionPlan>> GetAllActiveAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Checks if a plan name already exists
    /// </summary>
    Task<bool> ExistsByNameAsync(string name, CancellationToken cancellationToken = default);

    /// <summary>
    /// Adds a new subscription plan
    /// </summary>
    Task AddAsync(SubscriptionPlan plan, CancellationToken cancellationToken = default);

    /// <summary>
    /// Updates an existing subscription plan
    /// </summary>
    Task UpdateAsync(SubscriptionPlan plan, CancellationToken cancellationToken = default);

    /// <summary>
    /// Saves changes to the database
    /// </summary>
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
