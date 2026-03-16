# HestiaCP System Cleanup (v-clean-garbage)

A comprehensive cleanup script for HestiaCP servers to maintain disk space and system performance. It safely removes old logs, temporary files, and other system "garbage" without affecting user data.

## Features

*   **System Logs:** Cleans old Journalctl logs, rotated logs, and temp files.
*   **Service Logs:** Truncates and rotates logs for Nginx, Apache, Exim, Dovecot, MySQL, PHP-FPM, etc.
*   **Mail Queue:** Cleans old frozen emails and spam.
*   **Trash:** Empties user trash bins older than configured days.
*   **Database:** Purges MySQL slow query logs.
*   **Smart Safety:** Checks if files are in use before deleting.

## Installation

1.  Copy the script to your bin directory:
    ```bash
    cp v-clean-garbage /usr/local/bin/
    chmod +x /usr/local/bin/v-clean-garbage
    ```

2.  Set up a Cron Job (e.g., daily or weekly):
    ```bash
    # Run 'crontab -e' as root and add:
    0 4 * * * /usr/local/bin/v-clean-garbage >> /var/log/hestia/cleanup.log 2>&1
    ```

## Configuration

The script uses a default configuration which can be overridden by creating a file at `/etc/hestiacp-clean-garbage.conf`.

1.  Copy the sample configuration:
    ```bash
    cp clean-garbage.conf.sample /etc/hestiacp-clean-garbage.conf
    ```
2.  Edit `/etc/hestiacp-clean-garbage.conf` to adjust retention periods and enable/disable specific tasks:
    ```bash
    JOURNALCTL_RETENTION_DAYS=7
    SERVICE_LOGS_RETENTION_DAYS=30
    CLEAN_JOURNALCTL="TRUE"
    # ...
    ```

You can also edit the script header directly, but using the external config file prevents your settings from being overwritten when you update the script.

## Changelog

### v2.0 — 2026-03-14
- Added `set -o pipefail` for safer pipe error handling.
- Replaced fragile `pidof -x` concurrency check with atomic `flock` lock file.
- Added `trap ERR` that emails the admin on unexpected crash.
