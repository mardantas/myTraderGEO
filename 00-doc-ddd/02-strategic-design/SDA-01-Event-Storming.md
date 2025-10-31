# SDA-01-Event-Storming.md

**Projeto:** myTraderGEO  
**Data:** 2025-10-12  
**Facilitador:** SDA Agent  
**Versão:** 1.0  

---

## 📋 Contexto do Workshop

- **Duração:** 4 horas (simulado)
- **Participantes:**
  - Product Owner
  - Domain Experts (traders de opções)
  - Technical Lead
- **Escopo de Negócio:** Plataforma completa para gestão de investimentos no mercado brasileiro, incluindo criação, análise, execução, monitoramento e encerramento de estratégias com opções, ações ou combinações (estratégias mistas)

---

## 🎯 Objetivos

- Descobrir eventos de domínio principais
- Identificar bounded contexts emergentes
- Mapear processos de negócio
- Identificar hotspots e complexidades

---

## 📝 Eventos de Domínio Descobertos

### Processo Principal 1: Criação de Template (Catálogo)

```
[Template Selecionado (opcional)] → [Template Criado] → [Template Salvo no Catálogo]
```

**Eventos Detalhados:**

1. **Template Selecionado (opcional)**
   - Trigger: Trader escolhe template existente do catálogo (sistema ou pessoal) como base
   - Actor: Trader
   - Data: template ID, visibilidade (global=sistema, pessoal=próprio trader)
   - Business Rule: Trader vê templates globais (sistema) + seus templates pessoais

2. **Template Criado**
   - Trigger: Trader define estrutura/topologia do template (opções e/ou ações, posições relativas, quantidades) baseado em outro template ou do zero
   - Actor: Trader
   - Data: nome template, estrutura de pernas com referências relativas, tags
   - Business Rule: Template define a **estrutura/topologia** da estratégia, não valores absolutos. Cada perna especifica: (1) tipo de instrumento (ação, call, put), (2) posição (long/short), (3) quantidade relativa (+1, -2, etc), (4) referência relativa de strike para opções (ex: "ATM", "ATM+5%", "ATM-10%", "3 strikes acima"), (5) vencimento relativo (ex: "janeiro próximo", "+6 meses", "opção longa"). Exemplo Borboleta: +1 Call "strike baixo" / -2 Calls "ATM" / +1 Call "strike alto". Não tem ativo subjacente definido, não tem strikes absolutos (R$), não tem datas específicas. Template pode ser: somente opções, somente ações, ou estratégia mista

3. **Template Salvo no Catálogo**
   - Trigger: Trader confirma salvamento
   - Actor: Sistema
   - Data: template completo, nome, tags, visibilidade (pessoal)
   - Business Rule: Nome único por usuário no catálogo pessoal, template fica visível apenas para o trader

---

### Processo Principal 2: Criação de Estratégia (para Executar)

```
[Template Selecionado (opcional)] → [Estratégia Criada] → [Cálculos Automáticos Executados] → [Margem Calculada] → [Rentabilidade Analisada] → [Risco Avaliado]
```

**Eventos Detalhados:**

1. **Template Selecionado (opcional)**
   - Trigger: Trader escolhe template do catálogo como base para estratégia
   - Actor: Trader
   - Data: template ID
   - Business Rule: Template define estrutura, trader adiciona ativo subjacente e parâmetros específicos

2. **Estratégia Criada**
   - Trigger: Trader **instancia** template (ou cria do zero) definindo ativo subjacente e parâmetros absolutos
   - Actor: Trader
   - Data: nome estratégia, ativo subjacente específico (ex: PETR4), lista de pernas com valores absolutos
   - Business Rule: Mínimo 1 perna, ativo válido B3. Trader transforma referências relativas do template em valores absolutos: (1) strikes relativos → strikes absolutos em R$ (ex: "ATM" → R$ 32,00 baseado no preço atual), (2) vencimentos relativos → datas específicas (ex: "janeiro próximo" → jan/2026), (3) quantidades do template mantidas (+1, -2, etc). Exemplo: Template Borboleta instanciado em PETR4 → +1 Call R$ 30 jan/26 / -2 Calls R$ 32 jan/26 / +1 Call R$ 34 jan/26. Estratégia pode ser: somente ações, somente opções, ou mista

