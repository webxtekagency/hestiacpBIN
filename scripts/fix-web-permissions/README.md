# v-fix-web-permissions

Fixes file ownership and permissions inside `public_html` for any HestiaCP web domain, with full CMS-specific hardening and a universal security scan.

**This fills a gap in HestiaCP's built-in `v-rebuild-web-domain`**, which only repairs Hestia's own config directories (`conf/web/`, `ssl/`, `$USER_DATA`) — it does **not** touch files inside `public_html/`.

---

## The Problem

Broken permissions are one of the most common causes of **403 Forbidden** errors, failed CMS updates, and file upload failures. Common triggers:

- CMS auto-updates (WordPress, Joomla, etc.) writing as `www-data`
- SCP/SFTP uploads as `root`
- Manual `tar` extractions without `--no-same-owner`
- Restoring backups from a different server
- PHP-FPM pool misconfiguration

### Why does this happen and is it safe to change?

In standard HestiaCP environments, the web architecture works like this:
1. **Nginx (`www-data`)** serves static files (images, CSS, JS). It only needs **read** access (`644` / `755`), so group ownership is irrelevant.
2. **PHP-FPM (`user`)** runs PHP scripts and handles uploads/updates. It needs **write** access to specific folders.

If you extract a `.tar.gz` as `root`, or an old WordPress instance writes files as `www-data`, your PHP-FPM pool (running as `johndoe`, for example) will be locked out. This causes silent update failures, `403 Forbidden` errors on uploads, and breaks caching plugins.

This script safely re-aligns all files back to the expected `user:user` ownership and applies standard `755/644` base permissions, ensuring your PHP-FPM pool has native write access to its own files without relying on dangerous `777` (world-writable) fallbacks.

---

## What It Does

### Base Fix (all CMS types)

| Operation | Detail |
|---|---|
| **Ownership** | Recursive `chown user:user` on `public_html/` |
| **Over-permissive dirs** | Fixes dirs with world-write bit (`/002`) → `755` |
| **Over-permissive files** | Fixes files with group/world-write bit (`/022`) → `644` |
| **Never made more permissive** | Files already at `400`, `440`, `444`, `600` etc. are left alone |

### Automatically Excluded (never touched)

- `cgi-bin/` and `.well-known/` directories
- `*.cgi`, `*.pl`, `*.sh` files (preserve executable scripts)
- `.htaccess` files
- `.env` files (handled separately per CMS)
- `artisan`, `bin/console`, `bin/magento` (handled as executables)

---

## CMS-Specific Handling

The script auto-detects the CMS and applies targeted rules on top of the base fix.

### WordPress

| File / Directory | Permission | Notes |
|---|---|---|
| `wp-config.php` | `640` | Blocks world-read of DB credentials |
| `wp-content/debug.log` | `640` | Prevents exposure of SQL errors and paths |
| `wp-content/uploads/` | `755` dirs, `user:user` | PHP-FPM writes media uploads |
| `wp-content/cache/` | `755` dirs, `user:user` | Cache plugins write here |
| `wp-content/upgrade/` | `755` dirs, `user:user` | Core auto-updates |
| `wp-content/w3tc-config/` | `755` dirs, `user:user` | W3 Total Cache |
| `wp-content/wc-logs/` | `755` dirs, `user:user` | WooCommerce logs |

### Laravel

| File / Directory | Permission | Notes |
|---|---|---|
| `.env`, `.env.local`, `.env.production`, `.env.staging` | `640` | Credentials and config secrets |
| `artisan` | `755` | CLI entry point must be executable |
| `storage/` | `775` dirs, `user:user` | Logs, cache, sessions, views |
| `bootstrap/cache/` | `775` dirs, `user:user` | Compiled config and routes |

### Symfony

| File / Directory | Permission | Notes |
|---|---|---|
| `.env*` | `640` | Same as Laravel |
| `bin/console` | `755` | Symfony CLI entry point |
| `var/` | `775` dirs, `user:user` | Cache and logs |

### Drupal (standard)

