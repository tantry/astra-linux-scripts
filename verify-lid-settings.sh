#!/bin/bash
echo "Checking lid close configuration..."
echo "--- systemd-logind ---"
grep -E '^HandleLidSwitch' /etc/systemd/logind.conf
echo "--- Fly Power Manager lidAction values ---"
grep lidAction ~/.config/powermanagementprofilesrc | head -3
