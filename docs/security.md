# Security Baseline

- Treat all client events and arguments as untrusted.
- Validate sender, permission, character state, value ranges, and request frequency server-side.
- Keep balances, inventory, rewards, ownership, and combat outcomes server-authoritative.
- Use parameterized database queries; never concatenate untrusted input into SQL.
- Use least-privilege database credentials.
- Do not log passwords, session tokens, or connection strings.
- Make sensitive operations transactional and protect against duplicate requests.
- Log administrative and economy-changing actions with enough context for audit, without secrets.
- Backups must be protected and restore-tested.
