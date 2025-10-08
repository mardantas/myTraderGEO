# SDA-01-Event-Storming.md

**Projeto:** myTraderGEO
**Data:** 2025-10-06
**Facilitador:** SDA Agent

---

## 📋 Contexto do Workshop

**Duração:** 4 horas (simulado)
**Participantes:** Product Owner, Domain Experts (traders opções), Technical Lead
**Business Scope:** Plataforma completa para gestão de investimentos em opções no mercado brasileiro, incluindo criação, análise, execução, monitoramento e encerramento de estratégias com opções.

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
   - Trigger: Trader define estrutura do template (opções, strikes, vencimentos) baseado em outro template ou do zero
   - Actor: Trader
   - Data: nome template, estrutura de pernas (opções genéricas sem ativos específicos), tags
   - Business Rule: Template é modelo reutilizável, não tem ativo subjacente definido

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
   - Trigger: Trader define ativo subjacente e parâmetros específicos (baseado em template ou do zero)
   - Actor: Trader
   - Data: nome estratégia, ativo subjacente, lista de pernas (opções), tipo (call/put), quantidade, strike, vencimento
   - Business Rule: Mínimo 1 perna, ativo válido B3

3. **Cálculos Automáticos Executados**
   - Trigger: Estratégia criada ou modificada
   - Actor: Sistema de cálculo
   - Data: dados de mercado (volatilidade, preços, taxas)
   - Business Rule: Dados de mercado atualizados (tempo real para premium)

4. **Margem Calculada**
   - Trigger: Cálculos executados
   - Actor: Motor de cálculo de margem
   - Data: margem requerida, garantias disponíveis
   - Business Rule: Regras B3 de margem

5. **Rentabilidade Analisada**
   - Trigger: Cálculos executados
   - Actor: Motor de análise
   - Data: rentabilidade potencial, breakeven, lucro máximo, prejuízo máximo
   - Business Rule: Cenários múltiplos de preço

6. **Risco Avaliado**
   - Trigger: Rentabilidade calculada
   - Actor: Sistema de gestão de risco
   - Data: risco teórico, score de risco, compatibilidade com perfil
   - Business Rule: Limites por perfil de usuário

**Próximo passo:** Estratégia pode ser ativada para execução (Processo 3)

---

### Processo Principal 3: Execução e Monitoramento

```
[Estratégia Ativada] → [Posição Registrada] → [Dados de Mercado Sincronizados] → [Performance Calculada] → [Alerta Disparado] → [Ajuste Executado] → [Posição Atualizada]
```

**Eventos Detalhados:**

1. **Estratégia Ativada**
   - Trigger: Usuário move estratégia de sandbox para real
   - Actor: Trader
   - Data: estratégia ID, modo (sandbox/real)
   - Business Rule: Margem disponível suficiente

2. **Posição Registrada**
   - Trigger: Estratégia ativada
   - Actor: Trader (MVP: registro manual) | Sistema (futuro: execução automática via datafeed)
   - Data: ordens executadas, preços de entrada, timestamps
   - Business Rule: **MVP**: Trader registra ordens executadas manualmente na corretora (Rico, XP, etc). **Futuro**: Integração automática via datafeed providers (Nelógica, Cedro) que intermediam execução nas corretoras

3. **Dados de Mercado Sincronizados**
   - Trigger: Polling periódico ou real-time feed
   - Actor: Sistema de dados de mercado
   - Data: preços opções, preço ativo subjacente, volatilidade implícita
   - Business Rule: Atualização tempo real para premium

4. **Performance Calculada**
   - Trigger: Dados de mercado atualizados
   - Actor: Motor de performance
   - Data: P&L atual, P&L percentual, gregas (delta, gamma, theta, vega)
   - Business Rule: Cálculo em tempo real

5. **Alerta Disparado**
   - Trigger: Condição de alerta atendida
   - Actor: Sistema de alertas
   - Data: tipo alerta (margem, vencimento, conflito), severidade, mensagem
   - Business Rule: Chamada de margem, vencimento próximo (7 dias), conflitos entre posições

