# VENDRIX Architecture

## Authority boundaries
- Server resources are authoritative for gameplay, permissions, money, inventory, and persistence.
- Client code may render UI and submit requests, but client input is always untrusted.
- Database writes are owned by server-side services, not UI code.

## Resource responsibilities
- `vendrix_shared`: public constants and shared contracts only; no secrets.
- `vendrix_database`: database connection lifecycle and parameterized query boundary. Connection is not activated until the MTA build and database support are verified.
- `vendrix_core`: player lifecycle hooks and minimal core logging. No gameplay logic in this phase.

## Dependency direction
`vendrix_shared` <- `vendrix_database` <- `vendrix_core` is the intended startup dependency chain, with `vendrix_core` also depending on `vendrix_shared`.

Avoid circular resource dependencies. Cross-resource calls must be documented and validated.

## Data ownership
Each future domain has one authoritative server-side owner. For example, only the economy service may mutate balances; inventory code must not directly update wallet data.

## Performance
Prefer event-driven logic. Avoid per-frame database access, unnecessary timers, unbounded event handlers, and repeated expensive calculations. Measure performance under representative load before making capacity claims.
