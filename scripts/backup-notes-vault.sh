#!/bin/bash
SRC="/home/syncthing/notes-vault/"
BACKUP_DIR="/backups/notes-vault"
TODAY="$BACKUP_DIR/$(date +%F)"
LATEST="$BACKUP_DIR/latest"

# Skip if today's backup already exists
[ -d "$TODAY" ] && exit 0

rsync -a --checksum --delete --link-dest="$LATEST" "$SRC" "$TODAY"

# rsync -a gives the snapshot the source directory mtime, so an unchanged vault
# makes a new snapshot look old and the prune below deletes it. Stamp it now.
touch "$TODAY"

ln -snf "$TODAY" "$LATEST"

# Prune backups older than 30 days
find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" -mtime +30 -exec rm -rf {} \;
