# Phase 1 acceptance checklist

- [ ] Confirm exact MTA server version and Lua runtime.
- [ ] Verify `meta.xml` references only files/resources that exist.
- [ ] Verify resources start in the documented dependency order.
- [ ] Run Lua syntax checks with a compatible Lua/MTA-aware checker.
- [ ] Confirm the database resource fails closed while unconfigured.
- [ ] Confirm no credentials or database schema changes are included.
- [ ] Confirm no gameplay systems were added.
- [ ] Review `.gitignore` against actual local config and backup paths.
- [ ] Test on a separate development server before production use.
