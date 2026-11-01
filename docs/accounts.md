# VENDRIX NEXUS ID Accounts

## Scope

Version 1 implements registration, login, password change, one active in-memory session per account, and a 90-day login history. It does not implement email recovery, two-factor authentication, website linking, or character creation.

## Input policy

- Username: 3-20 ASCII characters, letters, digits, and underscore only.
- Password: at least 10 Unicode characters and no more than 72 UTF-8 bytes.
- Passwords use MTA's asynchronous bcrypt `passwordHash` and `passwordVerify` APIs with cost 10.
- Passwords and hashes are never sent to the client or written to logs.
- Username uniqueness and case-insensitive lookup are enforced by the existing `accounts` unique index and collation; the Lua validator applies the narrower 3-20 policy.

## Authentication flow

1. The client sends a registration or login request. The server validates the actual `client` player and requires `source == client`.
2. Per-player throttling is applied before processing.
3. Registration hashes the password asynchronously and inserts it using parameterized SQL.
4. Login fetches the account by username, checks active status, and verifies the password asynchronously.
5. A successful login acquires the in-memory account lock and marks the player authenticated server-side.
6. A second player cannot acquire an account lock while its first player session remains active.
7. Logout and player disconnect release the lock. An account resource restart clears all sessions and requires players to authenticate again.

The session map is intentionally runtime-only in v1. The pre-existing `account_sessions` table is not used for persistent reconnect tokens in this release. Server restart or resource restart therefore does not silently restore a player session.

## Password change

The player must already be authenticated and provide the current password. The server verifies the current hash, creates a new bcrypt hash asynchronously, then updates the account row with a parameterized query.

## Login history

- Records successful logins and failed attempts for syntactically valid usernames.
- Unknown usernames are stored with a NULL `account_id`; known accounts retain their account ID.
- Does not store IP addresses, passwords, or password hashes.
- Shows the latest 10 entries from the last 90 days.
- A daily asynchronous cleanup deletes rows older than 90 days.
- All timestamps are generated with `UTC_TIMESTAMP(3)`.

## Database contract

The account resource is explicitly allowlisted by `vendrix_database`. It calls:

```lua
exports.vendrix_database:queryAsync(requestId, sql, ...)
```

The call returns whether the query was queued. Completion is delivered to the calling resource root through `onVendrixDatabaseQueryComplete`, with arguments:

```text
requestId, result, affectedRows, lastInsertId, errorCode, errorMessage
```

The request ID is generated server-side. All player-supplied SQL values are bound through `?` placeholders. The client never selects table names or SQL statements.

## Migration

`database/migrations/0002_account_login_history.sql` adds only the login history table and indexes. It references the existing `accounts` table. It is not executed automatically.

Before applying it, verify the target is the local development database, take a backup, and inspect the migration. Do not run it against production.

## Resource order

Start in this order:

1. `vendrix_shared`
2. `vendrix_database`
3. `vendrix_core`
4. `vendrix_accounts`

## Known limits before production

- The 90-day cleanup is scheduled per resource lifetime; a failed cleanup is retried at the next daily interval.
- The account lock is process-local and assumes one authoritative MTA server process. A multi-server cluster would require a database-backed atomic lock design.
- Full gameplay integration must check `exports.vendrix_accounts:isPlayerAuthenticated(player)` before allowing protected gameplay.
- MTA-DEV runtime tests are still required for GUI rendering, bcrypt callbacks, DB event delivery, SQL migration, reconnects, and concurrent login attempts.