3. **Cálculos Automáticos Executados**
   - Trigger: Estratégia criada ou modificada
   - Actor: Sistema de cálculo
   - Data: dados de mercado (preços, volatilidade se opção, taxas)
   - Business Rule: Dados de mercado atualizados (tempo real para plano Pleno). Cálculos adaptados ao tipo de estratégia (ações, opções ou mista)

4. **Margem Calculada**
   - Trigger: Cálculos executados
   - Actor: Motor de cálculo de margem
   - Data: margem requerida, garantias disponíveis
   - Business Rule: Regras B3 de margem. Ações: margem para compra (se margem) ou garantia para venda descoberta. Opções: margem conforme regras B3. Estratégia mista: margem combinada

5. **Rentabilidade Analisada**
   - Trigger: Cálculos executados
   - Actor: Motor de análise
   - Data: rentabilidade potencial, breakeven, lucro máximo, prejuízo máximo
   - Business Rule: Cenários múltiplos de preço. Ações: análise linear simples. Opções: curva de payoff não-linear. Mista: combinação

6. **Risco Avaliado**
   - Trigger: Rentabilidade calculada
   - Actor: Sistema de gestão de risco
   - Data: risco teórico, score de risco, compatibilidade com perfil, tipo de estratégia
   - Business Rule: Limites por perfil de usuário. Risco considera tipo de instrumento (ação tem risco diferente de opção)

**Próximo passo:** Estratégia pode ser ativada para execução (Processo 3)  

---

### Processo Principal 3: Execução e Monitoramento

```
[Estratégia Validada] → [Paper Trading Iniciado | Estratégia Ativada Live] → [Posição Registrada (Real) / Performance Simulada (Paper)] → [Dados de Mercado Sincronizados] → [P&L Atualizado] → [Snapshot P&L Capturado] → [Alerta Disparado] → [Ajuste Executado (Perna Ajustada/Adicionada/Removida)] → [Posição Atualizada] → [Estratégia Encerrada]
```

**Nota:** O conceito de "Modo Selecionado" foi substituído por **Status da Estratégia** (StrategyStatus): Draft → Validated → PaperTrading → Live → Closed. Paper trading e Live são status, não modos separados.  

**Eventos Detalhados:**

1. **Estratégia Ativada**
   - Trigger: Usuário decide ativar estratégia
   - Actor: Trader
   - Data: estratégia ID, modo selecionado (paper trading ou real)
   - Business Rule: Trader escolhe entre paper trading (acompanhamento hipotético) ou real (execução efetiva)

2a. **Estratégia Ativada como Paper Trading**
   - Trigger: Modo paper trading selecionado
   - Actor: Trader
   - Data: estratégia ID, preços de entrada hipotéticos (preços de mercado no momento da ativação)
   - Business Rule: Performance acompanhada ao longo do tempo com dados reais, mas sem execução real. Não requer margem disponível.

2b. **Estratégia Ativada como Real**
   - Trigger: Modo real selecionado
   - Actor: Trader
   - Data: estratégia ID
   - Business Rule: Margem disponível suficiente obrigatória

3. **Posição Registrada (apenas Real)**
   - Trigger: Estratégia ativada como real
   - Actor: Trader (MVP: registro manual) | Sistema (futuro: execução automática via broker)
   - Data: ordens executadas, preços de entrada, timestamps
   - Business Rule: **MVP**: Trader registra ordens executadas manualmente na corretora (Rico, XP, etc). **Futuro**: Integração automática via broker (ex: Nelógica, Cedro) para execução de ordens. Sistema permite configurar datafeed provider e broker separadamente (podem ser o mesmo, ex: Nelógica para ambos, ou diferentes, ex: Nelógica datafeed + Cedro broker)

4. **Dados de Mercado Sincronizados**
   - Trigger: Polling periódico ou real-time feed
   - Actor: Sistema de dados de mercado
   - Data: preços opções, preço ativo subjacente, volatilidade implícita
   - Business Rule: Atualização tempo real para plano Pleno, aplica-se tanto para paper trading quanto real

