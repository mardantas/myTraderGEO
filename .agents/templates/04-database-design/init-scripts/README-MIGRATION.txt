=====================================================
MIGRATION NOTICE: Init Scripts Reorganization
=====================================================

As of 2025-01-10, the database init scripts have been reorganized
to implement environment-based password management.

OLD STRUCTURE:
  01-create-app-user.sql.template
    - Contained CREATE USER with hardcoded passwords
    - Contained GRANT statements

NEW STRUCTURE:
  00-init-users.sh.template
    - Unified script with CREATE USER + GRANTS
    - Passwords from environment variables ($DB_APP_PASSWORD, $DB_READONLY_PASSWORD)
    - Better security and consistency across all environments

BACKUP:
  01-create-app-user.sql.template.backup
    - Original template kept as reference
    - DO NOT USE for new projects

REASON FOR CHANGE:
  - Eliminates hardcoded passwords
  - Consistent password management (dev = staging = prod)
  - CREATE USER and GRANTS in same file (easier maintenance)
  - Follows 12-factor app principles

For existing projects, follow the migration guide in README.template.md
