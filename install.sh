#!/bin/bash

# HestiaCP Scripts Installer
# Installs scripts to /usr/local/hestia/bin and sets up configuration files in /etc
# Also cleans up old installations in /usr/local/bin
#
# Usage:
#   bash install.sh              — install scripts and configs only
#   bash install.sh --setup-crons  — also create/update system crontab entries

set -o pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="/usr/local/hestia/bin"
CRON_FILE="/etc/cron.d/hestiacp-custom"
SETUP_CRONS=false

# --- Parse arguments ---
for arg in "$@"; do
    case "$arg" in
        --setup-crons) SETUP_CRONS=true ;;
        --help|-h)
            echo "Usage: $0 [--setup-crons]"
            echo "  --setup-crons   Create/update /etc/cron.d/hestiacp-custom with recommended schedules"
            exit 0
            ;;
    esac
done

echo "======================================"
echo " HestiaCP Custom Tools Installer"
echo " Source: $SRC_DIR"
echo "======================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root"
    exit 1
fi

# Check if HestiaCP bin directory exists
if [ ! -d "$DEST_DIR" ]; then
    echo "ERROR: HestiaCP bin directory not found at $DEST_DIR"
    exit 1
fi

# ---------------------------------------------------------------------------
# install_script: copies a script to DEST_DIR, backs up existing, removes old
# ---------------------------------------------------------------------------
install_script() {
    local src="$1"
    local script_name="$2"
    local dest="$DEST_DIR/$script_name"
    local old_dest="/usr/local/bin/$script_name"

    if [ -f "$src" ]; then
        # Backup existing production script (non-destructive upgrade)
        if [ -f "$dest" ]; then
            local bak="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
            cp "$dest" "$bak" && echo "  -> Backed up existing: $bak"
        fi
        cp "$src" "$dest"
        chmod +x "$dest"
        echo "  -> [OK] $script_name installed to $dest"

        # Remove old location if present
        if [ -f "$old_dest" ]; then
            rm -f "$old_dest"
            echo "  -> Removed legacy: $old_dest"
        fi
    else
        echo "  -> [ERROR] Source not found: $src"
    fi
}

# ---------------------------------------------------------------------------
# install_config: copies .sample config to /etc/ only if not already present
# ---------------------------------------------------------------------------
install_config() {
    local src="$1"
    local dest="$2"

    if [ ! -f "$dest" ]; then
        if [ -f "$src" ]; then
            cp "$src" "$dest"
            echo "  -> [OK] Config installed: $dest"
            echo "  -> [IMPORTANT] Edit $dest before running the script."
        else
            echo "  -> [ERROR] Sample config not found: $src"
        fi
    else
        echo "  -> [INFO] Config already exists (skipped): $dest"
    fi
}

# ---------------------------------------------------------------------------
# add_cron_entry: idempotent — adds a line to CRON_FILE only if not present
# Uses a unique tag comment to identify each entry
# ---------------------------------------------------------------------------
add_cron_entry() {
    local tag="$1"      # unique identifier for this entry
    local schedule="$2" # e.g. "30 4 * * 0"
    local command="$3"  # e.g. "root /usr/local/hestia/bin/v-clean-garbage >> /var/log/..."

    if grep -q "# hestiacp-custom:$tag" "$CRON_FILE" 2>/dev/null; then
        echo "  -> [INFO] Cron already exists: $tag (skipped)"
    else
        {
            echo "# hestiacp-custom:$tag"
            echo "$schedule $command"
            echo ""
        } >> "$CRON_FILE"
        echo "  -> [OK] Cron added: $tag ($schedule)"
    fi
}

# ---------------------------------------------------------------------------
# INSTALL SCRIPTS
# ---------------------------------------------------------------------------

echo ""
    # Process specific script directories manually to maintain exact mapping
    echo "--- Installing Scripts ---"

echo "v-backup-users-custom:"
install_script "$SRC_DIR/scripts/backup-users-custom/v-backup-users-custom" "v-backup-users-custom"
install_config "$SRC_DIR/scripts/backup-users-custom/backup-custom.conf.sample" "/etc/hestiacp-backup-custom.conf"

echo "v-clean-garbage:"
install_script "$SRC_DIR/scripts/clean-garbage/v-clean-garbage" "v-clean-garbage"
install_config "$SRC_DIR/scripts/clean-garbage/clean-garbage.conf.sample" "/etc/hestiacp-clean-garbage.conf"

