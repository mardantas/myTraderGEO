# FEEDBACK-001-DE-SDA-Language-Sync.md

---

**Data Abertura:** 2025-10-24  
**Solicitante:** DE Agent (Domain Engineer)  
**Destinatário:** SDA Agent (Strategic Domain Analyst)  
**Status:** 🔴 Aberto  

**Tipo:**
- [x] Correção (deliverable já entregue precisa ajuste)
- [ ] Melhoria (sugestão de enhancement)
- [ ] Dúvida (esclarecimento necessário)
- [ ] Novo Requisito (mudança de escopo)

**Urgência:** 🔴 Alta  

**Deliverable(s) Afetado(s):**
- SDA-03-Ubiquitous-Language.md (principal)
- SDA-02-Context-Map.md (verificar relacionamentos)
- SDA-01-Event-Storming.md (verificar eventos novos)

---

## 📋 Descrição

Durante a implementação do modelo tático para EPIC-01 (Criação e Análise de Estratégias + Admin Management), foram identificadas **divergências significativas** entre o modelo de domínio implementado no DE-01 e a linguagem ubíqua documentada no SDA-03.

O documento DE-01-EPIC-01-CreateStrategy-Domain-Model.md implementou conceitos, termos e eventos que não existem no SDA-03, criando desalinhamento entre strategic design e tactical design.

**Total de mudanças necessárias:** ~40 novos termos + 5 termos atualizados + 2 termos removidos = **48 mudanças** distribuídas em 3 Bounded Contexts (Strategy Planning, Market Data, User Management).  

### Contexto

O trabalho de Domain Engineering para EPIC-01 foi concluído e incluiu:
- 7 aggregates, 10 child entities, 31 value objects documentados
- 50+ domain events
- 3 use cases completos (UC-Strategy-01, UC-MarketData-01, UC-MarketData-02)

Principais divergências identificadas:
1. **StrategyStatus** - PaperTrading é status (não modo de execução separado)
2. **Caracterização de Templates** - MarketView, Objective, RiskProfile, DefenseGuidelines (não existem no SDA-03)
3. **P&L Tracking** - PnLSnapshot, PnLType, histórico (não documentado)
4. **Opções Semanais** - OptionSeries W1-W5 (conceito ausente)
5. **Ajuste de Strike** - StrikeAdjustment por dividendos (não existe)
6. **Real-Time Streaming** - Eventos de subscrição, throttling (não documentado)
7. **Override de Planos** - UserPlanOverride, CustomFees, BillingPeriod (ausentes)

---

## 💥 Impacto Estimado

**Outros deliverables afetados:**
- [x] SDA-03-Ubiquitous-Language.md (principal - ALTO impacto)
- [ ] SDA-02-Context-Map.md (verificar se relacionamentos BC mudaram)
- [ ] SDA-01-Event-Storming.md (verificar se novos eventos afetam fluxos)

**Esforço estimado:** 1-2 dias de trabalho  

**Risco:** 🔴 Alto  

**Justificativa do risco:**
- Próximos épicos (EPIC-02 Trade Execution, EPIC-03 Risk Management) dependem dos termos corretos
- Código já implementado usa novos termos (StrategyStatus, PnLSnapshot, OptionSeries)
- Documentação desatualizada gera confusão no time de desenvolvimento
- Bloqueia progresso de outros agents (SE, DBA, FE) que precisam consultar linguagem ubíqua

---

## 💡 Proposta de Solução

### Resumo das Mudanças

#### Strategy Planning BC (23 mudanças)
**Novos termos:**
- StrategyStatus (enum: Draft, Validated, PaperTrading, Live, Closed)
- MarketView, StrategyObjective, StrategyRiskProfile (caracterização de templates)
- PriceRangeIdeal, DefenseGuidelines (orientações de uso)
- PnLSnapshot, PnLType, PnLHistory, CurrentPnL (tracking de P&L)
- LegQuantityAdjustment, LegAddition, LegRemoval, ClosingReason (manejo)
- Eventos: StrategyValidated, StrategyPaperTradingStarted, StrategyWentLive, StrategyPnLUpdated, PnLSnapshotCaptured, StrategyLegAdjusted, StrategyLegAddedToActive, StrategyLegRemoved, StrategyClosed

**Atualizar:**
- PaperTrading (de "modo" para "status")
- ProfitAndLoss → CurrentPnL

**Remover:**
- ExecutionMode (substituído por StrategyStatus)
- SimulatedPnL (não há distinção - mesmo cálculo)

