# HestiaCP Custom Scripts Collection

This directory contains useful scripts for HestiaCP administration and maintenance.

## Available Scripts

### [v-clean-garbage](./clean-garbage/)
**Status:** ✅ Stable
**Description:** Comprehensive system cleanup — old logs, rotated files, mail queue, spam, PHP sessions, core dumps, and SSD TRIM. Config-driven toggles per task.

### [v-backup-users-custom](./backup-users-custom/)
**Status:** ✅ Stable
**Description:** Enhanced backup wrapper with symlink support (rclone mounts), smart retention (one backup per user from previous months), and HestiaCP version guard.

### [v-github-mirror](./github-mirror/)
**Status:** ✅ Stable
**Description:** Automates mirroring of git repositories to the server. Supports private repos via SSH. Smart retention (Daily/Weekly/Monthly).

### [v-add-exim-limit](./exim-limit/)
**Status:** ✅ Stable
**Description:** Blocks outgoing emails larger than 10MB to protect IP reputation. Sends rejection messages with alternatives and notifies the admin.

### [v-system-report](./system-report/)
**Status:** ✅ Stable
**Description:** Daily health check — CPU, RAM, Disk, Load, all HestiaCP services, SSL expiry, email blacklists, and database errors. Sends HTML report to admin.

### [v-sync-backups](./v-sync-backups/)
**Status:** ✅ Stable
**Description:** Synchronizes HestiaCP's backup database with the actual filesystem. Detects and removes "phantom" backup records when files have been manually deleted.

### [v-fix-web-permissions](./fix-web-permissions/)
**Status:** ✅ Stable
**Description:** Fixes `public_html` ownership and permissions — the gap `v-rebuild-web-domain` doesn't cover. Auto-detects CMS (WordPress, Laravel, static) and applies specific rules. Supports `--audit` and `--dry` modes.

### [v-security-audit](./security-audit/)
**Status:** ✅ Stable
**Description:** A comprehensive, zero-dependency security auditing tool. Scans system hardening, per-domain file-level security (PHP malware, ClamAV, etc.), external HTTP attack surfaces, and features an offensive self-attack simulation module. Produces a scored report with actionable findings.

## How to use
Navigate to the specific script directory for detailed instructions.

Most scripts are designed to be linked into `/usr/local/hestia/bin/` for easy access:

```bash
# Example installation for a script
cd /path/to/script-folder
chmod +x script-name
ln -s $(pwd)/script-name /usr/local/hestia/bin/script-name
```