| File / Directory | Permission | Notes |
|---|---|---|
| `sites/default/settings.php` | `444` | Read-only after installation (Drupal requirement) |
| `sites/default/settings.local.php` | `444` | Read-only |
| `sites/default/services.yml` | `444` | Read-only |
| `sites/default/` (dir) | `555` | Prevents creation of new files in config dir |
| `sites/default/files/` | `755` dirs, `user:user` | Uploaded files |
| `sites/default/private/` | `750` dirs, `user:user` | Private files (no public access) |

### Drupal (Composer layout — Drupal 9/10+)

Same as above but with webroot at `public_html/web/` instead of `public_html/`.

### Joomla

| File / Directory | Permission | Notes |
|---|---|---|
| `configuration.php` | `640` | DB credentials |
| `cache/`, `tmp/`, `logs/`, `images/`, `media/` | `755` dirs, `user:user` | Writable by CMS |

### Magento

| File / Directory | Permission | Notes |
|---|---|---|
| `app/etc/env.php` | `640` | DB, cache, and search credentials |
| `app/etc/config.php` | `640` | Deployment config |
| `app/etc/` (dir) | `750` | Restricts directory listing |
| `bin/magento` | `755` | CLI entry point |
| `var/`, `generated/` | `775`, `user:user` | Cache, logs, DI |
| `pub/media/` | `775`, `user:user` | Media uploads |
| `pub/static/` | `755` | Generated static assets |

### PrestaShop

| File / Directory | Permission | Notes |
|---|---|---|
| `config/settings.inc.php` | `640` | PS 1.6 DB credentials |
| `app/config/parameters.php` | `640` | PS 1.7+ DB credentials |
| `app/config/parameters.yml` | `640` | PS 1.7+ config |
| `config/` (dir) | `750` | Restrict directory access |
| `cache/`, `log/`, `img/`, `upload/`, `download/`, `mails/`, `translations/`, `themes/` | `755`, `user:user` | Writable by CMS |
| `var/`, `cache/` (above webroot) | `775`, `user:user` | PS 1.7+ framework dirs |

### OpenCart

| File / Directory | Permission | Notes |
|---|---|---|
| `config.php` | `640` | DB credentials |
| `admin/config.php` | `640` | Admin DB credentials |
| `system/storage/` | `755`, `user:user` | Cache, sessions, downloads |
| `image/cache/`, `image/catalog/` | `755`, `user:user` | Generated images |

> **Note:** In OpenCart 2.x, `system/storage/` is inside `public_html/` which is a security risk. OpenCart 3.x moved it above the webroot. The script warns if it detects this configuration.

---

## Security Scan

Runs automatically on **every domain** regardless of CMS:

| Check | Action |
|---|---|
| `.git/` inside `public_html` | `[WARN]` — exposes entire codebase and history |
| `.env` inside `public_html` | `[WARN]` + hardened to `640` |
| `install/`, `installation/`, `setup/` directories | `[WARN]` — must be removed from production |
| `phpinfo.php`, `test.php`, `info.php`, `debug.php` | `[WARN]` — remove debug files |
| `composer.json` / `composer.lock` in `public_html` | `[WARN]` — exposes dependency versions |
| `wp-config-sample.php` on non-WordPress site | `[WARN]` — leftover file |

---

## Safety Features

### Custom permissions sentinel

If a domain uses custom permissions (CGI, custom PHP-FPM pools, manually hardened files), create this file to permanently skip it:

```bash
touch /home/USER/web/DOMAIN/public_html/.no-fix-permissions
```

The script logs `[SKIP]` and moves on. The file is never deleted by the script.

### PHP-FPM pool detection

If a PHP-FPM pool is detected running as a different user than the HestiaCP domain user, the script emits a `[WARN]` before applying ownership changes. This prevents breaking sites with atypical pool configurations.

### Only fixes over-permissive

The base file fix only touches files with the group or world **write bit** set (`-perm /022`). Files already more restrictive than `644` (e.g. `444`, `600`) are **never** made more permissive.

---

## Usage

