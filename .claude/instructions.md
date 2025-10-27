# Custom Instructions for DDD/EDA Workflow

## Markdown Formatting

All Markdown documents must use proper line breaks for correct rendering across all parsers (GitHub, VS Code, GitLab, etc.).

### Two Line Break Methods

**1. Hard Break (Compact Metadata)**

For metadata sections with multiple consecutive lines (headers/footers):
- Add **2 spaces** at end of each line
- Example:
  ```markdown
  **Projeto:** myTraderGEO
  **Database:** PostgreSQL 15+
  **Agent:** DBA Agent
  **Status:** ✅ Active
  ```

**2. Paragraph Break (Readable Content)**

For document body and content sections:
- Use **blank lines** between sections/paragraphs
- Lists, tables, code blocks use natural Markdown (no special formatting)

### Validation

**Before committing:**
1. Open Markdown preview (Ctrl+Shift+V)
2. Verify metadata appears one per line (not all together)
3. Verify content sections have proper spacing

### Template Comment

Every new template should include this comment at the top:

```markdown
<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->
```

## Document Strategy

### Two Document Strategy

Technical deliverables should follow the "Two Document Strategy":

1. **README.md** (Operational)
   - **Purpose:** HOW to use, quick reference
   - **Audience:** Developers, operators, new team members
   - **Content:** Commands, scripts, troubleshooting, quick start
   - **Format:** Task-oriented, imperative, concise

2. **Agent-XX-*.md** (Strategic)
   - **Purpose:** WHY/WHAT design decisions
   - **Audience:** Architects, technical leads, reviewers
   - **Content:** Design rationale, architecture, patterns, trade-offs
   - **Format:** Explanatory, declarative, comprehensive

### When to Create README.md

Create README.md when:
- ✅ There are operational procedures (deploy, build, run)
- ✅ There are scripts or commands to execute
- ✅ New team members need quick start guide
- ✅ Troubleshooting steps are needed

Don't create README.md when:
- ❌ Content is purely strategic/design (use Agent-XX instead)
- ❌ No operational procedures exist yet
- ❌ Would duplicate existing documentation without adding value

## Agent-Specific Notes

### All Agents
- Always validate Markdown preview before committing
- Use appropriate line break method for context (metadata vs content)
- Include template comment block in new templates
- Follow Two Document Strategy for deliverables

### DBA, PE, SE, FE (Technical Agents)
- README.md is **mandatory deliverable** for these agents
- README must use appropriate template from `.agents/templates/`
- Focus README on operational tasks (scripts, commands, troubleshooting)
- Keep strategic content in Agent-XX-*.md files

### SDA, DE, UXD, GM, SEC, QAE (Non-Technical Agents)
- README.md is optional (only if operational procedures exist)
- Focus on strategic documents (Agent-XX-*.md)
- Still follow Markdown formatting standards

## Commit Message Standards

When committing Markdown documentation changes:

```
docs(scope): Brief description

- Detail 1
- Detail 2

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

Examples:
- `docs(templates): Add formatting comment to all templates`
- `docs(dba): Create operational README for database procedures`
- `docs(agents): Update Markdown formatting guidelines in specs`

---

**Last Updated:** 2025-10-27
**Version:** 1.0
**Applies To:** All projects using the DDD/EDA workflow with multi-agent system
