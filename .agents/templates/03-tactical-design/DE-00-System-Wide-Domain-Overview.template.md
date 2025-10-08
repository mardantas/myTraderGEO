# DE-00-System-Wide-Domain-Overview.md

**Versão:** 1.0
**Data:** [YYYY-MM-DD]
**Fase:** Discovery (1x por projeto)
**Autor:** DE (Domain Engineer)
**Status:** [Draft | Review | Approved]

---

## 🎯 Objetivo

Fornecer visão geral de alto nível do modelo de domínio para **todo o sistema**, identificando Aggregates principais, Value Objects compartilhados e Domain Events para todos os Bounded Contexts.

**Nível de Detalhe:** Superficial (sem invariantes detalhadas, sem Use Cases)
**Público-alvo:** UXD, PE, SEC (contexto para trabalho posterior)

---

## 📊 1. Aggregates Principais por Bounded Context

### [Nome do BC 1]

#### [Aggregate Root 1]
- **Descrição Negócio:** [O que representa no domínio]
- **Identidade:** [NomeId (ex: OrderId, CustomerId)]
- **Estados Principais:** [ESTADO1, ESTADO2, ESTADO3]
- **Relacionamentos:**
  - Referencia: [Outro Aggregate]
  - Contém: [Entities internas]

**Exemplo:**
```
### Order Management BC

#### Order (Aggregate Root)
- **Descrição:** Pedido do cliente com itens e status de processamento
- **Identidade:** OrderId (GUID)
- **Estados:** DRAFT, PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED
- **Relacionamentos:**
  - Referencia: Customer (CustomerId)
  - Contém: OrderItem (list)
```

#### [Aggregate Root 2]
[Mesmo formato acima]

---

### [Nome do BC 2]

[Repetir estrutura]

---

## 🔷 2. Value Objects Compartilhados

Lista de Value Objects usados em múltiplos BCs (compartilhados entre contextos).

| Value Object | Estrutura | Usado em BCs | Validações Principais |
|--------------|-----------|--------------|----------------------|
| **Money** | { amount: decimal, currency: string } | Order, Payment, Invoice | amount ≥ 0, currency em [USD, EUR, BRL] |
| **Address** | { street, city, zipCode, country } | Customer, Shipping | zipCode format, country ISO |
| **Email** | { value: string } | Customer, User | email format valid |
| **PhoneNumber** | { countryCode, number } | Customer | format E.164 |

**Exemplo preenchido:**
```markdown
| Money | { amount: decimal, currency: string } | Order, Payment | amount ≥ 0, currency em [USD, BRL] |
| Address | { street, city, zipCode, country } | Customer, Shipping | zipCode /^\d{5}-\d{3}$/ |
```

---

## 📣 3. Domain Events Principais

Lista de Domain Events importantes para integração entre BCs.

| Event | BC Origem | BCs Consumidores | Trigger | Payload |
|-------|-----------|------------------|---------|---------|
| **OrderCreated** | Order Management | Payment, Inventory, Shipping | Order.Confirm() | { OrderId, CustomerId, Total, Items[] } |
| **PaymentProcessed** | Payment | Order, Accounting | Payment.Process() | { PaymentId, OrderId, Amount } |
| **InventoryReserved** | Inventory | Order, Shipping | Inventory.Reserve() | { OrderId, Items[] } |

**Exemplo preenchido:**
```markdown
| OrderCreated | Order Management | Payment, Inventory | Order.Confirm() | { OrderId, CustomerId, Total } |
```

---

## 🔗 4. Integration Patterns entre BCs

Descrever padrões de integração usados entre Bounded Contexts.

| BC Origem | BC Destino | Pattern | Justificativa |
|-----------|------------|---------|---------------|
| **Order Management** | **Customer Management** | Anti-Corruption Layer (ACL) | Customer BC é legado, proteger Order BC |
| **Order Management** | **Inventory** | Shared Kernel | Value Objects compartilhados (ProductId) |
| **Order Management** | **Payment** | Published Language | Contract definido por Order BC |
| **Payment** | **Order** | Customer-Supplier | Payment segue especificações de Order |

**Padrões disponíveis (Context Map):**
- **Partnership:** Colaboração bidirecional
- **Shared Kernel:** Código compartilhado (Value Objects comuns)
- **Customer-Supplier:** Upstream define contrato
- **Conformist:** Downstream aceita modelo upstream
- **Anti-Corruption Layer (ACL):** Camada de tradução
- **Published Language:** Contrato público bem definido
- **Separate Ways:** Contextos independentes (sem integração)

---

## 🔐 5. Dados Sensíveis Identificados

Lista de aggregates/campos com dados sensíveis (para SEC Threat Modeling).

| Aggregate | Campos Sensíveis | Classificação | Proteção Necessária |
|-----------|------------------|---------------|---------------------|
| **Customer** | cpf, email, phoneNumber | PII (LGPD) | Encryption at rest + Access control |
| **Payment** | cardNumber, cvv | PCI-DSS | Tokenização + HSM |
| **User** | password, securityAnswer | Credentials | Hashing (bcrypt) + MFA |

**Classificações:**
- **PII (Personally Identifiable Information):** LGPD compliance
- **PCI-DSS:** Payment card data
- **PHI (Protected Health Information):** HIPAA (se aplicável)
- **Credentials:** Authentication data

---

## 📋 6. Decisões Arquiteturais de Domínio

Registrar decisões importantes sobre modelagem.

### Decisão 1: [Título]
- **Contexto:** [Por que surgiu a decisão]
- **Decisão:** [O que foi decidido]
- **Alternativas Consideradas:** [Outras opções]
- **Justificativa:** [Por que escolhemos esta]
- **Consequências:** [Impactos positivos/negativos]

**Exemplo:**
```markdown
### Decisão 1: Order como Aggregate Root único
- **Contexto:** Pedido contém múltiplos itens, endereço, pagamento
- **Decisão:** Order é o Aggregate Root, OrderItem é Entity interna
- **Alternativas:** OrderItem como Aggregate separado
- **Justificativa:** Invariante "Total = Sum(Items)" precisa transação atômica
- **Consequências:** ✅ Consistência garantida, ❌ Limite de ~100 items por pedido
```

---

## 📚 7. Referências

- **SDA-02-Context-Map.md:** Bounded Contexts e relacionamentos
- **SDA-03-Ubiquitous-Language.md:** Termos de negócio (português → inglês)
- **04-DDD-Patterns-Reference.md:** Padrões DDD para consulta

---

## ✅ 8. Próximas Ações

- [ ] **UXD:** Usar este modelo para criar User Flows genéricos
- [ ] **PE:** Usar Aggregates para dimensionar infraestrutura (carga estimada)
- [ ] **SEC:** Usar dados sensíveis para Threat Modeling (STRIDE)
- [ ] **DE (épico):** Detalhar modelo tático por épico (DE-01-[EpicName])

---

**Status:** [Draft | Review | Approved]
**Próxima Revisão:** Após Epic 1 (ajustar se novos Aggregates surgirem)
