# Phase 1 acceptance checklist

- [ ] Confirm exact MTA server version and Lua runtime.
- [ ] Verify every `meta.xml` reference points to an existing file/resource.
- [ ] Verify resources start in the documented dependency order.
- [ ] Run Lua syntax checks with a compatible Lua/MTA-aware checker.
- [ ] Confirm the database resource remains unavailable with missing settings.
- [ ] Create a dedicated least-privilege MariaDB user; do not use root.
- [ ] Configure private database settings locally without committing credentials.
- [ ] Confirm the resource's asynchronous startup check succeeds against the DEV database.
- [ ] Confirm parameterized SELECT and INSERT/UPDATE behavior in DEV using disposable test data.
- [ ] Confirm query errors and connection loss are handled without server-blocking waits.
- [ ] Confirm no credentials or database schema changes are included in the resource code.
- [ ] Confirm no gameplay systems were added.
- [ ] Review `.gitignore` and the local MTA settings registry for secret exposure.
- [ ] Test on a separate development server before production use.

The code has not been run on the user's Windows MTA server yet; local acceptance checks remain pending.
