# SDA-03-Ubiquitous-Language.md

**Projeto:** myTraderGEO
**Data:** 2025-10-06

---

## 📖 Glossário de Termos de Negócio

### Por Bounded Context

#### Strategy Planning (Core Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Estratégia** | `Strategy` | Combinação de posições em opções que formam uma operação completa de trading | Aggregate Root |
| **Perna** | `StrategyLeg` | Cada opção individual dentro de uma estratégia, definindo tipo, strike, vencimento e quantidade | Entity |
| **Ativo Subjacente** | `UnderlyingAsset` | Ativo base das opções (ex: PETR4, VALE3, IBOV) negociado na B3 | Value Object |
| **Strike** | `StrikePrice` | Preço de exercício de uma opção | Value Object |
| **Tipo de Opção** | `OptionType` | Call (compra) ou Put (venda) | Value Object (Enum) |
| **Posição** | `Position` | Long (comprado) ou Short (vendido) | Value Object (Enum) |
| **Vencimento** | `ExpirationDate` | Data de vencimento da opção | Value Object |
| **Margem** | `MarginRequirement` | Garantia exigida pela B3 para manter posições em opções | Value Object |
| **Gregas** | `Greeks` | Medidas de sensibilidade da opção: Delta, Gamma, Theta, Vega | Value Object |
| **Delta** | `Delta` | Sensibilidade do preço da opção em relação ao preço do ativo subjacente | Value Object |
| **Gamma** | `Gamma` | Taxa de variação do Delta | Value Object |
| **Theta** | `Theta` | Decaimento do valor da opção com o passar do tempo | Value Object |
| **Vega** | `Vega` | Sensibilidade do preço da opção à volatilidade implícita | Value Object |
| **Breakeven** | `BreakEvenPoint` | Ponto de equilíbrio onde lucro/prejuízo é zero | Value Object |
| **Rentabilidade** | `Profitability` | Análise de lucro máximo, prejuízo máximo e cenários intermediários | Value Object |
| **Template de Estratégia** | `StrategyTemplate` | Modelo/template reutilizável SEM ativo subjacente definido (global do sistema ou pessoal do trader) | Entity |
| **Catálogo de Estratégias** | `StrategyCatalog` | Catálogo unificado com templates globais (sistema) + templates pessoais do trader | Aggregate Root |
| **Visibilidade** | `TemplateVisibility` | Indica se template é global (sistema) ou pessoal (trader) | Value Object (Enum) |
| **Estratégia** | `Strategy` | Operação específica COM ativo subjacente definido, pronta para executar | Aggregate Root |
| **Sandbox** | `SandboxMode` | Ambiente de simulação para validar estratégias sem execução real | Value Object (Enum) |
| **Template Selecionado** | `TemplateSelected` | Evento emitido quando trader escolhe template como base (para criar template ou estratégia) | Domain Event |
| **Template Criado** | `TemplateCreated` | Evento emitido quando novo template é criado (baseado em outro ou do zero) | Domain Event |
| **Template Salvo no Catálogo** | `TemplateSavedToCatalog` | Evento emitido quando template é salvo no catálogo pessoal | Domain Event |
| **Estratégia Criada** | `StrategyCreated` | Evento emitido quando nova estratégia (com ativo subjacente) é criada | Domain Event |
| **Cálculos Executados** | `CalculationsCompleted` | Evento emitido após cálculo de margem, rentabilidade e gregas | Domain Event |

---