6. **Ajuste Executado**
   - Trigger: Usuário decide ajustar estratégia
   - Actor: Trader
   - Data: tipo ajuste (rolagem, hedge, rebalanceamento), novas pernas
   - Business Rule: Cálculo automático de nova margem

7. **Posição Atualizada**
   - Trigger: Ajuste executado
   - Actor: Sistema
   - Data: histórico de ajustes, nova configuração
   - Business Rule: Histórico completo mantido

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
[Chat Iniciado] → [Mensagem Enviada] → [Estratégia Compartilhada] → [Estratégia Exportada para Rede Social] → [Cliente Adicionado (Consultor)] → [Estratégia Atribuída a Cliente]
```

**Eventos Detalhados:**

1. **Chat Iniciado**
   - Trigger: Usuário abre chat
   - Actor: Usuário
   - Data: participantes, sala/canal
   - Business Rule: Usuários autenticados

2. **Mensagem Enviada**
   - Trigger: Usuário envia mensagem
   - Actor: Usuário
   - Data: texto, timestamp, remetente
   - Business Rule: Mensagens persistidas

3. **Estratégia Compartilhada**
   - Trigger: Usuário compartilha estratégia na plataforma
   - Actor: Trader
   - Data: estratégia ID, visibilidade pública
   - Business Rule: Estratégias públicas visíveis na comunidade

4. **Estratégia Exportada para Rede Social**
   - Trigger: Usuário exporta para Telegram/Twitter
   - Actor: Trader
   - Data: estratégia formatada, link
   - Business Rule: Formatos específicos por rede social

5. **Cliente Adicionado (Consultor)**
   - Trigger: Consultor adiciona cliente à carteira
   - Actor: Consultor
   - Data: cliente ID, plano, permissões
   - Business Rule: Apenas plano Consultor

6. **Estratégia Atribuída a Cliente**
   - Trigger: Consultor compartilha estratégia com cliente
   - Actor: Consultor
   - Data: estratégia, cliente, permissões (view/copy)
   - Business Rule: Rastreamento de estratégias compartilhadas

---

### Processo Futuro: Automação e IA

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
- Administrator (gestão do sistema)

**Planos de Assinatura:**
- Básico, Pleno, Consultor

**Complexidade:** Baixa

**Dados Sensíveis:** Email, senha, dados pessoais (LGPD)

---

### 2. **Strategy Planning** (Core Domain)

**Responsabilidade:** Gestão do catálogo de estratégias (templates globais do sistema + templates pessoais do trader), criação, análise e simulação de estratégias com opções

**Eventos deste contexto:**
- Template Selecionado
- Estratégia Criada
- Cálculos Automáticos Executados
- Margem Calculada
- Rentabilidade Analisada
- Risco Avaliado
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

**Alta Carga:** Sim (real-time para premium, polling para básico)

---

### 4. **Trade Execution** (Core Domain)

**Responsabilidade:** Execução, monitoramento e ajuste de estratégias ativas

**Eventos deste contexto:**
- Estratégia Ativada
- Posição Registrada (manual no MVP, automática no futuro)
- Performance Calculada
- Ajuste Executado
- Posição Atualizada

**Complexidade:** Alta

**Dados Sensíveis:** Ordens e posições reais

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

**Responsabilidade:** Chat, compartilhamento de estratégias, exportação para redes sociais

**Eventos deste contexto:**
- Chat Iniciado
- Mensagem Enviada
- Estratégia Compartilhada
- Estratégia Exportada para Rede Social

**Complexidade:** Baixa

---

### 8. **Consultant Services** (Supporting)

**Responsabilidade:** Gestão de carteira de clientes para consultores, compartilhamento e monetização de estratégias

**Eventos deste contexto:**
- Cliente Adicionado (Consultor)
- Estratégia Atribuída a Cliente

**Complexidade:** Média

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
| **Escalabilidade Market Data** | Performance com múltiplos usuários premium em real-time | Alta | Médio |
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