5. **P&L Atualizado** (StrategyPnLUpdated)
   - Trigger: Dados de mercado atualizados ou ajuste executado
   - Actor: Motor de performance
   - Data: P&L atual (real ou simulado), P&L percentual, timestamp
   - Business Rule: Cálculo em tempo real para estratégias em status PaperTrading ou Live. Não há distinção no cálculo - CurrentPnL serve para ambos contextos

5a. **Snapshot P&L Capturado** (PnLSnapshotCaptured)
   - Trigger: Captura periódica (diária, semanal, mensal), sob demanda, ou no encerramento
   - Actor: Sistema
   - Data: P&L value, P&L percentual, tipo snapshot (Daily/OnDemand/Weekly/Monthly/Closing), timestamp
   - Business Rule: Snapshots são imutáveis após criação, formam histórico de P&L ao longo do tempo

6. **Alerta Disparado**
   - Trigger: Condição de alerta atendida
   - Actor: Sistema de alertas
   - Data: tipo alerta (margem, vencimento, conflito), severidade, mensagem, modo (paper/real)
   - Business Rule: **Real**: Chamada de margem, vencimento próximo (7 dias), conflitos entre posições. **Paper**: Apenas alertas informativos (sem obrigatoriedade)

7. **Ajuste Executado** (manejo de estratégias ativas)
   - Trigger: Usuário decide ajustar estratégia
   - Actor: Trader
   - Data: tipo ajuste, pernas afetadas, status (PaperTrading/Live)
   - Business Rule: Apenas estratégias PaperTrading ou Live podem ser ajustadas

   Eventos específicos de ajuste:
   - **Perna Ajustada** (StrategyLegAdjusted): Quantidade de perna existente foi alterada
   - **Perna Adicionada** (StrategyLegAddedToActive): Nova perna adicionada à estratégia ativa
   - **Perna Removida** (StrategyLegRemoved): Perna foi removida (mínimo 1 perna sempre mantida)

8. **Posição Atualizada**
   - Trigger: Ajuste executado
   - Actor: Sistema
   - Data: histórico de ajustes, nova configuração, status (PaperTrading/Live)
   - Business Rule: Histórico completo mantido para ambos status

9. **Estratégia Encerrada** (StrategyClosed)
   - Trigger: Trader decide encerrar estratégia ativa
   - Actor: Trader
   - Data: P&L final, P&L percentual final, motivo de encerramento (obrigatório), timestamp
   - Business Rule: Apenas estratégias PaperTrading ou Live podem ser encerradas. Snapshot final (Closing) capturado automaticamente. Status muda para Closed

10. **Estratégia Promovida para Real** (StrategyWentLive com flag wasPaperTrading=true)
   - Trigger: Usuário decide promover estratégia de paper trading para live
   - Actor: Trader
   - Data: estratégia ID, histórico de performance paper preservado, preços atuais de mercado
   - Business Rule: Margem disponível suficiente obrigatória, histórico paper preservado para referência, status muda de PaperTrading para Live

---

### Processo Principal 4: Gestão de Risco e Controle Financeiro

```
[Perfil de Risco Definido] → [Limites Operacionais Configurados] → [Conflito Detectado] → [Alerta de Conflito Enviado] → [Carteira de Ativos Sincronizada] → [Garantias Atualizadas] → [Aporte/Retirada Registrado]
```

**Eventos Detalhados:**

1. **Perfil de Risco Definido**
   - Trigger: Cadastro ou atualização de usuário
   - Actor: Trader
   - Data: perfil (conservador/moderado/agressivo), limites padrão
   - Business Rule: Limites por perfil pré-definidos

2. **Limites Operacionais Configurados**
   - Trigger: Perfil definido ou customização
   - Actor: Trader ou Sistema
   - Data: exposição máxima, risco máximo por operação, número máximo estratégias
   - Business Rule: Limites customizados dentro de boundaries do perfil

3. **Conflito Detectado**
   - Trigger: Análise de estratégia
   - Actor: Sistema de detecção de conflitos
   - Data: estratégias conflitantes, tipo conflito, impacto
   - Business Rule: Identificar operações que podem gerar resultados indesejados

4. **Alerta de Conflito Enviado**
   - Trigger: Conflito detectado
   - Actor: Sistema de notificações
   - Data: descrição conflito, estratégias envolvidas, ação recomendada
   - Business Rule: Notificação imediata

