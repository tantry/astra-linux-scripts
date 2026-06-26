#!/bin/bash
# restore-power-settings-from-backup.sh
# Restores previously backed up logind.conf and powermanagementprofilesrc

BACKUP_DIR="$HOME/.power-settings-backup"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "No backup directory found at $BACKUP_DIR"
    echo "Run backup-power-settings.sh first to create backups."
    exit 1
fi

echo "Available backups:"
ls -1 "$BACKUP_DIR" | grep -E 'logind\.conf\.[0-9_]+' | sed 's/logind\.conf\.//'
echo ""
echo "Enter the timestamp (e.g., 20250315_120000) of the backup you want to restore:"
read -r TIMESTAMP

LOGIND_BACKUP="$BACKUP_DIR/logind.conf.$TIMESTAMP"
PROFILE_BACKUP="$BACKUP_DIR/powermanagementprofilesrc.$TIMESTAMP"

if [ ! -f "$LOGIND_BACKUP" ]; then
    echo "Backup file $LOGIND_BACKUP not found."
    exit 1
fi

echo "Restoring systemd-logind configuration..."
sudo cp "$LOGIND_BACKUP" /etc/systemd/logind.conf
sudo systemctl restart systemd-logind

if [ -f "$PROFILE_BACKUP" ]; then
    echo "Restoring Fly Power Manager configuration..."
    cp "$PROFILE_BACKUP" ~/.config/powermanagementprofilesrc
    # Restart PowerDevil to apply changes
    pkill -f powerdevil
    sleep 1
    if ! pgrep -f powerdevil >/dev/null; then
        powerdevil &
    fi
else
    echo "No backup of powermanagementprofilesrc found for this timestamp. Skipping."
fi

echo "Restore completed. Close lid to test behavior."
