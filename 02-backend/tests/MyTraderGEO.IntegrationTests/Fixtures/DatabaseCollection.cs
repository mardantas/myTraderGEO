namespace MyTraderGEO.IntegrationTests.Fixtures;

/// <summary>
/// Collection definition that allows multiple test classes to share the same DatabaseFixture.
/// This avoids starting a new PostgreSQL container for each test class.
/// </summary>
/// <remarks>
/// Usage: Add [Collection("Database")] attribute to test classes that need database access.
/// <code>
/// [Collection("Database")]
/// public class MyRepositoryTests
/// {
///     private readonly DatabaseFixture _fixture;
///
///     public MyRepositoryTests(DatabaseFixture fixture)
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
