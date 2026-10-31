# VENDRIX RPG

Initial technical scaffold for the VENDRIX MTA:SA server.

## Status
This is a starter scaffold only. It does not include gameplay features, database schema, credentials, or deployment automation.

## Requirements to verify before use
- Confirm the exact MTA:SA server version and Lua runtime.
- Confirm the available database support for `dbConnect` on this server build.
- Configure a dedicated MariaDB account with least privilege.
- Keep real credentials in a local, untracked configuration file.
- Review all files and run the acceptance checks before deployment.

## Proposed resource startup order
1. `vendrix_shared`
2. `vendrix_database`
3. `vendrix_core`

The database resource intentionally does not connect automatically yet: the exact MTA/database support and local credentials have not been verified. No database changes are made by this scaffold.

## Player-facing text
Any future player-facing UI must use Latin-script Finglish, per project requirements.
