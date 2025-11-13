# ==================================
# Backend Production Dockerfile
# ==================================
# Multi-stage build for optimized image size

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution file
COPY ["MyTraderGEO.sln", "./"]

# Copy csproj files and restore dependencies (layer caching)
COPY ["src/MyTraderGEO.Domain/MyTraderGEO.Domain.csproj", "src/MyTraderGEO.Domain/"]
COPY ["src/MyTraderGEO.Application/MyTraderGEO.Application.csproj", "src/MyTraderGEO.Application/"]
COPY ["src/MyTraderGEO.Infrastructure/MyTraderGEO.Infrastructure.csproj", "src/MyTraderGEO.Infrastructure/"]
COPY ["src/MyTraderGEO.WebAPI/MyTraderGEO.WebAPI.csproj", "src/MyTraderGEO.WebAPI/"]

# Restore dependencies
RUN dotnet restore "MyTraderGEO.sln"

# Copy all source code
COPY . .

# Build the WebAPI project
WORKDIR "/src/src/MyTraderGEO.WebAPI"
RUN dotnet build "MyTraderGEO.WebAPI.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "MyTraderGEO.WebAPI.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Create non-root user for security
RUN groupadd --system --gid 1001 appuser && \
    useradd --system --uid 1001 --gid appuser --home-dir /app appuser

# Copy published application
COPY --from=publish /app/publish .

# Create logs directory
RUN mkdir -p /app/logs && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Entry point
ENTRYPOINT ["dotnet", "MyTraderGEO.WebAPI.dll"]