#### Trade Execution (Core Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Estratégia Ativa** | `ActiveStrategy` | Estratégia em execução real no mercado | Aggregate Root |
| **Ordem** | `Order` | Instrução de compra ou venda de uma opção | Entity |
| **P&L** | `ProfitAndLoss` | Lucro e prejuízo atual da estratégia | Value Object |
| **Performance** | `StrategyPerformance` | Análise de desempenho incluindo P&L, rentabilidade percentual e gregas atuais | Value Object |
| **Ajuste** | `Adjustment` | Modificação em estratégia ativa (rolagem, hedge, rebalanceamento) | Entity |
| **Rolagem** | `RollOver` | Substituir opções vencendo por opções de vencimento futuro | Value Object |
| **Hedge** | `Hedge` | Proteção contra movimentos adversos de mercado | Value Object |
| **Rebalanceamento** | `Rebalancing` | Ajuste de quantidades ou strikes para manter perfil de risco | Value Object |
| **Preço de Entrada** | `EntryPrice` | Preço pelo qual a opção foi adquirida | Value Object |
| **Histórico de Ajustes** | `AdjustmentHistory` | Registro completo de todas as modificações em uma estratégia | Entity |
| **Estratégia Ativada** | `StrategyActivated` | Evento emitido quando estratégia move de sandbox para real | Domain Event |
| **Posição Aberta** | `PositionOpened` | Evento emitido quando ordem é executada com sucesso | Domain Event |
| **Ajuste Executado** | `AdjustmentExecuted` | Evento emitido quando ajuste é concluído | Domain Event |
| **Posição Atualizada** | `PositionUpdated` | Evento emitido após atualização de posição | Domain Event |

---

#### Risk Management (Core Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Perfil de Risco** | `RiskProfile` | Classificação do usuário: Conservador, Moderado, Agressivo | Value Object (Enum) |
| **Limite Operacional** | `OperationalLimit` | Restrições máximas de exposição, risco e número de estratégias | Value Object |
| **Exposição Máxima** | `MaxExposure` | Valor máximo que pode ser alocado em estratégias | Value Object |
| **Risco Máximo** | `MaxRisk` | Prejuízo máximo tolerado por operação | Value Object |
| **Score de Risco** | `RiskScore` | Classificação numérica do risco de uma estratégia | Value Object |
| **Conflito** | `Conflict` | Situação onde múltiplas estratégias podem gerar resultados indesejados | Entity |
| **Tipo de Conflito** | `ConflictType` | Classificação do conflito (direções opostas, over-exposure, etc) | Value Object (Enum) |
| **Alerta** | `Alert` | Notificação de evento crítico (margem, vencimento, conflito) | Entity |
| **Severidade** | `Severity` | Criticidade do alerta: Baixa, Média, Alta, Crítica | Value Object (Enum) |
| **Chamada de Margem** | `MarginCall` | Alerta de margem insuficiente | Value Object |
| **Conflito Detectado** | `ConflictDetected` | Evento emitido quando sistema identifica conflito entre estratégias | Domain Event |
| **Alerta Disparado** | `AlertTriggered` | Evento emitido quando condição de alerta é atendida | Domain Event |
| **Risco Avaliado** | `RiskAssessed` | Evento emitido após cálculo de risco de estratégia | Domain Event |

---

#### Market Data (Supporting Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Preço de Opção** | `OptionPrice` | Cotação de uma opção (bid, ask, last) | Value Object |
| **Bid** | `BidPrice` | Preço de compra (quem quer comprar paga) | Value Object |
| **Ask** | `AskPrice` | Preço de venda (quem quer vender recebe) | Value Object |
| **Last** | `LastPrice` | Último preço negociado | Value Object |
| **Volatilidade Implícita** | `ImpliedVolatility` | Expectativa de volatilidade futura embutida no preço da opção | Value Object |
| **Dados de Mercado** | `MarketData` | Conjunto de preços, volatilidade e timestamps | Aggregate Root |
| **Feed de Mercado** | `MarketFeed` | Stream de dados em tempo real | Value Object |
| **Timestamp** | `MarketTimestamp` | Data/hora de atualização dos dados | Value Object |
| **Dados Sincronizados** | `MarketDataSynchronized` | Evento emitido quando dados de mercado são atualizados | Domain Event |

---

