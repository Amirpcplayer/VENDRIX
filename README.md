# VENDRIX RPG

Initial technical foundation for the VENDRIX MTA:SA server.

## Current status
- Initial identity schema migration: applied manually to the verified local `vendrix_rpg` database.
- `vendrix_shared`: shared public constants only; no secrets.
- `vendrix_database`: native MTA MySQL connection, private resource settings, startup connection check, and asynchronous parameterized query export.
- No account, character, economy, or gameplay flows have been implemented.

## Requirements before starting the database resource
- Use an MTA server build with native `dbConnect("mysql", ...)` support.
- Use MariaDB 10.11+ and create a dedicated database user with only the required privileges on `vendrix_rpg`.
- Configure the private `vendrix_database` settings in the local MTA settings registry. Never commit credentials or paste them into chat.
- Start resources in this order: `vendrix_shared`, then `vendrix_database`, then `vendrix_core`.
- Run the local development connection test before considering deployment.

## Database API
Only server resources whose names begin with `vendrix_` may call the database exports.
Use `exports.vendrix_database:isReady()` to check readiness and
`exports.vendrix_database:queryAsync(callback, sql, ...)` for parameterized queries.
Query callbacks receive `result, affectedRows, lastInsertId, errorCode, errorMessage`.
Do not use blocking `dbPoll(..., -1)` in gameplay code.

## Player-facing text
Any future player-facing UI must use Latin-script Finglish, per project requirements.
