# Optimal Power Settings for Surface Pro on Astra Linux

## Overview

On the Surface Pro (tested on Pro 3), the standard Linux suspend/hibernate features do **not** work reliably. After resuming from sleep, the network often fails to reconnect, requiring a full reboot. To avoid this, the best configuration is to **shut down the system when the lid is closed while on battery**, and **do nothing when the lid is closed while on external power** (so you can keep the system running when plugged in).

This document explains the two configuration files that control this behavior and provides scripts to backup, restore, and verify the optimal settings.

---

## Which Files Control Lid Behavior?

### 1. System‑wide: `/etc/systemd/logind.conf`

This file is managed by `systemd-logind`, the system service that handles power events (lid close, power button, etc.). The relevant settings are:

- `HandleLidSwitch` – action when lid is closed on **battery** power.
- `HandleLidSwitchExternalPower` – action when lid is closed on **external (AC)** power.

Possible values: `poweroff`, `suspend`, `hibernate`, `ignore`, `lock`.

**Optimal for Surface Pro:**
- On battery: `poweroff` (shut down)
- On external power: `ignore` (do nothing)

### 2. User‑level GUI: `~/.config/powermanagementprofilesrc`

This file is used by the **Fly Power Manager** (Astra's KDE PowerDevil backend). The GUI settings are stored here. The key for lid action is `lidAction` under sections `[AC]`, `[Battery]`, `[LowBattery]`.

- `lidAction=0` → Do nothing
- `lidAction=8` → Shutdown (Fly‑specific value)

**Optimal for Surface Pro:**
- `[AC]` → `lidAction=0` (so the GUI does not interfere)
- `[Battery]` → `lidAction=8` (shutdown – as a fallback)
- `[LowBattery]` → `lidAction=8` (shutdown)

Because `systemd-logind` already shuts down the system on battery, the Fly GUI setting is redundant but ensures consistency.

---

## Why Suspend/Hibernate Are Not Recommended

When the Surface Pro resumes from suspend or hibernate, the following issues occur:

- **WiFi / network does not reconnect** – even after manual restart of NetworkManager, it may fail.
- **Touchscreen (if enabled) may misbehave** – ghost taps can reappear.
- **Battery drain** – suspend still consumes power, leading to a hot bag.
- **Unreliable resume** – sometimes the system fails to wake properly.

Therefore, the only reliable power states are:
- **Shut down** (when you close the lid on battery) – saves battery and avoids resume issues.
- **Running with lid open or plugged in** – for continuous tasks.

---

## Provided Scripts

All scripts should be placed in the same directory (e.g., `~/astra-linux-scripts/`) and made executable with `chmod +x scriptname`.

### 1. `backup-power-settings.sh`

Saves current `logind.conf` and `powermanagementprofilesrc` to `~/.power-settings-backup/` with a timestamp.

```bash
#!/bin/bash
BACKUP_DIR="$HOME/.power-settings-backup"
mkdir -p "$BACKUP_DIR"
DATE=$(date +%Y%m%d_%H%M%S)

sudo cp /etc/systemd/logind.conf "$BACKUP_DIR/logind.conf.$DATE"
if [ -f ~/.config/powermanagementprofilesrc ]; then
    cp ~/.config/powermanagementprofilesrc "$BACKUP_DIR/powermanagementprofilesrc.$DATE"
fi

echo "Backup saved to $BACKUP_DIR with timestamp $DATE"
ls -la "$BACKUP_DIR"
```

### 2. `restore-optimal-lid-shutdown.sh`

Restores the optimal settings:
- On battery: shut down
- On external power: do nothing
- Fly GUI: AC=Do nothing, Battery=Shutdown, LowBattery=Shutdown

```bash
#!/bin/bash
echo "Restoring optimal lid behavior (battery=shutdown, AC=ignore)..."

# systemd-logind
sudo sed -i 's/^#HandleLidSwitch=.*/HandleLidSwitch=poweroff/' /etc/systemd/logind.conf
sudo sed -i 's/^#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
grep -q "^HandleLidSwitch=" /etc/systemd/logind.conf || echo "HandleLidSwitch=poweroff" | sudo tee -a /etc/systemd/logind.conf
grep -q "^HandleLidSwitchExternalPower=" /etc/systemd/logind.conf || echo "HandleLidSwitchExternalPower=ignore" | sudo tee -a /etc/systemd/logind.conf
sudo systemctl restart systemd-logind

# Fly Power Manager
if command -v kwriteconfig5 &>/dev/null; then
    kwriteconfig5 --file powermanagementprofilesrc --group "AC" --key "lidAction" 0
    kwriteconfig5 --file powermanagementprofilesrc --group "Battery" --key "lidAction" 8
    kwriteconfig5 --file powermanagementprofilesrc --group "LowBattery" --key "lidAction" 8
else
    sed -i '/\[AC\]/,/^\[/ s/^lidAction=.*/lidAction=0/' ~/.config/powermanagementprofilesrc
    sed -i '/\[Battery\]/,/^\[/ s/^lidAction=.*/lidAction=8/' ~/.config/powermanagementprofilesrc
    sed -i '/\[LowBattery\]/,/^\[/ s/^lidAction=.*/lidAction=8/' ~/.config/powermanagementprofilesrc
fi

pkill -f powerdevil
sleep 1
pgrep -f powerdevil >/dev/null || powerdevil &

echo "Optimal settings applied. Close lid: on battery → shutdown, on AC → nothing."
```

### 3. `restore-power-settings-from-backup.sh`

Restores a previously backed‑up configuration (any backup made by `backup-power-settings.sh`). You will be prompted to choose which backup to restore.

```bash
#!/bin/bash
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
    pkill -f powerdevil
    sleep 1
    if ! pgrep -f powerdevil >/dev/null; then
        powerdevil &
    fi
else
    echo "No backup of powermanagementprofilesrc found for this timestamp. Skipping."
fi

echo "Restore completed. Close lid to test behavior."
```

### 4. `verify-lid-settings.sh`

Checks current settings against the expected optimal values.

```bash
#!/bin/bash
echo "=== Current Lid Settings ==="
echo "--- systemd-logind ---"
grep -E '^HandleLidSwitch' /etc/systemd/logind.conf
echo "--- Fly Power Manager (lidAction) ---"
grep lidAction ~/.config/powermanagementprofilesrc | head -3
echo "--- Expected optimal: AC:0, Battery:8, LowBattery:8 ---"
```

---

## How to Use

1. **Make all scripts executable**:
   ```bash
   chmod +x backup-power-settings.sh restore-optimal-lid-shutdown.sh restore-power-settings-from-backup.sh verify-lid-settings.sh
   ```

2. **Back up current settings** (optional but recommended):
   ```bash
   ./backup-power-settings.sh
   ```

3. **Apply optimal settings**:
   ```bash
   ./restore-optimal-lid-shutdown.sh
   ```

4. **Verify**:
   ```bash
   ./verify-lid-settings.sh
   ```

After running the restore script, close the lid:
- If running on battery → system shuts down after a few seconds.
- If plugged into AC → nothing happens (lid can be closed without powering off).

5. **To restore a previous backup** (e.g., after experimenting):
   ```bash
   ./restore-power-settings-from-backup.sh
   ```
   Follow the prompts to select the backup timestamp.

---

## Manual Verification (Without Scripts)

```bash
grep -E '^HandleLidSwitch' /etc/systemd/logind.conf
grep lidAction ~/.config/powermanagementprofilesrc | head -3
```

Expected optimal output:
```
HandleLidSwitch=poweroff
HandleLidSwitchExternalPower=ignore
lidAction=0
lidAction=8
lidAction=8
```

---

## Notes

- The restore scripts use `sudo` for system files – you will be prompted for your password.
- You can also change the lid behavior manually using the Fly Power Manager GUI (search for "Power Management" in the menu). However, the GUI alone does not control `systemd-logind`; both need to be set appropriately.
- This configuration has been tested on Astra Linux 1.8.5 on a Surface Pro 3. It may work on other Surface models.

## Troubleshooting

- If after applying the script the system still suspends on lid close, check that no other power manager (like `xfce4-power-manager`) is running.
- To temporarily disable the effect, run `sudo systemctl mask sleep.target suspend.target hibernate.target` – but this is not recommended.
- If network drops after a resume (should not happen because we avoid suspend), reboot the system.
- Backups are stored in `~/.power-settings-backup/`. You can delete old backups manually if needed.