#### Asset Management (Supporting Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Carteira de Ativos** | `AssetPortfolio` | Conjunto de ativos físicos do trader na B3 (ações, índices, saldo) | Aggregate Root |
| **Carteira de Opções** | `OptionPortfolio` | Conjunto de posições em opções ativas do trader | Aggregate Root |
| **Ativo** | `Asset` | Ação ou índice na carteira (PETR4, VALE3, IBOV) | Entity |
| **Posição em Opção** | `OptionPosition` | Posição ativa em uma opção específica | Entity |
| **Ticker** | `Ticker` | Código do ativo na B3 | Value Object |
| **Quantidade** | `Quantity` | Quantidade de ativos ou contratos detidos | Value Object |
| **Garantia** | `Collateral` | Ativos utilizados como garantia para margem de opções | Value Object |
| **Custo Médio** | `AverageCost` | Preço médio ponderado de aquisição de ativos | Value Object |
| **Aporte** | `Deposit` | Entrada de capital na conta | Entity |
| **Retirada** | `Withdrawal` | Saída de capital da conta | Entity |
| **Saldo Disponível** | `AvailableBalance` | Capital disponível para novas operações | Value Object |
| **Garantias Aceitas** | `AcceptedCollateral` | Ativos válidos como garantia conforme regras B3 | Value Object |
| **Carteira de Ativos Sincronizada** | `AssetPortfolioSynchronized` | Evento emitido quando carteira de ativos B3 é atualizada | Domain Event |
| **Carteira de Opções Atualizada** | `OptionPortfolioUpdated` | Evento emitido quando carteira de opções é atualizada | Domain Event |
| **Garantias Atualizadas** | `CollateralUpdated` | Evento emitido quando garantias são recalculadas | Domain Event |
| **Movimentação Registrada** | `TransactionRecorded` | Evento emitido quando aporte/retirada é registrado | Domain Event |

---

#### User Management (Generic Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Usuário** | `User` | Pessoa registrada na plataforma com role e plano de assinatura | Aggregate Root |
| **Role** | `Role` | Papel do usuário no sistema: Trader (opera estratégias) ou Administrator (gestão do sistema) | Value Object (Enum) |
| **Plano de Assinatura** | `SubscriptionPlan` | Nível de assinatura do trader: Básico, Pleno, Consultor | Value Object (Enum) |
| **Perfil de Risco** | `RiskProfile` | Classificação do trader: Conservador, Moderado, Agressivo | Value Object (Enum) |
| **Email** | `Email` | Endereço de email único do usuário | Value Object |
| **Senha** | `Password` | Credencial de autenticação (hashed) | Value Object |
| **Perfil do Usuário** | `UserProfile` | Dados do usuário (nome, role, perfil de risco, plano de assinatura) | Entity |
| **Permissões** | `Permissions` | Autorização de acesso baseada em role e plano de assinatura | Value Object |
| **Usuário Cadastrado** | `UserRegistered` | Evento emitido quando novo usuário completa registro | Domain Event |
| **Role Atribuído** | `RoleAssigned` | Evento emitido quando role é atribuído ao usuário | Domain Event |
| **Plano de Assinatura Atualizado** | `SubscriptionPlanUpdated` | Evento emitido quando trader muda de plano | Domain Event |
| **Perfil de Risco Definido** | `RiskProfileDefined` | Evento emitido quando trader define seu perfil de risco | Domain Event |

---

#### Community & Sharing (Supporting Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Chat** | `Chat` | Conversa entre usuários da plataforma | Aggregate Root |
| **Mensagem** | `Message` | Texto enviado no chat | Entity |
| **Sala** | `ChatRoom` | Canal de comunicação | Entity |
| **Compartilhamento** | `Share` | Ação de tornar estratégia pública ou exportar | Entity |
| **Visibilidade** | `Visibility` | Pública (comunidade) ou Privada (apenas criador) | Value Object (Enum) |
| **Rede Social** | `SocialNetwork` | Plataforma externa (Telegram, Twitter) | Value Object (Enum) |
| **Mensagem Enviada** | `MessageSent` | Evento emitido quando mensagem é enviada | Domain Event |
| **Estratégia Compartilhada** | `StrategyShared` | Evento emitido quando estratégia é publicada | Domain Event |

