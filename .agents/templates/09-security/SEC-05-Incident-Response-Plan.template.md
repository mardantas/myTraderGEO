<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# SEC-05: Incident Response Plan

**Projeto:** [NOME-DO-PROJETO]
**Data:** [DATA]
**Security Specialist:** [NOME]
**Versão:** 1.0

---

## 🎯 Objetivo

Plano de resposta a incidentes de segurança: **Detecção → Contenção → Erradicação → Recuperação → Post-Mortem**.

---

## 📋 Incident Classification

### Severity Levels

| Level | Impact | Examples | Response Time |
|-------|--------|----------|---------------|
| **P0 - Critical** | Data breach, system compromise | Database exposed, ransomware | Immediate (15 min) |
| **P1 - High** | Service degradation, potential breach | DDoS attack, unauthorized access attempt | 1 hour |
| **P2 - Medium** | Limited impact, no data exposure | Single user account compromised | 4 hours |
| **P3 - Low** | Minimal impact | Failed login attempts spike | 24 hours |

### Incident Types

| Type | Description | Example |
|------|-------------|---------|
| **Data Breach** | Unauthorized access to sensitive data | Database dump leaked |
| **Ransomware** | Data encrypted by attacker | Files encrypted, ransom note |
| **DDoS** | Denial of Service attack | Service unavailable (503) |
| **Unauthorized Access** | Account takeover, privilege escalation | Admin account compromised |
| **Malware** | Malicious code execution | Cryptominer on server |
| **Social Engineering** | Phishing, credentials stolen | Employee clicked phishing link |

---

## 👥 Incident Response Team

### Roles & Responsibilities

| Role | Responsibilities | Contact |
|------|------------------|---------|
| **Incident Commander** | Overall coordination, decisions | [NOME] - [PHONE] |
| **Security Lead** | Technical investigation, containment | [NOME] - [EMAIL] |
| **DevOps Lead** | Infrastructure isolation, rollback | [NOME] - [EMAIL] |
| **Legal/Compliance** | LGPD notification, legal advice | [NOME] - [EMAIL] |
| **Communications** | Customer notification, PR | [NOME] - [EMAIL] |
| **DPO (Data Protection Officer)** | ANPD notification (LGPD) | [NOME] - [EMAIL] |

### Escalation Path

```
Developer detects anomaly
    ↓
Security Lead (investigate)
    ↓
Incident Commander (if P0/P1)
    ↓
CEO + Legal (if data breach)
    ↓
ANPD + Customers (if LGPD breach)
```

---

## 🔍 Detection Mechanisms

### Automated Alerts

```yaml
# AlertManager configuration (Prometheus)
alerts:
  - name: HighFailedLoginRate
    condition: rate(failed_logins[5m]) > 10
    severity: P1
    action: Notify Security Team
    playbook: playbooks/brute-force-attack.md

  - name: UnauthorizedDatabaseAccess
    condition: db_access_from_unknown_ip == true
    severity: P0
    action: Block IP + Alert Incident Commander
    playbook: playbooks/database-breach.md

  - name: SuspiciousDataExport
    condition: data_export_rows > 10000
    severity: P1
    action: Require approval + Log to SIEM
    playbook: playbooks/data-exfiltration.md

  - name: WAFBlockSpike
    condition: rate(waf_blocks[5m]) > 100
    severity: P1
    action: Investigate IP + Consider blocking
    playbook: playbooks/ddos-attack.md
```

### Manual Detection

- [ ] Security team monitors SIEM dashboard (Splunk/Sumo Logic)
- [ ] Customer reports suspicious activity (support@[DOMAIN])
- [ ] Third-party security researcher discloses vulnerability

---

## 🚨 Incident Response Procedure

### Phase 1: Detection & Triage (0-15 min)

**Objective:** Confirm incident is real (not false positive).

```yaml
steps:
  1. Receive alert (automated or manual)
  2. Security Lead investigates:
     - Check logs (audit logs, WAF logs, DB logs)
     - Identify affected systems/users
     - Estimate impact (how many users affected?)
  3. Classify severity (P0/P1/P2/P3)
  4. If P0/P1: Escalate to Incident Commander
```

**Example: Data Breach Alert**

```bash
# Check audit logs for suspicious activity
SELECT user_id, action, ip_address, timestamp
FROM audit_logs
WHERE timestamp > NOW() - INTERVAL '1 hour'
  AND action IN ('DATA_EXPORT', 'MASS_DELETE')
ORDER BY timestamp DESC;

# Check if known attacker IP
grep "suspicious_ip" /var/log/nginx/access.log
```

---

### Phase 2: Containment (15 min - 1 hour)

**Objective:** Stop the attack, prevent further damage.

#### Immediate Actions

