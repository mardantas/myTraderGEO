<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# 02-backend - {PROJECT_NAME} Backend API

**Projeto:** {PROJECT_NAME}  
**Stack:** {BACKEND_STACK} (e.g., .NET 8 + ASP.NET Core + Entity Framework Core)  
**Architecture:** Clean Architecture + DDD  
**Responsible Agent:** SE Agent  

---

## 📋 About This Document

This is a **quick reference guide** for building, running, and debugging the backend API. For strategic implementation decisions, domain model details, and architectural patterns, consult [SE-01-{EpicName}-Implementation-Report.md](../00-doc-ddd/04-tactical-design/SE-01-{EpicName}-Implementation-Report.md).

**Document Separation:**  
- **This README:** Commands and checklists (HOW to execute)
- **SE-01:** Implementation decisions, patterns, and trade-offs (WHY and WHAT)

**Principle:** README is an INDEX/QUICK-REFERENCE to SE-01, not a duplicate.  

---

## 🎯 Technology Stack

- **Runtime:** {RUNTIME} (e.g., .NET 8)
- **Framework:** {FRAMEWORK} (e.g., ASP.NET Core 8.0)
- **ORM:** {ORM} (e.g., Entity Framework Core 8.0)
- **Real-time:** {REALTIME} (e.g., SignalR)
- **Authentication:** JWT Bearer Tokens
- **API Documentation:** OpenAPI/Swagger (Swashbuckle)
- **Testing:** xUnit + FluentAssertions + Moq

---

## 📁 Directory Structure

```
02-backend/
├── src/
│   ├── Domain/                  # Domain layer (Aggregates, Entities, Value Objects)
│   │   ├── {BoundedContext}/
│   │   │   ├── Aggregates/
│   │   │   ├── ValueObjects/
│   │   │   ├── Events/
│   │   │   └── Interfaces/
│   ├── Application/             # Application layer (Use Cases, Commands, Queries)
│   │   ├── {BoundedContext}/
│   │   │   ├── Commands/
│   │   │   ├── Queries/
│   │   │   └── Handlers/
│   ├── Infrastructure/          # Infrastructure layer (Repositories, EF migrations)
│   │   ├── Persistence/
│   │   │   ├── Contexts/
│   │   │   ├── Repositories/
│   │   │   └── Migrations/
│   │   └── External/
│   └── Api/                     # API layer (Controllers, DTOs, Middleware)
│       ├── Controllers/
│       ├── DTOs/
│       ├── Middleware/
│       └── Program.cs
├── tests/
│   ├── unit/                    # Unit tests (Domain layer ≥70% coverage)
│   │   └── Domain.Tests/
│   ├── integration/             # Integration tests (optional)
│   │   └── Api.Tests/
│   └── e2e/                     # E2E tests (QAE responsibility)
└── README.md                    # This file
```

---

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Install {RUNTIME}
# {INSTALLATION_INSTRUCTIONS}

# Verify installation
{VERIFY_COMMAND}  # e.g., dotnet --version
```

### 2. Install Dependencies

```bash
cd 02-backend

# Restore packages
{RESTORE_COMMAND}  # e.g., dotnet restore
```

### 3. Configure Environment

```bash
# Copy .env example (if exists)
cp .env.example .env

# Or configure appsettings.Development.json
nano src/Api/appsettings.Development.json
```

**Required Configuration:**  
- Database connection string
- JWT secret (min 32 characters)
- CORS origins (frontend URL)

### 4. Run Migrations

```bash
# Apply database migrations
{MIGRATION_COMMAND}  # e.g., dotnet ef database update

# Or via Docker (if database in container)
docker compose -f ../05-infra/docker/docker-compose.yml exec api {MIGRATION_COMMAND}
```

### 5. Run API (Development)

```bash
# Run with hot reload
{RUN_COMMAND}  # e.g., dotnet run --project src/Api

