# HestiaCP GitHub Mirror Tool (v-github-mirror)

This tool automatically clones and updates GitHub repositories (or GitLab/Bitbucket) into your HestiaCP users' directories. This ensures that **source code for static sites** (like Astro, Next.js hosted on Cloudflare Pages) is included in your standard HestiaCP backups (`v-backup-user`).

## Features

*   **Multi-User:** Supports mirroring repos for different HestiaCP users.
*   **Simple Authentication:** Uses the server's ROOT SSH key for all git operations (simpler setup).
*   **Secure Permissions:** Automatically fixes file ownership (`chown user:user`) so HestiaCP backups work correctly.
*   **Flexible Retention:** Choose between **Overwrite** (incremental git mirror) or **Versioned** (keep N copies).
*   **Email Alerts:** Notifies the server admin (`root` email alias) if a clone or update fails.
    *   **Configurable:** Choose to receive emails always or only on failure.

## Installation

1.  Copy the script to your bin directory:
    ```bash
    cp v-github-mirror /usr/local/bin/
    chmod +x /usr/local/bin/v-github-mirror
    ```

2.  Create the configuration file:
    ```bash
    cp github-mirror.conf.sample /etc/hestiacp-github-mirror.conf
    ```

3.  Set up a Cron Job (e.g., every 12 hours):
    ```bash
    # Run 'crontab -e' as root and add:
    0 */12 * * * /usr/local/bin/v-github-mirror >> /var/log/hestia/github-mirror.cron.log 2>&1
    ```

## Configuration

Edit `/etc/hestiacp-github-mirror.conf`. The format uses **pipes (`|`)** as separators to handle git URLs correctly:

`USER|REPO_URL|BRANCH|DESTINATION_PATH[|RETENTION_MODE|RETENTION_COUNT]`

*   **USER:** The HestiaCP username.
*   **REPO_URL:** The git clone URL (HTTPS or SSH).
*   **BRANCH:** The branch to track.
*   **DESTINATION_PATH:** Path relative to the user's home directory.
*   **RETENTION_MODE:** (Optional)
    *   `overwrite`: (Default) Standard git mirror (updates the same folder).
    *   `versioned`: Keeps the last N copies (defined by `RETENTION_COUNT`).
    *   `backup`: Uses **Smart Retention** (Daily/Weekly/Monthly) configured in the script header.
*   **RETENTION_COUNT:** (Optional) Number of copies to keep (only for `versioned` mode).

**Examples:**
```
# Standard Overwrite (Fastest, best for big repos)
client1|git@github.com:my-org/site.git|main|web/example.com/private/src|overwrite

# Versioned (Keeps last 5 zip-like folders)
client1|git@github.com:my-org/site.git|main|web/example.com/private/src|versioned|5

# Smart Backup (Uses global Daily/Weekly/Monthly settings)
client1|git@github.com:my-org/site.git|main|web/example.com/private/src|backup
```

## Global Configuration (Smart Backup & Notifications)

You can override the default settings (Notification preferences and Smart Backup Retention counts) by creating a file at `/etc/hestiacp-github-mirror.settings`.

1.  Copy the sample settings file:
    ```bash
    cp github-mirror.settings.sample /etc/hestiacp-github-mirror.settings
    ```
2.  Edit the file to configure email alerts and retention logic:
    ```bash
    NOTIFY_ON_SUCCESS="false"
    ENABLE_DAILY_BACKUPS="true"
    # ...
    ```

If this file does not exist, the script uses the defaults defined in its header.

## Authentication (Private Repos)

Since the script runs as root, you only need to add the **Server's Root SSH Key** to your GitHub account.

1.  **Get the Root SSH Key:**
    ```bash
    cat /root/.ssh/id_rsa.pub
    ```

2.  **Add to GitHub:**
    *   Go to Repository -> Settings -> **Deploy Keys** (for single repo access).
    *   OR go to User Settings -> **SSH and GPG Keys** (for global access).

## Logs & Notifications

*   **Logs:** Stored in `/var/log/hestia/github-mirror.log`
*   **Email Reports:**
    *   Sent to the **HestiaCP Admin Email** (detected automatically from `admin` user or `hestia.conf`).
    *   Sends a summary report (HTML format) on completion, listing successful and failed repositories.
    *   Includes details like execution time and repository status.
    *   **Configuration:** You can change `NOTIFY_ON_SUCCESS="true"` to `"false"` in the script header if you only want to be notified when errors occur.

### Weekly Reports (Heartbeat)

You can force a notification (even if `NOTIFY_ON_SUCCESS="false"`) by running the script with the `--force-notification` flag. This is useful for weekly status reports.

Add this cron job to receive a weekly report (e.g., every Sunday at 10 AM):
```bash
0 10 * * 0 /usr/local/bin/v-github-mirror --force-notification >> /var/log/hestia/github-mirror.cron.log 2>&1
```

### Testing Email Configuration

To verify that email notifications are working correctly without running a full mirror sync:

```bash
v-github-mirror --test-email
```

This will send a sample "Failure" report to the configured admin email address to verify delivery.

## Changelog

### v2.0 — 2026-03-14
- Added `set -o pipefail` for safer pipe error handling.
- Fixed static `$DATE` variable in `log()` — all log entries now have accurate per-call timestamps.
- Replaced `eval echo "~$user"` with `getent passwd "$user"` (eliminates command injection risk).
- Replaced `ls -d | sort` pipelines with `find -print0 | sort -z` (safe with special chars in paths).
- Added `trap ERR` that emails the admin on unexpected crash.
