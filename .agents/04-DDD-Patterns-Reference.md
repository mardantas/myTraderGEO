# 04-DDD-Patterns-Reference.md

**Versão:** 1.0
**Data:** 2025-10-02
**Público:** DE (Domain Engineer)

---

## 🎯 Objetivo

Documentar padrões DDD para **referência e consulta** em cenários específicos de **qualquer projeto DDD**. Este documento é **guia de referência** para o DE (agente) - use quando necessário, **não implemente tudo de uma vez** (evitar over-engineering).

**⚠️ Nota sobre Exemplos:** Exemplos ilustrativos usam domínio genérico de e-commerce/pedidos. **Adapte para seu domínio específico.**

---

## 🎯 Matriz de Priorização: Quando Usar Cada Padrão

### Guia Geral por Fase do Projeto

| Padrão | Cenário Típico | Prioridade | Exemplo Genérico |
|--------|----------------|----------------|------------------|
| **Idempotency** | Operações críticas não-repetíveis (criar, pagar) | 🔴 **Epic 1-2** | Criar pedido, processar pagamento |
| **Domain Service** | Lógica de negócio entre 2+ Aggregates | 🔴 **Epic 1-3** | Calcular desconto (Order + Customer + Promotion) |
| **Factory** | Criação complexa de Aggregate (múltiplos steps) | 🟡 **Epic 1-3** | Criar pedido com validações e items |
| **Specification** | Queries complexas reutilizadas em múltiplos lugares | 🟡 **Epic 3-5** | Filtros avançados (status + data + categoria) |
| **Saga (Orchestration)** | Operação multi-BC com compensação | 🟢 **Epic 5+** | Processar pedido (Payment → Inventory → Shipping) |
| **Outbox** | Eventos críticos distribuídos (garantia de entrega) | 🟢 **Produção** | Garantir publicação de OrderCreated para billing |

### Legenda de Prioridade
- 🔴 **Epic 1-3:** Implemente cedo, é fundamental para operações básicas
- 🟡 **Epic 3-5 (Crescimento):** Avalie durante implementação, útil mas não crítico
- 🟢 **Epic 5+ ou Produção:** Apenas quando escalar, alta carga ou compliance exigir

### Como Decidir

**Pergunte-se:**
1. **Idempotency:** Essa operação pode ser executada 2x por acidente? (retry, duplo-clique) → Se sim, use
2. **Domain Service:** Essa lógica envolve 2+ Aggregates diferentes? → Se sim, considere
3. **Factory:** Criar este Aggregate tem >3 steps complexos? → Se sim, considere
4. **Specification:** Esta query se repete em 3+ lugares? → Se sim, use
5. **Saga:** Esta operação atravessa 3+ BCs e pode falhar no meio? → Se sim, considere (mas avalie complexidade)
6. **Outbox:** Perder este evento causa prejuízo grave? → Se sim, use (mas apenas em produção)

---

## 📚 Índice de Padrões

