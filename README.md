```markdown
# Linux Tools & Scripts (including Astra Linux Special Edition)

A collection of scripts and documentation for:

- **Astra Linux Special Edition** – safe third‑party repository management, ISO‑based upgrades, and system maintenance.
- **General Linux audio processing** – split FLAC+CUE to tagged AAC, loudness normalization with EBU R128.
- **Hardware fixes** – disable Surface Pro touchscreen when needed.

All scripts are tested on Debian‑based distributions (Astra, Ubuntu) and Arch‑based (Manjaro).

## 📖 Full Documentation & Guides

Detailed background and step‑by‑step instructions are available on the blog:

1. **[Astra Linux Special Edition 1.8 – Installation and Setup Guide](https://bushgrad.blogspot.com/2026/04/astra-linux-common-edition.html)**  
   *Initial installation, local repository setup, and basic configuration.*

2. **[Astra Linux after 30 Days: Managing Non‑Official Repository Conflicts](https://bushgrad.blogspot.com/2026/05/astra-linux-after-30-days-avoid-non.html)**  
   *How to safely isolate Debian/Chrome repositories, the multi‑language third‑party manager script, and why `fly-astra-update` fails with local ISOs.*

3. **[Astra Linux Upgrade: From 1.8.1.6 to 1.8.5 – What Actually Worked](https://bushgrad.blogspot.com/2026/05/astra-linux-upgrade-from-1816-to-185.html)**  
   *Step‑by‑step upgrade procedure using `apt dist-upgrade`, handling configuration prompts, and final verification.*

## 📁 Repository Contents

### 🐧 Astra Linux System Tools

| File | Description |
|------|-------------|
| `third-party-manager.sh` | Multi‑language (EN/RU/DE/FR/KO) script to safely enable, install/update, and disable third‑party repositories. Includes automatic cache population, dry‑run safety checks, and detection of critical Astra system packages. |

### 🎵 Audio Processing

| File | Description |
|------|-------------|
| `cue2aac_atomic.sh` | Convert a single FLAC + CUE album into individual AAC (`.m4a`) tracks with embedded metadata (title, artist, album, track number, year, genre) and filenames like `01 - Song Title.m4a`. Handles leading zeros (`08`, `09`) correctly. |
| `cue2aac_atomic.md` | Full documentation for the FLAC‑to‑AAC splitter – dependencies, usage, troubleshooting, and alternative tools. |
| `normalize.sh` | One‑pass loudness normalization for `.m4a` files using FFmpeg’s EBU R128 loudnorm filter (target: `-16 LUFS`, `-1.5 dBTP`, `LRA 11`). Creates `normalized_*.m4a` files. |
| `normalize_two_pass.sh` | Two‑pass normalization method (extract audio first) – more accurate for short tracks. |
| `normalize.md` | Documentation for both normalization scripts: customisation, batch processing other formats (MP3, FLAC), troubleshooting. |

### 💻 Hardware Fixes

| File | Description |
|------|-------------|
| `SurfacePro_fixes.md` | Instructions to disable the touchscreen on Microsoft Surface Pro devices running Linux – useful when using a mouse/keyboard only. |

## 🔧 Quick Usage

### Astra Linux: Third‑Party Repository Manager

```bash
wget https://raw.githubusercontent.com/tantry/astra-linux-scripts/main/third-party-manager.sh
chmod +x third-party-manager.sh
./third-party-manager.sh
```

### Audio: FLAC+CUE to Tagged AAC

```bash
# Install dependencies (Debian/Ubuntu/Astra)
sudo apt install shntool cuetools ffmpeg atomicparsley

# Run the script in your album folder
./cue2aac_atomic.sh
```

### Audio: Normalize Volume (`.m4a` files)

```bash
# One‑pass (simple)
./normalize.sh

# Two‑pass (more accurate for short tracks)
./normalize_two_pass.sh

# Remove the "normalized_" prefix after processing
for f in normalized_*.m4a; do mv "$f" "${f#normalized_}"; done
```

### Surface Pro: Disable Touchscreen

See `SurfacePro_fixes.md` for kernel command line parameters or udev rules.

## ⚠️ Important Notes

- **Astra Linux tools** are designed and tested on **Astra Linux Special Edition** with **local ISO repositories** (`file://`).  
- The official `astra-update` tool does **not** work reliably with local ISOs – use standard `apt` commands instead.  
- Always keep third‑party repository files outside `/etc/apt/sources.list.d/` unless actively using them (the script does this automatically).  
- The `third-party-manager.sh` script includes built‑in safety checks that abort any installation that would remove critical Astra packages (`astra-*`, `fly-*`, `parsec`, etc.).  
- Audio scripts are **distribution‑agnostic** – they work on any Linux with `ffmpeg`, `shntool`, `AtomicParsley`, etc.  
- `normalize.sh` uses AAC encoding; for MP3 or FLAC adjust the output codec (see `normalize.md`).

## 📄 Individual Documentation

Each tool has its own markdown file with detailed usage, customisation, and troubleshooting:

- [`cue2aac_atomic.md`](cue2aac_atomic.md)
- [`normalize.md`](normalize.md)
- [`SurfacePro_fixes.md`](SurfacePro_fixes.md)

## 🤝 Contributing

Feel free to open issues or pull requests for improvements, additional scripts, or translations.

## 📜 License

These scripts are provided as-is, without warranty. You may use, modify, and distribute them freely.
```

