namespace MyTraderGEO.IntegrationTests.Fixtures;

/// <summary>
/// Collection definition that allows multiple test classes to share the same DatabaseFixture.
/// This avoids starting a new PostgreSQL container for each test class.
/// </summary>
/// <remarks>
/// USAGE:
/// Add [Collection("Database")] attribute to test classes that need database access.
///
/// Example:
/// <code>
/// [Collection("Database")]
/// public class UserRepositoryTests
/// {
///     private readonly DatabaseFixture _fixture;
///
///     public UserRepositoryTests(DatabaseFixture fixture)
///     {
///         _fixture = fixture;
///     }
/// }
/// </code>
/// </remarks>
[CollectionDefinition("Database")]
public class DatabaseCollection : ICollectionFixture<DatabaseFixture>
{
    // This class has no code - it's just a marker for xUnit
}
