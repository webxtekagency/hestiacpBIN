# HestiaCP Custom Backup Wrapper (v-backup-users-custom)

A wrapper script for HestiaCP's backup system that adds reliability improvements and custom logic for handling backups, particularly useful for systems with external mounted backups or symlinks.

## Features

*   **Symlink Patching:** Automatically patches `v-delete-user-backup`, `v-restore-user`, and listing commands to correctly handle symlinked backup files (crucial for rclone mounts or external storage).
*   **Retention Control:** Can enforce a "keep only one old backup" policy to save space.
*   **Detailed Logging:** Provides enhanced logging for the backup process.
*   **Error Handling:** Retries and better error reporting.

## Installation

1.  Copy the script to your bin directory:
    ```bash
    cp v-backup-users-custom /usr/local/bin/
    chmod +x /usr/local/bin/v-backup-users-custom
    ```

2.  Set up a Cron Job (replacing the standard v-backup-users):
    ```bash
    # Run 'crontab -e' as root and add:
    5 3 * * * /usr/local/bin/v-backup-users-custom >> /var/log/hestia/backup-custom.log 2>&1
    ```

## Configuration

The script uses a default configuration which can be overridden by creating a file at `/etc/hestiacp-backup-custom.conf`.

1.  Copy the sample configuration:
    ```bash
    cp backup-custom.conf.sample /etc/hestiacp-backup-custom.conf
    ```
2.  Edit the file to configure admin overrides or retention settings:
    ```bash
    # Keep only 1 backup per user from previous months (TRUE/FALSE)
    KEEP_ONLY_ONE_OLD_BACKUP="TRUE"
    ```

## How it Works

This script acts as a supervisor for the standard `v-backup-user` command. It iterates through all users, triggers their backup, and applies fixes to the HestiaCP core scripts on-the-fly to ensure they can read/write to symlinked destinations if necessary.

## Changelog

### v2.0 — 2026-03-14
- Added `set -o pipefail` for safer pipe error handling.
- Replaced `eval "$log_cmd"` with a safe `_log()` helper (removes code injection vector).
- Added HestiaCP version compatibility guard before patching core scripts (`v-delete-user-backup`, `v-restore-user`).
- Added `trap ERR` that sends an email notification if the script crashes unexpectedly.
