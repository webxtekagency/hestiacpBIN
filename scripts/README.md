# HestiaCP Custom Scripts Collection

This directory contains useful scripts for HestiaCP administration and maintenance.

## Available Scripts

### [v-sync-backups](./v-sync-backups/)
**Status:** ✅ Stable  
**Description:** Synchronizes HestiaCP's backup database with the actual filesystem. Detects and removes "phantom" backup records when files have been manually deleted.
**Path:** `scripts/v-sync-backups/v-sync-backups`

## How to use
Navigate to the specific script directory for detailed instructions.

Most scripts are designed to be linked into `/usr/local/hestia/bin/` for easy access:

```bash
# Example installation for a script
cd /path/to/script-folder
chmod +x script-name
ln -s $(pwd)/script-name /usr/local/hestia/bin/script-name
```
