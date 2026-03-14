# HestiaCP Custom Tools Collection

This repository contains a collection of custom scripts and tools for production HestiaCP systems.

A personal contribution to the HestiaCP community — hopefully useful to others. Thank you to the HestiaCP team for your continuous hard work!

## 📂 Tools Included

### 1. [System Cleanup (v-clean-garbage)](clean-garbage/)
A comprehensive cleanup script to maintain server health.
- Cleans old system logs (Journalctl), rotated logs, and temp files.
- Manages mail queue and spam retention.
- Configuration-driven toggles per task.

### 2. [Custom Backup Wrapper (v-backup-users-custom)](backup-users-custom/)
Enhances the default HestiaCP backup system.
- **Symlink Support:** Patches core scripts to handle backups to symlinked locations (e.g., rclone mounts).
- **Smart Retention:** Option to keep only one backup per user from previous months.
- **Version Guard:** Patches only applied on validated HestiaCP versions (safe on upgrades).

### 3. [GitHub Mirror (v-github-mirror)](github-mirror/)
Automates mirroring of git repositories to your server.
- Perfect for backing up source code of static sites or web apps.
- Supports private repositories via SSH.
- **Smart Retention** (Daily/Weekly/Monthly) for versioned backup history.

### 4. [Exim Limit Monitor (v-add-exim-limit)](exim-limit/)
Protects your server's IP reputation.
- Blocks outgoing emails larger than 10MB.
- Sends rejection messages to users with alternatives.
- Notifies the admin when a block occurs.

### 5. [System Health Report (v-system-report)](system-report/)
Daily health check for your server.
- Checks CPU, RAM, Disk, Load averages.
- Monitors all HestiaCP services (Nginx, Apache, PHP-FPM, MySQL, Exim, etc.).
- Checks SSL expiry, email blacklists, and database errors.
- Sends a detailed HTML report to the admin.

## 🚀 Installation

```bash
git clone git@github.com:webxtekagency/hestiacpBIN.git /root/hestiacpBIN
cd /root/hestiacpBIN
bash install.sh
```

Each tool has its own directory with a `README.md` and a `.conf.sample` file. Configuration files in `/etc/` are **never committed** to this repository.

## 📋 Changelog

### v2.0 — 2026-03-14
- **All scripts:** Added `set -o pipefail` to catch silent pipe failures.
- **All scripts:** Added `trap INT TERM ABRT` email notification for crashes.
- **`v-backup-users-custom`:** Safe `_log()` helper & HestiaCP version guard.
- **`v-github-mirror`:** Dynamic timestamps, safe user home detection, safe `find`.
- **`v-system-report`:** Dynamic PHP detection, `flock` atomic concurrency.
- **`v-clean-garbage`:** Replaced `pidof -x` with `flock` for concurrency control.
- **`install.sh`:** Creates a timestamped backup before overwrite.

## ⚠️ Disclaimer

These scripts are provided "as is". While used in production, please review and test in your environment before deployment.
