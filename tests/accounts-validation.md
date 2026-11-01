# NEXUS ID manual validation

Run only on the isolated MTA-DEV server and local development database.

## Before testing

- Confirm the database is `vendrix_rpg` on the local XAMPP MariaDB instance.
- Take a database backup.
- Review and apply `database/migrations/0002_account_login_history.sql` exactly once.
- Pull the feature branch and copy the resources without copying local database credentials from Git.
- Start resources in order: shared, database, core, accounts.
- Confirm the database reports ready and the accounts resource starts without Lua errors.

## Registration

1. Register a new username using 3 characters; expect success if unused.
2. Register a new username using 20 characters; expect success if unused.
3. Try 2 and 21 characters; expect validation failure.
4. Try punctuation or whitespace in the username; expect validation failure.
5. Try a password shorter than 10 characters; expect validation failure.
6. Try a password exceeding 72 UTF-8 bytes; expect validation failure.
7. Register the same username again with different letter casing; expect duplicate rejection.
8. Inspect `accounts`: verify only a bcrypt hash is stored, never the submitted password.

## Login and sessions

1. Login with correct credentials; expect the player to unfreeze and see the account dashboard.
2. Login with an incorrect password; expect a generic credential error.
3. Attempt a second connection with the same account; expect rejection while the first session is active.
4. Logout; expect the player to freeze and return to the login view.
5. Disconnect and reconnect; expect the account lock to be released and normal login to work.
6. Restart the accounts resource; expect runtime sessions to be cleared and re-authentication required.

## Password change

1. Change password with the correct current password and a valid new password.
2. Verify the old password no longer works and the new password does.
3. Submit an incorrect current password; expect rejection and no database update.
4. Verify the updated row still records algorithm `bcrypt`.

## Login history

1. Verify successful and failed login attempts are recorded.
2. Open history and confirm only the latest 10 entries for the authenticated account appear.
3. Confirm unknown usernames are not exposed to another account's history.
4. Insert a disposable row older than 90 days in the development database and confirm cleanup removes it after the cleanup timer runs.
5. Confirm no IP address, plaintext password, or password hash is stored in history.

## Security and regression

- Trigger account events with malformed argument types and forged source elements; they must be rejected.
- Repeat requests rapidly; verify per-player cooldown and 8-per-minute cap.
- Confirm only `vendrix_core` and `vendrix_accounts` can call database exports.
- Confirm no client resource can access database credentials or the connection element.
- Inspect server logs for Lua errors and ensure no passwords or hashes appear.

## Test report

Record each case as PASS/FAIL with the MTA server log excerpt. Do not mark this checklist passed until each case is actually run.
