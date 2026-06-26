#!/bin/bash
# Restores the known working configuration:
# - systemd-logind: lid close = poweroff (on AC and battery)
# - Fly Power Manager: AC -> Do nothing (0), Battery -> Shutdown (8), LowBattery -> Shutdown (8)

echo "Restoring optimal lid close = SHUTDOWN configuration..."

# 1. Set systemd-logind
sudo sed -i 's/^#HandleLidSwitch=.*/HandleLidSwitch=poweroff/' /etc/systemd/logind.conf
sudo sed -i 's/^#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=poweroff/' /etc/systemd/logind.conf
# Ensure lines exist if missing
grep -q "^HandleLidSwitch=" /etc/systemd/logind.conf || echo "HandleLidSwitch=poweroff" | sudo tee -a /etc/systemd/logind.conf
grep -q "^HandleLidSwitchExternalPower=" /etc/systemd/logind.conf || echo "HandleLidSwitchExternalPower=poweroff" | sudo tee -a /etc/systemd/logind.conf

sudo systemctl restart systemd-logind
echo "✓ systemd-logind updated (lid close = poweroff)."

# 2. Set Fly Power Manager lid actions
# Use kwriteconfig5 if available (Fly uses KDE PowerDevil)
if command -v kwriteconfig5 &>/dev/null; then
    kwriteconfig5 --file powermanagementprofilesrc --group "AC" --key "lidAction" 0
    kwriteconfig5 --file powermanagementprofilesrc --group "Battery" --key "lidAction" 8
    kwriteconfig5 --file powermanagementprofilesrc --group "LowBattery" --key "lidAction" 8
else
    # Fallback: manually edit the file using sed
    # Ensure sections exist and set lidAction correctly
    for section in "AC" "Battery" "LowBattery"; do
        if ! grep -q "\[$section\]" ~/.config/powermanagementprofilesrc; then
            echo -e "\n[$section]\nlidAction=0" >> ~/.config/powermanagementprofilesrc
        else
            # Replace lidAction within the section
            sed -i "/\[$section\]/,/^\[/ s/^lidAction=.*/lidAction=0/" ~/.config/powermanagementprofilesrc
        fi
    done
    # Set specific values (AC=0, Battery/LowBattery=8)
    sed -i '/\[AC\]/,/^\[/ s/^lidAction=.*/lidAction=0/' ~/.config/powermanagementprofilesrc
    sed -i '/\[Battery\]/,/^\[/ s/^lidAction=.*/lidAction=8/' ~/.config/powermanagementprofilesrc
    sed -i '/\[LowBattery\]/,/^\[/ s/^lidAction=.*/lidAction=8/' ~/.config/powermanagementprofilesrc
fi

# 3. Restart Fly power manager (powerdevil) to apply changes
pkill -f powerdevil
sleep 1
if ! pgrep -f powerdevil >/dev/null; then
    powerdevil &
fi

echo "✓ Fly Power Manager set to: AC=Do nothing (0), Battery=Shutdown (8), LowBattery=Shutdown (8)."
echo "Optimal configuration restored. Close lid to test (system will shut down)."
