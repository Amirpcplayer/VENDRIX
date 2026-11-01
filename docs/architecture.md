# VENDRIX Architecture

## Authority boundaries
- Server resources are authoritative for accounts, sessions, gameplay, permissions, money, inventory, and persistence.
- Client code may render UI and submit requests, but client input is always untrusted.
- Database writes are owned by server-side services, not UI code.

## Resource responsibilities
- `vendrix_shared`: public constants and shared contracts only; no secrets.
- `vendrix_database`: private connection settings, database connection lifecycle, and asynchronous parameterized query boundary. The resource verifies the connection with a startup query and fails closed when configuration or MariaDB is unavailable.
- `vendrix_core`: player lifecycle hooks and minimal core logging.
- `vendrix_accounts`: account registration, login, password change, runtime session ownership, and login history. It is the only domain resource currently authorized for account-table writes.

## Dependency direction
`vendrix_shared` is foundational. `vendrix_database` depends on `vendrix_shared`; `vendrix_core` and `vendrix_accounts` depend on the shared/database foundations. Start in this order: shared, database, core, accounts.

Avoid circular resource dependencies. Cross-resource calls must be documented and validated. The database allowlist currently contains only `vendrix_core` and `vendrix_accounts`.

## Data ownership
Each domain has one authoritative server-side owner. The accounts resource owns account credentials, account status checks, session state, and login history. Future economy code must not mutate account credentials; only an economy service may mutate wallet balances.

## Database access
- Use `exports.vendrix_database:queryAsync(requestId, sql, ...)`.
- Query values must use MTA's `?` placeholders. Keep SQL identifiers fixed in trusted server code.
- The request ID is numeric and server-generated.
- Completion is routed to the calling resource root through `onVendrixDatabaseQueryComplete`; do not pass Lua functions across exports.
- Never expose the database connection element or credentials to client resources.
- Never block the server waiting for a query result.

## Performance
Prefer event-driven logic. Avoid per-frame database access, unnecessary timers, unbounded event handlers, and repeated expensive calculations. Measure performance under representative load before making capacity claims.
