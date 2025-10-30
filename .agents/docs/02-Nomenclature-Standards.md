# Padrões de Nomenclatura DDD

**Objetivo:** Definir convenções de nomenclatura consistentes para documentação e código em projetos DDD.

---

## 🎯 Princípio Fundamental

### Português para NEGÓCIO, Inglês para TÉCNICO

- **Documentação DDD:** Português brasileiro
- **Código fonte:** Inglês (padrão indústria)
- **Mapeamento:** Termos de negócio ↔ classes/namespaces

---

## 📋 Terminologia DDD

### Subdomínios (Subdomains)
**Divisões lógicas do domínio de negócio**

**Tipos:**
- **Core:** Funcionalidade central, diferencial competitivo
- **Supporting:** Suporte necessário ao core
- **Generic:** Funcionalidade comum (pode usar solução pronta)

**Nomenclatura:**
- Documentação: "Gestão de Estratégias" (português)
- Namespace: `StrategyManagement` (inglês)

---

### Bounded Contexts (Contextos Delimitados)
**Limites explícitos onde modelos de domínio se aplicam**

**Nomenclatura:**
```
Documentação: "Contexto de Gestão de Estratégias"
Namespace: StrategyManagement
Pasta: 02-backend/src/StrategyManagement/
```

**Exemplo genérico (e-commerce):**
| Bounded Context (PT) | Namespace (EN) | Tipo |
|----------------------|----------------|------|
| Gestão de Pedidos | OrderManagement | Core |
| Gestão de Estoque | InventoryManagement | Supporting |
| Gestão de Pagamentos | PaymentManagement | Supporting |
| Gestão de Clientes | CustomerManagement | Supporting |

---

## 🔤 Linguagem Ubíqua

### Template de Termos

| Termo Negócio (PT) | Código (EN) | Tipo DDD | Contexto |
|--------------------|-------------|----------|----------|
| Pedido | `Order` | Aggregate Root | Order Management |
| Item do Pedido | `OrderItem` | Entity | Order Management |
| Endereço de Entrega | `ShippingAddress` | Value Object | Order Management |
| Valor Monetário | `Money` | Value Object | Order Management |
| Produto | `Product` | Entity | Inventory Management |
| Pedido Criado | `OrderCreated` | Domain Event | Order Management |

### Diretrizes

**Boas Práticas:**
- ✅ Use português natural para stakeholders
- ✅ Seja específico ao contexto
- ✅ Mantenha consistência em todo projeto

**Evite:**
- ❌ Traduções literais forçadas
- ❌ Anglicismos desnecessários

---

## 📁 Nomenclatura de Arquivos

### Deliverables de Agentes

**Formato:** `[AGENTE]-[NN]-[Titulo-Descritivo].md`

**Exemplos:**
```
SDA-01-Event-Storming.md
SDA-02-Context-Map.md
UXD-01-User-Flows.md
DE-01-CreateOrder-Tactical-Model.md
DBA-01-CreateOrder-Schema-Review.md
QAE-01-Test-Strategy.md
GM-01-GitHub-Setup.md
```

---

### Feedbacks

**Formato:** `FEEDBACK-[NNN]-[FROM]-[TO]-[titulo-curto].md`

**Exemplos:**
```
FEEDBACK-001-DE-SDA-adicionar-evento-order-fulfilled.md
FEEDBACK-002-FE-UXD-corrigir-wireframe-dashboard.md
FEEDBACK-003-QAE-DBA-performance-query-orders.md
```

---

## 🏗️ Nomenclatura de Código

### Namespaces (C# / .NET)

**Estrutura:**
```
[ProjectName].OrderManagement.Domain
[ProjectName].OrderManagement.Application
[ProjectName].OrderManagement.Infrastructure
[ProjectName].PaymentManagement.Domain
```

**Padrão:** `[ProjectName].[BoundedContext].[Layer]`

---

### Classes DDD