---

#### Consultant Services (Supporting Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Consultor** | `Consultant` | Usuário com plano Consultor que gerencia carteira de clientes | Aggregate Root |
| **Cliente** | `Client` | Usuário gerenciado por consultor | Entity |
| **Carteira de Clientes** | `ClientPortfolio` | Conjunto de clientes de um consultor | Entity |
| **Atribuição** | `StrategyAssignment` | Estratégia compartilhada com cliente específico | Entity |
| **Permissão de Compartilhamento** | `SharingPermission` | Nível de acesso: View (visualizar) ou Copy (copiar) | Value Object (Enum) |
| **Cliente Adicionado** | `ClientAdded` | Evento emitido quando consultor adiciona cliente | Domain Event |
| **Estratégia Atribuída** | `StrategyAssigned` | Evento emitido quando consultor compartilha estratégia com cliente | Domain Event |

---

#### Analytics & AI (Generic Domain - Futuro)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Backtesting** | `Backtest` | Teste de estratégia com dados históricos | Aggregate Root |
| **Dados Históricos** | `HistoricalData` | Séries temporais de preços e volatilidade | Entity |
| **Resultado de Backtest** | `BacktestResult` | Métricas de performance histórica | Entity |
| **Sharpe Ratio** | `SharpeRatio` | Métrica de retorno ajustado ao risco | Value Object |
| **Max Drawdown** | `MaxDrawdown` | Maior perda acumulada em período | Value Object |
| **Win Rate** | `WinRate` | Percentual de trades vencedores | Value Object |
| **Sugestão de IA** | `AISuggestion` | Recomendação automática de ajuste ou nova estratégia | Entity |
| **Confiança** | `Confidence` | Nível de confiança da sugestão (0-100%) | Value Object |
| **Backtesting Solicitado** | `BacktestRequested` | Evento emitido quando usuário inicia backtest | Domain Event |
| **Sugestão Criada** | `SuggestionCreated` | Evento emitido quando IA gera recomendação | Domain Event |

---

## 🔄 Termos Compartilhados (Cross-Context)

| Termo (PT) | Código (EN) | Definição | Contextos |
|------------|-------------|-----------|-----------|
| **Valor Monetário** | `Money` | Valor com moeda (ex: 1500.50 BRL) | Todos os contextos |
| **ID de Usuário** | `UserId` | Identificador único de usuário | User Management, Strategy Planning, Trade Execution, Risk Management, Asset Management |
| **ID de Estratégia** | `StrategyId` | Identificador único de estratégia | Strategy Planning, Trade Execution, Risk Management, Community & Sharing, Consultant Services |
| **Símbolo de Opção** | `OptionSymbol` | Código da opção na B3 (ex: PETRH240) | Strategy Planning, Trade Execution, Market Data |
| **Data/Hora** | `Timestamp` | Momento temporal com timezone | Todos os contextos |

---

## ❌ Termos a Evitar

| ❌ Evitar | ✅ Usar | Razão |
|-----------|---------|-------|
| **Trade** | **Estratégia** ou **Operação** | "Trade" é termo genérico demais, "estratégia" é mais preciso no contexto de opções |
| **Posicão** (typo) | **Posição** | Erro ortográfico comum |
| **Greeks** (em português) | **Gregas** | Manter termo em português na documentação |
| **Option** (sem contexto) | **Opção** ou **Perna** | Especificar se é opção isolada ou parte de estratégia |
| **Configuração** | **Limite Operacional** ou **Perfil de Risco** | Ser específico ao contexto |
| **Ação** | **Ativo Subjacente** | "Ação" é apenas um tipo de ativo subjacente (pode ser índice) |
| **Plano** (genérico) | **Plano de Assinatura** | Distinguir de outros tipos de plano |
| **Premium** | **Pleno** | Consistência terminológica em português |
| **Usuário** em contexto técnico | **User** | Código em inglês |
| **User** em documentação | **Usuário** ou **Trader** | Documentação em português, especificar role quando relevante |

