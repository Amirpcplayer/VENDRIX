# VENDRIX Database Design

## Target and conventions

- Target engine: MariaDB 10.11+ (the local XAMPP instance must be verified before use).
- Storage engine: InnoDB for foreign keys and transactional DML.
- Character set/collation: utf8mb4 / utf8mb4_unicode_ci by default.
- All timestamps are stored in UTC by application convention.
- IDs use BIGINT UNSIGNED to leave room for long-lived server growth.
- Database credentials must not be committed. Runtime access must use a dedicated
  least-privilege database user, not the MariaDB root account.

## Initial tables

| Table | Responsibility |
|---|---|
| schema_migrations | Applied migration versions and exact-file SHA-256 checksums |
| accounts | Login identity, password hash metadata, account status and login timestamps |
| characters | Character ownership, slot number, display name and skin |
| character_stats | One-to-one base progression and character combat stats |
| account_sessions | Hashed persistent session tokens, expiry and revocation |

## Important constraints

- Account usernames are ASCII and case-insensitive under the selected collation.
- Character names use utf8mb4 and are unique under the selected collation.
- An account cannot use the same character slot twice.
- Account deletion is restricted while characters exist; this prevents accidental
  cascading loss of character data.
- Character stats are deleted only when their owning character is deleted.
- Session rows cascade with account deletion and store token hashes, never raw tokens.
- Status values currently use 1 = active and 0 = disabled. Server code must validate
  status transitions and must not trust client-supplied account or character IDs.

## Deliberately deferred

Wallets, inventory, weapons, jobs, vehicles, gangs, factions, territories, housing,
admin audit events and other gameplay domains will receive their own migrations
when those systems are designed. Do not add speculative columns to identity tables.

## Migration safety

The initial migration creates schema only and inserts no user or gameplay data.
MariaDB DDL can implicitly commit, so a partially failed migration must be inspected
and repaired deliberately; do not blindly rerun it. Keep a database backup before
applying migrations and verify the migration checksum. No production migration or
database reset is authorized by this document.

## Runtime connection

The MTA resource will connect only after the installed MTA build's MySQL backend
and local MariaDB port are verified. Credentials belong in a local ignored config,
not in Git, shared Lua, client files, or logs. SQL values must be passed as query
parameters; dynamic identifiers must come from fixed server-side allowlists.
