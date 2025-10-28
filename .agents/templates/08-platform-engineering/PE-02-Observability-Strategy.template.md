<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# PE-02: Observability Strategy

**Projeto:** [NOME-DO-PROJETO]  
**Data:** [DATA]  
**Platform Engineer:** [NOME]  
**Versão:** 1.0  

---

## 🎯 Objetivo

Implementar observability completa: **Metrics, Logs, Traces** (3 pilares) + **Alerting** + **Dashboards**.

---

## 📊 Stack de Observability

### Metrics: Prometheus + Grafana
```yaml
# monitoring/prometheus-config.yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
    - role: pod
    relabel_configs:
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
```

### Logs: ELK Stack / CloudWatch / Azure Monitor
```yaml
# Fluentd/Fluent Bit para agregação
# Elasticsearch para armazenamento
# Kibana para visualização
```

### Traces: Jaeger / OpenTelemetry
```yaml
# OpenTelemetry Collector
receivers:
  otlp:
    protocols:
      grpc:
      http:

exporters:
  jaeger:
    endpoint: jaeger-collector:14250
```

---

## 📈 Métricas Chave (Golden Signals)

| Métrica | Threshold | Alerta |
|---------|-----------|--------|
| **Latency** | p95 < 200ms | >500ms = warning, >1s = critical |
| **Traffic** | - | Spike >200% = investigate |
| **Errors** | <1% error rate | >5% = critical |
| **Saturation** | CPU <70%, Memory <80% | >90% = critical |

---

## 🔔 Alerting

### AlertManager Rules
```yaml
groups:
- name: backend_alerts
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value | humanizePercentage }}"

  - alert: HighLatency
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5
    for: 5m
    labels:
      severity: warning
```

### Integration: PagerDuty / Opsgenie
```yaml
receivers:
- name: 'pagerduty'
  pagerduty_configs:
  - service_key: [SERVICE_KEY]
```

---

## 📊 Grafana Dashboards

### Dashboard 1: Application Overview
- Requests/sec (RPS)
- p50, p95, p99 Latency
- Error rate
- Active users

### Dashboard 2: Infrastructure
- CPU usage (by pod)
- Memory usage
- Network I/O
- Disk I/O

### Dashboard 3: Business Metrics
- Orders created/hour
- Payment success rate
- User signups

---

## ✅ Definition of Done

- [ ] Prometheus coletando métricas de todos pods
- [ ] Grafana dashboards criados (Application, Infra, Business)
- [ ] Logs centralizados (ELK/CloudWatch) funcionando
- [ ] Distributed tracing (Jaeger) configurado
- [ ] Alerting (AlertManager + PagerDuty) testado
- [ ] SLOs documentados (p95 latency, error rate, availability)
- [ ] PE-checklist.yml completo
