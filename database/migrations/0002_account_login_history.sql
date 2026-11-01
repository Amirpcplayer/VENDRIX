-- VENDRIX migration: 0002_account_login_history
-- Stores account login outcomes only; no IP addresses or passwords.
-- Timestamps are supplied by the application using UTC_TIMESTAMP(3).
-- Retention policy: keep the most recent 90 days.

CREATE TABLE account_login_history (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    account_id BIGINT UNSIGNED NULL,
    attempted_username VARCHAR(20) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    result TINYINT UNSIGNED NOT NULL,
    failure_reason VARCHAR(24) CHARACTER SET ascii COLLATE ascii_bin NULL,
    created_at DATETIME(3) NOT NULL,
    PRIMARY KEY (id),
    KEY idx_login_history_account_created (account_id, created_at),
    KEY idx_login_history_created (created_at),
    CONSTRAINT fk_login_history_account
        FOREIGN KEY (account_id) REFERENCES accounts (id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT chk_login_history_result CHECK (result IN (0, 1))
) ENGINE=InnoDB
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
