<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)  
- Use blank lines between sections for readability (content)  
- Validate in Markdown preview before committing  
-->

# PE-02 - Scaling Strategy & Future Growth

**Agent:** PE (Platform Engineer)  
**Phase:** Discovery (1x) - Strategic Planning  
**Scope:** Future growth beyond Docker Compose - NOT for v1.0 implementation  
**Version:** 4.0 (Split from PE-00-Environments-Setup)  

---

## 📋 Metadata

- **Project Name:** [PROJECT_NAME]  
- **Created:** [DATE]  
- **PE Engineer:** [NAME]  
- **Target:** Strategic planning for scaling beyond 1k users  
- **Status:** Reference only - implement when needed  

---

## 🎯 Objetivo

Plan your **future scaling path** from Docker Compose to Managed Cloud or Kubernetes. This guide helps you decide **when and how** to scale your infrastructure as your project grows.

**Foundation:** Start with [PE-00-Quick-Start.md](./PE-00-Quick-Start.md) and [PE-01-Server-Setup.md](./PE-01-Server-Setup.md)  
**Implementation:** Do NOT implement this until you hit growth thresholds below  

---

## 📈 Scaling Decision Matrix

**When to scale?** Use this matrix to decide when to move from simple Docker Compose to more complex infrastructure.

| Users | Uptime SLA | Cost Budget | Infrastructure Recommendation |
|-------|-----------|-------------|-------------------------------|
| <1k | 95% | Low ($50-200/mo) | **Single VPS + Docker Compose** (current setup) |
| 1k-10k | 99% | Medium ($200-1k/mo) | **Managed Cloud (AWS ECS, Azure Container Instances)** |
| 10k-50k | 99.9% | High ($1k-5k/mo) | **Kubernetes (EKS, AKS, GKE)** |
| >50k | 99.95%+ | Very High (>$5k/mo) | **Full Enterprise Stack (K8s + Multi-Region + CDN)** |

---

## 🚀 Migration Path 1: Managed Cloud (RECOMMENDED for 1k-10k users)

### Overview

**Target:** AWS ECS Fargate, Azure Container Instances, or Google Cloud Run  
**Timeline:** 1-2 weeks  
**Complexity:** Low  
**When:** You hit 1k active users OR need 99%+ uptime SLA  

### Why Managed Cloud?

- ✅ **No server management** (fully managed)  
- ✅ **Auto-scaling out of the box** (CPU/memory-based)  
- ✅ **Built-in load balancing** (AWS ALB, Azure Application Gateway, Cloud Load Balancer)  
- ✅ **Pay-per-use pricing** (cost-effective for variable workloads)  
- ✅ **99.9% SLA guaranteed** (cloud provider SLA)  
- ✅ **Easy migration** from Docker Compose (containers already working)  

### Migration Steps

1. **Containerize** (already done via Docker Compose in PE-00/PE-01)
2. **Push images to cloud registry**:
   - AWS: Amazon ECR (Elastic Container Registry)  
   - Azure: Azure Container Registry (ACR)  
   - GCP: Google Container Registry (GCR)  

3. **Create managed database**:
   - AWS: Amazon RDS for PostgreSQL  
   - Azure: Azure Database for PostgreSQL  
   - GCP: Cloud SQL for PostgreSQL  

4. **Deploy containers to managed service**:
   - **AWS:** ECS Fargate with Application Load Balancer  
   - **Azure:** Container Instances with Application Gateway  
   - **GCP:** Cloud Run with Cloud Load Balancing  

5. **Configure auto-scaling** (CPU/memory-based policies)

6. **Set up monitoring**:
   - AWS: CloudWatch  
   - Azure: Azure Monitor  
   - GCP: Cloud Logging + Cloud Monitoring  

### AWS ECS Fargate Example

**Task Definition** (`ecs-task-definition.json`):

```json
{
  "family": "[project]-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "api",
      "image": "[AWS_ACCOUNT_ID].dkr.ecr.[REGION].amazonaws.com/[project]-api:latest",
      "portMappings": [{"containerPort": 5000, "protocol": "tcp"}],
      "environment": [
        {"name": "ASPNETCORE_ENVIRONMENT", "value": "Production"},
        {"name": "DATABASE_URL", "value": "postgresql://rds-endpoint:5432/db"}
      ],
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3
      }
    }
  ]
}
```

**ECS Service with Auto-Scaling:**

```bash
# Create ECS service
aws ecs create-service \
  --cluster [project]-cluster \
  --service-name api \
  --task-definition [project]-api \
  --desired-count 2 \
  --launch-type FARGATE \
  --load-balancers targetGroupArn=[ALB_TARGET_GROUP_ARN],containerName=api,containerPort=5000

# Configure auto-scaling
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/[project]-cluster/api \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 10

# CPU-based scaling policy
aws application-autoscaling put-scaling-policy \
  --policy-name cpu-scaling \
  --service-namespace ecs \
  --resource-id service/[project]-cluster/api \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{"TargetValue":70.0,"PredefinedMetricSpecification":{"PredefinedMetricType":"ECSServiceAverageCPUUtilization"}}'
```

