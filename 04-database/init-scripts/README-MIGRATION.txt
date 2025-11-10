=====================================================
MIGRATION NOTICE: Init Scripts Reorganization
=====================================================

As of 2025-01-10, the database init scripts have been reorganized
to implement environment-based password management.

OLD STRUCTURE:
  01-create-app-user.sql
    - Contained CREATE USER with hardcoded passwords
    - Contained GRANT statements

NEW STRUCTURE:
  00-init-users.sh
    - Unified script with CREATE USER + GRANTS
    - Passwords from environment variables ($DB_APP_PASSWORD, $DB_READONLY_PASSWORD)
    - Better security and consistency across all environments

LEGACY FILE REMOVED:
  01-create-app-user.sql
    - Old file with hardcoded passwords has been removed
    - Available in Git history if needed for reference

REASON FOR CHANGE:
  - Eliminates hardcoded passwords
  - Consistent password management (dev = staging = prod)
  - CREATE USER and GRANTS in same file (easier maintenance)
  - Follows 12-factor app principles

BREAKING CHANGE:
  - Old containers must be recreated with: docker compose down -v
  - .env.dev file is now REQUIRED (copy from .env.dev.example)
  - Passwords must be set in .env.dev before starting containers

For questions, see: 04-database/README.md
