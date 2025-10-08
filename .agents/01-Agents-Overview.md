# Agents Overview

**Objetivo:** Detalhamento dos 10 agentes especializados que executam o workflow DDD production-ready.

---

## 📊 Resumo Executivo

| # | Sigla | Agente | Escopo | Fase | Deliverables |
|---|-------|--------|--------|------|--------------|
| 10 | SDA | Strategic Domain Analyst | Sistema completo | Discovery | 3 docs |
| 15 | DE | Domain Engineer | Sistema + Por épico | Discovery + Iteração | 2 docs |
| 20 | UXD | User Experience Designer | Sistema completo | Discovery | 3 docs |
| 25 | GM | GitHub Manager | Setup + épicos | Discovery + Iteração | 1 doc |
| 30 | PE | Platform Engineer | Sistema completo | Discovery + Iteração | 4 docs + infra |
| 35 | SEC | Security Specialist | Sistema completo | Discovery + Iteração | 5 docs |
| 45 | SE | Software Engineer | Por épico | Iteração | Código + 1 doc |
| 50 | DBA | Database Administrator | Por épico | Iteração | 1 doc |
| 55 | FE | Frontend Engineer | Por épico | Iteração | Código |
| 60 | QAE | Quality Assurance Engineer | Por épico | Iteração | 1 doc + testes |

---

## 10 - SDA (Strategic Domain Analyst)

### Objetivo
Descobrir e mapear o domínio de negócio completo, definindo bounded contexts e épicos estratégicos.

### Responsabilidades
- Event Storming (descoberta de eventos de domínio)
- Identificação de Bounded Contexts
- Context Map com relacionamentos
- Ubiquitous Language (glossário)
- Priorização de épicos por valor de negócio

### Quando Executa
**1x no início do projeto** - fase de discovery

### Escopo
**Sistema completo** - analisa todo o domínio de negócio

### Deliverables
```
00-doc-ddd/02-strategic-design/
├── SDA-01-Event-Storming.md
├── SDA-02-Context-Map.md
└── SDA-03-Ubiquitous-Language.md
```

### Exemplo de Invocação
```
"SDA, faça a modelagem estratégica completa do sistema"
"SDA, atualize Context Map adicionando BC de Notificações"
"SDA, processe FEEDBACK-003"
```

### Especificação Completa
`.agents/10-SDA - Strategic Domain Analyst.xml`

---

## 20 - UXD (User Experience Designer)

### Objetivo
Projetar experiência do usuário e interfaces baseado na arquitetura estratégica.

### Responsabilidades
- User flows (jornadas principais)
- Wireframes (telas críticas)
- Component library (design system básico)
- Navegação entre contextos
- Acessibilidade e responsividade

### Quando Executa
**1x no início + ajustes incrementais** conforme épicos evoluem

### Escopo
**Sistema completo** - design para todos os bounded contexts identificados

### Deliverables
```
00-doc-ddd/03-ux-design/
├── UXD-01-User-Flows.md
├── UXD-02-Wireframes.md
└── UXD-03-Component-Library.md
```

### Exemplo de Invocação
```
"UXD, crie user flows para as jornadas principais"
"UXD, adicione wireframe para dashboard de risco"
"UXD, processe FEEDBACK-005"
```

### Especificação Completa
`.agents/20-UXD - User Experience Designer.xml`

---

## 15 - DE (Domain Engineer)

### Objetivo
Modelar domínio tático usando padrões DDD (NÃO implementa código).

### Responsabilidades
- Modelagem tática (Aggregates, Entities, Value Objects)
- Domain Events e business rules
- Use Cases / Application Services (especificação)
- Repository interfaces (contratos)
- Integration contracts entre BCs

### Quando Executa
- **Discovery (1x):** DE-00 System-Wide Domain Overview
- **Por épico (Nx):** DE-01-[EpicName]-Domain-Model

### Escopo
- **Discovery:** Sistema completo (high-level)
- **Iteration:** Múltiplos BCs do épico (detalhado)

### Deliverables
```
00-doc-ddd/04-tactical-design/
├── DE-00-System-Wide-Domain-Overview.md  (Discovery - 1x)
└── DE-01-[EpicName]-Domain-Model.md      (Per epic - Nx)
```

