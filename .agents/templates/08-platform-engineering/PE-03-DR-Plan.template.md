# PE-03: Disaster Recovery Plan

**Projeto:** [NOME-DO-PROJETO]
**Data:** [DATA]
**Platform Engineer:** [NOME]
**Versão:** 1.0

---

## 🎯 Objetivo

Garantir continuidade do negócio com backup automatizado, restore testado e RTO/RPO definidos.

---

## 📋 RTO/RPO Targets

| Resource | RTO (Recovery Time) | RPO (Recovery Point) | Backup Frequency |
|----------|---------------------|----------------------|------------------|
| **Production Database** | 1 hora | 15 minutos | Daily full + 15min incremental |
| **Application State** | 30 minutos | Stateless (zero data loss) | N/A (containers) |
| **Object Storage** | 2 horas | 24 horas | Daily snapshot |
| **Configuration** | 15 minutos | Versioned (git) | Continuous (IaC) |

---

## 💾 Backup Strategy

### Database Backup (Automated)

```bash
# AWS RDS Automated Backups
resource "aws_db_instance" "main" {
  backup_retention_period = 30  # 30 dias
  backup_window          = "03:00-04:00"  # UTC
  preferred_backup_window = true

  # Point-in-time restore enabled
  enabled_cloudwatch_logs_exports = ["postgresql"]
}

# Cross-region backup replication
resource "aws_db_instance_automated_backups_replication" "default" {
  source_db_instance_arn = aws_db_instance.main.arn
  retention_period       = 7
}
```

### Application Backup

```yaml
# Velero (Kubernetes backup)
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-backup
  namespace: velero
spec:
  schedule: "0 1 * * *"  # 1 AM daily
  template:
    includedNamespaces:
    - production
    storageLocation: aws-us-east-1
    volumeSnapshotLocations:
    - aws-us-east-1
```

---

## 🔄 Restore Procedures

### Database Restore

```bash
# Restore from automated backup
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier [project]-production-restored \
  --db-snapshot-identifier [snapshot-id]

# Point-in-time restore (para RPO < 30 dias)
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier [project]-production \
  --target-db-instance-identifier [project]-production-restored \
  --restore-time 2025-10-06T10:30:00Z
```

### Application Restore

```bash
# Restore from Velero backup
velero restore create --from-backup daily-backup-20251006
```

---

## 🧪 DR Drill (Monthly Test)

### Checklist de DR Drill

**Frequência:** Mensal (primeira sexta-feira do mês)
**Duração:** 2-3 horas
**Responsável:** Platform Engineer + DBA

#### Passos:

1. **Simulate Failure (Non-Production)**
   ```bash
   # Delete staging database (simulated failure)
   kubectl delete pvc postgres-data-staging
   ```

2. **Execute Restore**
   ```bash
   # Restore from backup (measure time)
   time aws rds restore-db-instance-from-db-snapshot ...
   ```

3. **Validate Recovery**
   ```bash
   # Check data integrity
   psql -h [restored-db] -c "SELECT COUNT(*) FROM orders;"

   # Check application connectivity
   kubectl exec -it backend-pod -- curl http://localhost/health
   ```

4. **Document Results**
   - ✅ RTO achieved: [X] minutos (target: 60 min)
   - ✅ RPO achieved: [Y] minutos (target: 15 min)
   - ❌ Issues found: [listar problemas]
   - 📝 Improvements: [ações de melhoria]

---

## 🚨 Incident Response (Disaster Scenarios)

### Scenario 1: Database Corruption

**Detection:** Query errors, data inconsistency alerts
**Response:**
1. Stop writes to database (read-only mode)
2. Identify last known good backup
3. Restore from backup to new instance
4. Validate data integrity
5. Switch DNS/connection string to restored instance
6. Resume writes

**Post-Incident:**
- Root cause analysis
- Update backup strategy if needed

---

### Scenario 2: Entire Region Failure (AWS/Azure/GCP)

**Detection:** Multiple availability zone failures
**Response:**
1. Failover to secondary region (if multi-region)
2. Or restore from cross-region backup
3. Update DNS to point to new region
4. Communicate downtime to users

**Post-Incident:**
- Implement multi-region if not exists
- Review RTO/RPO targets

---

## 📊 Backup Monitoring

### CloudWatch Alarms (AWS)

```yaml
resource "aws_cloudwatch_metric_alarm" "backup_failure" {
  alarm_name          = "[project]-backup-failure"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BackupRetentionPeriodStorageUsed"
  namespace           = "AWS/RDS"
  period              = "3600"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert if no backups in last 24h"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

---

## ✅ Definition of Done

- [ ] Backup automatizado configurado (DB, app, storage)
- [ ] RTO documentado e testado (≤ 1 hora)
- [ ] RPO documentado e testado (≤ 15 minutos)
- [ ] Cross-region backup habilitado (se multi-region)
- [ ] DR drill agendado (mensal) e executado com sucesso
- [ ] Runbooks de restore criados e validados
- [ ] Backup monitoring/alerting configurado
- [ ] PE-checklist.yml completo

---

**Próximos Passos:**
1. PE-04: Configurar Production Deployment (Blue-Green)
2. Executar primeiro DR drill
3. Documentar lições aprendidas
