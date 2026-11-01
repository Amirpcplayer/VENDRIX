# VENDRIX RPG Roadmap

This roadmap starts from the confirmed project baseline: a new MTA:SA RPG server, with no custom gameplay systems approved or implemented yet.

## Phase 0 — Environment verification
- Confirm the installed MTA:SA server build and bundled Lua runtime.
- Inspect the actual server resource directory and startup configuration without changing it.
- Confirm XAMPP/MariaDB version, port, and local development database state.
- Verify MTA database backend support against the exact installed build.
- Record findings before enabling integrations.

## Phase 1 — Repository and foundation
- Keep the repository structure modular and documented.
- Establish shared constants, logging conventions, and resource lifecycle conventions.
- Keep database connection disabled until backend and local secret handling are verified.
- Add repeatable static checks and an acceptance checklist.
- No gameplay or production database changes in this phase.

## Phase 2 — Database foundation
- Approve the data model and migration naming/version strategy.
- Create a least-privilege MariaDB account for the development server.
- Implement a server-only database connection lifecycle and narrow query API.
- Add parameterized query helpers, failure handling, migration tracking, and backup/restore instructions.
- Test against a disposable development database before any production use.

## Phase 3 — Account and character foundations
- Design account and character ownership rules.
- Implement server-authoritative registration/login/session handling appropriate to MTA.
- Add character creation and persistence only after schema and security review.
- Define recovery, duplicate-request, and reconnect behavior.

## Phase 4 — Core RPG systems
Implement separately approved modules in dependency order:
- Economy and transaction ledger.
- Inventory and item definitions.
- Progression, skills, and stats.
- Jobs and rewards.
- Vehicles and ownership.
- Gangs, factions, and territories.
- Combat and related progression.

Each module must define its data ownership, server events, validation, persistence, indexes, and tests before implementation.

## Phase 5 — UI and player experience
- Select one approved visual direction before each major UI build.
- Use Latin-script Finglish for all player-facing text.
- Keep gameplay decisions and validation server-side.
- Prefer event-driven updates and avoid unnecessary per-frame work.

## Phase 6 — Integration and release readiness
- Run resource, syntax, database, security, and regression checks.
- Test realistic concurrent-player scenarios before making capacity claims.
- Prepare deployment, backup, restore, monitoring, and rollback procedures.
- Deploy only after explicit approval.

## Capacity target
The initial planning target is 32 concurrent players. This is a test target, not a performance guarantee. Capacity must be measured on the actual host with representative gameplay and database load.
