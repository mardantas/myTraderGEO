# Custom Instructions for DDD/EDA Workflow

## Markdown Formatting Standards

**CRITICAL:** All Markdown documents MUST use proper line breaks to ensure correct rendering across all Markdown parsers (GitHub, VS Code, GitLab, etc.).

### Line Break Methods

#### 1. Hard Break (Compact Format)
**Usage:** Metadata sections in headers/footers (compact, machine-readable format)

**Method:** Add **2 spaces** at the end of each line

**Example:**
```markdown
**Projeto:** [PROJECT_NAME]
**Database:** PostgreSQL 15+
**Responsible Agent:** DBA Agent
**Last Updated:** 2025-10-27
**Status:** ✅ Active
```

**Common locations:**
- Document headers (project metadata)
- Document footers (version info, dates)
- Compact lists where vertical space matters

#### 2. Paragraph Break (Readable Format)
**Usage:** Content sections in document body (readable, human-friendly format)

**Method:** Leave **blank line** between blocks

**Example:**
```markdown
## Section Title

First paragraph with detailed explanation of the concept.
This continues on the same paragraph.

Second paragraph starts after a blank line. This is much more
readable for document content.

- List items don't need special formatting
- They naturally render correctly
- Just use normal Markdown syntax
```

**Common locations:**
- Section content
- Between major blocks (sections, tables, code blocks)
- Narrative text and explanations

### When to Use Each Method

| Format | Use Case | Line Break Method |
|--------|----------|-------------------|
| **Headers/Footers** | Metadata (compact) | 2 spaces at EOL |
| **Body Content** | Narrative text (readable) | Blank lines |
| **Lists** | Bullets, numbered | Natural Markdown (no special formatting) |
| **Tables** | Tabular data | Natural Markdown (no special formatting) |
| **Code blocks** | Code/commands | Natural Markdown (no special formatting) |

### Validation Process

**BEFORE committing any Markdown file:**

1. **Open Preview in VS Code:** Right-click file → "Open Preview" (or `Ctrl+Shift+V`)
2. **Check metadata sections:** Verify each metadata line appears on its own line
3. **Check content sections:** Verify paragraphs have proper spacing
4. **Common issues to spot:**
   - ❌ Metadata running together: "Projeto: X Database: Y Agent: Z"
   - ✅ Metadata on separate lines (one per line)
   - ❌ Content sections too cramped (no breathing room)
   - ✅ Content sections well-spaced with blank lines

### Template Comment Block

**Every new template file MUST include this comment at the top:**

```markdown
<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->
```

This comment serves as a reminder and guidance for anyone editing the template.

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
