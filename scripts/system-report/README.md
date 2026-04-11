# HestiaCP System Report (v-system-report)

A comprehensive system health check and reporting tool for HestiaCP servers. It performs over 20 checks including resource usage, service status, PHP/MySQL health, SSL validity, backups, and more.

## Features

*   **Extensive Checks:** CPU/RAM/Disk, Hestia Services, PHP-FPM pools, MySQL errors/crashes, Email blacklists, SSL certificates, Backups, etc.
*   **Email Reports:** Sends a detailed HTML report to the admin email.
*   **Configurable:** Enable/disable specific checks via configuration file.

## Installation

1.  Copy the script to your bin directory:
    ```bash
    cp v-system-report /usr/local/bin/
    chmod +x /usr/local/bin/v-system-report
    ```

2.  Set up a Cron Job (e.g., daily):
    ```bash
    # Run 'crontab -e' as root and add:
    0 8 * * * /usr/local/bin/v-system-report >> /var/log/hestia/system-report.log 2>&1
    ```

## Configuration

The script uses a default configuration which can be overridden by creating a file at `/etc/hestiacp-system-report.conf`.

1.  Copy the sample configuration:
    ```bash
    cp system-report.conf.sample /etc/hestiacp-system-report.conf
    ```
2.  Edit the file to enable/disable checks:
    ```bash
    CHECK_MYSQL="TRUE"
    SEND_EMAIL_REPORT="TRUE"
    # ...
    ```

## Changelog

### v2.0 — 2026-03-14
- Added `set -o pipefail` for safer pipe error handling.
- Removed duplicate `run_with_timeout()` definition (dead code eliminated).
- Replaced fragile `pidof -x` with atomic `flock` lock file.
- PHP version detection in error log analysis is now dynamic (auto-adapts to PHP 8.5+, etc.).
- Added `trap ERR` that emails the admin on unexpected crash.