### Azure Container Instances Example

**ARM Template** (`container-group.json`):

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": [
    {
      "type": "Microsoft.ContainerInstance/containerGroups",
      "apiVersion": "2021-09-01",
      "name": "[project]-api",
      "location": "[parameters('location')]",
      "properties": {
        "containers": [
          {
            "name": "api",
            "properties": {
              "image": "[parameters('containerImage')]",
              "resources": {
                "requests": {"cpu": 1, "memoryInGb": 1.5}
              },
              "ports": [{"port": 5000}],
              "environmentVariables": [
                {"name": "ASPNETCORE_ENVIRONMENT", "value": "Production"},
                {"name": "DATABASE_URL", "secureValue": "[parameters('databaseUrl')]"}
              ]
            }
          }
        ],
        "osType": "Linux",
        "restartPolicy": "Always"
      }
    }
  ]
}
```

### Google Cloud Run Example

```bash
# Deploy to Cloud Run
gcloud run deploy api \
  --image gcr.io/[PROJECT_ID]/[project]-api:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars ASPNETCORE_ENVIRONMENT=Production,DATABASE_URL=[CLOUD_SQL_CONNECTION] \
  --min-instances 2 \
  --max-instances 10 \
  --cpu 1 \
  --memory 512Mi

# Auto-scaling is built-in (scales to 0 when idle, saves costs)
```

### Cost Optimization Tips

- **Use Spot/Preemptible Instances** for non-critical workloads (70% cost savings)  
- **Right-size containers** (don't over-provision CPU/memory)  
- **Scale to zero on Cloud Run** for staging environments (only pay when used)  
- **Use reserved instances** for production (30-50% discount on AWS RDS, Azure DB)  
- **Implement caching** (Redis/Memcached) to reduce database load  

---

## 🔀 Migration Path 2: Docker Swarm (SKIP - Not Recommended)

**Status:** ❌ **Skip this option entirely**  

**Why?**
- Limited adoption and ecosystem compared to Kubernetes  
- Managed cloud services (ECS, AKS, Cloud Run) provide better features and support  
- Kubernetes is the industry standard for container orchestration  

**When to use Swarm?**
- Only if you have specific constraints (air-gapped environment, government restrictions on cloud providers)  

**Recommendation:** Go straight from Docker Compose to Managed Cloud (Path 1) or Kubernetes (Path 3).  

---

## ☸️ Migration Path 3: Kubernetes (For Enterprise Scale)

### Overview

**Target:** AWS EKS, Azure AKS, Google GKE  
**Timeline:** 4-8 weeks  
**Complexity:** High  
**When:** >10k active users OR complex microservices architecture (5+ services)  

### When to Migrate to Kubernetes?

Migrate to Kubernetes ONLY if you meet **3 or more** of these criteria:

- ✅ **>10k active users** (need horizontal scaling at pod level)  
- ✅ **Need for multi-region deployment** (disaster recovery, compliance)  
- ✅ **Complex microservices** (5+ independent services)  
- ✅ **Enterprise SLA requirements** (99.9%+ uptime)  
- ✅ **Team has K8s expertise** (or budget to hire DevOps engineers)  
- ✅ **Advanced deployment strategies needed** (blue-green, canary)  
- ✅ **Service mesh requirements** (Istio, Linkerd for mTLS, traffic shaping)  

### Why Kubernetes?

- ✅ **Industry standard** (massive ecosystem, widespread adoption)  
- ✅ **Multi-cloud portability** (move between AWS/Azure/GCP easily)  
- ✅ **Advanced deployment strategies** (blue-green, canary, rolling updates)  
- ✅ **Horizontal pod autoscaling** (HPA based on CPU, memory, custom metrics)  
- ✅ **Service mesh support** (Istio, Linkerd for zero-trust networking)  
- ✅ **Declarative infrastructure** (GitOps with ArgoCD, Flux)  

### Migration Steps

1. **Set up K8s cluster** (EKS, AKS, GKE with managed node pools)
2. **Create Helm charts** for application deployment (templating, versioning)
3. **Migrate database to managed service** (AWS RDS, Azure Database, Cloud SQL)
4. **Set up Ingress controller** (NGINX, Traefik, AWS ALB Ingress Controller)
5. **Configure autoscaling**:
   - HPA (Horizontal Pod Autoscaler) for pods  
   - Cluster Autoscaler for nodes  
6. **Implement observability**:
   - Metrics: Prometheus + Grafana  
   - Logging: Loki or ELK stack  
   - Tracing: Jaeger or Zipkin  
7. **Set up CI/CD** (ArgoCD for GitOps, Flux)
8. **Configure Disaster Recovery**:
   - Velero for cluster backups  
   - Multi-region replication  

### Kubernetes Deployment Example

**Deployment Manifest** (`k8s/api-deployment.yaml`):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api  
        image: [REGISTRY]/[project]-api:latest
        ports:
        - containerPort: 5000  
        env:
        - name: DATABASE_URL  
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource  
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource  
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Best Practices for Kubernetes

**Security:**
- Use Pod Security Standards (restricted mode)  
- Enable RBAC (Role-Based Access Control)  
- Network Policies for pod-to-pod communication  
- Secret management (AWS Secrets Manager, Azure Key Vault, Google Secret Manager)  

**Reliability:**
- Pod Disruption Budgets (PDB) to ensure availability during updates  
- Resource requests and limits for predictable performance  
- Anti-affinity rules to spread pods across nodes  

**Observability:**
- Prometheus metrics exporter in all services  
- Structured logging (JSON) for easy parsing  
- Distributed tracing headers (W3C Trace Context)  

---

## 💰 Cost Comparison

| Infrastructure | Monthly Cost | Users Supported | SLA | Management Overhead | Auto-Scaling |
|----------------|-------------|-----------------|-----|---------------------|--------------|
| **Single VPS (current)** | $50-200 | <1k | 95% | Low (1-2 hrs/week) | Manual |
| **Managed Cloud (ECS/AKS/Cloud Run)** | $200-1k | 1k-10k | 99.9% | Very Low (<1 hr/week) | Automatic |
| **Kubernetes (EKS/AKS/GKE)** | $1k-5k | 10k-50k | 99.95% | Medium (4-8 hrs/week) | Automatic + Advanced |

---

## 🎯 Recommended Migration Path

### Phase 1: v1.0 - Docker Compose on VPS (0-1k users)

**Current setup** (see [PE-00-Quick-Start.md](./PE-00-Quick-Start.md) and [PE-01-Server-Setup.md](./PE-01-Server-Setup.md)):
- Get to market fast  
- Validate product-market fit  
- Keep costs low (<$200/mo)  
- 95% uptime is acceptable for early adopters  

### Phase 2: Managed Cloud (1k-10k users)

**When to migrate:**
- You consistently have >1k active users  
- Revenue justifies $500-1k/mo infrastructure cost  
- Customers demand 99%+ uptime SLA  

**Recommended platforms:**
- **AWS ECS Fargate** (best for .NET apps, mature ecosystem)  
- **Azure Container Instances** (if already on Azure, excellent integration)  
- **Google Cloud Run** (best for serverless workloads, scales to zero)  

### Phase 3: Kubernetes (>10k users)

**When to migrate:**
- You reach 10k+ active users AND have team expertise  
- Don't migrate prematurely (YAGNI principle)  
- K8s adds significant complexity (requires dedicated DevOps engineer)  

**Recommended platforms:**
- **AWS EKS** (most mature, widest ecosystem)  
- **Azure AKS** (best Azure integration, Windows containers support)  
- **Google GKE** (best Kubernetes experience, fastest updates)  

---

## 🚫 What NOT to Do in v1.0

To maintain simplicity in small/medium projects, v1.0 **DOES NOT include**:

- ❌ **Full IaC** (Terraform, Bicep, CloudFormation) - scripts are enough  
- ❌ **Observability stack** (Prometheus, Grafana, Jaeger, Loki) - cloud provider monitoring is enough  
- ❌ **Disaster Recovery Plan** (formal RTO/RPO) - database backups are enough  
- ❌ **Blue-Green deployment** - rolling updates are enough  
- ❌ **Canary deployment** - staged rollouts are enough  
- ❌ **Advanced auto-scaling policies** - basic CPU/memory scaling is enough  
- ❌ **Complex VPC/Networking** - default VPC is enough  
- ❌ **Multi-region deployment** - single region is enough  

**When to add:** When you scale to enterprise or have >100k users.  

---

## 📚 Referências

### Documentação Relacionada
- **[PE-00-Quick-Start.md](./PE-00-Quick-Start.md)** - Local development MVP (start here)  
- **[PE-01-Server-Setup.md](./PE-01-Server-Setup.md)** - Production server setup (implement this first)  

### Recursos do Projeto
- **Checklist PE:** `.agents/workflow/02-checklists/PE-checklist.yml`  
- **Agent XML:** `.agents/30-PE - Platform Engineer.xml`  
- **Workflow Guide:** `.agents/docs/00-Workflow-Guide.md`  

### External Resources
- **AWS ECS:** https://aws.amazon.com/ecs/  
- **Azure Container Instances:** https://azure.microsoft.com/en-us/products/container-instances/  
- **Google Cloud Run:** https://cloud.google.com/run  
- **Kubernetes:** https://kubernetes.io/docs/home/  

---

**Template Version:** 4.0 (Scaling Strategy)  
**Last Updated:** 2025-10-29  
**Split From:** PE-00-Environments-Setup.template.md v3.0  
**Status:** Strategic reference - implement when growth thresholds are met  
