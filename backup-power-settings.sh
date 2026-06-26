#!/bin/bash
BACKUP_DIR="$HOME/.power-settings-backup"
mkdir -p "$BACKUP_DIR"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup systemd-logind.conf
sudo cp /etc/systemd/logind.conf "$BACKUP_DIR/logind.conf.$DATE"

# Backup Fly power manager config
if [ -f ~/.config/powermanagementprofilesrc ]; then
    cp ~/.config/powermanagementprofilesrc "$BACKUP_DIR/powermanagementprofilesrc.$DATE"
fi

echo "Backup saved to $BACKUP_DIR with timestamp $DATE"
ls -la "$BACKUP_DIR"