### Exemplo de Invocação
```
"DE, crie overview do sistema completo (DE-00)"
"DE, modele épico 'Criar Estratégia' nos BCs Strategy + Market Data"
"DE, crie feedback para SDA sobre evento faltante"
```

### Especificação Completa
`.agents/15-DE - Domain Engineer.xml`

---

## 25 - GM (GitHub Manager)

### Objetivo
Integrar workflow DDD com GitHub para rastreabilidade épico → issues.

### Responsabilidades
- Setup GitHub inicial (labels, milestones, templates)
- Criar issues por épico
- Manter sincronização épicos ↔ issues
- CI/CD Pipeline (GitHub Actions)
- Security scanning (Dependabot, CodeQL)
- Branch strategy e protection

### Quando Executa
- **Setup:** 1x no início
- **Issues:** Após cada épico ser definido por SDA

### Escopo
**Sistema completo** - rastreabilidade de todos épicos

### Deliverables
```
00-doc-ddd/07-github-management/
└── GM-01-GitHub-Setup.md

.github/
├── ISSUE_TEMPLATE/
├── PULL_REQUEST_TEMPLATE/
└── workflows/

03-github-manager/  (scripts opcionais)
```

### Exemplo de Invocação
```
"GM, configure GitHub para o projeto"
"GM, crie issues para épico 'Criar Estratégia'"
```

### Especificação Completa
`.agents/25-GM - GitHub Manager.xml`

---

## 30 - PE (Platform Engineer)

### Objetivo
Construir infraestrutura production-ready com observabilidade, disaster recovery e deploy automatizado.

### Responsabilidades
- Infrastructure as Code (Terraform, Bicep, CloudFormation)
- Container orchestration (Docker Swarm, Kubernetes)
- Observability stack (Prometheus, Grafana, Jaeger/OpenTelemetry)
- Logging centralizado (ELK Stack, CloudWatch, Azure Monitor)
- Disaster Recovery (backup automation, RTO/RPO compliance)
- CI/CD production-grade (blue-green, canary deployments)
- Secrets management (HashiCorp Vault, AWS Secrets Manager)
- Network security (VPC, Security Groups, WAF)
- Auto-scaling policies e performance monitoring

### Quando Executa
- **Setup:** 1x no início (infrastructure design)
- **Continuous:** Evoluindo infra conforme épicos avançam

### Escopo
**Sistema completo** - infraestrutura suporta todos bounded contexts

### Deliverables
```
00-doc-ddd/08-platform-engineering/
├── PE-01-Infrastructure-Design.md
├── PE-02-Observability-Strategy.md
├── PE-03-DR-Plan.md
└── PE-04-Production-Deployment.md

.terraform/  (IaC modules)
monitoring/  (Prometheus, Grafana configs)
.github/workflows/cd-production.yml
```

### Exemplo de Invocação
```
"PE, crie infrastructure design completo (AWS/Azure/GCP)"
"PE, configure observability stack (Prometheus + Grafana + Jaeger)"
"PE, implemente blue-green deployment para produção"
```

### Especificação Completa
`.agents/30-PE - Platform Engineer.xml`

---

## 35 - SEC (Security Specialist)

### Objetivo
Garantir segurança e compliance desde o início: threat modeling, pentesting, incident response.

### Responsabilidades
- Threat Modeling (STRIDE, PASTA, Attack Trees)
- Security Architecture Review (Zero-trust, Defense in Depth)
- Compliance Management (LGPD, SOC2, PCI-DSS, CVM/SEC)
- Penetration Testing (OWASP Top 10, business logic vulnerabilities)
- Vulnerability Management (SAST, DAST, dependency scanning)
- Incident Response Planning (detection, containment, recovery)
- Security Monitoring (SIEM integration, alerting)
- Secure coding guidance (input validation, encryption, secrets management)

### Quando Executa
- **Setup:** 1x no início (threat model, security architecture)
- **Continuous:** Pentesting, compliance audits, incident drills

### Escopo
**Sistema completo** - segurança transversal a todos BCs

### Deliverables
```
00-doc-ddd/09-security/
├── SEC-01-Threat-Model.md
├── SEC-02-Security-Architecture.md
├── SEC-03-Compliance-Report.md
├── SEC-04-Pentest-Report.md
└── SEC-05-Incident-Response-Plan.md
```

