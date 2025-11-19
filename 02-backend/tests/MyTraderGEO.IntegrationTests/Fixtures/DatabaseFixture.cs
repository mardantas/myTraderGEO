using Npgsql;
using Testcontainers.PostgreSql;

namespace MyTraderGEO.IntegrationTests.Fixtures;

/// <summary>
/// Shared test fixture that provides a real PostgreSQL database using TestContainers.
/// Applies DBA migrations and seeds for integration tests.
/// </summary>
/// <remarks>
/// Epic-01-A User Management: Configured for user_management schema.
/// </remarks>
public class DatabaseFixture : IAsyncLifetime
{
    private readonly PostgreSqlContainer _container = new PostgreSqlBuilder()
        .WithDatabase("mytrader_test")
        .WithUsername("mytrader_app")
        .WithPassword("test_password")
        .WithImage("postgres:15-alpine")
        .WithCleanUp(true)
        .Build();

    /// <summary>
    /// Connection string for the test database container.
    /// </summary>
    public string ConnectionString => _container.GetConnectionString();

    /// <summary>
    /// Starts the PostgreSQL container and applies DBA migrations.
    /// </summary>
    public async Task InitializeAsync()
    {
        // 1. Start PostgreSQL container
        await _container.StartAsync();

        // 2. Apply DBA migrations (SQL-First approach)
        await using var connection = new NpgsqlConnection(ConnectionString);
        await connection.OpenAsync();

        // Migration files (relative to test project output directory)
        var migrationFiles = new[]
        {
            "../../../../04-database/migrations/001_create_user_management_schema.sql"
            // Add more migrations as needed for future epics:
            // "../../../../04-database/migrations/002_create_{epic_name}_schema.sql",
        };

        foreach (var file in migrationFiles)
        {
            var fullPath = Path.GetFullPath(file);
            if (!File.Exists(fullPath))
            {
                Console.WriteLine($"Migration file not found: {fullPath}");
                continue;
            }

            var migrationScript = await File.ReadAllTextAsync(fullPath);
            await using var cmd = new NpgsqlCommand(migrationScript, connection);
            await cmd.ExecuteNonQueryAsync();
        }

        // 3. Apply seed data
        var seedFiles = new[]
        {
            "../../../../04-database/seeds/001_seed_user_management_defaults.sql"
        };

        foreach (var file in seedFiles)
        {
            var fullPath = Path.GetFullPath(file);
            if (!File.Exists(fullPath))
            {
                Console.WriteLine($"Seed file not found: {fullPath}");
                continue;
            }

            var seedScript = await File.ReadAllTextAsync(fullPath);
            await using var cmd = new NpgsqlCommand(seedScript, connection);
            await cmd.ExecuteNonQueryAsync();
        }
    }

    /// <summary>
    /// Stops and removes the PostgreSQL container.
    /// </summary>
    public async Task DisposeAsync()
    {
        await _container.DisposeAsync();
    }

    /// <summary>
    /// Resets database state by truncating all tables.
    /// Call this in test constructor if tests need isolated data.
    /// </summary>
    /// <remarks>
    /// Tables for Epic-01-A User Management: Users, SystemConfigs, SubscriptionPlans
    /// </remarks>
    public async Task ResetDatabaseAsync()
    {
        await using var connection = new NpgsqlConnection(ConnectionString);
        await connection.OpenAsync();

        // Order matters: truncate dependent tables first (CASCADE handles this)
        var cmd = new NpgsqlCommand(@"
            TRUNCATE TABLE users RESTART IDENTITY CASCADE;
            TRUNCATE TABLE system_configs RESTART IDENTITY CASCADE;
            TRUNCATE TABLE subscription_plans RESTART IDENTITY CASCADE;
        ", connection);

        await cmd.ExecuteNonQueryAsync();
    }
}