---

## 📊 Mapeamento Bounded Context → Namespace

| Bounded Context (PT) | Namespace (EN) | Pasta Backend |
|----------------------|----------------|---------------|
| **Gestão de Estratégias** | `StrategyPlanning` | `02-backend/src/Domain/StrategyPlanning/` |
| **Execução de Operações** | `TradeExecution` | `02-backend/src/Domain/TradeExecution/` |
| **Gestão de Risco** | `RiskManagement` | `02-backend/src/Domain/RiskManagement/` |
| **Dados de Mercado** | `MarketData` | `02-backend/src/Domain/MarketData/` |
| **Gestão de Ativos** | `AssetManagement` | `02-backend/src/Domain/AssetManagement/` |
| **Gestão de Usuários** | `UserManagement` | `02-backend/src/Domain/UserManagement/` |
| **Comunidade** | `CommunitySharing` | `02-backend/src/Domain/CommunitySharing/` |
| **Serviços de Consultoria** | `ConsultantServices` | `02-backend/src/Domain/ConsultantServices/` |
| **Análise Avançada** | `AnalyticsAI` | `02-backend/src/Domain/AnalyticsAI/` |

---

## 🎯 Exemplos de Código vs Documentação

### Exemplo 1: Aggregate Root

**Documentação (PT):**
```markdown
**Estratégia**: Combinação de posições em opções que formam uma operação completa
```

**Código (EN):**
```csharp
namespace MyTraderGEO.StrategyPlanning.Domain.Aggregates
{
    public class Strategy
    {
        public StrategyId Id { get; private set; }
        public string Name { get; private set; }
        public UnderlyingAsset UnderlyingAsset { get; private set; }
        public List<StrategyLeg> Legs { get; private set; }
        public Greeks Greeks { get; private set; }
        public MarginRequirement Margin { get; private set; }

        public void AddLeg(StrategyLeg leg) { }
        public void CalculateGreeks(MarketData marketData) { }
        public void CalculateMargin() { }
    }
}
```

---

### Exemplo 2: Value Object

**Documentação (PT):**
```markdown
**Gregas**: Medidas de sensibilidade da opção (Delta, Gamma, Theta, Vega)
```

**Código (EN):**
```csharp
namespace MyTraderGEO.StrategyPlanning.Domain.ValueObjects
{
    public record Greeks(
        decimal Delta,
        decimal Gamma,
        decimal Theta,
        decimal Vega
    );
}
```

---

### Exemplo 3: Domain Event

**Documentação (PT):**
```markdown
**Estratégia Criada**: Evento emitido quando nova estratégia é criada
```

**Código (EN):**
```csharp
namespace MyTraderGEO.StrategyPlanning.Domain.Events
{
    public record StrategyCreated(
        StrategyId StrategyId,
        UserId CreatedBy,
        DateTime CreatedAt
    ) : DomainEvent;
}
```

---

### Exemplo 4: Repository Interface

**Documentação (PT):**
```markdown
**Repositório de Estratégias**: Persistência e recuperação de estratégias
```

**Código (EN):**
```csharp
namespace MyTraderGEO.StrategyPlanning.Domain.Interfaces
{
    public interface IStrategyRepository
    {
        Task<Strategy> GetByIdAsync(StrategyId id);
        Task<List<Strategy>> GetByUserIdAsync(UserId userId);
        Task SaveAsync(Strategy strategy);
        Task DeleteAsync(StrategyId id);
    }
}
```

---

## 📝 Evolução da Linguagem