#### Market Data BC (16 mudanças)
**Novos termos:**
- OptionSeries, WeekNumber, MonthlyStandard (opções semanais W1-W5)
- StrikeAdjustment, OriginalStrike, CurrentStrike, AdjustmentReason (ajuste de strike)
- MarketDataStreamService, RealTimePriceUpdate, SymbolSubscription, PriceThrottling, SignificantChange (streaming)
- Eventos: OptionStrikeAdjusted, MarketDataStreamStarted, MarketDataStreamStopped, RealTimePriceReceived, UserSubscribedToSymbol, UserUnsubscribedFromSymbol, OptionsDataSyncStarted, OptionsDataSyncCompleted, NewOptionContractsDiscovered

**Atualizar:**
- MarketFeed (de Value Object → Domain Service)

#### User Management BC (9 mudanças)
**Novos termos:**
- UserPlanOverride, BillingPeriod, TradingFees, CustomFees, PlanFeatures
- Eventos: PlanOverrideGranted, PlanOverrideRevoked, CustomFeesConfigured, CustomFeesRemoved

**Atualizar:**
- SubscriptionPlan (de Value Object → Aggregate Root)

### Ações Solicitadas

1. Atualizar SDA-03-Ubiquitous-Language.md com todos os termos listados
2. Organizar novos termos por Bounded Context correto
3. Identificar tipo DDD corretamente (Aggregate, Entity, VO, Event, Service)
4. Atualizar tabela "Evolução da Linguagem" com entrada de 2025-10-24
5. Atualizar contadores de termos por BC (total atual: 105 → novo total: ~145)
6. Verificar SDA-02-Context-Map.md (relacionamentos entre BCs)
7. Verificar SDA-01-Event-Storming.md (novos eventos em fluxos)

### Referências Detalhadas

Todas as definições, justificativas e referências de linhas estão documentadas em:
- `DE-01-EPIC-01-CreateStrategy-Domain-Model.md` (documento completo do modelo tático)

Principais seções:
- Aggregates: linhas 150-2670
- Value Objects: linhas 1464-1665, 2671-2755
- Domain Events: linhas 2756-2917
- Use Cases: linhas 3934-4989

---

## ✅ Resolução

> _Seção preenchida pelo agent destinatário após resolver_

**Data Resolução:** 2025-10-24  
**Resolvido por:** SDA Agent  

**Ação Tomada:**
Sincronização completa da Linguagem Ubíqua com modelo de domínio do DE-01-EPIC-01. Total de 48 mudanças distribuídas em 3 Bounded Contexts.

**Deliverables Atualizados:**
- [x] **SDA-03-Ubiquitous-Language.md** - Adicionados 48 termos novos/atualizados:
  - **Strategy Planning BC:** +20 termos (StrategyStatus, MarketView, StrategyObjective, StrategyRiskProfile, PriceRangeIdeal, DefenseGuidelines, PnLSnapshot, PnLType, CurrentPnL, PnLHistory, ClosingReason + 9 novos eventos)
  - **Strategy Planning BC:** Removidos 2 termos obsoletos (ExecutionMode, SimulatedPnL)
  - **Strategy Planning BC:** Atualizado 1 termo (ProfitAndLoss → CurrentPnL)
  - **Market Data BC:** +18 termos (OptionSeries, WeekNumber, MonthlyStandard, StrikeAdjustment, OriginalStrike, CurrentStrike, AdjustmentReason, MarketDataStreamService, conceitos de streaming + 9 eventos)
  - **Market Data BC:** Atualizado 1 termo (MarketFeed: Value Object → Domain Service)
  - **User Management BC:** +9 termos (UserPlanOverride, BillingPeriod, TradingFees, CustomFees, PlanFeatures + 4 eventos)
  - **User Management BC:** Atualizado 1 termo (SubscriptionPlan: Value Object → Aggregate Root)
  - Atualizada tabela "Evolução da Linguagem" com 25 entradas de 2025-10-24
  - Atualizada seção "Termos a Evitar" com 3 novos termos obsoletos
  - Atualizados contadores: 105 → 150 termos totais
- [x] **SDA-02-Context-Map.md** - Atualizadas entidades principais:
  - Trade Execution BC: Atualizada nota sobre StrategyStatus substituindo ExecutionMode
  - User Management BC: Adicionados UserPlanOverride, BillingPeriod, TradingFees, CustomFees
- [x] **SDA-01-Event-Storming.md** - Atualizados eventos do Processo Principal 3:
  - Atualizado fluxo de Execução e Monitoramento com StrategyStatus
  - Adicionados eventos: StrategyValidated, StrategyPnLUpdated, PnLSnapshotCaptured, StrategyLegAdjusted, StrategyLegAddedToActive, StrategyLegRemoved, StrategyClosed
  - Removida referência a "Modo Selecionado", substituído por StrategyStatus

**Referência Git Commit:** b963c75  

---

**Status Final:** 🟢 Resolvido  

---

## 📝 Histórico

| Data | Mudança | Autor |
|------|---------|-------|
| 2025-10-24 | Criado | DE Agent |
