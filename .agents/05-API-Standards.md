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

## 🔗 Referências

- **REST API Guidelines:** Microsoft REST API Guidelines
- **OpenAPI Spec:** https://swagger.io/specification/
- **Idempotency:** Stripe API Idempotency Guide
- **Versioning:** API Versioning Best Practices (Google)

---

**Document Version:** 1.0
**Status:** Living Document
**Next Review:** Após Epic 1 (ajustar based on uso real)
