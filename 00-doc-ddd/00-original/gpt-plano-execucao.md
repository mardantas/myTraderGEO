# Plano de Execução - myTraderGEO

## Objetivo
Definir o fluxo de execução técnica e operacional para entrega da plataforma **myTraderGEO** em ambientes controlados (staging) e produtivos, garantindo estabilidade, escalabilidade e segurança.

---

## Fases do Projeto

### 1. Desenvolvimento
- Ambiente local via Docker Compose
- Mocks de integração (dados da B3 e ordens)
- Testes unitários e de integração (.NET + Vue Test Utils)
- Estruturação de migrations com EF Core

### 2. Integração Contínua (CI)
- GitHub Actions com:
  - Build do frontend e backend
  - Execução de testes automatizados
  - Validação de migrations
  - Lint + análise estática de código

### 3. Deploy Contínuo (CD)

#### Staging
- Push para `release/*` ou `hotfix/*`
- CI gera imagens `mytrader-geo-*`
- Deploy em Docker Swarm via SSH
- Traefik redireciona com subdomínio `staging.geo.mytrader.net`
- Testes de smoke + revisão manual

#### Produção
- Disparado por **tag** (`vX.Y.Z`)
- Gatilho `workflow_dispatch` para revisão prévia
- CI/CD:
  - Geração de imagem com tag imutável
  - Aplicação de migrations com backup prévio
  - Deploy em Swarm (`geo.mytrader.net`)
  - Notificação via e-mail ou Slack

---

## Checklist de Deploy

- [ ] Build da imagem sem erros
- [ ] Migrations aplicadas com sucesso
- [ ] Testes manuais em staging
- [ ] Aprovação por responsável técnico
- [ ] Execução do workflow de produção
- [ ] Monitoramento ativo (logs, alertas, uptime)

---

## Ferramentas de Apoio

- **GitHub Projects**: rastreio de tarefas e releases
- **Grafana/Prometheus**: monitoramento de serviços
- **Sentry**: rastreio de erros no frontend e backend
- **Portainer**: gerenciamento visual do Docker Swarm

---

## Observações Finais

- Os middlewares e TLS devem ser configurados centralmente no Traefik.
- Backups automáticos do banco devem ser agendados diariamente.
- Toda alteração crítica deve ser testada em sandbox com dados simulados.

