# Especificação Técnica - myTraderGEO

## Visão Geral
O **myTraderGEO** é uma plataforma web para gestão de estratégias com opções. O sistema permite a criação, monitoramento e ajuste de operações, com recursos de análise, integração com a carteira B3 e gestão de risco. Suporta múltiplos perfis de usuários e é escalável para diferentes níveis de complexidade operacional.

---

## Arquitetura

### Frontend
- **Tecnologia**: Vue.js
- **Deploy**: Docker, com Traefik (rota baseada em hostname)
- **Funções principais**:
  - Dashboard de estratégias e ativos
  - Visualização de performance
  - Simulação e ajuste de estratégias

### Backend
- **Tecnologia**: .NET
- **Princípios**: DDD, SOLID
- **APIs RESTful**
- **Funções principais**:
  - Cálculo de risco e rentabilidade
  - Integração com dados de mercado e carteira B3
  - Gestão de usuários, permissões e notificações

### Banco de Dados
- **SGBD**: PostgreSQL
- **Persistência**: estratégica e transacional (garantias, posições, logs de simulações)

---

## Ambientes

| Ambiente    | Frontend URL               | API URL                      | Usuário DB     |
|-------------|----------------------------|-------------------------------|----------------|
| Development | `geo.mytrader.local`       | `api.geo.mytrader.local`      | `mytrader-d`   |
| Staging     | `staging.geo.mytrader.net` | `api.staging.geo.mytrader.net`| `mytrader-s`   |
| Production  | `geo.mytrader.net`         | `api.geo.mytrader.net`        | `mytrader-p`   |

---

## Orquestração e Deploy

- **Orquestrador**: Docker Swarm
- **Proxy Reverso**: Traefik v2
- **Balanceamento**: baseado em hostname e réplicas por serviço
- **Segurança**: TLS com Let's Encrypt em staging/prod
- **Deploy automático** via CI/CD (GitHub Actions + tags)

---

## Estrutura Modular

- **Módulo Estratégias**: criação, ajuste, desmonte
- **Módulo Monitoramento**: alertas, análises em tempo real
- **Módulo Financeiro**: aportes, retiradas, controle de risco
- **Módulo de Dados**: integração com B3, TradingView, Bloomberg
- **Módulo de Execução (Futuro)**: integração com corretoras via API

---

## Segurança

- **Autenticação e Autorização**:
  - JWT
  - Níveis de acesso por plano
- **Proteções Web**:
  - HTTPS obrigatório
  - Rate Limiting por middleware
  - Sanitização de entradas e logs

---

## Roadmap Técnico

1. Execução de ordens via API
2. Aplicativo Mobile
3. Backtesting com dados históricos
4. Machine Learning para sugestões de ajuste