# Or via Docker
docker compose -f ../05-infra/docker/docker-compose.yml up api -d
```

**Access:**  
- API: http://localhost:5000
- Swagger UI: http://localhost:5000/swagger

---

## 🔧 Common Commands

### Development

```bash
# Build project
{BUILD_COMMAND}  # e.g., dotnet build

# Run API (hot reload)
{RUN_COMMAND}  # e.g., dotnet run --project src/Api

# Watch mode (auto-restart on changes)
{WATCH_COMMAND}  # e.g., dotnet watch --project src/Api

# Run specific project
{RUN_PROJECT_COMMAND}  # e.g., dotnet run --project src/Api --launch-profile Development
```

### Testing

```bash
# Run all tests
{TEST_COMMAND}  # e.g., dotnet test

# Run unit tests only
{TEST_UNIT_COMMAND}  # e.g., dotnet test tests/unit

# Run with coverage
{TEST_COVERAGE_COMMAND}  # e.g., dotnet test --collect:"XPlat Code Coverage"

# View coverage report
{COVERAGE_REPORT_COMMAND}  # e.g., reportgenerator -reports:coverage.cobertura.xml -targetdir:coverage-report
```

### Database Migrations

```bash
# Add new migration
{MIGRATION_ADD_COMMAND}  # e.g., dotnet ef migrations add MigrationName --project src/Infrastructure

# Apply migrations
{MIGRATION_UPDATE_COMMAND}  # e.g., dotnet ef database update --project src/Api

# Rollback last migration
{MIGRATION_ROLLBACK_COMMAND}  # e.g., dotnet ef database update PreviousMigration --project src/Api

# Remove last migration (not applied)
{MIGRATION_REMOVE_COMMAND}  # e.g., dotnet ef migrations remove --project src/Infrastructure

# Generate SQL script
{MIGRATION_SCRIPT_COMMAND}  # e.g., dotnet ef migrations script --project src/Api --output migrations.sql
```

### Code Quality

```bash
# Format code
{FORMAT_COMMAND}  # e.g., dotnet format

# Lint/Analyze
{LINT_COMMAND}  # e.g., dotnet build /p:EnforceCodeStyleInBuild=true

# Check for vulnerabilities
{SECURITY_COMMAND}  # e.g., dotnet list package --vulnerable
```

---

## 🏗️ Build & Deploy

### Build for Production

```bash
# Build release
{BUILD_RELEASE_COMMAND}  # e.g., dotnet build --configuration Release

# Publish (creates deployable artifacts)
{PUBLISH_COMMAND}  # e.g., dotnet publish --configuration Release --output ./publish
```

### Docker Build

```bash
# Build Docker image
docker build -f ../05-infra/dockerfiles/backend/Dockerfile -t {project}-api:latest .

# Run container
docker run -p 5000:8080 --env-file ../05-infra/configs/.env {project}-api:latest
```

---

## 🧪 Testing

### Unit Tests

**Coverage Target:** ≥70% on Domain layer  

```bash
# Run all unit tests
{TEST_UNIT_COMMAND}  # e.g., dotnet test tests/unit

# Run specific test class
{TEST_CLASS_COMMAND}  # e.g., dotnet test --filter ClassName=UserTests

# Run with detailed output
{TEST_VERBOSE_COMMAND}  # e.g., dotnet test --verbosity detailed
```

### Integration Tests

```bash
# Run integration tests (requires test database)
{TEST_INTEGRATION_COMMAND}  # e.g., dotnet test tests/integration

# Setup test database
docker compose -f ../05-infra/docker/docker-compose.test.yml up -d database
```

### Manual Testing (Swagger)

1. Start API: `{RUN_COMMAND}`
2. Open Swagger: http://localhost:5000/swagger
3. Authenticate (if needed):
   - Click "Authorize" button
   - Enter JWT token: `Bearer {token}`
4. Test endpoints

---

## 🐛 Debugging

### VS Code

**Launch Configuration (`.vscode/launch.json`):**  

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": ".NET Core Launch (API)",
      "type": "coreclr",
      "request": "launch",
      "preLaunchTask": "build",
      "program": "${workspaceFolder}/02-backend/src/Api/bin/Debug/net8.0/Api.dll",
      "args": [],
      "cwd": "${workspaceFolder}/02-backend/src/Api",
      "stopAtEntry": false,
      "env": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  ]
}
```