```yaml
- action: Isolate affected systems
  example: |
    # Block attacker IP at firewall
    aws ec2 authorize-security-group-ingress \
      --group-id sg-xxxxx \
      --protocol tcp --port 443 \
      --cidr [ATTACKER-IP]/32 \
      --revoke

- action: Revoke compromised credentials
  example: |
    # Invalidate JWT tokens
    redis-cli DEL user:123:refresh_token

    # Force password reset
    UPDATE users SET password_reset_required = true WHERE id = 123;

- action: Take snapshot (forensics)
  example: |
    # Snapshot database before changes
    aws rds create-db-snapshot \
      --db-instance-identifier [project]-prod \
      --db-snapshot-identifier incident-2025-10-05-snapshot
```

#### Communication

```markdown
**Internal Alert (Slack #security-incidents):**

🚨 INCIDENT P0: Data Breach Detected
- Severity: P0 (Critical)
- Affected: ~500 users (emails + hashed passwords exposed)
- Status: CONTAINED (attacker IP blocked)
- Next: Eradication phase (credential rotation)
- War Room: https://zoom.us/j/incident-12345
```

---

### Phase 3: Eradication (1-4 hours)

**Objective:** Remove attacker access, fix vulnerability.

```yaml
- action: Patch vulnerability
  example: |
    # Fix SQL injection (deploy hotfix)
    git checkout -b hotfix/sql-injection-fix
    # Apply fix from SEC-04 pentest report
    git commit -m "Fix CRIT-001: SQL injection in search endpoint"
    git push && deploy to production

- action: Rotate secrets
  example: |
    # Rotate database password
    aws secretsmanager rotate-secret --secret-id [project]/prod/db-password

    # Rotate JWT signing key
    aws secretsmanager update-secret \
      --secret-id [project]/prod/jwt-key \
      --secret-string "$(openssl rand -base64 32)"

- action: Scan for malware
  example: |
    # Run ClamAV on all servers
    clamscan -r /var/www/html --remove

- action: Review access logs
  example: |
    # Identify all actions by attacker
    SELECT * FROM audit_logs WHERE ip_address = '[ATTACKER-IP]';
```

---

### Phase 4: Recovery (4-24 hours)

**Objective:** Restore normal operations, monitor for reinfection.

```yaml
- action: Restore from backup (if needed)
  example: |
    # Restore database from pre-incident snapshot
    aws rds restore-db-instance-from-db-snapshot \
      --db-instance-identifier [project]-prod-restored \
      --db-snapshot-identifier incident-2025-10-05-snapshot

- action: Deploy hardened configuration
  example: |
    # Deploy WAF rules (block similar attacks)
    terraform apply -target=aws_wafv2_web_acl.main

- action: Monitor for 48 hours
  checklist:
    - [ ] No failed login spikes
    - [ ] No suspicious data exports
    - [ ] No WAF blocks from new IPs
    - [ ] No anomalous database queries
```

---

### Phase 5: Post-Mortem (24-72 hours)

**Objective:** Learn from incident, prevent recurrence.

#### Post-Mortem Report Template

```markdown
# Incident Post-Mortem: [INCIDENT-ID]

**Date:** 2025-10-05
**Duration:** 3 hours (14:00 - 17:00 UTC)
**Severity:** P0 (Critical)

## Summary

SQL injection vulnerability in `/api/v1/orders` endpoint allowed attacker to dump 500 user records (emails + hashed passwords).

## Timeline

| Time | Event |
|------|-------|
| 14:00 | Attacker discovers SQL injection vulnerability |
| 14:15 | Automated alert: "SuspiciousDataExport" triggered |
| 14:20 | Security Lead confirms data breach |
| 14:25 | Incident Commander paged (P0 escalation) |
| 14:30 | Attacker IP blocked (containment) |
| 15:00 | Vulnerability patched (hotfix deployed) |
| 16:00 | All users forced to reset passwords |
| 17:00 | Incident closed (monitoring continues) |

## Root Cause

Developer used string concatenation instead of parameterized query in `OrdersController.SearchOrders()` method.

## Impact

- **Users affected:** 500 users
- **Data exposed:** Emails + bcrypt hashed passwords (NOT plaintext)
- **Business impact:** $0 (no financial loss, no service downtime)

## What Went Well

✅ Automated alert detected breach within 15 minutes
✅ Containment achieved in 30 minutes (IP blocked)
✅ Hotfix deployed in 1 hour

## What Went Wrong

❌ SQL injection vulnerability not caught by code review
❌ No SAST (static analysis) in CI/CD pipeline
❌ Incident response playbook outdated (IP blocking script failed)

## Action Items

| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| Add SAST tool (Semgrep) to CI/CD | DevOps | 2025-10-12 | 🔴 OPEN |
| Update incident playbooks (test quarterly) | Security | 2025-10-10 | 🔴 OPEN |
| Mandatory security training for devs | HR | 2025-11-01 | 🔴 OPEN |
| Implement query review checklist | DE | 2025-10-08 | 🔴 OPEN |

## LGPD Notification

- [ ] ANPD notified (72 hours deadline): ✅ 2025-10-06 10:00
- [ ] Affected users notified: ✅ 2025-10-06 12:00 (email sent)
```

---

## 📚 Playbooks (Runbooks)

### Playbook 1: Database Breach

**File:** `playbooks/database-breach.md`

