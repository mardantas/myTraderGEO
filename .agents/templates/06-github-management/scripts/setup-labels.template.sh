#!/bin/bash

# setup-labels.sh
# Creates GitHub labels for DDD Workflow
# Customized based on SDA output (Bounded Contexts and Epics)

set -e

# Configuration
REPO="[GITHUB_OWNER]/[REPO_NAME]"  # e.g., "username/myproject"

echo "🏷️  Creating GitHub labels for repository: $REPO"
echo ""

# ============================================================================
# 1. AGENT LABELS (Who is working)
# ============================================================================
echo "📋 Creating Agent labels..."

gh label create "agent:SDA" \
  --description "Strategic Domain Analyst" \
  --color "0E8A16" \
  --repo "$REPO" || echo "⚠️  Label agent:SDA already exists"

gh label create "agent:UXD" \
  --description "User Experience Designer" \
  --color "1D76DB" \
  --repo "$REPO" || echo "⚠️  Label agent:UXD already exists"

gh label create "agent:DE" \
  --description "Domain Engineer" \
  --color "5319E7" \
  --repo "$REPO" || echo "⚠️  Label agent:DE already exists"

gh label create "agent:DBA" \
  --description "Database Administrator" \
  --color "D93F0B" \
  --repo "$REPO" || echo "⚠️  Label agent:DBA already exists"

gh label create "agent:SE" \
  --description "Software Engineer" \
  --color "C5DEF5" \
  --repo "$REPO" || echo "⚠️  Label agent:SE already exists"

gh label create "agent:FE" \
  --description "Frontend Engineer" \
  --color "FBCA04" \
  --repo "$REPO" || echo "⚠️  Label agent:FE already exists"

gh label create "agent:QAE" \
  --description "Quality Assurance Engineer" \
  --color "006B75" \
  --repo "$REPO" || echo "⚠️  Label agent:QAE already exists"

gh label create "agent:GM" \
  --description "GitHub Manager" \
  --color "B60205" \
  --repo "$REPO" || echo "⚠️  Label agent:GM already exists"

gh label create "agent:PE" \
  --description "Platform Engineer" \
  --color "7057FF" \
  --repo "$REPO" || echo "⚠️  Label agent:PE already exists"

gh label create "agent:SEC" \
  --description "Security Specialist" \
  --color "D73A4A" \
  --repo "$REPO" || echo "⚠️  Label agent:SEC already exists"

echo "✅ Agent labels created"
echo ""

# ============================================================================
# 2. BOUNDED CONTEXT LABELS (Where the work is)
# ============================================================================
echo "📋 Creating Bounded Context labels (from SDA-02-Context-Map.md)..."

# PLACEHOLDER: Replace with actual BCs from SDA output
# Example BCs - customize based on your project:

gh label create "bc:[BC_NAME_1]" \
  --description "Bounded Context: [BC_NAME_1]" \
  --color "C2E0C6" \
  --repo "$REPO" || echo "⚠️  Label bc:[BC_NAME_1] already exists"

gh label create "bc:[BC_NAME_2]" \
  --description "Bounded Context: [BC_NAME_2]" \
  --color "C2E0C6" \
  --repo "$REPO" || echo "⚠️  Label bc:[BC_NAME_2] already exists"

gh label create "bc:[BC_NAME_3]" \
  --description "Bounded Context: [BC_NAME_3]" \
  --color "C2E0C6" \
  --repo "$REPO" || echo "⚠️  Label bc:[BC_NAME_3] already exists"

# Add more BCs as identified by SDA
# gh label create "bc:[BC_NAME_4]" --description "Bounded Context: [BC_NAME_4]" --color "C2E0C6" --repo "$REPO"

echo "✅ Bounded Context labels created"
echo ""

# ============================================================================
# 3. EPIC LABELS (What functionality)
# ============================================================================
echo "📋 Creating Epic labels (from SDA-01-Event-Storming.md)..."

# PLACEHOLDER: Replace with actual epics from SDA output
# Example epics - customize based on your project:

gh label create "epic:[EPIC_1_SHORT_NAME]" \
  --description "Epic: [EPIC_1_FULL_NAME]" \
  --color "FEF2C0" \
  --repo "$REPO" || echo "⚠️  Label epic:[EPIC_1_SHORT_NAME] already exists"

gh label create "epic:[EPIC_2_SHORT_NAME]" \
  --description "Epic: [EPIC_2_FULL_NAME]" \
  --color "FEF2C0" \
  --repo "$REPO" || echo "⚠️  Label epic:[EPIC_2_SHORT_NAME] already exists"