### Exemplo de Invocação
```
"SEC, execute threat modeling completo (STRIDE por BC)"
"SEC, configure security architecture (Zero-Trust + Defense in Depth)"
"SEC, execute penetration test (OWASP Top 10)"
"SEC, documente compliance LGPD + SOC2"
```

### Especificação Completa
`.agents/35-SEC - Security Specialist.xml`

---

## 45 - SE (Software Engineer)

### Objetivo
Implementar backend completo baseado no modelo de domínio do DE.

### Responsabilidades
- Implementação domain layer (Aggregates do DE-01)
- Implementação application layer (Use Cases do DE-01)
- Implementação infrastructure layer (Repositories, EF Migrations)
- APIs REST/GraphQL (Controllers, DTOs, OpenAPI)
- Testes unitários básicos (≥70% coverage domain layer)

### Quando Executa
**Por épico** - após DE criar DE-01-[EpicName]-Domain-Model.md

### Escopo
**Múltiplos BCs do épico** - implementa completamente o modelo especificado pelo DE

### Deliverables
```
02-backend/
├── src/Domain/           (Aggregates, Entities, Value Objects)
├── src/Application/      (Use Cases, Commands, Queries, Handlers)
├── src/Infrastructure/   (Repositories, EF Migrations, DB Context)
├── src/Api/              (REST Controllers, DTOs, OpenAPI/Swagger)
└── tests/unit/           (Domain layer tests ≥70% coverage)

00-doc-ddd/04-tactical-design/
└── SE-01-[EpicName]-Implementation-Report.md  (opcional, para rastreabilidade)
```

### Exemplo de Invocação
```
"SE, implemente domain layer do épico 'Criar Estratégia'"
"SE, crie APIs REST para o épico 'Calcular Greeks'"
"SE, adicione testes unitários para aggregate Strategy"
"SE, crie feedback para DE sobre invariante ambígua"
```

### Especificação Completa
`.agents/45-SE - Software Engineer.xml`

---

## 50 - DBA (Database Administrator)

### Objetivo
Validar e otimizar schema database criado pelo DE.

### Responsabilidades LIGHTWEIGHT (vs versão anterior)
- **Validação** de schema criado por DE
- Indexing strategy
- Query optimization
- Performance review
- Guidance para DE ajustar schema

### Quando Executa
**Por épico** - após DE criar schema

### Escopo
**Múltiplos BCs do épico** - valida schema coordenado entre BCs

### Deliverables
```
00-doc-ddd/05-database-design/
└── DBA-01-[EpicName]-Schema-Review.md
```

### Exemplo de Invocação
```
"DBA, revise schema do épico 'Criar Estratégia'"
"DBA, sugira indexes para query de Greeks"
"DBA, processe FEEDBACK-007"
```

### Especificação Completa
`.agents/50-DBA - Database Administrator.xml`

---

## 55 - FE (Frontend Engineer)

### Objetivo
Implementar interfaces de usuário seguindo specs do UXD.

### Responsabilidades EXPANDIDAS (vs versão anterior)
- Implementação de componentes UI
- **Skeleton frontend** (estrutura de projeto)
- State management
- API integration (backend)
- Responsividade e acessibilidade
- **Testes unitários básicos de componentes**

### Quando Executa
**Por épico** - iterativo, paralelo ao DE

### Escopo
**Features transversais do épico** - UI que integra múltiplos BCs

### Deliverables
```
01-frontend/
├── src/components/
├── src/pages/
├── src/services/
└── tests/
```

### Exemplo de Invocação
```
"FE, implemente UI do épico 'Criar Estratégia'"
"FE, crie componente de visualização de Greeks"
"FE, crie feedback para UXD sobre wireframe dashboard"
```

### Especificação Completa
`.agents/55-FE - Frontend Engineer.xml`

---

## 60 - QAE (Quality Assurance Engineer)

### Objetivo
Garantir qualidade através de testes integrados e end-to-end.

### Responsabilidades
- Estratégia de testes (definida 1x no início)
- **Expandir** testes unitários de DE/FE (casos avançados)
- **Integration tests** (entre BCs, APIs)
- **E2E tests** (user journeys completas)
- Performance tests (básicos)
- Test automation + CI/CD integration

