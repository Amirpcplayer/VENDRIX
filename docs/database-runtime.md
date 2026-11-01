# VENDRIX Database Runtime

## Connection method

The resource uses MTA's native server-side `dbConnect("mysql", ...)` support. Do not install a separate legacy MTA-MySQL module.

At startup, the resource:
1. Reads private settings belonging to `vendrix_database`.
2. Rejects missing or malformed host, port, database, username, or password values.
3. Creates one non-shared MariaDB connection.
4. Runs `SELECT 1 AS connection_ok` asynchronously.
5. Exposes the query API only after the startup check succeeds.

The connection is not created if settings are incomplete. Connection loss leaves the API unavailable; after restoring MariaDB, restart `vendrix_database`.

## Private settings

Configure these settings in the local MTA server console/settings registry. The `@` prefix marks them private to this resource:

- `@vendrix_database.db_host` — for local XAMPP, `127.0.0.1`
- `@vendrix_database.db_port` — `3306`
- `@vendrix_database.db_name` — `vendrix_rpg`
- `@vendrix_database.db_user` — a dedicated MariaDB application username
- `@vendrix_database.db_password` — that user's password

Example console commands (replace only the final password value locally; never share it):

```text
set @vendrix_database.db_host 127.0.0.1
set @vendrix_database.db_port 3306
set @vendrix_database.db_name vendrix_rpg
set @vendrix_database.db_user vendrix_app
set @vendrix_database.db_password YOUR_LOCAL_PASSWORD
```

MTA stores resource settings in its local settings registry, outside this Git repository. Protect that file and its backups. Do not use the MariaDB root account. Create a dedicated user with only the privileges needed by the application on `vendrix_rpg.*` (initially SELECT, INSERT, UPDATE and DELETE); do not grant global privileges or schema-altering permissions to the runtime account.

## Export API

### Readiness

```lua
if exports.vendrix_database:isReady() then
    -- The initial MariaDB connection check succeeded.
end
```

Only resources whose names begin with `vendrix_` may call the exports.

### Asynchronous query

```lua
local queued = exports.vendrix_database:queryAsync(
    function(result, affectedRows, lastInsertId, errorCode, errorMessage)
        if result == false then
            -- Handle the database error without exposing secrets to players.
            return
        end

        -- Process result rows or affected-row information here.
    end,
    "SELECT id, username FROM accounts WHERE username = ?",
    username
)
```

- Return value: `true` if MTA accepted the query for processing; otherwise `false`.
- Callback arguments: `result, affectedRows, lastInsertId, errorCode, errorMessage`.
- On failure, `result` is `false` and error details are supplied to the server-side callback.
- Query parameters must be strings or finite numbers, with no more than 64 values.
- SQL values must use `?` placeholders. Never concatenate player input into SQL.
- Keep identifiers (table and column names) fixed in trusted code.
- Do not call `dbPoll(queryHandle, -1)`; the API is asynchronous.

This resource does not implement account registration, login, migrations, transactions, or gameplay persistence yet.
