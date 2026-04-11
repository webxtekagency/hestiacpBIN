# v-sync-backups

A custom maintenance script for HestiaCP to synchronize backup metadata with the filesystem.

## Problem
HestiaCP maintains a list of user backups in `backup.conf`. If a backup file is manually deleted from the filesystem (e.g., using `rm`), HestiaCP does not automatically detect this. This leads to "phantom backups" appearing in the panel and incorrect disk usage statistics.

## Solution
This script iterates through all users (or a specific user), checks if the backups listed in their configuration actually exist on the disk (in `/backup`), and removes the record if the file is missing.

## Usage

### 1. Dry Run (Recommended First Step)
To see what would be deleted without actually making changes:
```bash
./v-sync-backups dry-run
```

### 2. Execute Fix
To remove phantom backups:
```bash
./v-sync-backups
```

### 3. Specific User
To run only for a specific user:
```bash
./v-sync-backups adminx078sys dry-run
```

## Installation
To use this tool globally as a Hestia command:

```bash
chmod +x v-sync-backups
ln -s $(pwd)/v-sync-backups /usr/local/hestia/bin/v-sync-backups
```
Now you can run it from anywhere as `v-sync-backups`.
