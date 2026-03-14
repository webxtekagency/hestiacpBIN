# Exim Limit Monitor (v-add-exim-limit)

A tool to enforce email size limits on HestiaCP servers, protecting IP reputation by preventing large outgoing attachments while optionally allowing large incoming emails.

## Features

*   **Configurable Limit:** Set maximum email size (default 10MB).
*   **Smart Scope:** Can limit ONLY outgoing emails (authenticated users) or ALL emails (incoming + outgoing).
    *   **Outgoing Only (Default/Recommended):** Prevents your users from sending huge attachments that could hurt IP reputation, but allows them to receive large emails from outside.
    *   **All Emails:** Saves disk space by blocking large incoming emails as well.
*   **User-Friendly Rejection:** Sends a clear error message suggesting alternatives (WeTransfer, Google Drive).
*   **Admin Notifications:** Alerts the admin when a message is blocked.

## Installation

1.  Copy the script to your bin directory:
    ```bash
    cp v-add-exim-limit /usr/local/bin/
    chmod +x /usr/local/bin/v-add-exim-limit
    ```

2.  Run the installer:
    ```bash
    bash /usr/local/bin/v-add-exim-limit
    ```

## Configuration

The script uses a default configuration which can be overridden by creating a file at `/etc/hestiacp-exim-limit.conf`.

1.  Copy the sample configuration:
    ```bash
    cp exim-limit.conf.sample /etc/hestiacp-exim-limit.conf
    ```
2.  Edit the file to configure the limit scope:
    ```bash
    # TRUE  = Limit ONLY outgoing emails (Recommended to prevent IP bans)
    # FALSE = Limit BOTH incoming and outgoing emails (Saves disk space)
    LIMIT_OUTGOING_ONLY="TRUE"
    ```

3.  Apply changes by running the installer again:
    ```bash
    bash /usr/local/bin/v-add-exim-limit
    ```

## Large Email Monitor (Optional)

This package includes a Python script `monitor_large_emails.py` that monitors the Exim log for rejected large emails and sends a digest alert to the administrator.

### Installation

1.  Copy the script to your bin directory:
    ```bash
    cp monitor_large_emails.py /usr/local/bin/
    chmod +x /usr/local/bin/monitor_large_emails.py
    ```

2.  **Configuration (Important):**
    Open `/usr/local/bin/monitor_large_emails.py` and update the configuration section at the top:
    ```python
    # --- Configuration ---
    ADMIN_EMAIL = "your-email@domain.com"      # Where to send alerts
    SENDER_EMAIL = "monitor@your-server.com"   # Sender address (must be valid)
    ```

3.  Setup Cron Job:
    Add a cron job to run the script every minute (or as desired):
    ```bash
    echo "*/1 * * * * root /usr/local/bin/monitor_large_emails.py" > /etc/cron.d/exim-large-monitor
    ```

### Testing

You can test the email delivery by running:
```bash
/usr/local/bin/monitor_large_emails.py --test
```
This will send a test alert to the configured ADMIN_EMAIL without scanning logs.

