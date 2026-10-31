# Database migrations

No schema migrations are included in phase 1 because the account/character data model has not been approved.

Rules:
- Use ordered, uniquely named migration files.
- Record successfully applied versions in `schema_migrations`.
- Review every migration before execution.
- Back up and test restore before risky schema changes.
- MariaDB DDL may implicitly commit; do not assume every migration can be rolled back transactionally.
- Never reset or destructively migrate production data without explicit approval.