5. **Carteira de Ativos Sincronizada**
   - Trigger: Polling periódico ou manual
   - Actor: Sistema de integração B3
   - Data: ativos em carteira, quantidades, preços médios
   - Business Rule: Sincronização com B3 para atualizar garantias disponíveis

6. **Garantias Atualizadas**
   - Trigger: Carteira sincronizada
   - Actor: Sistema de margem
   - Data: ativos disponíveis para garantia, valores
   - Business Rule: Regras B3 de garantias aceitas

7. **Aporte/Retirada Registrado**
   - Trigger: Usuário registra movimentação financeira
   - Actor: Trader
   - Data: valor, tipo (aporte/retirada), data, ativo
   - Business Rule: Atualiza custo médio consolidado

---

### Processo Principal 5: Comunidade e Compartilhamento

```
[Chat Iniciado] → [Mensagem Enviada] → [Conteúdo Sinalizado (opcional)] → [Conteúdo Moderado] → [Estratégia Compartilhada] → [Estratégia Exportada para Rede Social]
```

**Eventos Detalhados:**

1. **Chat Iniciado**
   - Trigger: Usuário abre chat da comunidade
   - Actor: Usuário
   - Data: participantes, sala/canal
   - Business Rule: Usuários autenticados

2. **Mensagem Enviada**
   - Trigger: Usuário envia mensagem no chat da comunidade
   - Actor: Usuário
   - Data: texto, timestamp, remetente
   - Business Rule: Mensagens persistidas, sujeitas a moderação

3. **Conteúdo Sinalizado**
   - Trigger: Usuário ou sistema automático sinaliza conteúdo impróprio
   - Actor: Usuário ou Sistema de detecção automática
   - Data: conteúdo ID, motivo (spam, fraude, conteúdo enganoso, violação regulatória), usuário denunciante
   - Business Rule: Conteúdo entra em fila de moderação, sinalizações múltiplas priorizam revisão

4. **Conteúdo Moderado**
   - Trigger: Moderador revisa conteúdo sinalizado ou em pré-moderação
   - Actor: Moderator
   - Data: conteúdo ID, decisão (aprovado/rejeitado/removido), justificativa
   - Business Rule: Moderadores têm poder de aprovar, rejeitar ou remover conteúdo. Histórico de moderação mantido. Compliance com regulamentações de mercado financeiro

5. **Estratégia Compartilhada**
   - Trigger: Usuário compartilha estratégia publicamente na plataforma (aprovada por moderação)
   - Actor: Trader
   - Data: estratégia ID, visibilidade pública, status moderação
   - Business Rule: Estratégias públicas visíveis para toda a comunidade após aprovação de moderação (pós-moderação para usuários veteranos, pré-moderação para novos)

6. **Estratégia Exportada para Rede Social**
   - Trigger: Usuário exporta estratégia para Telegram/Twitter
   - Actor: Trader
   - Data: estratégia formatada, link
   - Business Rule: Formatos específicos por rede social, exportação não requer moderação (responsabilidade do usuário)

---

### Processo Principal 6: Consultoria

```
[Cliente Adicionado] → [Estratégia Atribuída a Cliente] → [Operação Orientada] → [Operação Executada por Consultor]
```

**Eventos Detalhados:**

1. **Cliente Adicionado**
   - Trigger: Consultor adiciona cliente à sua carteira
   - Actor: Consultor
   - Data: cliente ID, dados de contato, perfil de risco, permissões
   - Business Rule: Apenas usuários com plano Consultor

2. **Estratégia Atribuída a Cliente**
   - Trigger: Consultor compartilha estratégia específica com cliente
   - Actor: Consultor
   - Data: estratégia ID, cliente ID, permissões (view/copy/execute)
   - Business Rule: Rastreamento de estratégias compartilhadas por consultor

3. **Operação Orientada**
   - Trigger: Consultor orienta cliente sobre operação a executar
   - Actor: Consultor
   - Data: estratégia, orientação, recomendação, cliente
   - Business Rule: Cliente executa por conta própria na corretora

4. **Operação Executada por Consultor**
   - Trigger: Consultor executa operação em nome do cliente
   - Actor: Consultor
   - Data: estratégia, ordens executadas, cliente, autorização
   - Business Rule: Requer autorização prévia do cliente, consultor executa na corretora do cliente

