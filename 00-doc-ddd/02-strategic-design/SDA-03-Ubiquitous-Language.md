# SDA-03-Ubiquitous-Language.md

**Projeto:** myTraderGEO  
**Data:** 2025-10-12  
**Versão:** 1.0  

---

## 📖 Glossário de Termos de Negócio

### Por Bounded Context

#### Strategy Planning (Core Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Estratégia** | `Strategy` | Combinação de posições em opções, ações ou ambos que formam uma operação completa de trading | Aggregate Root |
| **Perna** | `StrategyLeg` | Cada instrumento individual (ação ou opção) dentro de uma estratégia | Entity |
| **Tipo de Perna** | `LegType` | Tipo de instrumento: Stock (ação), CallOption, PutOption | Value Object (Enum) |
| **Perna de Ação** | `StockLeg` | Perna contendo ação (apenas posição e quantidade, sem strike ou vencimento) | Entity |
| **Perna de Opção** | `OptionLeg` | Perna contendo opção (tipo call/put, strike, vencimento, quantidade) | Entity |
| **Estratégia Mista** | `MixedStrategy` | Estratégia que combina ações e opções (ex: covered call = ação long + call short) | Aggregate Root |
| **Ativo Subjacente** | `UnderlyingAsset` | Ativo base (ex: PETR4, VALE3, IBOV) negociado na B3 | Value Object |
| **Strike** | `StrikePrice` | Preço de exercício de uma opção (não aplicável para ações) | Value Object |
| **Tipo de Opção** | `OptionType` | Call (compra) ou Put (venda) | Value Object (Enum) |
| **Posição** | `Position` | Long (comprado) ou Short (vendido) - aplica-se a ações e opções | Value Object (Enum) |
| **Vencimento** | `ExpirationDate` | Data de vencimento da opção (não aplicável para ações) | Value Object |
| **Margem** | `MarginRequirement` | Garantia exigida pela B3 para manter posições (opções, ações em margem, venda descoberta) | Value Object |
| **Gregas** | `Greeks` | Medidas de sensibilidade da opção: Delta, Gamma, Theta, Vega (não aplicável para ações puras) | Value Object |
| **Delta** | `Delta` | Sensibilidade do preço da opção em relação ao preço do ativo subjacente (para ações: sempre 1.0 long ou -1.0 short) | Value Object |
| **Gamma** | `Gamma` | Taxa de variação do Delta (zero para ações) | Value Object |
| **Theta** | `Theta` | Decaimento do valor da opção com o passar do tempo (zero para ações) | Value Object |
| **Vega** | `Vega` | Sensibilidade do preço da opção à volatilidade implícita (zero para ações) | Value Object |
| **Breakeven** | `BreakEvenPoint` | Ponto de equilíbrio onde lucro/prejuízo é zero (aplica-se a ações e opções) | Value Object |
| **Rentabilidade** | `Profitability` | Análise de lucro máximo, prejuízo máximo e cenários intermediários (linear para ações, não-linear para opções) | Value Object |
| **Template de Estratégia** | `StrategyTemplate` | Define estrutura/topologia da estratégia com referências relativas (não valores absolutos). Contém pernas com strikes relativos, vencimentos relativos, quantidades e posições | Entity |
| **Perna de Template** | `TemplateLeg` | Perna do template com referências relativas: tipo instrumento, posição (long/short), quantidade (+1/-2), strike relativo (se opção), vencimento relativo (se opção) | Entity |
| **Strike Relativo** | `RelativeStrike` | Referência relativa de strike: ATM (at-the-money), ATM+X%, ATM-X%, "X strikes acima/abaixo", "strike baixo/médio/alto" | Value Object |
| **Vencimento Relativo** | `RelativeExpiration` | Referência relativa de vencimento: "janeiro próximo", "fevereiro próximo", "+1 mês", "+6 meses", "opção longa (>6m)", "opção curta (<2m)" | Value Object |
| **Instanciação de Template** | `TemplateInstantiation` | Processo de transformar template (referências relativas) em estratégia real (valores absolutos) aplicando ativo subjacente específico | Domain Service |
| **Catálogo de Estratégias** | `StrategyCatalog` | Catálogo unificado com templates globais (sistema) + templates pessoais do trader | Aggregate Root |
| **Visibilidade** | `TemplateVisibility` | Indica se template é global (sistema) ou pessoal (trader) | Value Object (Enum) |
| **Estratégia** | `Strategy` | Operação específica instanciada COM ativo subjacente definido, strikes absolutos (R$), datas específicas, pronta para executar | Aggregate Root |
| **Sandbox** | `SandboxMode` | Ambiente de simulação para validar estratégias sem execução real | Value Object (Enum) |
| **Template Selecionado** | `TemplateSelected` | Evento emitido quando trader escolhe template como base (para criar template ou estratégia) | Domain Event |
| **Template Criado** | `TemplateCreated` | Evento emitido quando novo template é criado (baseado em outro ou do zero) | Domain Event |
| **Template Salvo no Catálogo** | `TemplateSavedToCatalog` | Evento emitido quando template é salvo no catálogo pessoal | Domain Event |
| **Estratégia Criada** | `StrategyCreated` | Evento emitido quando nova estratégia (com ativo subjacente e valores absolutos) é criada por instanciação de template ou do zero | Domain Event |
| **Template Instanciado** | `TemplateInstantiated` | Evento emitido quando template é transformado em estratégia real (referências relativas → valores absolutos) | Domain Event |
| **Cálculos Executados** | `CalculationsCompleted` | Evento emitido após cálculo de margem, rentabilidade e gregas | Domain Event |
| **Status da Estratégia** | `StrategyStatus` | Estado do ciclo de vida: Draft (rascunho), Validated (validada), PaperTrading (simulação), Live (ativo com capital), Closed (encerrada) | Value Object (Enum) |
| **Visão de Mercado** | `MarketView` | Expectativa de direção do mercado: Bullish (alta), Bearish (baixa), Neutral (lateral), Volatile (volátil) | Value Object (Enum) |
| **Objetivo da Estratégia** | `StrategyObjective` | Propósito principal: Income (renda), Protection (proteção), Speculation (especulação), Hedge | Value Object (Enum) |
| **Perfil de Risco da Estratégia** | `StrategyRiskProfile` | Nível de risco: Conservative (baixo), Moderate (médio), Aggressive (alto) | Value Object (Enum) |
| **Faixa de Preço Ideal** | `PriceRangeIdeal` | Faixa recomendada de preço do ativo subjacente para aplicar a estratégia | Value Object |
| **Orientações de Defesa** | `DefenseGuidelines` | Recomendações de ajuste quando mercado se move contra expectativa (alta/baixa/volatilidade) | Value Object |
| **Snapshot de P&L** | `PnLSnapshot` | Registro imutável de lucro/prejuízo em momento específico (histórico) | Entity |
| **Tipo de Snapshot P&L** | `PnLType` | Categoria do snapshot: Daily (diário automático), OnDemand (manual), Weekly (semanal), Monthly (mensal), Closing (encerramento) | Value Object (Enum) |
| **P&L Atual** | `CurrentPnL` | Lucro ou prejuízo não realizado da estratégia ativa | Value Object |
| **Histórico de P&L** | `PnLHistory` | Coleção de snapshots de P&L ao longo do tempo | Collection (Entity) |
| **Motivo de Encerramento** | `ClosingReason` | Justificativa para fechamento da estratégia (obrigatório ao encerrar) | Value Object |
| **Estratégia Validada** | `StrategyValidated` | Evento emitido quando estratégia é validada e está pronta para ativação | Domain Event |
| **Paper Trading Iniciado** | `StrategyPaperTradingStarted` | Evento emitido quando estratégia entra em modo de simulação | Domain Event |
| **Estratégia Ativada (Live)** | `StrategyWentLive` | Evento emitido quando estratégia é ativada com capital real | Domain Event |
| **P&L Atualizado** | `StrategyPnLUpdated` | Evento emitido quando P&L atual da estratégia é recalculado | Domain Event |
| **Snapshot P&L Capturado** | `PnLSnapshotCaptured` | Evento emitido quando snapshot de P&L é registrado no histórico | Domain Event |
| **Perna Ajustada** | `StrategyLegAdjusted` | Evento emitido quando quantidade de uma perna é alterada (manejo) | Domain Event |
| **Perna Adicionada** | `StrategyLegAddedToActive` | Evento emitido quando nova perna é adicionada a estratégia ativa (manejo) | Domain Event |
| **Perna Removida** | `StrategyLegRemoved` | Evento emitido quando perna é removida de estratégia ativa (manejo) | Domain Event |
| **Estratégia Encerrada** | `StrategyClosed` | Evento emitido quando estratégia é fechada (com P&L final e motivo) | Domain Event |

