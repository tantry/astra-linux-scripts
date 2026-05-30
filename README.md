# Astra Linux Tools & Scripts

This repository contains scripts and tools for managing Astra Linux Special Edition, focusing on safe handling of third‑party repositories (Debian Bookworm, Google Chrome) and reliable system upgrades using local ISO files.

## 📖 Full Documentation & Guides

For detailed instructions and background, please refer to the following blog posts:

1. **[Astra Linux Special Edition 1.8 – Installation and Setup Guide](https://bushgrad.blogspot.com/2026/04/astra-linux-common-edition.html)**  
   *Initial installation, local repository setup, and basic configuration.*

2. **[Astra Linux after 30 Days: Managing Non‑Official Repository Conflicts](https://bushgrad.blogspot.com/2026/05/astra-linux-after-30-days-avoid-non.html)**  
   *How to safely isolate Debian/Chrome repositories, the multi‑language third‑party manager script, and why `fly-astra-update` fails with local ISOs.*

3. **[Astra Linux Upgrade: From 1.8.1.6 to 1.8.5 – What Actually Worked](https://bushgrad.blogspot.com/2026/05/astra-linux-upgrade-from-1816-to-185.html)**  
   *Step‑by‑step upgrade procedure using `apt dist-upgrade`, handling configuration prompts, and final verification.*

## 📁 Repository Contents

- `third-party-manager.sh` – Multi‑language (EN/RU/DE/FR/KO) script to safely enable, install/update, and disable third‑party repositories.  
  *Includes automatic cache population on first run, dry‑run safety checks, and detection of critical Astra system packages.*

*(Additional scripts may be added as needed.)*

## ⚠️ Important Notes

- These tools are designed and tested on **Astra Linux Special Edition** with **local ISO repositories** (`file://`).  
- The official `astra-update` tool does **not** work reliably with local ISOs – use standard `apt` commands instead.  
- Always keep third‑party repository files outside `/etc/apt/sources.list.d/` unless actively using them (the script does this automatically).  
- The script includes built‑in safety checks that will abort any installation that would remove critical Astra packages (`astra-*`, `fly-*`, `parsec`, etc.).

## 🔧 Quick Usage

```bash
# Download the script
wget https://raw.githubusercontent.com/tantry/astra-linux-scripts/main/third-party-manager.sh

# Make it executable
chmod +x third-party-manager.sh

# Run it
./third-party-manager.sh
