#!/bin/bash

# setup-milestones.sh
# Creates GitHub milestones for DDD Workflow
# Customized based on SDA Epic Backlog (prioritized epics)

set -e

# Configuration
REPO="[GITHUB_OWNER]/[REPO_NAME]"  # e.g., "username/myproject"

echo "🎯 Creating GitHub milestones for repository: $REPO"
echo ""

# ============================================================================
# Milestone 0: Discovery Foundation (Always first)
# ============================================================================
echo "📋 Creating Milestone 0: Discovery Foundation..."

gh milestone create "M0: Discovery Foundation" \
  --repo "$REPO" \
  --description "Strategic analysis, UX foundations, GitHub setup, environments, security baseline, test strategy" \
  --due-date "[DISCOVERY_DUE_DATE]" || echo "⚠️  Milestone M0 already exists"

echo "✅ Milestone M0 created"
echo ""

# ============================================================================
# Epic Milestones (from SDA Epic Backlog)
# ============================================================================
echo "📋 Creating Epic milestones (from SDA-01-Event-Storming.md)..."

# PLACEHOLDER: Replace with actual epics from SDA output
# Format: M{N}: {Epic Name}
# Due dates should reflect epic prioritization and estimated duration

# Epic 1 (Highest priority)
gh milestone create "M1: [EPIC_1_NAME]" \
  --repo "$REPO" \
  --description "[EPIC_1_DESCRIPTION] - Priority: High" \
  --due-date "[EPIC_1_DUE_DATE]" || echo "⚠️  Milestone M1 already exists"

# Epic 2
gh milestone create "M2: [EPIC_2_NAME]" \
  --repo "$REPO" \
  --description "[EPIC_2_DESCRIPTION] - Priority: High" \
  --due-date "[EPIC_2_DUE_DATE]" || echo "⚠️  Milestone M2 already exists"

# Epic 3
gh milestone create "M3: [EPIC_3_NAME]" \
  --repo "$REPO" \
  --description "[EPIC_3_DESCRIPTION] - Priority: Medium" \
  --due-date "[EPIC_3_DUE_DATE]" || echo "⚠️  Milestone M3 already exists"

# Epic 4
gh milestone create "M4: [EPIC_4_NAME]" \
  --repo "$REPO" \
  --description "[EPIC_4_DESCRIPTION] - Priority: Medium" \
  --due-date "[EPIC_4_DUE_DATE]" || echo "⚠️  Milestone M4 already exists"

# Epic 5
gh milestone create "M5: [EPIC_5_NAME]" \
  --repo "$REPO" \
  --description "[EPIC_5_DESCRIPTION] - Priority: Low" \
  --due-date "[EPIC_5_DUE_DATE]" || echo "⚠️  Milestone M5 already exists"

# Add more milestones as needed based on SDA Epic Backlog
# gh milestone create "M6: [EPIC_6_NAME]" --repo "$REPO" --description "[EPIC_6_DESCRIPTION]" --due-date "[EPIC_6_DUE_DATE]"

echo "✅ Epic milestones created"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "🎉 All milestones created successfully!"
echo ""
echo "📊 Summary:"
echo "   - M0: Discovery Foundation"
echo "   - M1-M[N]: Epic milestones (customize from SDA backlog)"
echo ""
echo "View all milestones: gh milestone list --repo $REPO"
echo ""
echo "💡 Next steps:"
echo "   1. Create Issue #1 for Discovery Foundation (Milestone M0)"
echo "   2. After DE-01 per epic, create epic issues and assign to corresponding milestones"
