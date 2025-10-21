# GitHub Manager - Quick Reference

**📖 For complete documentation, see:** [GM-00-GitHub-Setup.md](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md)

---

## 📋 About This Document

This is a **quick reference guide** for executing GitHub setup tasks. For strategic decisions, justifications, and technical details, consult [GM-00-GitHub-Setup.md](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md).

- **This README:** Commands and checklists (HOW to execute)
- **GM-00:** Justifications and details (WHY and WHAT)

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
**Execute:** Once during Discovery phase
**Usage:**
```bash
bash 03-github-manager/scripts/setup-labels.sh
```

**Verify:**
```bash
gh label list --repo [OWNER]/[REPO]
```

**See GM-00 for:** Complete label list and justifications

---

### `create-milestone.sh`
**Purpose:** Creates a milestone on-demand (one at a time, when starting an epic)
**Execute:** Automatically by GM on Day 2 of each epic iteration
**Manual Usage (if needed):**
```bash
bash 03-github-manager/scripts/create-milestone.sh \
  <number> "<title>" "<description>" "<due-date-YYYY-MM-DD>"
```

**Examples:**
```bash
# M0: Discovery (no due date)
bash 03-github-manager/scripts/create-milestone.sh \
  0 "Discovery Foundation" "Setup inicial" ""

# M1: EPIC-01 (with due date)
bash 03-github-manager/scripts/create-milestone.sh \
  1 "EPIC-01 - Name" "Description" "2026-02-28"
```

**Verify:**
```bash
gh api repos/[OWNER]/[REPO]/milestones
```

**See GM-00 for:** Complete milestone strategy

---

### `create-epic-issue.sh`
**Purpose:** Creates an epic issue on-demand (after DE-01 complete)
**Execute:** Automatically by GM on Day 2 of each epic iteration
**Manual Usage (if needed):**
```bash
bash 03-github-manager/scripts/create-epic-issue.sh \
  <epic-number> "<milestone-title>"
```

**Examples:**
```bash
# EPIC-01 (after DE-01-EPIC-01-*.md complete)
bash 03-github-manager/scripts/create-epic-issue.sh \
  1 "M1: EPIC-01 - Name"
```

**⚠️ IMPORTANT:**
- Script creates base template automatically
- **User MUST edit issue after creation** to add complete DE-01 details
- GM guides user on what to customize (1min)

**Verify:**
```bash
gh issue list --label epic --repo [OWNER]/[REPO]
```

**See GM-00 for:** Complete epic issue structure

---

### `create-epic-full.sh` ⭐ **NEW - RECOMMENDED**
**Purpose:** Creates COMPLETE epic setup: milestone + epic issue + all agent issues (all at once)
**Execute:** When starting a new epic (after DE-01 complete)
**Usage:**
```bash
bash 03-github-manager/scripts/create-epic-full.sh \
  <epic-number> "<epic-name>" "<due-date-YYYY-MM-DD>"
```

**Examples:**
```bash
# EPIC-01
bash 03-github-manager/scripts/create-epic-full.sh \
  1 "Criar Estratégia Bull Call Spread" "2026-02-28"
```

**What it creates:**
1. Milestone M1
2. Issue: [EPIC-01] Epic Name (parent)
3. Issue: DE - Domain Model
4. Issue: DBA - Schema Review
5. Issue: SE - Backend Implementation
6. Issue: UXD - Wireframes
7. Issue: FE - Frontend Implementation
8. Issue: QAE - Quality Gate

**✅ Advantages:**
- Saves ~15min vs creating issues manually
- Ensures consistency (all issues follow same pattern)
- All issues linked to milestone automatically
- Agent labels applied automatically

**⚠️ Note:** Still need to customize epic issue with DE-01 details

**Verify:**
```bash
gh issue list --milestone "M1: EPIC-01" --repo [OWNER]/[REPO]
```

**See GM-00 for:** Complete epic workflow and customization

---

