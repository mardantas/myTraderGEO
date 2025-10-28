<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# PE-04: Production Deployment

**Projeto:** [NOME-DO-PROJETO]  
**Data:** [DATA]  
**Platform Engineer:** [NOME]  
**Versão:** 1.0  

---

## 🎯 Objetivo

Configurar deploy production-ready com zero downtime: **Blue-Green** ou **Canary** deployment + **Rollback** automatizado.

---

## 🔵🟢 Blue-Green Deployment Strategy

### Conceito

```
┌─────────────────┐
│  Load Balancer  │
└────────┬────────┘
         │
    ┌────┴─────┐
    │          │
┌───▼──┐   ┌──▼───┐
│ BLUE │   │GREEN │
│(v1.0)│   │(v1.1)│
└──────┘   └──────┘

1. Deploy GREEN (v1.1) paralelo ao BLUE (v1.0)
2. Test GREEN com smoke tests
3. Switch LB: BLUE → GREEN
4. Monitor por 30 min
5. Se OK: destroy BLUE
6. Se FALHA: rollback (LB → BLUE)
```

### Kubernetes Implementation

```yaml
# kubernetes/deployment-blue.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api-blue
  labels:
    app: backend-api
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend-api
      version: blue
  template:
    metadata:
      labels:
        app: backend-api
        version: blue
    spec:
      containers:
      - name: api
        image: [REGISTRY]/backend-api:v1.0.0
        ports:
        - containerPort: 8080

---
# kubernetes/deployment-green.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api-green
  labels:
    app: backend-api
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend-api
      version: green
  template:
    metadata:
      labels:
        app: backend-api
        version: green
    spec:
      containers:
      - name: api
        image: [REGISTRY]/backend-api:v1.1.0  # Nova versão
        ports:
        - containerPort: 8080

---
# kubernetes/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-api
spec:
  selector:
    app: backend-api
    version: blue  # Switch para "green" quando deployar
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

---

## 🚀 Deployment Pipeline (GitHub Actions)

```yaml
# .github/workflows/cd-production.yml
name: Deploy to Production (Blue-Green)

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Build and Push Docker Image
      run: |
        docker build -t [REGISTRY]/backend-api:${{ github.sha }} .
        docker push [REGISTRY]/backend-api:${{ github.sha }}

    - name: Configure kubectl
      run: |
        aws eks update-kubeconfig --name [project]-production

    - name: Deploy GREEN (new version)
      run: |
        # Update image in green deployment
        kubectl set image deployment/backend-api-green \
          api=[REGISTRY]/backend-api:${{ github.sha }} \
          -n production

        # Wait for rollout
        kubectl rollout status deployment/backend-api-green -n production

    - name: Smoke Tests (GREEN environment)
      run: |
        # Get GREEN pod IP
        POD_IP=$(kubectl get pod -l version=green -n production \
          -o jsonpath='{.items[0].status.podIP}')

        # Test health endpoint
        curl -f http://$POD_IP:8080/health || exit 1

        # Test critical endpoints
        curl -f http://$POD_IP:8080/api/v1/orders || exit 1

    - name: Switch Traffic (BLUE → GREEN)
      run: |
        # Update service selector
        kubectl patch service backend-api -n production \
          -p '{"spec":{"selector":{"version":"green"}}}'

        echo "Traffic switched to GREEN"

    - name: Monitor for 5 minutes
      run: |
        # Watch for errors
        for i in {1..10}; do
          ERROR_RATE=$(curl -s http://[METRICS-ENDPOINT]/error_rate)
          if (( $(echo "$ERROR_RATE > 0.05" | bc -l) )); then
            echo "Error rate too high: $ERROR_RATE"
            exit 1
          fi
          sleep 30
        done

    - name: Cleanup OLD (BLUE)
      if: success()
      run: |
        kubectl scale deployment/backend-api-blue --replicas=0 -n production
        echo "BLUE deployment scaled down"

    - name: Rollback (if failure)
      if: failure()
      run: |
        # Switch back to BLUE
        kubectl patch service backend-api -n production \
          -p '{"spec":{"selector":{"version":"blue"}}}'

        echo "ROLLED BACK to BLUE"
```

---

## 🐤 Canary Deployment (Alternative)

### Strategy: Gradual Rollout

```
1. Deploy v1.1 com 10% do tráfego
2. Monitor por 30 min
3. Se OK: aumenta para 50%
4. Monitor por 30 min
5. Se OK: aumenta para 100%
6. Se FALHA em qualquer etapa: rollback
```

### Istio/Linkerd Implementation

```yaml
# kubernetes/virtual-service.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend-api
spec:
  hosts:
  - backend-api
  http:
  - match:
    - uri:
        prefix: /api
    route:
    - destination:
        host: backend-api
        subset: v1
      weight: 90  # 90% para versão antiga
    - destination:
        host: backend-api
        subset: v2
      weight: 10  # 10% para nova versão (canary)
```

---

## 🔙 Rollback Procedures

### Automated Rollback (CI/CD)

```bash
# Rollback via kubectl
kubectl rollout undo deployment/backend-api-green -n production

# Ou switch service selector
kubectl patch service backend-api -n production \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

### Manual Rollback (Emergency)

```bash
# 1. Identify last known good version
kubectl rollout history deployment/backend-api-green -n production

# 2. Rollback to specific revision
kubectl rollout undo deployment/backend-api-green \
  --to-revision=5 -n production

# 3. Verify
kubectl rollout status deployment/backend-api-green -n production
```

---

## 📊 Health Checks & Readiness

### Liveness Probe (Is app alive?)

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3
```

### Readiness Probe (Is app ready for traffic?)

```yaml
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 3
```

### Health Check Implementation (.NET)

```csharp
// Program.cs
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>("database")
    .AddUrlGroup(new Uri("https://external-api.com/health"), "external-api");

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false  // Liveness: always healthy if app is running
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Name == "database" || check.Name == "external-api"
});
```

---

## 🧪 Smoke Tests (Post-Deployment)

```bash
#!/bin/bash
# scripts/smoke-tests.sh

API_URL="https://app.[YOUR-DOMAIN]"

echo "Running smoke tests..."

# Test 1: Health check
curl -f $API_URL/health || { echo "Health check failed"; exit 1; }

# Test 2: Authentication
curl -f -X POST $API_URL/api/v1/auth/login \
  -d '{"email":"test@example.com","password":"test123"}' || exit 1

# Test 3: Critical business endpoint
curl -f $API_URL/api/v1/orders?limit=1 || exit 1

echo "✅ All smoke tests passed"
```

---

## ✅ Definition of Done

- [ ] Blue-Green deployment configurado (Kubernetes manifests)
- [ ] CD pipeline produção criado (.github/workflows/cd-production.yml)
- [ ] Smoke tests automatizados (passando)
- [ ] Rollback procedure testado (consegue voltar versão anterior)
- [ ] Health checks configurados (liveness, readiness)
- [ ] Monitoring pós-deploy (5-30 min observation window)
- [ ] Runbook de deploy documentado
- [ ] Runbook de rollback documentado
- [ ] PE-checklist.yml completo

---

**Checklist de Deploy Produção:**  

- [ ] 1. Deploy GREEN (nova versão)
- [ ] 2. Smoke tests (GREEN isolado)
- [ ] 3. Switch traffic (BLUE → GREEN)
- [ ] 4. Monitor por 30 min (erro < 1%, latência OK)
- [ ] 5. Se OK: destroy BLUE
- [ ] 6. Se FALHA: rollback (GREEN → BLUE)
- [ ] 7. Post-mortem (se houver rollback)