### Quando Executa
**Contínuo** - estratégia no início, testes por épico

### Escopo
**Por épico** - testa funcionalidade completa transversal

### Deliverables
```
00-doc-ddd/06-quality-assurance/
└── QAE-01-Test-Strategy.md  (1x no início)

02-backend/tests/
└── integration/

01-frontend/tests/
└── e2e/
```

### Exemplo de Invocação
```
"QAE, crie estratégia de testes do projeto"
"QAE, implemente integration tests do épico 'Criar Estratégia'"
"QAE, crie E2E test para user journey completa"
```

### Especificação Completa
`.agents/60-QAE - Quality Assurance Engineer.xml`

---

## 🔄 Interações Entre Agents

### Discovery Phase (SDA → DE-00 → UXD → GM + PE + SEC)
```
SDA produz: BCs + Context Map + Épicos + UL
    ↓
DE produz: DE-00 (Aggregates high-level, Value Objects, Domain Events, Sensitive Data)
    ↓
UXD consome: BCs + DE-00 para criar user flows e wireframes detalhados
    ↓
GM consome: Épicos para criar issues
    ↓
PE consome: DE-00 para Infrastructure Design (estimativas de carga)
    ↓
SEC consome: DE-00 para Threat Modeling (STRIDE per BC + sensitive data)
```

### Iteration Phase (DE-01 → SE + DBA, FE || QAE + PE/SEC)
```
DE modela detalhado (DE-01)
    ↓
SE implementa backend
    ├─→ Domain layer
    ├─→ Application layer
    ├─→ Infrastructure layer
    ├─→ API layer
    └─→ Unit tests
    ↓
DBA valida schema (EF migrations)
    ↓
SE ajusta se necessário

Em paralelo:
FE implementa UI (usando APIs do SE)
    ↓
QAE testa integração SE + FE
    ├─→ Integration tests
    └─→ E2E tests

Continuous (per epic):
PE: Deploy automation, observability dashboards
SEC: Pentest, vulnerability scanning
```

### Feedback Loops
```
Qualquer agente pode criar FEEDBACK para outro:
- DE → SDA (evento faltante)
- FE → UXD (wireframe inconsistente)
- QAE → DBA (performance de query)
- PE → DE (API needs health check endpoint)
- SEC → PE (WAF rule missing for SQL injection)
- SEC → DE (Input validation missing in endpoint)
- etc.
```

---

## 📋 Templates por Agente

| Agente | Templates |
|-------|-----------|
| SDA | 3 templates (Event-Storming, Context-Map, Ubiquitous-Language) |
| UXD | 3 templates (User-Flows, Wireframes, Component-Library) |
| DE | 2 templates (System-Overview, Epic-Domain-Model) |
| SE | 1 template (Implementation-Report - opcional) |
| DBA | 1 template (Schema-Review) |
| FE | 0 (código é documentação) |
| QAE | 1 template (Test-Strategy) |
| GM | 1 template (GitHub-Setup) |
| PE | 4 templates (Infrastructure, Observability, DR, Deployment) |
| SEC | 5 templates (Threat-Model, Security-Architecture, Compliance, Pentest, Incident-Response) |
| Todos | 1 template compartilhado (FEEDBACK) |

---

## 🎯 Agentes Opcionais (Quando Adicionar)

**NOTA:** PE e SEC agora são **CORE AGENTS** (incluídos nos 10 agentes desde dia 1 para projetos production-ready).

### SE - Software Engineer (Architect)
**Quando:**
- Time 10+ pessoas
- Múltiplos squads em BCs diferentes
- Complexidade arquitetural alta
- Necessidade de governance central

### BE - Backend Developer (separado de DE)
**Quando:**
- Separar modelagem de implementação
- Time grande com especialização
- DE foca em design, BE em código

---

## 📚 Referências

- **Workflow Geral:** [00-Workflow-Guide.md](00-Workflow-Guide.md)
- **Nomenclatura:** [02-Nomenclature-Standards.md](02-Nomenclature-Standards.md)
- **Especificações XML:** `.agents/10-SDA.xml` até `.agents/60-QAE.xml`
- **Templates:** `.agents/templates/`

---

**Versão:** 2.1
**Data:** 2025-10-08
**Agents:** 10 agents especializados (production-ready)