---

### Processo Principal 7: Automação e IA (Futuro)

```
[Backtesting Solicitado] → [Dados Históricos Carregados] → [Estratégia Testada] → [Resultado de Backtest Gerado] → [Sugestão de IA Criada] → [Ajuste Recomendado]
```

**Eventos Detalhados:**

1. **Backtesting Solicitado**
   - Trigger: Usuário inicia backtest
   - Actor: Trader
   - Data: estratégia, período, parâmetros
   - Business Rule: Dados históricos disponíveis

2. **Dados Históricos Carregados**
   - Trigger: Backtest solicitado
   - Actor: Sistema de dados históricos
   - Data: séries de preços, volatilidade histórica
   - Business Rule: Dados completos para período

3. **Estratégia Testada**
   - Trigger: Dados carregados
   - Actor: Motor de backtesting
   - Data: simulação de trades, P&L por período
   - Business Rule: Simulação realista

4. **Resultado de Backtest Gerado**
   - Trigger: Teste completo
   - Actor: Sistema
   - Data: métricas (sharpe, max drawdown, win rate), gráficos
   - Business Rule: Relatório completo

5. **Sugestão de IA Criada**
   - Trigger: Análise de mercado ou estratégia
   - Actor: Motor de IA
   - Data: recomendação, confiança, justificativa
   - Business Rule: Baseado em padrões de mercado

6. **Ajuste Recomendado**
   - Trigger: Sugestão criada
   - Actor: Sistema
   - Data: tipo ajuste, impacto esperado
   - Business Rule: Ajustes validados por regras de negócio

---

## 🏗️ Bounded Contexts Emergentes

### 1. **User Management** (Generic)

**Responsabilidade:** Gerenciar cadastro, autenticação, autorização, roles (Trader, Administrator), perfis de risco e planos de assinatura  

**Eventos deste contexto:**
- Usuário Cadastrado
- Role Atribuído
- Perfil de Risco Definido
- Plano de Assinatura Atualizado

**Roles:**
- Trader (opera estratégias)
- Moderator (modera conteúdo da comunidade, compliance regulatório)
- Administrator (gestão do sistema, usuários, configurações globais)

**Planos de Assinatura:**
- Básico (gratuito, limite de estratégias)
- Pleno (acesso ilimitado, dados real-time)
- Consultor (ferramentas de consultoria)

**Complexidade:** Baixa  

**Dados Sensíveis:** Email, senha, dados pessoais (LGPD)  

---

### 2. **Strategy Planning** (Core Domain)

**Responsabilidade:** Gestão do catálogo de estratégias (templates globais do sistema + templates pessoais do trader), criação, análise e simulação de estratégias com opções, ações ou combinações (estratégias mistas)  

**Eventos deste contexto:**
- Template Selecionado
- Estratégia Criada (com opções, ações ou ambos)
- Cálculos Automáticos Executados (adaptados ao tipo: ação, opção, mista)
- Margem Calculada (conforme instrumento)
- Rentabilidade Analisada (linear para ações, não-linear para opções)
- Risco Avaliado (por tipo de instrumento)
- Trader Solicita Salvar como Template (opcional)
- Template Salvo no Catálogo (opcional)

**Complexidade:** Alta  

**Dados Sensíveis:** Estratégias privadas (propriedade intelectual)  

---

### 3. **Market Data** (Supporting)

**Responsabilidade:** Sincronização de dados de mercado (preços, volatilidade, gregas) em tempo real ou batch  

**Eventos deste contexto:**
- Dados de Mercado Sincronizados

**Complexidade:** Média  

**Alta Carga:** Sim (real-time para Pleno, polling para Básico)  

---

### 4. **Trade Execution** (Core Domain)

**Responsabilidade:** Execução, monitoramento e ajuste de estratégias ativas (real e paper trading)  

**Eventos deste contexto:**
- Estratégia Ativada (modo: paper trading ou real)
- Estratégia Ativada como Paper Trading
- Estratégia Ativada como Real
- Posição Registrada (apenas real: manual no MVP, automática no futuro)
- Performance Calculada (real e simulada)
- Ajuste Executado (real e simulado)
- Posição Atualizada (real e simulada)
- Estratégia Promovida para Real (paper → real)