---

#### Trade Execution (Core Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Estratégia Ativa** | `ActiveStrategy` | Estratégia ativada para execução (real) ou acompanhamento (paper trading) | Aggregate Root |
| **Paper Trading** | `PaperTrading` | Status de acompanhamento hipotético com dados reais mas sem execução efetiva (é um status, não modo) | Value Object (Status) |
| **Posição Simulada** | `PaperPosition` | Posição hipotética em paper trading com preços de entrada do momento da ativação | Entity |
| **Posição Real** | `RealPosition` | Posição efetivamente executada no mercado | Entity |
| **Ordem** | `Order` | Instrução de compra ou venda de uma opção (apenas real) | Entity |
| **Performance** | `StrategyPerformance` | Análise de desempenho incluindo P&L, rentabilidade percentual e gregas atuais (real ou simulado) | Value Object |
| **Ajuste** | `Adjustment` | Modificação em estratégia ativa (rolagem, hedge, rebalanceamento, encerramento parcial, encerramento total) | Entity |
| **Rolagem** | `RollOver` | Substituir opções vencendo por opções de vencimento futuro | Value Object |
| **Hedge** | `Hedge` | Proteção contra movimentos adversos de mercado | Value Object |
| **Rebalanceamento** | `Rebalancing` | Ajuste de quantidades ou strikes para manter perfil de risco | Value Object |
| **Encerramento Parcial** | `PartialClosure` | Fechamento de parte das pernas da estratégia | Value Object |
| **Encerramento Total** | `FullClosure` | Fechamento completo de todas as pernas da estratégia | Value Object |
| **P&L Realizado** | `RealizedPnL` | Lucro ou prejuízo efetivamente realizado após encerramento | Value Object |
| **Preço de Entrada** | `EntryPrice` | Preço pelo qual a opção foi adquirida (real) ou preço de mercado no momento da ativação (paper) | Value Object |
| **Histórico de Ajustes** | `AdjustmentHistory` | Registro completo de todas as modificações em uma estratégia (real ou paper) | Entity |
| **Histórico Paper** | `PaperHistory` | Histórico completo de performance em paper trading (preservado após promoção para real) | Entity |
| **Estratégia Ativada** | `StrategyActivated` | Evento emitido quando estratégia é ativada (paper ou real) | Domain Event |
| **Estratégia Ativada como Paper** | `StrategyActivatedAsPaper` | Evento emitido quando estratégia é ativada em modo paper trading | Domain Event |
| **Estratégia Ativada como Real** | `StrategyActivatedAsReal` | Evento emitido quando estratégia é ativada em modo real | Domain Event |
| **Estratégia Promovida para Real** | `StrategyPromotedToReal` | Evento emitido quando estratégia é promovida de paper para real | Domain Event |
| **Posição Aberta** | `PositionOpened` | Evento emitido quando ordem real é executada com sucesso | Domain Event |
| **Ajuste Executado** | `AdjustmentExecuted` | Evento emitido quando ajuste é concluído (real ou simulado) | Domain Event |
| **Posição Atualizada** | `PositionUpdated` | Evento emitido após atualização de posição (real ou simulada) | Domain Event |

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
| **Feed de Mercado** | `MarketFeed` | Stream de dados em tempo real | Domain Service |
| **Timestamp** | `MarketTimestamp` | Data/hora de atualização dos dados | Value Object |
| **Dados Sincronizados** | `MarketDataSynchronized` | Evento emitido quando dados de mercado são atualizados | Domain Event |
| **Série de Opção** | `OptionSeries` | Identifica semana de vencimento: W1-W5 (W3 = mensal padrão, 3ª segunda-feira) | Value Object |
| **Número da Semana** | `WeekNumber` | Número da semana de vencimento (1-5) dentro do mês | Value Object |
| **Mensal Padrão** | `MonthlyStandard` | Indica se é opção mensal padrão (W3, vence na 3ª segunda-feira) | Value Object (Flag) |
| **Ajuste de Strike** | `StrikeAdjustment` | Registro de ajuste de strike por dividendo ou evento corporativo | Entity |
| **Strike Original** | `OriginalStrike` | Preço de exercício original na emissão do contrato (imutável) | Value Object |
| **Strike Atual** | `CurrentStrike` | Preço de exercício atual (após ajustes por dividendos) | Value Object |
| **Motivo do Ajuste** | `AdjustmentReason` | Causa do ajuste: Dividend (dividendo), Split, Inplit, etc. | Value Object (Enum) |
| **Serviço de Streaming** | `MarketDataStreamService` | Serviço de domínio para throttling e cache de updates em tempo real | Domain Service |
| **Atualização em Tempo Real** | `RealTimePriceUpdate` | Update de preço em tempo real via streaming | Value Object |
| **Inscrição de Símbolo** | `SymbolSubscription` | Registro de cliente inscrito para receber updates de um símbolo | Value Object |
| **Throttling de Preço** | `PriceThrottling` | Controle de frequência de updates para evitar sobrecarga | Domain Service Behavior |
| **Mudança Significativa** | `SignificantChange` | Variação de preço relevante que justifica update (ex: > 0.5%) | Value Object |
| **Strike Ajustado** | `OptionStrikeAdjusted` | Evento emitido quando strike é ajustado por dividendo ou evento corporativo | Domain Event |
| **Streaming Iniciado** | `MarketDataStreamStarted` | Evento emitido quando stream de dados em tempo real é iniciado | Domain Event |
| **Streaming Parado** | `MarketDataStreamStopped` | Evento emitido quando stream de dados em tempo real é interrompido | Domain Event |
| **Preço em Tempo Real Recebido** | `RealTimePriceReceived` | Evento emitido quando novo preço chega via streaming | Domain Event |
| **Usuário Inscrito em Símbolo** | `UserSubscribedToSymbol` | Evento emitido quando usuário se inscreve para receber updates de símbolo | Domain Event |
| **Usuário Desinscrito de Símbolo** | `UserUnsubscribedFromSymbol` | Evento emitido quando usuário cancela inscrição de updates de símbolo | Domain Event |
| **Sincronização de Opções Iniciada** | `OptionsDataSyncStarted` | Evento emitido quando sincronização batch com B3 inicia | Domain Event |
| **Sincronização de Opções Concluída** | `OptionsDataSyncCompleted` | Evento emitido quando sincronização batch com B3 termina | Domain Event |
| **Novos Contratos Descobertos** | `NewOptionContractsDiscovered` | Evento emitido quando novos contratos de opção são encontrados na B3 | Domain Event |

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
| **Role** | `Role` | Papel do usuário no sistema: Trader (opera estratégias), Moderator (modera conteúdo), Administrator (gestão do sistema) | Value Object (Enum) |
| **Plano de Assinatura** | `SubscriptionPlan` | Nível de assinatura do trader: Básico, Pleno, Consultor | Aggregate Root |
| **Perfil de Risco** | `RiskProfile` | Classificação do trader: Conservador, Moderado, Agressivo | Value Object (Enum) |
| **Email** | `Email` | Endereço de email único do usuário | Value Object |
| **Senha** | `Password` | Credencial de autenticação (hashed) | Value Object |
| **Perfil do Usuário** | `UserProfile` | Dados do usuário (nome, role, perfil de risco, plano de assinatura) | Entity |
| **Permissões** | `Permissions` | Autorização de acesso baseada em role e plano de assinatura | Value Object |
| **Override de Plano** | `UserPlanOverride` | Override temporário ou permanente de limites e features do plano (ex: beta tester, VIP, trial) | Value Object |
| **Período de Cobrança** | `BillingPeriod` | Periodicidade de pagamento: Monthly (mensal) ou Annual (anual com desconto) | Value Object (Enum) |
| **Taxas de Trading** | `TradingFees` | Taxas de negociação: corretagem, emolumentos B3, liquidação, impostos | Value Object |
| **Taxas Customizadas** | `CustomFees` | Taxas personalizadas para usuário específico (ex: corretora diferente, conta VIP) | Value Object |
| **Funcionalidades do Plano** | `PlanFeatures` | Features habilitadas no plano: dados em tempo real, alertas avançados, ferramentas de consultoria | Value Object |
| **Usuário Cadastrado** | `UserRegistered` | Evento emitido quando novo usuário completa registro | Domain Event |
| **Role Atribuído** | `RoleAssigned` | Evento emitido quando role é atribuído ao usuário | Domain Event |
| **Plano de Assinatura Atualizado** | `SubscriptionPlanUpdated` | Evento emitido quando trader muda de plano | Domain Event |
| **Perfil de Risco Definido** | `RiskProfileDefined` | Evento emitido quando trader define seu perfil de risco | Domain Event |
| **Override de Plano Concedido** | `PlanOverrideGranted` | Evento emitido quando administrador concede override de plano a usuário | Domain Event |
| **Override de Plano Revogado** | `PlanOverrideRevoked` | Evento emitido quando administrador revoga override de plano | Domain Event |
| **Taxas Customizadas Configuradas** | `CustomFeesConfigured` | Evento emitido quando taxas personalizadas são configuradas para usuário | Domain Event |
| **Taxas Customizadas Removidas** | `CustomFeesRemoved` | Evento emitido quando taxas personalizadas são removidas | Domain Event |