**Aggregates:**
```csharp
public class Strategy { }  // Aggregate Root
public class StrategyLeg { }  // Entity dentro do aggregate
```

**Value Objects:**
```csharp
public record Greeks(decimal Delta, decimal Gamma, decimal Theta, decimal Vega);
public record StrikePrice(decimal Value, string Currency);
```

**Domain Events:**
```csharp
public record StrategyCreated(Guid StrategyId, DateTime CreatedAt);
public record StrategyAdjusted(Guid StrategyId, string Reason);
```

**Repositories:**
```csharp
public interface IStrategyRepository { }
public class StrategyRepository : IStrategyRepository { }
```

---

### Pastas de Código

**Backend:**
```
02-backend/
├── src/
│   ├── Domain/
│   │   ├── StrategyManagement/
│   │   │   ├── Aggregates/
│   │   │   ├── ValueObjects/
│   │   │   ├── DomainEvents/
│   │   │   └── Interfaces/
│   │   └── RiskManagement/
│   ├── Application/
│   │   ├── StrategyManagement/
│   │   │   ├── Commands/
│   │   │   ├── Queries/
│   │   │   └── UseCases/
│   └── Infrastructure/
│       ├── Persistence/
│       └── Integrations/
```

**Frontend:**
```
01-frontend/
├── src/
│   ├── components/
│   │   ├── strategy/
│   │   ├── risk/
│   │   └── shared/
│   ├── pages/
│   └── services/
```

---

## 📊 Nomenclatura de Épicos e Issues

### Épicos (GitHub)

**Formato:** `[EPIC-NN] Nome Descritivo da Funcionalidade`

**Exemplos:**
```
[EPIC-01] Criar e Visualizar Estratégia Bull Call Spread
[EPIC-02] Calcular Greeks e P&L em Tempo Real
[EPIC-03] Alertas de Risco Automáticos
```

**Características:**
- Nome em português (negócio)
- Descreve funcionalidade, não BC
- Transversal aos bounded contexts

---

### Issues (GitHub)

**Formato:** `[AGENTE-BC] Descrição da tarefa`

**Exemplos:**
```
[DE-Strategy] Implementar aggregate Strategy com validações
[FE-Dashboard] Criar componente de visualização de Greeks
[QAE-Integration] Testes de integração Strategy + Market Data
[DBA-Performance] Otimizar query de cálculo de Greeks
```

---

## 🔢 Numeração de Agentes

**Formato:** Múltiplos de 5 para permitir inserções futuras

```
10 - SDA (Strategic Domain Analyst)
15 - DE (Domain Engineer)
20 - UXD (User Experience Designer)
25 - GM (GitHub Manager)
30 - PE (Platform Engineer)
35 - SEC (Security Specialist)
45 - SE (Software Engineer)
50 - DBA (Database Administrator)
55 - FE (Frontend Engineer)
60 - QAE (Quality Assurance Engineer)
```

---

## 📂 Estrutura de Pastas de Documentação

```
00-doc-ddd/
├── 00-feedback/                    # Feedbacks entre agentes
├── 01-inputs-raw/                  # Requisitos originais
├── 02-strategic-design/            # SDA deliverables
├── 03-ux-design/                   # UXD deliverables
├── 04-tactical-design/             # DE deliverables
├── 05-database-design/             # DBA deliverables
├── 06-quality-assurance/           # QAE deliverables
└── 07-github-management/           # GM deliverables
```

**Numeração:** Múltiplos de 1, sequencial por fase do processo

---

## 🔧 Nomenclatura de Configuração

### .env Files (Environment Variables)

**Formato:** `.env.[environment]`

**Estratégia Multi-Ambiente:**
```bash
# Repository structure
05-infra/configs/
├── .env.example          # Template with placeholders
├── .env.dev             # Development (localhost) - committed with safe defaults
├── .env.staging         # Staging server - NOT committed (create on server)
└── .env.prod      # Prod server - NOT committed (create on server)
```

