# myTraderGEO Backend API

Backend da plataforma myTraderGEO para gerenciamento de traders e estratégias de trading na bolsa brasileira (B3).

## Visão Geral

API RESTful desenvolvida em .NET 8 seguindo princípios de **Clean Architecture** e **Domain-Driven Design (DDD)** com padrão **CQRS** usando MediatR.

### Tecnologias

- **.NET 8** (LTS) - Framework principal
- **Entity Framework Core 8** - ORM para PostgreSQL
- **PostgreSQL 15** - Banco de dados relacional
- **MediatR** - Implementação de CQRS e mediator pattern
- **BCrypt.Net** - Hash de senhas
- **JWT (JSON Web Tokens)** - Autenticação e autorização
- **Serilog** - Logging estruturado
- **Swagger/OpenAPI** - Documentação da API
- **xUnit + Moq + FluentAssertions** - Testes unitários
- **TestContainers** - Testes de integração

## Arquitetura

### Estrutura de Projetos

```
02-backend/
├── MyTraderGEO.sln
├── src/
│   ├── MyTraderGEO.Domain/           # Camada de domínio (entidades, value objects, interfaces)
│   ├── MyTraderGEO.Application/      # Camada de aplicação (casos de uso, comandos, handlers)
│   ├── MyTraderGEO.Infrastructure/   # Camada de infraestrutura (repositórios, serviços externos)
│   └── MyTraderGEO.WebAPI/           # Camada de apresentação (controllers, DTOs)
└── tests/
    ├── MyTraderGEO.Domain.UnitTests/
    ├── MyTraderGEO.Application.UnitTests/
    └── MyTraderGEO.IntegrationTests/
```

### Camadas

#### 1. Domain (Domínio)
- **Aggregates**: User, SubscriptionPlan, SystemConfig
- **Value Objects**: Email, PasswordHash, PhoneNumber, Money, TradingFees, PlanFeatures, UserPlanOverride
- **Enums**: UserRole, UserStatus, RiskProfile, BillingPeriod
- **Interfaces**: IUserRepository, ISubscriptionPlanRepository, ISystemConfigRepository

#### 2. Application (Aplicação)
- **Commands**: RegisterTrader, Login, ConfigureSubscriptionPlan, UpdateSystemParameters, GrantPlanOverride, RevokePlanOverride
- **Handlers**: Implementação dos casos de uso usando MediatR
- **Services**: IPasswordHasher, IJwtTokenGenerator

#### 3. Infrastructure (Infraestrutura)
- **Data Models**: Modelos EF Core mapeados para o banco
- **Repositories**: Implementação dos repositórios
- **Services**: PasswordHasher (BCrypt), JwtTokenGenerator
- **Database Context**: ApplicationDbContext

#### 4. WebAPI (Apresentação)
- **Controllers**: AuthController, PlansController, UsersController, SystemController
- **Configuration**: JWT, Swagger, CORS, Health Checks

