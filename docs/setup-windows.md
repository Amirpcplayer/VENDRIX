# Windows Development Setup

1. Install and verify MTA:SA server.
2. Verify the exact server build/version and Lua runtime.
3. Verify XAMPP MariaDB is running and note the configured port.
4. Create/use a dedicated MariaDB account for the game server; do not use `root` at runtime.
5. Verify whether the installed MTA server build supports the intended `dbConnect` backend.
6. Keep real connection credentials in an ignored local configuration file.
7. Test resource loading and database failure behavior in a development environment before deployment.

No server settings, database tables, or dependencies are changed by this scaffold.