---

#### Community & Sharing (Supporting Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Chat da Comunidade** | `CommunityChat` | Conversa pública entre usuários da plataforma | Aggregate Root |
| **Mensagem** | `Message` | Texto enviado no chat da comunidade | Entity |
| **Sala** | `ChatRoom` | Canal de comunicação da comunidade | Entity |
| **Conteúdo** | `Content` | Conteúdo compartilhado na comunidade (mensagem, estratégia pública) | Entity |
| **Denúncia/Sinalização** | `ContentFlag` | Marcação de conteúdo como impróprio por usuário ou sistema automático | Entity |
| **Motivo de Denúncia** | `FlagReason` | Spam, Fraude, Conteúdo Enganoso, Violação Regulatória | Value Object (Enum) |
| **Fila de Moderação** | `ModerationQueue` | Fila de conteúdo pendente de revisão por moderadores | Aggregate Root |
| **Decisão de Moderação** | `ModerationDecision` | Aprovado, Rejeitado, Removido | Value Object (Enum) |
| **Estratégia de Moderação** | `ModerationStrategy` | Pré-moderação (aprovação antes) ou Pós-moderação (publica e modera depois) | Value Object (Enum) |
| **Histórico de Moderação** | `ModerationHistory` | Registro de todas decisões de moderação por conteúdo/usuário | Entity |
| **Compartilhamento Público** | `PublicShare` | Ação de tornar estratégia pública na comunidade (após moderação) ou exportar para redes sociais | Entity |
| **Rede Social** | `SocialNetwork` | Plataforma externa (Telegram, Twitter) | Value Object (Enum) |
| **Mensagem Enviada** | `MessageSent` | Evento emitido quando mensagem é enviada no chat da comunidade | Domain Event |
| **Conteúdo Sinalizado** | `ContentFlagged` | Evento emitido quando conteúdo é denunciado | Domain Event |
| **Conteúdo Moderado** | `ContentModerated` | Evento emitido quando moderador toma decisão sobre conteúdo | Domain Event |
| **Estratégia Compartilhada Publicamente** | `StrategySharedPublicly` | Evento emitido quando estratégia é publicada na comunidade (aprovada) | Domain Event |
| **Estratégia Exportada** | `StrategyExported` | Evento emitido quando estratégia é exportada para rede social | Domain Event |

