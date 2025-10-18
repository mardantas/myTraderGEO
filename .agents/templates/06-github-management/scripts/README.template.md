# GitHub Manager - Quick Reference

**📖 For complete documentation, see:** [GM-00-GitHub-Setup.md](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md)

---

## 📋 About This Document

This is a **quick reference guide** for executing GitHub setup tasks. For strategic decisions, justifications, and technical details, consult [GM-00-GitHub-Setup.md](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md).

**This README:** Commands and checklists (HOW to execute)
**GM-00:** Justifications and details (WHY and WHAT)

---

## 🚀 Quick Start Checklist

### Discovery Phase (One-time)

- [ ] **1. Execute labels script**
  ```bash
  bash 03-github-manager/setup-labels.sh
  ```
  **Details:** [GM-00 Labels Section](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md#labels)

- [ ] **2. Create Milestone M0** (GitHub UI - 30 seconds)
  ```
  GitHub → Issues → Milestones → New Milestone
  Title: M0: Discovery Foundation
  Description: Setup inicial completo: SDA, UXD, GM, PE, SEC, QAE deliverables
  ```
  **Details:** [GM-00 Milestones Section](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md#milestones)

- [ ] **3. Verify CI/CD workflows created**
  ```bash
  gh workflow list --repo [OWNER]/[REPO]
  ```
  **Expected:** 3 workflows (ci-backend.yml, ci-frontend.yml, security.yml)
  **Details:** [GM-00 CI/CD Section](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md#cicd-workflows)

- [ ] **4. Verify Dependabot enabled**
  ```bash
  cat .github/dependabot.yml
  ```
  **Details:** [GM-00 Dependabot Section](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md#dependabot)

---

## 📦 Files in This Directory

### `setup-labels.sh`
**Purpose:** Creates 41 GitHub labels (agents, BCs, epics, types, priorities, status)
**Execute once:** During Discovery phase
**Usage:**
```bash
bash 03-github-manager/setup-labels.sh
```

**Verify:**
```bash
gh label list --repo [OWNER]/[REPO]
```

**See GM-00 for:** Complete label list and justifications

---

## 🔧 Common Commands

### Labels
```bash
# List all labels
gh label list --repo [OWNER]/[REPO]

# Create single label
gh label create "label-name" --description "Description" --color "FF0000" --repo [OWNER]/[REPO]
```

### Milestones
```bash
# List milestones
gh api repos/[OWNER]/[REPO]/milestones

# Create milestone via CLI
gh api repos/[OWNER]/[REPO]/milestones -X POST \
  -f title="M1: EPIC-01 - Epic Name" \
  -f description="Epic description" \
  -f due_on="2025-12-31T23:59:59Z" \
  -f state="open"

# GitHub UI: Issues → Milestones → New Milestone (30s)
```

**See GM-00 for:** Complete examples for all milestones (M0-M7)

### Issues
```bash
# List issues in milestone
gh issue list --milestone "M1: EPIC-01" --repo [OWNER]/[REPO]

# List issues by agent
gh issue list --label "agent:DE" --state open --repo [OWNER]/[REPO]

# List blocked issues
gh issue list --label "status:blocked" --repo [OWNER]/[REPO]
```

### CI/CD
```bash
# View workflow runs
gh run list --repo [OWNER]/[REPO]

# View specific run
gh run view [RUN_ID] --repo [OWNER]/[REPO]

# View workflow logs
gh run view [RUN_ID] --log --repo [OWNER]/[REPO]
```

### Velocity Metrics
```bash
# Issues closed last week
gh issue list --state closed --search "closed:>=2025-10-10" --repo [OWNER]/[REPO]

# Issues closed in epic
gh issue list --state closed --milestone "M1: EPIC-01" --repo [OWNER]/[REPO]
```

**See GM-00 for:** Complete metrics guide and interpretation

---

## 🔄 Per Epic Workflow

### When: After DE-01 domain model is complete

1. **Create Milestone** (if not exists)
   - GitHub UI → Milestones → New Milestone (30 seconds)
   - **Details:** [GM-00 Milestones](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md#milestones)

2. **Create Epic Issue**

   **Option A: GitHub Form (recommended for first epic)**
   ```
   GitHub → New Issue → Select "🎯 Epic Issue" template
   Fill form with DE-01 details (2min)
   Submit
   ```

   **Option B: CLI (faster for subsequent epics)**
   ```bash
   gh issue create --repo [OWNER]/[REPO] \
     --title "[EPIC-01] Epic Name" \
     --label "epic,bc:context-name,priority-high,agent:DE,agent:SE,agent:FE,agent:QAE" \
     --milestone "M1: Epic Name" \
     --body "$(cat <<'EOF'
   ## Epic Overview
   [Paste from DE-01]

   ## Objectives
   - Objective 1
   - Objective 2

   ## Acceptance Criteria
   - [ ] Criterion 1
   - [ ] Criterion 2

   [See GM-00 for complete template structure]
   EOF
   )"
   ```

   **Details:** [GM-00 Epic Issues](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md#epic-issues)

3. **Optional: Create Sub-Issues**
   - 1 issue per agent (DE, DBA, SE, FE, QAE)
   - Link to epic issue
   - **Details:** [GM-00 Issue Strategy](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md#issue-strategy)

---

## 🔒 Branch Strategy Quick Reference

### Naming Conventions
```bash
# Discovery
feature/discovery-foundation

# Epics
feature/epic-1-criar-estrategia

# Agent tasks
feature/de-strategy-domain-model
feature/se-strategy-api
feature/fe-strategy-form

# Bug fixes
bugfix/123-fix-margin-calculation

# Hotfixes
hotfix/critical-security-patch
```

**See GM-00 for:** Complete branch strategy and merge workflow

---

## 📊 Semantic Versioning

```bash
# Create tag
git tag -a v1.0.0 -m "Release v1.0.0: EPIC-01

- Feature: Description
- Feature: Description

Closes #2"

# Push tag
git push origin v1.0.0

# Create GitHub Release
gh release create v1.0.0 \
  --title "v1.0.0: EPIC-01 - Epic Name" \
  --notes "Release notes here"
```

**See GM-00 for:** Semantic versioning strategy and examples

---

## 🛠️ Troubleshooting

### Error: "Resource not accessible by integration"
```bash
# Check authentication
gh auth status

# Re-authenticate
gh auth login
```

### Labels already exist
Normal behavior. Script skips existing labels.

### CI workflow not running
Check:
1. File exists: `.github/workflows/ci-backend.yml`
2. Triggers configured correctly
3. GitHub Actions enabled in repo settings

**See GM-00 for:** Complete troubleshooting guide

---

## 📚 Complete Documentation

For strategic decisions, technical details, justifications, and integrations:

**→ [GM-00-GitHub-Setup.md](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md)**

Other references:
- [SDA-01 Event Storming](../00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md) - Epics source
- [SDA-02 Context Map](../00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md) - Bounded Contexts source
- [PE-00 Environments Setup](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md) - Stack for CI/CD

---

**Project:** [PROJECT_NAME]
**Version:** 1.0
**Last Updated:** [DATE]