## Requisitos

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [PostgreSQL 15](https://www.postgresql.org/download/) ou [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/) (opcional, para ambiente completo)

## Configuração e Execução

### Opção 1: Usando Docker Compose (Recomendado)

> **Importante**: Todos os comandos docker compose devem ser executados a partir da **raiz do projeto** (`myTraderGEO/`).

1. **Build da aplicação (primeiro uso ou após alterações):**
   ```bash
   dotnet build 02-backend/MyTraderGEO.sln
   ```

2. **Inicie o banco de dados e a API:**
   ```bash
   docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up -d
   ```

3. **Acesse a aplicação:**
   - API: http://localhost:5000
   - Swagger UI: http://localhost:5000
   - Health Check: http://localhost:5000/health
   - PgAdmin: http://localhost:8080 (usuário: admin@mytrader.local, senha: admin123)

4. **Para parar os serviços:**
   ```bash
   docker compose -f 05-infra/docker/docker-compose.dev.yml down
   ```

### Opção 2: Executando Localmente

1. **Inicie o banco de dados PostgreSQL:**
   ```bash
   docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev up -d database
   ```

2. **Configure a string de conexão:**

   O arquivo `02-backend/src/MyTraderGEO.WebAPI/appsettings.json` já está configurado com as credenciais corretas:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Host=localhost;Port=5432;Database=mytrader_dev;Username=mytrader_app;Password=local_app"
     }
   }
   ```

3. **Execute a API:**
   ```bash
   dotnet run --project 02-backend/src/MyTraderGEO.WebAPI
   ```

4. **Acesse a aplicação:**
   - API: http://localhost:5024 (porta dinâmica, verifique o console)
   - Swagger UI: http://localhost:5024

## Endpoints da API

### Autenticação (`/api/Auth`)

- **POST /api/Auth/register** - Registrar novo trader
  ```json
  {
    "email": "trader@example.com",
    "password": "SecurePass123!",
    "fullName": "Nome Completo",
    "displayName": "trader_name",
    "riskProfile": 1,
    "subscriptionPlanId": "10000000-0000-0000-0000-000000000001",
    "billingPeriod": 0
  }
  ```

- **POST /api/Auth/login** - Login de usuário
  ```json
  {
    "email": "trader@example.com",
    "password": "SecurePass123!"
  }
  ```

### Planos de Assinatura (`/api/Plans`)

- **GET /api/Plans** - Listar todos os planos ativos (público)
- **GET /api/Plans/{id}** - Obter plano por ID (público)
- **POST /api/Plans** - Criar/atualizar plano (requer: Administrator)

### Usuários (`/api/Users`)

- **GET /api/Users/me** - Obter perfil do usuário atual (autenticado)
- **POST /api/Users/{id}/plan-override** - Conceder override de plano (requer: Administrator)
- **DELETE /api/Users/{id}/plan-override** - Revogar override de plano (requer: Administrator)

### Configuração do Sistema (`/api/System`)

- **GET /api/System/config** - Obter configuração do sistema (requer: Moderator ou Administrator)
- **PUT /api/System/config** - Atualizar parâmetros do sistema (requer: Administrator)
  ```json
  {
    "brokerCommissionRate": 0.0003,
    "b3EmolumentRate": 0.000325,
    "settlementFeeRate": 0.000275,
    "incomeTaxRate": 0.15,
    "dayTradeIncomeTaxRate": 0.20,
    "maxOpenStrategiesPerUser": 100,
    "maxStrategiesInTemplate": 20
  }
  ```

## Autenticação e Autorização

A API usa **JWT Bearer Tokens** para autenticação. Após o login, inclua o token no header:

```
Authorization: Bearer {seu-token-jwt}
```

### Roles (Perfis)

1. **Trader** - Usuário comum da plataforma
2. **Moderator** - Moderador com permissões especiais
3. **Administrator** - Administrador com acesso total

### Políticas de Autorização

- `RequireTrader` - Qualquer usuário autenticado
- `RequireModerator` - Moderator ou Administrator
- `RequireAdministrator` - Apenas Administrator

## Banco de Dados

### Schema

- **users** - Dados dos usuários
- **subscriptionplans** - Planos de assinatura disponíveis
- **systemconfigs** - Configurações globais do sistema (singleton)

### Migrações (Database First)

Este projeto usa **Database First**: o DBA cria SQL migrations primeiro, depois o SE faz scaffold dos modelos.

#### Workflow para mudanças no schema:

**1. DBA cria migration SQL:**
```bash
# Exemplo: 04-database/migrations/002_add_new_feature.sql
```

**2. Aplicar migration ao banco:**
```bash
docker compose -f 05-infra/docker/docker-compose.dev.yml --env-file 05-infra/configs/.env.dev exec database psql -U mytrader_app -d mytrader_dev -f /db-scripts/migrations/002_add_new_feature.sql
```

**3. SE re-scaffold modelos EF Core:**
```bash
dotnet ef dbcontext scaffold "Host=localhost;Port=5432;Database=mytrader_dev;Username=mytrader_app;Password=local_app" Npgsql.EntityFrameworkCore.PostgreSQL --project 02-backend/src/MyTraderGEO.Infrastructure --context-dir Data --output-dir Data/Models --context ApplicationDbContext --force --no-onconfiguring
```

**📝 Nota sobre Classes Parciais:**
- Modelos EF Core são `partial` para permitir extensões
- Código customizado fica em arquivos separados (ex: `User.Extensions.cs`)
- Re-scaffold com `--force` só sobrescreve arquivos auto-gerados

## Desenvolvimento

### Build

```bash
dotnet build 02-backend/MyTraderGEO.sln
```

### Testes

```bash
# Todos os testes
dotnet test 02-backend/MyTraderGEO.sln

