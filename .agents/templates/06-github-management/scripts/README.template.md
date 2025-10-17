# GitHub Automation Scripts

This directory contains automation scripts for GitHub setup and management as part of the DDD Workflow.

## 📋 Prerequisites

### GitHub CLI
All scripts require GitHub CLI (`gh`) installed and authenticated:

```bash
# Install GitHub CLI (if not already installed)
# macOS
brew install gh

# Windows
winget install --id GitHub.cli

# Linux
sudo apt install gh

# Verify installation
gh --version
```

### Authentication
```bash
# Login to GitHub
gh auth login

# Verify authentication
gh auth status
```

## 🚀 Scripts

### 1. `setup-labels.sh`

Creates all GitHub labels for the DDD workflow.

**When to run:** Once during Discovery phase (after SDA completes)

**What it creates:**
- Agent labels (`agent:SDA`, `agent:DE`, etc.)
- Bounded Context labels (`bc:[BC_NAME]`) - from SDA-02-Context-Map.md
- Epic labels (`epic:[EPIC_NAME]`) - from SDA-01-Event-Storming.md
- Type labels (`type:feature`, `type:bug`, etc.)
- Priority labels (`priority:high`, `priority:medium`, `priority:low`)
- Status labels (`status:blocked`, `status:wip`, etc.)
- Phase labels (`phase:discovery`, `phase:iteration`)

**Usage:**
```bash
# Make executable
chmod +x setup-labels.sh

# Run
./setup-labels.sh
```

**Customization required:**
Before running, replace placeholders:
- `[GITHUB_OWNER]` - Your GitHub username or organization
- `[REPO_NAME]` - Your repository name
- `[BC_NAME_1]`, `[BC_NAME_2]`, etc. - Bounded Contexts from SDA-02
- `[EPIC_1_SHORT_NAME]`, `[EPIC_2_SHORT_NAME]`, etc. - Epics from SDA-01

---

### 2. `setup-milestones.sh`

Creates GitHub milestones for Discovery and all Epics.

**When to run:** Once during Discovery phase (after SDA completes)

**What it creates:**
- M0: Discovery Foundation (always first)
- M1, M2, M3... - One milestone per epic (from SDA Epic Backlog)

**Usage:**
```bash
# Make executable
chmod +x setup-milestones.sh

# Run
./setup-milestones.sh
```

**Customization required:**
Before running, replace placeholders:
- `[GITHUB_OWNER]` - Your GitHub username or organization
- `[REPO_NAME]` - Your repository name
- `[DISCOVERY_DUE_DATE]` - Due date for Discovery (format: YYYY-MM-DD)
- `[EPIC_N_NAME]` - Epic names from SDA backlog
- `[EPIC_N_DESCRIPTION]` - Epic descriptions
- `[EPIC_N_DUE_DATE]` - Due dates based on prioritization

**Example:**
```bash
# Epic 1: Create Bull Call Spread Strategy
# Due: 2025-02-01 (2 weeks from start)

gh milestone create "M1: Create Bull Call Spread" \
  --repo "username/myproject" \
  --description "Implement Bull Call Spread strategy - Priority: High" \
  --due-date "2025-02-01"
```

---

### 3. `create-epic-issue.sh`

Creates a detailed epic issue AFTER DE-01 is complete.

**When to run:** Once per epic, AFTER DE-01-{EpicName}-Domain-Model.md is done

**What it creates:**
- Epic-level issue with full details from DE-01
- Assigns to correct milestone
- Adds epic label
- Includes acceptance criteria, deliverables checklist, DoD

**Usage:**
```bash
# Make executable
chmod +x create-epic-issue.sh

# Run
./create-epic-issue.sh
```

**Customization required:**
Before running, replace placeholders in the script:
- `[GITHUB_OWNER]` - Your GitHub username or organization
- `[REPO_NAME]` - Your repository name
- `[EPIC_NUMBER]` - Epic number (1, 2, 3...)
- `[EPIC_SHORT_NAME]` - Short name for label (e.g., "bull-call-spread")
- `[EPIC_FULL_NAME]` - Full epic name (e.g., "Create Bull Call Spread Strategy")
- `[DUE_DATE]` - Due date (format: YYYY-MM-DD)

In the issue body, populate from DE-01:
- Epic description
- Business objectives
- Aggregates, Value Objects, Domain Events
- Acceptance criteria

---

## 📊 Workflow

```
Discovery Phase:
1. SDA completes SDA-01 (Event Storming) and SDA-02 (Context Map)
2. GM customizes setup-labels.sh with BCs and Epics
3. GM runs ./setup-labels.sh
4. GM customizes setup-milestones.sh with Epic backlog
5. GM runs ./setup-milestones.sh

Per Epic (Iteration):
1. DE completes DE-01-{EpicName}-Domain-Model.md
2. GM customizes create-epic-issue.sh with DE-01 details
3. GM runs ./create-epic-issue.sh
4. Epic issue created → Development begins
```

---

## 🔍 Verification

### Check labels
```bash
gh label list --repo [OWNER]/[REPO]
```

### Check milestones
```bash
gh milestone list --repo [OWNER]/[REPO]
```

### Check issues in milestone
```bash
gh issue list --milestone "M1: [Epic Name]" --repo [OWNER]/[REPO]
```

---

## 🛠️ Troubleshooting

### Error: "Resource not accessible by integration"
- **Solution:** Check GitHub CLI authentication: `gh auth status`
- Re-authenticate: `gh auth login`

### Error: "Label already exists"
- **Solution:** Normal behavior. Script continues without overwriting.
- To force recreation, delete label first: `gh label delete "label-name" --repo [OWNER]/[REPO]`

### Error: "Milestone already exists"
- **Solution:** Normal behavior. Script continues without overwriting.
- To force recreation, delete milestone first: `gh milestone delete "milestone-title" --repo [OWNER]/[REPO]`

---

## 📚 References

- **GitHub CLI Manual:** https://cli.github.com/manual/
- **SDA Output:** Used to populate BCs and Epics
- **DE Output:** Used to populate epic issues with accurate scope
- **Workflow Guide:** `.agents/docs/00-Workflow-Guide.md`

---

**Project:** [PROJECT_NAME]
**GitHub Manager Version:** 2.0
**Last Updated:** [DATE]
