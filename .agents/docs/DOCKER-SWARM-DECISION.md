# Decisão Arquitetural: Docker Swarm vs Kubernetes

**Data:** 2025-10-06
**Decisão:** Docker Swarm como padrão para projetos pequenos/médios

---

## 🎯 Contexto

Workflow DDD v2.0 precisa definir stack de orquestração de containers para projetos production-ready.

**Perfil dos projetos:**
- Production-ready desde o início
- Tamanho: Pequeno/Médio (2-20 serviços)
- Time: 1-5 desenvolvedores
- Orçamento: Limitado/Moderado
- Servidor: Contabo VPS (1-2 servidores inicialmente)

---

## ⚖️ Análise Comparativa

### Docker Swarm ✅ ESCOLHIDO

**Vantagens:**
- ✅ **Simplicidade brutal** - aprende em 1 dia vs 1 semana (K8s)
- ✅ **Setup 10 minutos** - `docker swarm init` vs 1h+ (K8s)
- ✅ **Menor overhead** - roda bem com 3 nodes pequenos (t3.medium)
- ✅ **Docker Compose compatível** - `docker stack deploy -c docker-compose.yml`
- ✅ **Secrets nativo** - `docker secret create`
- ✅ **Rolling updates simples** - `docker service update`
- ✅ **Menor custo** - ~$60/mês (3 VMs t3.medium) vs ~$200/mês (K8s)
- ✅ **Menor manutenção** - quase zero overhead operacional

**Desvantagens:**
- ❌ Menos features avançadas (auto-scaling via script, não nativo)
- ❌ Ecossistema menor (menos integrações)
- ❌ Comunidade menor que Kubernetes

**Casos de uso ideais:**
- Projetos pequenos/médios (2-20 serviços)
- Time pequeno (1-5 desenvolvedores)
- Orçamento limitado
- **Nosso perfil: Production-ready, mas não enterprise**

---

### Kubernetes ⚠️ OVERKILL para maioria dos projetos

**Vantagens:**
- ✅ **Industry standard** (99% das empresas grandes)
- ✅ **Auto-scaling robusto** (HPA, VPA, cluster autoscaling)
- ✅ **Ecossistema gigante** (Helm, Istio, Argo CD)
- ✅ **Multi-cloud fácil** (EKS, AKS, GKE)

**Desvantagens:**
- ❌ **Complexidade alta** - curva de aprendizado íngreme
- ❌ **Custo maior** - mínimo 3 control-plane nodes (~$200/mês)
- ❌ **Overhead operacional** - precisa de time dedicado (>10 devs)

**Casos de uso ideais:**
- Empresas grandes (>50 serviços)
- Time grande (>10 desenvolvedores)
- Requisitos enterprise (multi-tenancy, compliance rigoroso)

---

## 📋 Decisão Final

### Docker Swarm como Padrão

**Motivos:**
1. **Maioria dos projetos pequenos/médios** não precisa da complexidade de Kubernetes
2. **Custo 3x menor** - orçamento limitado é realidade
3. **Time to market** - setup em 1 dia vs 1 semana
4. **Manutenção zero** - time pequeno não pode ter overhead operacional
5. **Conceitos transferíveis** - se crescer, migração para K8s é direta (conceitos são os mesmos: services, replicas, health checks)

### Kubernetes como Opcional

**Quando usar:**
- Projeto cresceu >20 serviços
- Time cresceu >10 desenvolvedores
- Requisitos enterprise (multi-tenancy, compliance ISO27001/SOC2 Type II)
- Budget permite ($200+/mês de infra)

---

## 🔄 Impacto nas Templates

### Templates Atualizados

**PE-01-Infrastructure-Design.template.md:**
- ✅ Docker Swarm como padrão (docker-stack.yml)
- ✅ Terraform com EC2 instances (não EKS)
- ✅ Swarm cluster (1 manager + 3 workers)
- ⚠️ Kubernetes mantido como referência opcional

**PE-04-Production-Deployment.template.md:**
- ✅ Blue-Green deployment com Docker Swarm
- ✅ Rolling updates: `docker service update`
- ✅ Rollback: `docker service rollback`

**PE-checklist.yml:**
- ✅ Checks atualizados para Docker Swarm
- ✅ `docker node ls` (não `kubectl get nodes`)
- ✅ `docker-stack.yml` versionado
- ✅ Overlay networks configuradas

**80-PE.xml:**
- ✅ Responsabilidade atualizada: "Docker Swarm - RECOMENDADO"

---

## 📚 Conceitos Transferíveis (Swarm → K8s)

Se no futuro precisar migrar para Kubernetes, os conceitos são os mesmos:

| Docker Swarm | Kubernetes | Conceito |
|--------------|------------|----------|
| `docker service` | `Deployment` | Definição de app |
| `replicas: 3` | `replicas: 3` | Escala horizontal |
| `docker stack` | `Helm chart` | Bundle de serviços |
| `overlay network` | `Service mesh` | Networking |
| `docker secret` | `Secret` | Secrets management |
| `healthcheck` | `livenessProbe` | Health monitoring |
| `update_config` | `RollingUpdate` | Deploy strategy |

**Migração:** 80% do docker-stack.yml pode ser convertido automaticamente para K8s manifests com [kompose](https://kompose.io/).

---

## ✅ Aprovação

**Status:** ✅ APROVADO
**Decisão:** Docker Swarm como padrão para workflow DDD v2.0
**Responsável:** Platform Engineer (PE)
**Data:** 2025-10-06

---

**Próximos Passos:**
1. ✅ Templates PE atualizados
2. ✅ Checklist PE atualizado
3. ✅ Agent spec (80-PE.xml) atualizado
4. 📝 Criar exemplo completo docker-stack.yml (PE-04 template)
5. 📝 Documentar migração Swarm → K8s (quando crescer)