**Nomenclatura de Variáveis:**
```bash
# Domain configuration
DOMAIN=localhost                    # dev
DOMAIN=staging.myproject.com        # staging
DOMAIN=myproject.com                # prod

# Database credentials (per environment)
DB_APP_PASSWORD=dev_password_123    # dev (simple OK)
DB_APP_PASSWORD=St@g!ng_SecureP@ss  # staging (strong)
DB_APP_PASSWORD=Pr0d_VeryStr0ng!#$  # prod (very strong)

# Features flags
FEATURE_ANALYTICS_ENABLED=false     # dev/staging
FEATURE_ANALYTICS_ENABLED=true      # prod
```

**Uso em Comandos:**
```bash
# SEMPRE usar --env-file explícito
docker compose -f docker-compose.yml --env-file .env.dev up
docker compose -f docker-compose.staging.yml --env-file .env.staging up -d
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

**Segurança:**
- ✅ `.env.dev` commitado com valores seguros (localhost, senhas simples)
- ❌ `.env.staging` e `.env.prod` NUNCA commitados (secrets reais)
- ✅ `.env.example` commitado como template com placeholders

---

### Server Hostnames

**Formato:** `[project-name]-[environment]`

**Exemplos:**
```bash
# Development (local)
localhost

# Staging server
myproject-stage
staging.myproject.com

# Prod server
myproject-prod
myproject.com
www.myproject.com
```

**Configuração:**
```bash
# Set hostname on server
sudo hostnamectl set-hostname myproject-stage  # staging
sudo hostnamectl set-hostname myproject-prod   # prod
```

**Uso em Deploy Scripts:**
```bash
# deploy.sh pattern
if [ "$ENV" = "staging" ]; then
    SERVER_HOST="myproject-stage"
elif [ "$ENV" = "prod" ]; then
    SERVER_HOST="myproject-prod"
fi

ssh mytrader@$SERVER_HOST "docker compose up -d"
```

---

## ✅ Checklist de Nomenclatura

Antes de criar qualquer deliverable, verifique:

- [ ] Nome do arquivo segue padrão `[AGENTE]-[NN]-[Titulo].md`
- [ ] Termos de negócio em português na documentação
- [ ] Código em inglês seguindo convenções
- [ ] Mapeamento claro entre termos PT ↔ código EN
- [ ] Bounded Contexts nomeados consistentemente
- [ ] Épicos descrevem funcionalidade (não BC)
- [ ] Feedbacks seguem formato `FEEDBACK-[NNN]-[FROM]-[TO]-[titulo].md`
- [ ] .env files seguem padrão `.env.[environment]`
- [ ] Comandos docker-compose usam `--env-file` explícito
- [ ] Hostnames de servidores seguem padrão `[project]-[environment]`

---

## 📚 Exemplos Práticos

### Exemplo 1: Termo de Negócio → Código

**Linguagem Ubíqua:**
```
Termo: "Estratégia com Opções"
Definição: Combinação de posições em opções que formam uma estratégia
           de trading (ex: Bull Call Spread, Iron Condor)
```

**Código:**
```csharp
// Aggregate Root
public class Strategy
{
    public StrategyId Id { get; private set; }
    public string Name { get; private set; }
    public List<StrategyLeg> Legs { get; private set; }
    public Greeks Greeks { get; private set; }

    public void AddLeg(StrategyLeg leg) { }
    public void CalculateGreeks() { }
}
```

---

### Exemplo 2: Documentação → Namespace

**SDA-02-Context-Map.md:**
```markdown
## Bounded Contexts

### Contexto de Gestão de Pedidos
Responsabilidade: Criação, processamento e acompanhamento de pedidos
```

**Código:**
```
Namespace: [ProjectName].OrderManagement
Pasta: 02-backend/src/Domain/OrderManagement/
```

---

---

**Versão:** 1.0
**Data:** 2025-10-02
**Status:** Ativo