```bash
# Audit entire server (read-only, no changes)
v-fix-web-permissions --all --audit

# Dry-run — show what would change without applying
v-fix-web-permissions --all --dry

# Fix a single domain
v-fix-web-permissions admin example.com

# Fix all domains for a user
v-fix-web-permissions admin

# Fix all domains on the server
v-fix-web-permissions --all
```

### CMS Override

Force a specific CMS mode, skipping auto-detection:

```bash
v-fix-web-permissions admin example.com --wordpress
v-fix-web-permissions admin example.com --drupal
v-fix-web-permissions admin example.com --laravel
v-fix-web-permissions admin example.com --symfony
v-fix-web-permissions admin example.com --magento
v-fix-web-permissions admin example.com --joomla
v-fix-web-permissions admin example.com --prestashop
v-fix-web-permissions admin example.com --opencart
v-fix-web-permissions admin example.com --static
```

### CMS Filter

Process only domains of a specific CMS type (auto-detected), skip all others:

```bash
v-fix-web-permissions --all --filter-wordpress
v-fix-web-permissions --all --filter-drupal
v-fix-web-permissions --all --filter-joomla
v-fix-web-permissions --all --filter-laravel
v-fix-web-permissions --all --filter-symfony
v-fix-web-permissions --all --filter-magento
v-fix-web-permissions --all --filter-opencart
v-fix-web-permissions --all --filter-prestashop
v-fix-web-permissions --all --filter-composer
v-fix-web-permissions --all --filter-static
v-fix-web-permissions --all --filter-generic
```

### Combining flags

```bash
# Preview only WordPress domains on the whole server
v-fix-web-permissions --all --filter-wordpress --dry

# Force Drupal mode and audit a specific domain
v-fix-web-permissions admin example.com --drupal --audit

# Fix only WP sites for a specific user
v-fix-web-permissions johndoe --filter-wordpress
```

---

## Logging

### Terminal output

All output is colour-coded:

| Tag | Meaning |
|---|---|
| `[OK]` | Already correct, no action needed |
| `[FIX]` | Change was applied |
| `[DRY]` | Would change (dry-run mode) |
| `[WARN]` | Problem detected or security issue |
| `[SKIP]` | Domain skipped (sentinel file or CMS filter) |

### Change log file

Every LIVE run generates a timestamped log at:

```
/var/log/hestia/fix-permissions/YYYYMMDD-HHMMSS.log
```

Records every changed file with before/after permissions and ownership:

```
# [johndoe] example.com
CHANGED | DIR  | /home/johndoe/.../public_html          | 775 johndoe:www-data | 755 johndoe:johndoe
CHANGED | FILE | /home/johndoe/.../public_html/wp-config.php | 644 johndoe:www-data | 640 johndoe:johndoe
# Total changes: 2
```

The log directory is `chmod 700` (root-only). If no changes were made, the log file is automatically deleted.

### HestiaCP system log

Results are written to `/var/log/hestia/system.log` (visible in HestiaCP panel) via `log_event`, consistent with all other scripts in this suite.

---

## Installation

Via `install.sh` (recommended):

```bash
bash install.sh
```

Manual:

```bash
ln -s /root/hestiacp-useful-tools/scripts/fix-web-permissions/v-fix-web-permissions /usr/local/hestia/bin/v-fix-web-permissions
chmod +x /usr/local/hestia/bin/v-fix-web-permissions
```

---

## Recommended Workflow

```bash
# 1. Audit first — no changes, just see what's wrong
v-fix-web-permissions --all --audit

# 2. Dry-run on a single domain to verify output
v-fix-web-permissions admin example.com --dry

# 3. Apply to the full server
v-fix-web-permissions --all

# 4. Review the change log
cat /var/log/hestia/fix-permissions/$(ls -t /var/log/hestia/fix-permissions/ | head -1)
```

---

## Cron (Optional)

Weekly audit with output logged:

```bash
# Every Sunday at 3 AM
0 3 * * 0 /usr/local/hestia/bin/v-fix-web-permissions --all >> /var/log/hestia/fix-permissions/cron.log 2>&1
```