```markdown
# Playbook: Database Breach

## Detection
- Alert: "UnauthorizedDatabaseAccess" OR "SuspiciousDataExport"
- Manual: Customer reports data leak

## Immediate Actions (15 min)
1. Block attacker IP:
   aws ec2 revoke-security-group-ingress --group-id [SG-ID] --cidr [IP]/32
2. Snapshot database (forensics):
   aws rds create-db-snapshot --db-instance-identifier [DB-ID]
3. Identify affected data:
   SELECT * FROM audit_logs WHERE ip_address = '[ATTACKER-IP]';

## Containment (1 hour)
4. Rotate database credentials:
   aws secretsmanager rotate-secret --secret-id [DB-SECRET]
5. Restart application (force reconnect with new credentials)
6. Review database permissions (least privilege)

## Eradication (4 hours)
7. Patch vulnerability (deploy hotfix)
8. Run full security scan (OWASP ZAP)
9. Review all database queries (prevent similar issues)

## Recovery (24 hours)
10. Monitor database access logs (48 hours)
11. If data exposed: notify ANPD (LGPD) + affected users

## Post-Mortem
12. Document incident (template above)
13. Update this playbook with lessons learned
```

### Playbook 2: DDoS Attack

**File:** `playbooks/ddos-attack.md`

```markdown
# Playbook: DDoS Attack

## Detection
- Alert: "WAFBlockSpike" OR "HighTrafficRate"
- Manual: Service unavailable (503 errors)

## Immediate Actions (15 min)
1. Enable CloudFlare "I'm Under Attack" mode
2. Increase rate limiting (10 req/sec → 1 req/sec)
3. Block top attacking IPs (WAF blacklist)

## Containment (1 hour)
4. Scale up infrastructure (auto-scaling)
5. Enable DDoS protection (AWS Shield, CloudFlare)
6. Contact upstream provider (if volumetric attack)

## Recovery (4 hours)
7. Monitor traffic (ensure attack stopped)
8. Gradually relax rate limits
9. Disable "I'm Under Attack" mode

## Post-Mortem
10. Analyze attack pattern (identify weaknesses)
11. Update DDoS protection rules
```

### Playbook 3: Ransomware

**File:** `playbooks/ransomware.md`

```markdown
# Playbook: Ransomware

## Detection
- Files encrypted + ransom note
- Antivirus alert

## Immediate Actions (IMMEDIATE)
1. DO NOT PAY RANSOM
2. Isolate infected systems (disconnect network)
3. Shutdown affected servers (prevent spread)

## Containment (1 hour)
4. Identify ransomware variant (ransom note, file extensions)
5. Check backups (unaffected?)
6. Scan all systems (ensure no lateral movement)

## Recovery (24 hours)
7. Restore from backup (pre-infection snapshot)
8. Rebuild infected systems (clean OS install)
9. Update antivirus signatures

## Post-Mortem
10. Identify infection vector (phishing email? vulnerable service?)
11. Mandatory security training for employees
```

---

## 📞 Emergency Contacts

| Role | Name | Phone | Email |
|------|------|-------|-------|
| **Incident Commander** | [NOME] | [+55-XX-XXXXX-XXXX] | [EMAIL] |
| **Security Lead** | [NOME] | [+55-XX-XXXXX-XXXX] | [EMAIL] |
| **DevOps Lead** | [NOME] | [+55-XX-XXXXX-XXXX] | [EMAIL] |
| **Legal** | [NOME] | [+55-XX-XXXXX-XXXX] | [EMAIL] |
| **DPO** | [NOME] | [+55-XX-XXXXX-XXXX] | [EMAIL] |
| **AWS Support** | N/A | N/A | https://console.aws.amazon.com/support |
| **CloudFlare Support** | N/A | N/A | https://dash.cloudflare.com/support |

---

## 🧪 Incident Drills

### Quarterly Drills

- [ ] **Q1:** Simulate database breach (test playbook/database-breach.md)
- [ ] **Q2:** Simulate DDoS attack (test playbook/ddos-attack.md)
- [ ] **Q3:** Simulate ransomware (test playbook/ransomware.md)
- [ ] **Q4:** Simulate unauthorized access (test playbook/account-takeover.md)

**Drill Checklist:**
- [ ] Alert mechanisms working? (automated alerts triggered?)
- [ ] Response time within SLA? (P0: 15 min)
- [ ] Playbooks up-to-date? (no broken commands)
- [ ] Team knows their roles? (no confusion)

---

## ✅ Definition of Done

- [ ] Incident response plan documentado (5 fases)
- [ ] Incident Response Team definido (roles + contacts)
- [ ] Playbooks criados (database breach, DDoS, ransomware)
- [ ] Automated alerts configurados (SIEM integration)
- [ ] LGPD breach notification procedure documentado (72h)
- [ ] Quarterly drills agendados (Q1-Q4)
- [ ] Post-mortem template criado
- [ ] SEC-checklist.yml completo

---

**Próximos Passos:**
1. Agendar primeiro incident drill (Q1)
2. Integrar playbooks com SIEM (Splunk/Sumo Logic)
3. Treinar equipe nos playbooks (walkthrough)