# Testes unitários do domínio
dotnet test 02-backend/tests/MyTraderGEO.Domain.UnitTests/

# Testes de integração
dotnet test 02-backend/tests/MyTraderGEO.IntegrationTests/
```

### Hot Reload

O projeto suporta hot reload durante o desenvolvimento:

```bash
dotnet watch --project 02-backend/src/MyTraderGEO.WebAPI
```

## Configurações

### appsettings.json

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=mytrader_dev;Username=mytrader_app;Password=local_app",
    "_Note": "In Docker: This is overridden by ConnectionStrings__DefaultConnection environment variable (docker-compose.dev.yml line 26). In Local: Ensure PostgreSQL is running with DB_APP_PASSWORD=local_app"
  },
  "JwtSettings": {
    "Secret": "dev-secret-key-change-in-production-minimum-32-chars-long-for-security",
    "Issuer": "myTraderGEO",
    "Audience": "myTraderGEO",
    "ExpirationMinutes": "60"
  },
  "Serilog": {
    "Using": [ "Serilog.Sinks.Console" ],
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "Microsoft.AspNetCore": "Warning",
        "Microsoft.EntityFrameworkCore": "Warning"
      }
    },
    "WriteTo": [
      {
        "Name": "Console",
        "Args": {
          "outputTemplate": "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}"
        }
      }
    ],
    "Enrich": [ "FromLogContext" ]
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

### Variáveis de Ambiente (Docker)

- `ASPNETCORE_ENVIRONMENT` - Ambiente (Development/Staging/Production)
- `ConnectionStrings__DefaultConnection` - String de conexão do banco
- `JwtSettings__Secret` - Secret para JWT
- `JwtSettings__Issuer` - Emissor do token
- `JwtSettings__Audience` - Audiência do token

## Troubleshooting

### Erro ao iniciar a API

**Problema**: API trava após "Starting myTraderGEO API..."

**Solução**: O problema era causado pela configuração do Serilog lendo de appsettings.json. Foi corrigido usando configuração programática.

### Erro 400 ao registrar usuário

Verifique se:
- O email está em formato válido
- A senha tem pelo menos 8 caracteres
- O subscriptionPlanId é um UUID válido e existe no banco
- O billingPeriod é 0 (Monthly) ou 1 (Annually)
- O riskProfile é 0 (Conservador), 1 (Moderado) ou 2 (Agressivo)

### Banco de dados não conecta

1. Verifique se o container do PostgreSQL está rodando:
   ```bash
   docker ps | grep postgres
   ```

2. Teste a conexão:
   ```bash
   docker exec mytrader-dev-database pg_isready -U postgres
   ```

3. Verifique os logs do container:
   ```bash
   docker logs mytrader-dev-database
   ```

## Estrutura de Dados Iniciais

### Planos de Assinatura

1. **Básico** (ID: 10000000-0000-0000-0000-000000000001)
   - Grátis
   - 3 estratégias simultâneas
   - Sem acesso a dados em tempo real

2. **Pleno** (ID: 20000000-0000-0000-0000-000000000002)
   - R$ 49,90/mês ou R$ 479,04/ano
   - 10 estratégias simultâneas
   - Dados em tempo real
   - Alertas avançados

3. **Consultor** (ID: 30000000-0000-0000-0000-000000000003)
   - R$ 99,90/mês ou R$ 959,04/ano
   - Estratégias ilimitadas
   - Todos os recursos do Pleno
   - Ferramentas de consultoria
   - Acesso à comunidade

### Configuração do Sistema

ID Singleton: 00000000-0000-0000-0000-000000000001

Taxas padrão:
- Corretagem: 0% (maioria das corretoras é zero)
- Emolumentos B3: 0,0325%
- Taxa de liquidação: 0,0275%
- Imposto de renda (swing-trade): 15%
- Imposto de renda (day-trade): 20%

Limites globais:
- Máximo de estratégias abertas por usuário: 100
- Máximo de estratégias em template: 20

## Referências

- [.NET Documentation](https://docs.microsoft.com/dotnet/)
- [Entity Framework Core](https://docs.microsoft.com/ef/core/)
- [MediatR](https://github.com/jbogard/MediatR)
- [Serilog](https://serilog.net/)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html)

## Suporte

Para problemas ou dúvidas:
- Abra uma issue no repositório
- Entre em contato: support@mytrader.com

---

**Desenvolvido com .NET 8 e Clean Architecture**