1. [Saga Pattern (Process Manager)](#saga-pattern) - Transações distribuídas entre BCs
2. [Outbox Pattern](#outbox-pattern) - Publicação confiável de eventos
3. [Specification Pattern](#specification-pattern) - Queries complexas encapsuladas
4. [Domain Service](#domain-service) - Operações sem dono claro
5. [Factory Pattern](#factory-pattern) - Criação complexa de aggregates
6. [Idempotency Pattern](#idempotency-pattern) - Operações repetíveis sem efeito colateral

---

<a name="saga-pattern"></a>
## 1. Saga Pattern (Process Manager)

### O que é?

**Saga** coordena uma sequência de operações que atravessam múltiplos Bounded Contexts, garantindo consistência eventual quando transações ACID não são possíveis.

**Problema que resolve:**
- Transação distribuída: operação envolve Order BC + Payment BC + Inventory BC
- ACID transaction não funciona entre BCs (bounded contexts são independentes)
- Precisa coordenar: Create Order → Process Payment → Reserve Inventory

### Quando usar?

✅ **Use Saga quando:**
- Operação atravessa 2+ Bounded Contexts
- Cada step pode falhar independentemente
- Precisa compensar falhas (rollback distribuído)

❌ **Não use quando:**
- Operação dentro de 1 BC só (use transaction normal)
- Não há dependência entre steps

### Tipos de Saga

#### **1. Choreography Saga** (Baseado em eventos)
Cada BC escuta eventos e decide próximo passo.

```
[Order BC]  →  OrderCreated event
                    ↓
             [Payment BC] escuta
                    ↓
             Processa pagamento
                    ↓
             PaymentProcessed event
                    ↓
             [Inventory BC] escuta
                    ↓
             Reserva estoque
                    ↓
             InventoryReserved event
```

**Prós:** Desacoplado, BCs independentes
**Contras:** Difícil rastrear fluxo completo

#### **2. Orchestration Saga** (Coordenador central)
Um **Process Manager** (Saga) coordena o fluxo.

```csharp
public class OrderFulfillmentProcess
{
    public Guid ProcessId { get; private set; }
    public Guid OrderId { get; private set; }
    public ProcessState State { get; private set; }

    // State: Created → PaymentProcessing → InventoryReserving → Completed

    public void Handle(OrderCreated @event)
    {
        OrderId = @event.OrderId;
        State = ProcessState.PaymentProcessing;

        // Envia command para Payment BC
        _commandBus.Send(new ProcessPayment(OrderId, @event.Amount));
    }

    public void Handle(PaymentProcessed @event)
    {
        State = ProcessState.InventoryReserving;

        // Envia command para Inventory BC
        _commandBus.Send(new ReserveInventory(OrderId, @event.Items));
    }

    public void Handle(InventoryReserved @event)
    {
        State = ProcessState.Completed;
        // Saga concluída!
    }

    // Compensação (Rollback)
    public void Handle(PaymentFailed @event)
    {
        State = ProcessState.Failed;

        // Compensa: cancela ordem
        _commandBus.Send(new CancelOrder(OrderId));
    }
}
```

**Prós:** Fluxo centralizado, fácil rastrear
**Contras:** Process Manager pode virar ponto central de falha

### Exemplo Genérico: "Processar Pedido"

**Cenário:** Usuário cria pedido → processa pagamento → reserva estoque → envia para shipping

**Saga Orchestrada:**

1. **OrderFulfillmentSaga** (Process Manager)
2. **Step 1:** Process payment (Payment BC)
3. **Step 2:** Reserve inventory (Inventory BC)
4. **Step 3:** Create shipment (Shipping BC)

**Compensação se falhar:**
- Payment falhou? → Cancel order
- Inventory indisponível? → Refund payment + cancel order
- Shipping falhou? → Release inventory + refund payment

### Implementação

**Persistência:**
- Saga state: Tabela `SagaInstances` (Id, State, Data JSON)
- Events: Event Store ou Outbox (próximo padrão)

**Frameworks:**
- **NServiceBus** (paid)
- **MassTransit** (open-source) ⭐ Recomendado
- **Manual** (para aprender, projetos iniciais)

---

<a name="outbox-pattern"></a>
## 2. Outbox Pattern

### O que é?

**Outbox** garante que Domain Events sejam publicados **exatamente uma vez**, mesmo se o sistema cair após salvar no banco.

**Problema que resolve:**
- Salvou aggregate no DB ✅
- Sistema caiu ANTES de publicar evento ❌
- Evento perdido, BCs dessincronizados

### Como Funciona?

**Duas escritas atômicas (mesma transaction):**

1. Salvar aggregate
2. Salvar evento na tabela `Outbox`

**Publisher separado:**
- Background job lê `Outbox`
- Publica eventos
- Marca como publicado

```csharp
// 1. Salvar aggregate + evento (mesma transaction)
public async Task Handle(CreateOrderCommand cmd)
{
    var order = new Order(cmd.CustomerId, cmd.Items);

    // Domain event
    var @event = new OrderCreated(order.Id, order.Total);

    await _dbContext.Orders.AddAsync(order);

    // Outbox: salva evento para publicação futura
    await _dbContext.OutboxMessages.AddAsync(new OutboxMessage
    {
        EventType = nameof(OrderCreated),
        Payload = JsonSerializer.Serialize(@event),
        CreatedAt = DateTime.UtcNow
    });

    await _dbContext.SaveChangesAsync(); // Transação atômica!
}

// 2. Publisher (background job)
public class OutboxPublisher : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            var pending = await _dbContext.OutboxMessages
                .Where(m => m.PublishedAt == null)
                .Take(100)
                .ToListAsync(ct);

            foreach (var msg in pending)
            {
                // Publica no message bus
                await _eventBus.Publish(msg.Payload);

                msg.PublishedAt = DateTime.UtcNow;
            }

            await _dbContext.SaveChangesAsync(ct);
            await Task.Delay(1000, ct); // Poll a cada 1s
        }
    }
}
```

### Quando usar?

✅ **Use Outbox quando:**
- Domain Events críticos (não pode perder)
- Múltiplos BCs dependem do evento
- Precisa garantir "exatamente uma vez"

❌ **Não use quando:**
- Evento não é crítico (ex: log de auditoria)
- Projetos iniciais (pode começar sem e adicionar depois)

### Schema Outbox

```sql
CREATE TABLE OutboxMessages
(
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    EventType NVARCHAR(200) NOT NULL,
    Payload NVARCHAR(MAX) NOT NULL, -- JSON
    CreatedAt DATETIME2 NOT NULL,
    PublishedAt DATETIME2 NULL,
    INDEX IX_PublishedAt (PublishedAt) -- Query rápida para pending
);
```

---

<a name="specification-pattern"></a>
## 3. Specification Pattern

### O que é?

**Specification** encapsula regras de negócio complexas para queries, permitindo reuso e composição.

**Problema que resolve:**
- Query complexa espalhada em vários lugares
- Difícil testar lógica de query
- Duplicação de business rules

### Exemplo Simples

```csharp
// Interface
public interface ISpecification<T>
{
    bool IsSatisfiedBy(T candidate);
    Expression<Func<T, bool>> ToExpression(); // Para EF Core
}

// Specification: "Pedidos ativos"
public class ActiveOrdersSpec : ISpecification<Order>
{
    public bool IsSatisfiedBy(Order order)
    {
        return order.Status == OrderStatus.Active &&
               order.CreatedAt > DateTime.Now.AddDays(-30);
    }

    public Expression<Func<Order, bool>> ToExpression()
    {
        return o => o.Status == OrderStatus.Active &&
                    o.CreatedAt > DateTime.Now.AddDays(-30);
    }
}

// Uso no Repository
public async Task<List<Order>> GetActiveOrders()
{
    var spec = new ActiveOrdersSpec();

    return await _dbContext.Orders
        .Where(spec.ToExpression())
        .ToListAsync();
}
```

### Composição de Specifications

```csharp
// And Specification
public class AndSpecification<T> : ISpecification<T>
{
    private readonly ISpecification<T> _left;
    private readonly ISpecification<T> _right;

    public AndSpecification(ISpecification<T> left, ISpecification<T> right)
    {
        _left = left;
        _right = right;
    }

    public bool IsSatisfiedBy(T candidate)
    {
        return _left.IsSatisfiedBy(candidate) &&
               _right.IsSatisfiedBy(candidate);
    }
}

// Uso
var activeSpec = new ActiveOrdersSpec();
var highValueSpec = new HighValueOrdersSpec(); // Total > 1000

var activeAndHighValue = new AndSpecification<Order>(activeSpec, highValueSpec);

var orders = await _repo.Find(activeAndHighValue);
```

### Quando usar?

✅ **Use Specification quando:**
- Query complexa reutilizada em vários lugares
- Precisa testar lógica de filtro isoladamente
- Business rules podem ser combinadas (AND, OR, NOT)

❌ **Não use quando:**
- Query simples de 1 linha
- Não há reuso

---

<a name="domain-service"></a>
## 4. Domain Service

### O que é?

**Domain Service** é operação de domínio **stateless** que não pertence a nenhum Aggregate específico.

**Quando usar?**
- Operação envolve 2+ Aggregates
- Lógica de negócio não "cabe" em nenhum Aggregate

### Exemplo: Cálculo de Desconto Multi-Item

```csharp
// Domain Service (stateless)
public class OrderPricingService
{
    public decimal CalculateTotalWithDiscounts(
        Order order,
        Customer customer,
        List<Promotion> activePromotions)
    {
        decimal total = order.Items.Sum(i => i.Price * i.Quantity);

        // Desconto por volume
        if (order.Items.Count > 10)
            total *= 0.9m; // 10% off

        // Desconto VIP customer
        if (customer.IsVIP)
            total *= 0.95m; // 5% off

        // Promoções ativas
        foreach (var promo in activePromotions)
        {
            total -= promo.CalculateDiscount(order);
        }

        return total;
    }
}

// Uso
var pricingService = new OrderPricingService();
var finalTotal = pricingService.CalculateTotalWithDiscounts(order, customer, promotions);
```

**Diferença para Application Service:**
- **Domain Service:** Lógica de domínio (business rules)
- **Application Service:** Orquestração (chama repository, domain service, etc)

---

<a name="factory-pattern"></a>
## 5. Factory Pattern

### O que é?

**Factory** encapsula criação complexa de Aggregates.

### Quando usar?

✅ **Use Factory quando:**
- Criar Aggregate envolve múltiplos steps
- Lógica de criação é complexa
- Vários tipos de criação (Factory Methods)

### Exemplo: OrderFactory

```csharp
public interface IOrderFactory
{
    Order CreateStandardOrder(
        CustomerId customerId,
        List<OrderItem> items);

    Order CreateSubscriptionOrder(
        CustomerId customerId,
        ProductId productId,
        BillingPeriod period);
}

public class OrderFactory : IOrderFactory
{
    public Order CreateStandardOrder(
        CustomerId customerId,
        List<OrderItem> items)
    {
        var order = new Order(customerId, OrderType.Standard);

        foreach (var item in items)
        {
            order.AddItem(item);
        }

        return order;
    }

    public Order CreateSubscriptionOrder(
        CustomerId customerId,
        ProductId productId,
        BillingPeriod period)
    {
        var order = new Order(customerId, OrderType.Subscription);

        // Lógica complexa: calcula próximo billing date, cria recurring schedule
        var billingDate = period == BillingPeriod.Monthly
            ? DateTime.Now.AddMonths(1)
            : DateTime.Now.AddYears(1);

        order.SetBillingSchedule(billingDate, period);
        order.AddSubscriptionProduct(productId);

        return order;
    }
}
```

---

<a name="idempotency-pattern"></a>
## 6. Idempotency Pattern

### O que é?

**Idempotency** garante que executar operação múltiplas vezes tem o **mesmo efeito** de executar uma vez.

**Problema que resolve:**
- Request duplicado (retry automático)
- Operações críticas: criar pedido 2x = duplicata ❌

### Implementação: Idempotency Key

```csharp
public class CreateOrderCommand
{
    public Guid IdempotencyKey { get; set; } // Gerado pelo client
    public CustomerId CustomerId { get; set; }
    public List<OrderItem> Items { get; set; }
}

public class CreateOrderHandler
{
    public async Task<Order> Handle(CreateOrderCommand cmd)
    {
        // 1. Verifica se já processou este IdempotencyKey
        var existing = await _dbContext.IdempotencyRecords
            .FirstOrDefaultAsync(r => r.Key == cmd.IdempotencyKey);

        if (existing != null)
        {
            // Já processado, retorna resultado anterior
            return await _dbContext.Orders
                .FindAsync(existing.ResultId);
        }

        // 2. Processa (primeira vez)
        var order = new Order(cmd.CustomerId, cmd.Items);
        await _dbContext.Orders.AddAsync(order);

        // 3. Salva IdempotencyKey
        await _dbContext.IdempotencyRecords.AddAsync(new IdempotencyRecord
        {
            Key = cmd.IdempotencyKey,
            ResultId = order.Id,
            ProcessedAt = DateTime.UtcNow
        });

        await _dbContext.SaveChangesAsync();

        return order;
    }
}
```

### Schema

```sql
CREATE TABLE IdempotencyRecords
(
    Id BIGINT IDENTITY PRIMARY KEY,
    [Key] UNIQUEIDENTIFIER UNIQUE NOT NULL,
    ResultId UNIQUEIDENTIFIER NOT NULL, -- ID do resultado
    ProcessedAt DATETIME2 NOT NULL,
    INDEX IX_Key ([Key])
);
```

### Quando usar?

✅ **Use Idempotency quando:**
- Operação crítica (pagamento, criação de pedido)
- Client pode retry automaticamente
- Duplicação tem consequência grave

❌ **Não use quando:**
- Operação naturalmente idempotent (GET)
- Duplicação não é problema

---

## 📊 Matriz de Decisão: Qual Padrão Usar?

| Cenário | Padrão Recomendado |
|---------|-------------------|
| Operação atravessa múltiplos BCs | **Saga Pattern** |
| Publicar evento com garantia | **Outbox Pattern** |
| Query complexa reutilizada | **Specification Pattern** |
| Operação entre 2+ Aggregates | **Domain Service** |
| Criação complexa de Aggregate | **Factory Pattern** |
| Prevenir duplicação de operação crítica | **Idempotency Pattern** |

---

## 🎯 Recomendações para Implementação Inicial

### ✅ Implementar Agora (Essencial):
1. **Idempotency** - Crítico para operações não-repetíveis
2. **Domain Service** - Lógica que cruza aggregates
3. **Factory** - Se criação de aggregate for complexa

### ⏳ Implementar se Precisar (Avaliar):
4. **Specification** - Se queries ficarem complexas e repetidas
5. **Saga** - Se operações multi-BC falharem com frequência

### 🚀 Implementar Depois (Produção com Escala):
6. **Outbox** - Quando garantia de entrega de eventos for crítica

---

## 🔗 Referências

- **Implementing DDD (Vernon):** Capítulos sobre Sagas, Services
- **Microservices Patterns (Richardson):** Saga Pattern detalhado
- **Enterprise Integration Patterns:** Outbox, Idempotency
- **MassTransit Docs:** Implementação Saga/Outbox
- **Domain-Driven Design (Evans):** Specification, Services, Factories

---

**Document Version:** 1.0
**Status:** Living Document - Genérico para qualquer domínio DDD
**Próxima Revisão:** Após implementar padrões no projeto real
