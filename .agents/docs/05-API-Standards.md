# 05-API-Standards.md

**Versão:** 1.0
**Data:** 2025-10-01
**Público:** DE (Domain Engineer) + FE (Frontend Engineer)

---

## 🎯 Objetivo

Estabelecer padrões de API para garantir consistência, versionamento adequado e boas práticas REST em **qualquer projeto DDD**.

**⚠️ Nota sobre Exemplos:** Exemplos ilustrativos usam domínio genérico (pedidos, usuários). **Adapte para seu domínio específico.**

---

## 📋 Princípios Fundamentais

1. **RESTful** - Recursos claros, verbos HTTP corretos
2. **Idempotência** - Operações críticas são idempotentes
3. **Versionamento** - APIs evoluem sem quebrar clients
4. **Documentação** - OpenAPI/Swagger automático
5. **Segurança** - HTTPS, CORS, Rate Limiting

---

## 🎯 API MVP Checklist - Priorização por Épico

### **⚠️ IMPORTANTE: Evite Overengineering**

Este documento contém TODAS as práticas de API para produção. **NÃO implemente tudo no Epic 1!**

Use esta matriz de priorização para decidir o que implementar em cada fase:

---

### **🔴 EPIC 1-3: MVP Essencial (OBRIGATÓRIO)**

Foco: **Funcionalidade básica funcionando**

#### ✅ Implementar AGORA

| Feature | Por quê? | Exemplo |
|---------|----------|---------|
| **REST básico** | CRUD funcional | GET, POST, PUT, DELETE |
| **Status codes corretos** | Client precisa saber resultado | 200, 201, 400, 404 |
| **DTO mapping** | Não expor domain entities | Request/Response DTOs |
| **Validação básica** | Prevenir dados inválidos | FluentValidation em DTOs |
| **OpenAPI/Swagger** | Frontend precisa de contrato | XML comments → Swagger UI |
| **Error handling consistente** | Debug e troubleshooting | ErrorResponse padrão |

#### ❌ NÃO Implementar Ainda

- ❌ Idempotency Keys (adicionar em Epic 5+)
- ❌ Rate Limiting (adicionar em Epic 5+)
- ❌ Versionamento /v1, /v2 (apenas /v1 fixo)
- ❌ Paginação complexa (cursor-based)
- ❌ Contract Tests (Pact)
- ❌ HATEOAS links

**Exemplo de Controller MVP (Epic 1-3):**

```csharp
[ApiController]
[Route("v1/orders")]
public class OrdersController : ControllerBase
{
    private readonly IMediator _mediator;

    /// <summary>
    /// Create a new order
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
    {
        try
        {
            var command = new CreateOrderCommand(request.CustomerId, request.Items);
            var result = await _mediator.Send(command);

            return CreatedAtAction(nameof(GetOrder), new { id = result.Id }, result);
        }
        catch (ValidationException ex)
        {
            return BadRequest(new ErrorResponse
            {
                Error = "VALIDATION_ERROR",
                Message = ex.Message
            });
        }
    }

    /// <summary>
    /// Get order by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetOrder(Guid id)
    {
        var query = new GetOrderQuery(id);
        var result = await _mediator.Send(query);

        return result != null ? Ok(result) : NotFound();
    }
}
```

**Checklist Epic 1-3:**
- [ ] Endpoints RESTful básicos (GET, POST, PUT)
- [ ] DTOs (não expor domain entities)
- [ ] Validação de input (FluentValidation)
- [ ] Error handling (try-catch → HTTP status codes)
- [ ] OpenAPI docs (XML comments)
- [ ] Response types corretos (200, 201, 400, 404)

---

### **🟡 EPIC 4-6: Produção Básica (RECOMENDADO)**

Foco: **Robustez e escalabilidade inicial**

#### ✅ Implementar Nesta Fase