echo "v-github-mirror:"
install_script "$SRC_DIR/scripts/github-mirror/v-github-mirror" "v-github-mirror"
# Main config contains user repos — never overwrite it
if [ ! -f "/etc/hestiacp-github-mirror.conf" ]; then
    install_config "$SRC_DIR/scripts/github-mirror/github-mirror.conf.sample" "/etc/hestiacp-github-mirror.conf"
else
    echo "  -> [INFO] Config already exists (skipped): /etc/hestiacp-github-mirror.conf"
fi
install_config "$SRC_DIR/scripts/github-mirror/github-mirror.settings.sample" "/etc/hestiacp-github-mirror.settings"

echo "v-add-exim-limit:"
install_script "$SRC_DIR/scripts/exim-limit/v-add-exim-limit" "v-add-exim-limit"
install_config "$SRC_DIR/scripts/exim-limit/exim-limit.conf.sample" "/etc/hestiacp-exim-limit.conf"

echo "v-system-report:"
install_script "$SRC_DIR/scripts/system-report/v-system-report" "v-system-report"
install_config "$SRC_DIR/scripts/system-report/system-report.conf.sample" "/etc/hestiacp-system-report.conf"

echo "v-sync-backups:"
install_script "$SRC_DIR/scripts/v-sync-backups/v-sync-backups" "v-sync-backups"

# ---------------------------------------------------------------------------
# CRON SETUP (only if --setup-crons was passed)
# ---------------------------------------------------------------------------

if [ "$SETUP_CRONS" = true ]; then
    echo ""
    echo "--- Setting Up Cron Jobs ---"
    echo "Target: $CRON_FILE"

    # Create file with header if it doesn't exist
    if [ ! -f "$CRON_FILE" ]; then
        cat > "$CRON_FILE" << 'CRONHEADER'
# HestiaCP Custom Tools — Cron Schedule
# Managed by install.sh — do not edit manually, re-run with --setup-crons
# Each entry is tagged for idempotent updates.
SHELL=/bin/bash
PATH=/usr/local/hestia/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

CRONHEADER
        echo "  -> Created $CRON_FILE"
    fi

    ts="$(date +%Y%m%d-%H%M%S)"
    for legacy_cron in /etc/cron.d/hestia-github-mirror /etc/cron.d/hestia-github-mirror-weekly; do
        if [ -f "$legacy_cron" ]; then
            mv "$legacy_cron" "${legacy_cron}.disabled.${ts}"
            echo "  -> Disabled legacy cron: ${legacy_cron}.disabled.${ts}"
        fi
    done

    # v-clean-garbage: every Sunday at 04:30
    add_cron_entry "clean-garbage" \
        "30 4 * * 0" \
        "root /usr/local/hestia/bin/v-clean-garbage >> /var/log/hestia/clean-garbage.log 2>&1"

    # v-github-mirror: every 12 hours (silent, email only on failure)
    add_cron_entry "github-mirror-sync" \
        "0 */12 * * *" \
        "root /usr/local/hestia/bin/v-github-mirror >> /var/log/hestia/github-mirror.cron.log 2>&1"

    # v-github-mirror: weekly forced notification (Sunday 06:00)
    add_cron_entry "github-mirror-weekly-report" \
        "0 6 * * 0" \
        "root /usr/local/hestia/bin/v-github-mirror --force-notification >> /var/log/hestia/github-mirror.cron.log 2>&1"

    # v-system-report: every Sunday at 08:00 (end of maintenance window)
    add_cron_entry "system-report" \
        "0 8 * * 0" \
        "root /usr/local/hestia/bin/v-system-report >> /var/log/hestia/system-report.log 2>&1"

    chmod 644 "$CRON_FILE"

    echo ""
    echo "  NOTE: v-backup-users-custom is NOT added to system cron."
    echo "        Add it from the HestiaCP panel (Admin > Cron Jobs)"
    echo "        for full HestiaCP integration (backup history tracking)."
    echo "        Suggested schedule: 0 2 * * * /usr/local/hestia/bin/v-backup-users-custom"
fi

# ---------------------------------------------------------------------------
# DONE
# ---------------------------------------------------------------------------

echo ""
echo "======================================"
echo " Installation complete!"
echo ""
echo " Scripts: $DEST_DIR"
echo " Configs: /etc/hestiacp-*.conf"
if [ "$SETUP_CRONS" = true ]; then
    echo " Crons:   $CRON_FILE"
else
    echo ""
    echo " TIP: Run with --setup-crons to create cron schedules automatically."
    echo "      Or see README.md for the recommended cron schedules."
fi
echo "======================================"