| Data | Termo | Mudança | Motivo |
|------|-------|---------|--------|
| 2025-10-06 | Todos os termos | Adicionado | Criação inicial da linguagem ubíqua |
| 2025-10-06 | Gregas | Definido como Value Object | Padrão DDD para conjunto de valores imutáveis |
| 2025-10-06 | Estratégia | Definido como Aggregate Root | Entidade principal do domínio Strategy Planning |
| 2025-10-06 | Perna | Definido como Entity | Parte da estratégia, tem identidade própria |
| 2025-10-06 | Portfolio Management → Asset Management | Renomeado BC | Clareza: "Carteira de Ativos" em PT é mais preciso que "Portfolio" |
| 2025-10-06 | Catálogo de Estratégias | Redefinido como único | Catálogo unificado: templates globais (sistema) + templates pessoais (trader) com controle de visibilidade |
| 2025-10-06 | Carteira de Estratégias | Removido | Conceito substituído por Catálogo unificado com visibilidade |
| 2025-10-06 | Carteira de Opções | Adicionado | Posições em opções ativas, gerenciada por Asset Management |
| 2025-10-06 | Template vs Estratégia | Clarificado | Template = modelo SEM ativo subjacente; Estratégia = operação COM ativo subjacente |
| 2025-10-06 | Processos renumerados | Reorganizado | P1=Criar Template, P2=Criar Estratégia, P3=Executar, P4=Risco, P5=Comunidade |
| 2025-10-06 | Template Criado | Adicionado evento | Novo processo (P1) para criar templates do zero ou baseados em outros |
| 2025-10-07 | Role | Adicionado | Distinção clara entre Role (Trader, Administrator) e Plano de Assinatura (Básico, Pleno, Consultor) |
| 2025-10-07 | Plano → Plano de Assinatura | Renomeado | Termo mais específico para evitar ambiguidade |
| 2025-10-07 | Administrator | Adicionado role | Role para gestão do sistema, usuários e moderação de conteúdo |
| 2025-10-07 | Perfil de Risco | Explicitado | Separado como entidade distinta (Conservador, Moderado, Agressivo) |
| 2025-10-07 | Premium → Pleno | Renomeado | Consistência terminológica em português |

---

## 📚 Diretrizes de Uso

### Para Desenvolvedores (DE, FE, DBA)

✅ **Use código em inglês sempre**
✅ **Consulte este glossário para mapear termos de negócio → classes**
✅ **Mantenha consistência de nomenclatura por Bounded Context**
✅ **Use namespaces conforme tabela de mapeamento**

### Para Documentação (SDA, UXD, QAE)

✅ **Use termos em português**
✅ **Seja específico ao contexto (BC)**
✅ **Atualize glossário quando surgirem novos termos**
✅ **Evite anglicismos desnecessários**

### Para Comunicação com Stakeholders

✅ **Sempre use termos em português**
✅ **Explique termos técnicos quando necessário**
✅ **Mantenha linguagem alinhada com este glossário**

---

## ✅ Validação da Linguagem Ubíqua

### Critérios de Qualidade

- [x] ≥20 termos documentados (85 termos no total)
- [x] Mapeamento PT → EN completo
- [x] Termos organizados por Bounded Context
- [x] Tipos DDD identificados (Aggregate, Entity, VO, Event)
- [x] Exemplos de código fornecidos
- [x] Termos a evitar documentados
- [x] Mapeamento de namespaces completo

### Cobertura por Bounded Context

- [x] Strategy Planning (21 termos - incluindo Template vs Estratégia, Catálogo com visibilidade)
- [x] Trade Execution (14 termos)
- [x] Risk Management (13 termos)
- [x] Market Data (8 termos)
- [x] Asset Management (15 termos - incluindo Carteira de Ativos e Opções)
- [x] User Management (7 termos)
- [x] Community & Sharing (7 termos)
- [x] Consultant Services (6 termos)
- [x] Analytics & AI (10 termos)

**Total:** 101 termos + 4 termos compartilhados = **105 termos**

---

**Status:** Completo e pronto para uso
**Próxima revisão:** Após feedback de UXD e DE
