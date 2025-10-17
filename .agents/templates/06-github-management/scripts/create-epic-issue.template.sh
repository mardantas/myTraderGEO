#!/bin/bash

# create-epic-issue.sh
# Creates a detailed epic issue AFTER DE-01 is complete
# Uses information from DE-01 to populate issue with accurate scope

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================
REPO="[GITHUB_OWNER]/[REPO_NAME]"
EPIC_NUMBER="[EPIC_NUMBER]"          # e.g., "1", "2", "3"
EPIC_SHORT_NAME="[EPIC_SHORT_NAME]"  # e.g., "bull-call-spread"
EPIC_FULL_NAME="[EPIC_FULL_NAME]"    # e.g., "Create Bull Call Spread Strategy"

# Milestone (should match M{N} format)
MILESTONE="M${EPIC_NUMBER}: ${EPIC_FULL_NAME}"

# Labels
LABELS="type:feature,priority:high,epic:${EPIC_SHORT_NAME},phase:iteration"

# Due date (optional)
DUE_DATE="[DUE_DATE]"  # Format: YYYY-MM-DD

# ============================================================================
# ISSUE BODY (populated from DE-01)
# ============================================================================
read -r -d '' ISSUE_BODY << 'EOF'
## 📋 Epic Description

[Description from DE-01-{EpicName}-Domain-Model.md]

This epic implements [functionality description] across the following Bounded Contexts:
- [BC 1]
- [BC 2]

---

## 🎯 Business Objectives

- [ ] [Objective 1 from DE-01]
- [ ] [Objective 2 from DE-01]
- [ ] [Objective 3 from DE-01]

---

## 🏗️ Domain Model (from DE-01)

### Aggregates
- **[Aggregate 1]**: [Description]
- **[Aggregate 2]**: [Description]

### Value Objects
- [VO 1]
- [VO 2]

### Domain Events
- [Event 1]
- [Event 2]

See full details: [DE-01-{EpicName}-Domain-Model.md](00-doc-ddd/04-tactical-design/DE-01-{EpicName}-Domain-Model.md)

---

## 👥 Agents and Deliverables

### 1. Domain Engineer (DE) ✅ DONE
- [x] DE-01-{EpicName}-Domain-Model.md

### 2. Database Administrator (DBA)
- [ ] DBA-01-{EpicName}-Schema-Review.md
- [ ] EF Core migrations created
- [ ] Schema validated

### 3. User Experience Designer (UXD)
- [ ] UXD-01-{EpicName}-Wireframes.md
- [ ] UI components designed

### 4. Software Engineer (SE)
- [ ] Domain layer implementation
- [ ] Application layer (use cases)
- [ ] API endpoints (controllers)
- [ ] Unit tests (coverage >= 80%)

### 5. Frontend Engineer (FE)
- [ ] React components
- [ ] API integration
- [ ] Unit tests (coverage >= 70%)

### 6. Quality Assurance Engineer (QAE) - QUALITY GATE
- [ ] Integration tests
- [ ] E2E tests
- [ ] Regression tests
- [ ] **ALL TESTS PASSING** (blocker for deploy)

---

## 📦 Acceptance Criteria (from DE-01)

- [ ] [AC 1 from DE-01]
- [ ] [AC 2 from DE-01]
- [ ] [AC 3 from DE-01]
- [ ] [AC 4 from DE-01]

---

## 🔗 Dependencies

- **Blocks:** [Epic/Issue that depends on this]
- **Blocked by:** [Epic/Issue this depends on]
- **Related:** [Related epics/issues]

---

## ✅ Definition of Done

### Code
- [ ] All deliverables created (DE, DBA, UXD, SE, FE, QAE docs)
- [ ] Backend code complete (domain + application + API)
- [ ] Frontend code complete (components + pages)
- [ ] Code review approved (at least 1 reviewer)

### Tests
- [ ] Unit tests passing (backend >= 80%, frontend >= 70%)
- [ ] Integration tests passing
- [ ] E2E tests passing
- [ ] No P0/P1 bugs

### Documentation
- [ ] API documentation updated
- [ ] README updated if needed
- [ ] Ubiquitous Language updated (if new terms)

### Deployment
- [ ] Deployed to staging
- [ ] Smoke tests passed in staging
- [ ] QAE sign-off (quality gate passed)
- [ ] Ready for production deploy

---

## 📅 Timeline

- **Start:** [START_DATE]
- **Due:** [DUE_DATE]
- **Duration:** ~2 weeks (10 days)

---

## 📊 Progress Tracking

Use this epic's milestone to track all related issues:
- View progress: `gh issue list --milestone "${MILESTONE}" --repo ${REPO}`
- Epic label: `epic:${EPIC_SHORT_NAME}`

---

**References:**
- DE-01 Domain Model: [00-doc-ddd/04-tactical-design/DE-01-{EpicName}-Domain-Model.md]
- SDA Context Map: [00-doc-ddd/02-strategic-design/SDA-02-Context-Map.md]
- UL: [00-doc-ddd/02-strategic-design/SDA-03-Ubiquitous-Language.md]
EOF

# ============================================================================
# CREATE ISSUE
# ============================================================================
echo "📝 Creating Epic Issue..."
echo ""
echo "Epic: ${EPIC_FULL_NAME}"
echo "Milestone: ${MILESTONE}"
echo "Labels: ${LABELS}"
echo ""

gh issue create \
  --repo "$REPO" \
  --title "[EPIC-${EPIC_NUMBER}] ${EPIC_FULL_NAME}" \
  --body "$ISSUE_BODY" \
  --milestone "$MILESTONE" \
  --label "$LABELS"

echo ""
echo "✅ Epic issue created successfully!"
echo ""
echo "View issue: gh issue view --repo $REPO --web"