### `start-work-on-issue.sh` ⭐ **NEW - RECOMMENDED**
**Purpose:** Automates starting work on an issue (branch + commit + PR)
**Execute:** When you're ready to start working on a specific issue
**Usage:**
```bash
bash 03-github-manager/scripts/start-work-on-issue.sh <issue-number>
```

**Examples:**
```bash
# Start work on issue #6 (DE: Domain Model)
bash 03-github-manager/scripts/start-work-on-issue.sh 6
```

**What it does:**
1. Fetches issue info (title, milestone, labels)
2. Generates branch name (feature/epic-01-de-domain-model)
3. Creates and checks out branch
4. Makes initial empty commit (following 03-GIT-PATTERNS.md)
5. Pushes branch to origin
6. Creates draft PR linked to issue

**✅ Advantages:**
- Saves ~3min vs manual setup
- Ensures correct branch naming (kebab-case, with epic number)
- Initial commit follows 03-GIT-PATTERNS.md standard
- PR automatically linked to issue

**When ready for review:**
```bash
gh pr ready  # Mark PR as ready for review
```

**When approved:**
```bash
gh pr merge --merge --delete-branch
```

**See 03-GIT-PATTERNS.md for:** Complete Git workflow details

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

## 🔄 Per Epic Workflow (Automated by GM)

### When: GM executes on Day 2 of each epic iteration (after DE-01 complete)

**GM automatically:**
1. ✅ Reads DE-01-EPIC-{N}-{Name}-Domain-Model.md
2. ✅ Executes `create-milestone.sh` → Milestone M{N} created
3. ✅ Executes `create-epic-issue.sh` → Epic issue created with base template
4. ⚠️ Guides user to customize epic issue (1min)

---

### What GM Does Automatically

1. **Create Milestone** (executed by GM automatically - 20s)

   GM executes:
   ```bash
   bash 03-github-manager/scripts/create-milestone.sh \
     {N} \
     "EPIC-{N} - {Name from DE-01}" \
     "{Description from DE-01}" \
     "{Today + 6 weeks}"
   ```

   **Result:** Milestone M{N} created in GitHub

2. **Create Epic Issue** (executed by GM automatically - 20s)

   GM executes:
   ```bash
   bash 03-github-manager/scripts/create-epic-issue.sh \
     {N} \
     "M{N}: EPIC-{N} - {Name from DE-01}"
   ```

   **Result:** Epic issue created with base template

3. **User Customizes Issue** (guided by GM - 1min)

   GM instructs user to:
   ```
   ⚠️ NEXT STEPS:
   1. Open epic issue in GitHub
   2. Edit title: [EPIC-{N}] {Name from DE-01}
   3. Add complete objectives from DE-01
   4. Add complete acceptance criteria from DE-01
   5. Add BC labels: bc:context-1, bc:context-2
   6. Verify deliverables checklist
   ```

---

### Manual Alternatives (if needed)

If you need to create milestone/epic manually (GM didn't execute or retry needed):

**Option A: Use the scripts manually**
```bash
# Create milestone
bash 03-github-manager/scripts/create-milestone.sh \
  1 "EPIC-01 - Name" "Description" "2026-02-28"

# Create epic issue
bash 03-github-manager/scripts/create-epic-issue.sh \
  1 "M1: EPIC-01 - Name"
```

**Option B: GitHub UI**
```
GitHub → Issues → Milestones → New Milestone
GitHub → New Issue → Select "🎯 Epic Issue" template
```

**Details:** [GM-00 Epic Issues](../00-doc-ddd/07-github-management/GM-00-GitHub-Setup.md#epic-issues)
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
- [03-GIT-PATTERNS.md](../.agents/docs/03-GIT-PATTERNS.md) - Git workflow (branches, PRs, milestones, tags)
- [SDA-01 Event Storming](../00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md) - Epics source
- [SDA-02 Context Map](../00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md) - Bounded Contexts source
- [PE-00 Environments Setup](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md) - Stack for CI/CD

---

**Project:** [PROJECT_NAME]
**Version:** 1.0
**Last Updated:** [DATE]