---

#### Consultant Services (Supporting Domain)

| Termo (PT) | Código (EN) | Definição | Tipo DDD |
|------------|-------------|-----------|----------|
| **Consultor** | `Consultant` | Usuário com plano Consultor que gerencia carteira de clientes (herda todas funcionalidades do Pleno para suas próprias estratégias) | Aggregate Root |
| **Cliente** | `Client` | Usuário gerenciado por consultor | Entity |
| **Carteira de Clientes** | `ClientPortfolio` | Conjunto de clientes de um consultor | Entity |
| **Atribuição de Estratégia** | `StrategyAssignment` | Estratégia compartilhada privadamente com cliente específico | Entity |
| **Orientação** | `Guidance` | Recomendação do consultor para cliente executar operação | Entity |
| **Execução por Consultor** | `ConsultantExecution` | Operação executada pelo consultor em nome do cliente | Entity |
| **Autorização de Execução** | `ExecutionAuthorization` | Permissão do cliente para consultor executar operações | Value Object |
| **Permissão de Compartilhamento** | `SharingPermission` | Nível de acesso: View (visualizar), Copy (copiar) ou Execute (executar) | Value Object (Enum) |
| **Cliente Adicionado** | `ClientAdded` | Evento emitido quando consultor adiciona cliente à carteira | Domain Event |
| **Estratégia Atribuída a Cliente** | `StrategyAssignedToClient` | Evento emitido quando consultor compartilha estratégia com cliente | Domain Event |
| **Operação Orientada** | `OperationGuidedEvent` | Evento emitido quando consultor orienta cliente sobre operação | Domain Event |
| **Operação Executada por Consultor** | `OperationExecutedByConsultant` | Evento emitido quando consultor executa operação para cliente | Domain Event |

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
| **ExecutionMode** | **StrategyStatus** | Paper trading é um status (PaperTrading), não modo de execução separado |
| **SimulatedPnL** | **CurrentPnL** | Não há distinção entre P&L real e simulado - mesmo cálculo, contexto determina uso |
| **ProfitAndLoss** | **CurrentPnL** | Usar termo mais específico para P&L não realizado |

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
| 2025-10-24 | StrategyStatus | Adicionado | Ciclo de vida da estratégia: Draft, Validated, PaperTrading, Live, Closed |
| 2025-10-24 | ExecutionMode | Removido | Substituído por StrategyStatus - paper trading é status, não modo |
| 2025-10-24 | SimulatedPnL | Removido | Não há distinção - CurrentPnL serve para ambos contextos |
| 2025-10-24 | ProfitAndLoss → CurrentPnL | Renomeado | Termo mais específico para P&L não realizado |
| 2025-10-24 | MarketView, StrategyObjective, StrategyRiskProfile | Adicionados | Caracterização de templates de estratégia |
| 2025-10-24 | PriceRangeIdeal, DefenseGuidelines | Adicionados | Orientações de uso de templates |
| 2025-10-24 | PnLSnapshot, PnLType, PnLHistory | Adicionados | Sistema de tracking histórico de P&L |
| 2025-10-24 | ClosingReason | Adicionado | Obrigatório ao encerrar estratégia |
| 2025-10-24 | Eventos de Strategy (9 novos) | Adicionados | StrategyValidated, StrategyPaperTradingStarted, StrategyWentLive, StrategyPnLUpdated, PnLSnapshotCaptured, StrategyLegAdjusted, StrategyLegAddedToActive, StrategyLegRemoved, StrategyClosed |
| 2025-10-24 | OptionSeries, WeekNumber, MonthlyStandard | Adicionados | Suporte a opções semanais W1-W5 (W3 = mensal padrão) |
| 2025-10-24 | StrikeAdjustment, OriginalStrike, CurrentStrike, AdjustmentReason | Adicionados | Sistema de ajuste de strike por dividendos |
| 2025-10-24 | MarketFeed | Atualizado | De Value Object para Domain Service |
| 2025-10-24 | MarketDataStreamService | Adicionado | Domain Service para streaming, throttling e cache |
| 2025-10-24 | Eventos de Streaming (9 novos) | Adicionados | MarketDataStreamStarted, MarketDataStreamStopped, RealTimePriceReceived, UserSubscribedToSymbol, UserUnsubscribedFromSymbol, OptionsDataSyncStarted, OptionsDataSyncCompleted, NewOptionContractsDiscovered, OptionStrikeAdjusted |
| 2025-10-24 | SubscriptionPlan | Atualizado | De Value Object para Aggregate Root |
| 2025-10-24 | UserPlanOverride, BillingPeriod | Adicionados | Sistema de override de planos (beta tester, VIP, trial) |
| 2025-10-24 | TradingFees, CustomFees | Adicionados | Taxas customizadas por usuário (corretora, conta VIP) |
| 2025-10-24 | PlanFeatures | Adicionado | Features habilitadas por plano (realtime data, alertas, consultoria) |
| 2025-10-24 | Eventos de User (4 novos) | Adicionados | PlanOverrideGranted, PlanOverrideRevoked, CustomFeesConfigured, CustomFeesRemoved |

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

- [x] Strategy Planning (41 termos - incluindo StrategyStatus, caracterização de templates, P&L tracking, manejo)
- [x] Trade Execution (12 termos - removidos ExecutionMode e SimulatedPnL, atualizado PaperTrading)
- [x] Risk Management (13 termos)
- [x] Market Data (26 termos - incluindo opções semanais, ajuste de strike, streaming)
- [x] Asset Management (15 termos - incluindo Carteira de Ativos e Opções)
- [x] User Management (16 termos - incluindo plan override, custom fees, billing period)
- [x] Community & Sharing (7 termos)
- [x] Consultant Services (6 termos)
- [x] Analytics & AI (10 termos)

**Total:** 146 termos + 4 termos compartilhados = **150 termos**  

---

**Status:** Completo e pronto para uso  
**Próxima revisão:** Após feedback de UXD e DE  