| Feature | Por quê? | Onde no Doc |
|---------|----------|-------------|
| **Idempotency (POST/PUT)** | Retry safety crítico | [Seção Idempotência](#-idempotência) |
| **Paginação básica** | Listas grandes | [Seção Paginação](#-paginação-filtros-e-ordenação) |
| **Filtros simples** | Query por status, data | [Seção Filtros](#-paginação-filtros-e-ordenação) |
| **CORS configurado** | Frontend precisa de acesso | [Seção Segurança](#️-segurança) |
| **HTTPS obrigatório** | Segurança básica | [Seção Segurança](#️-segurança) |
| **Health check endpoint** | Monitoramento | `/health` |

**Exemplo de Idempotency (Epic 4-6):**

```csharp
[HttpPost]
public async Task<IActionResult> CreateOrder(
    [FromBody] CreateOrderRequest request,
    [FromHeader(Name = "X-Idempotency-Key")] Guid? idempotencyKey)
{
    // Agora SIM implementa idempotency
    if (idempotencyKey.HasValue)
    {
        var existing = await _idempotencyService.GetResult(idempotencyKey.Value);
        if (existing != null)
            return StatusCode(existing.StatusCode, existing.Response);
    }

    var command = new CreateOrderCommand(request.CustomerId, request.Items);
    var result = await _mediator.Send(command);

    if (idempotencyKey.HasValue)
    {
        await _idempotencyService.SaveResult(
            idempotencyKey.Value,
            201,
            result.Id,
            result);
    }

    return CreatedAtAction(nameof(GetOrder), new { id = result.Id }, result);
}
```

**Checklist Epic 4-6:**
- [ ] Idempotency-Key header (POST/PUT críticos)
- [ ] Paginação (page/pageSize ou cursor)
- [ ] Filtros (status, date range)
- [ ] CORS configurado (AllowOrigins específico)
- [ ] HTTPS redirect obrigatório
- [ ] Health check endpoint

---

### **🟢 EPIC 7+: Produção Avançada (OPCIONAL)**

Foco: **Alta escala e contratos rígidos**

#### ✅ Implementar Apenas se Necessário

| Feature | Quando Implementar | Onde no Doc |
|---------|-------------------|-------------|
| **Rate Limiting** | >1000 req/min por user | [Seção Segurança](#️-segurança) |
| **Versionamento /v2** | Breaking change necessário | [Seção Versionamento](#-versionamento-de-api) |
| **Contract Tests (Pact)** | Múltiplos clients (mobile + web) | [Seção Testes](#-testes-de-api) |
| **Cursor-based paging** | Listas com milhões de registros | [Seção Paginação](#-paginação-filtros-e-ordenação) |
| **HATEOAS links** | APIs públicas/externas | [Seção Response](#-estrutura-de-requestresponse) |
| **ETags (caching)** | Performance crítica | Não coberto neste doc |

**Exemplo de Rate Limiting (Epic 7+):**

```csharp
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("api", opt =>
    {
        opt.Window = TimeSpan.FromMinutes(1);
        opt.PermitLimit = 100;
    });
});

[EnableRateLimiting("api")]
[HttpPost("/v1/orders")]
public IActionResult CreateOrder(/* ... */) { }
```

**Checklist Epic 7+:**
- [ ] Rate limiting (100 req/min)
- [ ] Versionamento /v2 (se houver breaking changes)
- [ ] Contract tests (Pact ou similar)
- [ ] Cursor-based pagination (se listas >10k registros)
- [ ] HATEOAS (se API pública)

---

### **📊 Matriz de Decisão Rápida**

| Feature | Epic 1-3 | Epic 4-6 | Epic 7+ | Urgência |
|---------|----------|----------|---------|----------|
| REST básico (GET/POST/PUT) | ✅ | ✅ | ✅ | 🔴 CRÍTICO |
| Status codes corretos | ✅ | ✅ | ✅ | 🔴 CRÍTICO |
| DTOs (não expor domain) | ✅ | ✅ | ✅ | 🔴 CRÍTICO |
| Validação input | ✅ | ✅ | ✅ | 🔴 CRÍTICO |
| OpenAPI/Swagger | ✅ | ✅ | ✅ | 🔴 CRÍTICO |
| Error handling | ✅ | ✅ | ✅ | 🔴 CRÍTICO |
| Idempotency-Key | ❌ | ✅ | ✅ | 🟡 IMPORTANTE |
| Paginação | ❌ | ✅ | ✅ | 🟡 IMPORTANTE |
| CORS | ❌ | ✅ | ✅ | 🟡 IMPORTANTE |
| HTTPS | ❌ | ✅ | ✅ | 🟡 IMPORTANTE |
| Rate Limiting | ❌ | ❌ | ✅ | 🟢 NICE TO HAVE |
| Versionamento /v2 | ❌ | ❌ | ✅ | 🟢 NICE TO HAVE |
| Contract Tests | ❌ | ❌ | ✅ | �� NICE TO HAVE |
| HATEOAS | ❌ | ❌ | ✅ | 🟢 NICE TO HAVE |

---

### **🚨 Sinais de Overengineering no Epic 1-3**

Se você está fazendo isso **no Epic 1**, PARE:

- ❌ Implementando Idempotency-Key (exceto se operação financeira)
- ❌ Criando /v1 e /v2 (ainda não há v2!)
- ❌ Rate limiting (ainda não tem carga)
- ❌ Contract tests (ainda não tem clients múltiplos)
- ❌ HATEOAS links (REST nível 3)
- ❌ Cursor-based pagination (ainda não tem 10k+ registros)
- ❌ ETags (ainda não tem problema de performance)

**Lembre-se:** YAGNI (You Aren't Gonna Need It) - Implemente quando precisar, não "por precaução".

---

## 🌐 Estrutura de URLs

### Padrão Base

```
https://api.[YOUR-DOMAIN]/v1/{bounded-context}/{resource}
```

**Exemplos (domínio genérico de e-commerce):**
```
GET    /v1/orders                        # Listar pedidos
POST   /v1/orders                        # Criar pedido
GET    /v1/orders/{id}                   # Obter pedido
PUT    /v1/orders/{id}                   # Atualizar pedido
DELETE /v1/orders/{id}                   # Deletar pedido

GET    /v1/orders/{id}/items             # Items do pedido (sub-resource)
POST   /v1/orders/{id}/fulfill           # Ação customizada
```

### Convenções de Naming

- **Recursos:** Plural, lowercase (orders, products, users)
- **IDs:** GUID no path (`/orders/550e8400-e29b-41d4-a716-446655440000`)
- **Query params:** camelCase (`?includeItems=true&sortBy=createdAt`)
- **JSON fields:** camelCase (`{ "orderTotal": 99.99 }`)

---

## 📦 Estrutura de Request/Response

### Request (POST/PUT)

```json
POST /v1/orders
Content-Type: application/json
X-Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000

{
  "customerId": "abc-123-def-456",
  "items": [
    {
      "productId": "prod-001",
      "quantity": 2,
      "unitPrice": 49.99
    },
    {
      "productId": "prod-002",
      "quantity": 1,
      "unitPrice": 99.99
    }
  ],
  "shippingAddress": {
    "street": "123 Main St",
    "city": "Springfield",
    "zipCode": "12345"
  }
}
```

### Response (Success - 201 Created)

```json
HTTP/1.1 201 Created
Location: /v1/orders/550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "customerId": "abc-123-def-456",
  "status": "PENDING",
  "total": 199.97,
  "createdAt": "2025-10-01T10:30:00Z",
  "items": [
    {
      "id": "item-001",
      "productId": "prod-001",
      "quantity": 2,
      "unitPrice": 49.99,
      "subtotal": 99.98
    }
  ],
  "_links": {
    "self": { "href": "/v1/orders/550e8400-e29b-41d4-a716-446655440000" },
    "fulfill": { "href": "/v1/orders/550e8400-e29b-41d4-a716-446655440000/fulfill" }
  }
}
```

### Response (Error - 400 Bad Request)

```json
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid order data",
    "details": [
      {
        "field": "items[0].quantity",
        "error": "Quantity must be greater than 0",
        "value": -1
      }
    ]
  },
  "traceId": "abc-123-def-456"
}
```

---

## 🔢 HTTP Status Codes

### Success (2xx)

| Code | Uso | Exemplo |
|------|-----|---------|
| **200 OK** | GET, PUT bem-sucedido | Retornar pedido, atualizar pedido |
| **201 Created** | POST criou recurso | Criar pedido |
| **204 No Content** | DELETE bem-sucedido | Deletar pedido |

### Client Errors (4xx)

| Code | Uso | Exemplo |
|------|-----|---------|
| **400 Bad Request** | Validação falhou | Quantidade negativa, dados inválidos |
| **401 Unauthorized** | Não autenticado | Token JWT ausente/inválido |
| **403 Forbidden** | Não autorizado | User tentando deletar pedido de outro |
| **404 Not Found** | Recurso não existe | GET /orders/id-inexistente |
| **409 Conflict** | Conflito de estado | Cancelar pedido já enviado |
| **422 Unprocessable Entity** | Business rule falhou | Pedido excede limite de crédito |
| **429 Too Many Requests** | Rate limit excedido | >100 requests/min |

### Server Errors (5xx)

| Code | Uso | Exemplo |
|------|-----|---------|
| **500 Internal Server Error** | Erro genérico | Exception não tratada |
| **503 Service Unavailable** | Serviço indisponível | Database down, maintenance |

---

## 🔄 Versionamento de API

### Estratégia: URL Versioning (v1, v2, v3)

**Formato:** `/v{major}/resource`

```
/v1/orders  →  Versão 1 (atual)
/v2/orders  →  Versão 2 (futura, com breaking changes)
```

### Quando Incrementar Versão?

| Mudança | Major (v1 → v2) | Minor (backward compatible) |
|---------|-----------------|----------------------------|
| **Remove field** | ✅ Breaking | ❌ |
| **Rename field** | ✅ Breaking | ❌ |
| **Change type** | ✅ Breaking | ❌ |
| **Add optional field** | ❌ | ✅ Safe |
| **Add new endpoint** | ❌ | ✅ Safe |
| **Deprecate endpoint** | ❌ | ✅ Safe (com aviso) |

### Deprecation Process

```csharp
[Obsolete("Use /v2/orders instead. This endpoint will be removed on 2026-01-01")]
[HttpGet("/v1/orders")]
public IActionResult GetOrdersV1()
{
    Response.Headers.Add("X-API-Deprecated", "true");
    Response.Headers.Add("X-API-Sunset", "2026-01-01");

    // ...
}
```

---

## 🔒 Idempotência

### Idempotency Key Header

**Operações que DEVEM ser idempotentes:**
- POST (criar recurso)
- PUT (atualizar)
- DELETE (se executado 2x, mesmo efeito)

```http
POST /v1/orders
X-Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
```

**Client:**
- Gera GUID único por request
- Retry usa MESMO key

**Server:**
- Verifica se key já processado
- Se sim: retorna resultado anterior (mesmo status code)
- Se não: processa normalmente

```csharp
[HttpPost]
public async Task<IActionResult> CreateOrder(
    [FromBody] CreateOrderRequest request,
    [FromHeader(Name = "X-Idempotency-Key")] Guid idempotencyKey)
{
    // Verifica se já processado
    var existing = await _idempotencyService
        .GetResult(idempotencyKey);

    if (existing != null)
    {
        return existing.StatusCode == 201
            ? CreatedAtAction(nameof(GetOrder),
                new { id = existing.ResourceId },
                existing.Response)
            : StatusCode(existing.StatusCode, existing.Response);
    }

    // Processa (primeira vez)
    var order = await _orderService.Create(request);

    // Salva resultado para idempotência
    await _idempotencyService.SaveResult(
        idempotencyKey,
        statusCode: 201,
        resourceId: order.Id,
        response: order);

    return CreatedAtAction(nameof(GetOrder),
        new { id = order.Id },
        order);
}
```

---

## 🛡️ Segurança

### 1. HTTPS Obrigatório

```csharp
// Startup.cs
app.UseHttpsRedirection();
app.UseHsts(); // HTTP Strict Transport Security
```

### 2. CORS Configuration

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("https://app.[YOUR-DOMAIN]")
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});
```

### 3. Rate Limiting

```csharp
// Rate limit: 100 requests/min por user
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("api", opt =>
    {
        opt.Window = TimeSpan.FromMinutes(1);
        opt.PermitLimit = 100;
        opt.QueueLimit = 0;
    });
});

// Aplicar no endpoint
[EnableRateLimiting("api")]
[HttpPost("/v1/orders")]
public IActionResult CreateOrder(/* ... */) { }
```

### 4. Authentication & Authorization

```csharp
[Authorize] // Requer JWT token
[HttpPost("/v1/orders")]
public async Task<IActionResult> CreateOrder(/* ... */)
{
    var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    // ...
}

// Política customizada
[Authorize(Policy = "CanCancelOrder")]
[HttpPost("/v1/orders/{id}/cancel")]
public IActionResult CancelOrder(Guid id) { }
```

---

## 📖 Documentação: OpenAPI/Swagger

### Configuração

```csharp
// Program.cs
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "[PROJECT-NAME] API",
        Version = "v1",
        Description = "[Your API description]",
        Contact = new OpenApiContact
        {
            Name = "Support",
            Email = "api@[YOUR-DOMAIN]"
        }
    });

    // JWT authentication
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
});
```

### Documentar Endpoints

```csharp
/// <summary>
/// Create a new order
/// </summary>
/// <param name="request">Order details</param>
/// <param name="idempotencyKey">Idempotency key for retry safety</param>
/// <returns>Created order</returns>
/// <response code="201">Order created successfully</response>
/// <response code="400">Invalid request (validation errors)</response>
/// <response code="422">Business rule violation</response>
[HttpPost]
[ProducesResponseType(typeof(OrderResponse), StatusCodes.Status201Created)]
[ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
[ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status422UnprocessableEntity)]
public async Task<IActionResult> CreateOrder(
    [FromBody] CreateOrderRequest request,
    [FromHeader(Name = "X-Idempotency-Key")] Guid idempotencyKey)
{
    // ...
}
```

### Swagger UI Endpoint

```
https://api.[YOUR-DOMAIN]/swagger/index.html
```

---

## 🔍 Paginação, Filtros e Ordenação

### Paginação (Cursor-based para alta performance)

**Request:**
```http
GET /v1/orders?limit=20&cursor=abc123def456
```

**Response:**
```json
{
  "data": [
    { "id": "...", "customerId": "...", "total": 99.99 }
  ],
  "paging": {
    "next": "/v1/orders?limit=20&cursor=xyz789abc",
    "previous": null
  }
}
```

**Implementação:**
```csharp
[HttpGet]
public async Task<IActionResult> GetOrders(
    [FromQuery] int limit = 20,
    [FromQuery] string? cursor = null)
{
    var orders = await _repo.GetPaginated(limit, cursor);

    var response = new
    {
        data = orders.Items,
        paging = new
        {
            next = orders.HasNext
                ? $"/v1/orders?limit={limit}&cursor={orders.NextCursor}"
                : null,
            previous = orders.HasPrevious
                ? $"/v1/orders?limit={limit}&cursor={orders.PreviousCursor}"
                : null
        }
    };

    return Ok(response);
}
```

### Filtros

```http
GET /v1/orders?status=PENDING&minTotal=100
```

```csharp
[HttpGet]
public async Task<IActionResult> GetOrders(
    [FromQuery] OrderStatus? status = null,
    [FromQuery] decimal? minTotal = null)
{
    var spec = new OrderFilterSpec(status, minTotal);
    var orders = await _repo.Find(spec);

    return Ok(orders);
}
```

### Ordenação

```http
GET /v1/orders?sortBy=createdAt&order=desc
```

```csharp
[HttpGet]
public async Task<IActionResult> GetOrders(
    [FromQuery] string sortBy = "createdAt",
    [FromQuery] string order = "asc")
{
    var orders = await _repo.GetAll(sortBy, order);
    return Ok(orders);
}
```

---

## 🧪 Testes de API

### Contract Testing (Exemplo com Pact)

```csharp
// Consumer test (Frontend)
[Fact]
public async Task GetOrder_ShouldReturnOrder()
{
    _mockProviderService
        .Given("Order 123 exists")
        .UponReceiving("A request for order 123")
        .With(new ProviderServiceRequest
        {
            Method = HttpVerb.Get,
            Path = "/v1/orders/123"
        })
        .WillRespondWith(new ProviderServiceResponse
        {
            Status = 200,
            Headers = new Dictionary<string, object>
            {
                { "Content-Type", "application/json" }
            },
            Body = new
            {
                id = "123",
                customerId = "cust-456",
                total = 199.97,
                status = "PENDING"
            }
        });

    var result = await _apiClient.GetOrder("123");

    Assert.Equal("123", result.Id);
    Assert.Equal("cust-456", result.CustomerId);
}
```

---

## ✅ Checklist de API Design

### Antes de Criar Endpoint:
- [ ] Nome do recurso é plural e claro? (`/orders`, não `/order`)
- [ ] Verbo HTTP correto? (GET = read, POST = create, PUT = update, DELETE = delete)
- [ ] Endpoint é idempotente? (se POST/PUT, usar X-Idempotency-Key)
- [ ] Versionamento correto? (`/v1/...`)
- [ ] Status codes apropriados?

### Implementação:
- [ ] Request validation (FluentValidation)
- [ ] Response DTOs (não expor domain entities)
- [ ] Error handling consistente
- [ ] OpenAPI documentation (XML comments)
- [ ] Rate limiting aplicado?
- [ ] Authorization verificada?

### Testes:
- [ ] Unit tests (business logic)
- [ ] Integration tests (API)
- [ ] Contract tests (se múltiplos clients)

---

## 🎮 Controller Implementation Examples

### Complete REST Controller

Exemplo completo implementando TODOS os padrões deste documento:

```csharp
using MediatR;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("v1/orders")]
[Produces("application/json")]
public class OrdersController : ControllerBase
{
    private readonly IMediator _mediator;

    public OrdersController(IMediator mediator) => _mediator = mediator;

    /// <summary>
    /// Create a new order (idempotent)
    /// </summary>
    /// <param name="request">Order creation request</param>
    /// <param name="idempotencyKey">Idempotency key (GUID)</param>
    /// <returns>Created order</returns>
    [HttpPost]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> CreateOrder(
        [FromBody] CreateOrderRequest request,
        [FromHeader(Name = "X-Idempotency-Key")] Guid idempotencyKey)
    {
        var command = new CreateOrderCommand(
            request.CustomerId,
            request.Items,
            idempotencyKey
        );

        try
        {
            var result = await _mediator.Send(command);

            return CreatedAtAction(
                nameof(GetOrder),
                new { id = result.Id },
                result
            );
        }
        catch (ValidationException ex)
        {
            return BadRequest(new ErrorResponse
            {
                Error = "VALIDATION_ERROR",
                Message = ex.Message,
                Details = ex.Errors
            });
        }
        catch (DomainException ex)
        {
            return UnprocessableEntity(new ErrorResponse
            {
                Error = "BUSINESS_RULE_VIOLATION",
                Message = ex.Message
            });
        }
    }

    /// <summary>
    /// Get order by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetOrder(Guid id)
    {
        var query = new GetOrderQuery(id);
        var result = await _mediator.Send(query);

        return result != null
            ? Ok(result)
            : NotFound(new ErrorResponse
            {
                Error = "ORDER_NOT_FOUND",
                Message = $"Order {id} not found"
            });
    }

    /// <summary>
    /// List orders with pagination
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(PaginatedResponse<OrderDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListOrders(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? status = null)
    {
        var query = new ListOrdersQuery(page, pageSize, status);
        var result = await _mediator.Send(query);

        Response.Headers.Add("X-Total-Count", result.TotalCount.ToString());
        Response.Headers.Add("X-Page", page.ToString());
        Response.Headers.Add("X-Page-Size", pageSize.ToString());

        return Ok(result);
    }

    /// <summary>
    /// Confirm order (business action)
    /// </summary>
    [HttpPost("{id:guid}/confirm")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ErrorResponse), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> ConfirmOrder(
        Guid id,
        [FromHeader(Name = "X-Idempotency-Key")] Guid idempotencyKey)
    {
        var command = new ConfirmOrderCommand(id, idempotencyKey);

        try
        {
            await _mediator.Send(command);
            return NoContent();
        }
        catch (NotFoundException)
        {
            return NotFound(new ErrorResponse
            {
                Error = "ORDER_NOT_FOUND",
                Message = $"Order {id} not found"
            });
        }
        catch (DomainException ex)
        {
            return UnprocessableEntity(new ErrorResponse
            {
                Error = "BUSINESS_RULE_VIOLATION",
                Message = ex.Message
            });
        }
    }
}
```

### Key Implementation Points

**1. Route & Versioning:**
```csharp
[Route("v1/orders")]  // Version in URL
```

**2. Idempotency:**
```csharp
[FromHeader(Name = "X-Idempotency-Key")] Guid idempotencyKey
// Passar para Command, implementar check em Handler
```

**3. Status Codes:**
- `201 Created` → Resource created + Location header
- `200 OK` → Success with response body
- `204 No Content` → Success without response body
- `400 Bad Request` → Invalid input (validation)
- `404 Not Found` → Resource not found
- `422 Unprocessable Entity` → Business rule violation

**4. OpenAPI Documentation:**
```csharp
/// <summary> XML comments → Swagger docs
[ProducesResponseType] → Response types for OpenAPI
```

**5. Error Handling:**
```csharp
try-catch → Map domain exceptions to HTTP status codes
ErrorResponse → Consistent error format
```

**6. Pagination Headers:**
```csharp
Response.Headers.Add("X-Total-Count", ...);
Response.Headers.Add("X-Page", ...);
```

### Error Response Model

```csharp
public record ErrorResponse
{
    public string Error { get; init; }
    public string Message { get; init; }
    public object? Details { get; init; }
}

// Example response:
// {
//   "error": "BUSINESS_RULE_VIOLATION",
//   "message": "Cannot confirm order in Cancelled status",
//   "details": null
// }
```

### Common Mistakes to Avoid

**❌ Don't:**
```csharp
// Business logic in controller
public IActionResult CreateOrder(...)
{
    var order = new Order();
    order.Total = request.Items.Sum(i => i.Price); // ❌
    _repository.Add(order);
}
```

**✅ Do:**
```csharp
// Delegate to Command Handler
public IActionResult CreateOrder(...)
{
    var command = new CreateOrderCommand(...);
    return await _mediator.Send(command); // ✅
}
```

---

## 🔗 Referências

- **REST API Guidelines:** Microsoft REST API Guidelines
- **OpenAPI Spec:** https://swagger.io/specification/
- **Idempotency:** Stripe API Idempotency Guide
- **Versioning:** API Versioning Best Practices (Google)

---

**Document Version:** 1.0
**Status:** Living Document
**Next Review:** Após Epic 1 (ajustar based on uso real)