**Complexidade:** Alta  

**Dados Sensíveis:** Ordens e posições reais, histórico de paper trading  

---

### 5. **Risk Management** (Core Domain)

**Responsabilidade:** Gestão de risco, detecção de conflitos, limites operacionais e alertas  

**Eventos deste contexto:**
- Limites Operacionais Configurados
- Conflito Detectado
- Alerta Disparado
- Alerta de Conflito Enviado

**Complexidade:** Alta  

---

### 6. **Asset Management** (Supporting)

**Responsabilidade:** Gestão da carteira de ativos (ações, índices, saldo) e carteira de opções (posições ativas), integração com B3, controle de garantias, aportes/retiradas e custo médio  

**Eventos deste contexto:**
- Carteira de Ativos Sincronizada
- Carteira de Opções Atualizada
- Garantias Atualizadas
- Aporte/Retirada Registrado

**Complexidade:** Média  

**Dados Sensíveis:** Posições em ativos, opções e saldos financeiros (LGPD)  

---

### 7. **Community & Sharing** (Supporting)

**Responsabilidade:** Chat da comunidade, compartilhamento público de estratégias, exportação para redes sociais, moderação de conteúdo  

**Eventos deste contexto:**
- Chat Iniciado
- Mensagem Enviada
- Conteúdo Sinalizado (denúncias/flags)
- Conteúdo Moderado (aprovação/rejeição/remoção)
- Estratégia Compartilhada (público, após moderação)
- Estratégia Exportada para Rede Social

**Complexidade:** Média (adicionado sistema de moderação e compliance)  

---

### 8. **Consultant Services** (Supporting)

**Responsabilidade:** Gestão de carteira de clientes por consultores, orientação e execução de operações para clientes  

**Eventos deste contexto:**
- Cliente Adicionado
- Estratégia Atribuída a Cliente (privado consultor-cliente)
- Operação Orientada
- Operação Executada por Consultor

**Complexidade:** Média  

**Dados Sensíveis:** Dados de clientes, operações executadas (LGPD)  

---

### 9. **Analytics & AI** (Generic - Futuro)

**Responsabilidade:** Backtesting, sugestões de IA, análise avançada de mercado  

**Eventos deste contexto:**
- Backtesting Solicitado
- Dados Históricos Carregados
- Estratégia Testada
- Resultado de Backtest Gerado
- Sugestão de IA Criada
- Ajuste Recomendado

**Complexidade:** Alta  

**Alta Carga:** Sim (processamento intensivo)  

---

## 🔥 Hotspots Identificados

| Hotspot | Descrição | Complexidade | Risco |
|---------|-----------|--------------|-------|
| **Cálculo de Margem B3** | Regras complexas de margem conforme regulamentação B3, múltiplos cenários | Alta | Alto |
| **Detecção de Conflitos** | Identificar automaticamente estratégias que podem gerar resultados indesejados | Alta | Médio |
| **Integração B3 em Tempo Real** | Sincronização de carteira e dados de mercado com B3 | Alta | Alto |
| **Cálculo de Gregas** | Cálculo preciso de delta, gamma, theta, vega em tempo real | Alta | Médio |
| **Execução Automática de Ordens (Futuro)** | Integração via API com corretoras (Nelógica, Cedro) | Alta | Alto |
| **Segurança de Dados (LGPD)** | Proteção de dados sensíveis (posições, saldos, estratégias privadas) | Média | Alto |
| **Escalabilidade Market Data** | Performance com múltiplos usuários Pleno em real-time | Alta | Médio |
| **Backtesting Performance** | Processamento de grandes volumes de dados históricos | Alta | Baixo |

---

## 📖 Linguagem Ubíqua

Para consultar a **Linguagem Ubíqua completa** com mapeamento PT → EN e definições detalhadas, veja:
- **[SDA-03-Ubiquitous-Language.md](./SDA-03-Ubiquitous-Language.md)**

---

## 🎯 Próximos Passos

- [x] Event Storming completo
- [x] Criar Context Map com relacionamentos entre BCs
- [x] Refinar Ubiquitous Language com mapeamento PT → EN
- [x] Definir épicos por funcionalidade (cross-BC)
- [x] Priorizar épicos por valor de negócio