gh label create "epic:[EPIC_3_SHORT_NAME]" \
  --description "Epic: [EPIC_3_FULL_NAME]" \
  --color "FEF2C0" \
  --repo "$REPO" || echo "⚠️  Label epic:[EPIC_3_SHORT_NAME] already exists"

# Add more epics as identified by SDA
# gh label create "epic:[EPIC_4_SHORT_NAME]" --description "Epic: [EPIC_4_FULL_NAME]" --color "FEF2C0" --repo "$REPO"

echo "✅ Epic labels created"
echo ""

# ============================================================================
# 4. TYPE LABELS (Nature of work)
# ============================================================================
echo "📋 Creating Type labels..."

gh label create "type:feature" \
  --description "Nova funcionalidade" \
  --color "A2EEEF" \
  --repo "$REPO" || echo "⚠️  Label type:feature already exists"

gh label create "type:bug" \
  --description "Correção de bug" \
  --color "D73A4A" \
  --repo "$REPO" || echo "⚠️  Label type:bug already exists"

gh label create "type:refactor" \
  --description "Refatoração de código" \
  --color "0075CA" \
  --repo "$REPO" || echo "⚠️  Label type:refactor already exists"

gh label create "type:docs" \
  --description "Documentação" \
  --color "0075CA" \
  --repo "$REPO" || echo "⚠️  Label type:docs already exists"

gh label create "type:test" \
  --description "Testes" \
  --color "BFD4F2" \
  --repo "$REPO" || echo "⚠️  Label type:test already exists"

gh label create "type:chore" \
  --description "Tarefas de manutenção" \
  --color "FEF2C0" \
  --repo "$REPO" || echo "⚠️  Label type:chore already exists"

echo "✅ Type labels created"
echo ""

# ============================================================================
# 5. PRIORITY LABELS
# ============================================================================
echo "📋 Creating Priority labels..."

gh label create "priority:high" \
  --description "Alta prioridade" \
  --color "D93F0B" \
  --repo "$REPO" || echo "⚠️  Label priority:high already exists"

gh label create "priority:medium" \
  --description "Média prioridade" \
  --color "FBCA04" \
  --repo "$REPO" || echo "⚠️  Label priority:medium already exists"

gh label create "priority:low" \
  --description "Baixa prioridade" \
  --color "0E8A16" \
  --repo "$REPO" || echo "⚠️  Label priority:low already exists"

echo "✅ Priority labels created"
echo ""

# ============================================================================
# 6. STATUS LABELS
# ============================================================================
echo "📋 Creating Status labels..."

gh label create "status:blocked" \
  --description "Bloqueado por dependência" \
  --color "B60205" \
  --repo "$REPO" || echo "⚠️  Label status:blocked already exists"

gh label create "status:wip" \
  --description "Work in Progress" \
  --color "FBCA04" \
  --repo "$REPO" || echo "⚠️  Label status:wip already exists"

gh label create "status:review" \
  --description "Em revisão" \
  --color "0052CC" \
  --repo "$REPO" || echo "⚠️  Label status:review already exists"

gh label create "status:ready" \
  --description "Pronto para trabalhar" \
  --color "0E8A16" \
  --repo "$REPO" || echo "⚠️  Label status:ready already exists"

echo "✅ Status labels created"
echo ""

# ============================================================================
# 7. WORKFLOW PHASE LABELS
# ============================================================================
echo "📋 Creating Workflow Phase labels..."

gh label create "phase:discovery" \
  --description "Fase Discovery" \
  --color "BFDADC" \
  --repo "$REPO" || echo "⚠️  Label phase:discovery already exists"

gh label create "phase:iteration" \
  --description "Fase de Iteração (Epic)" \
  --color "C5DEF5" \
  --repo "$REPO" || echo "⚠️  Label phase:iteration already exists"

echo "✅ Workflow Phase labels created"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "🎉 All labels created successfully!"
echo ""
echo "📊 Summary:"
echo "   - 10 Agent labels"
echo "   - [X] Bounded Context labels (customize from SDA-02)"
echo "   - [Y] Epic labels (customize from SDA-01)"
echo "   - 6 Type labels"
echo "   - 3 Priority labels"
echo "   - 4 Status labels"
echo "   - 2 Phase labels"
echo ""
echo "View all labels: gh label list --repo $REPO"
