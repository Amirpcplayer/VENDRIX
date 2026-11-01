# VENDRIX RPG

Initial technical foundation and NEXUS ID account system for the VENDRIX MTA:SA server.

## Current status

- Initial identity schema migration `0001_initial_identity.sql` is recorded as manually applied to the verified local `vendrix_rpg` database.
- `vendrix_shared`: shared public constants only; no secrets.
- `vendrix_database`: native MTA MySQL connection, private resource settings, startup connection check, parameterized asynchronous query export, and explicit caller allowlist.
- `vendrix_core`: minimal player lifecycle hooks and core logging.
- `vendrix_accounts`: NEXUS ID registration, login, password change, single active runtime session, and login history UI/backend.
- Migration `0002_account_login_history.sql` is added but is not applied automatically.

## Requirements before starting

- Use the verified MTA 1.6 server build with native `dbConnect("mysql", ...)` support.
- Use MariaDB 10.11+ and a dedicated least-privilege user on `vendrix_rpg`.
- Configure private `vendrix_database` settings locally. Never commit credentials or paste them into chat.
- Start resources in this order: `vendrix_shared`, `vendrix_database`, `vendrix_core`, `vendrix_accounts`.

## Database API

Only explicitly allowlisted resources may call the database exports. Current allowlist: `vendrix_core` and `vendrix_accounts`.

- `exports.vendrix_database:isReady()` checks the connection state.
- `exports.vendrix_database:queryAsync(requestId, sql, ...)` queues a parameterized query.
- Completion is delivered to the calling resource root through `onVendrixDatabaseQueryComplete`, including the request ID and result/error fields.

Do not pass Lua callback functions through exports and do not use blocking `dbPoll(..., -1)`.

## NEXUS ID policy

- Username: 3-20 ASCII letters, digits, or underscore.
- Password: minimum 10 characters, maximum 72 UTF-8 bytes.
- Password hashing and verification: asynchronous bcrypt through MTA's password APIs.
- One active account session per MTA server process.
- Login history retention: 90 days; latest 10 records are shown in the UI.
- All player-facing UI text uses Latin-script Finglish.

See `docs/accounts.md` for the authentication flow, security boundaries, migration notes, and known limitations.
