# Database migrations

Migrations are ordered, immutable schema changes for MariaDB.

## Current baseline

- `0001_initial_identity.sql` creates the initial identity schema:
  `schema_migrations`, `accounts`, `characters`, `character_stats`,
  and `account_sessions`.
- It creates no player records, passwords, starter money, or gameplay content.
- The migration is designed for MariaDB 10.11+ with InnoDB and utf8mb4.
- Do not apply it to any database until its target and backup have been verified.

## Rules

1. Use ordered, uniquely named migration files.
2. Calculate a SHA-256 checksum from the exact migration file bytes.
3. Record a version only after every statement in that migration succeeds.
4. Never edit a migration after it has been applied; add a new migration instead.
5. Review every migration and test it against a disposable development database.
6. Back up and test restore before risky schema changes.
7. MariaDB DDL can implicitly commit. Do not assume a group of CREATE/ALTER
   statements can be rolled back as one transaction.
8. Never reset or destructively migrate production data without explicit approval.

The migration runner and Lua integration are separate follow-up work. This
folder currently contains SQL source only; no automatic migration is run.
