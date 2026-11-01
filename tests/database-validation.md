# Database migration validation

Run these checks only against a disposable development database or after taking
and verifying a backup. Do not use a production database for first-run testing.

## Before applying

- Confirm the selected database name and MariaDB server/port.
- Confirm the database is empty or inspect every existing object first.
- Verify the backup can be restored.
- Review the complete SQL migration.
- Calculate and record the migration file SHA-256 checksum.

## After applying 0001

Run in phpMyAdmin or the MariaDB client:

```sql
SHOW TABLES;

SHOW CREATE TABLE accounts;
SHOW CREATE TABLE characters;
SHOW CREATE TABLE character_stats;
SHOW CREATE TABLE account_sessions;
SHOW CREATE TABLE schema_migrations;

SELECT
    TABLE_NAME,
    ENGINE,
    TABLE_COLLATION
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN (
      'schema_migrations',
      'accounts',
      'characters',
      'character_stats',
      'account_sessions'
  )
ORDER BY TABLE_NAME;
```

Expected: exactly the five VENDRIX tables above are present, use InnoDB, and
use utf8mb4-compatible collations. Foreign keys must exist on characters,
character_stats and account_sessions.

The migration runner is not implemented yet, so the migration version is not
automatically inserted into schema_migrations by this SQL file. Do not manually
mark it as applied until the complete migration has succeeded and its checksum
has been calculated.

## Not yet tested

This checklist does not claim that the SQL has been executed. SQL execution,
foreign-key verification, Lua connection tests and failure-path tests remain
pending on the user's local development environment.