### Visual Studio

1. Open solution: `{SOLUTION_FILE}`
2. Set `Api` as startup project
3. Press F5 to start debugging

### Attach to Docker Container

```bash
# Find container ID
docker ps | grep api

# Attach debugger (IDE-specific)
# VS Code: Remote-Containers extension
# Visual Studio: Debug → Attach to Process → Docker
```

---

## 📊 Architecture Layers

### Domain Layer (`src/Domain/`)

**Responsibility:** Business logic, invariants, domain rules  

**Contains:**  
- Aggregates (Aggregate Roots + Entities)
- Value Objects (Email, Money, etc.)
- Domain Events
- Repository Interfaces (contracts only)

**Key Patterns:**  
- Aggregate Pattern (consistency boundaries)
- Value Object Pattern (immutability)
- Domain Events (loose coupling)
- Specification Pattern (complex business rules)

**See:** [SE-01 - Domain Layer Section](../00-doc-ddd/04-tactical-design/SE-01-{EpicName}-Implementation-Report.md#domain-layer)  

### Application Layer (`src/Application/`)

**Responsibility:** Orchestration, use cases, business workflows  

**Contains:**  
- Commands (write operations)
- Queries (read operations)
- Command/Query Handlers (CQRS pattern)
- Application Services (orchestration)

**Key Patterns:**  
- CQRS (Command Query Responsibility Segregation)
- Mediator Pattern (MediatR library)
- Unit of Work Pattern (transaction management)

**See:** [SE-01 - Application Layer Section](../00-doc-ddd/04-tactical-design/SE-01-{EpicName}-Implementation-Report.md#application-layer)  

### Infrastructure Layer (`src/Infrastructure/`)

**Responsibility:** Technical implementations, external dependencies  

**Contains:**  
- EF Core DbContext
- Repository Implementations
- Migrations
- External service integrations (email, SMS, etc.)

**Key Patterns:**  
- Repository Pattern (data access abstraction)
- Dependency Injection (loose coupling)

**See:** [SE-01 - Infrastructure Layer Section](../00-doc-ddd/04-tactical-design/SE-01-{EpicName}-Implementation-Report.md#infrastructure-layer)  

### API Layer (`src/Api/`)

**Responsibility:** HTTP endpoints, DTOs, middleware, API concerns  

**Contains:**  
- Controllers (REST endpoints)
- DTOs (Data Transfer Objects)
- Middleware (auth, logging, error handling)
- OpenAPI/Swagger configuration

**Key Patterns:**  
- RESTful API (resource-based)
- DTO Pattern (decoupling API from domain)
- Middleware Pipeline (cross-cutting concerns)

**See:** [SE-01 - API Layer Section](../00-doc-ddd/04-tactical-design/SE-01-{EpicName}-Implementation-Report.md#api-layer)  

---

## 🔗 Related Artifacts

This section connects operational README with strategic documentation.

| Artifact | Purpose | When to Consult |
|----------|---------|------------------|
| **[SE-01-{EpicName}-Implementation-Report.md](../00-doc-ddd/04-tactical-design/SE-01-{EpicName}-Implementation-Report.md)** | Implementation decisions, patterns used, trade-offs, architecture layers | To understand **WHY** code is structured this way, patterns chosen, evaluate alternatives |
| **[DE-01-{EpicName}-Domain-Model.md](../00-doc-ddd/04-tactical-design/DE-01-{EpicName}-Domain-Model.md)** | Domain model (Aggregates, Use Cases, invariants, ubiquitous language) | To understand business rules, domain concepts, aggregate boundaries |
| **[DBA-01-{EpicName}-Database-Design-Decisions.md](../00-doc-ddd/05-database-design/DBA-01-{EpicName}-Database-Design-Decisions.md)** | Database schema, indexes, constraints, performance | To understand database design, migration strategy, query optimization |
| **[API Standards](../.agents/docs/06-API-Standards.md)** | API conventions (versioning, status codes, error responses, pagination) | To ensure consistent API design across endpoints |
| **[DDD Patterns Reference](../.agents/docs/05-DDD-Patterns-Reference.md)** | DDD patterns guide (Saga, Outbox, Specification, etc.) | To implement domain patterns correctly |

---

## 📚 References

### Internal Documentation

- **Implementation Report:** [00-doc-ddd/04-tactical-design/SE-01-{EpicName}-Implementation-Report.md](../00-doc-ddd/04-tactical-design/SE-01-{EpicName}-Implementation-Report.md)
- **Domain Model:** [00-doc-ddd/04-tactical-design/DE-01-{EpicName}-Domain-Model.md](../00-doc-ddd/04-tactical-design/DE-01-{EpicName}-Domain-Model.md)
- **API Standards:** [.agents/docs/06-API-Standards.md](../.agents/docs/06-API-Standards.md)
- **DDD Patterns:** [.agents/docs/05-DDD-Patterns-Reference.md](../.agents/docs/05-DDD-Patterns-Reference.md)

### External Documentation

- **{FRAMEWORK} Documentation:** {DOCS_URL} (e.g., https://learn.microsoft.com/aspnet/core/)
- **{ORM} Documentation:** {ORM_DOCS_URL} (e.g., https://learn.microsoft.com/ef/core/)
- **Clean Architecture:** https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- **Domain-Driven Design:** https://martinfowler.com/bliki/DomainDrivenDesign.html

---

## 🛠️ Troubleshooting

### Problem: Build fails with dependency errors

**Symptom:** `{BUILD_ERROR_EXAMPLE}`  

**Solution:**  
```bash
# Clear package cache
{CLEAR_CACHE_COMMAND}  # e.g., dotnet clean && dotnet nuget locals all --clear

# Restore packages
{RESTORE_COMMAND}

# Rebuild
{BUILD_COMMAND}
```

### Problem: Cannot connect to database

**Symptom:** `Unable to connect to database` error  

**Solution:**  
```bash
# 1. Check if database container is running
docker compose -f ../05-infra/docker/docker-compose.yml ps database

# 2. Verify connection string in appsettings.Development.json
cat src/Api/appsettings.Development.json | grep ConnectionString

# 3. Test connection manually
docker compose exec database psql -U {project}_app -d {project}_dev -c "SELECT 1;"

# 4. Check database logs
docker compose logs database
```

### Problem: Migrations fail

**Symptom:** `Migration failed` error  

**Solution:**  
```bash
# 1. Check if migration already applied
{MIGRATION_LIST_COMMAND}  # e.g., dotnet ef migrations list

# 2. Rollback to previous migration
{MIGRATION_ROLLBACK_COMMAND}

# 3. Remove problematic migration
{MIGRATION_REMOVE_COMMAND}

# 4. Recreate migration
{MIGRATION_ADD_COMMAND}
{MIGRATION_UPDATE_COMMAND}
```

### Problem: Hot reload not working

**Symptom:** Code changes not reflected  

**Solution:**  
```bash
# 1. Ensure using watch mode
{WATCH_COMMAND}

# 2. Check file watcher limits (Linux)
cat /proc/sys/fs/inotify/max_user_watches  # Should be ≥524288
sudo sysctl fs.inotify.max_user_watches=524288

# 3. Restart API
# Ctrl+C and re-run {RUN_COMMAND}
```

### Problem: Tests fail with "Database locked"

**Symptom:** Integration tests fail with database lock errors  

**Solution:**  
```bash
# Use in-memory database for tests
# Or: Use separate test database per test class
# Or: Run tests sequentially (not in parallel)

{TEST_COMMAND} --no-parallel
```

---

**SE Agent** - {PROJECT_NAME} Backend Engineering
**Last Updated:** {YYYY-MM-DD}  
**Status:** ⏳ {Status}  
